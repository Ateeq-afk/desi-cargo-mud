/*
  # Fix Organization Policies
  
  1. Changes
    - Drop existing policies
    - Create simplified policies for organizations and members
    - Enable basic access for authenticated users
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON organizations;
DROP POLICY IF EXISTS "Enable all access for organization members" ON organization_members;
DROP POLICY IF EXISTS "Enable initial admin access" ON organization_members;

-- Create simplified policies for organizations
CREATE POLICY "Organizations are viewable by all authenticated users"
  ON organizations
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Organizations are creatable by authenticated users"
  ON organizations
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Create simplified policies for organization members
CREATE POLICY "Members are viewable by authenticated users"
  ON organization_members
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Members are manageable by organization admins"
  ON organization_members
  FOR ALL
  USING (
    auth.uid() IS NOT NULL AND (
      -- Allow if user is an admin of the organization
      EXISTS (
        SELECT 1 FROM organization_members
        WHERE organization_id = organization_members.organization_id
        AND user_id = auth.uid()
        AND role = 'admin'
      )
      OR
      -- Allow if this is the first member being added
      NOT EXISTS (
        SELECT 1 FROM organization_members
        WHERE organization_id = organization_members.organization_id
      )
    )
  );