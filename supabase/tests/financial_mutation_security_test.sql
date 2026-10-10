set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$
begin
  begin
    perform public.create_category_rpc('10000000-0000-0000-0000-000000000005','Unauthorized','expense','food','FF00884B');
    raise exception 'Unauthorized create_category_rpc accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.update_category_rpc('30000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000005','Unauthorized','expense','food','FF00884B');
    raise exception 'Unauthorized update_category_rpc accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.soft_delete_category_rpc('30000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000005');
    raise exception 'Unauthorized soft_delete_category_rpc accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.create_transaction_rpc('10000000-0000-0000-0000-000000000005','30000000-0000-0000-0000-000000000005',100,'VND','expense',now(),gen_random_uuid());
    raise exception 'Unauthorized create_transaction_rpc accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.update_transaction_rpc(gen_random_uuid(),'10000000-0000-0000-0000-000000000005','30000000-0000-0000-0000-000000000005',100,'VND','expense',now(),gen_random_uuid());
    raise exception 'Unauthorized update_transaction_rpc accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.soft_delete_transaction_rpc(gen_random_uuid(),'10000000-0000-0000-0000-000000000005');
    raise exception 'Unauthorized soft_delete_transaction_rpc accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.create_budget_rpc('10000000-0000-0000-0000-000000000005','30000000-0000-0000-0000-000000000005','monthly',now(),now(),100,'VND');
    raise exception 'Unauthorized create_budget_rpc accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.update_budget_rpc(gen_random_uuid(),'10000000-0000-0000-0000-000000000005','30000000-0000-0000-0000-000000000005','monthly',now(),now(),100,'VND');
    raise exception 'Unauthorized update_budget_rpc accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.soft_delete_budget_rpc(gen_random_uuid(),'10000000-0000-0000-0000-000000000005');
    raise exception 'Unauthorized soft_delete_budget_rpc accepted';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;

insert into public.wallets(id,workspace_id,name,normalized_name,created_by_user_id,updated_by_user_id) values
('60000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000005','Other','other','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002');
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$
declare
  own_workspace uuid := '10000000-0000-0000-0000-000000000001';
  other_category uuid := '30000000-0000-0000-0000-000000000005';
  other_wallet uuid := '60000000-0000-0000-0000-000000000005';
  category_row public.categories;
  wallet_row public.wallets;
  destination_row public.wallets;
  budget_row public.budgets;
  transaction_row public.transactions;
  transfer_row public.transactions;
begin
  category_row := public.create_category_rpc(own_workspace,'Security test','expense','food','FF00884B');
  perform public.update_category_rpc(category_row.id,own_workspace,'Updated security test','expense','food','FF00884B');
  wallet_row := public.create_wallet_rpc(own_workspace,'Security source','cash','wallet','FF00884B');
  destination_row := public.create_wallet_rpc(own_workspace,'Security destination','cash','wallet','FF00884B');
  budget_row := public.create_budget_rpc(own_workspace,category_row.id,'monthly',now(),now(),100,'VND');
  perform public.update_budget_rpc(budget_row.id,own_workspace,category_row.id,'monthly',now(),now(),200,'VND');
  transaction_row := public.create_transaction_rpc(own_workspace,category_row.id,100,'VND','expense',now(),wallet_row.id);
  perform public.update_transaction_rpc(transaction_row.id,own_workspace,category_row.id,200,'VND','expense',now(),wallet_row.id);
  transfer_row := public.create_transaction_rpc(own_workspace,null,100,'VND','transfer',now(),wallet_row.id,destination_row.id);
  perform public.update_transaction_rpc(transfer_row.id,own_workspace,null,200,'VND','transfer',now(),wallet_row.id,destination_row.id);
  begin
    perform public.create_transaction_rpc(own_workspace,other_category,100,'VND','expense',now(),wallet_row.id);
    raise exception 'Foreign category accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.create_transaction_rpc(own_workspace,category_row.id,100,'VND','expense',now(),other_wallet);
    raise exception 'Foreign source wallet accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.update_transaction_rpc(transfer_row.id,own_workspace,null,999,'VND','transfer',now(),wallet_row.id,other_wallet);
    raise exception 'Foreign destination wallet accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.update_budget_rpc(budget_row.id,own_workspace,other_category,'monthly',now(),now(),999,'VND');
    raise exception 'Foreign budget category accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.create_budget_rpc(own_workspace,other_category,'monthly',now(),now(),999,'VND');
    raise exception 'Foreign category accepted on budget creation';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.create_transaction_rpc(own_workspace,null,999,'VND','transfer',now(),wallet_row.id,other_wallet);
    raise exception 'Foreign destination accepted on transfer creation';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.update_transaction_rpc(transaction_row.id,own_workspace,other_category,999,'VND','expense',now(),wallet_row.id);
    raise exception 'Foreign category accepted on transaction update';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.update_transaction_rpc(transaction_row.id,own_workspace,category_row.id,999,'VND','expense',now(),other_wallet);
    raise exception 'Foreign source accepted on transaction update';
  exception when insufficient_privilege then null;
  end;
  if not exists (select 1 from public.categories where id = category_row.id and name = 'Updated security test') then raise exception 'Category edit failed'; end if;
  if not exists (select 1 from public.budgets where id = budget_row.id and limit_minor = 200 and category_id = category_row.id) then raise exception 'Budget edit or preservation failed'; end if;
  if not exists (select 1 from public.transactions where id = transaction_row.id and amount_minor = 200) then raise exception 'Transaction edit failed'; end if;
  if not exists (select 1 from public.transactions where id = transfer_row.id and amount_minor = 200 and to_wallet_id = destination_row.id and category_id is null) then raise exception 'Transfer edit or preservation failed'; end if;
  perform public.soft_delete_transaction_rpc(transaction_row.id,own_workspace);
  perform public.soft_delete_transaction_rpc(transfer_row.id,own_workspace);
  perform public.soft_delete_budget_rpc(budget_row.id,own_workspace);
  perform public.soft_delete_category_rpc(category_row.id,own_workspace);
  if not exists (select 1 from public.transactions where id = transaction_row.id and deleted_at is not null) then raise exception 'Transaction deletion failed'; end if;
end;
$$;
reset role;
do $$
begin
  if not exists (select 1 from public.categories where name = 'Updated security test' and deleted_at is not null) then raise exception 'Category deletion failed'; end if;
  if not exists (select 1 from public.budgets b join public.categories c on c.id = b.category_id where c.name = 'Updated security test' and b.deleted_at is not null) then raise exception 'Budget deletion failed'; end if;
  if not exists (select 1 from public.wallets where id = '60000000-0000-0000-0000-000000000005' and deleted_at is null and name = 'Other') then raise exception 'Other wallet changed'; end if;
  if not exists (select 1 from public.categories where id = '30000000-0000-0000-0000-000000000005' and deleted_at is null and name = 'Other') then raise exception 'Other category changed'; end if;
end;
$$;
