-- Fresh schema for flutter_money_management.
-- Run after 00_reset_database.sql.

begin;

create extension if not exists "pgcrypto" with schema extensions;

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create or replace function public.normalize_name(input_text text)
returns text as $$
begin
  return lower(trim(input_text));
end;
$$ language plpgsql immutable;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  display_name text not null,
  avatar_url text,
  phone text,
  default_currency_code text not null default 'VND',
  locale text not null default 'vi',
  timezone text not null default 'Asia/Ho_Chi_Minh',
  status text not null default 'active' check (status in ('active', 'disabled', 'deleted')),
  last_active_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (char_length(display_name) > 0)
);

create table public.workspaces (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('personal', 'group')),
  name text not null,
  slug text,
  owner_user_id uuid not null references public.profiles(id) on delete cascade,
  default_currency_code text not null default 'VND',
  timezone text not null default 'Asia/Ho_Chi_Minh',
  month_start_day smallint not null default 1 check (month_start_day between 1 and 31),
  status text not null default 'active' check (status in ('active', 'archived', 'deleted')),
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.workspace_members (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('owner', 'admin', 'member')),
  membership_status text not null default 'active' check (membership_status in ('pending', 'active', 'removed', 'declined')),
  permissions jsonb not null default '{}'::jsonb,
  joined_at timestamptz,
  invited_by_user_id uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  removed_at timestamptz,
  constraint workspace_members_unique unique (workspace_id, user_id)
);

create table public.workspace_invites (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  email text not null,
  role text not null default 'member' check (role in ('member')),
  token text not null unique,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'expired', 'revoked', 'declined')),
  invited_by_user_id uuid not null references public.profiles(id),
  accepted_by_user_id uuid references public.profiles(id),
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('workspace_invite', 'transaction_created', 'transaction_updated', 'transaction_deleted', 'category_created', 'category_updated', 'category_deleted', 'budget_created', 'budget_updated', 'budget_deleted')),
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  name text not null,
  normalized_name text not null,
  type text not null check (type in ('expense', 'income')),
  icon_name text not null,
  color_value text not null check (color_value ~ '^[0-9A-F]{8}$'),
  is_system boolean not null default false,
  is_archived boolean not null default false,
  sort_order integer not null default 0,
  created_by_user_id uuid not null references public.profiles(id),
  updated_by_user_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by_user_id uuid references public.profiles(id),
  version integer not null default 1 check (version > 0),
  metadata jsonb not null default '{}'::jsonb
);

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  category_id uuid not null references public.categories(id),
  amount_minor bigint not null check (amount_minor > 0),
  currency_code text not null,
  transaction_type text not null check (transaction_type in ('expense', 'income')),
  transaction_at timestamptz not null,
  note text,
  source text not null default 'manual' check (source in ('manual', 'import', 'system')),
  client_reference_id text,
  receipt_path text,
  created_by_user_id uuid not null references public.profiles(id),
  updated_by_user_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by_user_id uuid references public.profiles(id),
  version integer not null default 1 check (version > 0),
  metadata jsonb not null default '{}'::jsonb
);

create table public.transaction_attachments (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  transaction_id uuid not null references public.transactions(id) on delete cascade,
  storage_bucket text not null,
  storage_path text not null,
  file_name text not null,
  mime_type text,
  file_size bigint,
  checksum text,
  uploaded_by_user_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.budgets (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  category_id uuid not null references public.categories(id),
  name text,
  period_type text not null check (period_type in ('monthly', 'yearly', 'custom')),
  period_start timestamptz not null,
  period_end timestamptz not null,
  limit_minor bigint not null check (limit_minor > 0),
  currency_code text not null,
  allow_overdraft boolean not null default false,
  is_archived boolean not null default false,
  created_by_user_id uuid not null references public.profiles(id),
  updated_by_user_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by_user_id uuid references public.profiles(id),
  version integer not null default 1 check (version > 0),
  metadata jsonb not null default '{}'::jsonb,
  check (period_end >= period_start)
);

create table public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  actor_user_id uuid not null references public.profiles(id),
  entity_type text not null,
  entity_id uuid not null,
  action text not null,
  summary text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.user_workspace_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  preferred_report_range text,
  preferred_chart_type text,
  last_selected_tab text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_workspace_preferences_unique unique (user_id, workspace_id)
);

create table public.error_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  error_type text not null,
  error_message text not null,
  stack_trace text,
  device_info jsonb,
  app_version text,
  platform text,
  context jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.recurring_transactions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  title text not null,
  category_id uuid not null references public.categories(id),
  amount_minor bigint not null check (amount_minor > 0),
  currency_code text not null default 'VND',
  transaction_type text not null check (transaction_type in ('income', 'expense')),
  frequency text not null check (frequency in ('weekly', 'monthly', 'yearly')),
  mode text not null check (mode in ('reminderOnly', 'manualConfirm')),
  interval_count integer not null default 1 check (interval_count > 0),
  note text,
  day_of_month integer check (day_of_month between 1 and 31),
  day_of_week integer check (day_of_week between 1 and 7),
  month_of_year integer check (month_of_year between 1 and 12),
  start_date timestamptz not null,
  end_date timestamptz,
  next_occurrence_at timestamptz not null,
  reminder_days_before integer not null default 0 check (reminder_days_before >= 0),
  is_active boolean not null default true,
  created_by_user_id uuid not null references public.profiles(id),
  updated_by_user_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by_user_id uuid references public.profiles(id),
  check (end_date is null or end_date >= start_date)
);

