/*
  # Fix Organization Policies Recursion
  
  1. Changes
    - Drop existing problematic policies
    - Create new non-recursive policies for organizations and members
    - Simplify policy logic to prevent infinite recursion
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Organizations are viewable by all authenticated users" ON organizations;
DROP POLICY IF EXISTS "Organizations are creatable by authenticated users" ON organizations;
DROP POLICY IF EXISTS "Members are viewable by authenticated users" ON organization_members;
DROP POLICY IF EXISTS "Members are manageable by organization admins" ON organization_members;

-- Create new non-recursive policies for organizations
CREATE POLICY "Allow select for authenticated users"
  ON organizations
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Allow insert for authenticated users"
  ON organizations
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Allow update for organization admins"
  ON organizations
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Create new non-recursive policies for organization members
CREATE POLICY "Allow select members for authenticated users"
  ON organization_members
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Allow insert first member"
  ON organization_members
  FOR INSERT
  WITH CHECK (
    -- Allow if this is the first member (for the trigger)
    NOT EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_members.organization_id
    )
    OR
    -- Or if the user is an admin
    (
      auth.uid() IN (
        SELECT user_id 
        FROM organization_members
        WHERE organization_id = organization_members.organization_id
        AND role = 'admin'
      )
    )
  );

CREATE POLICY "Allow update by admin"
  ON organization_members
  FOR UPDATE
  USING (
    auth.uid() IN (
      SELECT user_id 
      FROM organization_members
      WHERE organization_id = organization_members.organization_id
      AND role = 'admin'
    )
  );

CREATE POLICY "Allow delete by admin"
  ON organization_members
  FOR DELETE
  USING (
    auth.uid() IN (
      SELECT user_id 
      FROM organization_members
      WHERE organization_id = organization_members.organization_id
      AND role = 'admin'
    )
  );