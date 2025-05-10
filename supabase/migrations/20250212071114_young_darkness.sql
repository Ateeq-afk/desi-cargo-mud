-- First drop existing check constraint
ALTER TABLE branch_users 
DROP CONSTRAINT IF EXISTS branch_users_role_check;

-- Update role check constraint to only allow admin and operator
ALTER TABLE branch_users
ADD CONSTRAINT branch_users_role_check 
CHECK (role IN ('admin', 'operator'));

-- Create function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM branch_users
    WHERE user_id = auth.uid()
    AND role = 'admin'
  );
END;
$$;

-- Create function to check if user is branch operator
CREATE OR REPLACE FUNCTION is_branch_operator(branch_id uuid)
RETURNS boolean
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM branch_users
    WHERE user_id = auth.uid()
    AND branch_id = $1
    AND role = 'operator'
  );
END;
$$;

-- Create function to get user's branch
CREATE OR REPLACE FUNCTION get_user_branch()
RETURNS uuid
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  user_branch_id uuid;
BEGIN
  SELECT branch_id INTO user_branch_id
  FROM branch_users
  WHERE user_id = auth.uid()
  LIMIT 1;
  
  RETURN user_branch_id;
END;
$$;

-- Update branch_users policies
CREATE POLICY "branch_users_select"
  ON branch_users
  FOR SELECT
  USING (
    is_admin() OR
    user_id = auth.uid()
  );

CREATE POLICY "branch_users_insert"
  ON branch_users
  FOR INSERT
  WITH CHECK (
    is_admin()
  );

CREATE POLICY "branch_users_update"
  ON branch_users
  FOR UPDATE
  USING (
    is_admin()
  );

CREATE POLICY "branch_users_delete"
  ON branch_users
  FOR DELETE
  USING (
    is_admin()
  );

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION is_admin TO authenticated;
GRANT EXECUTE ON FUNCTION is_branch_operator TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_branch TO authenticated;