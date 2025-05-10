-- Drop trigger first to remove dependency
DROP TRIGGER IF EXISTS on_organization_created ON organizations CASCADE;

-- Drop existing policies and functions
DROP POLICY IF EXISTS "organizations_select_policy" ON organizations;
DROP POLICY IF EXISTS "organizations_insert_policy" ON organizations;
DROP POLICY IF EXISTS "organizations_update_policy" ON organizations;
DROP POLICY IF EXISTS "organizations_delete_policy" ON organizations;
DROP FUNCTION IF EXISTS handle_new_organization() CASCADE;

-- Create secure function to check if user exists
CREATE OR REPLACE FUNCTION check_user_exists(user_id uuid)
RETURNS boolean
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users WHERE id = user_id
  );
END;
$$;

-- Create secure function to get user email
CREATE OR REPLACE FUNCTION get_user_email(user_id uuid)
RETURNS text
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  user_email text;
BEGIN
  SELECT email INTO user_email
  FROM auth.users
  WHERE id = user_id;
  RETURN user_email;
END;
$$;

-- Create improved organization creation handler
CREATE OR REPLACE FUNCTION handle_new_organization()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  user_exists boolean;
  current_user_id uuid;
BEGIN
  -- Get current user ID
  current_user_id := auth.uid();
  
  -- Check if user exists
  SELECT check_user_exists(current_user_id) INTO user_exists;
  
  IF NOT user_exists THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  -- Add creator as admin member
  INSERT INTO organization_members (
    organization_id,
    user_id,
    role
  )
  VALUES (
    NEW.id,
    current_user_id,
    'admin'
  )
  ON CONFLICT (organization_id, user_id) 
  DO UPDATE SET role = 'admin';
  
  -- Initialize usage data
  UPDATE organizations 
  SET 
    usage_data = jsonb_build_object(
      'bookings_count', 0,
      'storage_used', 0,
      'api_calls', 0,
      'users_count', 1
    ),
    updated_at = now()
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$;

-- Create organization policies
CREATE POLICY "organizations_select"
  ON organizations
  FOR SELECT
  USING (
    -- Allow super admin
    get_user_email(auth.uid()) = 'tabateeq@gmail.com'
    OR
    -- Allow organization members
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "organizations_insert"
  ON organizations
  FOR INSERT
  WITH CHECK (
    -- Allow any authenticated user
    auth.uid() IS NOT NULL
  );

CREATE POLICY "organizations_update"
  ON organizations
  FOR UPDATE
  USING (
    -- Allow super admin
    get_user_email(auth.uid()) = 'tabateeq@gmail.com'
    OR
    -- Allow organization admins
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

CREATE POLICY "organizations_delete"
  ON organizations
  FOR DELETE
  USING (
    -- Only super admin can delete
    get_user_email(auth.uid()) = 'tabateeq@gmail.com'
  );

-- Create trigger for organization creation
CREATE TRIGGER on_organization_created
  AFTER INSERT ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_organization();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION check_user_exists TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_email TO authenticated;
GRANT EXECUTE ON FUNCTION handle_new_organization TO authenticated;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_organization_members_user_role 
ON organization_members(user_id, role);