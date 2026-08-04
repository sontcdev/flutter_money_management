-- Additive migration: wallets + transfer transaction type.
-- Safe to run on an existing database with live data. Idempotent.
-- Run AFTER 01_create_schema.sql. Does NOT drop or reset anything.

begin;

-- ---------------------------------------------------------------------------
-- 1. wallets table
-- ---------------------------------------------------------------------------

create table if not exists public.wallets (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  name text not null,
  normalized_name text not null,
  wallet_type text not null default 'cash' check (wallet_type in ('cash', 'bank', 'ewallet', 'credit_card', 'savings', 'other')),
  icon_name text not null default 'wallet',
  color_value text not null default 'FF00884B' check (color_value ~ '^[0-9A-F]{8}$'),
  -- May be negative: credit cards start with a debt balance.
  opening_balance_minor bigint not null default 0,
  currency_code text not null default 'VND',
  is_default boolean not null default false,
  is_archived boolean not null default false,
  sort_order integer not null default 0,
  created_by_user_id uuid not null references public.profiles(id),
  updated_by_user_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by_user_id uuid references public.profiles(id),
  version integer not null default 1 check (version > 0),
  metadata jsonb not null default '{}'::jsonb
);

create unique index if not exists wallets_workspace_name_unique_idx
  on public.wallets(workspace_id, normalized_name) where deleted_at is null;
create index if not exists wallets_workspace_idx
  on public.wallets(workspace_id) where deleted_at is null;
-- At most one default wallet per workspace.
create unique index if not exists wallets_workspace_default_unique_idx
  on public.wallets(workspace_id) where is_default and deleted_at is null;

drop trigger if exists wallets_updated_at on public.wallets;
create trigger wallets_updated_at before update on public.wallets
  for each row execute function public.set_updated_at();

create or replace function public.wallets_normalize_name()
returns trigger as $$
begin
  new.normalized_name = public.normalize_name(new.name);
  return new;
end;
$$ language plpgsql;

drop trigger if exists wallets_normalize_name_trigger on public.wallets;
create trigger wallets_normalize_name_trigger before insert or update of name on public.wallets
  for each row execute function public.wallets_normalize_name();

alter table public.wallets enable row level security;

-- Mirrors the categories policy set: members read, managers write, no DELETE
-- policy (removal always goes through the soft-delete RPC).
drop policy if exists wallets_select_member on public.wallets;
create policy wallets_select_member on public.wallets
  for select using (public.is_workspace_member(workspace_id) and deleted_at is null);
drop policy if exists wallets_insert_manager on public.wallets;
create policy wallets_insert_manager on public.wallets
  for insert with check (public.can_manage_workspace(workspace_id));
drop policy if exists wallets_update_manager on public.wallets;
create policy wallets_update_manager on public.wallets
  for update using (public.can_manage_workspace(workspace_id))
  with check (public.can_manage_workspace(workspace_id));

-- ---------------------------------------------------------------------------
-- 2. transactions: wallet columns + transfer type
-- ---------------------------------------------------------------------------

alter table public.transactions
  add column if not exists wallet_id uuid references public.wallets(id),
  add column if not exists to_wallet_id uuid references public.wallets(id);

alter table public.transactions drop constraint if exists transactions_transaction_type_check;
alter table public.transactions add constraint transactions_transaction_type_check
  check (transaction_type in ('expense', 'income', 'transfer'));

-- Transfers carry no category, so category_id can no longer be mandatory.
alter table public.transactions alter column category_id drop not null;

alter table public.recurring_transactions
  add column if not exists wallet_id uuid references public.wallets(id);

-- ---------------------------------------------------------------------------
-- 3. Backfill: one default "Tiền mặt" wallet per workspace, all existing
--    transactions assigned to it. Must run before the NOT NULL constraint.
-- ---------------------------------------------------------------------------

