/*
  # Fix Auth Permissions and Policies

  1. Changes
    - Create secure function to check super admin status
    - Update policies to use new function
    - Fix permission issues with auth.users table
  
  2. Security
    - Keep super admin access for tabateeq@gmail.com
    - Maintain existing permissions
    - Use security definer for safer auth checks
*/

-- Create a secure function to check super admin status
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean AS $$
  -- Use security definer to run as postgres user
  SELECT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND email = 'tabateeq@gmail.com'
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Update organization policies
DROP POLICY IF EXISTS "Allow super admin and members to view organizations" ON organizations;
CREATE POLICY "Allow super admin and members to view organizations"
  ON organizations
  FOR SELECT
  USING (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
      AND user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Allow super admin to delete organizations" ON organizations;
CREATE POLICY "Allow super admin to delete organizations"
  ON organizations
  FOR DELETE
  USING (public.is_super_admin());

-- Update organization members policies
DROP POLICY IF EXISTS "organization_members_select_policy" ON organization_members;
CREATE POLICY "organization_members_select_policy"
  ON organization_members
  FOR SELECT
  USING (
    public.is_super_admin() OR
    user_id = auth.uid()
  );

DROP POLICY IF EXISTS "organization_members_insert_policy" ON organization_members;
CREATE POLICY "organization_members_insert_policy"
  ON organization_members
  FOR INSERT
  WITH CHECK (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_members.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "organization_members_update_policy" ON organization_members;
CREATE POLICY "organization_members_update_policy"
  ON organization_members
  FOR UPDATE
  USING (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_members.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "organization_members_delete_policy" ON organization_members;
CREATE POLICY "organization_members_delete_policy"
  ON organization_members
  FOR DELETE
  USING (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_members.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Grant necessary permissions
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT ON auth.users TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_super_admin TO authenticated;