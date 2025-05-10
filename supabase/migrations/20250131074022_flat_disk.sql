-- Create function to check if user can manage customers
CREATE OR REPLACE FUNCTION can_manage_customers(org_id uuid)
RETURNS boolean
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Super admin can manage all customers
  IF EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND email = 'tabateeq@gmail.com'
  ) THEN
    RETURN true;
  END IF;

  -- Organization members can manage their org's customers
  RETURN EXISTS (
    SELECT 1 FROM organization_members
    WHERE organization_id = org_id
    AND user_id = auth.uid()
  );
END;
$$;

-- Create function to add customer with proper validation
CREATE OR REPLACE FUNCTION add_customer(
  org_id uuid,
  customer_data json
)
RETURNS json
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  result json;
BEGIN
  -- Validate inputs
  IF org_id IS NULL THEN
    RAISE EXCEPTION 'Organization ID is required';
  END IF;

  -- Check if user has permission
  IF NOT can_manage_customers(org_id) THEN
    RAISE EXCEPTION 'Permission denied: must be an organization member or super admin';
  END IF;

  -- Add customer
  INSERT INTO customers (
    organization_id,
    name,
    mobile,
    gst,
    type
  )
  SELECT
    org_id,
    customer_data->>'name',
    customer_data->>'mobile',
    customer_data->>'gst',
    customer_data->>'type'
  RETURNING json_build_object(
    'id', id,
    'organization_id', organization_id,
    'name', name,
    'mobile', mobile,
    'gst', gst,
    'type', type,
    'created_at', created_at
  ) INTO result;

  RETURN result;
END;
$$;

-- Drop existing customer policies
DROP POLICY IF EXISTS "customers_select_policy" ON customers;
DROP POLICY IF EXISTS "customers_insert_policy" ON customers;
DROP POLICY IF EXISTS "customers_update_policy" ON customers;
DROP POLICY IF EXISTS "customers_delete_policy" ON customers;

-- Create improved customer policies
CREATE POLICY "customers_select_policy"
  ON customers
  FOR SELECT
  USING (
    -- Super admin can view all customers
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND email = 'tabateeq@gmail.com'
    )
    OR
    -- Organization members can view their org's customers
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
    can_manage_customers(organization_id)
  );

CREATE POLICY "customers_update_policy"
  ON customers
  FOR UPDATE
  USING (
    can_manage_customers(organization_id)
  );

CREATE POLICY "customers_delete_policy"
  ON customers
  FOR DELETE
  USING (
    can_manage_customers(organization_id)
  );

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION can_manage_customers TO authenticated;
GRANT EXECUTE ON FUNCTION add_customer TO authenticated;

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_customers_organization_mobile ON customers(organization_id, mobile);
CREATE INDEX IF NOT EXISTS idx_customers_organization_name ON customers(organization_id, name);
CREATE INDEX IF NOT EXISTS idx_customers_organization_gst ON customers(organization_id, gst);