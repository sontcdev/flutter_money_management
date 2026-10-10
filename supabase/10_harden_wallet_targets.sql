begin;

create or replace function public.update_wallet_rpc(p_wallet_id uuid, p_workspace_id uuid, p_name text, p_wallet_type text, p_icon_name text, p_color_value text, p_opening_balance_minor bigint, p_currency_code text, p_is_default boolean, p_is_archived boolean default false, p_sort_order integer default 0)
returns void as $$
begin
  if not public.can_manage_workspace(p_workspace_id) then raise exception 'Only workspace owner or admin can update wallets'; end if;

  if not exists (
    select 1 from public.wallets
    where id = p_wallet_id and workspace_id = p_workspace_id and deleted_at is null
  ) then
    raise exception 'Wallet does not belong to workspace' using errcode = '42501';
  end if;

  if p_is_default then
    update public.wallets set is_default = false, updated_by_user_id = auth.uid(), version = version + 1
    where workspace_id = p_workspace_id and is_default and id <> p_wallet_id and deleted_at is null;
  end if;

  update public.wallets set name = trim(p_name), normalized_name = public.normalize_name(p_name), wallet_type = p_wallet_type, icon_name = p_icon_name, color_value = p_color_value, opening_balance_minor = p_opening_balance_minor, currency_code = p_currency_code, is_default = p_is_default, is_archived = p_is_archived, sort_order = p_sort_order, updated_by_user_id = auth.uid(), updated_at = now(), version = version + 1
  where id = p_wallet_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.set_default_wallet_rpc(p_wallet_id uuid, p_workspace_id uuid)
returns void as $$
begin
  if not public.can_manage_workspace(p_workspace_id) then raise exception 'Only workspace owner or admin can change the default wallet'; end if;

  if not exists (
    select 1 from public.wallets
    where id = p_wallet_id and workspace_id = p_workspace_id and deleted_at is null
  ) then
    raise exception 'Wallet does not belong to workspace' using errcode = '42501';
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
  if not public.can_manage_workspace(p_workspace_id) then raise exception 'Only workspace owner or admin can delete wallets'; end if;

  if not exists (
    select 1 from public.wallets
    where id = p_wallet_id and workspace_id = p_workspace_id and deleted_at is null
  ) then
    raise exception 'Wallet does not belong to workspace' using errcode = '42501';
  end if;

  -- A wallet holding transactions can only be archived, never deleted:
  -- removing it would orphan the balance history.
  select count(*) into usage_count from public.transactions
  where deleted_at is null and (wallet_id = p_wallet_id or to_wallet_id = p_wallet_id);
  if usage_count > 0 then
    raise exception 'WALLET_IN_USE: wallet still has % transaction(s)', usage_count;
  end if;

  update public.wallets set deleted_at = now(), deleted_by_user_id = auth.uid(), updated_by_user_id = auth.uid(), updated_at = now(), is_default = false, version = version + 1
  where id = p_wallet_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

commit;
