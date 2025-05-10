-- Grant necessary auth permissions
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT ON auth.users TO authenticated;

-- Create secure function to get current user
CREATE OR REPLACE FUNCTION get_current_user()
RETURNS TABLE (
  id uuid,
  email text,
  role text
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.email::text,
    CASE 
      WHEN u.email = 'tabateeq@gmail.com' THEN 'super_admin'::text
      ELSE 'user'::text
    END as role
  FROM auth.users u
  WHERE u.id = auth.uid();
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_current_user TO authenticated;

-- Create policy for organization members to view users
CREATE POLICY "users_select_policy"
  ON auth.users
  FOR SELECT
  USING (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow users to see themselves
    id = auth.uid()
    OR
    -- Allow organization admins to see their members
    EXISTS (
      SELECT 1 FROM organization_members om
      WHERE om.user_id = auth.uid()
      AND om.role = 'admin'
      AND EXISTS (
        SELECT 1 FROM organization_members om2
        WHERE om2.organization_id = om.organization_id
        AND om2.user_id = auth.users.id
      )
    )
  );