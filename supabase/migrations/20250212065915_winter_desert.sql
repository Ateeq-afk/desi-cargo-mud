-- Drop problematic policy
DROP POLICY IF EXISTS "users_select_policy" ON auth.users;

-- Create improved user access policy
CREATE POLICY "users_select_policy_v2"
  ON auth.users
  FOR SELECT
  USING (
    -- Allow super admin
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND email = 'tabateeq@gmail.com'
    )
    OR
    -- Allow users to see themselves
    id = auth.uid()
    OR
    -- Allow organization admins to see their members
    EXISTS (
      SELECT 1 FROM organization_members om1
      WHERE om1.user_id = auth.uid()
      AND om1.role = 'admin'
      AND EXISTS (
        SELECT 1 FROM organization_members om2
        WHERE om2.organization_id = om1.organization_id
        AND om2.user_id = auth.users.id
      )
    )
  );

-- Create secure function to get user details
CREATE OR REPLACE FUNCTION get_user_details(user_ids uuid[])
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
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND email = 'tabateeq@gmail.com'
    )
    OR
    -- Users can see themselves
    u.id = auth.uid()
    OR
    -- Organization admins can see their members
    EXISTS (
      SELECT 1 FROM organization_members om1
      WHERE om1.user_id = auth.uid()
      AND om1.role = 'admin'
      AND EXISTS (
        SELECT 1 FROM organization_members om2
        WHERE om2.organization_id = om1.organization_id
        AND om2.user_id = u.id
      )
    )
  );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_details TO authenticated;