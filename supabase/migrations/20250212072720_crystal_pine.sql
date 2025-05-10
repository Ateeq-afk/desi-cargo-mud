-- Create policies for organizations
CREATE POLICY "organizations_select"
  ON organizations
  FOR SELECT
  USING (
    -- Allow super admin
    is_super_admin()
    OR
    -- Allow branch users to view their organization
    EXISTS (
      SELECT 1 FROM branch_users bu
      JOIN branches b ON b.id = bu.branch_id
      WHERE bu.user_id = auth.uid()
      AND b.organization_id = organizations.id
    )
  );

CREATE POLICY "organizations_insert"
  ON organizations
  FOR INSERT
  WITH CHECK (
    -- Only super admin can create organizations
    is_super_admin()
  );

CREATE POLICY "organizations_update"
  ON organizations
  FOR UPDATE
  USING (
    -- Only super admin can update organizations
    is_super_admin()
  );

-- Create policies for branches
CREATE POLICY "branches_select"
  ON branches
  FOR SELECT
  USING (
    -- Allow super admin
    is_super_admin()
    OR
    -- Allow branch users to view their branch and organization branches
    EXISTS (
      SELECT 1 FROM branch_users bu
      WHERE bu.user_id = auth.uid()
      AND bu.branch_id = branches.id
    )
  );

CREATE POLICY "branches_insert"
  ON branches
  FOR INSERT
  WITH CHECK (
    -- Allow super admin
    is_super_admin()
    OR
    -- Allow branch admins
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );

CREATE POLICY "branches_update"
  ON branches
  FOR UPDATE
  USING (
    -- Allow super admin
    is_super_admin()
    OR
    -- Allow branch admins
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Create policies for customers
CREATE POLICY "customers_select"
  ON customers
  FOR SELECT
  USING (
    -- Allow super admin
    is_super_admin()
    OR
    -- Allow branch users to view their branch customers
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND branch_id = customers.branch_id
    )
  );

CREATE POLICY "customers_insert"
  ON customers
  FOR INSERT
  WITH CHECK (
    -- Allow super admin
    is_super_admin()
    OR
    -- Allow branch users to add customers to their branch
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND branch_id = customers.branch_id
    )
  );

CREATE POLICY "customers_update"
  ON customers
  FOR UPDATE
  USING (
    -- Allow super admin
    is_super_admin()
    OR
    -- Allow branch users to update their branch customers
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND branch_id = customers.branch_id
    )
  );

CREATE POLICY "customers_delete"
  ON customers
  FOR DELETE
  USING (
    -- Allow super admin
    is_super_admin()
    OR
    -- Allow branch admins to delete their branch customers
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND branch_id = customers.branch_id
      AND role = 'admin'
    )
  );

-- Create policies for articles
CREATE POLICY "articles_select"
  ON articles
  FOR SELECT
  USING (
    -- Allow super admin
    is_super_admin()
    OR
    -- Allow branch users to view their branch articles
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND branch_id = articles.branch_id
    )
  );

CREATE POLICY "articles_insert"
  ON articles
  FOR INSERT
  WITH CHECK (
    -- Allow super admin
    is_super_admin()
    OR
    -- Allow branch admins
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND branch_id = articles.branch_id
      AND role = 'admin'
    )
  );

CREATE POLICY "articles_update"
  ON articles
  FOR UPDATE
  USING (
    -- Allow super admin
    is_super_admin()
    OR
    -- Allow branch admins
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND branch_id = articles.branch_id
      AND role = 'admin'
    )
  );

-- Create policies for bookings
CREATE POLICY "bookings_select"
  ON bookings
  FOR SELECT
  USING (
    -- Allow super admin
    is_super_admin()
    OR
    -- Allow branch users to view their branch bookings
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND branch_id = bookings.branch_id
    )
  );

CREATE POLICY "bookings_insert"
  ON bookings
  FOR INSERT
  WITH CHECK (
    -- Allow super admin
    is_super_admin()
    OR
    -- Allow branch users to create bookings
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND branch_id = bookings.branch_id
    )
  );

CREATE POLICY "bookings_update"
  ON bookings
  FOR UPDATE
  USING (
    -- Allow super admin
    is_super_admin()
    OR
    -- Allow branch users to update their bookings
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND branch_id = bookings.branch_id
    )
  );

-- Create helper functions for common operations
CREATE OR REPLACE FUNCTION get_branch_details(branch_id uuid)
RETURNS TABLE (
  id uuid,
  name text,
  code text,
  organization_id uuid,
  organization_name text,
  organization_display_name text
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if user has access to branch
  IF NOT (
    is_super_admin() OR
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND branch_id = $1
    )
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    b.id,
    b.name,
    b.code,
    o.id as organization_id,
    o.name as organization_name,
    o.display_name as organization_display_name
  FROM branches b
  JOIN organizations o ON o.id = b.organization_id
  WHERE b.id = $1;
END;
$$;

-- Create function to get user's permissions
CREATE OR REPLACE FUNCTION get_user_permissions()
RETURNS TABLE (
  is_super_admin boolean,
  is_branch_admin boolean,
  branch_id uuid,
  organization_id uuid
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check super admin first
  IF is_super_admin() THEN
    RETURN QUERY
    SELECT 
      true as is_super_admin,
      true as is_branch_admin,
      NULL::uuid as branch_id,
      NULL::uuid as organization_id;
    RETURN;
  END IF;

  -- Get branch user details
  RETURN QUERY
  SELECT 
    false as is_super_admin,
    bu.role = 'admin' as is_branch_admin,
    bu.branch_id,
    b.organization_id
  FROM branch_users bu
  JOIN branches b ON b.id = bu.branch_id
  WHERE bu.user_id = auth.uid()
  LIMIT 1;

  -- Return default values if no permissions found
  IF NOT FOUND THEN
    RETURN QUERY
    SELECT 
      false as is_super_admin,
      false as is_branch_admin,
      NULL::uuid as branch_id,
      NULL::uuid as organization_id;
  END IF;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_branch_details TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_permissions TO authenticated;