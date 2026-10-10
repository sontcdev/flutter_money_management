update auth.users set email = 'first@example.invalid' where id = '00000000-0000-0000-0000-000000000001';
update auth.users set email = 'second@example.invalid' where id = '00000000-0000-0000-0000-000000000002';
insert into public.workspace_invites(workspace_id,email,token,invited_by_user_id,expires_at)
values ('10000000-0000-0000-0000-000000000002','second@example.invalid','security-recipient-token','00000000-0000-0000-0000-000000000002',now() + interval '1 day');
insert into public.user_notifications(recipient_user_id,type,title,body,payload)
select '00000000-0000-0000-0000-000000000002','workspace_invite','Security invitation','Security invitation',jsonb_build_object('invite_id',id)
from public.workspace_invites where token = 'security-recipient-token';
set role anon;
set request.jwt.claim.sub = '';
do $$
begin
  begin
    perform public.get_workspace_invite_preview('security-recipient-token');
    raise exception 'Anonymous preview accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.log_workspace_activity('10000000-0000-0000-0000-000000000001','workspace','10000000-0000-0000-0000-000000000001','test');
    raise exception 'Anonymous activity logging accepted';
  exception when insufficient_privilege then null;
  end;
  if (public.decline_workspace_invite('security-recipient-token')->>'success')::boolean then
    raise exception 'Anonymous decline accepted';
  end if;
end;
$$;
reset role;
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$
begin
  perform public.log_workspace_activity('10000000-0000-0000-0000-000000000001','workspace','10000000-0000-0000-0000-000000000001','test');
  begin
    perform public.log_workspace_activity('10000000-0000-0000-0000-000000000005','workspace','10000000-0000-0000-0000-000000000001','test');
    raise exception 'Foreign workspace logging accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.get_workspace_invite_preview('security-recipient-token');
    raise exception 'Wrong recipient preview accepted';
  exception when insufficient_privilege then null;
  end;
  if (public.decline_workspace_invite('security-recipient-token')->>'success')::boolean then
    raise exception 'Wrong recipient decline accepted';
  end if;
end;
$$;
reset role;
do $$
begin
  if not exists (select 1 from public.workspace_invites where token = 'security-recipient-token' and status = 'pending') then
    raise exception 'Rejected decline changed invitation';
  end if;
  if not exists (select 1 from public.user_notifications n join public.workspace_invites i on n.payload->>'invite_id' = i.id::text where i.token = 'security-recipient-token' and n.read_at is null) then
    raise exception 'Rejected decline changed notification';
  end if;
end;
$$;
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
do $$
begin
  if public.get_workspace_invite_preview('security-recipient-token')->>'email' <> 'second@example.invalid' then
    raise exception 'Recipient preview failed';
  end if;
  if not (public.decline_workspace_invite('security-recipient-token')->>'success')::boolean then
    raise exception 'Recipient decline failed';
  end if;
end;
$$;
reset role;
do $$
begin
  if not exists (select 1 from public.workspace_invites where token = 'security-recipient-token' and status = 'declined') then
    raise exception 'Recipient decline not persisted';
  end if;
  if not exists (select 1 from public.user_notifications n join public.workspace_invites i on n.payload->>'invite_id' = i.id::text where i.token = 'security-recipient-token' and n.read_at is not null) then
    raise exception 'Recipient notification not marked read';
  end if;
end;
$$;
