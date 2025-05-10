/*
  # Add branch relationship to customers

  1. Changes
    - Add branch_id column to customers table
    - Add foreign key constraint to branches table
    - Add index for better query performance

  2. Security
    - Maintain existing RLS policies
*/

-- Add branch_id to customers
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS branch_id uuid REFERENCES branches(id);

-- Add index for branch lookups
CREATE INDEX IF NOT EXISTS idx_customers_branch_id ON customers(branch_id);

-- Update existing customers query
CREATE OR REPLACE FUNCTION get_customer_details(customer_ids uuid[])
RETURNS TABLE (
  id uuid,
  organization_id uuid,
  branch_id uuid,
  name text,
  mobile text,
  gst text,
  type text,
  created_at timestamptz,
  updated_at timestamptz,
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
  RETURN QUERY
  SELECT 
    c.id,
    c.organization_id,
    c.branch_id,
    c.name,
    c.mobile,
    c.gst,
    c.type,
    c.created_at,
    c.updated_at,
    o.name as organization_name,
    o.display_name as organization_display_name,
    b.name as branch_name,
    b.code as branch_code
  FROM customers c
  LEFT JOIN organizations o ON o.id = c.organization_id
  LEFT JOIN branches b ON b.id = c.branch_id
  WHERE c.id = ANY(customer_ids);
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_customer_details TO authenticated;