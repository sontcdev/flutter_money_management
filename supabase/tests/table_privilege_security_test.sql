do $$
declare
  table_name text;
  privilege_name text;
begin
  foreach table_name in array array['profiles', 'workspaces', 'workspace_members', 'workspace_invites', 'user_notifications', 'categories', 'wallets', 'transactions', 'transaction_attachments', 'budgets', 'activity_logs', 'user_workspace_preferences', 'error_reports', 'recurring_transactions', 'recurring_transaction_occurrences'] loop
    foreach privilege_name in array array['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER', 'MAINTAIN'] loop
      if has_table_privilege('anon', 'public.' || table_name, privilege_name) then
        raise exception 'Anonymous table privilege retained: %.%', table_name, privilege_name;
      end if;
      if not has_table_privilege('service_role', 'public.' || table_name, privilege_name) then
        raise exception 'Service privilege lost: %.%', table_name, privilege_name;
      end if;
      if has_table_privilege('authenticated', 'public.' || table_name, privilege_name) <> (privilege_name = any(array['SELECT', 'INSERT', 'UPDATE', 'DELETE'])) then
        raise exception 'Authenticated privilege mismatch: %.%', table_name, privilege_name;
      end if;
    end loop;
  end loop;
end;
$$;
