begin;

create or replace function public.transfer_workspace_owner(p_workspace_id uuid, p_new_owner_user_id uuid)
returns void as $$
begin
  if not public.is_workspace_owner(p_workspace_id) then raise exception 'Only owner can transfer ownership'; end if;
  if not exists (
    select 1 from public.workspace_members
    where workspace_id = p_workspace_id and user_id = p_new_owner_user_id
      and membership_status = 'active'
  ) then
    raise exception 'New owner must be an active workspace member' using errcode = '42501';
  end if;
  update public.workspace_members set role = 'admin', updated_at = now() where workspace_id = p_workspace_id and user_id = auth.uid();
  update public.workspace_members set role = 'owner', updated_at = now() where workspace_id = p_workspace_id and user_id = p_new_owner_user_id;
  update public.workspaces set owner_user_id = p_new_owner_user_id, updated_at = now() where id = p_workspace_id;
end;
$$ language plpgsql security definer set search_path = public;

commit;
