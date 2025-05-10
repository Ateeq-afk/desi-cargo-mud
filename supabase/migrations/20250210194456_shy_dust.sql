-- Create audit_logs table
CREATE TABLE audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id),
  action text NOT NULL,
  details jsonb NOT NULL DEFAULT '{}',
  status text NOT NULL CHECK (status IN ('success', 'failure')),
  error_message text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Audit logs viewable by organization members and super admin"
  ON audit_logs
  FOR SELECT
  USING (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization members
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = audit_logs.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Audit logs insertable by authenticated users"
  ON audit_logs
  FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
  );

-- Create indexes
CREATE INDEX idx_audit_logs_organization_id ON audit_logs(organization_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);