insert into public.wallets (workspace_id, name, normalized_name, wallet_type, is_default, created_by_user_id, updated_by_user_id)
select w.id, 'Tiền mặt', public.normalize_name('Tiền mặt'), 'cash', true, w.owner_user_id, w.owner_user_id
from public.workspaces w
where not exists (select 1 from public.wallets x where x.workspace_id = w.id and x.deleted_at is null);

update public.transactions t
set wallet_id = w.id
from public.wallets w
where w.workspace_id = t.workspace_id and w.is_default and w.deleted_at is null
  and t.wallet_id is null;

update public.recurring_transactions r
set wallet_id = w.id
from public.wallets w
where w.workspace_id = r.workspace_id and w.is_default and w.deleted_at is null
  and r.wallet_id is null;

-- Every transaction must belong to a wallet from now on.
alter table public.transactions alter column wallet_id set not null;

-- Shape constraint, added after backfill so existing rows validate.
alter table public.transactions drop constraint if exists transactions_transfer_shape_check;
alter table public.transactions add constraint transactions_transfer_shape_check check (
  (transaction_type = 'transfer'
    and to_wallet_id is not null
    and to_wallet_id <> wallet_id
    and category_id is null)
  or (transaction_type <> 'transfer'
    and category_id is not null
    and to_wallet_id is null)
);

create index if not exists transactions_workspace_wallet_date_idx
  on public.transactions(workspace_id, wallet_id, transaction_at desc);
create index if not exists transactions_workspace_to_wallet_idx
  on public.transactions(workspace_id, to_wallet_id) where to_wallet_id is not null;

-- ---------------------------------------------------------------------------
-- 4. Wallet RPCs
-- ---------------------------------------------------------------------------

create or replace function public.create_wallet_rpc(
  p_workspace_id uuid,
  p_name text,
  p_wallet_type text,
  p_icon_name text,
  p_color_value text,
  p_opening_balance_minor bigint default 0,
  p_currency_code text default 'VND',
  p_is_default boolean default false,
  p_sort_order integer default 0,
  p_id uuid default null
)
returns public.wallets as $$
declare inserted public.wallets;
begin
  if not public.can_manage_workspace(p_workspace_id) then
    raise exception 'Only workspace owner or admin can create wallets';
  end if;

  if p_is_default then
    update public.wallets set is_default = false, updated_by_user_id = auth.uid(), version = version + 1
    where workspace_id = p_workspace_id and is_default and deleted_at is null;
  end if;

  insert into public.wallets(id, workspace_id, name, normalized_name, wallet_type, icon_name, color_value,
    opening_balance_minor, currency_code, is_default, sort_order, created_by_user_id, updated_by_user_id)
  values (coalesce(p_id, gen_random_uuid()), p_workspace_id, p_name, public.normalize_name(p_name), p_wallet_type,
    p_icon_name, p_color_value, p_opening_balance_minor, p_currency_code, p_is_default, p_sort_order,
    auth.uid(), auth.uid())
  returning * into inserted;

  return inserted;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.update_wallet_rpc(
  p_wallet_id uuid,
  p_workspace_id uuid,
  p_name text,
  p_wallet_type text,
  p_icon_name text,
  p_color_value text,
  p_opening_balance_minor bigint,
  p_currency_code text,
  p_is_default boolean,
  p_is_archived boolean default false,
  p_sort_order integer default 0
)
returns void as $$
begin
  if not public.can_manage_workspace(p_workspace_id) then
    raise exception 'Only workspace owner or admin can update wallets';
  end if;

  if p_is_default then
    update public.wallets set is_default = false, updated_by_user_id = auth.uid(), version = version + 1
    where workspace_id = p_workspace_id and is_default and id <> p_wallet_id and deleted_at is null;
  end if;

  update public.wallets set
    name = p_name,
    normalized_name = public.normalize_name(p_name),
    wallet_type = p_wallet_type,
    icon_name = p_icon_name,
    color_value = p_color_value,
    opening_balance_minor = p_opening_balance_minor,
    currency_code = p_currency_code,
    is_default = p_is_default,
    is_archived = p_is_archived,
    sort_order = p_sort_order,
    updated_by_user_id = auth.uid(),
    updated_at = now(),
    version = version + 1
  where id = p_wallet_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.set_default_wallet_rpc(p_wallet_id uuid, p_workspace_id uuid)
