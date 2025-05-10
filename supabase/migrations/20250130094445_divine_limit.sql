/*
  # Enhance Branches Table

  1. New Fields
    - `status` - Branch operational status
    - `contact_person` - Primary contact person
    - `working_hours` - Branch working hours
    - `location_coordinates` - Geographical coordinates
    - `features` - Branch features/capabilities

  2. Changes
    - Add new fields to branches table
    - Add validation constraints
    - Add indexes for performance
*/

ALTER TABLE branches ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'maintenance'));
ALTER TABLE branches ADD COLUMN IF NOT EXISTS contact_person jsonb;
ALTER TABLE branches ADD COLUMN IF NOT EXISTS working_hours jsonb;
ALTER TABLE branches ADD COLUMN IF NOT EXISTS location_coordinates point;
ALTER TABLE branches ADD COLUMN IF NOT EXISTS features text[] DEFAULT '{}';

-- Add indexes for common queries
CREATE INDEX IF NOT EXISTS idx_branches_status ON branches(status);
CREATE INDEX IF NOT EXISTS idx_branches_city ON branches(city);
CREATE INDEX IF NOT EXISTS idx_branches_state ON branches(state);