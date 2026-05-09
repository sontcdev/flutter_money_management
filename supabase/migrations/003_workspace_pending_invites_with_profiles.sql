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
