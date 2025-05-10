-- Add client_code to organizations
ALTER TABLE organizations 
ADD COLUMN IF NOT EXISTS client_code text UNIQUE;

-- Create function to generate client code
CREATE OR REPLACE FUNCTION generate_client_code()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  code text;
  exists boolean;
BEGIN
  LOOP
    -- Generate a 6-character alphanumeric code
    code := upper(substring(md5(random()::text) from 1 for 6));
    
    -- Check if code exists
    SELECT EXISTS (
      SELECT 1 FROM organizations WHERE client_code = code
    ) INTO exists;
    
    -- Exit loop if code is unique
    EXIT WHEN NOT exists;
  END LOOP;
  
  RETURN code;
END;
$$;

-- Add trigger to automatically generate client code
CREATE OR REPLACE FUNCTION set_client_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.client_code IS NULL THEN
    NEW.client_code := generate_client_code();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_client_code
  BEFORE INSERT ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION set_client_code();

-- Create function to get organization by client code
CREATE OR REPLACE FUNCTION get_organization_by_code(code text)
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
  WHERE o.client_code = code;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION generate_client_code TO authenticated;
GRANT EXECUTE ON FUNCTION get_organization_by_code TO authenticated;