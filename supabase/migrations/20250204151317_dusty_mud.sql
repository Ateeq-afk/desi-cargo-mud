-- Drop existing policies
DROP POLICY IF EXISTS "organization_subscriptions_select" ON organization_subscriptions;
DROP POLICY IF EXISTS "organization_subscriptions_insert" ON organization_subscriptions;
DROP POLICY IF EXISTS "organization_subscriptions_update" ON organization_subscriptions;
DROP POLICY IF EXISTS "organization_subscriptions_delete" ON organization_subscriptions;

-- Create simplified policies for organization_subscriptions
CREATE POLICY "subscriptions_select_policy"
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

CREATE POLICY "subscriptions_insert_policy"
  ON organization_subscriptions
  FOR INSERT
  WITH CHECK (
    -- Allow super admin
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
    OR
    -- Allow organization members to create free subscriptions
    (
      plan_id IN (SELECT id FROM subscription_plans WHERE code = 'free')
      AND EXISTS (
        SELECT 1 FROM organization_members
        WHERE organization_id = organization_subscriptions.organization_id
        AND user_id = auth.uid()
      )
    )
  );

CREATE POLICY "subscriptions_update_policy"
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

-- Create function to initialize free subscription
CREATE OR REPLACE FUNCTION initialize_free_subscription(org_id uuid)
RETURNS organization_subscriptions
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  free_plan_id uuid;
  new_subscription organization_subscriptions;
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

  -- Create subscription
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
  RETURNING * INTO new_subscription;

  RETURN new_subscription;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION initialize_free_subscription TO authenticated;