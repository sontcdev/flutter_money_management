-- Full Supabase bootstrap schema for flutter_money_management
-- Intended for a clean Supabase project or a database you have reset manually.

BEGIN;

-- Reset existing app objects so this script can rebuild the schema from scratch.
DROP POLICY IF EXISTS transaction_receipts_select_member ON storage.objects;
DROP POLICY IF EXISTS transaction_receipts_insert_creator ON storage.objects;
DROP POLICY IF EXISTS transaction_receipts_delete_creator ON storage.objects;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

DROP TABLE IF EXISTS public.user_workspace_preferences CASCADE;
DROP TABLE IF EXISTS public.activity_logs CASCADE;
DROP TABLE IF EXISTS public.transaction_attachments CASCADE;
DROP TABLE IF EXISTS public.transactions CASCADE;
DROP TABLE IF EXISTS public.budgets CASCADE;
DROP TABLE IF EXISTS public.categories CASCADE;
DROP TABLE IF EXISTS public.workspace_invites CASCADE;
DROP TABLE IF EXISTS public.workspace_members CASCADE;
DROP TABLE IF EXISTS public.workspaces CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

DROP FUNCTION IF EXISTS public.create_transaction_rpc(uuid, uuid, bigint, text, text, timestamptz, text, text, boolean, uuid, timestamptz, timestamptz);
DROP FUNCTION IF EXISTS public.update_transaction_rpc(uuid, uuid, uuid, bigint, text, text, timestamptz, text, boolean, timestamptz);
DROP FUNCTION IF EXISTS public.soft_delete_transaction_rpc(uuid, uuid);
DROP FUNCTION IF EXISTS public.create_budget_rpc(uuid, uuid, text, timestamptz, timestamptz, bigint, text, boolean, uuid, timestamptz, timestamptz);
DROP FUNCTION IF EXISTS public.update_budget_rpc(uuid, uuid, uuid, text, timestamptz, timestamptz, bigint, text, boolean, timestamptz);
DROP FUNCTION IF EXISTS public.soft_delete_budget_rpc(uuid, uuid);
DROP FUNCTION IF EXISTS public.create_category_rpc(uuid, text, text, text, text, uuid, timestamptz, timestamptz);
DROP FUNCTION IF EXISTS public.update_category_rpc(uuid, uuid, text, text, text, text, timestamptz);
DROP FUNCTION IF EXISTS public.soft_delete_category_rpc(uuid, uuid);
DROP FUNCTION IF EXISTS public.create_group_workspace(text, jsonb);
DROP FUNCTION IF EXISTS public.accept_workspace_invite(text);
DROP FUNCTION IF EXISTS public.revoke_workspace_invite(uuid);
DROP FUNCTION IF EXISTS public.archive_workspace(uuid);
DROP FUNCTION IF EXISTS public.ensure_workspace_setup_for_user(uuid, text, jsonb);
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.categories_soft_delete_guard_trigger();
DROP FUNCTION IF EXISTS public.budgets_business_rules_trigger();
DROP FUNCTION IF EXISTS public.assert_budget_period_not_overlapping(uuid, uuid, uuid, timestamptz, timestamptz);
DROP FUNCTION IF EXISTS public.transactions_business_rules_trigger();
DROP FUNCTION IF EXISTS public.assert_transaction_budget_allowed(uuid, uuid, uuid, timestamptz, bigint, text, boolean);
DROP FUNCTION IF EXISTS public.assert_transaction_category_valid(uuid, uuid, text);
DROP FUNCTION IF EXISTS public.can_edit_transaction(uuid, uuid);
DROP FUNCTION IF EXISTS public.is_active_member(uuid);
DROP FUNCTION IF EXISTS public.is_workspace_owner(uuid);
DROP FUNCTION IF EXISTS public.is_workspace_member(uuid);
DROP FUNCTION IF EXISTS public.categories_normalize_name();
DROP FUNCTION IF EXISTS public.normalize_name(text);
DROP FUNCTION IF EXISTS public.set_updated_at();

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION normalize_name(input_text text)
RETURNS text AS $$
BEGIN
  RETURN lower(trim(input_text));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL UNIQUE,
  display_name text NOT NULL,
  avatar_url text,
  phone text,
  default_currency_code text NOT NULL DEFAULT 'VND',
  locale text NOT NULL DEFAULT 'vi',
  timezone text NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  status text NOT NULL DEFAULT 'active',
  last_active_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT profiles_status_check CHECK (status IN ('active', 'disabled', 'deleted')),
  CONSTRAINT profiles_display_name_check CHECK (char_length(display_name) > 0)
);

CREATE UNIQUE INDEX profiles_email_idx ON public.profiles(email);
CREATE INDEX profiles_status_idx ON public.profiles(status);

