/*
  # Add Super Admin Customer Management

  1. Changes
    - Add helper functions for super admin checks
    - Update customer policies to allow super admin access
    - Add organization validation functions
    
  2. Security
    - Uses secure functions with proper error handling
    - Maintains RLS policies
*/

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

-- Create function to validate organization access
CREATE OR REPLACE FUNCTION can_access_organization(org_id uuid)
RETURNS boolean
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Super admin can access all organizations
  IF is_super_admin() THEN
    RETURN true;
  END IF;

  -- Check if user is a member of the organization
  RETURN EXISTS (
    SELECT 1 FROM organization_members
    WHERE organization_id = org_id
    AND user_id = auth.uid()
  );
END;
$$;

-- Drop existing customer policies
DROP POLICY IF EXISTS "Customers are viewable by organization members" ON customers;
DROP POLICY IF EXISTS "Customers are manageable by organization members" ON customers;

-- Create new customer policies that include super admin access
CREATE POLICY "customers_select_policy"
  ON customers
  FOR SELECT
  USING (
    is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "customers_insert_policy"
  ON customers
  FOR INSERT
  WITH CHECK (
    is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "customers_update_policy"
  ON customers
  FOR UPDATE
  USING (
    is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "customers_delete_policy"
  ON customers
  FOR DELETE
  USING (
    is_super_admin() OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
    )
  );

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION is_super_admin TO authenticated;
GRANT EXECUTE ON FUNCTION can_access_organization TO authenticated;