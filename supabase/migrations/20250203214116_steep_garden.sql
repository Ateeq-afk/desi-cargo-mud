-- Drop existing customer policies
DROP POLICY IF EXISTS "Customers viewable by organization members and super admin" ON customers;
DROP POLICY IF EXISTS "Customers manageable by organization admins and super admin" ON customers;

-- Create new, more permissive policies
CREATE POLICY "customers_select_policy"
  ON customers
  FOR SELECT
  USING (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization members
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "customers_insert_policy"
  ON customers
  FOR INSERT
  WITH CHECK (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization members
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "customers_update_policy"
  ON customers
  FOR UPDATE
  USING (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization members
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "customers_delete_policy"
  ON customers
  FOR DELETE
  USING (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization admins
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Drop and recreate validation trigger with more lenient rules
DROP TRIGGER IF EXISTS validate_customer_data ON customers;
DROP FUNCTION IF EXISTS validate_customer_data();

CREATE OR REPLACE FUNCTION validate_customer_data()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate mobile number format (more lenient)
  IF NEW.mobile !~ '^[0-9+]{10,15}$' THEN
    RAISE EXCEPTION 'Invalid mobile number format. Must be 10-15 digits.';
  END IF;

  -- Validate GST format if provided (more lenient)
  IF NEW.gst IS NOT NULL AND NEW.gst !~ '^[0-9A-Z]{15}$' THEN
    RAISE EXCEPTION 'Invalid GST number format. Must be 15 characters.';
  END IF;

  -- Validate customer type
  IF NEW.type NOT IN ('individual', 'company') THEN
    RAISE EXCEPTION 'Invalid customer type. Must be individual or company.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_customer_data
  BEFORE INSERT OR UPDATE ON customers
  FOR EACH ROW
  EXECUTE FUNCTION validate_customer_data();