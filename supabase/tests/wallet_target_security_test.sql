set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$
declare
  own_workspace uuid := '10000000-0000-0000-0000-000000000001';
  other_wallet uuid := '60000000-0000-0000-0000-000000000005';
  own_wallet public.wallets;
  next_wallet public.wallets;
begin
  own_wallet := public.create_wallet_rpc(own_workspace,'Target security default','cash','wallet','FF00884B',0,'VND',true);
  begin
    perform public.set_default_wallet_rpc(other_wallet,own_workspace);
    raise exception 'Foreign default target accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.update_wallet_rpc(other_wallet,own_workspace,'Unauthorized','cash','wallet','FF00884B',0,'VND',true);
    raise exception 'Foreign update target accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.soft_delete_wallet_rpc(other_wallet,own_workspace);
    raise exception 'Foreign deletion target accepted';
  exception when insufficient_privilege then null;
  end;
  if not exists (select 1 from public.wallets where id = own_wallet.id and is_default) then
    raise exception 'Rejected target cleared default';
  end if;
  next_wallet := public.create_wallet_rpc(own_workspace,'Target security next','cash','wallet','FF00884B');
  perform public.set_default_wallet_rpc(next_wallet.id,own_workspace);
  if not exists (select 1 from public.wallets where id = next_wallet.id and is_default) or exists (select 1 from public.wallets where id = own_wallet.id and is_default) then
    raise exception 'Permitted default switch failed';
  end if;
  perform public.update_wallet_rpc(next_wallet.id,own_workspace,'Target security updated','cash','wallet','FF00884B',200,'VND',true);
  if not exists (select 1 from public.wallets where id = next_wallet.id and name = 'Target security updated' and opening_balance_minor = 200) then
    raise exception 'Permitted wallet update failed';
  end if;
  perform public.soft_delete_wallet_rpc(next_wallet.id,own_workspace);
end;
$$;
reset role;
do $$
begin
  if not exists (select 1 from public.wallets where name = 'Target security updated' and deleted_at is not null) then
    raise exception 'Permitted wallet deletion failed';
  end if;
  if not exists (select 1 from public.wallets where id = '60000000-0000-0000-0000-000000000005' and name = 'Other' and deleted_at is null) then
    raise exception 'Foreign wallet changed';
  end if;
end;
$$;
