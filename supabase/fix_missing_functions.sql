-- Fix missing functions in Supabase database
-- Run this script in Supabase SQL Editor to create the missing functions

-- ============================================================================
-- Function 1: get_workspace_members_with_profiles
-- ============================================================================

DROP FUNCTION IF EXISTS public.get_workspace_members_with_profiles(uuid);

CREATE OR REPLACE FUNCTION public.get_workspace_members_with_profiles(
  p_workspace_id uuid
)
RETURNS TABLE (
  member_id uuid,
  user_id uuid,
  display_name text,
  email text,
  avatar_url text,
  role text,
  membership_status text,
  joined_at timestamptz
) AS $$
BEGIN
  IF NOT public.is_workspace_member(p_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace members can view members';
  END IF;

  RETURN QUERY
  SELECT
    wm.id AS member_id,
    wm.user_id,
    p.display_name,
    p.email,
    p.avatar_url,
    wm.role,
    wm.membership_status,
    wm.joined_at
  FROM public.workspace_members wm
  JOIN public.profiles p ON p.id = wm.user_id
  WHERE wm.workspace_id = p_workspace_id
    AND wm.membership_status IN ('active', 'pending')
  ORDER BY
    CASE WHEN wm.role = 'owner' THEN 0 ELSE 1 END,
    p.display_name,
    p.email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_workspace_members_with_profiles(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_workspace_members_with_profiles(uuid) TO service_role;

-- ============================================================================
-- Function 2: get_workspace_pending_invites_with_profiles
-- ============================================================================

DROP FUNCTION IF EXISTS public.get_workspace_pending_invites_with_profiles(uuid);

CREATE OR REPLACE FUNCTION public.get_workspace_pending_invites_with_profiles(
  p_workspace_id uuid
)
RETURNS TABLE (
  id uuid,
  email text,
  role text,
  status text,
  token text,
  expires_at timestamptz,
  created_at timestamptz,
  matched_user_id uuid,
  matched_display_name text,
  matched_avatar_url text
) AS $$
BEGIN
  IF NOT public.is_workspace_owner(p_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner can view pending invites';
  END IF;

  RETURN QUERY
  SELECT
    wi.id,
    wi.email,
    wi.role,
    wi.status,
    wi.token,
    wi.expires_at,
    wi.created_at,
    p.id AS matched_user_id,
    p.display_name AS matched_display_name,
    p.avatar_url AS matched_avatar_url
  FROM public.workspace_invites wi
  LEFT JOIN public.profiles p ON lower(p.email) = lower(wi.email)
  WHERE wi.workspace_id = p_workspace_id
    AND wi.status = 'pending'
  ORDER BY wi.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_workspace_pending_invites_with_profiles(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_workspace_pending_invites_with_profiles(uuid) TO service_role;

-- ============================================================================
-- Function 3: create_workspace_invite
-- ============================================================================

DROP FUNCTION IF EXISTS public.create_workspace_invite(uuid, text);

CREATE OR REPLACE FUNCTION public.create_workspace_invite(
  p_workspace_id uuid,
  p_email text
)
RETURNS TABLE (
  id uuid,
  email text,
  role text,
  status text,
  token text,
  expires_at timestamptz,
  created_at timestamptz,
  matched_user_id uuid,
  matched_display_name text,
  matched_avatar_url text
) AS $$
DECLARE
  normalized_email text;
BEGIN
  IF NOT public.is_workspace_owner(p_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner can invite members';
  END IF;

  normalized_email := lower(trim(p_email));
  IF normalized_email = '' THEN
    RAISE EXCEPTION 'Email is required';
  END IF;

  IF normalized_email !~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$' THEN
    RAISE EXCEPTION 'Email format is invalid';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.workspace_members wm
    JOIN public.profiles p ON p.id = wm.user_id
    WHERE wm.workspace_id = p_workspace_id
      AND wm.membership_status = 'active'
      AND lower(p.email) = normalized_email
  ) THEN
    RAISE EXCEPTION 'This email is already a workspace member';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.workspace_invites wi
    WHERE wi.workspace_id = p_workspace_id
      AND wi.status = 'pending'
      AND lower(wi.email) = normalized_email
  ) THEN
    RAISE EXCEPTION 'A pending invite already exists for this email';
  END IF;

  RETURN QUERY
  WITH inserted_invite AS (
    INSERT INTO public.workspace_invites (
      workspace_id,
      email,
      role,
      token,
      status,
      invited_by_user_id,
      expires_at
    )
    VALUES (
      p_workspace_id,
      normalized_email,
      'member',
      gen_random_uuid()::text,
      'pending',
      auth.uid(),
      now() + interval '7 days'
    )
    RETURNING *
  )
  SELECT
    wi.id,
    wi.email,
    wi.role,
    wi.status,
    wi.token,
    wi.expires_at,
    wi.created_at,
    p.id AS matched_user_id,
    p.display_name AS matched_display_name,
    p.avatar_url AS matched_avatar_url
  FROM inserted_invite wi
  LEFT JOIN public.profiles p ON lower(p.email) = lower(wi.email);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.create_workspace_invite(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_workspace_invite(uuid, text) TO service_role;

-- ============================================================================
-- Verification queries (optional - run these to verify the functions work)
-- ============================================================================

-- Test if functions exist:
-- SELECT routine_name 
-- FROM information_schema.routines 
-- WHERE routine_schema = 'public' 
--   AND routine_name IN ('get_workspace_members_with_profiles', 'get_workspace_pending_invites_with_profiles', 'create_workspace_invite');

-- Test calling the functions (replace with your actual workspace_id):
-- SELECT * FROM public.get_workspace_members_with_profiles('your-workspace-id-here');
-- SELECT * FROM public.get_workspace_pending_invites_with_profiles('your-workspace-id-here');
-- SELECT * FROM public.create_workspace_invite('your-workspace-id-here', 'test@example.com');
