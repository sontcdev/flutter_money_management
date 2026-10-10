begin;

create or replace function public.create_category_rpc(p_workspace_id uuid, p_name text, p_type text, p_icon_name text, p_color_value text, p_id uuid default null, p_created_at timestamptz default now(), p_updated_at timestamptz default now())
returns public.categories as $$
declare inserted public.categories;
begin
  if auth.uid() is null or not public.is_workspace_member(p_workspace_id) then
    raise exception 'Active workspace membership required' using errcode = '42501';
  end if;

  insert into public.categories(id, workspace_id, name, normalized_name, type, icon_name, color_value, created_by_user_id, updated_by_user_id, created_at, updated_at)
  values (coalesce(p_id, gen_random_uuid()), p_workspace_id, trim(p_name), public.normalize_name(p_name), p_type, p_icon_name, p_color_value, auth.uid(), auth.uid(), p_created_at, p_updated_at)
  returning * into inserted;
  return inserted;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.update_category_rpc(p_category_id uuid, p_workspace_id uuid, p_name text, p_type text, p_icon_name text, p_color_value text, p_updated_at timestamptz default now())
returns void as $$
begin
  if auth.uid() is null or not public.is_workspace_member(p_workspace_id) then
    raise exception 'Active workspace membership required' using errcode = '42501';
  end if;

  update public.categories set name = trim(p_name), normalized_name = public.normalize_name(p_name), type = p_type, icon_name = p_icon_name, color_value = p_color_value, updated_by_user_id = auth.uid(), updated_at = p_updated_at, version = version + 1
  where id = p_category_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.soft_delete_category_rpc(p_category_id uuid, p_workspace_id uuid)
returns void as $$
begin
  if auth.uid() is null or not public.is_workspace_member(p_workspace_id) then
    raise exception 'Active workspace membership required' using errcode = '42501';
  end if;

  update public.categories set deleted_at = now(), deleted_by_user_id = auth.uid(), updated_by_user_id = auth.uid(), updated_at = now(), version = version + 1
  where id = p_category_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.create_transaction_rpc(p_workspace_id uuid, p_category_id uuid, p_amount_minor bigint, p_currency_code text, p_transaction_type text, p_transaction_at timestamptz, p_wallet_id uuid, p_to_wallet_id uuid default null, p_note text default null, p_client_reference_id text default null, p_allow_overdraft_override boolean default false, p_id uuid default null, p_created_at timestamptz default now(), p_updated_at timestamptz default now())
returns public.transactions as $$
declare inserted public.transactions;
begin
  if auth.uid() is null or not public.is_workspace_member(p_workspace_id) then
    raise exception 'Active workspace membership required' using errcode = '42501';
  end if;

  if p_category_id is not null and not exists (select 1 from public.categories c where c.id = p_category_id and c.workspace_id = p_workspace_id) then
    raise exception 'Category not found in workspace' using errcode = '42501';
  end if;

  if p_wallet_id is not null and not exists (select 1 from public.wallets w where w.id = p_wallet_id and w.workspace_id = p_workspace_id) then
    raise exception 'Wallet not found in workspace' using errcode = '42501';
  end if;

  if p_to_wallet_id is not null and not exists (select 1 from public.wallets w where w.id = p_to_wallet_id and w.workspace_id = p_workspace_id) then
    raise exception 'Wallet not found in workspace' using errcode = '42501';
  end if;

  insert into public.transactions(id, workspace_id, category_id, amount_minor, currency_code, transaction_type, transaction_at, wallet_id, to_wallet_id, note, client_reference_id, created_by_user_id, updated_by_user_id, created_at, updated_at)
  values (coalesce(p_id, gen_random_uuid()), p_workspace_id, p_category_id, p_amount_minor, p_currency_code, p_transaction_type, p_transaction_at, p_wallet_id, p_to_wallet_id, p_note, p_client_reference_id, auth.uid(), auth.uid(), p_created_at, p_updated_at)
  returning * into inserted;
  return inserted;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.update_transaction_rpc(p_transaction_id uuid, p_workspace_id uuid, p_category_id uuid, p_amount_minor bigint, p_currency_code text, p_transaction_type text, p_transaction_at timestamptz, p_wallet_id uuid, p_to_wallet_id uuid default null, p_note text default null, p_allow_overdraft_override boolean default false, p_updated_at timestamptz default now())
