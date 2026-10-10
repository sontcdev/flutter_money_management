do $$
declare result jsonb;
begin
  result := public.prepare_account_deletion('00000000-0000-0000-0000-000000000001');
  if result->>'status' <> 'blocked' or jsonb_array_length(result->'workspaces') <> 2 then
    raise exception 'Shared membership was not blocked';
  end if;
  if exists(select 1 from public.account_deletion_jobs) then
    raise exception 'Blocked request mutated deletion state';
  end if;
end;
$$;

update public.workspaces set owner_user_id = '00000000-0000-0000-0000-000000000002'
where name = 'OwnerMissingMembership';
update public.workspace_members set membership_status = 'removed'
where workspace_id = '10000000-0000-0000-0000-000000000002'
  and user_id = '00000000-0000-0000-0000-000000000001';

insert into public.categories(id,workspace_id,name,normalized_name,type,icon_name,color_value,created_by_user_id,updated_by_user_id)
select ('20000000-0000-0000-0000-' || lpad(n::text,12,'0'))::uuid,
  ('10000000-0000-0000-0000-' || lpad(n::text,12,'0'))::uuid,
  'Food','food','expense','food','FF00884B',
  '00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002'
from unnest(array[1,3]) n;
insert into public.wallets(id,workspace_id,name,normalized_name,created_by_user_id,updated_by_user_id)
select ('30000000-0000-0000-0000-' || lpad(n::text,12,'0'))::uuid,
  ('10000000-0000-0000-0000-' || lpad(n::text,12,'0'))::uuid,
  'Cash','cash','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002'
from unnest(array[1,3]) n;
insert into public.transactions(id,workspace_id,category_id,wallet_id,amount_minor,currency_code,transaction_type,transaction_at,created_by_user_id,updated_by_user_id)
select ('40000000-0000-0000-0000-' || lpad(n::text,12,'0'))::uuid,
  ('10000000-0000-0000-0000-' || lpad(n::text,12,'0'))::uuid,
  ('20000000-0000-0000-0000-' || lpad(n::text,12,'0'))::uuid,
  ('30000000-0000-0000-0000-' || lpad(n::text,12,'0'))::uuid,
  100,'VND','expense',now(),'00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002'
from unnest(array[1,3]) n;
insert into public.budgets(workspace_id,category_id,period_type,period_start,period_end,limit_minor,currency_code,created_by_user_id,updated_by_user_id)
select t.workspace_id,t.category_id,'monthly',now(),now(),100,'VND',t.created_by_user_id,t.updated_by_user_id from public.transactions t;
insert into public.recurring_transactions(id,workspace_id,title,category_id,wallet_id,amount_minor,transaction_type,frequency,mode,start_date,next_occurrence_at,created_by_user_id,updated_by_user_id)
select t.id,t.workspace_id,'Rent',t.category_id,t.wallet_id,100,'expense','monthly','manualConfirm',now(),now(),t.created_by_user_id,t.updated_by_user_id from public.transactions t;
insert into public.recurring_transaction_occurrences(recurring_transaction_id,workspace_id,scheduled_for,remind_at,status,generated_transaction_id)
select t.id,t.workspace_id,now(),now(),'completed',t.id from public.transactions t;
insert into public.activity_logs(workspace_id,actor_user_id,entity_type,entity_id,action)
select workspace_id,created_by_user_id,'transaction',id,'create' from public.transactions;
insert into public.error_reports(user_id,error_type,error_message) values
('00000000-0000-0000-0000-000000000001','test','test');
insert into public.workspace_invites(workspace_id,email,token,invited_by_user_id,expires_at) values
('10000000-0000-0000-0000-000000000003','third@example.invalid','test-token','00000000-0000-0000-0000-000000000001',now());
insert into public.user_notifications(recipient_user_id,type,title,body,payload) values
('00000000-0000-0000-0000-000000000002','workspace_invite','Invite','Invite','{"invited_by_user_id":"00000000-0000-0000-0000-000000000001"}');
insert into storage.objects(bucket_id,name,owner_id) values
('transaction-receipts','workspaces/10000000-0000-0000-0000-000000000001/transactions/40000000-0000-0000-0000-000000000001/receipt.jpg',null),
('transaction-receipts','workspaces/10000000-0000-0000-0000-000000000003/transactions/40000000-0000-0000-0000-000000000003/own.jpg','00000000-0000-0000-0000-000000000001'),
('transaction-receipts','workspaces/10000000-0000-0000-0000-000000000003/transactions/40000000-0000-0000-0000-000000000003/other.jpg','00000000-0000-0000-0000-000000000002');
insert into public.transaction_attachments(workspace_id,transaction_id,storage_bucket,storage_path,file_name,uploaded_by_user_id) values
('10000000-0000-0000-0000-000000000003','40000000-0000-0000-0000-000000000003','transaction-receipts','workspaces/10000000-0000-0000-0000-000000000003/transactions/40000000-0000-0000-0000-000000000003/other.jpg','malicious-reference.jpg','00000000-0000-0000-0000-000000000001');

