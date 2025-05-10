/*
  # Add Organization Update Policy

  1. Changes
    - Add policy to allow organization admins to update organization names
    - Add policy to allow super admin to update any organization
*/

-- Drop existing update policy if it exists
DROP POLICY IF EXISTS "Allow super admin and org admins to update organizations" ON organizations;

-- Create new update policy
CREATE POLICY "Allow organization updates"
  ON organizations
  FOR UPDATE
  USING (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  )
  WITH CHECK (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );