/*
  # Add Super Admin Role and Policies

  1. Changes
    - Add super_admin function to auth schema
    - Update RLS policies to allow super admin access
  
  2. Security
    - Super admin (tabateeq@gmail.com) can manage all organizations
    - Super admin can manage all users and resources
    - Existing member permissions remain unchanged
*/

-- Drop existing policies
DO $$ 
BEGIN
  -- Organizations
  DROP POLICY IF EXISTS "Organizations viewable by authenticated users" ON organizations;
  DROP POLICY IF EXISTS "Organizations insertable by authenticated users" ON organizations;
  DROP POLICY IF EXISTS "Organizations updatable by admins" ON organizations;
  
  -- Organization members
  DROP POLICY IF EXISTS "Members viewable by authenticated users" ON organization_members;
  DROP POLICY IF EXISTS "Members insertable by admins" ON organization_members;
  
  -- Branches
  DROP POLICY IF EXISTS "Branches are viewable by organization members" ON branches;
  DROP POLICY IF EXISTS "Branches are manageable by organization admins" ON branches;
  
  -- Customers
  DROP POLICY IF EXISTS "Customers are viewable by organization members" ON customers;
  DROP POLICY IF EXISTS "Customers are manageable by organization members" ON customers;
  
  -- Articles
  DROP POLICY IF EXISTS "Articles are viewable by organization members" ON articles;
  DROP POLICY IF EXISTS "Articles are manageable by organization members" ON articles;
  
  -- Bookings
  DROP POLICY IF EXISTS "Bookings are viewable by organization members" ON bookings;
  DROP POLICY IF EXISTS "Bookings are manageable by organization members" ON bookings;
  
  -- Vehicles
  DROP POLICY IF EXISTS "Vehicles are viewable by organization members" ON vehicles;
  DROP POLICY IF EXISTS "Vehicles are manageable by organization admins" ON vehicles;
END $$;

-- Create super admin function
CREATE OR REPLACE FUNCTION auth.is_super_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (
    SELECT email = 'tabateeq@gmail.com'
    FROM auth.users
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create new policies for organizations
CREATE POLICY "Allow super admin and members to view organizations"
  ON organizations
  FOR SELECT
  USING (
    auth.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Allow super admin and members to insert organizations"
  ON organizations
  FOR INSERT
  WITH CHECK (
    auth.is_super_admin() OR
    auth.uid() IS NOT NULL
  );

CREATE POLICY "Allow super admin and org admins to update organizations"
  ON organizations
  FOR UPDATE
  USING (
    auth.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

CREATE POLICY "Allow super admin to delete organizations"
  ON organizations
  FOR DELETE
  USING (auth.is_super_admin());

-- Create new policies for organization members
CREATE POLICY "Allow super admin and members to view organization members"
  ON organization_members
  FOR SELECT
  USING (auth.is_super_admin() OR auth.uid() IS NOT NULL);

CREATE POLICY "Allow super admin and org admins to manage members"
  ON organization_members
  FOR ALL
  USING (
    auth.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_members.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Create new policies for branches
CREATE POLICY "Allow super admin and members to view branches"
  ON branches
  FOR SELECT
  USING (
    auth.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = branches.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Allow super admin and org admins to manage branches"
  ON branches
  FOR ALL
  USING (
    auth.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = branches.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Create new policies for customers
CREATE POLICY "Allow super admin and members to view customers"
  ON customers
  FOR SELECT
  USING (
    auth.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Allow super admin and members to manage customers"
  ON customers
  FOR ALL
  USING (
    auth.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
    )
  );

-- Create new policies for articles
CREATE POLICY "Allow super admin and members to view articles"
  ON articles
  FOR SELECT
  USING (
    auth.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = articles.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Allow super admin and members to manage articles"
  ON articles
  FOR ALL
  USING (
    auth.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = articles.organization_id
      AND user_id = auth.uid()
    )
  );

-- Create new policies for bookings
CREATE POLICY "Allow super admin and members to view bookings"
  ON bookings
  FOR SELECT
  USING (
    auth.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = bookings.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Allow super admin and members to manage bookings"
  ON bookings
  FOR ALL
  USING (
    auth.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = bookings.organization_id
      AND user_id = auth.uid()
    )
  );

-- Create new policies for vehicles
CREATE POLICY "Allow super admin and members to view vehicles"
  ON vehicles
  FOR SELECT
  USING (
    auth.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = vehicles.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Allow super admin and org admins to manage vehicles"
  ON vehicles
  FOR ALL
  USING (
    auth.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = vehicles.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );