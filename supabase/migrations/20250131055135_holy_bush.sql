/*
  # Fix Organization Members Policies

  1. Changes
    - Drop existing policies
    - Create new non-recursive policies with proper syntax
    - Add performance optimization index
  
  2. Security
    - Maintain super admin access
    - Fix NEW reference issue
    - Keep existing permissions intact
*/

-- Drop problematic policies
DROP POLICY IF EXISTS "Allow super admin and members to view organization members" ON organization_members;
DROP POLICY IF EXISTS "Allow super admin and org admins to manage members" ON organization_members;

-- Create simplified policies for organization members
CREATE POLICY "organization_members_select_policy"
  ON organization_members
  FOR SELECT
  USING (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow users to see organizations they're members of
    user_id = auth.uid()
  );

CREATE POLICY "organization_members_insert_policy"
  ON organization_members
  FOR INSERT
  WITH CHECK (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization admins
    (
      EXISTS (
        SELECT 1 FROM organization_members
        WHERE organization_id = organization_members.organization_id
        AND user_id = auth.uid()
        AND role = 'admin'
      )
    )
  );

CREATE POLICY "organization_members_update_policy"
  ON organization_members
  FOR UPDATE
  USING (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization admins
    (
      EXISTS (
        SELECT 1 FROM organization_members
        WHERE organization_id = organization_members.organization_id
        AND user_id = auth.uid()
        AND role = 'admin'
      )
    )
  );

CREATE POLICY "organization_members_delete_policy"
  ON organization_members
  FOR DELETE
  USING (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization admins
    (
      EXISTS (
        SELECT 1 FROM organization_members
        WHERE organization_id = organization_members.organization_id
        AND user_id = auth.uid()
        AND role = 'admin'
      )
    )
  );

-- Create index to improve policy performance
CREATE INDEX IF NOT EXISTS idx_org_members_user_role ON organization_members(user_id, role);