-- First drop all dependent policies
DROP POLICY IF EXISTS "organization_members_select_policy" ON organization_members;
DROP POLICY IF EXISTS "organization_members_insert_policy" ON organization_members;
DROP POLICY IF EXISTS "organization_members_update_policy" ON organization_members;
DROP POLICY IF EXISTS "organization_members_delete_policy" ON organization_members;
DROP POLICY IF EXISTS "Allow organization updates" ON organizations;

-- Now we can safely drop the functions
DROP FUNCTION IF EXISTS is_super_admin() CASCADE;
DROP FUNCTION IF EXISTS get_current_user_role() CASCADE;

-- Create function to check if user is super admin
CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS boolean
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND email = 'tabateeq@gmail.com'
  );
END;
$$;

-- Create function to get current user's role with super admin check
CREATE OR REPLACE FUNCTION get_current_user_role()
RETURNS TABLE (
  is_admin boolean,
  is_super_admin boolean,
  branch_id uuid
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- First check if user is super admin
  IF EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND email = 'tabateeq@gmail.com'
  ) THEN
    RETURN QUERY
    SELECT 
      true as is_admin,
      true as is_super_admin,
      NULL::uuid as branch_id;
    RETURN;
  END IF;

  -- Otherwise check branch user role
  RETURN QUERY
  SELECT 
    bu.role = 'admin' as is_admin,
    false as is_super_admin,
    bu.branch_id
  FROM branch_users bu
  WHERE bu.user_id = auth.uid()
  LIMIT 1;
END;
$$;

-- Recreate organization members policies
CREATE POLICY "organization_members_select_policy"
  ON organization_members
  FOR SELECT
  USING (
    is_super_admin() OR
    user_id = auth.uid()
  );

CREATE POLICY "organization_members_insert_policy"
  ON organization_members
  FOR INSERT
  WITH CHECK (
    is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_members.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

CREATE POLICY "organization_members_update_policy"
  ON organization_members
  FOR UPDATE
  USING (
    is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_members.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

CREATE POLICY "organization_members_delete_policy"
  ON organization_members
  FOR DELETE
  USING (
    is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_members.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Recreate organization update policy
CREATE POLICY "Allow organization updates"
  ON organizations
  FOR UPDATE
  USING (
    is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Update branch_users policies to include super admin
DROP POLICY IF EXISTS "branch_users_select" ON branch_users;
DROP POLICY IF EXISTS "branch_users_insert" ON branch_users;
DROP POLICY IF EXISTS "branch_users_update" ON branch_users;
DROP POLICY IF EXISTS "branch_users_delete" ON branch_users;

CREATE POLICY "branch_users_select"
  ON branch_users
  FOR SELECT
  USING (
    is_super_admin() OR
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
    OR user_id = auth.uid()
  );

CREATE POLICY "branch_users_insert"
  ON branch_users
  FOR INSERT
  WITH CHECK (
    is_super_admin() OR
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );

CREATE POLICY "branch_users_update"
  ON branch_users
  FOR UPDATE
  USING (
    is_super_admin() OR
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );

CREATE POLICY "branch_users_delete"
  ON branch_users
  FOR DELETE
  USING (
    is_super_admin() OR
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION is_super_admin TO authenticated;
GRANT EXECUTE ON FUNCTION get_current_user_role TO authenticated;