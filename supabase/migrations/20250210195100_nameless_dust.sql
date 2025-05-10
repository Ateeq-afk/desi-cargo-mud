-- Drop existing organization policies
DROP POLICY IF EXISTS "Allow super admin and members to view organizations" ON organizations;
DROP POLICY IF EXISTS "Allow super admin and members to insert organizations" ON organizations;
DROP POLICY IF EXISTS "Allow super admin and org admins to update organizations" ON organizations;
DROP POLICY IF EXISTS "Allow super admin to delete organizations" ON organizations;

-- Create simplified organization policies
CREATE POLICY "organizations_select_policy"
  ON organizations
  FOR SELECT
  USING (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization members
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "organizations_insert_policy"
  ON organizations
  FOR INSERT
  WITH CHECK (
    -- Allow any authenticated user to create an organization
    auth.uid() IS NOT NULL
  );

CREATE POLICY "organizations_update_policy"
  ON organizations
  FOR UPDATE
  USING (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization admins
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

CREATE POLICY "organizations_delete_policy"
  ON organizations
  FOR DELETE
  USING (
    -- Only super admin can delete organizations
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
  );

-- Create function to handle organization creation
CREATE OR REPLACE FUNCTION handle_new_organization()
RETURNS TRIGGER AS $$
BEGIN
  -- Add creator as admin member
  INSERT INTO organization_members (organization_id, user_id, role)
  VALUES (NEW.id, auth.uid(), 'admin')
  ON CONFLICT (organization_id, user_id) DO NOTHING;
  
  -- Initialize usage data
  UPDATE organizations 
  SET usage_data = jsonb_build_object(
    'bookings_count', 0,
    'storage_used', 0,
    'api_calls', 0,
    'users_count', 1
  )
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create or replace the trigger
DROP TRIGGER IF EXISTS on_organization_created ON organizations;
CREATE TRIGGER on_organization_created
  AFTER INSERT ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_organization();