/*
  # Update Organization Name

  1. Changes
    - Add display_name column to organizations table
    - Update existing organizations to use display_name
    - Make display_name required for new organizations
*/

-- Add display_name column
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS display_name text;

-- Update existing organizations to use "FastTrack Logistics" as display_name
UPDATE organizations SET display_name = 'FastTrack Logistics' WHERE display_name IS NULL;

-- Make display_name required for new organizations
ALTER TABLE organizations ALTER COLUMN display_name SET NOT NULL;

-- Add index for display_name
CREATE INDEX IF NOT EXISTS idx_organizations_display_name ON organizations(display_name);