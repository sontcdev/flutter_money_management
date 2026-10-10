begin;

create or replace function public.generate_recurring_occurrences_rpc(p_workspace_id uuid, p_through_date timestamptz)
returns void as $$
declare item public.recurring_transactions%rowtype;
begin
  if auth.uid() is null or not public.is_workspace_member(p_workspace_id) then
    raise exception 'Active workspace membership required' using errcode = '42501';
  end if;

  for item in select * from public.recurring_transactions where workspace_id = p_workspace_id and deleted_at is null and is_active = true and next_occurrence_at <= p_through_date and (end_date is null or next_occurrence_at <= end_date)
  loop
    insert into public.recurring_transaction_occurrences(recurring_transaction_id, workspace_id, scheduled_for, remind_at, status)
    values (item.id, item.workspace_id, item.next_occurrence_at, item.next_occurrence_at - make_interval(days => item.reminder_days_before), 'pending')
    on conflict (recurring_transaction_id, scheduled_for) do nothing;
  end loop;
end;
$$ language plpgsql security definer set search_path = public;

revoke all on function public.ensure_default_wallet(uuid, uuid) from public, anon, authenticated;
revoke all on function public.ensure_workspace_setup_for_user(uuid, text, jsonb) from public, anon, authenticated;
grant execute on function public.ensure_default_wallet(uuid, uuid) to service_role;
grant execute on function public.ensure_workspace_setup_for_user(uuid, text, jsonb) to service_role;
revoke all on function public.generate_recurring_occurrences_rpc(uuid, timestamptz) from public, anon;
grant execute on function public.generate_recurring_occurrences_rpc(uuid, timestamptz) to authenticated;

commit;
