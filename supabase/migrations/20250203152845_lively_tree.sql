/*
  # Customer Functions Migration

  1. Changes
    - Drop and recreate get_customers_with_details function
    - Add timestamp update trigger
    - Add data validation trigger
  
  2. Security
    - Functions use SECURITY DEFINER
    - Proper access control checks
    - Input validation
*/

-- First drop existing function if it exists
DROP FUNCTION IF EXISTS get_customers_with_details(uuid);

-- Create function to get customers with details
CREATE OR REPLACE FUNCTION get_customers_with_details(org_id uuid)
RETURNS TABLE (
  id uuid,
  organization_id uuid,
  name text,
  mobile text,
  gst text,
  type text,
  created_at timestamptz,
  updated_at timestamptz,
  branch_id uuid,
  organization_name text,
  organization_display_name text,
  branch_name text,
  branch_code text
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if user has access to organization
  IF NOT EXISTS (
    SELECT 1 FROM organization_members
    WHERE organization_id = org_id
    AND user_id = auth.uid()
  ) AND NOT (
    SELECT email = 'tabateeq@gmail.com'
    FROM auth.users
    WHERE id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    c.id,
    c.organization_id,
    c.name,
    c.mobile,
    c.gst,
    c.type,
    c.created_at,
    c.updated_at,
    c.branch_id,
    o.name as organization_name,
    o.display_name as organization_display_name,
    b.name as branch_name,
    b.code as branch_code
  FROM customers c
  LEFT JOIN organizations o ON o.id = c.organization_id
  LEFT JOIN branches b ON b.id = c.branch_id
  WHERE c.organization_id = org_id
  ORDER BY c.created_at DESC;
END;
$$;

-- Drop existing triggers and functions if they exist
DROP TRIGGER IF EXISTS update_customer_timestamps ON customers;
DROP FUNCTION IF EXISTS update_customer_timestamps();

DROP TRIGGER IF EXISTS validate_customer_data ON customers;
DROP FUNCTION IF EXISTS validate_customer_data();

-- Create trigger to update timestamps
CREATE OR REPLACE FUNCTION update_customer_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customer_timestamps
  BEFORE UPDATE ON customers
  FOR EACH ROW
  EXECUTE FUNCTION update_customer_timestamps();

-- Create function to validate customer data
CREATE OR REPLACE FUNCTION validate_customer_data()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate mobile number format
  IF NEW.mobile !~ '^\+?[0-9]{10,15}$' THEN
    RAISE EXCEPTION 'Invalid mobile number format';
  END IF;

  -- Validate GST format if provided
  IF NEW.gst IS NOT NULL AND NEW.gst !~ '^[0-9A-Z]{15}$' THEN
    RAISE EXCEPTION 'Invalid GST number format';
  END IF;

  -- Validate customer type
  IF NEW.type NOT IN ('individual', 'company') THEN
    RAISE EXCEPTION 'Invalid customer type';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_customer_data
  BEFORE INSERT OR UPDATE ON customers
  FOR EACH ROW
  EXECUTE FUNCTION validate_customer_data();

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_customers_with_details TO authenticated;