-- Repair missing app-level workspace setup for Supabase auth users.
--
-- Run this file in Supabase SQL Editor when users can sign in but see
-- "Workspace setup is incomplete" because rows are missing from:
--   - public.profiles
--   - public.workspaces
--   - public.workspace_members
--
-- Update the target_user_id below if you want to repair one specific user
-- before or in addition to the full backfill.

BEGIN;

CREATE OR REPLACE FUNCTION public.ensure_workspace_setup_for_user(
  target_user_id uuid,
  target_email text,
  target_raw_user_meta_data jsonb DEFAULT '{}'::jsonb
)
RETURNS void AS $$
DECLARE
  new_workspace_id uuid;
BEGIN
  IF target_user_id IS NULL THEN
    RAISE EXCEPTION 'target_user_id must not be null';
  END IF;

  IF target_email IS NULL OR btrim(target_email) = '' THEN
    RAISE EXCEPTION 'target_email must not be null or empty for user %', target_user_id;
  END IF;

  INSERT INTO public.profiles (
    id,
    email,
    display_name,
    created_at,
    updated_at
  )
  VALUES (
    target_user_id,
    target_email,
    COALESCE(
      NULLIF(target_raw_user_meta_data->>'display_name', ''),
      split_part(target_email, '@', 1),
      'User'
    ),
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    display_name = COALESCE(public.profiles.display_name, EXCLUDED.display_name),
    updated_at = now();

  SELECT w.id
  INTO new_workspace_id
  FROM public.workspaces w
  WHERE w.owner_user_id = target_user_id
    AND w.type = 'personal'
    AND w.deleted_at IS NULL
  ORDER BY w.created_at
  LIMIT 1;

  IF new_workspace_id IS NULL THEN
    INSERT INTO public.workspaces (
      name,
      type,
      owner_user_id,
      created_at,
      updated_at
    )
    VALUES (
      'My Workspace',
      'personal',
      target_user_id,
      now(),
      now()
    )
    RETURNING id INTO new_workspace_id;
  END IF;

  INSERT INTO public.workspace_members (
    workspace_id,
    user_id,
    role,
    membership_status,
    joined_at,
    created_at,
    updated_at
  )
  VALUES (
    new_workspace_id,
    target_user_id,
    'owner',
    'active',
    now(),
    now(),
    now()
  )
  ON CONFLICT (workspace_id, user_id) DO UPDATE SET
    role = 'owner',
    membership_status = 'active',
    joined_at = COALESCE(public.workspace_members.joined_at, now()),
    removed_at = NULL,
    updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  PERFORM public.ensure_workspace_setup_for_user(
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data, '{}'::jsonb)
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

GRANT EXECUTE ON FUNCTION public.ensure_workspace_setup_for_user(uuid, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ensure_workspace_setup_for_user(uuid, text, jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;

DO $$
DECLARE
  target_user_id uuid := '0e763d64-6357-42e6-a5f4-1eb21a999cbd';
  target_email text;
  target_meta jsonb;
BEGIN
  SELECT email, COALESCE(raw_user_meta_data, '{}'::jsonb)
  INTO target_email, target_meta
  FROM auth.users
  WHERE id = target_user_id;

  IF target_email IS NULL THEN
    RAISE NOTICE 'Target auth user % not found, skipping single-user repair block.', target_user_id;
  ELSE
    PERFORM public.ensure_workspace_setup_for_user(
      target_user_id,
      target_email,
      target_meta
    );
  END IF;
END;
$$;

DO $$
DECLARE
  auth_user auth.users%ROWTYPE;
BEGIN
  FOR auth_user IN
    SELECT *
    FROM auth.users
  LOOP
    PERFORM public.ensure_workspace_setup_for_user(
      auth_user.id,
      auth_user.email,
      COALESCE(auth_user.raw_user_meta_data, '{}'::jsonb)
    );
  END LOOP;
END;
$$;

COMMIT;

-- Optional verification queries:
--
-- select id, email from auth.users where id = '0e763d64-6357-42e6-a5f4-1eb21a999cbd';
-- select * from public.profiles where id = '0e763d64-6357-42e6-a5f4-1eb21a999cbd';
-- select * from public.workspace_members where user_id = '0e763d64-6357-42e6-a5f4-1eb21a999cbd';
-- select * from public.workspaces where owner_user_id = '0e763d64-6357-42e6-a5f4-1eb21a999cbd';
