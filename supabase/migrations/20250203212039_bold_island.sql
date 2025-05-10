-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_customers_with_details(uuid);
DROP FUNCTION IF EXISTS get_customers_with_details(p_org_id uuid);

-- Create function to get customers with details
CREATE OR REPLACE FUNCTION get_customers_with_details(p_org_id uuid)
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
    WHERE organization_id = p_org_id
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
  WHERE c.organization_id = p_org_id
  ORDER BY c.created_at DESC;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_customers_with_details(uuid) TO authenticated;