DROP FUNCTION IF EXISTS public.decline_workspace_invite(text);

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
  SET status = 'revoked',
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
