insert into public.categories(id,workspace_id,name,normalized_name,type,icon_name,color_value,created_by_user_id,updated_by_user_id) values
('30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','Own','own','expense','food','FF00884B','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001'),
('30000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000005','Other','other','expense','food','FF00884B','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002');
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
select public.create_recurring_transaction_rpc(id => '40000000-0000-0000-0000-000000000001', workspace_id => '10000000-0000-0000-0000-000000000001', title => 'Own', category_id => '30000000-0000-0000-0000-000000000001', amount_minor => 100, currency_code => 'VND', transaction_type => 'expense', frequency => 'monthly', mode => 'manualConfirm', interval_count => 1, start_date => '2026-10-01'::timestamptz, next_occurrence_at => '2026-10-15'::timestamptz, reminder_days_before => 0, is_active => true, created_by_user_id => '00000000-0000-0000-0000-000000000001', updated_by_user_id => '00000000-0000-0000-0000-000000000001', created_at => now(), updated_at => now());
select public.generate_recurring_occurrences_rpc('10000000-0000-0000-0000-000000000001', '2026-10-31');
do $$
begin
  begin
    perform public.create_recurring_transaction_rpc(id => '40000000-0000-0000-0000-000000000009', workspace_id => '10000000-0000-0000-0000-000000000001', title => 'Own', category_id => '30000000-0000-0000-0000-000000000005', amount_minor => 100, currency_code => 'VND', transaction_type => 'expense', frequency => 'monthly', mode => 'manualConfirm', interval_count => 1, start_date => '2026-10-01'::timestamptz, next_occurrence_at => '2026-10-15'::timestamptz, reminder_days_before => 0, is_active => true, created_by_user_id => '00000000-0000-0000-0000-000000000001', updated_by_user_id => '00000000-0000-0000-0000-000000000001', created_at => now(), updated_at => now());
    raise exception 'Other workspace category accepted for create';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.update_recurring_transaction_rpc(id => '40000000-0000-0000-0000-000000000001', workspace_id => '10000000-0000-0000-0000-000000000001', title => 'Updated', category_id => '30000000-0000-0000-0000-000000000005', amount_minor => 100, currency_code => 'VND', transaction_type => 'expense', frequency => 'monthly', mode => 'manualConfirm', interval_count => 1, start_date => '2026-10-01'::timestamptz, next_occurrence_at => '2026-10-15'::timestamptz, reminder_days_before => 0, is_active => true, created_by_user_id => '00000000-0000-0000-0000-000000000001', updated_by_user_id => '00000000-0000-0000-0000-000000000001', created_at => now(), updated_at => now());
    raise exception 'Other workspace category accepted for update';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;
do $$
begin
  if exists (select 1 from public.recurring_transactions where id = '40000000-0000-0000-0000-000000000009') then raise exception 'Rejected create left a record'; end if;
  if not exists (select 1 from public.recurring_transactions where id = '40000000-0000-0000-0000-000000000001' and category_id = '30000000-0000-0000-0000-000000000001' and title = 'Own') then raise exception 'Rejected category edit changed recurring record'; end if;
  if not exists (select 1 from public.recurring_transaction_occurrences where recurring_transaction_id = '40000000-0000-0000-0000-000000000001' and status = 'pending') then raise exception 'Rejected category edit removed pending occurrence'; end if;
end;
$$;
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
select public.update_recurring_transaction_rpc(id => '40000000-0000-0000-0000-000000000001', workspace_id => '10000000-0000-0000-0000-000000000001', title => 'Updated', category_id => '30000000-0000-0000-0000-000000000001', amount_minor => 100, currency_code => 'VND', transaction_type => 'expense', frequency => 'monthly', mode => 'manualConfirm', interval_count => 1, start_date => '2026-10-01'::timestamptz, next_occurrence_at => '2026-10-15'::timestamptz, reminder_days_before => 0, is_active => true, created_by_user_id => '00000000-0000-0000-0000-000000000001', updated_by_user_id => '00000000-0000-0000-0000-000000000001', created_at => now(), updated_at => now());
reset role;
do $$
begin
  if not exists (select 1 from public.recurring_transactions where id = '40000000-0000-0000-0000-000000000001' and title = 'Updated') then raise exception 'Permitted edit failed'; end if;
  if exists (select 1 from public.recurring_transaction_occurrences where recurring_transaction_id = '40000000-0000-0000-0000-000000000001') then raise exception 'Edit did not clear pending occurrences'; end if;
