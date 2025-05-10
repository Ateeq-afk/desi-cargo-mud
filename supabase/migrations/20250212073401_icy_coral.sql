-- Drop super admin related functions
DROP FUNCTION IF EXISTS is_super_admin CASCADE;

-- First drop the existing function
DROP FUNCTION IF EXISTS get_current_user_role();

-- Create new get_current_user_role function
CREATE OR REPLACE FUNCTION get_current_user_role()
RETURNS TABLE (
  is_admin boolean,
  branch_id uuid
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    bu.role = 'admin' as is_admin,
    bu.branch_id
  FROM branch_users bu
  WHERE bu.user_id = auth.uid()
  LIMIT 1;

  -- If no rows returned, return default values
  IF NOT FOUND THEN
    RETURN QUERY SELECT 
      false as is_admin,
      NULL::uuid as branch_id;
  END IF;
END;
$$;

-- Update branch_users policies
DROP POLICY IF EXISTS "branch_users_select" ON branch_users;
DROP POLICY IF EXISTS "branch_users_insert" ON branch_users;
DROP POLICY IF EXISTS "branch_users_update" ON branch_users;
DROP POLICY IF EXISTS "branch_users_delete" ON branch_users;

CREATE POLICY "branch_users_select"
  ON branch_users
  FOR SELECT
  USING (
    -- Allow branch admins to see all users in their branch
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND branch_id = branch_users.branch_id
      AND role = 'admin'
    )
    OR
    -- Allow users to see themselves
    user_id = auth.uid()
  );

CREATE POLICY "branch_users_insert"
  ON branch_users
  FOR INSERT
  WITH CHECK (
    -- Only branch admins can add users
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND branch_id = branch_users.branch_id
      AND role = 'admin'
    )
  );

CREATE POLICY "branch_users_update"
  ON branch_users
  FOR UPDATE
  USING (
    -- Only branch admins can update users
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND branch_id = branch_users.branch_id
      AND role = 'admin'
    )
  );

CREATE POLICY "branch_users_delete"
  ON branch_users
  FOR DELETE
  USING (
    -- Only branch admins can delete users
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND branch_id = branch_users.branch_id
      AND role = 'admin'
    )
  );

-- Create function to initialize first admin
CREATE OR REPLACE FUNCTION initialize_first_admin(
  branch_id uuid,
  user_email text,
  user_name text,
  user_phone text
)
RETURNS void
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Check if branch exists
  IF NOT EXISTS (SELECT 1 FROM branches WHERE id = branch_id) THEN
    RAISE EXCEPTION 'Branch not found';
  END IF;

  -- Check if branch already has an admin
  IF EXISTS (
    SELECT 1 FROM branch_users 
    WHERE branch_id = branch_id 
    AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Branch already has an admin';
  END IF;

  -- Get user ID from email
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = user_email;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not found with email: %', user_email;
  END IF;

  -- Add user as branch admin
  INSERT INTO branch_users (
    branch_id,
    user_id,
    role,
    name,
    email,
    phone
  )
  VALUES (
    branch_id,
    v_user_id,
    'admin',
    user_name,
    user_email,
    user_phone
  );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_current_user_role TO authenticated;
GRANT EXECUTE ON FUNCTION initialize_first_admin TO authenticated;