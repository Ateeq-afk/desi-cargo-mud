/*
  # Booking Management Schema

  1. New Tables
    - `customers`
      - Customer information
      - Contact details
      - GST information
    - `articles`
      - Article types and rates
    - `routes`
      - Route information
    - `bookings` (LR)
      - Basic booking information
      - Customer details
      - Article details
      - Payment information
    - `ogpl`
      - Loading sheet details
      - Vehicle and driver information
      - Route information
    - `loading_records`
      - Loading operation details
    - `unloading_records`
      - Unloading operation details

  2. Security
    - Enable RLS on all tables
    - Add policies for organization-based access
*/

-- Create customers table
CREATE TABLE customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  mobile text NOT NULL,
  gst text,
  type text NOT NULL CHECK (type IN ('individual', 'company')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, mobile)
);

-- Create articles table
CREATE TABLE articles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  base_rate numeric(10,2) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, name)
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

-- Create routes table
CREATE TABLE routes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, name)
);

-- Create bookings (LR) table
CREATE TABLE bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
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
  UNIQUE(organization_id, lr_number)
);

-- Create OGPL table
CREATE TABLE ogpl (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  ogpl_number text NOT NULL,
  name text NOT NULL,
  vehicle_id uuid REFERENCES vehicles(id),
  transit_mode text NOT NULL CHECK (transit_mode IN ('direct', 'hub', 'local')),
  route_id uuid REFERENCES routes(id),
  transit_date date NOT NULL,
  from_station uuid REFERENCES branches(id),
  to_station uuid REFERENCES branches(id),
  departure_time time NOT NULL,
  arrival_time time NOT NULL,
  supervisor_name text NOT NULL,
  supervisor_mobile text NOT NULL,
  primary_driver_name text NOT NULL,
  primary_driver_mobile text NOT NULL,
  secondary_driver_name text,
  secondary_driver_mobile text,
  via_stations uuid[] DEFAULT '{}',
  hub_load_stations uuid[] DEFAULT '{}',
  local_transit_station uuid REFERENCES branches(id),
  remarks text,
  status text NOT NULL DEFAULT 'created' CHECK (status IN ('created', 'in_transit', 'completed', 'cancelled')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, ogpl_number)
);

-- Create loading_records table
CREATE TABLE loading_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  ogpl_id uuid REFERENCES ogpl(id),
  booking_id uuid REFERENCES bookings(id),
  loaded_at timestamptz NOT NULL DEFAULT now(),
  loaded_by uuid REFERENCES auth.users(id),
  remarks text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create unloading_records table
CREATE TABLE unloading_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  ogpl_id uuid REFERENCES ogpl(id),
  booking_id uuid REFERENCES bookings(id),
  unloaded_at timestamptz NOT NULL DEFAULT now(),
  unloaded_by uuid REFERENCES auth.users(id),
  condition_status text NOT NULL DEFAULT 'good' CHECK (condition_status IN ('good', 'damaged', 'missing')),
  damage_remarks text,
  remarks text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_article_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE ogpl ENABLE ROW LEVEL SECURITY;
ALTER TABLE loading_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE unloading_records ENABLE ROW LEVEL SECURITY;

-- Create policies for customers
CREATE POLICY "Customers are viewable by organization members"
  ON customers
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Customers are manageable by organization members"
  ON customers
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = customers.organization_id
      AND user_id = auth.uid()
    )
  );

-- Create policies for articles
CREATE POLICY "Articles are viewable by organization members"
  ON articles
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = articles.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Articles are manageable by organization members"
  ON articles
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = articles.organization_id
      AND user_id = auth.uid()
    )
  );

-- Create policies for customer_article_rates
CREATE POLICY "Customer article rates are viewable by organization members"
  ON customer_article_rates
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organization_members om
      JOIN customers c ON c.organization_id = om.organization_id
      WHERE c.id = customer_article_rates.customer_id
      AND om.user_id = auth.uid()
    )
  );

CREATE POLICY "Customer article rates are manageable by organization members"
  ON customer_article_rates
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM organization_members om
      JOIN customers c ON c.organization_id = om.organization_id
      WHERE c.id = customer_article_rates.customer_id
      AND om.user_id = auth.uid()
    )
  );

-- Create policies for routes
CREATE POLICY "Routes are viewable by organization members"
  ON routes
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = routes.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Routes are manageable by organization members"
  ON routes
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = routes.organization_id
      AND user_id = auth.uid()
    )
  );

-- Create policies for bookings
CREATE POLICY "Bookings are viewable by organization members"
  ON bookings
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = bookings.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Bookings are manageable by organization members"
  ON bookings
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = bookings.organization_id
      AND user_id = auth.uid()
    )
  );

-- Create policies for OGPL
CREATE POLICY "OGPL is viewable by organization members"
  ON ogpl
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = ogpl.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "OGPL is manageable by organization members"
  ON ogpl
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = ogpl.organization_id
      AND user_id = auth.uid()
    )
  );

-- Create policies for loading records
CREATE POLICY "Loading records are viewable by organization members"
  ON loading_records
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = loading_records.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Loading records are manageable by organization members"
  ON loading_records
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = loading_records.organization_id
      AND user_id = auth.uid()
    )
  );

-- Create policies for unloading records
CREATE POLICY "Unloading records are viewable by organization members"
  ON unloading_records
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = unloading_records.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Unloading records are manageable by organization members"
  ON unloading_records
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = unloading_records.organization_id
      AND user_id = auth.uid()
    )
  );

-- Create indexes
CREATE INDEX idx_customers_organization_id ON customers(organization_id);
CREATE INDEX idx_customers_mobile ON customers(mobile);
CREATE INDEX idx_customers_type ON customers(type);

CREATE INDEX idx_articles_organization_id ON articles(organization_id);
CREATE INDEX idx_articles_name ON articles(name);

CREATE INDEX idx_customer_article_rates_customer_id ON customer_article_rates(customer_id);
CREATE INDEX idx_customer_article_rates_article_id ON customer_article_rates(article_id);

CREATE INDEX idx_routes_organization_id ON routes(organization_id);
CREATE INDEX idx_routes_name ON routes(name);

CREATE INDEX idx_bookings_organization_id ON bookings(organization_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_payment_type ON bookings(payment_type);
CREATE INDEX idx_bookings_sender_id ON bookings(sender_id);
CREATE INDEX idx_bookings_receiver_id ON bookings(receiver_id);

CREATE INDEX idx_ogpl_organization_id ON ogpl(organization_id);
CREATE INDEX idx_ogpl_vehicle_id ON ogpl(vehicle_id);
CREATE INDEX idx_ogpl_status ON ogpl(status);
CREATE INDEX idx_ogpl_transit_date ON ogpl(transit_date);

CREATE INDEX idx_loading_records_organization_id ON loading_records(organization_id);
CREATE INDEX idx_loading_records_ogpl_id ON loading_records(ogpl_id);
CREATE INDEX idx_loading_records_booking_id ON loading_records(booking_id);

CREATE INDEX idx_unloading_records_organization_id ON unloading_records(organization_id);
CREATE INDEX idx_unloading_records_ogpl_id ON unloading_records(ogpl_id);
CREATE INDEX idx_unloading_records_booking_id ON unloading_records(booking_id);