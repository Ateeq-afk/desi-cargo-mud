-- First drop any existing foreign key constraints
ALTER TABLE bookings 
DROP CONSTRAINT IF EXISTS bookings_sender_id_fkey,
DROP CONSTRAINT IF EXISTS bookings_receiver_id_fkey;

-- Drop existing indexes
DROP INDEX IF EXISTS idx_bookings_sender_id;
DROP INDEX IF EXISTS idx_bookings_receiver_id;

-- Drop columns if they exist
ALTER TABLE bookings 
DROP COLUMN IF EXISTS sender_id,
DROP COLUMN IF EXISTS receiver_id;

-- Add columns with foreign key constraints
ALTER TABLE bookings 
ADD COLUMN sender_id uuid REFERENCES customers(id) ON DELETE RESTRICT,
ADD COLUMN receiver_id uuid REFERENCES customers(id) ON DELETE RESTRICT;

-- Create indexes
CREATE INDEX idx_bookings_sender_id ON bookings(sender_id);
CREATE INDEX idx_bookings_receiver_id ON bookings(receiver_id);