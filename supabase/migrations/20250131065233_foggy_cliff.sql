-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS get_user_emails;
DROP FUNCTION IF EXISTS get_user_by_email;

-- Create improved function to get user emails with better error handling
CREATE OR REPLACE FUNCTION get_user_emails(user_ids uuid[])
RETURNS TABLE (id uuid, email text)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  IF array_length(user_ids, 1) IS NULL THEN
    RAISE EXCEPTION 'No user IDs provided';
  END IF;

  RETURN QUERY
  SELECT au.id, au.email::text
  FROM auth.users au
  WHERE au.id = ANY(user_ids)
  ORDER BY au.email;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No users found with the provided IDs';
  END IF;
END;
$$;

-- Create improved function to get user by email with better error handling
CREATE OR REPLACE FUNCTION get_user_by_email(email_address text)
RETURNS TABLE (id uuid, email text)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  IF email_address IS NULL OR email_address = '' THEN
    RAISE EXCEPTION 'Email address is required';
  END IF;

  IF NOT email_address ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
    RAISE EXCEPTION 'Invalid email format';
  END IF;

  RETURN QUERY
  SELECT au.id, au.email::text
  FROM auth.users au
  WHERE au.email = email_address;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found with email: %', email_address;
  END IF;
END;
$$;

-- Create function to check if user can manage organization
CREATE OR REPLACE FUNCTION can_manage_organization(org_id uuid)
RETURNS boolean
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  is_admin boolean;
BEGIN
  -- Check if user is super admin
  IF EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND email = 'tabateeq@gmail.com'
  ) THEN
    RETURN true;
  END IF;

  -- Check if user is organization admin
  SELECT EXISTS (
    SELECT 1 FROM organization_members
    WHERE organization_id = org_id
    AND user_id = auth.uid()
    AND role = 'admin'
  ) INTO is_admin;

  RETURN is_admin;
END;
$$;

-- Create function to add organization member with proper validation
CREATE OR REPLACE FUNCTION add_organization_member(
  org_id uuid,
  member_email text,
  member_role text DEFAULT 'member'
)
RETURNS json
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  new_member_id uuid;
  result json;
BEGIN
  -- Validate inputs
  IF org_id IS NULL THEN
    RAISE EXCEPTION 'Organization ID is required';
  END IF;

  IF member_email IS NULL OR member_email = '' THEN
    RAISE EXCEPTION 'Member email is required';
  END IF;

  IF member_role NOT IN ('admin', 'member') THEN
    RAISE EXCEPTION 'Invalid role: must be either admin or member';
  END IF;

  -- Check if user has permission
  IF NOT can_manage_organization(org_id) THEN
    RAISE EXCEPTION 'Permission denied: must be an organization admin';
  END IF;

  -- Get user ID from email
  SELECT id INTO new_member_id
  FROM get_user_by_email(member_email);

  -- Check if user is already a member
  IF EXISTS (
    SELECT 1 FROM organization_members
    WHERE organization_id = org_id
    AND user_id = new_member_id
  ) THEN
    RAISE EXCEPTION 'User is already a member of this organization';
  END IF;

  -- Add member
  INSERT INTO organization_members (organization_id, user_id, role)
  VALUES (org_id, new_member_id, member_role)
  RETURNING json_build_object(
    'id', id,
    'organization_id', organization_id,
    'user_id', user_id,
    'role', role,
    'created_at', created_at
  ) INTO result;

  RETURN result;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_user_emails TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_by_email TO authenticated;
GRANT EXECUTE ON FUNCTION can_manage_organization TO authenticated;
GRANT EXECUTE ON FUNCTION add_organization_member TO authenticated;