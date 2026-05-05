-- Migration 024: Auth signup triggers
-- Automatically create profile and personal workspace on signup

-- NOTE: This migration creates a function that will be called by a trigger on auth.users
-- The trigger itself must be created manually in Supabase Dashboard SQL Editor
-- because regular users don't have permission to create triggers on auth.users

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  new_workspace_id uuid;
BEGIN
  -- Create profile for new user
  INSERT INTO public.profiles (id, email, display_name, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    now(),
    now()
  );

  -- Create personal workspace for new user
  INSERT INTO public.workspaces (name, type, owner_user_id, created_at, updated_at)
  VALUES (
    'My Workspace',
    'personal',
    NEW.id,
    now(),
    now()
  )
  RETURNING id INTO new_workspace_id;

  -- Create owner membership for personal workspace
  INSERT INTO public.workspace_members (
    workspace_id, 
    user_id, 
    role, 
    created_at, 
    updated_at
  )
  VALUES (
    new_workspace_id,
    NEW.id,
    'owner',
    now(),
    now()
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;

-- Comments
COMMENT ON FUNCTION public.handle_new_user IS 'Creates profile, personal workspace, and owner membership on signup. Must be triggered from auth.users via Dashboard.';

-- MANUAL STEP REQUIRED:
-- After running this migration, you MUST manually create the trigger in Supabase Dashboard > SQL Editor:
--
-- CREATE TRIGGER on_auth_user_created
--   AFTER INSERT ON auth.users
--   FOR EACH ROW
--   EXECUTE FUNCTION public.handle_new_user();
