-- First drop any foreign key constraints if they exist
DO $$ 
BEGIN
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
END $$;

-- Drop tables if they exist
DROP TABLE IF EXISTS customer_article_rates CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- Remove columns from bookings table if they exist
DO $$ 
BEGIN
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