create table public.recurring_transaction_occurrences (
  id uuid primary key default gen_random_uuid(),
  recurring_transaction_id uuid not null references public.recurring_transactions(id) on delete cascade,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  scheduled_for timestamptz not null,
  remind_at timestamptz not null,
  status text not null check (status in ('pending', 'completed', 'skipped', 'dismissed')),
  generated_transaction_id uuid references public.transactions(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (recurring_transaction_id, scheduled_for)
);

create index profiles_email_idx on public.profiles(email);
create index workspaces_owner_user_id_idx on public.workspaces(owner_user_id);
create index workspace_members_workspace_id_idx on public.workspace_members(workspace_id);
create index workspace_members_user_id_idx on public.workspace_members(user_id);
create index workspace_invites_email_idx on public.workspace_invites(email);
create index workspace_invites_status_idx on public.workspace_invites(status);
create index user_notifications_recipient_created_idx on public.user_notifications(recipient_user_id, created_at desc);
create index user_notifications_recipient_unread_idx on public.user_notifications(recipient_user_id, created_at desc) where read_at is null;
create index user_notifications_type_idx on public.user_notifications(type);
create unique index categories_workspace_name_type_unique_idx on public.categories(workspace_id, normalized_name, type) where deleted_at is null;
create index categories_workspace_type_idx on public.categories(workspace_id, type);
create index transactions_workspace_date_idx on public.transactions(workspace_id, transaction_at desc);
create index transactions_workspace_category_date_idx on public.transactions(workspace_id, category_id, transaction_at desc);
create index budgets_workspace_period_idx on public.budgets(workspace_id, period_start, period_end);
create index activity_logs_workspace_created_idx on public.activity_logs(workspace_id, created_at desc);
create index idx_error_reports_user_id on public.error_reports(user_id);
create index idx_recurring_transactions_workspace_active on public.recurring_transactions(workspace_id, is_active, next_occurrence_at) where deleted_at is null;
create index idx_recurring_occurrences_workspace_schedule on public.recurring_transaction_occurrences(workspace_id, status, scheduled_for);

create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
create trigger workspaces_updated_at before update on public.workspaces for each row execute function public.set_updated_at();
create trigger workspace_members_updated_at before update on public.workspace_members for each row execute function public.set_updated_at();
create trigger workspace_invites_updated_at before update on public.workspace_invites for each row execute function public.set_updated_at();
create trigger user_notifications_updated_at before update on public.user_notifications for each row execute function public.set_updated_at();
create trigger categories_updated_at before update on public.categories for each row execute function public.set_updated_at();
create trigger transactions_updated_at before update on public.transactions for each row execute function public.set_updated_at();
create trigger budgets_updated_at before update on public.budgets for each row execute function public.set_updated_at();
create trigger user_workspace_preferences_updated_at before update on public.user_workspace_preferences for each row execute function public.set_updated_at();
create trigger error_reports_updated_at before update on public.error_reports for each row execute function public.set_updated_at();
create trigger recurring_transactions_updated_at before update on public.recurring_transactions for each row execute function public.set_updated_at();
create trigger recurring_occurrences_updated_at before update on public.recurring_transaction_occurrences for each row execute function public.set_updated_at();

create or replace function public.categories_normalize_name()
returns trigger as $$
begin
  new.normalized_name = public.normalize_name(new.name);
  return new;
end;
$$ language plpgsql;

create trigger categories_normalize_name_trigger before insert or update of name on public.categories for each row execute function public.categories_normalize_name();

create or replace function public.is_workspace_member(workspace_uuid uuid)
returns boolean as $$
begin
  return exists (
    select 1 from public.workspace_members
    where workspace_id = workspace_uuid and user_id = auth.uid() and membership_status = 'active'
  );
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.can_manage_workspace(workspace_uuid uuid)
returns boolean as $$
begin
  return exists (
    select 1 from public.workspace_members
    where workspace_id = workspace_uuid
      and user_id = auth.uid()
      and role in ('owner', 'admin')
      and membership_status = 'active'
  );
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.is_workspace_owner(workspace_uuid uuid)
returns boolean as $$
begin
  return exists (
    select 1 from public.workspace_members
    where workspace_id = workspace_uuid and user_id = auth.uid() and role = 'owner' and membership_status = 'active'
  );
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.log_workspace_activity(
  p_workspace_id uuid,
  p_entity_type text,
  p_entity_id uuid,
  p_action text,
  p_summary text default null,
  p_payload jsonb default '{}'::jsonb
)
returns uuid as $$
declare
  v_id uuid;
begin
  insert into public.activity_logs(workspace_id, actor_user_id, entity_type, entity_id, action, summary, payload)
  values (p_workspace_id, auth.uid(), p_entity_type, p_entity_id, p_action, p_summary, coalesce(p_payload, '{}'::jsonb))
  returning id into v_id;
  return v_id;
end;
$$ language plpgsql security definer set search_path = public;

alter table public.profiles enable row level security;
alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.workspace_invites enable row level security;
alter table public.user_notifications enable row level security;
alter table public.categories enable row level security;
alter table public.transactions enable row level security;
alter table public.transaction_attachments enable row level security;
alter table public.budgets enable row level security;
alter table public.activity_logs enable row level security;
alter table public.user_workspace_preferences enable row level security;
alter table public.error_reports enable row level security;
alter table public.recurring_transactions enable row level security;
alter table public.recurring_transaction_occurrences enable row level security;

create policy profiles_select_own on public.profiles for select using (id = auth.uid());
create policy profiles_update_own on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());
create policy workspaces_select_member on public.workspaces for select using (public.is_workspace_member(id));
create policy workspaces_insert_own on public.workspaces for insert with check (auth.uid() = owner_user_id);
create policy workspaces_update_manager on public.workspaces for update using (public.can_manage_workspace(id)) with check (public.can_manage_workspace(id));
create policy workspace_members_select_member on public.workspace_members for select using (public.is_workspace_member(workspace_id));
create policy workspace_members_insert_manager on public.workspace_members for insert with check (public.can_manage_workspace(workspace_id));
create policy workspace_members_update_manager on public.workspace_members for update using (public.can_manage_workspace(workspace_id)) with check (public.can_manage_workspace(workspace_id));
create policy workspace_members_delete_manager on public.workspace_members for delete using (public.can_manage_workspace(workspace_id));
create policy workspace_invites_select_manager on public.workspace_invites for select using (public.can_manage_workspace(workspace_id));
create policy workspace_invites_insert_manager on public.workspace_invites for insert with check (public.can_manage_workspace(workspace_id));
create policy workspace_invites_update_manager on public.workspace_invites for update using (public.can_manage_workspace(workspace_id)) with check (public.can_manage_workspace(workspace_id));
create policy workspace_invites_delete_manager on public.workspace_invites for delete using (public.can_manage_workspace(workspace_id));
create policy user_notifications_select_own on public.user_notifications for select using (recipient_user_id = auth.uid());
create policy user_notifications_update_own on public.user_notifications for update using (recipient_user_id = auth.uid()) with check (recipient_user_id = auth.uid());
create policy categories_select_member on public.categories for select using (public.is_workspace_member(workspace_id) and deleted_at is null);
create policy categories_insert_manager on public.categories for insert with check (public.can_manage_workspace(workspace_id));
create policy categories_update_manager on public.categories for update using (public.can_manage_workspace(workspace_id)) with check (public.can_manage_workspace(workspace_id));
create policy transactions_select_member on public.transactions for select using (public.is_workspace_member(workspace_id));
create policy transactions_insert_member on public.transactions for insert with check (public.is_workspace_member(workspace_id) and created_by_user_id = auth.uid());
create policy transactions_update_member on public.transactions for update using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy attachments_select_member on public.transaction_attachments for select using (public.is_workspace_member(workspace_id));
create policy attachments_insert_member on public.transaction_attachments for insert with check (public.is_workspace_member(workspace_id) and uploaded_by_user_id = auth.uid());
create policy attachments_delete_member on public.transaction_attachments for delete using (public.is_workspace_member(workspace_id));
create policy budgets_select_member on public.budgets for select using (public.is_workspace_member(workspace_id) and deleted_at is null);
create policy budgets_insert_manager on public.budgets for insert with check (public.can_manage_workspace(workspace_id));
create policy budgets_update_manager on public.budgets for update using (public.can_manage_workspace(workspace_id)) with check (public.can_manage_workspace(workspace_id));
create policy activity_logs_select_member on public.activity_logs for select using (public.is_workspace_member(workspace_id));
create policy preferences_select_own on public.user_workspace_preferences for select using (user_id = auth.uid());
create policy preferences_insert_own on public.user_workspace_preferences for insert with check (user_id = auth.uid() and public.is_workspace_member(workspace_id));
create policy preferences_update_own on public.user_workspace_preferences for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy error_reports_insert_own on public.error_reports for insert to authenticated with check (auth.uid() = user_id);
create policy error_reports_select_own on public.error_reports for select to authenticated using (auth.uid() = user_id);
create policy recurring_transactions_select_member on public.recurring_transactions for select using (public.is_workspace_member(workspace_id) and deleted_at is null);
create policy recurring_transactions_insert_member on public.recurring_transactions for insert with check (public.is_workspace_member(workspace_id) and created_by_user_id = auth.uid());
create policy recurring_transactions_update_member on public.recurring_transactions for update using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy recurring_occurrences_select_member on public.recurring_transaction_occurrences for select using (public.is_workspace_member(workspace_id));
create policy recurring_occurrences_insert_member on public.recurring_transaction_occurrences for insert with check (public.is_workspace_member(workspace_id));
create policy recurring_occurrences_update_member on public.recurring_transaction_occurrences for update using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));