returns void as $$
begin
  if auth.uid() is null or not public.is_workspace_member(p_workspace_id) then
    raise exception 'Active workspace membership required' using errcode = '42501';
  end if;

  if p_category_id is not null and not exists (select 1 from public.categories c where c.id = p_category_id and c.workspace_id = p_workspace_id) then
    raise exception 'Category not found in workspace' using errcode = '42501';
  end if;

  if p_wallet_id is not null and not exists (select 1 from public.wallets w where w.id = p_wallet_id and w.workspace_id = p_workspace_id) then
    raise exception 'Wallet not found in workspace' using errcode = '42501';
  end if;

  if p_to_wallet_id is not null and not exists (select 1 from public.wallets w where w.id = p_to_wallet_id and w.workspace_id = p_workspace_id) then
    raise exception 'Wallet not found in workspace' using errcode = '42501';
  end if;

  update public.transactions set category_id = p_category_id, amount_minor = p_amount_minor, currency_code = p_currency_code, transaction_type = p_transaction_type, transaction_at = p_transaction_at, wallet_id = p_wallet_id, to_wallet_id = p_to_wallet_id, note = p_note, updated_by_user_id = auth.uid(), updated_at = p_updated_at, version = version + 1
  where id = p_transaction_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.soft_delete_transaction_rpc(p_transaction_id uuid, p_workspace_id uuid)
returns void as $$
begin
  if auth.uid() is null or not public.is_workspace_member(p_workspace_id) then
    raise exception 'Active workspace membership required' using errcode = '42501';
  end if;

  update public.transactions set deleted_at = now(), deleted_by_user_id = auth.uid(), updated_by_user_id = auth.uid(), updated_at = now(), version = version + 1
  where id = p_transaction_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.create_budget_rpc(p_workspace_id uuid, p_category_id uuid, p_period_type text, p_period_start timestamptz, p_period_end timestamptz, p_limit_minor bigint, p_currency_code text, p_allow_overdraft boolean default false, p_id uuid default null, p_created_at timestamptz default now(), p_updated_at timestamptz default now())
returns public.budgets as $$
declare inserted public.budgets;
begin
  if auth.uid() is null or not public.is_workspace_member(p_workspace_id) then
    raise exception 'Active workspace membership required' using errcode = '42501';
  end if;

  if p_category_id is not null and not exists (select 1 from public.categories c where c.id = p_category_id and c.workspace_id = p_workspace_id) then
    raise exception 'Category not found in workspace' using errcode = '42501';
  end if;

  insert into public.budgets(id, workspace_id, category_id, period_type, period_start, period_end, limit_minor, currency_code, allow_overdraft, created_by_user_id, updated_by_user_id, created_at, updated_at)
  values (coalesce(p_id, gen_random_uuid()), p_workspace_id, p_category_id, p_period_type, p_period_start, p_period_end, p_limit_minor, p_currency_code, p_allow_overdraft, auth.uid(), auth.uid(), p_created_at, p_updated_at)
  returning * into inserted;
  return inserted;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.update_budget_rpc(p_budget_id uuid, p_workspace_id uuid, p_category_id uuid, p_period_type text, p_period_start timestamptz, p_period_end timestamptz, p_limit_minor bigint, p_currency_code text, p_allow_overdraft boolean default false, p_updated_at timestamptz default now())
returns void as $$
begin
  if auth.uid() is null or not public.is_workspace_member(p_workspace_id) then
    raise exception 'Active workspace membership required' using errcode = '42501';
  end if;

  if p_category_id is not null and not exists (select 1 from public.categories c where c.id = p_category_id and c.workspace_id = p_workspace_id) then
    raise exception 'Category not found in workspace' using errcode = '42501';
  end if;

  update public.budgets set category_id = p_category_id, period_type = p_period_type, period_start = p_period_start, period_end = p_period_end, limit_minor = p_limit_minor, currency_code = p_currency_code, allow_overdraft = p_allow_overdraft, updated_by_user_id = auth.uid(), updated_at = p_updated_at, version = version + 1
  where id = p_budget_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.soft_delete_budget_rpc(p_budget_id uuid, p_workspace_id uuid)
returns void as $$
begin
  if auth.uid() is null or not public.is_workspace_member(p_workspace_id) then
    raise exception 'Active workspace membership required' using errcode = '42501';
  end if;

  update public.budgets set deleted_at = now(), deleted_by_user_id = auth.uid(), updated_by_user_id = auth.uid(), updated_at = now(), version = version + 1
  where id = p_budget_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

commit;
