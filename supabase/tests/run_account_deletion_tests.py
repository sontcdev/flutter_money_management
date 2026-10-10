from pathlib import Path
import subprocess
import time
import uuid

root = Path(__file__).resolve().parents[2]
container = 'mymoney-deletion-test-' + uuid.uuid4().hex[:12]
subprocess.run([
    'docker', 'run', '--detach', '--rm', '--network', 'none',
    '--name', container, '-e', 'POSTGRES_HOST_AUTH_METHOD=trust',
    'postgres:17-alpine',
], check=True, capture_output=True)
try:
    for attempt in range(30):
        result = subprocess.run(
            ['docker', 'exec', container, 'pg_isready', '-h', '127.0.0.1', '-U', 'postgres'],
            capture_output=True,
        )
        if result.returncode == 0:
            break
        time.sleep(0.2)
    else:
        raise RuntimeError('Isolated Postgres did not become ready')
    schema = (root / 'supabase/01_create_schema.sql').read_text()
    setup = '''
create role anon;
create role authenticated;
create role service_role bypassrls;
create schema auth;
create table auth.users(id uuid primary key, email text, raw_user_meta_data jsonb);
create schema extensions;
create schema storage;
create table storage.buckets(id text primary key, name text, public boolean);
create table storage.objects(bucket_id text, name text, owner_id text, primary key(bucket_id, name));
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;
'''
    setup += schema
    setup += (root / 'supabase/04_restore_recurring_completion.sql').read_text()
    setup += """
alter table auth.users disable trigger on_auth_user_created;
alter table storage.objects enable row level security;
grant usage on schema auth, storage to authenticated, service_role;
grant select, insert, update, delete on storage.objects to authenticated, service_role;
"""
    migration = (root / 'supabase/05_account_deletion.sql').read_text()
    migration += (root / 'supabase/06_harden_workspace_helpers.sql').read_text()
    migration += (root / 'supabase/07_harden_recurring_mutations.sql').read_text()
    migration += (root / 'supabase/08_harden_financial_mutations.sql').read_text()
    migration += (root / 'supabase/09_harden_workspace_activity_invites.sql').read_text()
    migration += (root / 'supabase/10_harden_wallet_targets.sql').read_text()
    migration += (root / 'supabase/11_harden_workspace_owner_transfer.sql').read_text()
    migration += 'grant all on table public.profiles, public.workspaces, public.workspace_members, public.workspace_invites, public.user_notifications, public.categories, public.wallets, public.transactions, public.transaction_attachments, public.budgets, public.activity_logs, public.user_workspace_preferences, public.error_reports, public.recurring_transactions, public.recurring_transaction_occurrences to public, anon, authenticated;\n'
    migration += (root / 'supabase/12_harden_table_privileges.sql').read_text()
    migration += (root / 'supabase/12_harden_table_privileges.sql').read_text()
    tests = (root / 'supabase/tests/account_deletion_precheck_test.sql').read_text()
    tests += (root / 'supabase/tests/table_privilege_security_test.sql').read_text()
    tests += (root / 'supabase/tests/account_deletion_prepare_test.sql').read_text()
    subprocess.run(
        ['docker', 'exec', '-i', container, 'psql', '-h', '127.0.0.1', '-U', 'postgres',
         '-v', 'ON_ERROR_STOP=1', '-q'],
        input=setup + migration + tests, text=True, check=True,
    )
    print('Account deletion: precheck, cleanup, retry, and privilege tests passed.')
finally:
    subprocess.run(['docker', 'rm', '--force', container],
                   check=True, capture_output=True)
