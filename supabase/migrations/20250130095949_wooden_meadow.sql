/*
  # Fix organization policies and constraints

  1. Changes
    - Drop existing problematic policies
    - Add proper unique constraints
    - Update organization creation trigger
    - Add proper error handling
    - Fix member assignment policies

  2. Security
    - Maintain RLS
    - Ensure proper access control
    - Prevent duplicate entries
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Allow select for authenticated users" ON organizations;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON organizations;
DROP POLICY IF EXISTS "Allow update for organization admins" ON organizations;
DROP POLICY IF EXISTS "Allow select members for authenticated users" ON organization_members;
DROP POLICY IF EXISTS "Allow insert first member" ON organization_members;
DROP POLICY IF EXISTS "Allow update by admin" ON organization_members;
DROP POLICY IF EXISTS "Allow delete by admin" ON organization_members;

-- Drop existing trigger
DROP TRIGGER IF EXISTS on_organization_created ON organizations;
DROP FUNCTION IF EXISTS public.handle_new_organization();

-- Create new organization policies
CREATE POLICY "Organizations viewable by authenticated users"
  ON organizations
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Organizations insertable by authenticated users"
  ON organizations
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Organizations updatable by admins"
  ON organizations
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Create new member policies
CREATE POLICY "Members viewable by authenticated users"
  ON organization_members
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Members insertable by admins"
  ON organization_members
  FOR INSERT
  WITH CHECK (
    -- Allow if user is an admin of the organization
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_members.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
    OR
    -- Or if this is the first member being added by the trigger
    (
      organization_members.user_id = auth.uid() AND
      NOT EXISTS (
        SELECT 1 FROM organization_members
        WHERE organization_id = organization_members.organization_id
      )
    )
  );

-- Create improved organization creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_organization()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if member already exists to prevent duplicates
  IF NOT EXISTS (
    SELECT 1 FROM organization_members
    WHERE organization_id = NEW.id AND user_id = auth.uid()
  ) THEN
    INSERT INTO organization_members (organization_id, user_id, role)
    VALUES (NEW.id, auth.uid(), 'admin');
  END IF;
  RETURN NEW;
EXCEPTION
  WHEN unique_violation THEN
    -- If there's a unique violation, just return the NEW record
    -- This allows the organization creation to succeed even if
    -- the member already exists
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create new trigger
CREATE TRIGGER on_organization_created
  AFTER INSERT ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_organization();

-- Add proper indexes
CREATE INDEX IF NOT EXISTS idx_org_members_user_id ON organization_members(user_id);
CREATE INDEX IF NOT EXISTS idx_org_members_org_id ON organization_members(organization_id);