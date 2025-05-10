-- First add the columns without constraints
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS sender_id uuid,
ADD COLUMN IF NOT EXISTS receiver_id uuid;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_bookings_sender_id ON bookings(sender_id);
CREATE INDEX IF NOT EXISTS idx_bookings_receiver_id ON bookings(receiver_id);

-- Add foreign key constraints
DO $$ 
BEGIN
  -- Add sender_id foreign key
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.table_constraints 
    WHERE constraint_name = 'bookings_sender_id_fkey'
  ) THEN
    ALTER TABLE bookings 
    ADD CONSTRAINT bookings_sender_id_fkey 
    FOREIGN KEY (sender_id) 
    REFERENCES customers(id)
    ON DELETE RESTRICT;
  END IF;

  -- Add receiver_id foreign key
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.table_constraints 
    WHERE constraint_name = 'bookings_receiver_id_fkey'
  ) THEN
    ALTER TABLE bookings 
    ADD CONSTRAINT bookings_receiver_id_fkey 
    FOREIGN KEY (receiver_id) 
    REFERENCES customers(id)
    ON DELETE RESTRICT;
  END IF;
END $$;