returns void as $$
begin
  if not public.can_manage_workspace(p_workspace_id) then
    raise exception 'Only workspace owner or admin can change the default wallet';
  end if;

  update public.wallets set is_default = false, updated_by_user_id = auth.uid(), version = version + 1
  where workspace_id = p_workspace_id and is_default and id <> p_wallet_id and deleted_at is null;

  update public.wallets set is_default = true, updated_by_user_id = auth.uid(), updated_at = now(), version = version + 1
  where id = p_wallet_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.soft_delete_wallet_rpc(p_wallet_id uuid, p_workspace_id uuid)
returns void as $$
declare usage_count integer;
begin
  if not public.can_manage_workspace(p_workspace_id) then
    raise exception 'Only workspace owner or admin can delete wallets';
  end if;

  -- A wallet holding transactions can only be archived, never deleted:
  -- removing it would orphan the balance history.
  select count(*) into usage_count from public.transactions
  where deleted_at is null and (wallet_id = p_wallet_id or to_wallet_id = p_wallet_id);
  if usage_count > 0 then
    raise exception 'WALLET_IN_USE: wallet still has % transaction(s)', usage_count;
  end if;

  update public.wallets set
    deleted_at = now(),
    deleted_by_user_id = auth.uid(),
    updated_by_user_id = auth.uid(),
    updated_at = now(),
    is_default = false,
    version = version + 1
  where id = p_wallet_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

-- ---------------------------------------------------------------------------
-- 4b. Every workspace must always own at least one wallet, otherwise the
--     NOT NULL transactions.wallet_id makes the workspace unusable.
-- ---------------------------------------------------------------------------

create or replace function public.ensure_default_wallet(p_workspace_id uuid, p_user_id uuid)
returns uuid as $$
declare wallet_id uuid;
begin
  select id into wallet_id from public.wallets
  where workspace_id = p_workspace_id and deleted_at is null
  order by is_default desc, created_at
  limit 1;

  if wallet_id is null then
    insert into public.wallets(workspace_id, name, normalized_name, wallet_type, is_default,
      created_by_user_id, updated_by_user_id)
    values (p_workspace_id, 'Tiền mặt', public.normalize_name('Tiền mặt'), 'cash', true, p_user_id, p_user_id)
    returning id into wallet_id;
  end if;

  return wallet_id;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.ensure_workspace_setup_for_user(target_user_id uuid, target_email text, target_raw_user_meta_data jsonb default '{}'::jsonb)
returns void as $$
declare
  new_workspace_id uuid;
begin
  insert into public.profiles(id, email, display_name)
  values (target_user_id, target_email, coalesce(target_raw_user_meta_data->>'display_name', split_part(target_email, '@', 1)))
  on conflict (id) do update set email = excluded.email, updated_at = now();

  select id into new_workspace_id
  from public.workspaces
  where owner_user_id = target_user_id and type = 'personal' and deleted_at is null
  order by created_at
  limit 1;

  if new_workspace_id is null then
    insert into public.workspaces(type, name, owner_user_id)
    values ('personal', 'My Workspace', target_user_id)
    returning id into new_workspace_id;
  end if;

  insert into public.workspace_members(workspace_id, user_id, role, membership_status, joined_at)
  values (new_workspace_id, target_user_id, 'owner', 'active', now())
  on conflict (workspace_id, user_id) do update set role = 'owner', membership_status = 'active', removed_at = null, updated_at = now();

  perform public.ensure_default_wallet(new_workspace_id, target_user_id);
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.create_group_workspace_v2(workspace_name text, workspace_description text default null, workspace_avatar_path text default null)
returns uuid as $$
declare
  new_workspace_id uuid;
