begin;

create or replace function public.account_deletion_shared_workspaces(p_user_id uuid)
returns table(workspace_id uuid, workspace_name text)
language sql stable security definer
set search_path = ''
as $$
  select w.id, w.name
  from public.workspaces w
  where (
    w.owner_user_id = p_user_id
    or exists (
      select 1 from public.workspace_members mine
      where mine.workspace_id = w.id
        and mine.user_id = p_user_id
        and mine.membership_status in ('active', 'pending')
    )
  )
  and exists (
    select 1 from public.workspace_members other
    where other.workspace_id = w.id
      and other.user_id <> p_user_id
      and other.membership_status in ('active', 'pending')
  )
  order by w.name, w.id;
$$;

revoke all on function public.account_deletion_shared_workspaces(uuid) from public, anon, authenticated;
grant execute on function public.account_deletion_shared_workspaces(uuid) to service_role;

create or replace function public.get_account_deletion_blockers()
returns table(workspace_id uuid, workspace_name text)
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  return query select * from public.account_deletion_shared_workspaces(auth.uid());
end;
$$;

revoke all on function public.get_account_deletion_blockers() from public, anon;
grant execute on function public.get_account_deletion_blockers() to authenticated;

create table public.account_deletion_jobs (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.account_deletion_objects (
  user_id uuid not null references public.account_deletion_jobs(user_id) on delete cascade,
  bucket_id text not null,
  name text not null,
  primary key (user_id, bucket_id, name)
);

alter table public.account_deletion_jobs enable row level security;
alter table public.account_deletion_objects enable row level security;
revoke all on public.account_deletion_jobs, public.account_deletion_objects from public, anon, authenticated;
grant all on public.account_deletion_jobs, public.account_deletion_objects to service_role;

do $$
declare table_name text; column_name text;
begin
  foreach table_name in array array['categories', 'wallets', 'transactions', 'budgets', 'recurring_transactions'] loop
    foreach column_name in array array['created_by_user_id', 'updated_by_user_id', 'deleted_by_user_id'] loop
      execute format('alter table public.%I alter column %I drop not null', table_name, column_name);
      execute format('alter table public.%I drop constraint %I', table_name, table_name || '_' || column_name || '_fkey');
      execute format('alter table public.%I add constraint %I foreign key (%I) references public.profiles(id) on delete set null', table_name, table_name || '_' || column_name || '_fkey', column_name);
    end loop;
  end loop;
end;
$$;

alter table public.workspace_members drop constraint workspace_members_invited_by_user_id_fkey;
alter table public.workspace_members add constraint workspace_members_invited_by_user_id_fkey
  foreign key (invited_by_user_id) references public.profiles(id) on delete set null;

create function public.reject_account_deletion_writes()
returns trigger language plpgsql security definer
set search_path = ''
as $$
begin
  if exists (select 1 from public.account_deletion_jobs where user_id = auth.uid()) then
    raise exception 'Account deletion is in progress' using errcode = '42501';
  end if;
  if tg_table_name = 'workspace_members' then
    if exists (select 1 from public.account_deletion_jobs where user_id = new.user_id) then
      raise exception 'Account deletion is in progress' using errcode = '42501';
    end if;
  elsif tg_table_name = 'workspaces' then
    if exists (select 1 from public.account_deletion_jobs where user_id = new.owner_user_id) then
      raise exception 'Account deletion is in progress' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;
revoke all on function public.reject_account_deletion_writes() from public, anon, authenticated;

do $$
declare table_name text;
begin
  foreach table_name in array array['profiles', 'workspaces', 'workspace_members', 'workspace_invites', 'user_notifications', 'categories', 'wallets', 'transactions', 'transaction_attachments', 'budgets', 'activity_logs', 'user_workspace_preferences', 'error_reports', 'recurring_transactions', 'recurring_transaction_occurrences'] loop
    execute format('create trigger account_deletion_write_guard before insert or update on public.%I for each row execute function public.reject_account_deletion_writes()', table_name);
  end loop;
end;
$$;

create function public.prepare_account_deletion(p_user_id uuid)
returns jsonb language plpgsql security definer
set search_path = ''
as $$
declare
  blockers jsonb;
  own_workspaces uuid[];
  target_email text;
  table_name text;
  column_name text;
begin
  if p_user_id is null then
    raise exception 'User required' using errcode = '22023';
  end if;
  lock table public.profiles, public.workspaces, public.workspace_members,
    public.workspace_invites, public.transactions, storage.objects
    in share row exclusive mode;
  if exists (select 1 from public.account_deletion_jobs where user_id = p_user_id) then
    insert into public.account_deletion_objects(user_id, bucket_id, name)
      select p_user_id, bucket_id, name from storage.objects
      where owner_id = p_user_id::text on conflict do nothing;
    return jsonb_build_object('status', 'prepared');
  end if;
  select email into target_email from public.profiles where id = p_user_id;
  if not found then
    raise exception 'Account not found' using errcode = 'P0002';
  end if;
  select coalesce(jsonb_agg(to_jsonb(b)), '[]'::jsonb) into blockers
    from public.account_deletion_shared_workspaces(p_user_id) b;
  if jsonb_array_length(blockers) > 0 then
    return jsonb_build_object('status', 'blocked', 'workspaces', blockers);
  end if;
  select coalesce(array_agg(id), array[]::uuid[]) into own_workspaces
    from public.workspaces where owner_user_id = p_user_id;
  insert into public.account_deletion_jobs(user_id) values (p_user_id);
  insert into public.account_deletion_objects(user_id, bucket_id, name)
    select p_user_id, o.bucket_id, o.name from storage.objects o
    where o.owner_id = p_user_id::text
      or (o.bucket_id = 'transaction-receipts'
        and split_part(o.name, '/', 1) = 'workspaces'
        and split_part(o.name, '/', 2) = any(select id::text from unnest(own_workspaces) id));
  delete from public.user_notifications where recipient_user_id = p_user_id
    or payload->>'invited_by_user_id' = p_user_id::text
    or payload->>'invite_id' in (
      select id::text from public.workspace_invites
      where invited_by_user_id = p_user_id or accepted_by_user_id = p_user_id
        or lower(email) = lower(target_email)
    );
  delete from public.workspace_invites where invited_by_user_id = p_user_id
    or accepted_by_user_id = p_user_id or lower(email) = lower(target_email);
  delete from public.activity_logs where actor_user_id = p_user_id;
  delete from public.error_reports where user_id = p_user_id;
  delete from public.user_workspace_preferences where user_id = p_user_id;
  delete from public.transaction_attachments a where uploaded_by_user_id = p_user_id
    or exists (select 1 from public.account_deletion_objects o
      where o.user_id = p_user_id and o.bucket_id = a.storage_bucket and o.name = a.storage_path);
  update public.transactions t set receipt_path = null
    where exists (select 1 from public.account_deletion_objects o
      where o.user_id = p_user_id and o.bucket_id = 'transaction-receipts' and o.name = t.receipt_path);
  delete from public.recurring_transaction_occurrences where workspace_id = any(own_workspaces);
  delete from public.recurring_transactions where workspace_id = any(own_workspaces);
  delete from public.budgets where workspace_id = any(own_workspaces);
  delete from public.transactions where workspace_id = any(own_workspaces);
  delete from public.wallets where workspace_id = any(own_workspaces);
  delete from public.categories where workspace_id = any(own_workspaces);
  delete from public.workspaces where id = any(own_workspaces);
  delete from public.workspace_members where user_id = p_user_id;
  foreach table_name in array array['categories', 'wallets', 'transactions', 'budgets', 'recurring_transactions'] loop
    foreach column_name in array array['created_by_user_id', 'updated_by_user_id', 'deleted_by_user_id'] loop
      execute format('update public.%I set %I = null where %I = $1', table_name, column_name, column_name) using p_user_id;
    end loop;
  end loop;
  update public.workspace_members set invited_by_user_id = null where invited_by_user_id = p_user_id;
  update public.profiles set status = 'deleted' where id = p_user_id;
  return jsonb_build_object('status', 'prepared');
end;
$$;

revoke all on function public.prepare_account_deletion(uuid) from public, anon, authenticated;
grant execute on function public.prepare_account_deletion(uuid) to service_role;

commit;
