-- First disable the trigger
DROP TRIGGER IF EXISTS on_organization_created ON organizations;
DROP FUNCTION IF EXISTS handle_new_organization();

-- Now add test data
INSERT INTO organizations (name, slug, display_name)
VALUES ('k2k-logistics', 'k2k-logistics', 'K2K Logistics')
ON CONFLICT (slug) DO UPDATE 
SET display_name = EXCLUDED.display_name
RETURNING id;

-- Add test articles
INSERT INTO articles (organization_id, name, description, base_rate)
SELECT 
  id,
  unnest(ARRAY['Cloth Bundle', 'Cloth Box', 'Garments', 'Fabric Rolls', 'Textile Machinery']),
  unnest(ARRAY['Standard cloth bundles', 'Boxed cloth materials', 'Ready-made garments', 'Rolled fabric materials', 'Textile manufacturing equipment']),
  unnest(ARRAY[100.00, 150.00, 200.00, 180.00, 500.00])
FROM organizations
WHERE slug = 'k2k-logistics'
ON CONFLICT DO NOTHING;

-- Add test branches
INSERT INTO branches (organization_id, name, code, address, city, state, pincode, phone, email, is_head_office)
SELECT 
  id,
  unnest(ARRAY['Mumbai HQ', 'Delhi Branch', 'Bangalore Branch']),
  unnest(ARRAY['MUM-HQ', 'DEL-01', 'BLR-01']),
  unnest(ARRAY['123 Business Park', '456 Industrial Area', '789 Tech Park']),
  unnest(ARRAY['Mumbai', 'Delhi', 'Bangalore']),
  unnest(ARRAY['Maharashtra', 'Delhi', 'Karnataka']),
  unnest(ARRAY['400001', '110001', '560001']),
  unnest(ARRAY['9876543210', '9876543211', '9876543212']),
  unnest(ARRAY['mumbai@k2k.com', 'delhi@k2k.com', 'bangalore@k2k.com']),
  unnest(ARRAY[true, false, false])
FROM organizations
WHERE slug = 'k2k-logistics'
ON CONFLICT DO NOTHING;