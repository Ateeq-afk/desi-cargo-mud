-- First check if tables exist
DO $$ 
BEGIN
  -- Drop triggers that depend on functions if they exist
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_customer_timestamps') THEN
    DROP TRIGGER IF EXISTS update_customer_timestamps ON customers;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'validate_customer_data') THEN
    DROP TRIGGER IF EXISTS validate_customer_data ON customers;
  END IF;

  -- Drop functions if they exist
  DROP FUNCTION IF EXISTS get_customers_with_details(uuid);
  DROP FUNCTION IF EXISTS update_customer_timestamps();
  DROP FUNCTION IF EXISTS validate_customer_data();

  -- Drop foreign key constraints if they exist
  IF EXISTS (
    SELECT 1 
    FROM information_schema.table_constraints 
    WHERE constraint_name = 'bookings_sender_id_fkey'
  ) THEN
    ALTER TABLE bookings DROP CONSTRAINT bookings_sender_id_fkey;
  END IF;

  IF EXISTS (
    SELECT 1 
    FROM information_schema.table_constraints 
    WHERE constraint_name = 'bookings_receiver_id_fkey'
  ) THEN
    ALTER TABLE bookings DROP CONSTRAINT bookings_receiver_id_fkey;
  END IF;

  -- Drop tables if they exist
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'customer_article_rates') THEN
    DROP TABLE customer_article_rates;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'customers') THEN
    DROP TABLE customers;
  END IF;

  -- Remove columns from bookings table if they exist
  IF EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'bookings' AND column_name = 'sender_id'
  ) THEN
    ALTER TABLE bookings DROP COLUMN sender_id;
  END IF;

  IF EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'bookings' AND column_name = 'receiver_id'
  ) THEN
    ALTER TABLE bookings DROP COLUMN receiver_id;
  END IF;
END $$;