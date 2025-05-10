-- Drop problematic policies first
DROP POLICY IF EXISTS "users_select_policy_v2" ON auth.users;

-- Create secure function to check if user is super admin
CREATE OR REPLACE FUNCTION is_super_admin_v2()
RETURNS boolean
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND email = 'tabateeq@gmail.com'
  );
END;
$$;

-- Create secure function to check organization membership
CREATE OR REPLACE FUNCTION is_organization_member(org_id uuid)
RETURNS boolean
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM organization_members
    WHERE organization_id = org_id
    AND user_id = auth.uid()
  );
END;
$$;

-- Create secure function to check organization admin status
CREATE OR REPLACE FUNCTION is_organization_admin(org_id uuid)
RETURNS boolean
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM organization_members
    WHERE organization_id = org_id
    AND user_id = auth.uid()
    AND role = 'admin'
  );
END;
$$;

-- Update bookings policies
DROP POLICY IF EXISTS "Bookings are viewable by organization members" ON bookings;
DROP POLICY IF EXISTS "Bookings are manageable by organization members" ON bookings;

CREATE POLICY "bookings_select_policy"
  ON bookings
  FOR SELECT
  USING (
    is_super_admin_v2() OR
    is_organization_member(organization_id)
  );

CREATE POLICY "bookings_insert_policy"
  ON bookings
  FOR INSERT
  WITH CHECK (
    is_super_admin_v2() OR
    is_organization_member(organization_id)
  );

CREATE POLICY "bookings_update_policy"
  ON bookings
  FOR UPDATE
  USING (
    is_super_admin_v2() OR
    is_organization_member(organization_id)
  );

CREATE POLICY "bookings_delete_policy"
  ON bookings
  FOR DELETE
  USING (
    is_super_admin_v2() OR
    is_organization_admin(organization_id)
  );

-- Update customers policies
DROP POLICY IF EXISTS "Customers viewable by organization members and super admin" ON customers;
DROP POLICY IF EXISTS "Customers manageable by organization admins and super admin" ON customers;

CREATE POLICY "customers_select_policy"
  ON customers
  FOR SELECT
  USING (
    is_super_admin_v2() OR
    is_organization_member(organization_id)
  );

CREATE POLICY "customers_insert_policy"
  ON customers
  FOR INSERT
  WITH CHECK (
    is_super_admin_v2() OR
    is_organization_member(organization_id)
  );

CREATE POLICY "customers_update_policy"
  ON customers
  FOR UPDATE
  USING (
    is_super_admin_v2() OR
    is_organization_member(organization_id)
  );

CREATE POLICY "customers_delete_policy"
  ON customers
  FOR DELETE
  USING (
    is_super_admin_v2() OR
    is_organization_admin(organization_id)
  );

-- Create secure function to get user details without recursion
CREATE OR REPLACE FUNCTION get_user_details_v2(user_ids uuid[])
RETURNS TABLE (
  id uuid,
  email text,
  role text
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if user is authenticated
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  RETURN QUERY
  WITH user_orgs AS (
    -- Get organizations where current user is admin
    SELECT DISTINCT organization_id
    FROM organization_members
    WHERE user_id = auth.uid()
    AND role = 'admin'
  )
  SELECT 
    u.id,
    u.email::text,
    CASE 
      WHEN u.email = 'tabateeq@gmail.com' THEN 'super_admin'::text
      ELSE 'user'::text
    END as role
  FROM auth.users u
  WHERE u.id = ANY(user_ids)
  AND (
    -- Super admin can see all users
    is_super_admin_v2()
    OR
    -- Users can see themselves
    u.id = auth.uid()
    OR
    -- Organization admins can see their members
    EXISTS (
      SELECT 1 FROM organization_members om
      WHERE om.user_id = u.id
      AND om.organization_id IN (SELECT organization_id FROM user_orgs)
    )
  );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION is_super_admin_v2 TO authenticated;
GRANT EXECUTE ON FUNCTION is_organization_member TO authenticated;
GRANT EXECUTE ON FUNCTION is_organization_admin TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_details_v2 TO authenticated;