end;
$$;

insert into public.recurring_transactions(id,workspace_id,title,category_id,amount_minor,currency_code,transaction_type,frequency,mode,interval_count,start_date,next_occurrence_at,reminder_days_before,is_active,created_by_user_id,updated_by_user_id)
select '40000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000005','Other','30000000-0000-0000-0000-000000000005',amount_minor,currency_code,transaction_type,frequency,mode,interval_count,start_date,next_occurrence_at,reminder_days_before,is_active,'00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002'
from public.recurring_transactions where id = '40000000-0000-0000-0000-000000000001';
insert into public.recurring_transaction_occurrences(id,recurring_transaction_id,workspace_id,scheduled_for,remind_at,status) values
('50000000-0000-0000-0000-000000000005','40000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000005','2026-10-15','2026-10-15','pending');
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$
begin
  begin
    perform public.update_recurring_transaction_rpc(id => '40000000-0000-0000-0000-000000000005', workspace_id => '10000000-0000-0000-0000-000000000001', title => 'Updated', category_id => '30000000-0000-0000-0000-000000000001', amount_minor => 100, currency_code => 'VND', transaction_type => 'expense', frequency => 'monthly', mode => 'manualConfirm', interval_count => 1, start_date => '2026-10-01'::timestamptz, next_occurrence_at => '2026-10-15'::timestamptz, reminder_days_before => 0, is_active => true, created_by_user_id => '00000000-0000-0000-0000-000000000001', updated_by_user_id => '00000000-0000-0000-0000-000000000001', created_at => now(), updated_at => now());
    raise exception 'Other recurring ID edit accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.soft_delete_recurring_transaction_rpc('40000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000005');
    raise exception 'Other workspace deletion accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.soft_delete_recurring_transaction_rpc('40000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000001');
    raise exception 'Other recurring ID deletion accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.skip_recurring_occurrence_rpc('50000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000005');
    raise exception 'Other workspace skip accepted';
  exception when insufficient_privilege then null;
  end;
end;
$$;
select public.generate_recurring_occurrences_rpc('10000000-0000-0000-0000-000000000001','2026-10-31');
select public.skip_recurring_occurrence_rpc(id,'10000000-0000-0000-0000-000000000001') from public.recurring_transaction_occurrences where recurring_transaction_id = '40000000-0000-0000-0000-000000000001';
reset role;
do $$
begin
  if not exists (select 1 from public.recurring_transaction_occurrences where recurring_transaction_id = '40000000-0000-0000-0000-000000000001' and status = 'skipped') then raise exception 'Permitted skip failed'; end if;
end;
$$;
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
select public.soft_delete_recurring_transaction_rpc('40000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001');
reset role;
do $$
begin
  if not exists (select 1 from public.recurring_transactions where id = '40000000-0000-0000-0000-000000000001' and deleted_at is not null and not is_active) then raise exception 'Permitted deletion failed'; end if;
  if not exists (select 1 from public.recurring_transactions where id = '40000000-0000-0000-0000-000000000005' and deleted_at is null and title = 'Other' and is_active) then raise exception 'Other recurring record changed'; end if;
  if not exists (select 1 from public.recurring_transaction_occurrences where id = '50000000-0000-0000-0000-000000000005' and status = 'pending') then raise exception 'Other occurrence changed'; end if;
end;
$$;
