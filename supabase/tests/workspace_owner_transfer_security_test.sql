insert into public.workspaces(id,type,name,owner_user_id) values
('10000000-0000-0000-0000-000000000011','group','Ownership security','00000000-0000-0000-0000-000000000001');
insert into public.workspace_members(workspace_id,user_id,role,membership_status) values
('10000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000001','owner','active'),
('10000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000002','member','pending');
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$
begin
  begin
    perform public.transfer_workspace_owner('10000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000002');
    raise exception 'Pending successor accepted';
  exception when insufficient_privilege then null;
  end;
  if not public.is_workspace_owner('10000000-0000-0000-0000-000000000011') then
    raise exception 'Rejected transfer demoted owner';
  end if;
end;
$$;
reset role;
update public.workspace_members set membership_status = 'active'
where workspace_id = '10000000-0000-0000-0000-000000000011' and user_id = '00000000-0000-0000-0000-000000000002';
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
select public.transfer_workspace_owner('10000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000002');
reset role;
do $$
begin
  if not exists (select 1 from public.workspaces where id = '10000000-0000-0000-0000-000000000011' and owner_user_id = '00000000-0000-0000-0000-000000000002') then
    raise exception 'Workspace owner not updated';
  end if;
  if not exists (select 1 from public.workspace_members where workspace_id = '10000000-0000-0000-0000-000000000011' and user_id = '00000000-0000-0000-0000-000000000002' and role = 'owner' and membership_status = 'active') then
    raise exception 'Successor not promoted';
  end if;
  if not exists (select 1 from public.workspace_members where workspace_id = '10000000-0000-0000-0000-000000000011' and user_id = '00000000-0000-0000-0000-000000000001' and role = 'admin') then
    raise exception 'Previous owner not demoted';
  end if;
end;
$$;