create or replace function public.ensure_workspace_setup_for_user(target_user_id uuid, target_email text, target_raw_user_meta_data jsonb default '{}'::jsonb)
returns void as $$
declare
  new_workspace_id uuid;
begin
  insert into public.profiles(id, email, display_name)
  values (target_user_id, target_email, coalesce(target_raw_user_meta_data->>'display_name', split_part(target_email, '@', 1)))
  on conflict (id) do update set email = excluded.email, updated_at = now();

  select id into new_workspace_id
  from public.workspaces
  where owner_user_id = target_user_id and type = 'personal' and deleted_at is null
  order by created_at
  limit 1;

  if new_workspace_id is null then
    insert into public.workspaces(type, name, owner_user_id)
    values ('personal', 'My Workspace', target_user_id)
    returning id into new_workspace_id;
  end if;

  insert into public.workspace_members(workspace_id, user_id, role, membership_status, joined_at)
  values (new_workspace_id, target_user_id, 'owner', 'active', now())
  on conflict (workspace_id, user_id) do update set role = 'owner', membership_status = 'active', removed_at = null, updated_at = now();
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.handle_new_user()
returns trigger as $$
begin
  perform public.ensure_workspace_setup_for_user(new.id, new.email, new.raw_user_meta_data);
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

create or replace function public.create_group_workspace_v2(workspace_name text, workspace_description text default null, workspace_avatar_path text default null)
returns uuid as $$
declare
  new_workspace_id uuid;
begin
  insert into public.workspaces(type, name, owner_user_id, settings)
  values ('group', trim(workspace_name), auth.uid(), jsonb_build_object('description', nullif(trim(coalesce(workspace_description, '')), ''), 'avatar_path', nullif(trim(coalesce(workspace_avatar_path, '')), '')))
  returning id into new_workspace_id;
  insert into public.workspace_members(workspace_id, user_id, role, membership_status, joined_at)
  values (new_workspace_id, auth.uid(), 'owner', 'active', now());
  perform public.log_workspace_activity(new_workspace_id, 'workspace', new_workspace_id, 'workspace_created', 'Workspace created');
  return new_workspace_id;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.get_workspace_members_with_profiles(p_workspace_id uuid)
