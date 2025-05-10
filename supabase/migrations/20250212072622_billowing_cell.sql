-- Drop all existing tables and functions
DO $$ 
BEGIN
  -- Drop tables in correct order
  DROP TABLE IF EXISTS unloading_records CASCADE;
  DROP TABLE IF EXISTS loading_records CASCADE;
  DROP TABLE IF EXISTS ogpl CASCADE;
  DROP TABLE IF EXISTS bookings CASCADE;
  DROP TABLE IF EXISTS customer_article_rates CASCADE;
  DROP TABLE IF EXISTS articles CASCADE;
  DROP TABLE IF EXISTS customers CASCADE;
  DROP TABLE IF EXISTS branch_users CASCADE;
  DROP TABLE IF EXISTS branches CASCADE;
  DROP TABLE IF EXISTS organization_members CASCADE;
  DROP TABLE IF EXISTS organizations CASCADE;
  
  -- Drop functions
  DROP FUNCTION IF EXISTS is_super_admin CASCADE;
  DROP FUNCTION IF EXISTS get_current_user_role CASCADE;
  DROP FUNCTION IF EXISTS is_admin CASCADE;
  DROP FUNCTION IF EXISTS is_branch_operator CASCADE;
  DROP FUNCTION IF EXISTS get_user_branch CASCADE;
END $$;

-- Create organizations table
CREATE TABLE organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  display_name text NOT NULL,
  client_code text UNIQUE,
  settings jsonb DEFAULT '{}',
  usage_data jsonb DEFAULT '{
    "bookings_count": 0,
    "storage_used": 0,
    "api_calls": 0,
    "users_count": 0
  }',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create branches table
CREATE TABLE branches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  code text NOT NULL,
  address text,
  city text NOT NULL,
  state text NOT NULL,
  pincode text,
  phone text,
  email text,
  is_head_office boolean DEFAULT false,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'maintenance')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, code)
);

-- Create branch_users table
CREATE TABLE branch_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id uuid REFERENCES branches(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('admin', 'operator')),
  name text NOT NULL,
  email text NOT NULL,
  phone text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(branch_id, user_id)
);

-- Create customers table
CREATE TABLE customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id uuid REFERENCES branches(id),
  name text NOT NULL,
  mobile text NOT NULL,
  gst text,
  type text NOT NULL CHECK (type IN ('individual', 'company')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(branch_id, mobile)
);

-- Create articles table
CREATE TABLE articles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id uuid REFERENCES branches(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  base_rate numeric(10,2) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(branch_id, name)
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

-- Create bookings table
CREATE TABLE bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id uuid REFERENCES branches(id),
  lr_number text NOT NULL,
  lr_type text NOT NULL CHECK (lr_type IN ('system', 'manual')),
  manual_lr_number text,
  from_branch uuid REFERENCES branches(id),
  to_branch uuid REFERENCES branches(id),
  sender_id uuid REFERENCES customers(id),
  receiver_id uuid REFERENCES customers(id),
  article_id uuid REFERENCES articles(id),
  description text,
  uom text NOT NULL,
  actual_weight numeric(10,2) DEFAULT 0,
  quantity integer NOT NULL DEFAULT 1,
  freight_per_qty numeric(10,2) NOT NULL DEFAULT 0,
  loading_charges numeric(10,2) DEFAULT 0,
  unloading_charges numeric(10,2) DEFAULT 0,
  total_amount numeric(10,2) GENERATED ALWAYS AS (
    (quantity * freight_per_qty) + loading_charges + unloading_charges
  ) STORED,
  private_mark_number text,
  remarks text,
  payment_type text NOT NULL CHECK (payment_type IN ('Quotation', 'To Pay', 'Paid')),
  status text NOT NULL DEFAULT 'booked' CHECK (status IN ('booked', 'in_transit', 'delivered', 'cancelled')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(branch_id, lr_number)
);

-- Enable RLS
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE branch_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_article_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Create function to check if user is super admin
CREATE OR REPLACE FUNCTION is_super_admin()
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

-- Create function to get current user's role
CREATE OR REPLACE FUNCTION get_current_user_role()
RETURNS TABLE (
  is_admin boolean,
  is_super_admin boolean,
  branch_id uuid
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- First check if user is super admin
  IF EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND email = 'tabateeq@gmail.com'
  ) THEN
    RETURN QUERY SELECT 
      true as is_admin,
      true as is_super_admin,
      NULL::uuid as branch_id;
    RETURN;
  END IF;

  -- Otherwise check branch user role
  RETURN QUERY
  SELECT 
    bu.role = 'admin' as is_admin,
    false as is_super_admin,
    bu.branch_id
  FROM branch_users bu
  WHERE bu.user_id = auth.uid()
  LIMIT 1;

  -- If no rows returned, return default values
  IF NOT FOUND THEN
    RETURN QUERY SELECT 
      false as is_admin,
      false as is_super_admin,
      NULL::uuid as branch_id;
  END IF;
END;
$$;

-- Create function to get user's branch
CREATE OR REPLACE FUNCTION get_user_branch()
RETURNS uuid
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  user_branch_id uuid;
BEGIN
  SELECT branch_id INTO user_branch_id
  FROM branch_users
  WHERE user_id = auth.uid()
  LIMIT 1;
  
  RETURN user_branch_id;
END;
$$;

-- Create indexes
CREATE INDEX idx_organizations_name ON organizations(name);
CREATE INDEX idx_organizations_client_code ON organizations(client_code);
CREATE INDEX idx_branches_organization_id ON branches(organization_id);
CREATE INDEX idx_branches_status ON branches(status);
CREATE INDEX idx_branch_users_branch_id ON branch_users(branch_id);
CREATE INDEX idx_branch_users_user_id ON branch_users(user_id);
CREATE INDEX idx_branch_users_role ON branch_users(role);
CREATE INDEX idx_customers_branch_id ON customers(branch_id);
CREATE INDEX idx_customers_mobile ON customers(mobile);
CREATE INDEX idx_articles_branch_id ON articles(branch_id);
CREATE INDEX idx_bookings_branch_id ON bookings(branch_id);
CREATE INDEX idx_bookings_lr_number ON bookings(lr_number);
CREATE INDEX idx_bookings_status ON bookings(status);

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION is_super_admin TO authenticated;
GRANT EXECUTE ON FUNCTION get_current_user_role TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_branch TO authenticated;