CREATE TABLE public.workspaces (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL,
  name text NOT NULL,
  slug text,
  owner_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  default_currency_code text NOT NULL DEFAULT 'VND',
  timezone text NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  month_start_day smallint NOT NULL DEFAULT 1,
  status text NOT NULL DEFAULT 'active',
  settings jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT workspaces_type_check CHECK (type IN ('personal', 'group')),
  CONSTRAINT workspaces_status_check CHECK (status IN ('active', 'archived', 'deleted')),
  CONSTRAINT workspaces_month_start_day_check CHECK (month_start_day BETWEEN 1 AND 31)
);

CREATE INDEX workspaces_owner_user_id_idx ON public.workspaces(owner_user_id);
CREATE INDEX workspaces_type_status_idx ON public.workspaces(type, status);

CREATE TABLE public.workspace_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role text NOT NULL,
  membership_status text NOT NULL DEFAULT 'active',
  permissions jsonb NOT NULL DEFAULT '{}'::jsonb,
  joined_at timestamptz,
  invited_by_user_id uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  removed_at timestamptz,
  CONSTRAINT workspace_members_role_check CHECK (role IN ('owner', 'member')),
  CONSTRAINT workspace_members_status_check CHECK (membership_status IN ('pending', 'active', 'removed', 'declined')),
  CONSTRAINT workspace_members_unique UNIQUE (workspace_id, user_id)
);

CREATE INDEX workspace_members_workspace_id_idx ON public.workspace_members(workspace_id);
CREATE INDEX workspace_members_user_id_idx ON public.workspace_members(user_id);
CREATE INDEX workspace_members_workspace_status_idx ON public.workspace_members(workspace_id, membership_status);

CREATE TABLE public.workspace_invites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  email text NOT NULL,
  role text NOT NULL DEFAULT 'member',
  token text NOT NULL UNIQUE,
  status text NOT NULL DEFAULT 'pending',
  invited_by_user_id uuid NOT NULL REFERENCES public.profiles(id),
  accepted_by_user_id uuid REFERENCES public.profiles(id),
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT workspace_invites_role_check CHECK (role IN ('member')),
  CONSTRAINT workspace_invites_status_check CHECK (status IN ('pending', 'accepted', 'expired', 'revoked'))
);

CREATE UNIQUE INDEX workspace_invites_token_idx ON public.workspace_invites(token);
CREATE INDEX workspace_invites_workspace_id_idx ON public.workspace_invites(workspace_id);
CREATE INDEX workspace_invites_email_idx ON public.workspace_invites(email);
CREATE INDEX workspace_invites_status_idx ON public.workspace_invites(status);

CREATE TABLE public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  normalized_name text NOT NULL,
  type text NOT NULL,
  icon_name text NOT NULL,
  color_value text NOT NULL,
  is_system boolean NOT NULL DEFAULT false,
  is_archived boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0,
  created_by_user_id uuid NOT NULL REFERENCES public.profiles(id),
  updated_by_user_id uuid NOT NULL REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  deleted_by_user_id uuid REFERENCES public.profiles(id),
  version integer NOT NULL DEFAULT 1,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  CONSTRAINT categories_type_check CHECK (type IN ('expense', 'income')),
  CONSTRAINT categories_version_check CHECK (version > 0),
  CONSTRAINT categories_color_value_hex_check CHECK (color_value ~ '^[0-9A-F]{8}$')
);

CREATE UNIQUE INDEX categories_workspace_name_type_unique_idx
  ON public.categories(workspace_id, normalized_name, type)
  WHERE deleted_at IS NULL;
CREATE INDEX categories_workspace_id_idx ON public.categories(workspace_id);
CREATE INDEX categories_workspace_type_idx ON public.categories(workspace_id, type);

CREATE TABLE public.transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES public.categories(id),
  amount_minor bigint NOT NULL,
  currency_code text NOT NULL,
  transaction_type text NOT NULL,
  transaction_at timestamptz NOT NULL,
  note text,
  source text NOT NULL DEFAULT 'manual',
  client_reference_id text,
  receipt_path text,
  created_by_user_id uuid NOT NULL REFERENCES public.profiles(id),
  updated_by_user_id uuid NOT NULL REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  deleted_by_user_id uuid REFERENCES public.profiles(id),
  version integer NOT NULL DEFAULT 1,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  CONSTRAINT transactions_type_check CHECK (transaction_type IN ('expense', 'income')),
  CONSTRAINT transactions_source_check CHECK (source IN ('manual', 'import', 'system')),
  CONSTRAINT transactions_amount_check CHECK (amount_minor > 0),
  CONSTRAINT transactions_version_check CHECK (version > 0)
);

CREATE INDEX transactions_workspace_id_idx ON public.transactions(workspace_id);
CREATE INDEX transactions_workspace_date_idx ON public.transactions(workspace_id, transaction_at DESC);
CREATE INDEX transactions_workspace_category_date_idx ON public.transactions(workspace_id, category_id, transaction_at DESC);
CREATE INDEX transactions_workspace_creator_date_idx ON public.transactions(workspace_id, created_by_user_id, transaction_at DESC);
CREATE INDEX transactions_workspace_type_date_idx
  ON public.transactions(workspace_id, transaction_type, transaction_at DESC)
  WHERE deleted_at IS NULL;

