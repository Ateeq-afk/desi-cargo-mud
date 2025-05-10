-- Initialize K2K Logistics organization
INSERT INTO organizations (name, slug, display_name, client_code)
VALUES (
  'k2k-logistics',
  'k2k-logistics',
  'K2K Logistics',
  'K2KLOG'
)
ON CONFLICT (slug) DO UPDATE
SET 
  display_name = EXCLUDED.display_name,
  client_code = EXCLUDED.client_code
RETURNING id;

-- Create initial branches
WITH org AS (
  SELECT id FROM organizations WHERE slug = 'k2k-logistics'
)
INSERT INTO branches (
  organization_id,
  name,
  code,
  address,
  city,
  state,
  pincode,
  phone,
  email,
  is_head_office,
  status
)
SELECT
  org.id,
  name,
  code,
  address,
  city,
  state,
  pincode,
  phone,
  email,
  is_head_office,
  status
FROM org,
(VALUES
  (
    'Mumbai HQ',
    'MUM-HQ',
    '123 Business Park, Andheri East',
    'Mumbai',
    'Maharashtra',
    '400069',
    '022-12345678',
    'mumbai@k2k.com',
    true,
    'active'
  ),
  (
    'Delhi Branch',
    'DEL-01',
    '456 Industrial Area, Okhla Phase 1',
    'Delhi',
    'Delhi',
    '110020',
    '011-12345678',
    'delhi@k2k.com',
    false,
    'active'
  ),
  (
    'Bangalore Branch',
    'BLR-01',
    '789 Tech Park, Whitefield',
    'Bangalore',
    'Karnataka',
    '560066',
    '080-12345678',
    'bangalore@k2k.com',
    false,
    'active'
  ),
  (
    'Chennai Branch',
    'CHN-01',
    '321 Industrial Estate, Guindy',
    'Chennai',
    'Tamil Nadu',
    '600032',
    '044-12345678',
    'chennai@k2k.com',
    false,
    'active'
  ),
  (
    'Kolkata Branch',
    'KOL-01',
    '654 Business Center, Salt Lake',
    'Kolkata',
    'West Bengal',
    '700091',
    '033-12345678',
    'kolkata@k2k.com',
    false,
    'active'
  )
) AS b(name, code, address, city, state, pincode, phone, email, is_head_office, status)
ON CONFLICT (organization_id, code) DO UPDATE
SET
  name = EXCLUDED.name,
  address = EXCLUDED.address,
  city = EXCLUDED.city,
  state = EXCLUDED.state,
  pincode = EXCLUDED.pincode,
  phone = EXCLUDED.phone,
  email = EXCLUDED.email,
  is_head_office = EXCLUDED.is_head_office,
  status = EXCLUDED.status;

-- Create initial articles for each branch
WITH branches_data AS (
  SELECT b.id as branch_id
  FROM organizations o
  JOIN branches b ON b.organization_id = o.id
  WHERE o.slug = 'k2k-logistics'
)
INSERT INTO articles (
  branch_id,
  name,
  description,
  base_rate
)
SELECT
  branch_id,
  name,
  description,
  base_rate
FROM branches_data,
(VALUES
  ('Cloth Bundle', 'Standard cloth bundles', 100.00),
  ('Cloth Box', 'Boxed cloth materials', 150.00),
  ('Garments', 'Ready-made garments', 200.00),
  ('Fabric Rolls', 'Rolled fabric materials', 180.00),
  ('Textile Machinery', 'Textile manufacturing equipment', 500.00),
  ('Raw Materials', 'Raw textile materials', 120.00),
  ('Accessories', 'Textile accessories and supplies', 80.00),
  ('Yarn Boxes', 'Boxes of yarn', 90.00),
  ('Sample Pieces', 'Clothing samples', 50.00),
  ('Documents', 'Business documents and papers', 30.00)
) AS a(name, description, base_rate)
ON CONFLICT (branch_id, name) DO UPDATE
SET
  description = EXCLUDED.description,
  base_rate = EXCLUDED.base_rate;

-- Create function to initialize branch admin
CREATE OR REPLACE FUNCTION initialize_branch_admin(
  p_branch_id uuid,
  p_email text,
  p_name text,
  p_phone text
)
RETURNS void
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Get user ID from email
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = p_email;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not found with email: %', p_email;
  END IF;

  -- Add user as branch admin
  INSERT INTO branch_users (
    branch_id,
    user_id,
    role,
    name,
    email,
    phone
  )
  VALUES (
    p_branch_id,
    v_user_id,
    'admin',
    p_name,
    p_email,
    p_phone
  )
  ON CONFLICT (branch_id, user_id) DO UPDATE
  SET
    role = 'admin',
    name = EXCLUDED.name,
    phone = EXCLUDED.phone;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION initialize_branch_admin TO authenticated;