begin
  insert into public.workspaces(type, name, owner_user_id, settings)
  values ('group', trim(workspace_name), auth.uid(), jsonb_build_object('description', nullif(trim(coalesce(workspace_description, '')), ''), 'avatar_path', nullif(trim(coalesce(workspace_avatar_path, '')), '')))
  returning id into new_workspace_id;
  insert into public.workspace_members(workspace_id, user_id, role, membership_status, joined_at)
  values (new_workspace_id, auth.uid(), 'owner', 'active', now());
  perform public.ensure_default_wallet(new_workspace_id, auth.uid());
  perform public.log_workspace_activity(new_workspace_id, 'workspace', new_workspace_id, 'workspace_created', 'Workspace created');
  return new_workspace_id;
end;
$$ language plpgsql security definer set search_path = public;

-- ---------------------------------------------------------------------------
-- 5. Transaction RPCs gain wallet parameters
--    Old overloads are dropped first: keeping them would make PostgREST calls
--    ambiguous, since the new parameters have defaults.
-- ---------------------------------------------------------------------------

do $$
declare r record;
begin
  for r in
    select oid::regprocedure as signature from pg_proc
    where proname in ('create_transaction_rpc', 'update_transaction_rpc')
      and pronamespace = 'public'::regnamespace
  loop
    execute 'drop function ' || r.signature;
  end loop;
end $$;

create or replace function public.create_transaction_rpc(
  p_workspace_id uuid,
  p_category_id uuid,
  p_amount_minor bigint,
  p_currency_code text,
  p_transaction_type text,
  p_transaction_at timestamptz,
  p_wallet_id uuid,
  p_to_wallet_id uuid default null,
  p_note text default null,
  p_client_reference_id text default null,
  p_allow_overdraft_override boolean default false,
  p_id uuid default null,
  p_created_at timestamptz default now(),
  p_updated_at timestamptz default now()
)
returns public.transactions as $$
declare inserted public.transactions;
begin
  insert into public.transactions(id, workspace_id, category_id, amount_minor, currency_code, transaction_type,
    transaction_at, wallet_id, to_wallet_id, note, client_reference_id, created_by_user_id, updated_by_user_id,
    created_at, updated_at)
  values (coalesce(p_id, gen_random_uuid()), p_workspace_id, p_category_id, p_amount_minor, p_currency_code,
    p_transaction_type, p_transaction_at, p_wallet_id, p_to_wallet_id, p_note, p_client_reference_id,
    auth.uid(), auth.uid(), p_created_at, p_updated_at)
  returning * into inserted;
  return inserted;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.update_transaction_rpc(
  p_transaction_id uuid,
  p_workspace_id uuid,
  p_category_id uuid,
  p_amount_minor bigint,
  p_currency_code text,
  p_transaction_type text,
  p_transaction_at timestamptz,
  p_wallet_id uuid,
  p_to_wallet_id uuid default null,
  p_note text default null,
  p_allow_overdraft_override boolean default false,
  p_updated_at timestamptz default now()
)
returns void as $$
begin
  update public.transactions set
    category_id = p_category_id,
    amount_minor = p_amount_minor,
    currency_code = p_currency_code,
    transaction_type = p_transaction_type,
    transaction_at = p_transaction_at,
    wallet_id = p_wallet_id,
    to_wallet_id = p_to_wallet_id,
    note = p_note,
    updated_by_user_id = auth.uid(),
    updated_at = p_updated_at,
    version = version + 1
  where id = p_transaction_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

-- ---------------------------------------------------------------------------
-- 6. Grants (01_create_schema.sql grants in bulk; new objects need their own)
-- ---------------------------------------------------------------------------

grant select, insert, update, delete on public.wallets to authenticated;
grant all on public.wallets to service_role;
grant execute on all routines in schema public to authenticated;
grant all on all routines in schema public to service_role;

commit;

-- PostgREST caches the schema; without this reload the client keeps returning
-- PGRST205 "Could not find the table 'public.wallets' in the schema cache".
notify pgrst, 'reload schema';
