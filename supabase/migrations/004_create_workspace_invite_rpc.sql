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