do $$
declare result jsonb;
begin
  result := public.prepare_account_deletion('00000000-0000-0000-0000-000000000001');
  if result->>'status' <> 'prepared' then raise exception 'Preparation failed'; end if;
  if (select count(*) from public.account_deletion_objects) <> 2 then
    raise exception 'Storage cleanup was not scoped to authoritative ownership';
  end if;
  if exists(select 1 from public.account_deletion_objects where name like '%other.jpg') then
    raise exception 'Attachment metadata authorized another user object';
  end if;
  if exists(select 1 from public.workspaces where name = 'Solo') then raise exception 'Sole workspace remains'; end if;
  if (select count(*) from public.transactions) <> 1 then raise exception 'Shared history lost'; end if;
  if exists(select 1 from public.transactions where created_by_user_id is not null or updated_by_user_id is null) then
    raise exception 'Author cleanup changed another author';
  end if;
  if (select count(*) from public.recurring_transaction_occurrences) <> 1 then raise exception 'Shared recurring history lost'; end if;
  if exists(select 1 from public.error_reports) or exists(select 1 from public.activity_logs)
    or exists(select 1 from public.workspace_invites) or exists(select 1 from public.user_notifications) then
    raise exception 'User-specific records remain';
  end if;
  result := public.prepare_account_deletion('00000000-0000-0000-0000-000000000001');
  if result->>'status' <> 'prepared' or (select count(*) from public.account_deletion_objects) <> 2 then
    raise exception 'Retry did not preserve cleanup manifest';
  end if;
  begin
    insert into public.workspace_members(workspace_id,user_id,role) values
    ('10000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000001','member');
    raise exception 'Deleting user rejoined';
  exception when insufficient_privilege then null;
  end;
end;
$$;
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$
begin
  begin
    perform public.prepare_account_deletion('00000000-0000-0000-0000-000000000002');
    raise exception 'Client accessed destructive helper';
  exception when insufficient_privilege then null;
  end;
  if has_table_privilege('authenticated','public.account_deletion_objects','select') then
    raise exception 'Cleanup manifest exposed';
  end if;
  begin
    update public.profiles set display_name = 'Reactivated'
      where id = '00000000-0000-0000-0000-000000000001';
    raise exception 'Deleting account could update its profile';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into storage.objects(bucket_id,name,owner_id) values
    ('transaction-receipts','workspaces/10000000-0000-0000-0000-000000000003/transactions/40000000-0000-0000-0000-000000000003/new.jpg','00000000-0000-0000-0000-000000000001');
    raise exception 'Deleting account could upload another receipt';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;
set request.jwt.claim.sub = '';
insert into storage.objects(bucket_id,name,owner_id) values
('another-bucket','late-upload.jpg','00000000-0000-0000-0000-000000000001');
do $$
begin
  perform public.prepare_account_deletion('00000000-0000-0000-0000-000000000001');
  if (select count(*) from public.account_deletion_objects) <> 3 then
    raise exception 'Retry missed a newly owned storage object';
  end if;
end;
$$;
delete from auth.users where id = '00000000-0000-0000-0000-000000000001';
do $$
begin
  if exists(select 1 from public.profiles where id = '00000000-0000-0000-0000-000000000001')
    or exists(select 1 from public.account_deletion_jobs) or exists(select 1 from public.account_deletion_objects) then
    raise exception 'Auth deletion did not remove profile and retry state';
  end if;
  if (select count(*) from public.workspaces) <> 4 or (select count(*) from public.transactions) <> 1 then
    raise exception 'Auth deletion affected other account data';
  end if;
end;
$$;
