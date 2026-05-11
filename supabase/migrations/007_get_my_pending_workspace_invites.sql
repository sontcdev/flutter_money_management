DROP FUNCTION IF EXISTS public.get_my_pending_workspace_invites();

CREATE OR REPLACE FUNCTION public.get_my_pending_workspace_invites()
RETURNS TABLE (
  id uuid,
  workspace_id uuid,
  workspace_name text,
  email text,
  role text,
  status text,
  token text,
  expires_at timestamptz,
  created_at timestamptz,
  invited_by_user_id uuid,
  invited_by_email text,
  invited_by_display_name text
) AS $$
DECLARE
  current_user_email text;
BEGIN
  SELECT auth.users.email INTO current_user_email
  FROM auth.users
  WHERE id = auth.uid();

  IF current_user_email IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    wi.id,
    wi.workspace_id,
    w.name AS workspace_name,
    wi.email,
    wi.role,
    wi.status,
    wi.token,
    wi.expires_at,
    wi.created_at,
    wi.invited_by_user_id,
    inviter.email AS invited_by_email,
    inviter.display_name AS invited_by_display_name
  FROM public.workspace_invites wi
  JOIN public.workspaces w ON w.id = wi.workspace_id
  LEFT JOIN public.profiles inviter ON inviter.id = wi.invited_by_user_id
  WHERE wi.status = 'pending'
    AND wi.expires_at > now()
    AND lower(wi.email) = lower(current_user_email)
  ORDER BY wi.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_my_pending_workspace_invites() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_pending_workspace_invites() TO service_role;
