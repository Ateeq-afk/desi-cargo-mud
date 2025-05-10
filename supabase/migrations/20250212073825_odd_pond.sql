-- First ensure K2K organization exists
DO $$ 
DECLARE
  k2k_org_id uuid;
BEGIN
  -- Create or update K2K organization
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
  ON CONFLICT (slug) DO UPDATE
  SET 
    display_name = EXCLUDED.display_name,
    client_code = EXCLUDED.client_code
  RETURNING id INTO k2k_org_id;

  -- Delete all other organizations
  DELETE FROM organizations 
  WHERE id != k2k_org_id;

  -- Update all existing branches to belong to K2K
  UPDATE branches 
  SET organization_id = k2k_org_id
  WHERE organization_id != k2k_org_id;
END $$;

-- Create function to get K2K organization
CREATE OR REPLACE FUNCTION get_k2k_organization()
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
  RETURN QUERY
  SELECT 
    o.id,
    o.name,
    o.display_name,
    o.client_code
  FROM organizations o
  WHERE o.slug = 'k2k-logistics'
  LIMIT 1;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_k2k_organization TO authenticated;