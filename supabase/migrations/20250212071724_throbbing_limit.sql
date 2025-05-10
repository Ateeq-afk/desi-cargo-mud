-- Drop existing branch_users table if it exists
DROP TABLE IF EXISTS branch_users CASCADE;

-- Create branch_users table
CREATE TABLE branch_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id uuid REFERENCES branches(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('admin', 'operator')),
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
CREATE POLICY "branch_users_select"
  ON branch_users
  FOR SELECT
  USING (
    -- Allow admins to see all users
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
    OR
    -- Allow users to see themselves
    user_id = auth.uid()
  );

CREATE POLICY "branch_users_insert"
  ON branch_users
  FOR INSERT
  WITH CHECK (
    -- Only admins can add users
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );

CREATE POLICY "branch_users_update"
  ON branch_users
  FOR UPDATE
  USING (
    -- Only admins can update users
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );

CREATE POLICY "branch_users_delete"
  ON branch_users
  FOR DELETE
  USING (
    -- Only admins can delete users
    EXISTS (
      SELECT 1 FROM branch_users
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Create function to get current user's role and branch
CREATE OR REPLACE FUNCTION get_current_user_role()
RETURNS TABLE (
  is_admin boolean,
  branch_id uuid
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    role = 'admin' as is_admin,
    bu.branch_id
  FROM branch_users bu
  WHERE bu.user_id = auth.uid()
  LIMIT 1;
END;
$$;

-- Create indexes
CREATE INDEX idx_branch_users_user_id ON branch_users(user_id);
CREATE INDEX idx_branch_users_branch_id ON branch_users(branch_id);
CREATE INDEX idx_branch_users_role ON branch_users(role);

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_current_user_role TO authenticated;