-- First drop existing foreign key constraints if they exist
DO $$ 
BEGIN
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

-- Drop existing indexes if they exist
DROP INDEX IF EXISTS idx_bookings_sender_id;
DROP INDEX IF EXISTS idx_bookings_receiver_id;

-- Add or update the columns
ALTER TABLE bookings 
DROP COLUMN IF EXISTS sender_id,
DROP COLUMN IF EXISTS receiver_id;

ALTER TABLE bookings 
ADD COLUMN sender_id uuid REFERENCES customers(id) ON DELETE RESTRICT,
ADD COLUMN receiver_id uuid REFERENCES customers(id) ON DELETE RESTRICT;

-- Create new indexes
CREATE INDEX idx_bookings_sender_id ON bookings(sender_id);
CREATE INDEX idx_bookings_receiver_id ON bookings(receiver_id);