/*
  # Add Organization Trigger
  
  1. Changes
    - Add function to automatically add organization creator as admin
    - Add trigger to call function on organization creation
    - Add policies for organization management
*/

-- Create function to add organization creator as admin
CREATE OR REPLACE FUNCTION public.handle_new_organization()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.organization_members (organization_id, user_id, role)
  VALUES (NEW.id, auth.uid(), 'admin');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically add creator as admin
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'on_organization_created'
  ) THEN
    CREATE TRIGGER on_organization_created
      AFTER INSERT ON public.organizations
      FOR EACH ROW
      EXECUTE FUNCTION public.handle_new_organization();
  END IF;
END $$;

-- Update organization members policies
CREATE POLICY "First member can be created by trigger"
  ON organization_members
  FOR INSERT
  WITH CHECK (
    (SELECT COUNT(*) FROM organization_members WHERE organization_id = organization_members.organization_id) = 0
    OR
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organization_members.organization_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );