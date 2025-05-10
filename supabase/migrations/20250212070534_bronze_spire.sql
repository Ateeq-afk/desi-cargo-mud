-- Drop existing policies
DROP POLICY IF EXISTS "org_select_policy_v1" ON organizations;
DROP POLICY IF EXISTS "org_insert_policy_v1" ON organizations;
DROP POLICY IF EXISTS "org_update_policy_v1" ON organizations;
DROP POLICY IF EXISTS "org_delete_policy_v1" ON organizations;

-- Create improved organization policies
CREATE POLICY "organizations_select_policy_v3"
  ON organizations
  FOR SELECT
  USING (
    -- Allow all authenticated users to view organizations
    auth.uid() IS NOT NULL
  );

CREATE POLICY "organizations_insert_policy_v3"
  ON organizations
  FOR INSERT
  WITH CHECK (
    -- Allow super admin or first organization creation
    (
      SELECT email = 'tabateeq@gmail.com'
      FROM auth.users
      WHERE id = auth.uid()
    )
    OR
    NOT EXISTS (SELECT 1 FROM organizations)
  );

-- Create function to initialize K2K organization
CREATE OR REPLACE FUNCTION initialize_k2k_organization()
RETURNS void
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  org_id uuid;
BEGIN
  -- Check if K2K organization exists
  IF NOT EXISTS (
    SELECT 1 FROM organizations WHERE name = 'k2k-logistics'
  ) THEN
    -- Create K2K organization
    INSERT INTO organizations (
      name,
      slug,
      display_name,
      client_code
    )
    VALUES (
      'k2k-logistics',
      'k2k-logistics',
      'K2K Logistics',
      'K2KLOG'
    )
    RETURNING id INTO org_id;

    -- Initialize usage data
    UPDATE organizations 
    SET usage_data = jsonb_build_object(
      'bookings_count', 0,
      'storage_used', 0,
      'api_calls', 0,
      'users_count', 0
    )
    WHERE id = org_id;
  END IF;
END;
$$;

-- Create function to get organization by name
CREATE OR REPLACE FUNCTION get_organization_by_name(org_name text)
RETURNS TABLE (
  id uuid,
  name text,
  display_name text,
  client_code text
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Initialize K2K if it doesn't exist
  IF org_name = 'k2k-logistics' THEN
    PERFORM initialize_k2k_organization();
  END IF;

  RETURN QUERY
  SELECT 
    o.id,
    o.name,
    o.display_name,
    o.client_code
  FROM organizations o
  WHERE o.name = org_name;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION initialize_k2k_organization TO authenticated;
GRANT EXECUTE ON FUNCTION get_organization_by_name TO authenticated;

-- Create index for organization lookups
CREATE INDEX IF NOT EXISTS idx_organizations_name ON organizations(name);
CREATE INDEX IF NOT EXISTS idx_organizations_client_code ON organizations(client_code);