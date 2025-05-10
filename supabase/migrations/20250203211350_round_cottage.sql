-- Create customers table
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

-- Enable RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- Create policies for customers
CREATE POLICY "Customers viewable by organization members and super admin"
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

CREATE POLICY "Customers manageable by organization admins and super admin"
  ON customers
  FOR ALL
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

-- Enable RLS
ALTER TABLE customer_article_rates ENABLE ROW LEVEL SECURITY;

-- Create policies for customer_article_rates
CREATE POLICY "Customer article rates viewable by organization members and super admin"
  ON customer_article_rates
  FOR SELECT
  USING (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization members
    EXISTS (
      SELECT 1 FROM organization_members om
      JOIN customers c ON c.organization_id = om.organization_id
      WHERE c.id = customer_article_rates.customer_id
      AND om.user_id = auth.uid()
    )
  );

CREATE POLICY "Customer article rates manageable by organization admins and super admin"
  ON customer_article_rates
  FOR ALL
  USING (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization admins
    EXISTS (
      SELECT 1 FROM organization_members om
      JOIN customers c ON c.organization_id = om.organization_id
      WHERE c.id = customer_article_rates.customer_id
      AND om.user_id = auth.uid()
      AND om.role = 'admin'
    )
  );

-- Create indexes
CREATE INDEX idx_customers_organization_id ON customers(organization_id);
CREATE INDEX idx_customers_branch_id ON customers(branch_id);
CREATE INDEX idx_customers_mobile ON customers(mobile);
CREATE INDEX idx_customers_type ON customers(type);
CREATE INDEX idx_customer_article_rates_customer_id ON customer_article_rates(customer_id);
CREATE INDEX idx_customer_article_rates_article_id ON customer_article_rates(article_id);

-- Create function to get customers with details
CREATE OR REPLACE FUNCTION get_customers_with_details(p_org_id uuid)
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_customers_with_details TO authenticated;