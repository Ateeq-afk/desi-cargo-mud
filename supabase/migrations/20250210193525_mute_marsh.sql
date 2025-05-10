-- Create function to clean up data
CREATE OR REPLACE FUNCTION cleanup_organization_data(org_id uuid)
RETURNS void
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Delete all bookings for the organization
  DELETE FROM bookings 
  WHERE organization_id = org_id;

  -- Reset organization usage data
  UPDATE organizations 
  SET usage_data = jsonb_build_object(
    'bookings_count', 0,
    'storage_used', 0,
    'api_calls', 0,
    'users_count', 0
  )
  WHERE id = org_id;

  -- Verify customer data integrity
  UPDATE customers
  SET branch_id = NULL
  WHERE organization_id = org_id
  AND branch_id NOT IN (
    SELECT id FROM branches WHERE organization_id = org_id
  );

  -- Clean up orphaned customer article rates
  DELETE FROM customer_article_rates car
  WHERE NOT EXISTS (
    SELECT 1 FROM customers c
    WHERE c.id = car.customer_id
    AND c.organization_id = org_id
  );
END;
$$;

-- Create function to validate organization data
CREATE OR REPLACE FUNCTION validate_organization_data(org_id uuid)
RETURNS TABLE (
  issue_type text,
  issue_description text,
  affected_records int
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check for customers without valid branches
  RETURN QUERY
  SELECT 
    'Invalid Branch Reference'::text,
    'Customers referencing non-existent branches'::text,
    COUNT(*)::int
  FROM customers c
  WHERE c.organization_id = org_id
  AND c.branch_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM branches b
    WHERE b.id = c.branch_id
    AND b.organization_id = org_id
  );

  -- Check for orphaned customer article rates
  RETURN QUERY
  SELECT 
    'Orphaned Article Rates'::text,
    'Article rates without valid customers'::text,
    COUNT(*)::int
  FROM customer_article_rates car
  WHERE EXISTS (
    SELECT 1 FROM customers c
    WHERE c.id = car.customer_id
    AND c.organization_id = org_id
  )
  AND NOT EXISTS (
    SELECT 1 FROM articles a
    WHERE a.id = car.article_id
    AND a.organization_id = org_id
  );

  -- Check for invalid article references
  RETURN QUERY
  SELECT 
    'Invalid Article Reference'::text,
    'Bookings referencing non-existent articles'::text,
    COUNT(*)::int
  FROM bookings b
  WHERE b.organization_id = org_id
  AND NOT EXISTS (
    SELECT 1 FROM articles a
    WHERE a.id = b.article_id
    AND a.organization_id = org_id
  );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION cleanup_organization_data TO authenticated;
GRANT EXECUTE ON FUNCTION validate_organization_data TO authenticated;