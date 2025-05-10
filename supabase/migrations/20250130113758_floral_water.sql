-- Create branch_users table
CREATE TABLE branch_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id uuid REFERENCES branches(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('manager', 'supervisor', 'operator')),
  name text NOT NULL,
  email text NOT NULL,
  phone text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(branch_id, user_id)
);

-- Enable RLS
ALTER TABLE branch_users ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Branch users are viewable by organization members"
  ON branch_users
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organization_members om
      JOIN branches b ON b.organization_id = om.organization_id
      WHERE b.id = branch_users.branch_id
      AND om.user_id = auth.uid()
    )
  );

CREATE POLICY "Branch users are manageable by organization admins"
  ON branch_users
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM organization_members om
      JOIN branches b ON b.organization_id = om.organization_id
      WHERE b.id = branch_users.branch_id
      AND om.user_id = auth.uid()
      AND om.role = 'admin'
    )
  );

-- Create indexes
CREATE INDEX idx_branch_users_branch_id ON branch_users(branch_id);
CREATE INDEX idx_branch_users_user_id ON branch_users(user_id);