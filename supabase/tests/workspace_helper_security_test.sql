do $$
begin
  if has_function_privilege('anon', 'public.ensure_default_wallet(uuid,uuid)', 'execute')
     or has_function_privilege('authenticated', 'public.ensure_default_wallet(uuid,uuid)', 'execute')
     or has_function_privilege('anon', 'public.ensure_workspace_setup_for_user(uuid,text,jsonb)', 'execute')
     or has_function_privilege('authenticated', 'public.ensure_workspace_setup_for_user(uuid,text,jsonb)', 'execute')
     or has_function_privilege('anon', 'public.generate_recurring_occurrences_rpc(uuid,timestamptz)', 'execute') then
    raise exception 'Internal or anonymous helper execution remains exposed';
  end if;
end;
$$;

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
select public.generate_recurring_occurrences_rpc('10000000-0000-0000-0000-000000000001', now());
do $$
declare workspace_id uuid;
begin
  foreach workspace_id in array array[
    '10000000-0000-0000-0000-000000000002'::uuid,
    '10000000-0000-0000-0000-000000000003'::uuid,
    '10000000-0000-0000-0000-000000000005'::uuid
  ] loop
    begin
      perform public.generate_recurring_occurrences_rpc(workspace_id, now());
      raise exception 'Pending, removed, or unrelated membership accepted';
    exception when insufficient_privilege then null;
    end;
  end loop;
end;
$$;
set request.jwt.claim.sub = '';
do $$
begin
  begin
    perform public.generate_recurring_occurrences_rpc('10000000-0000-0000-0000-000000000001', now());
    raise exception 'Missing caller identity accepted';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;
insert into auth.users(id,email,raw_user_meta_data) values
('00000000-0000-0000-0000-000000000006','setup@example.invalid','{"display_name":"Setup"}');
set role service_role;
select public.ensure_workspace_setup_for_user('00000000-0000-0000-0000-000000000006','setup@example.invalid','{"display_name":"Setup"}');
reset role;
do $$
begin
  if not exists (
    select 1 from public.workspaces w join public.wallets wallet on wallet.workspace_id = w.id
    where w.owner_user_id = '00000000-0000-0000-0000-000000000006' and wallet.is_default
  ) then
    raise exception 'Backend setup failed to create default wallet';
  end if;
end;
$$;

alter table auth.users enable trigger on_auth_user_created;
insert into auth.users(id,email,raw_user_meta_data) values
('00000000-0000-0000-0000-000000000007','trigger@example.invalid','{"display_name":"Trigger"}');
do $$
begin
  if not exists (
    select 1 from public.workspaces w join public.wallets wallet on wallet.workspace_id = w.id
    where w.owner_user_id = '00000000-0000-0000-0000-000000000007' and wallet.is_default
  ) then
    raise exception 'Sign-up trigger failed after helper revocation';
  end if;
end;
$$;

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$
begin
  begin
    perform public.soft_delete_recurring_transaction_rpc('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000005');
    raise exception 'Cross-workspace recurring deletion accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.soft_delete_recurring_transaction_rpc('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001');
    raise exception 'Unbound recurring ID accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.skip_recurring_occurrence_rpc('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000005');
    raise exception 'Cross-workspace occurrence skip accepted';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;

set role anon;
set request.jwt.claim.sub = '';
do $$
declare
  result jsonb;
begin
  result := public.check_signup_uniqueness(' TRIGGER@EXAMPLE.INVALID ', ' tRiGgEr ');
  if result <> jsonb_build_object('email_exists', true, 'display_name_exists', true) then
    raise exception 'Anonymous signup uniqueness check lost existing identity detection';
  end if;
  result := public.check_signup_uniqueness('unused@example.invalid', '');
  if result <> jsonb_build_object('email_exists', false, 'display_name_exists', false) then
    raise exception 'Anonymous signup uniqueness check rejected an unused identity';
  end if;
  begin
    perform 1 from public.profiles limit 1;
    raise exception 'Anonymous direct profile read accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.profiles set display_name = 'Anonymous mutation' where email = 'trigger@example.invalid';
    raise exception 'Anonymous direct profile update accepted';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;
do $$
begin
  if not exists (
    select 1 from public.profiles
    where email = 'trigger@example.invalid' and display_name = 'Trigger'
  ) then
    raise exception 'Rejected anonymous update changed the signup profile';
  end if;
end;
$$;
