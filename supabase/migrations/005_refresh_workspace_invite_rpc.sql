DROP FUNCTION IF EXISTS public.refresh_workspace_invite(uuid);

CREATE OR REPLACE FUNCTION public.refresh_workspace_invite(
  p_invite_id uuid
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
  invite_workspace_id uuid;
BEGIN
  SELECT workspace_id INTO invite_workspace_id
  FROM public.workspace_invites
  WHERE id = p_invite_id
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pending invite not found';
  END IF;

  IF NOT public.is_workspace_owner(invite_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner can refresh invites';
  END IF;

  RETURN QUERY
  WITH refreshed_invite AS (
    UPDATE public.workspace_invites
    SET token = gen_random_uuid()::text,
        expires_at = now() + interval '7 days',
        updated_at = now()
    WHERE workspace_invites.id = p_invite_id
      AND workspace_invites.status = 'pending'
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
  FROM refreshed_invite wi
  LEFT JOIN public.profiles p ON lower(p.email) = lower(wi.email);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.refresh_workspace_invite(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.refresh_workspace_invite(uuid) TO service_role;
