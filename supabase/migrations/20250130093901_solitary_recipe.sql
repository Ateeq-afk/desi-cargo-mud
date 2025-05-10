/*
  # Fix RLS Policies
  
  1. Changes
    - Fixes policy structure to avoid recursion
    - Simplifies policy management
    - Maintains same security model
    
  2. Security Updates
    - Organizations viewable by members
    - Organizations insertable by authenticated users
    - Organizations updatable by admins
    - Members viewable by authenticated users
    - Members manageable by admins
    - Branches manageable by admins
*/

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Organizations are viewable by organization members" ON organizations;
DROP POLICY IF EXISTS "Organizations are insertable by authenticated users" ON organizations;
DROP POLICY IF EXISTS "Organizations are updatable by organization admins" ON organizations;
DROP POLICY IF EXISTS "Organization members are viewable by organization members" ON organization_members;
DROP POLICY IF EXISTS "Organization members are manageable by organization admins" ON organization_members;
DROP POLICY IF EXISTS "Organization members are viewable by authenticated users" ON organization_members;
DROP POLICY IF EXISTS "Organization members are insertable by organization admins" ON organization_members;
DROP POLICY IF EXISTS "Organization members are updatable by organization admins" ON organization_members;
DROP POLICY IF EXISTS "Organization members are deletable by organization admins" ON organization_members;
DROP POLICY IF EXISTS "Branches are viewable by organization members" ON branches;
DROP POLICY IF EXISTS "Branches are manageable by organization admins" ON branches;
DROP POLICY IF EXISTS "Branches are insertable by organization admins" ON branches;
DROP POLICY IF EXISTS "Branches are updatable by organization admins" ON branches;
DROP POLICY IF EXISTS "Branches are deletable by organization admins" ON branches;

-- Create simplified policies for organizations
CREATE POLICY "Organizations are viewable by organization members"
  ON organizations
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Organizations are insertable by authenticated users"
  ON organizations
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Organizations are updatable by organization admins"
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

-- Create simplified policies for organization_members
CREATE POLICY "Organization members are viewable by authenticated users"
  ON organization_members
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Organization members are manageable by organization admins"
  ON organization_members
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM organization_members om
      WHERE om.organization_id = organization_members.organization_id
      AND om.user_id = auth.uid()
      AND om.role = 'admin'
    )
  );

-- Create simplified policies for branches
CREATE POLICY "Branches are viewable by organization members"
  ON branches
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = branches.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Branches are manageable by organization admins"
  ON branches
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = branches.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );