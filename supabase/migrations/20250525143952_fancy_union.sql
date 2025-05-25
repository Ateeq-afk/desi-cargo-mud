/*
  # Add loading_records table and relationships

  1. New Tables
    - `loading_records` table
      - `id` (uuid, primary key)
      - `ogpl_id` (uuid, foreign key to ogpl)
      - `booking_id` (uuid, foreign key to bookings)
      - `loaded_at` (timestamptz)
      - `loaded_by` (text)
      - `remarks` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
  2. Relationships
    - Add foreign key from `loading_records.ogpl_id` to `ogpl.id`
    - Add foreign key from `loading_records.booking_id` to `bookings.id`
  3. Indexes
    - Create indexes on foreign key columns for better performance
*/

-- Create loading_records table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.loading_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ogpl_id UUID NOT NULL,
  booking_id UUID NOT NULL,
  loaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  loaded_by TEXT NOT NULL,
  remarks TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT loading_records_ogpl_id_fkey FOREIGN KEY (ogpl_id) REFERENCES ogpl(id) ON DELETE CASCADE,
  CONSTRAINT loading_records_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_loading_records_ogpl_id ON loading_records(ogpl_id);
CREATE INDEX IF NOT EXISTS idx_loading_records_booking_id ON loading_records(booking_id);
CREATE INDEX IF NOT EXISTS idx_loading_records_loaded_at ON loading_records(loaded_at);

-- Add comments for better documentation
COMMENT ON TABLE loading_records IS 'Records of items loaded onto OGPLs';
COMMENT ON COLUMN loading_records.ogpl_id IS 'Reference to the OGPL this loading record belongs to';
COMMENT ON COLUMN loading_records.booking_id IS 'Reference to the booking being loaded';