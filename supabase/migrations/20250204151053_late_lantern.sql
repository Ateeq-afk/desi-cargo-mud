-- Drop existing policies
DROP POLICY IF EXISTS "organization_subscriptions_viewable_by_members" ON organization_subscriptions;
DROP POLICY IF EXISTS "organization_subscriptions_manageable_by_admins" ON organization_subscriptions;

-- Create new policies for organization_subscriptions
CREATE POLICY "organization_subscriptions_select"
  ON organization_subscriptions
  FOR SELECT
  USING (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization members
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_subscriptions.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "organization_subscriptions_insert"
  ON organization_subscriptions
  FOR INSERT
  WITH CHECK (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization admins
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_subscriptions.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
    OR
    -- Allow creating free plan subscription
    (
      plan_id IN (SELECT id FROM subscription_plans WHERE code = 'free')
      AND EXISTS (
        SELECT 1 FROM organization_members
        WHERE organization_id = organization_subscriptions.organization_id
        AND user_id = auth.uid()
      )
    )
  );

CREATE POLICY "organization_subscriptions_update"
  ON organization_subscriptions
  FOR UPDATE
  USING (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization admins
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_subscriptions.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

CREATE POLICY "organization_subscriptions_delete"
  ON organization_subscriptions
  FOR DELETE
  USING (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization admins
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_subscriptions.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Create function to get or create free subscription
CREATE OR REPLACE FUNCTION get_or_create_free_subscription(org_id uuid)
RETURNS TABLE (
  id uuid,
  organization_id uuid,
  plan_id uuid,
  status text,
  current_period_start timestamptz,
  current_period_end timestamptz,
  cancel_at_period_end boolean,
  trial_start timestamptz,
  trial_end timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  plan jsonb
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  free_plan_id uuid;
  subscription_record record;
BEGIN
  -- Check if user has access to organization
  IF NOT EXISTS (
    SELECT 1 FROM organization_members
    WHERE organization_id = org_id
    AND user_id = auth.uid()
  ) AND NOT (
    SELECT email = 'tabateeq@gmail.com'
    FROM auth.users
    WHERE id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Get free plan ID
  SELECT id INTO free_plan_id
  FROM subscription_plans
  WHERE code = 'free';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Free plan not found';
  END IF;

  -- Get or create subscription
  INSERT INTO organization_subscriptions (
    organization_id,
    plan_id,
    status,
    current_period_start,
    current_period_end,
    cancel_at_period_end
  )
  VALUES (
    org_id,
    free_plan_id,
    'active',
    now(),
    now() + interval '1 month',
    false
  )
  ON CONFLICT (organization_id) DO NOTHING;

  -- Return subscription with plan details
  RETURN QUERY
  SELECT 
    s.*,
    row_to_json(p.*)::jsonb as plan
  FROM organization_subscriptions s
  LEFT JOIN subscription_plans p ON p.id = s.plan_id
  WHERE s.organization_id = org_id;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_or_create_free_subscription TO authenticated;