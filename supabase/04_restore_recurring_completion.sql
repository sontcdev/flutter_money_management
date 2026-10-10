begin;

create or replace function public.next_recurring_occurrence_at(p_current_occurrence_at timestamptz, p_frequency text, p_interval_count integer, p_day_of_month integer, p_day_of_week integer, p_month_of_year integer)
returns timestamptz as $$
declare
  safe_interval integer := greatest(p_interval_count, 1);
  occurrence_date date := p_current_occurrence_at::date;
  occurrence_time time := p_current_occurrence_at::time;
  base_date date;
  next_date date;
begin
  case p_frequency
    when 'weekly' then next_date := occurrence_date + (safe_interval * 7);
    when 'monthly' then
      base_date := (occurrence_date + make_interval(months => safe_interval))::date;
      next_date := public.recurring_safe_date(extract(year from base_date)::integer, extract(month from base_date)::integer, coalesce(p_day_of_month, extract(day from occurrence_date)::integer));
    when 'yearly' then
      base_date := (occurrence_date + make_interval(years => safe_interval))::date;
      next_date := public.recurring_safe_date(extract(year from base_date)::integer, coalesce(p_month_of_year, extract(month from occurrence_date)::integer), coalesce(p_day_of_month, extract(day from occurrence_date)::integer));
    else raise exception 'Unsupported recurring frequency: %', p_frequency;
  end case;
  return next_date::timestamp + occurrence_time;
end;
$$ language plpgsql immutable;

create or replace function public.complete_recurring_occurrence_rpc(p_occurrence_id uuid, p_workspace_id uuid, p_generated_transaction_id uuid)
returns void as $$
declare occurrence_row public.recurring_transaction_occurrences%rowtype; recurring_row public.recurring_transactions%rowtype;
begin
  if auth.uid() is null or not public.is_workspace_member(p_workspace_id) then
    raise exception 'Not a workspace member';
  end if;
  if not exists (
    select 1 from public.transactions
    where id = p_generated_transaction_id
      and workspace_id = p_workspace_id
      and created_by_user_id = auth.uid()
  ) then
    raise exception 'Generated transaction not found';
  end if;
  select * into occurrence_row from public.recurring_transaction_occurrences where id = p_occurrence_id and workspace_id = p_workspace_id for update;
  if occurrence_row.id is null then raise exception 'Recurring occurrence not found'; end if;
  if occurrence_row.status = 'completed' and occurrence_row.generated_transaction_id = p_generated_transaction_id then
    return;
  end if;
  if occurrence_row.status <> 'pending' then
    raise exception 'Recurring occurrence is not pending';
  end if;
  select * into recurring_row from public.recurring_transactions where id = occurrence_row.recurring_transaction_id and workspace_id = p_workspace_id and deleted_at is null;
  if recurring_row.id is null then raise exception 'Recurring transaction not found'; end if;
  update public.recurring_transaction_occurrences set status = 'completed', generated_transaction_id = p_generated_transaction_id, updated_at = now() where id = p_occurrence_id;
  update public.recurring_transactions set next_occurrence_at = public.next_recurring_occurrence_at(recurring_row.next_occurrence_at, recurring_row.frequency, recurring_row.interval_count, recurring_row.day_of_month, recurring_row.day_of_week, recurring_row.month_of_year), updated_by_user_id = auth.uid(), updated_at = now() where id = recurring_row.id;
end;
$$ language plpgsql security invoker set search_path = public;

revoke execute on function public.complete_recurring_occurrence_rpc(uuid, uuid, uuid) from public, anon;
grant execute on function public.complete_recurring_occurrence_rpc(uuid, uuid, uuid) to authenticated;

notify pgrst, 'reload schema';

commit;