returns table(member_id uuid, user_id uuid, display_name text, email text, avatar_url text, role text, membership_status text, joined_at timestamptz) as $$
begin
  if not public.is_workspace_member(p_workspace_id) then raise exception 'Not a workspace member'; end if;
  return query
  select wm.id, wm.user_id, p.display_name, p.email, p.avatar_url, wm.role, wm.membership_status, wm.joined_at
  from public.workspace_members wm join public.profiles p on p.id = wm.user_id
  where wm.workspace_id = p_workspace_id and wm.membership_status = 'active'
  order by case wm.role when 'owner' then 0 when 'admin' then 1 else 2 end, p.display_name;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.get_workspace_detail(p_workspace_id uuid)
returns table(id uuid, name text, type text, owner_user_id uuid, description text, avatar_path text, created_at timestamptz, updated_at timestamptz, member_count bigint, current_user_role text) as $$
begin
  if not public.is_workspace_member(p_workspace_id) then raise exception 'Not a workspace member'; end if;
  return query
  select w.id, w.name, w.type, w.owner_user_id, w.settings->>'description', w.settings->>'avatar_path', w.created_at, w.updated_at,
    (select count(*) from public.workspace_members wm where wm.workspace_id = w.id and wm.membership_status = 'active') as member_count,
    (select wm.role from public.workspace_members wm where wm.workspace_id = w.id and wm.user_id = auth.uid() and wm.membership_status = 'active') as current_user_role
  from public.workspaces w where w.id = p_workspace_id and w.deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.get_workspace_activity_logs(p_workspace_id uuid, p_limit integer default 50, p_offset integer default 0)
returns table(id uuid, workspace_id uuid, actor_user_id uuid, actor_display_name text, actor_email text, actor_avatar_url text, entity_type text, entity_id uuid, action text, summary text, payload jsonb, created_at timestamptz) as $$
begin
  if not public.is_workspace_member(p_workspace_id) then raise exception 'Not a workspace member'; end if;
  return query
  select al.id, al.workspace_id, al.actor_user_id, p.display_name, p.email, p.avatar_url, al.entity_type, al.entity_id, al.action, al.summary, al.payload, al.created_at
  from public.activity_logs al left join public.profiles p on p.id = al.actor_user_id
  where al.workspace_id = p_workspace_id
  order by al.created_at desc
  limit greatest(p_limit, 1) offset greatest(p_offset, 0);
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.create_workspace_invite(p_workspace_id uuid, p_email text)
returns table(id uuid, email text, role text, status text, token text, expires_at timestamptz, created_at timestamptz, updated_at timestamptz, matched_user_id uuid, matched_display_name text, matched_avatar_url text) as $$
declare
  normalized_email text := lower(trim(p_email));
  new_token text := encode(extensions.gen_random_bytes(24), 'hex');
  invite_id uuid;
  workspace_name text;
  recipient public.profiles%rowtype;
  inviter public.profiles%rowtype;
begin
  if not public.can_manage_workspace(p_workspace_id) then raise exception 'Only workspace owner or admin can invite members'; end if;

  select * into recipient from public.profiles p where lower(p.email) = normalized_email limit 1;
  if recipient.id is null then raise exception 'WORKSPACE_INVITE_USER_NOT_FOUND'; end if;

  if exists (
    select 1 from public.workspace_members wm
    where wm.workspace_id = p_workspace_id
      and wm.user_id = recipient.id
      and wm.membership_status = 'active'
  ) then raise exception 'WORKSPACE_INVITE_ALREADY_MEMBER'; end if;

  if exists (
    select 1 from public.workspace_invites wi
    where wi.workspace_id = p_workspace_id
      and lower(wi.email) = normalized_email
      and wi.status = 'pending'
      and wi.expires_at > now()
  ) then raise exception 'WORKSPACE_INVITE_ALREADY_PENDING'; end if;

  select w.name into workspace_name from public.workspaces w where w.id = p_workspace_id;
  select * into inviter from public.profiles p where p.id = auth.uid();

  insert into public.workspace_invites(workspace_id, email, role, token, status, invited_by_user_id, expires_at)
  values (p_workspace_id, normalized_email, 'member', new_token, 'pending', auth.uid(), now() + interval '7 days')
  returning workspace_invites.id into invite_id;

  insert into public.user_notifications(recipient_user_id, type, title, body, payload)
  values (
    recipient.id,
    'workspace_invite',
    'Workspace invitation',
    'You were invited to a workspace',
    jsonb_build_object(
      'invite_id', invite_id,
      'workspace_id', p_workspace_id,
      'workspace_name', workspace_name,
      'invite_token', new_token,
      'invited_by_user_id', auth.uid(),
      'invited_by_email', inviter.email,
      'invited_by_display_name', inviter.display_name
    )
  );

  return query
  select wi.id, wi.email, wi.role, wi.status, wi.token, wi.expires_at, wi.created_at, wi.updated_at, p.id, p.display_name, p.avatar_url
  from public.workspace_invites wi left join public.profiles p on lower(p.email) = lower(wi.email)
  where wi.id = invite_id;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.get_workspace_invites_with_profiles(p_workspace_id uuid)
returns table(id uuid, email text, role text, status text, token text, expires_at timestamptz, created_at timestamptz, updated_at timestamptz, matched_user_id uuid, matched_display_name text, matched_avatar_url text) as $$
begin
  if not public.can_manage_workspace(p_workspace_id) then raise exception 'Only workspace owner or admin can view invites'; end if;
  return query
  select wi.id, wi.email, wi.role, wi.status, wi.token, wi.expires_at, wi.created_at, wi.updated_at, p.id, p.display_name, p.avatar_url
  from public.workspace_invites wi left join public.profiles p on lower(p.email) = lower(wi.email)
  where wi.workspace_id = p_workspace_id and wi.status in ('pending', 'declined', 'revoked')
  order by wi.created_at desc;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.get_my_pending_workspace_invites()
returns table(id uuid, workspace_id uuid, workspace_name text, email text, role text, status text, token text, expires_at timestamptz, created_at timestamptz, invited_by_user_id uuid, invited_by_email text, invited_by_display_name text) as $$
declare
  current_user_email text;