CREATE TABLE public.transaction_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  transaction_id uuid NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
  storage_bucket text NOT NULL,
  storage_path text NOT NULL,
  file_name text NOT NULL,
  mime_type text,
  file_size bigint,
  checksum text,
  uploaded_by_user_id uuid NOT NULL REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX transaction_attachments_transaction_id_idx ON public.transaction_attachments(transaction_id);
CREATE INDEX transaction_attachments_workspace_id_idx ON public.transaction_attachments(workspace_id);

CREATE TABLE public.budgets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES public.categories(id),
  name text,
  period_type text NOT NULL,
  period_start timestamptz NOT NULL,
  period_end timestamptz NOT NULL,
  limit_minor bigint NOT NULL,
  currency_code text NOT NULL,
  allow_overdraft boolean NOT NULL DEFAULT false,
  is_archived boolean NOT NULL DEFAULT false,
  created_by_user_id uuid NOT NULL REFERENCES public.profiles(id),
  updated_by_user_id uuid NOT NULL REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  deleted_by_user_id uuid REFERENCES public.profiles(id),
  version integer NOT NULL DEFAULT 1,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  CONSTRAINT budgets_period_type_check CHECK (period_type IN ('monthly', 'yearly', 'custom')),
  CONSTRAINT budgets_period_check CHECK (period_end >= period_start),
  CONSTRAINT budgets_limit_check CHECK (limit_minor > 0),
  CONSTRAINT budgets_version_check CHECK (version > 0)
);

CREATE INDEX budgets_workspace_id_idx ON public.budgets(workspace_id);
CREATE INDEX budgets_workspace_category_idx ON public.budgets(workspace_id, category_id);
CREATE INDEX budgets_workspace_period_idx ON public.budgets(workspace_id, period_start, period_end);

CREATE TABLE public.activity_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  actor_user_id uuid NOT NULL REFERENCES public.profiles(id),
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  action text NOT NULL,
  summary text,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX activity_logs_workspace_id_idx ON public.activity_logs(workspace_id);
CREATE INDEX activity_logs_workspace_created_idx ON public.activity_logs(workspace_id, created_at DESC);
CREATE INDEX activity_logs_entity_idx ON public.activity_logs(entity_type, entity_id);

CREATE TABLE public.user_workspace_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  preferred_report_range text,
  preferred_chart_type text,
  last_selected_tab text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_workspace_preferences_unique UNIQUE (user_id, workspace_id)
);

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER workspaces_updated_at
  BEFORE UPDATE ON public.workspaces
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER workspace_members_updated_at
  BEFORE UPDATE ON public.workspace_members
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER workspace_invites_updated_at
  BEFORE UPDATE ON public.workspace_invites
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER categories_updated_at
  BEFORE UPDATE ON public.categories
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER transactions_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER budgets_updated_at
  BEFORE UPDATE ON public.budgets
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER user_workspace_preferences_updated_at
  BEFORE UPDATE ON public.user_workspace_preferences
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE OR REPLACE FUNCTION public.categories_normalize_name()
RETURNS trigger AS $$
BEGIN
  NEW.normalized_name = normalize_name(NEW.name);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER categories_normalize_name_trigger
  BEFORE INSERT OR UPDATE OF name ON public.categories
  FOR EACH ROW
  EXECUTE FUNCTION public.categories_normalize_name();

