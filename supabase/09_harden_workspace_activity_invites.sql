begin;

create or replace function public.log_workspace_activity(
  p_workspace_id uuid,
  p_entity_type text,
  p_entity_id uuid,
  p_action text,
  p_summary text default null,
  p_payload jsonb default '{}'::jsonb
)
returns uuid as $$
declare
  v_id uuid;
begin
  if auth.uid() is null or not public.is_workspace_member(p_workspace_id) then
    raise exception 'Active workspace membership required' using errcode = '42501';
  end if;
  insert into public.activity_logs(workspace_id, actor_user_id, entity_type, entity_id, action, summary, payload)
  values (p_workspace_id, auth.uid(), p_entity_type, p_entity_id, p_action, p_summary, coalesce(p_payload, '{}'::jsonb))
  returning id into v_id;
  return v_id;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.decline_workspace_invite(invite_token text)
returns jsonb as $$
declare
  invite_record public.workspace_invites%rowtype;
begin
  select * into invite_record from public.workspace_invites where token = trim(invite_token) and status = 'pending' and expires_at > now();
  if not found then return jsonb_build_object('success', false, 'error', 'Invalid or expired invite'); end if;
  if auth.uid() is null or not exists (
    select 1 from auth.users au
    where au.id = auth.uid() and lower(au.email) = lower(invite_record.email)
  ) then
    return jsonb_build_object('success', false, 'error', 'Email mismatch');
  end if;
  update public.workspace_invites set status = 'declined', updated_at = now() where id = invite_record.id;
  update public.user_notifications
  set read_at = coalesce(read_at, now()), updated_at = now()
  where recipient_user_id = auth.uid()
    and type = 'workspace_invite'
    and payload->>'invite_id' = invite_record.id::text;
  return jsonb_build_object('success', true, 'invite_id', invite_record.id, 'workspace_id', invite_record.workspace_id);
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.get_workspace_invite_preview(invite_token text)
returns jsonb as $$
declare
  invite_record public.workspace_invites%rowtype;
  workspace_record public.workspaces%rowtype;
  inviter public.profiles%rowtype;
  members jsonb;
begin
  select * into invite_record from public.workspace_invites where token = trim(invite_token) and status = 'pending' and expires_at > now();
  if not found then raise exception 'Invalid or expired invite'; end if;
  if auth.uid() is null or not exists (
    select 1 from auth.users au
    where au.id = auth.uid() and lower(au.email) = lower(invite_record.email)
  ) then
    raise exception 'Invitation recipient required' using errcode = '42501';
  end if;
  select * into workspace_record from public.workspaces where id = invite_record.workspace_id;
  select * into inviter from public.profiles where id = invite_record.invited_by_user_id;
  select coalesce(jsonb_agg(jsonb_build_object('user_id', wm.user_id, 'display_name', p.display_name, 'email', p.email, 'avatar_url', p.avatar_url, 'role', wm.role, 'joined_at', wm.joined_at)), '[]'::jsonb)
  into members
  from public.workspace_members wm join public.profiles p on p.id = wm.user_id
  where wm.workspace_id = invite_record.workspace_id and wm.membership_status = 'active';
  return jsonb_build_object('workspace_id', workspace_record.id, 'workspace_name', workspace_record.name, 'workspace_type', workspace_record.type, 'description', workspace_record.settings->>'description', 'avatar_path', workspace_record.settings->>'avatar_path', 'email', invite_record.email, 'role', invite_record.role, 'token', invite_record.token, 'expires_at', invite_record.expires_at, 'invited_by_user_id', invite_record.invited_by_user_id, 'invited_by_display_name', inviter.display_name, 'invited_by_email', inviter.email, 'members', members);
end;
$$ language plpgsql security definer set search_path = public;

commit;
