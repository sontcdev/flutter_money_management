ALTER TABLE public.workspace_members
DROP CONSTRAINT IF EXISTS workspace_members_role_check;

ALTER TABLE public.workspace_members
ADD CONSTRAINT workspace_members_role_check
CHECK (role IN ('owner', 'admin', 'member'));

CREATE OR REPLACE FUNCTION public.is_workspace_admin(workspace_uuid uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.workspace_members
    WHERE workspace_id = workspace_uuid
      AND user_id = auth.uid()
      AND role = 'admin'
      AND membership_status = 'active'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.can_manage_workspace(workspace_uuid uuid)
RETURNS boolean AS $$
BEGIN
  RETURN public.is_workspace_owner(workspace_uuid)
    OR public.is_workspace_admin(workspace_uuid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.can_manage_workspace_content(workspace_uuid uuid)
RETURNS boolean AS $$
BEGIN
  RETURN public.can_manage_workspace(workspace_uuid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.can_manage_transaction(
  workspace_uuid uuid,
  creator_uuid uuid
)
RETURNS boolean AS $$
BEGIN
  RETURN public.is_workspace_member(workspace_uuid)
    AND (
      creator_uuid = auth.uid()
      OR public.can_manage_workspace(workspace_uuid)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.log_workspace_activity(
  p_workspace_id uuid,
  p_entity_type text,
  p_entity_id uuid,
  p_action text,
  p_summary text,
  p_payload jsonb DEFAULT '{}'::jsonb
)
RETURNS void AS $$
BEGIN
  INSERT INTO public.activity_logs (
    workspace_id,
    actor_user_id,
    entity_type,
    entity_id,
    action,
    summary,
    payload,
    created_at
  )
  VALUES (
    p_workspace_id,
    auth.uid(),
    p_entity_type,
    p_entity_id,
    p_action,
    p_summary,
    COALESCE(p_payload, '{}'::jsonb),
    now()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP POLICY IF EXISTS workspace_members_insert_owner ON public.workspace_members;
CREATE POLICY workspace_members_insert_owner
  ON public.workspace_members FOR INSERT
  WITH CHECK (public.can_manage_workspace(workspace_id));

DROP POLICY IF EXISTS workspace_members_update_owner ON public.workspace_members;
CREATE POLICY workspace_members_update_owner
  ON public.workspace_members FOR UPDATE
  USING (public.can_manage_workspace(workspace_id))
  WITH CHECK (public.can_manage_workspace(workspace_id));

DROP POLICY IF EXISTS workspace_members_delete_owner ON public.workspace_members;
CREATE POLICY workspace_members_delete_owner
  ON public.workspace_members FOR DELETE
  USING (public.can_manage_workspace(workspace_id));

DROP POLICY IF EXISTS workspace_invites_select_owner ON public.workspace_invites;
CREATE POLICY workspace_invites_select_owner
  ON public.workspace_invites FOR SELECT
  USING (public.can_manage_workspace(workspace_id));

DROP POLICY IF EXISTS workspace_invites_insert_owner ON public.workspace_invites;
CREATE POLICY workspace_invites_insert_owner
  ON public.workspace_invites FOR INSERT
  WITH CHECK (public.can_manage_workspace(workspace_id));

DROP POLICY IF EXISTS workspace_invites_update_owner ON public.workspace_invites;
CREATE POLICY workspace_invites_update_owner
  ON public.workspace_invites FOR UPDATE
  USING (public.can_manage_workspace(workspace_id))
  WITH CHECK (public.can_manage_workspace(workspace_id));

DROP POLICY IF EXISTS workspace_invites_delete_owner ON public.workspace_invites;
CREATE POLICY workspace_invites_delete_owner
  ON public.workspace_invites FOR DELETE
  USING (public.can_manage_workspace(workspace_id));

DROP POLICY IF EXISTS categories_insert_owner ON public.categories;
CREATE POLICY categories_insert_owner
  ON public.categories FOR INSERT
  WITH CHECK (public.can_manage_workspace_content(workspace_id));

DROP POLICY IF EXISTS categories_update_owner ON public.categories;
CREATE POLICY categories_update_owner
  ON public.categories FOR UPDATE
  USING (public.can_manage_workspace_content(workspace_id))
  WITH CHECK (public.can_manage_workspace_content(workspace_id));

DROP POLICY IF EXISTS budgets_insert_owner ON public.budgets;
CREATE POLICY budgets_insert_owner
  ON public.budgets FOR INSERT
  WITH CHECK (public.can_manage_workspace_content(workspace_id));

DROP POLICY IF EXISTS budgets_update_owner ON public.budgets;
CREATE POLICY budgets_update_owner
  ON public.budgets FOR UPDATE
  USING (public.can_manage_workspace_content(workspace_id))
  WITH CHECK (public.can_manage_workspace_content(workspace_id));

DROP POLICY IF EXISTS transactions_update_creator ON public.transactions;
CREATE POLICY transactions_update_creator
  ON public.transactions FOR UPDATE
  USING (public.can_manage_transaction(workspace_id, created_by_user_id))
  WITH CHECK (public.is_workspace_member(workspace_id));

DROP POLICY IF EXISTS transaction_attachments_delete_creator ON public.transaction_attachments;
CREATE POLICY transaction_attachments_delete_creator
  ON public.transaction_attachments FOR DELETE
  USING (
    public.is_workspace_member(workspace_id)
    AND EXISTS (
      SELECT 1
      FROM public.transactions
      WHERE transactions.id = transaction_id
        AND public.can_manage_transaction(
          transactions.workspace_id,
          transactions.created_by_user_id
        )
    )
  );

DROP POLICY IF EXISTS transaction_receipts_delete_creator ON storage.objects;
CREATE POLICY transaction_receipts_delete_creator
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'transaction-receipts'
    AND split_part(name, '/', 1) = 'workspaces'
    AND split_part(name, '/', 3) = 'transactions'
    AND EXISTS (
      SELECT 1
      FROM public.transactions
      WHERE transactions.id = split_part(name, '/', 4)::uuid
        AND transactions.workspace_id = split_part(name, '/', 2)::uuid
        AND public.can_manage_transaction(
          transactions.workspace_id,
          transactions.created_by_user_id
        )
    )
  );

CREATE OR REPLACE FUNCTION public.create_group_workspace_v2(
  workspace_name text,
  workspace_description text DEFAULT NULL,
  workspace_avatar_path text DEFAULT NULL,
  workspace_settings jsonb DEFAULT '{}'::jsonb
)
RETURNS uuid AS $$
DECLARE
  new_workspace_id uuid;
  merged_settings jsonb;
BEGIN
  merged_settings := COALESCE(workspace_settings, '{}'::jsonb)
    || jsonb_strip_nulls(
      jsonb_build_object(
        'description', NULLIF(trim(workspace_description), ''),
        'avatar_path', NULLIF(trim(workspace_avatar_path), '')
      )
    );

  INSERT INTO public.workspaces (
    id,
    type,
    name,
    owner_user_id,
    settings,
    created_at,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    'group',
    trim(workspace_name),
    auth.uid(),
    merged_settings,
    now(),
    now()
  )
  RETURNING id INTO new_workspace_id;

  INSERT INTO public.workspace_members (
    id,
    workspace_id,
    user_id,
    role,
    membership_status,
    joined_at,
    created_at,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    new_workspace_id,
    auth.uid(),
    'owner',
    'active',
    now(),
    now(),
    now()
  );

  PERFORM public.log_workspace_activity(
    new_workspace_id,
    'workspace',
    new_workspace_id,
    'workspace_created',
    format('Workspace %s was created', trim(workspace_name)),
    merged_settings
  );

  RETURN new_workspace_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.get_workspace_detail(
  p_workspace_id uuid
)
RETURNS TABLE (
  id uuid,
  name text,
  type text,
  owner_user_id uuid,
  description text,
  avatar_path text,
  created_at timestamptz,
  updated_at timestamptz,
  member_count bigint,
  current_user_role text
) AS $$
BEGIN
  IF NOT public.is_workspace_member(p_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace members can view workspace details';
  END IF;

  RETURN QUERY
  SELECT
    w.id,
    w.name,
    w.type,
    w.owner_user_id,
    NULLIF(w.settings->>'description', ''),
    NULLIF(w.settings->>'avatar_path', ''),
    w.created_at,
    w.updated_at,
    (
      SELECT count(*)
      FROM public.workspace_members wm_count
      WHERE wm_count.workspace_id = w.id
        AND wm_count.membership_status = 'active'
    ) AS member_count,
    wm.role AS current_user_role
  FROM public.workspaces w
  JOIN public.workspace_members wm
    ON wm.workspace_id = w.id
   AND wm.user_id = auth.uid()
   AND wm.membership_status = 'active'
  WHERE w.id = p_workspace_id
    AND w.deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.get_workspace_invite_preview(
  invite_token text
)
RETURNS jsonb AS $$
DECLARE
  invite_record public.workspace_invites%ROWTYPE;
  preview_payload jsonb;
BEGIN
  SELECT * INTO invite_record
  FROM public.workspace_invites
  WHERE token = trim(invite_token)
    AND status = 'pending'
    AND expires_at > now();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid or expired invite';
  END IF;

  SELECT jsonb_build_object(
    'workspace_id', w.id,
    'workspace_name', w.name,
    'workspace_type', w.type,
    'description', NULLIF(w.settings->>'description', ''),
    'avatar_path', NULLIF(w.settings->>'avatar_path', ''),
    'email', invite_record.email,
    'role', invite_record.role,
    'token', invite_record.token,
    'expires_at', invite_record.expires_at,
    'invited_by_user_id', invite_record.invited_by_user_id,
    'invited_by_display_name', inviter.display_name,
    'invited_by_email', inviter.email,
    'members', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'user_id', p.id,
          'display_name', p.display_name,
          'email', p.email,
          'avatar_url', p.avatar_url,
          'role', wm.role,
          'joined_at', wm.joined_at
        )
        ORDER BY CASE wm.role WHEN 'owner' THEN 0 WHEN 'admin' THEN 1 ELSE 2 END,
                 p.display_name,
                 p.email
      )
      FROM public.workspace_members wm
      JOIN public.profiles p ON p.id = wm.user_id
      WHERE wm.workspace_id = w.id
        AND wm.membership_status = 'active'
    ), '[]'::jsonb)
  ) INTO preview_payload
  FROM public.workspaces w
  JOIN public.profiles inviter ON inviter.id = invite_record.invited_by_user_id
  WHERE w.id = invite_record.workspace_id
    AND w.deleted_at IS NULL;

  RETURN preview_payload;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.get_workspace_activity_logs(
  p_workspace_id uuid,
  p_limit integer DEFAULT 50,
  p_offset integer DEFAULT 0
)
RETURNS TABLE (
  id uuid,
  workspace_id uuid,
  actor_user_id uuid,
  actor_display_name text,
  actor_email text,
  actor_avatar_url text,
  entity_type text,
  entity_id uuid,
  action text,
  summary text,
  payload jsonb,
  created_at timestamptz
) AS $$
BEGIN
  IF NOT public.is_workspace_member(p_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace members can view activity logs';
  END IF;

  RETURN QUERY
  SELECT
    al.id,
    al.workspace_id,
    al.actor_user_id,
    p.display_name,
    p.email,
    p.avatar_url,
    al.entity_type,
    al.entity_id,
    al.action,
    al.summary,
    al.payload,
    al.created_at
  FROM public.activity_logs al
  JOIN public.profiles p ON p.id = al.actor_user_id
  WHERE al.workspace_id = p_workspace_id
  ORDER BY al.created_at DESC
  LIMIT GREATEST(p_limit, 1)
  OFFSET GREATEST(p_offset, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_workspace_member_role(
  p_workspace_id uuid,
  p_user_id uuid,
  p_role text
)
RETURNS boolean AS $$
DECLARE
  target_member public.workspace_members%ROWTYPE;
  normalized_role text;
BEGIN
  IF NOT public.is_workspace_owner(p_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner can update member roles';
  END IF;

  normalized_role := lower(trim(p_role));
  IF normalized_role NOT IN ('admin', 'member') THEN
    RAISE EXCEPTION 'Unsupported workspace role';
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
    RAISE EXCEPTION 'Cannot change owner role';
  END IF;

  UPDATE public.workspace_members
  SET role = normalized_role,
      updated_at = now()
  WHERE id = target_member.id;

  PERFORM public.log_workspace_activity(
    p_workspace_id,
    'workspace_member',
    target_member.id,
    'member_role_updated',
    format('Member role changed to %s', normalized_role),
    jsonb_build_object('user_id', p_user_id, 'role', normalized_role)
  );

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.transfer_workspace_owner(
  p_workspace_id uuid,
  p_new_owner_user_id uuid
)
RETURNS boolean AS $$
DECLARE
  current_owner_member public.workspace_members%ROWTYPE;
  new_owner_member public.workspace_members%ROWTYPE;
BEGIN
  IF NOT public.is_workspace_owner(p_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner can transfer ownership';
  END IF;

  SELECT * INTO current_owner_member
  FROM public.workspace_members
  WHERE workspace_id = p_workspace_id
    AND user_id = auth.uid()
    AND membership_status = 'active';

  SELECT * INTO new_owner_member
  FROM public.workspace_members
  WHERE workspace_id = p_workspace_id
    AND user_id = p_new_owner_user_id
    AND membership_status = 'active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'New owner must be an active workspace member';
  END IF;

  UPDATE public.workspace_members
  SET role = 'admin',
      updated_at = now()
  WHERE id = current_owner_member.id;

  UPDATE public.workspace_members
  SET role = 'owner',
      updated_at = now()
  WHERE id = new_owner_member.id;

  UPDATE public.workspaces
  SET owner_user_id = p_new_owner_user_id,
      updated_at = now()
  WHERE id = p_workspace_id;

  PERFORM public.log_workspace_activity(
    p_workspace_id,
    'workspace',
    p_workspace_id,
    'workspace_owner_transferred',
    'Workspace ownership was transferred',
    jsonb_build_object(
      'previous_owner_user_id', auth.uid(),
      'new_owner_user_id', p_new_owner_user_id
    )
  );

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.leave_workspace(
  p_workspace_id uuid
)
RETURNS boolean AS $$
DECLARE
  current_member public.workspace_members%ROWTYPE;
BEGIN
  SELECT * INTO current_member
  FROM public.workspace_members
  WHERE workspace_id = p_workspace_id
    AND user_id = auth.uid()
    AND membership_status = 'active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Active member not found';
  END IF;

  IF current_member.role = 'owner' THEN
    RAISE EXCEPTION 'Owner must transfer ownership before leaving';
  END IF;

  UPDATE public.workspace_members
  SET membership_status = 'removed',
      removed_at = now(),
      updated_at = now()
  WHERE id = current_member.id;

  PERFORM public.log_workspace_activity(
    p_workspace_id,
    'workspace_member',
    current_member.id,
    'member_left_workspace',
    'A member left the workspace',
    jsonb_build_object('user_id', auth.uid(), 'role', current_member.role)
  );

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

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
    CASE wm.role
      WHEN 'owner' THEN 0
      WHEN 'admin' THEN 1
      ELSE 2
    END,
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
  actor_role text;
BEGIN
  IF NOT public.can_manage_workspace(p_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner or admin can remove members';
  END IF;

  IF p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Use leave workspace instead';
  END IF;

  SELECT role INTO actor_role
  FROM public.workspace_members
  WHERE workspace_id = p_workspace_id
    AND user_id = auth.uid()
    AND membership_status = 'active';

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

  IF actor_role = 'admin' AND target_member.role = 'admin' THEN
    RAISE EXCEPTION 'Admin cannot remove another admin';
  END IF;

  UPDATE public.workspace_members
  SET membership_status = 'removed',
      removed_at = now(),
      updated_at = now()
  WHERE id = target_member.id;

  PERFORM public.log_workspace_activity(
    p_workspace_id,
    'workspace_member',
    target_member.id,
    'member_removed',
    'A member was removed from the workspace',
    jsonb_build_object('user_id', p_user_id, 'role', target_member.role)
  );

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

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
  IF NOT public.can_manage_workspace(p_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner or admin can view invites';
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

GRANT EXECUTE ON FUNCTION public.is_workspace_admin(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.can_manage_workspace(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.can_manage_workspace_content(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.can_manage_transaction(uuid, uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.log_workspace_activity(uuid, text, uuid, text, text, jsonb) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.create_group_workspace_v2(text, text, text, jsonb) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_workspace_detail(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_workspace_invite_preview(text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_workspace_activity_logs(uuid, integer, integer) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.update_workspace_member_role(uuid, uuid, text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.transfer_workspace_owner(uuid, uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.leave_workspace(uuid) TO authenticated, service_role;

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
  created_invite_id uuid;
BEGIN
  IF NOT public.can_manage_workspace(p_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner or admin can invite members';
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

  SELECT id INTO created_invite_id
  FROM public.workspace_invites
  WHERE workspace_id = p_workspace_id
    AND lower(email) = normalized_email
  ORDER BY created_at DESC
  LIMIT 1;

  PERFORM public.log_workspace_activity(
    p_workspace_id,
    'workspace_invite',
    created_invite_id,
    'invite_created',
    format('Invite created for %s', normalized_email),
    jsonb_build_object('email', normalized_email)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

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

  IF NOT public.can_manage_workspace(invite_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner or admin can refresh invites';
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

  PERFORM public.log_workspace_activity(
    invite_workspace_id,
    'workspace_invite',
    p_invite_id,
    'invite_refreshed',
    'Invite token was refreshed',
    jsonb_build_object('invite_id', p_invite_id)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.revoke_workspace_invite(invite_id uuid)
RETURNS boolean AS $$
DECLARE
  workspace_id uuid;
BEGIN
  SELECT wi.workspace_id INTO workspace_id
  FROM public.workspace_invites wi
  WHERE wi.id = invite_id
    AND wi.status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pending invite not found';
  END IF;

  IF NOT public.can_manage_workspace(workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner or admin can revoke invites';
  END IF;

  UPDATE public.workspace_invites
  SET status = 'revoked',
      updated_at = now()
  WHERE id = invite_id;

  PERFORM public.log_workspace_activity(
    workspace_id,
    'workspace_invite',
    invite_id,
    'invite_revoked',
    'Invite was revoked',
    jsonb_build_object('invite_id', invite_id)
  );

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.accept_workspace_invite(invite_token text)
RETURNS jsonb AS $$
DECLARE
  invite_record public.workspace_invites%ROWTYPE;
  new_member_id uuid;
  joined_workspace_name text;
BEGIN
  SELECT * INTO invite_record
  FROM public.workspace_invites
  WHERE token = trim(invite_token)
    AND status = 'pending'
    AND expires_at > now();

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid or expired invite');
  END IF;

  IF invite_record.email != (SELECT email FROM auth.users WHERE id = auth.uid()) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Email mismatch');
  END IF;

  INSERT INTO public.workspace_members (
    id,
    workspace_id,
    user_id,
    role,
    membership_status,
    joined_at,
    invited_by_user_id,
    created_at,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    invite_record.workspace_id,
    auth.uid(),
    invite_record.role,
    'active',
    now(),
    invite_record.invited_by_user_id,
    now(),
    now()
  )
  ON CONFLICT (workspace_id, user_id) DO UPDATE SET
    role = EXCLUDED.role,
    membership_status = 'active',
    invited_by_user_id = EXCLUDED.invited_by_user_id,
    joined_at = COALESCE(public.workspace_members.joined_at, now()),
    removed_at = NULL,
    updated_at = now()
  RETURNING id INTO new_member_id;

  UPDATE public.workspace_invites
  SET status = 'accepted',
      accepted_by_user_id = auth.uid(),
      updated_at = now()
  WHERE id = invite_record.id;

  SELECT name INTO joined_workspace_name
  FROM public.workspaces
  WHERE id = invite_record.workspace_id;

  PERFORM public.log_workspace_activity(
    invite_record.workspace_id,
    'workspace_member',
    new_member_id,
    'member_joined_workspace',
    format('%s joined workspace %s', COALESCE((SELECT display_name FROM public.profiles WHERE id = auth.uid()), 'A member'), joined_workspace_name),
    jsonb_build_object('user_id', auth.uid(), 'invite_id', invite_record.id)
  );

  RETURN jsonb_build_object('success', true, 'workspace_id', invite_record.workspace_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.decline_workspace_invite(invite_token text)
RETURNS jsonb AS $$
DECLARE
  invite_record public.workspace_invites%ROWTYPE;
  current_user_email text;
BEGIN
  SELECT * INTO invite_record
  FROM public.workspace_invites
  WHERE token = trim(invite_token)
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

  PERFORM public.log_workspace_activity(
    invite_record.workspace_id,
    'workspace_invite',
    invite_record.id,
    'invite_declined',
    'Invite was declined',
    jsonb_build_object('invite_id', invite_record.id)
  );

  RETURN jsonb_build_object(
    'success', true,
    'invite_id', invite_record.id,
    'workspace_id', invite_record.workspace_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.create_workspace_invite(uuid, text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.refresh_workspace_invite(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.revoke_workspace_invite(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.accept_workspace_invite(text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.decline_workspace_invite(text) TO authenticated, service_role;
