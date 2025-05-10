/*
  # Subscription System Implementation

  1. New Tables
    - `subscription_plans`
      - Defines available subscription tiers
      - Includes limits and features
    - `organization_subscriptions`
      - Links organizations to their subscription plans
      - Tracks billing and usage

  2. Security
    - Enable RLS on all tables
    - Add policies for access control

  3. Changes
    - Add usage tracking columns to organizations
*/

-- Create subscription plans table
CREATE TABLE subscription_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  code text UNIQUE NOT NULL,
  description text,
  price numeric(10,2) NOT NULL,
  billing_period text NOT NULL CHECK (billing_period IN ('monthly', 'yearly')),
  features jsonb NOT NULL DEFAULT '{}',
  limits jsonb NOT NULL DEFAULT '{}',
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create organization subscriptions table
CREATE TABLE organization_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  plan_id uuid REFERENCES subscription_plans(id),
  status text NOT NULL CHECK (status IN ('active', 'cancelled', 'past_due', 'trialing')),
  current_period_start timestamptz NOT NULL,
  current_period_end timestamptz NOT NULL,
  cancel_at_period_end boolean NOT NULL DEFAULT false,
  trial_start timestamptz,
  trial_end timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id)
);

-- Add usage tracking to organizations
ALTER TABLE organizations 
ADD COLUMN IF NOT EXISTS usage_data jsonb DEFAULT '{
  "bookings_count": 0,
  "storage_used": 0,
  "api_calls": 0,
  "users_count": 0
}';

-- Enable RLS
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_subscriptions ENABLE ROW LEVEL SECURITY;

-- Create policies for subscription_plans
CREATE POLICY "subscription_plans_viewable_by_authenticated_users" ON subscription_plans
  FOR SELECT
  USING (
    auth.role() = 'authenticated' AND is_active = true
  );

CREATE POLICY "subscription_plans_manageable_by_super_admin" ON subscription_plans
  FOR ALL
  USING (
    (SELECT email = 'tabateeq@gmail.com' FROM auth.users WHERE id = auth.uid())
  );

-- Create policies for organization_subscriptions
CREATE POLICY "organization_subscriptions_viewable_by_members" ON organization_subscriptions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_subscriptions.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "organization_subscriptions_manageable_by_admins" ON organization_subscriptions
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_subscriptions.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Create indexes
CREATE INDEX idx_subscription_plans_code ON subscription_plans(code);
CREATE INDEX idx_subscription_plans_active ON subscription_plans(is_active);
CREATE INDEX idx_organization_subscriptions_organization_id ON organization_subscriptions(organization_id);
CREATE INDEX idx_organization_subscriptions_plan_id ON organization_subscriptions(plan_id);
CREATE INDEX idx_organization_subscriptions_status ON organization_subscriptions(status);

-- Insert default plans
INSERT INTO subscription_plans (name, code, description, price, billing_period, features, limits) VALUES
  (
    'Free',
    'free',
    'Basic logistics management for small businesses',
    0,
    'monthly',
    '{"bookings": true, "customers": true, "basic_reports": true}',
    '{"bookings_per_month": 50, "storage_gb": 1, "users": 2}'
  ),
  (
    'Pro',
    'pro',
    'Advanced features for growing businesses',
    2999,
    'monthly',
    '{
      "bookings": true,
      "customers": true,
      "basic_reports": true,
      "advanced_reports": true,
      "api_access": true,
      "priority_support": true
    }',
    '{
      "bookings_per_month": 500,
      "storage_gb": 10,
      "users": 10,
      "api_calls_per_month": 10000
    }'
  ),
  (
    'Enterprise',
    'enterprise',
    'Unlimited features for large organizations',
    9999,
    'monthly',
    '{
      "bookings": true,
      "customers": true,
      "basic_reports": true,
      "advanced_reports": true,
      "api_access": true,
      "priority_support": true,
      "custom_integrations": true,
      "dedicated_support": true
    }',
    '{
      "bookings_per_month": -1,
      "storage_gb": 100,
      "users": -1,
      "api_calls_per_month": -1
    }'
  );

-- Create function to check subscription limits
CREATE OR REPLACE FUNCTION check_subscription_limit(
  org_id uuid,
  limit_name text
)
RETURNS boolean
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  subscription record;
  plan record;
  current_usage jsonb;
  limit_value int;
BEGIN
  -- Get organization's subscription
  SELECT * INTO subscription
  FROM organization_subscriptions
  WHERE organization_id = org_id
  AND status = 'active'
  AND current_period_end > now();

  -- If no active subscription, use free plan limits
  IF subscription.id IS NULL THEN
    SELECT * INTO plan
    FROM subscription_plans
    WHERE code = 'free';
  ELSE
    SELECT * INTO plan
    FROM subscription_plans
    WHERE id = subscription.plan_id;
  END IF;

  -- Get current usage
  SELECT usage_data INTO current_usage
  FROM organizations
  WHERE id = org_id;

  -- Get limit value
  limit_value := (plan.limits->limit_name)::int;

  -- -1 means unlimited
  IF limit_value = -1 THEN
    RETURN true;
  END IF;

  -- Check if within limits
  RETURN (current_usage->limit_name)::int < limit_value;
END;
$$;

-- Create function to increment usage
CREATE OR REPLACE FUNCTION increment_usage(
  org_id uuid,
  usage_type text,
  increment int DEFAULT 1
)
RETURNS void
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE organizations
  SET usage_data = jsonb_set(
    usage_data,
    ARRAY[usage_type],
    to_jsonb((COALESCE((usage_data->>usage_type)::int, 0) + increment)::text)
  )
  WHERE id = org_id;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION check_subscription_limit TO authenticated;
GRANT EXECUTE ON FUNCTION increment_usage TO authenticated;