begin
  select au.email into current_user_email from auth.users au where au.id = auth.uid();
  if current_user_email is null then return; end if;
  return query
  select wi.id, wi.workspace_id, w.name, wi.email, wi.role, wi.status, wi.token, wi.expires_at, wi.created_at, wi.invited_by_user_id, inviter.email, inviter.display_name
  from public.workspace_invites wi
  join public.workspaces w on w.id = wi.workspace_id
  left join public.profiles inviter on inviter.id = wi.invited_by_user_id
  where wi.status = 'pending' and wi.expires_at > now() and lower(wi.email) = lower(current_user_email)
  order by wi.created_at desc;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.get_my_notifications(p_limit int default 50, p_offset int default 0)
returns table(id uuid, recipient_user_id uuid, type text, title text, body text, payload jsonb, read_at timestamptz, created_at timestamptz) as $$
begin
  return query
  select un.id, un.recipient_user_id, un.type, un.title, un.body, un.payload, un.read_at, un.created_at
  from public.user_notifications un
  where un.recipient_user_id = auth.uid()
  order by un.created_at desc
  limit greatest(p_limit, 1) offset greatest(p_offset, 0);
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.get_my_unread_notification_count()
returns integer as $$
declare
  notification_count integer;
begin
  select count(*)::integer into notification_count
  from public.user_notifications un
  where un.recipient_user_id = auth.uid()
    and un.read_at is null;

  return notification_count;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.mark_notification_read(p_notification_id uuid)
returns boolean as $$
begin
  update public.user_notifications
  set read_at = coalesce(read_at, now()), updated_at = now()
  where id = p_notification_id
    and recipient_user_id = auth.uid();

  return found;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.get_workspace_invite_preview(invite_token text)
returns jsonb as $$
declare
  invite_record public.workspace_invites%rowtype;
  workspace_record public.workspaces%rowtype;
  inviter public.profiles%rowtype;
  members jsonb;
begin
  select * into invite_record from public.workspace_invites where token = trim(invite_token) and status = 'pending' and expires_at > now();
  if not found then raise exception 'Invalid or expired invite'; end if;
  select * into workspace_record from public.workspaces where id = invite_record.workspace_id;
  select * into inviter from public.profiles where id = invite_record.invited_by_user_id;
  select coalesce(jsonb_agg(jsonb_build_object('user_id', wm.user_id, 'display_name', p.display_name, 'email', p.email, 'avatar_url', p.avatar_url, 'role', wm.role, 'joined_at', wm.joined_at)), '[]'::jsonb)
  into members
  from public.workspace_members wm join public.profiles p on p.id = wm.user_id
  where wm.workspace_id = invite_record.workspace_id and wm.membership_status = 'active';
  return jsonb_build_object('workspace_id', workspace_record.id, 'workspace_name', workspace_record.name, 'workspace_type', workspace_record.type, 'description', workspace_record.settings->>'description', 'avatar_path', workspace_record.settings->>'avatar_path', 'email', invite_record.email, 'role', invite_record.role, 'token', invite_record.token, 'expires_at', invite_record.expires_at, 'invited_by_user_id', invite_record.invited_by_user_id, 'invited_by_display_name', inviter.display_name, 'invited_by_email', inviter.email, 'members', members);
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.accept_workspace_invite(invite_token text)
returns jsonb as $$
declare
  invite_record public.workspace_invites%rowtype;
  current_user_email text;
begin
  select * into invite_record from public.workspace_invites where token = trim(invite_token) and status = 'pending' and expires_at > now();
  if not found then return jsonb_build_object('success', false, 'error', 'Invalid or expired invite'); end if;
  select au.email into current_user_email from auth.users au where au.id = auth.uid();
  if current_user_email is null or lower(invite_record.email) <> lower(current_user_email) then return jsonb_build_object('success', false, 'error', 'Email mismatch'); end if;
  insert into public.workspace_members(workspace_id, user_id, role, membership_status, joined_at, invited_by_user_id)
  values (invite_record.workspace_id, auth.uid(), invite_record.role, 'active', now(), invite_record.invited_by_user_id)
  on conflict (workspace_id, user_id) do update set role = excluded.role, membership_status = 'active', removed_at = null, updated_at = now();
  update public.workspace_invites set status = 'accepted', accepted_by_user_id = auth.uid(), updated_at = now() where id = invite_record.id;
  update public.user_notifications
  set read_at = coalesce(read_at, now()), updated_at = now()
  where recipient_user_id = auth.uid()
    and type = 'workspace_invite'
    and payload->>'invite_id' = invite_record.id::text;
  return jsonb_build_object('success', true, 'workspace_id', invite_record.workspace_id);
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.decline_workspace_invite(invite_token text)
returns jsonb as $$
declare
  invite_record public.workspace_invites%rowtype;
begin
  select * into invite_record from public.workspace_invites where token = trim(invite_token) and status = 'pending' and expires_at > now();
  if not found then return jsonb_build_object('success', false, 'error', 'Invalid or expired invite'); end if;
  update public.workspace_invites set status = 'declined', updated_at = now() where id = invite_record.id;
  update public.user_notifications
  set read_at = coalesce(read_at, now()), updated_at = now()
  where recipient_user_id = auth.uid()
    and type = 'workspace_invite'
    and payload->>'invite_id' = invite_record.id::text;
  return jsonb_build_object('success', true, 'invite_id', invite_record.id, 'workspace_id', invite_record.workspace_id);
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.revoke_workspace_invite(invite_id uuid)
returns boolean as $$
declare
  target_workspace_id uuid;
begin
  select workspace_id into target_workspace_id from public.workspace_invites where id = invite_id and status = 'pending';
  if target_workspace_id is null then raise exception 'Pending invite not found'; end if;
  if not public.can_manage_workspace(target_workspace_id) then raise exception 'Only workspace owner or admin can revoke invites'; end if;
  update public.workspace_invites set status = 'revoked', updated_at = now() where id = invite_id;
  return true;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.refresh_workspace_invite(p_invite_id uuid)
