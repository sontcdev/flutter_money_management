ALTER TABLE public.workspace_invites
DROP CONSTRAINT IF EXISTS workspace_invites_status_check;

ALTER TABLE public.workspace_invites
ADD CONSTRAINT workspace_invites_status_check
CHECK (status IN ('pending', 'accepted', 'expired', 'revoked', 'declined'));

DROP FUNCTION IF EXISTS public.get_workspace_invites_with_profiles(uuid);

CREATE OR REPLACE FUNCTION public.get_workspace_invites_with_profiles(
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
  updated_at timestamptz,
  matched_user_id uuid,
  matched_display_name text,
  matched_avatar_url text
) AS $$
BEGIN
  IF NOT public.is_workspace_owner(p_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner can view invites';
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
    wi.updated_at,
    p.id AS matched_user_id,
    p.display_name AS matched_display_name,
    p.avatar_url AS matched_avatar_url
  FROM public.workspace_invites wi
  LEFT JOIN public.profiles p ON lower(p.email) = lower(wi.email)
  WHERE wi.workspace_id = p_workspace_id
    AND wi.status IN ('pending', 'declined', 'revoked')
  ORDER BY
    CASE wi.status
      WHEN 'pending' THEN 0
      WHEN 'declined' THEN 1
      ELSE 2
    END,
    wi.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_workspace_invites_with_profiles(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_workspace_invites_with_profiles(uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.decline_workspace_invite(invite_token text)
RETURNS jsonb AS $$
DECLARE
  invite_record public.workspace_invites%ROWTYPE;
  current_user_email text;
BEGIN
  SELECT * INTO invite_record
  FROM public.workspace_invites
  WHERE token = invite_token
    AND status = 'pending'
    AND expires_at > now();

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid or expired invite');
  END IF;

  SELECT auth.users.email INTO current_user_email
  FROM auth.users
  WHERE id = auth.uid();

  IF current_user_email IS NULL OR lower(invite_record.email) != lower(current_user_email) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Email mismatch');
  END IF;

  UPDATE public.workspace_invites
  SET status = 'declined',
      updated_at = now()
  WHERE id = invite_record.id;

  RETURN jsonb_build_object(
    'success', true,
    'invite_id', invite_record.id,
    'workspace_id', invite_record.workspace_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.decline_workspace_invite(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.decline_workspace_invite(text) TO service_role;
