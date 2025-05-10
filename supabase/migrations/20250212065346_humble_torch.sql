-- Add function to set custom client code (only for super admin)
CREATE OR REPLACE FUNCTION set_organization_client_code(
  org_id uuid,
  new_code text
)
RETURNS boolean
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if user is super admin
  IF NOT (
    SELECT email = 'tabateeq@gmail.com' 
    FROM auth.users 
    WHERE id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Only super admin can set custom client codes';
  END IF;

  -- Validate code format
  IF new_code !~ '^[A-Z0-9]{6}$' THEN
    RAISE EXCEPTION 'Client code must be 6 alphanumeric characters';
  END IF;

  -- Check if code is already in use
  IF EXISTS (
    SELECT 1 FROM organizations 
    WHERE client_code = new_code 
    AND id != org_id
  ) THEN
    RAISE EXCEPTION 'Client code already in use';
  END IF;

  -- Update organization
  UPDATE organizations 
  SET 
    client_code = new_code,
    updated_at = now()
  WHERE id = org_id;

  RETURN FOUND;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION set_organization_client_code TO authenticated;