returns table(id uuid, email text, role text, status text, token text, expires_at timestamptz, created_at timestamptz, updated_at timestamptz, matched_user_id uuid, matched_display_name text, matched_avatar_url text) as $$
declare
  new_token text := encode(extensions.gen_random_bytes(24), 'hex');
  target_workspace_id uuid;
begin
  select workspace_id into target_workspace_id from public.workspace_invites where workspace_invites.id = p_invite_id;
  if not public.can_manage_workspace(target_workspace_id) then raise exception 'Only workspace owner or admin can refresh invites'; end if;
  update public.workspace_invites set token = new_token, status = 'pending', expires_at = now() + interval '7 days', updated_at = now() where workspace_invites.id = p_invite_id;
  return query
  select wi.id, wi.email, wi.role, wi.status, wi.token, wi.expires_at, wi.created_at, wi.updated_at, p.id, p.display_name, p.avatar_url
  from public.workspace_invites wi left join public.profiles p on lower(p.email) = lower(wi.email)
  where wi.id = p_invite_id;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.leave_workspace(p_workspace_id uuid)
returns void as $$
begin
  update public.workspace_members set membership_status = 'removed', removed_at = now(), updated_at = now()
  where workspace_id = p_workspace_id and user_id = auth.uid() and role <> 'owner';
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.transfer_workspace_owner(p_workspace_id uuid, p_new_owner_user_id uuid)
returns void as $$
begin
  if not public.is_workspace_owner(p_workspace_id) then raise exception 'Only owner can transfer ownership'; end if;
  update public.workspace_members set role = 'admin', updated_at = now() where workspace_id = p_workspace_id and user_id = auth.uid();
  update public.workspace_members set role = 'owner', updated_at = now() where workspace_id = p_workspace_id and user_id = p_new_owner_user_id;
  update public.workspaces set owner_user_id = p_new_owner_user_id, updated_at = now() where id = p_workspace_id;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.update_workspace_member_role(p_workspace_id uuid, p_user_id uuid, p_role text)
returns void as $$
begin
  if not public.is_workspace_owner(p_workspace_id) then raise exception 'Only owner can update roles'; end if;
  if p_role not in ('admin', 'member') then raise exception 'Invalid role'; end if;
  update public.workspace_members set role = p_role, updated_at = now() where workspace_id = p_workspace_id and user_id = p_user_id and role <> 'owner';
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.remove_workspace_member(p_workspace_id uuid, p_user_id uuid)
returns void as $$
begin
  if not public.can_manage_workspace(p_workspace_id) then raise exception 'Only workspace owner or admin can remove members'; end if;
  update public.workspace_members set membership_status = 'removed', removed_at = now(), updated_at = now() where workspace_id = p_workspace_id and user_id = p_user_id and role <> 'owner';
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.create_category_rpc(p_workspace_id uuid, p_name text, p_type text, p_icon_name text, p_color_value text, p_id uuid default null, p_created_at timestamptz default now(), p_updated_at timestamptz default now())
returns public.categories as $$
declare inserted public.categories;
begin
  insert into public.categories(id, workspace_id, name, normalized_name, type, icon_name, color_value, created_by_user_id, updated_by_user_id, created_at, updated_at)
  values (coalesce(p_id, gen_random_uuid()), p_workspace_id, trim(p_name), public.normalize_name(p_name), p_type, p_icon_name, p_color_value, auth.uid(), auth.uid(), p_created_at, p_updated_at)
  returning * into inserted;
  return inserted;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.update_category_rpc(p_category_id uuid, p_workspace_id uuid, p_name text, p_type text, p_icon_name text, p_color_value text, p_updated_at timestamptz default now())
returns void as $$
begin
  update public.categories set name = trim(p_name), normalized_name = public.normalize_name(p_name), type = p_type, icon_name = p_icon_name, color_value = p_color_value, updated_by_user_id = auth.uid(), updated_at = p_updated_at, version = version + 1
  where id = p_category_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.soft_delete_category_rpc(p_category_id uuid, p_workspace_id uuid)
returns void as $$
begin
  update public.categories set deleted_at = now(), deleted_by_user_id = auth.uid(), updated_by_user_id = auth.uid(), updated_at = now(), version = version + 1
  where id = p_category_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.create_transaction_rpc(p_workspace_id uuid, p_category_id uuid, p_amount_minor bigint, p_currency_code text, p_transaction_type text, p_transaction_at timestamptz, p_note text default null, p_client_reference_id text default null, p_allow_overdraft_override boolean default false, p_id uuid default null, p_created_at timestamptz default now(), p_updated_at timestamptz default now())
returns public.transactions as $$
declare inserted public.transactions;
begin
  insert into public.transactions(id, workspace_id, category_id, amount_minor, currency_code, transaction_type, transaction_at, note, client_reference_id, created_by_user_id, updated_by_user_id, created_at, updated_at)
  values (coalesce(p_id, gen_random_uuid()), p_workspace_id, p_category_id, p_amount_minor, p_currency_code, p_transaction_type, p_transaction_at, p_note, p_client_reference_id, auth.uid(), auth.uid(), p_created_at, p_updated_at)
  returning * into inserted;
  return inserted;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.update_transaction_rpc(p_transaction_id uuid, p_workspace_id uuid, p_category_id uuid, p_amount_minor bigint, p_currency_code text, p_transaction_type text, p_transaction_at timestamptz, p_note text default null, p_allow_overdraft_override boolean default false, p_updated_at timestamptz default now())
returns void as $$
begin
  update public.transactions set category_id = p_category_id, amount_minor = p_amount_minor, currency_code = p_currency_code, transaction_type = p_transaction_type, transaction_at = p_transaction_at, note = p_note, updated_by_user_id = auth.uid(), updated_at = p_updated_at, version = version + 1
  where id = p_transaction_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.soft_delete_transaction_rpc(p_transaction_id uuid, p_workspace_id uuid)