CREATE OR REPLACE FUNCTION public.is_workspace_member(workspace_uuid uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.workspace_members
    WHERE workspace_id = workspace_uuid
      AND user_id = auth.uid()
      AND membership_status = 'active'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_workspace_owner(workspace_uuid uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.workspace_members
    WHERE workspace_id = workspace_uuid
      AND user_id = auth.uid()
      AND role = 'owner'
      AND membership_status = 'active'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_active_member(workspace_uuid uuid)
RETURNS boolean AS $$
BEGIN
  RETURN is_workspace_member(workspace_uuid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.can_edit_transaction(workspace_uuid uuid, creator_uuid uuid)
RETURNS boolean AS $$
BEGIN
  RETURN is_workspace_member(workspace_uuid) AND creator_uuid = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspace_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspace_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_workspace_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY profiles_select_own
  ON public.profiles FOR SELECT
  USING (id = auth.uid());

CREATE POLICY profiles_update_own
  ON public.profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY workspaces_select_member
  ON public.workspaces FOR SELECT
  USING (is_workspace_member(id));

CREATE POLICY workspaces_insert_own
  ON public.workspaces FOR INSERT
  WITH CHECK (auth.uid() = owner_user_id);

CREATE POLICY workspaces_update_owner
  ON public.workspaces FOR UPDATE
  USING (is_workspace_owner(id))
  WITH CHECK (is_workspace_owner(id));

CREATE POLICY workspace_members_select
  ON public.workspace_members FOR SELECT
  USING (is_workspace_member(workspace_id));

CREATE POLICY workspace_members_insert_owner
  ON public.workspace_members FOR INSERT
  WITH CHECK (is_workspace_owner(workspace_id));

CREATE POLICY workspace_members_update_owner
  ON public.workspace_members FOR UPDATE
  USING (is_workspace_owner(workspace_id))
  WITH CHECK (is_workspace_owner(workspace_id));

CREATE POLICY workspace_members_delete_owner
  ON public.workspace_members FOR DELETE
  USING (is_workspace_owner(workspace_id));

CREATE POLICY workspace_invites_select_owner
  ON public.workspace_invites FOR SELECT
  USING (is_workspace_owner(workspace_id));

CREATE POLICY workspace_invites_insert_owner
  ON public.workspace_invites FOR INSERT
  WITH CHECK (is_workspace_owner(workspace_id));

CREATE POLICY workspace_invites_update_owner
  ON public.workspace_invites FOR UPDATE
  USING (is_workspace_owner(workspace_id))
  WITH CHECK (is_workspace_owner(workspace_id));

CREATE POLICY workspace_invites_delete_owner
  ON public.workspace_invites FOR DELETE
  USING (is_workspace_owner(workspace_id));

CREATE POLICY categories_select_member
  ON public.categories FOR SELECT
  USING (is_workspace_member(workspace_id) AND deleted_at IS NULL);

CREATE POLICY categories_insert_owner
  ON public.categories FOR INSERT
  WITH CHECK (is_workspace_owner(workspace_id));

CREATE POLICY categories_update_owner
  ON public.categories FOR UPDATE
  USING (is_workspace_owner(workspace_id))
  WITH CHECK (is_workspace_owner(workspace_id));

CREATE POLICY transactions_select_member
  ON public.transactions FOR SELECT
  USING (is_workspace_member(workspace_id));

CREATE POLICY transactions_insert_member
  ON public.transactions FOR INSERT
  WITH CHECK (
    is_workspace_member(workspace_id)
    AND created_by_user_id = auth.uid()
  );

CREATE POLICY transactions_update_creator
  ON public.transactions FOR UPDATE
  USING (
    is_workspace_member(workspace_id)
    AND created_by_user_id = auth.uid()
  )
  WITH CHECK (
    is_workspace_member(workspace_id)
    AND created_by_user_id = auth.uid()
  );

CREATE POLICY transaction_attachments_select_member
  ON public.transaction_attachments FOR SELECT
  USING (is_workspace_member(workspace_id));

CREATE POLICY transaction_attachments_insert_creator
  ON public.transaction_attachments FOR INSERT
  WITH CHECK (
    is_workspace_member(workspace_id)
    AND EXISTS (
      SELECT 1 FROM public.transactions
      WHERE transactions.id = transaction_id
        AND transactions.created_by_user_id = auth.uid()
    )
  );

CREATE POLICY transaction_attachments_delete_creator
  ON public.transaction_attachments FOR DELETE
  USING (
    is_workspace_member(workspace_id)
    AND EXISTS (
      SELECT 1 FROM public.transactions
      WHERE transactions.id = transaction_id
        AND transactions.created_by_user_id = auth.uid()
    )
  );

CREATE POLICY budgets_select_member
  ON public.budgets FOR SELECT
  USING (is_workspace_member(workspace_id) AND deleted_at IS NULL);

CREATE POLICY budgets_insert_owner
  ON public.budgets FOR INSERT
  WITH CHECK (is_workspace_owner(workspace_id));

CREATE POLICY budgets_update_owner
  ON public.budgets FOR UPDATE
  USING (is_workspace_owner(workspace_id))
  WITH CHECK (is_workspace_owner(workspace_id));

CREATE POLICY activity_logs_select_member
  ON public.activity_logs FOR SELECT
  USING (is_workspace_member(workspace_id));

CREATE POLICY user_workspace_preferences_select_own
  ON public.user_workspace_preferences FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY user_workspace_preferences_insert_own
  ON public.user_workspace_preferences FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND is_workspace_member(workspace_id)
  );

CREATE POLICY user_workspace_preferences_update_own
  ON public.user_workspace_preferences FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY user_workspace_preferences_delete_own
  ON public.user_workspace_preferences FOR DELETE
  USING (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.ensure_workspace_setup_for_user(
  target_user_id uuid,
  target_email text,
  target_raw_user_meta_data jsonb DEFAULT '{}'::jsonb
)
RETURNS void AS $$
DECLARE
  new_workspace_id uuid;
BEGIN
  INSERT INTO public.profiles (id, email, display_name, created_at, updated_at)
  VALUES (
    target_user_id,
    target_email,
    COALESCE(target_raw_user_meta_data->>'display_name', split_part(target_email, '@', 1)),
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    display_name = COALESCE(public.profiles.display_name, EXCLUDED.display_name),
    updated_at = now();

  SELECT w.id
  INTO new_workspace_id
  FROM public.workspaces w
  WHERE w.owner_user_id = target_user_id
    AND w.type = 'personal'
    AND w.deleted_at IS NULL
  ORDER BY w.created_at
  LIMIT 1;

  IF new_workspace_id IS NULL THEN
    INSERT INTO public.workspaces (name, type, owner_user_id, created_at, updated_at)
    VALUES (
      'My Workspace',
      'personal',
      target_user_id,
      now(),
      now()
    )
    RETURNING id INTO new_workspace_id;
  END IF;

  INSERT INTO public.workspace_members (
    workspace_id,
    user_id,
    role,
    membership_status,
    joined_at,
    created_at,
    updated_at
  )
  VALUES (
    new_workspace_id,
    target_user_id,
    'owner',
    'active',
    now(),
    now(),
    now()
  )
  ON CONFLICT (workspace_id, user_id) DO UPDATE SET
    role = 'owner',
    membership_status = 'active',
    joined_at = COALESCE(public.workspace_members.joined_at, now()),
    removed_at = NULL,
    updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  PERFORM public.ensure_workspace_setup_for_user(NEW.id, NEW.email, NEW.raw_user_meta_data);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

GRANT EXECUTE ON FUNCTION public.ensure_workspace_setup_for_user(uuid, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ensure_workspace_setup_for_user(uuid, text, jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;

DO $$
DECLARE
  auth_user auth.users%ROWTYPE;
BEGIN
  FOR auth_user IN
    SELECT *
    FROM auth.users
  LOOP
    PERFORM public.ensure_workspace_setup_for_user(
      auth_user.id,
      auth_user.email,
      auth_user.raw_user_meta_data
    );
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_group_workspace(
  workspace_name text,
  workspace_settings jsonb DEFAULT '{}'::jsonb
)
RETURNS uuid AS $$
DECLARE
  new_workspace_id uuid;
BEGIN
  INSERT INTO public.workspaces (
    id,
    type,
    name,
    owner_user_id,
    settings,
    created_at,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    'group',
    workspace_name,
    auth.uid(),
    workspace_settings,
    now(),
    now()
  )
  RETURNING id INTO new_workspace_id;

  INSERT INTO public.workspace_members (
    id,
    workspace_id,
    user_id,
    role,
    membership_status,
    joined_at,
    created_at,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    new_workspace_id,
    auth.uid(),
    'owner',
    'active',
    now(),
    now(),
    now()
  );

  RETURN new_workspace_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.accept_workspace_invite(invite_token text)
RETURNS jsonb AS $$
DECLARE
  invite_record public.workspace_invites%ROWTYPE;
  new_member_id uuid;
BEGIN
  SELECT * INTO invite_record
  FROM public.workspace_invites
  WHERE token = invite_token
    AND status = 'pending'
    AND expires_at > now();

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid or expired invite');
  END IF;

  IF invite_record.email != (SELECT email FROM auth.users WHERE id = auth.uid()) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Email mismatch');
  END IF;

  INSERT INTO public.workspace_members (
    id,
    workspace_id,
    user_id,
    role,
    membership_status,
    joined_at,
    invited_by_user_id,
    created_at,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    invite_record.workspace_id,
    auth.uid(),
    invite_record.role,
    'active',
    now(),
    invite_record.invited_by_user_id,
    now(),
    now()
  )
  RETURNING id INTO new_member_id;

  UPDATE public.workspace_invites
  SET status = 'accepted',
      accepted_by_user_id = auth.uid(),
      updated_at = now()
  WHERE id = invite_record.id;

  RETURN jsonb_build_object(
    'success', true,
    'workspace_id', invite_record.workspace_id,
    'member_id', new_member_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.revoke_workspace_invite(invite_id uuid)
RETURNS boolean AS $$
DECLARE
  invite_workspace_id uuid;
BEGIN
  SELECT workspace_id INTO invite_workspace_id
  FROM public.workspace_invites
  WHERE id = invite_id;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  IF NOT is_workspace_owner(invite_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner can revoke invites';
  END IF;

  UPDATE public.workspace_invites
  SET status = 'revoked',
      updated_at = now()
  WHERE id = invite_id;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.archive_workspace(workspace_id uuid)
RETURNS boolean AS $$
BEGIN
  IF NOT is_workspace_owner(workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner can archive workspace';
  END IF;

  UPDATE public.workspaces
  SET status = 'archived',
      updated_at = now()
  WHERE id = workspace_id;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.assert_transaction_category_valid(
  p_workspace_id uuid,
  p_category_id uuid,
  p_transaction_type text
)
RETURNS void AS $$
DECLARE
  v_category public.categories%ROWTYPE;
BEGIN
  SELECT *
  INTO v_category
  FROM public.categories
  WHERE id = p_category_id
    AND workspace_id = p_workspace_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'INVALID_CATEGORY',
      DETAIL = 'Category must exist in the active workspace';
  END IF;

  IF v_category.type != p_transaction_type THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'CATEGORY_TYPE_MISMATCH',
      DETAIL = format(
        'Category type %s does not match transaction type %s',
        v_category.type,
        p_transaction_type
      );
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.assert_transaction_budget_allowed(
  p_transaction_id uuid,
  p_workspace_id uuid,
  p_category_id uuid,
  p_transaction_at timestamptz,
  p_amount_minor bigint,
  p_transaction_type text,
  p_budget_override boolean DEFAULT false
)
RETURNS void AS $$
DECLARE
  v_budget public.budgets%ROWTYPE;
  v_consumed bigint := 0;
  v_remaining bigint := 0;
BEGIN
  IF p_transaction_type != 'expense' THEN
    RETURN;
  END IF;

  SELECT *
  INTO v_budget
  FROM public.budgets
  WHERE workspace_id = p_workspace_id
    AND category_id = p_category_id
    AND deleted_at IS NULL
    AND period_start <= p_transaction_at
    AND period_end >= p_transaction_at
  ORDER BY period_start
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  SELECT COALESCE(SUM(amount_minor), 0)
  INTO v_consumed
  FROM public.transactions
  WHERE workspace_id = p_workspace_id
    AND category_id = p_category_id
    AND transaction_type = 'expense'
    AND deleted_at IS NULL
    AND transaction_at >= v_budget.period_start
    AND transaction_at <= v_budget.period_end
    AND (p_transaction_id IS NULL OR id != p_transaction_id);

  IF v_consumed + p_amount_minor > v_budget.limit_minor
     AND NOT p_budget_override
     AND NOT v_budget.allow_overdraft THEN
    v_remaining := v_budget.limit_minor - v_consumed;
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'BUDGET_EXCEEDED',
      DETAIL = json_build_object(
        'remaining_cents', v_remaining,
        'limit_cents', v_budget.limit_minor
      )::text;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.transactions_business_rules_trigger()
RETURNS trigger AS $$
DECLARE
  v_budget_override boolean := false;
BEGIN
  IF NEW.deleted_at IS NOT NULL THEN
    RETURN NEW;
  END IF;

  v_budget_override := COALESCE((NEW.metadata ->> 'budget_override')::boolean, false);

  PERFORM public.assert_transaction_category_valid(
    NEW.workspace_id,
    NEW.category_id,
    NEW.transaction_type
  );

  PERFORM public.assert_transaction_budget_allowed(
    NEW.id,
    NEW.workspace_id,
    NEW.category_id,
    NEW.transaction_at,
    NEW.amount_minor,
    NEW.transaction_type,
    v_budget_override
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER transactions_business_rules
  BEFORE INSERT OR UPDATE OF workspace_id, category_id, amount_minor, transaction_type, transaction_at, deleted_at, metadata
  ON public.transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.transactions_business_rules_trigger();

CREATE OR REPLACE FUNCTION public.assert_budget_period_not_overlapping(
  p_budget_id uuid,
  p_workspace_id uuid,
  p_category_id uuid,
  p_period_start timestamptz,
  p_period_end timestamptz
)
RETURNS void AS $$
BEGIN
  IF p_period_end < p_period_start THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'INVALID_BUDGET_PERIOD',
      DETAIL = 'Budget period_end must be greater than or equal to period_start';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.budgets
    WHERE workspace_id = p_workspace_id
      AND category_id = p_category_id
      AND deleted_at IS NULL
      AND (p_budget_id IS NULL OR id != p_budget_id)
      AND NOT (p_period_end < period_start OR p_period_start > period_end)
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'BUDGET_OVERLAP',
      DETAIL = 'Budget period overlaps with an existing active budget';
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.budgets_business_rules_trigger()
RETURNS trigger AS $$
BEGIN
  IF NEW.deleted_at IS NOT NULL THEN
    RETURN NEW;
  END IF;

  PERFORM public.assert_transaction_category_valid(
    NEW.workspace_id,
    NEW.category_id,
    'expense'
  );

  PERFORM public.assert_budget_period_not_overlapping(
    NEW.id,
    NEW.workspace_id,
    NEW.category_id,
    NEW.period_start,
    NEW.period_end
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER budgets_business_rules
  BEFORE INSERT OR UPDATE OF workspace_id, category_id, period_start, period_end, deleted_at
  ON public.budgets
  FOR EACH ROW
  EXECUTE FUNCTION public.budgets_business_rules_trigger();

CREATE OR REPLACE FUNCTION public.categories_soft_delete_guard_trigger()
RETURNS trigger AS $$
BEGIN
  IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
    IF EXISTS (
      SELECT 1
      FROM public.transactions
      WHERE workspace_id = NEW.workspace_id
        AND category_id = NEW.id
        AND deleted_at IS NULL
    ) OR EXISTS (
      SELECT 1
      FROM public.budgets
      WHERE workspace_id = NEW.workspace_id
        AND category_id = NEW.id
        AND deleted_at IS NULL
    ) THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P0001',
        MESSAGE = 'CATEGORY_IN_USE',
        DETAIL = 'Category is referenced by active transactions or budgets';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER categories_soft_delete_guard
  BEFORE UPDATE OF deleted_at
  ON public.categories
  FOR EACH ROW
  EXECUTE FUNCTION public.categories_soft_delete_guard_trigger();

CREATE OR REPLACE FUNCTION public.create_transaction_rpc(
  p_workspace_id uuid,
  p_category_id uuid,
  p_amount_minor bigint,
  p_currency_code text,
  p_transaction_type text,
  p_transaction_at timestamptz,
  p_note text DEFAULT NULL,
  p_client_reference_id text DEFAULT NULL,
  p_allow_overdraft_override boolean DEFAULT false,
  p_id uuid DEFAULT NULL,
  p_created_at timestamptz DEFAULT now(),
  p_updated_at timestamptz DEFAULT now()
)
RETURNS public.transactions AS $$
DECLARE
  v_transaction public.transactions;
BEGIN
  INSERT INTO public.transactions (
    id,
    workspace_id,
    category_id,
    amount_minor,
    currency_code,
    transaction_type,
    transaction_at,
    note,
    client_reference_id,
    created_by_user_id,
    updated_by_user_id,
    created_at,
    updated_at,
    metadata
  )
  VALUES (
    COALESCE(p_id, gen_random_uuid()),
    p_workspace_id,
    p_category_id,
    p_amount_minor,
    p_currency_code,
    p_transaction_type,
    p_transaction_at,
    p_note,
    p_client_reference_id,
    auth.uid(),
    auth.uid(),
    p_created_at,
    p_updated_at,
    jsonb_build_object('budget_override', p_allow_overdraft_override)
  )
  RETURNING * INTO v_transaction;

  RETURN v_transaction;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.update_transaction_rpc(
  p_transaction_id uuid,
  p_workspace_id uuid,
  p_category_id uuid,
  p_amount_minor bigint,
  p_currency_code text,
  p_transaction_type text,
  p_transaction_at timestamptz,
  p_note text DEFAULT NULL,
  p_allow_overdraft_override boolean DEFAULT false,
  p_updated_at timestamptz DEFAULT now()
)
RETURNS public.transactions AS $$
DECLARE
  v_transaction public.transactions;
BEGIN
  UPDATE public.transactions
  SET category_id = p_category_id,
      amount_minor = p_amount_minor,
      currency_code = p_currency_code,
      transaction_type = p_transaction_type,
      transaction_at = p_transaction_at,
      note = p_note,
      updated_by_user_id = auth.uid(),
      updated_at = p_updated_at,
      metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object('budget_override', p_allow_overdraft_override)
  WHERE id = p_transaction_id
    AND workspace_id = p_workspace_id
    AND deleted_at IS NULL
  RETURNING * INTO v_transaction;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'TRANSACTION_NOT_FOUND',
      DETAIL = 'Active transaction could not be found for update';
  END IF;

  RETURN v_transaction;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.soft_delete_transaction_rpc(
  p_transaction_id uuid,
  p_workspace_id uuid
)
RETURNS void AS $$
BEGIN
  UPDATE public.transactions
  SET deleted_at = now(),
      deleted_by_user_id = auth.uid(),
      updated_by_user_id = auth.uid()
  WHERE id = p_transaction_id
    AND workspace_id = p_workspace_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'TRANSACTION_NOT_FOUND',
      DETAIL = 'Active transaction could not be found for deletion';
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.create_budget_rpc(
  p_workspace_id uuid,
  p_category_id uuid,
  p_period_type text,
  p_period_start timestamptz,
  p_period_end timestamptz,
  p_limit_minor bigint,
  p_currency_code text,
  p_allow_overdraft boolean,
  p_id uuid DEFAULT NULL,
  p_created_at timestamptz DEFAULT now(),
  p_updated_at timestamptz DEFAULT now()
)
RETURNS public.budgets AS $$
DECLARE
  v_budget public.budgets;
BEGIN
  INSERT INTO public.budgets (
    id,
    workspace_id,
    category_id,
    period_type,
    period_start,
    period_end,
    limit_minor,
    currency_code,
    allow_overdraft,
    created_by_user_id,
    updated_by_user_id,
    created_at,
    updated_at
  )
  VALUES (
    COALESCE(p_id, gen_random_uuid()),
    p_workspace_id,
    p_category_id,
    p_period_type,
    p_period_start,
    p_period_end,
    p_limit_minor,
    p_currency_code,
    p_allow_overdraft,
    auth.uid(),
    auth.uid(),
    p_created_at,
    p_updated_at
  )
  RETURNING * INTO v_budget;

  RETURN v_budget;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.update_budget_rpc(
  p_budget_id uuid,
  p_workspace_id uuid,
  p_category_id uuid,
  p_period_type text,
  p_period_start timestamptz,
  p_period_end timestamptz,
  p_limit_minor bigint,
  p_currency_code text,
  p_allow_overdraft boolean,
  p_updated_at timestamptz DEFAULT now()
)
RETURNS public.budgets AS $$
DECLARE
  v_budget public.budgets;
BEGIN
  UPDATE public.budgets
  SET category_id = p_category_id,
      period_type = p_period_type,
      period_start = p_period_start,
      period_end = p_period_end,
      limit_minor = p_limit_minor,
      currency_code = p_currency_code,
      allow_overdraft = p_allow_overdraft,
      updated_by_user_id = auth.uid(),
      updated_at = p_updated_at
  WHERE id = p_budget_id
    AND workspace_id = p_workspace_id
    AND deleted_at IS NULL
  RETURNING * INTO v_budget;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'BUDGET_NOT_FOUND',
      DETAIL = 'Active budget could not be found for update';
  END IF;

  RETURN v_budget;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.soft_delete_budget_rpc(
  p_budget_id uuid,
  p_workspace_id uuid
)
RETURNS void AS $$
BEGIN
  UPDATE public.budgets
  SET deleted_at = now(),
      deleted_by_user_id = auth.uid(),
      updated_by_user_id = auth.uid()
  WHERE id = p_budget_id
    AND workspace_id = p_workspace_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'BUDGET_NOT_FOUND',
      DETAIL = 'Active budget could not be found for deletion';
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.create_category_rpc(
  p_workspace_id uuid,
  p_name text,
  p_type text,
  p_icon_name text,
  p_color_value text,
  p_id uuid DEFAULT NULL,
  p_created_at timestamptz DEFAULT now(),
  p_updated_at timestamptz DEFAULT now()
)
RETURNS public.categories AS $$
DECLARE
  v_category public.categories;
BEGIN
  INSERT INTO public.categories (
    id,
    workspace_id,
    name,
    normalized_name,
    type,
    icon_name,
    color_value,
    created_by_user_id,
    updated_by_user_id,
    created_at,
    updated_at
  )
  VALUES (
    COALESCE(p_id, gen_random_uuid()),
    p_workspace_id,
    trim(p_name),
    normalize_name(trim(p_name)),
    p_type,
    p_icon_name,
    upper(trim(p_color_value)),
    auth.uid(),
    auth.uid(),
    p_created_at,
    p_updated_at
  )
  RETURNING * INTO v_category;

  RETURN v_category;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.update_category_rpc(
  p_category_id uuid,
  p_workspace_id uuid,
  p_name text,
  p_type text,
  p_icon_name text,
  p_color_value text,
  p_updated_at timestamptz DEFAULT now()
)
RETURNS public.categories AS $$
DECLARE
  v_category public.categories;
BEGIN
  UPDATE public.categories
  SET name = trim(p_name),
      normalized_name = normalize_name(trim(p_name)),
      type = p_type,
      icon_name = p_icon_name,
      color_value = upper(trim(p_color_value)),
      updated_by_user_id = auth.uid(),
      updated_at = p_updated_at
  WHERE id = p_category_id
    AND workspace_id = p_workspace_id
    AND deleted_at IS NULL
  RETURNING * INTO v_category;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'CATEGORY_NOT_FOUND',
      DETAIL = 'Active category could not be found for update';
  END IF;

  RETURN v_category;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.soft_delete_category_rpc(
  p_category_id uuid,
  p_workspace_id uuid
)
RETURNS void AS $$
BEGIN
  UPDATE public.categories
  SET deleted_at = now(),
      deleted_by_user_id = auth.uid(),
      updated_by_user_id = auth.uid()
  WHERE id = p_category_id
    AND workspace_id = p_workspace_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'CATEGORY_NOT_FOUND',
      DETAIL = 'Active category could not be found for deletion';
  END IF;
END;
$$ LANGUAGE plpgsql;

INSERT INTO storage.buckets (id, name, public)
VALUES ('transaction-receipts', 'transaction-receipts', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY transaction_receipts_select_member
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'transaction-receipts'
    AND split_part(name, '/', 1) = 'workspaces'
    AND is_workspace_member(split_part(name, '/', 2)::uuid)
  );

CREATE POLICY transaction_receipts_insert_creator
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'transaction-receipts'
    AND split_part(name, '/', 1) = 'workspaces'
    AND split_part(name, '/', 3) = 'transactions'
    AND EXISTS (
      SELECT 1
      FROM public.transactions
      WHERE transactions.id = split_part(name, '/', 4)::uuid
        AND transactions.workspace_id = split_part(name, '/', 2)::uuid
        AND transactions.created_by_user_id = auth.uid()
    )
  );

CREATE POLICY transaction_receipts_delete_creator
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'transaction-receipts'
    AND split_part(name, '/', 1) = 'workspaces'
    AND split_part(name, '/', 3) = 'transactions'
    AND EXISTS (
      SELECT 1
      FROM public.transactions
      WHERE transactions.id = split_part(name, '/', 4)::uuid
        AND transactions.workspace_id = split_part(name, '/', 2)::uuid
        AND transactions.created_by_user_id = auth.uid()
    )
  );

COMMIT;
