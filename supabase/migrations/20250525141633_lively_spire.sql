-- Add foreign key relationship between ogpl and vehicles tables
DO $$
BEGIN
  -- Check if vehicle_id column exists in ogpl table
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'ogpl' AND column_name = 'vehicle_id'
  ) THEN
    -- Add vehicle_id column if it doesn't exist
    ALTER TABLE ogpl ADD COLUMN vehicle_id UUID;
  END IF;

  -- Add foreign key constraint if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints tc
    JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'ogpl' 
    AND ccu.table_name = 'vehicles'
    AND ccu.column_name = 'id'
  ) THEN
    ALTER TABLE ogpl 
    ADD CONSTRAINT ogpl_vehicle_id_fkey 
    FOREIGN KEY (vehicle_id) 
    REFERENCES vehicles(id);
  END IF;
END $$;

-- Create index on vehicle_id for better query performance
CREATE INDEX IF NOT EXISTS idx_ogpl_vehicle_id ON ogpl(vehicle_id);

-- Update the useUnloading hook to use the correct relationship
COMMENT ON CONSTRAINT ogpl_vehicle_id_fkey ON ogpl IS 'Relationship between OGPL and vehicles';