returns void as $$
begin
  update public.transactions set deleted_at = now(), deleted_by_user_id = auth.uid(), updated_by_user_id = auth.uid(), updated_at = now(), version = version + 1
  where id = p_transaction_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.create_budget_rpc(p_workspace_id uuid, p_category_id uuid, p_period_type text, p_period_start timestamptz, p_period_end timestamptz, p_limit_minor bigint, p_currency_code text, p_allow_overdraft boolean default false, p_id uuid default null, p_created_at timestamptz default now(), p_updated_at timestamptz default now())
returns public.budgets as $$
declare inserted public.budgets;
begin
  insert into public.budgets(id, workspace_id, category_id, period_type, period_start, period_end, limit_minor, currency_code, allow_overdraft, created_by_user_id, updated_by_user_id, created_at, updated_at)
  values (coalesce(p_id, gen_random_uuid()), p_workspace_id, p_category_id, p_period_type, p_period_start, p_period_end, p_limit_minor, p_currency_code, p_allow_overdraft, auth.uid(), auth.uid(), p_created_at, p_updated_at)
  returning * into inserted;
  return inserted;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.update_budget_rpc(p_budget_id uuid, p_workspace_id uuid, p_category_id uuid, p_period_type text, p_period_start timestamptz, p_period_end timestamptz, p_limit_minor bigint, p_currency_code text, p_allow_overdraft boolean default false, p_updated_at timestamptz default now())
returns void as $$
begin
  update public.budgets set category_id = p_category_id, period_type = p_period_type, period_start = p_period_start, period_end = p_period_end, limit_minor = p_limit_minor, currency_code = p_currency_code, allow_overdraft = p_allow_overdraft, updated_by_user_id = auth.uid(), updated_at = p_updated_at, version = version + 1
  where id = p_budget_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.soft_delete_budget_rpc(p_budget_id uuid, p_workspace_id uuid)
returns void as $$
begin
  update public.budgets set deleted_at = now(), deleted_by_user_id = auth.uid(), updated_by_user_id = auth.uid(), updated_at = now(), version = version + 1
  where id = p_budget_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.create_error_report(p_error_type text, p_error_message text, p_stack_trace text default null, p_device_info jsonb default null, p_app_version text default null, p_platform text default null, p_context jsonb default null)
returns uuid as $$
declare v_report_id uuid;
begin
  insert into public.error_reports(user_id, error_type, error_message, stack_trace, device_info, app_version, platform, context)
  values (auth.uid(), p_error_type, p_error_message, p_stack_trace, p_device_info, p_app_version, p_platform, p_context)
  returning id into v_report_id;
  return v_report_id;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.recurring_safe_date(p_year integer, p_month integer, p_day integer)
returns date as $$
declare max_day integer;
begin
  max_day := extract(day from (make_date(p_year, p_month, 1) + interval '1 month - 1 day'))::integer;
  return make_date(p_year, p_month, least(greatest(p_day, 1), max_day));
end;
$$ language plpgsql immutable;

create or replace function public.next_recurring_occurrence_at(p_current_occurrence_at timestamptz, p_frequency text, p_interval_count integer, p_day_of_month integer, p_day_of_week integer, p_month_of_year integer)
returns timestamptz as $$
declare
  safe_interval integer := greatest(p_interval_count, 1);
  current_date date := p_current_occurrence_at::date;
  current_time time := p_current_occurrence_at::time;
  base_date date;
  next_date date;
begin
  case p_frequency
    when 'weekly' then next_date := current_date + (safe_interval * 7);
    when 'monthly' then
      base_date := (current_date + make_interval(months => safe_interval))::date;
      next_date := public.recurring_safe_date(extract(year from base_date)::integer, extract(month from base_date)::integer, coalesce(p_day_of_month, extract(day from current_date)::integer));
    when 'yearly' then
      base_date := (current_date + make_interval(years => safe_interval))::date;
      next_date := public.recurring_safe_date(extract(year from base_date)::integer, coalesce(p_month_of_year, extract(month from current_date)::integer), coalesce(p_day_of_month, extract(day from current_date)::integer));
    else raise exception 'Unsupported recurring frequency: %', p_frequency;
  end case;
  return next_date::timestamp + current_time;
end;
$$ language plpgsql immutable;

create or replace function public.create_recurring_transaction_rpc(id uuid, workspace_id uuid, title text, category_id uuid, amount_minor bigint, currency_code text, transaction_type text, frequency text, mode text, interval_count integer, start_date timestamptz, next_occurrence_at timestamptz, reminder_days_before integer, is_active boolean, created_by_user_id uuid, updated_by_user_id uuid, created_at timestamptz, updated_at timestamptz, note text default null, day_of_month integer default null, day_of_week integer default null, month_of_year integer default null, end_date timestamptz default null)
returns public.recurring_transactions as $$
declare inserted public.recurring_transactions;
begin
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
  delete from public.recurring_transaction_occurrences where recurring_transaction_id = id and status = 'pending';
  update public.recurring_transactions rt set title = trim(update_recurring_transaction_rpc.title), category_id = update_recurring_transaction_rpc.category_id, amount_minor = update_recurring_transaction_rpc.amount_minor, currency_code = update_recurring_transaction_rpc.currency_code, transaction_type = update_recurring_transaction_rpc.transaction_type, frequency = update_recurring_transaction_rpc.frequency, mode = update_recurring_transaction_rpc.mode, interval_count = update_recurring_transaction_rpc.interval_count, note = update_recurring_transaction_rpc.note, day_of_month = update_recurring_transaction_rpc.day_of_month, day_of_week = update_recurring_transaction_rpc.day_of_week, month_of_year = update_recurring_transaction_rpc.month_of_year, start_date = update_recurring_transaction_rpc.start_date, end_date = update_recurring_transaction_rpc.end_date, next_occurrence_at = update_recurring_transaction_rpc.next_occurrence_at, reminder_days_before = update_recurring_transaction_rpc.reminder_days_before, is_active = update_recurring_transaction_rpc.is_active, updated_by_user_id = auth.uid(), updated_at = update_recurring_transaction_rpc.updated_at
  where rt.id = update_recurring_transaction_rpc.id and rt.workspace_id = update_recurring_transaction_rpc.workspace_id and rt.deleted_at is null
  returning * into updated_row;
  return updated_row;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.soft_delete_recurring_transaction_rpc(p_recurring_transaction_id uuid, p_workspace_id uuid)
