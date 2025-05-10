/*
  # Add K2K Logistics Data

  1. Articles
    - Add common logistics articles with base rates
  2. Customers
    - Add initial customers for K2K Logistics
*/

-- First, get the organization ID for K2K Logistics
DO $$ 
DECLARE
  org_id uuid;
BEGIN
  SELECT id INTO org_id FROM organizations WHERE name = 'k2k-logistics' OR slug = 'k2k-logistics' LIMIT 1;
  
  IF org_id IS NOT NULL THEN
    -- Insert articles
    INSERT INTO articles (organization_id, name, description, base_rate) VALUES
      (org_id, 'Cloth Bundle', 'Standard cloth bundles', 100.00),
      (org_id, 'Cloth Box', 'Boxed cloth materials', 150.00),
      (org_id, 'Garments', 'Ready-made garments', 200.00),
      (org_id, 'Fabric Rolls', 'Rolled fabric materials', 180.00),
      (org_id, 'Textile Machinery', 'Textile manufacturing equipment', 500.00),
      (org_id, 'Raw Materials', 'Raw textile materials', 120.00),
      (org_id, 'Accessories', 'Textile accessories and supplies', 80.00),
      (org_id, 'Yarn Boxes', 'Boxes of yarn', 90.00),
      (org_id, 'Sample Pieces', 'Clothing samples', 50.00),
      (org_id, 'Documents', 'Business documents and papers', 30.00)
    ON CONFLICT (organization_id, name) DO UPDATE 
    SET 
      description = EXCLUDED.description,
      base_rate = EXCLUDED.base_rate;

    -- Insert customers
    INSERT INTO customers (organization_id, name, mobile, gst, type) VALUES
      (org_id, 'Textile Hub', '9876543210', 'GSTIN9876543210', 'company'),
      (org_id, 'Fashion World', '9876543211', 'GSTIN9876543211', 'company'),
      (org_id, 'Garment Express', '9876543212', 'GSTIN9876543212', 'company'),
      (org_id, 'Style Solutions', '9876543213', 'GSTIN9876543213', 'company'),
      (org_id, 'Fabric Masters', '9876543214', 'GSTIN9876543214', 'company'),
      (org_id, 'Amit Textiles', '9876543215', 'GSTIN9876543215', 'individual'),
      (org_id, 'Priya Fashion', '9876543216', 'GSTIN9876543216', 'individual'),
      (org_id, 'Kumar Fabrics', '9876543217', 'GSTIN9876543217', 'individual'),
      (org_id, 'Sharma Clothing', '9876543218', 'GSTIN9876543218', 'individual'),
      (org_id, 'Mehta Enterprises', '9876543219', 'GSTIN9876543219', 'company')
    ON CONFLICT (organization_id, mobile) DO UPDATE 
    SET 
      name = EXCLUDED.name,
      gst = EXCLUDED.gst,
      type = EXCLUDED.type;
  END IF;
END $$;