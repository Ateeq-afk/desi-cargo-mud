/*
  # Create vehicles table

  1. New Tables
    - `vehicles`
      - `id` (uuid, primary key)
      - `organization_id` (uuid, foreign key)
      - `vehicle_number` (text)
      - `type` (text) - own/hired/attached
      - `make` (text)
      - `model` (text)
      - `year` (integer)
      - `status` (text) - active/maintenance/inactive
      - `last_maintenance_date` (timestamptz)
      - `next_maintenance_date` (timestamptz)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `vehicles` table
    - Add policies for organization members to view vehicles
    - Add policies for organization admins to manage vehicles
*/

-- Create vehicles table
CREATE TABLE vehicles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  vehicle_number text NOT NULL,
  type text NOT NULL CHECK (type IN ('own', 'hired', 'attached')),
  make text,
  model text,
  year integer,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'inactive')),
  last_maintenance_date timestamptz,
  next_maintenance_date timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, vehicle_number)
);

-- Enable RLS
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Vehicles are viewable by organization members"
  ON vehicles
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = vehicles.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Vehicles are manageable by organization admins"
  ON vehicles
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = vehicles.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Create indexes
CREATE INDEX idx_vehicles_organization_id ON vehicles(organization_id);
CREATE INDEX idx_vehicles_status ON vehicles(status);
CREATE INDEX idx_vehicles_type ON vehicles(type);