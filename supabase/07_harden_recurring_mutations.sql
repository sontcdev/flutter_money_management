begin;

create or replace function public.create_recurring_transaction_rpc(id uuid, workspace_id uuid, title text, category_id uuid, amount_minor bigint, currency_code text, transaction_type text, frequency text, mode text, interval_count integer, start_date timestamptz, next_occurrence_at timestamptz, reminder_days_before integer, is_active boolean, created_by_user_id uuid, updated_by_user_id uuid, created_at timestamptz, updated_at timestamptz, note text default null, day_of_month integer default null, day_of_week integer default null, month_of_year integer default null, end_date timestamptz default null)
returns public.recurring_transactions as $$
declare inserted public.recurring_transactions;
begin
  if auth.uid() is null or not public.is_workspace_member(create_recurring_transaction_rpc.workspace_id) then
    raise exception 'Active workspace membership required' using errcode = '42501';
  end if;

  if not exists (select 1 from public.categories c where c.id = create_recurring_transaction_rpc.category_id and c.workspace_id = create_recurring_transaction_rpc.workspace_id) then
    raise exception 'Category not found in workspace' using errcode = '42501';
  end if;

  insert into public.recurring_transactions(id, workspace_id, title, category_id, amount_minor, currency_code, transaction_type, frequency, mode, interval_count, note, day_of_month, day_of_week, month_of_year, start_date, end_date, next_occurrence_at, reminder_days_before, is_active, created_by_user_id, updated_by_user_id, created_at, updated_at)
  values (coalesce(id, gen_random_uuid()), workspace_id, trim(title), category_id, amount_minor, currency_code, transaction_type, frequency, mode, interval_count, note, day_of_month, day_of_week, month_of_year, start_date, end_date, next_occurrence_at, reminder_days_before, is_active, auth.uid(), auth.uid(), created_at, updated_at)
  returning * into inserted;
  return inserted;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.update_recurring_transaction_rpc(id uuid, workspace_id uuid, title text, category_id uuid, amount_minor bigint, currency_code text, transaction_type text, frequency text, mode text, interval_count integer, start_date timestamptz, next_occurrence_at timestamptz, reminder_days_before integer, is_active boolean, created_by_user_id uuid, updated_by_user_id uuid, created_at timestamptz, updated_at timestamptz, note text default null, day_of_month integer default null, day_of_week integer default null, month_of_year integer default null, end_date timestamptz default null)
returns public.recurring_transactions as $$
declare updated_row public.recurring_transactions;
begin
  if auth.uid() is null or not public.is_workspace_member(update_recurring_transaction_rpc.workspace_id) then
    raise exception 'Active workspace membership required' using errcode = '42501';
  end if;

  if not exists (select 1 from public.categories c where c.id = update_recurring_transaction_rpc.category_id and c.workspace_id = update_recurring_transaction_rpc.workspace_id) then
    raise exception 'Category not found in workspace' using errcode = '42501';
  end if;

  if not exists (select 1 from public.recurring_transactions rt where rt.id = update_recurring_transaction_rpc.id and rt.workspace_id = update_recurring_transaction_rpc.workspace_id and rt.deleted_at is null) then
    raise exception 'Recurring transaction not found' using errcode = '42501';
  end if;

  delete from public.recurring_transaction_occurrences where recurring_transaction_id = update_recurring_transaction_rpc.id and status = 'pending';
  update public.recurring_transactions rt set title = trim(update_recurring_transaction_rpc.title), category_id = update_recurring_transaction_rpc.category_id, amount_minor = update_recurring_transaction_rpc.amount_minor, currency_code = update_recurring_transaction_rpc.currency_code, transaction_type = update_recurring_transaction_rpc.transaction_type, frequency = update_recurring_transaction_rpc.frequency, mode = update_recurring_transaction_rpc.mode, interval_count = update_recurring_transaction_rpc.interval_count, note = update_recurring_transaction_rpc.note, day_of_month = update_recurring_transaction_rpc.day_of_month, day_of_week = update_recurring_transaction_rpc.day_of_week, month_of_year = update_recurring_transaction_rpc.month_of_year, start_date = update_recurring_transaction_rpc.start_date, end_date = update_recurring_transaction_rpc.end_date, next_occurrence_at = update_recurring_transaction_rpc.next_occurrence_at, reminder_days_before = update_recurring_transaction_rpc.reminder_days_before, is_active = update_recurring_transaction_rpc.is_active, updated_by_user_id = auth.uid(), updated_at = update_recurring_transaction_rpc.updated_at
  where rt.id = update_recurring_transaction_rpc.id and rt.workspace_id = update_recurring_transaction_rpc.workspace_id and rt.deleted_at is null
  returning * into updated_row;
  return updated_row;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.soft_delete_recurring_transaction_rpc(p_recurring_transaction_id uuid, p_workspace_id uuid)
returns void as $$
begin
  if auth.uid() is null or not public.is_workspace_member(p_workspace_id) then
    raise exception 'Active workspace membership required' using errcode = '42501';
  end if;

  if not exists (select 1 from public.recurring_transactions rt where rt.id = p_recurring_transaction_id and rt.workspace_id = p_workspace_id and rt.deleted_at is null) then
    raise exception 'Recurring transaction not found' using errcode = '42501';
  end if;

  delete from public.recurring_transaction_occurrences where recurring_transaction_id = p_recurring_transaction_id and status = 'pending';
  update public.recurring_transactions set deleted_at = now(), deleted_by_user_id = auth.uid(), updated_by_user_id = auth.uid(), updated_at = now(), is_active = false
  where id = p_recurring_transaction_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.skip_recurring_occurrence_rpc(p_occurrence_id uuid, p_workspace_id uuid)
returns void as $$
declare occurrence_row public.recurring_transaction_occurrences%rowtype; recurring_row public.recurring_transactions%rowtype;
begin
  if auth.uid() is null or not public.is_workspace_member(p_workspace_id) then
    raise exception 'Active workspace membership required' using errcode = '42501';
  end if;

  select * into occurrence_row from public.recurring_transaction_occurrences where id = p_occurrence_id and workspace_id = p_workspace_id;
  if occurrence_row.id is null then raise exception 'Recurring occurrence not found'; end if;
  select * into recurring_row from public.recurring_transactions where id = occurrence_row.recurring_transaction_id and workspace_id = p_workspace_id and deleted_at is null;
  update public.recurring_transaction_occurrences set status = 'skipped', updated_at = now() where id = p_occurrence_id;
  update public.recurring_transactions set next_occurrence_at = public.next_recurring_occurrence_at(recurring_row.next_occurrence_at, recurring_row.frequency, recurring_row.interval_count, recurring_row.day_of_month, recurring_row.day_of_week, recurring_row.month_of_year), updated_by_user_id = auth.uid(), updated_at = now() where id = recurring_row.id;
end;
$$ language plpgsql security definer set search_path = public;

commit;
