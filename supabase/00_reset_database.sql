-- Reset flutter_money_management database objects to a clean public schema.
-- Run this first on a Supabase project when you want a destructive rebuild.
-- This deletes all app data in public.*.
-- Supabase blocks direct deletion from storage.objects; delete bucket contents with
-- the Storage API/dashboard if you also need to remove uploaded receipt files.

begin;

drop trigger if exists on_auth_user_created on auth.users;

drop policy if exists transaction_receipts_select_member on storage.objects;
drop policy if exists transaction_receipts_insert_creator on storage.objects;
drop policy if exists transaction_receipts_delete_creator on storage.objects;

drop schema if exists public cascade;
create schema public;

grant usage on schema public to postgres, anon, authenticated, service_role;
grant all on schema public to postgres, service_role;

create extension if not exists "pgcrypto" with schema extensions;

notify pgrst, 'reload schema';

commit;
