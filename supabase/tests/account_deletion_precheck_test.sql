insert into auth.users(id) values
('00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000002');
insert into public.profiles(id,email,display_name) values
('00000000-0000-0000-0000-000000000001','first@example.invalid','First'),
('00000000-0000-0000-0000-000000000002','second@example.invalid','Second');
insert into public.workspaces(id,type,name,owner_user_id) values
('10000000-0000-0000-0000-000000000001','personal','Solo','00000000-0000-0000-0000-000000000001'),
('10000000-0000-0000-0000-000000000002','group','Shared','00000000-0000-0000-0000-000000000002'),
('10000000-0000-0000-0000-000000000003','group','Left','00000000-0000-0000-0000-000000000002'),
('10000000-0000-0000-0000-000000000004','group','OwnerMissingMembership','00000000-0000-0000-0000-000000000001'),
('10000000-0000-0000-0000-000000000005','personal','Unrelated','00000000-0000-0000-0000-000000000002');
insert into public.workspace_members(workspace_id,user_id,role,membership_status) values
('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','owner','active'),
('10000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000001','member','pending'),
('10000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002','owner','active'),
('10000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000001','member','removed'),
('10000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000002','owner','active'),
('10000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000002','member','active'),
('10000000-0000-0000-0000-000000000005','00000000-0000-0000-0000-000000000002','owner','active');

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$
declare names text[];
begin
  select array_agg(workspace_name order by workspace_name) into names
  from public.get_account_deletion_blockers();
  if names is distinct from array['OwnerMissingMembership','Shared'] then
    raise exception 'Unexpected blockers: %', names;
  end if;
  begin
    perform public.account_deletion_shared_workspaces('00000000-0000-0000-0000-000000000002');
    raise exception 'Arbitrary-user helper is accessible';
  exception when insufficient_privilege then null;
  end;
end;
$$;
set request.jwt.claim.sub = '';
do $$
begin
  begin
    perform public.get_account_deletion_blockers();
    raise exception 'Missing user was accepted';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;
do $$
begin
  if has_function_privilege('anon','public.get_account_deletion_blockers()','execute') then
    raise exception 'Anonymous access is allowed';
  end if;
  if not has_function_privilege('service_role','public.account_deletion_shared_workspaces(uuid)','execute') then
    raise exception 'Backend helper is inaccessible';
  end if;
end;
$$;
