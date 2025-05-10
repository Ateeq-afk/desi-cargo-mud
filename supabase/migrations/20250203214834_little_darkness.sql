-- Drop dependent tables first
DROP TABLE IF EXISTS customer_article_rates CASCADE;

-- Drop existing triggers first
DROP TRIGGER IF EXISTS validate_customer_data ON customers CASCADE;
DROP TRIGGER IF EXISTS update_customer_timestamps ON customers CASCADE;

-- Drop existing functions
DROP FUNCTION IF EXISTS validate_customer_data() CASCADE;
DROP FUNCTION IF EXISTS update_customer_timestamps() CASCADE;
DROP FUNCTION IF EXISTS get_customers_with_details(uuid) CASCADE;

-- Drop existing policies
DROP POLICY IF EXISTS customers_select ON customers CASCADE;
DROP POLICY IF EXISTS customers_insert ON customers CASCADE;
DROP POLICY IF EXISTS customers_update ON customers CASCADE;
DROP POLICY IF EXISTS customers_delete ON customers CASCADE;

-- Drop existing table if it exists
DROP TABLE IF EXISTS customers CASCADE;

-- Create the customers table
CREATE TABLE customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  branch_id uuid REFERENCES branches(id),
  name text NOT NULL,
  mobile text NOT NULL,
  gst text,
  type text NOT NULL CHECK (type IN ('individual', 'company')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, mobile)
);

-- Create indexes
CREATE INDEX idx_customers_organization_id ON customers(organization_id);
CREATE INDEX idx_customers_branch_id ON customers(branch_id);
CREATE INDEX idx_customers_mobile ON customers(mobile);
CREATE INDEX idx_customers_type ON customers(type);

-- Enable RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- Create validation function
CREATE FUNCTION validate_customer_data()
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

-- Create timestamp update function
CREATE FUNCTION update_customer_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER validate_customer_data
  BEFORE INSERT OR UPDATE ON customers
  FOR EACH ROW
  EXECUTE FUNCTION validate_customer_data();

CREATE TRIGGER update_customer_timestamps
  BEFORE UPDATE ON customers
  FOR EACH ROW
  EXECUTE FUNCTION update_customer_timestamps();

-- Create function to get customers with details
CREATE FUNCTION get_customers_with_details(p_org_id uuid)
RETURNS TABLE (
  id uuid,
  organization_id uuid,
  name text,
  mobile text,
  gst text,
  type text,
  created_at timestamptz,
  updated_at timestamptz,
  branch_id uuid,
  organization_name text,
  organization_display_name text,
  branch_name text,
  branch_code text
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if user has access to organization
  IF NOT EXISTS (
    SELECT 1 FROM organization_members
    WHERE organization_id = p_org_id
    AND user_id = auth.uid()
  ) AND NOT (
    SELECT email = 'tabateeq@gmail.com'
    FROM auth.users
    WHERE id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    c.id,
    c.organization_id,
    c.name,
    c.mobile,
    c.gst,
    c.type,
    c.created_at,
    c.updated_at,
    c.branch_id,
    o.name as organization_name,
    o.display_name as organization_display_name,
    b.name as branch_name,
    b.code as branch_code
  FROM customers c
  LEFT JOIN organizations o ON o.id = c.organization_id
  LEFT JOIN branches b ON b.id = c.branch_id
  WHERE c.organization_id = p_org_id
  ORDER BY c.created_at DESC;
END;
$$;

-- Create RLS policies
CREATE POLICY customers_select
  ON customers
  FOR SELECT
  USING (
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY customers_insert
  ON customers
  FOR INSERT
  WITH CHECK (
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY customers_update
  ON customers
  FOR UPDATE
  USING (
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY customers_delete
  ON customers
  FOR DELETE
  USING (
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Create customer_article_rates table
CREATE TABLE customer_article_rates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid REFERENCES customers(id) ON DELETE CASCADE,
  article_id uuid REFERENCES articles(id) ON DELETE CASCADE,
  rate numeric(10,2) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(customer_id, article_id)
);

-- Enable RLS for customer_article_rates
ALTER TABLE customer_article_rates ENABLE ROW LEVEL SECURITY;

-- Create policies for customer_article_rates
CREATE POLICY customer_article_rates_select
  ON customer_article_rates
  FOR SELECT
  USING (
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    EXISTS (
      SELECT 1 FROM organization_members om
      JOIN customers c ON c.organization_id = om.organization_id
      WHERE c.id = customer_article_rates.customer_id
      AND om.user_id = auth.uid()
    )
  );

CREATE POLICY customer_article_rates_all
  ON customer_article_rates
  FOR ALL
  USING (
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    EXISTS (
      SELECT 1 FROM organization_members om
      JOIN customers c ON c.organization_id = om.organization_id
      WHERE c.id = customer_article_rates.customer_id
      AND om.user_id = auth.uid()
      AND om.role = 'admin'
    )
  );

-- Create indexes for customer_article_rates
CREATE INDEX idx_customer_article_rates_customer_id ON customer_article_rates(customer_id);
CREATE INDEX idx_customer_article_rates_article_id ON customer_article_rates(article_id);

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_customers_with_details TO authenticated;