returns void as $$
begin
  delete from public.recurring_transaction_occurrences where recurring_transaction_id = p_recurring_transaction_id and status = 'pending';
  update public.recurring_transactions set deleted_at = now(), deleted_by_user_id = auth.uid(), updated_by_user_id = auth.uid(), updated_at = now(), is_active = false
  where id = p_recurring_transaction_id and workspace_id = p_workspace_id and deleted_at is null;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.generate_recurring_occurrences_rpc(p_workspace_id uuid, p_through_date timestamptz)
returns void as $$
declare item public.recurring_transactions%rowtype;
begin
  for item in select * from public.recurring_transactions where workspace_id = p_workspace_id and deleted_at is null and is_active = true and next_occurrence_at <= p_through_date and (end_date is null or next_occurrence_at <= end_date)
  loop
    insert into public.recurring_transaction_occurrences(recurring_transaction_id, workspace_id, scheduled_for, remind_at, status)
    values (item.id, item.workspace_id, item.next_occurrence_at, item.next_occurrence_at - make_interval(days => item.reminder_days_before), 'pending')
    on conflict (recurring_transaction_id, scheduled_for) do nothing;
  end loop;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.skip_recurring_occurrence_rpc(p_occurrence_id uuid, p_workspace_id uuid)
returns void as $$
declare occurrence_row public.recurring_transaction_occurrences%rowtype; recurring_row public.recurring_transactions%rowtype;
begin
  select * into occurrence_row from public.recurring_transaction_occurrences where id = p_occurrence_id and workspace_id = p_workspace_id;
  if occurrence_row.id is null then raise exception 'Recurring occurrence not found'; end if;
  select * into recurring_row from public.recurring_transactions where id = occurrence_row.recurring_transaction_id and workspace_id = p_workspace_id and deleted_at is null;
  update public.recurring_transaction_occurrences set status = 'skipped', updated_at = now() where id = p_occurrence_id;
  update public.recurring_transactions set next_occurrence_at = public.next_recurring_occurrence_at(recurring_row.next_occurrence_at, recurring_row.frequency, recurring_row.interval_count, recurring_row.day_of_month, recurring_row.day_of_week, recurring_row.month_of_year), updated_by_user_id = auth.uid(), updated_at = now() where id = recurring_row.id;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.complete_recurring_occurrence_rpc(p_occurrence_id uuid, p_workspace_id uuid, p_generated_transaction_id uuid)
returns void as $$
declare occurrence_row public.recurring_transaction_occurrences%rowtype; recurring_row public.recurring_transactions%rowtype;
begin
  select * into occurrence_row from public.recurring_transaction_occurrences where id = p_occurrence_id and workspace_id = p_workspace_id;
  if occurrence_row.id is null then raise exception 'Recurring occurrence not found'; end if;
  select * into recurring_row from public.recurring_transactions where id = occurrence_row.recurring_transaction_id and workspace_id = p_workspace_id and deleted_at is null;
  update public.recurring_transaction_occurrences set status = 'completed', generated_transaction_id = p_generated_transaction_id, updated_at = now() where id = p_occurrence_id;
  update public.recurring_transactions set next_occurrence_at = public.next_recurring_occurrence_at(recurring_row.next_occurrence_at, recurring_row.frequency, recurring_row.interval_count, recurring_row.day_of_month, recurring_row.day_of_week, recurring_row.month_of_year), updated_by_user_id = auth.uid(), updated_at = now() where id = recurring_row.id;
end;
$$ language plpgsql security definer set search_path = public;

insert into storage.buckets(id, name, public)
values ('transaction-receipts', 'transaction-receipts', false)
on conflict (id) do nothing;

drop policy if exists transaction_receipts_select_member on storage.objects;
create policy transaction_receipts_select_member
  on storage.objects for select
  using (
    bucket_id = 'transaction-receipts'
    and split_part(name, '/', 1) = 'workspaces'
    and public.is_workspace_member(split_part(name, '/', 2)::uuid)
  );

drop policy if exists transaction_receipts_insert_creator on storage.objects;
create policy transaction_receipts_insert_creator
  on storage.objects for insert
  with check (
    bucket_id = 'transaction-receipts'
    and split_part(name, '/', 1) = 'workspaces'
    and split_part(name, '/', 3) = 'transactions'
    and exists (
      select 1
      from public.transactions
      where transactions.id = split_part(name, '/', 4)::uuid
        and transactions.workspace_id = split_part(name, '/', 2)::uuid
        and transactions.created_by_user_id = auth.uid()
    )
  );

drop policy if exists transaction_receipts_delete_creator on storage.objects;
create policy transaction_receipts_delete_creator
  on storage.objects for delete
  using (
    bucket_id = 'transaction-receipts'
    and split_part(name, '/', 1) = 'workspaces'
    and split_part(name, '/', 3) = 'transactions'
    and exists (
      select 1
      from public.transactions
      where transactions.id = split_part(name, '/', 4)::uuid
        and transactions.workspace_id = split_part(name, '/', 2)::uuid
        and transactions.created_by_user_id = auth.uid()
    )
  );

grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to service_role;
grant all on all routines in schema public to service_role;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant execute on all routines in schema public to authenticated;

do $$
declare auth_user auth.users%rowtype;
begin
  for auth_user in select * from auth.users loop
    perform public.ensure_workspace_setup_for_user(auth_user.id, auth_user.email, auth_user.raw_user_meta_data);
  end loop;
end;
$$;

notify pgrst, 'reload schema';

commit;
