DROP FUNCTION IF EXISTS public.get_workspace_members_with_profiles(uuid);
DROP FUNCTION IF EXISTS public.remove_workspace_member(uuid, uuid);

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

CREATE OR REPLACE FUNCTION public.remove_workspace_member(
  p_workspace_id uuid,
  p_user_id uuid
)
RETURNS boolean AS $$
DECLARE
  target_member public.workspace_members%ROWTYPE;
BEGIN
  IF NOT public.is_workspace_owner(p_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner can remove members';
  END IF;

  IF p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Owner cannot remove themselves';
  END IF;

  SELECT * INTO target_member
  FROM public.workspace_members
  WHERE workspace_id = p_workspace_id
    AND user_id = p_user_id
    AND membership_status = 'active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Member not found';
  END IF;

  IF target_member.role = 'owner' THEN
    RAISE EXCEPTION 'Workspace owner cannot be removed';
  END IF;

  UPDATE public.workspace_members
  SET membership_status = 'removed',
      removed_at = now(),
      updated_at = now()
  WHERE id = target_member.id;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_workspace_members_with_profiles(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_workspace_members_with_profiles(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.remove_workspace_member(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_workspace_member(uuid, uuid) TO service_role;
