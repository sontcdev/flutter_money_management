CREATE TABLE IF NOT EXISTS public.recurring_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  title text NOT NULL,
  category_id uuid NOT NULL REFERENCES public.categories(id),
  amount_minor bigint NOT NULL CHECK (amount_minor > 0),
  currency_code text NOT NULL DEFAULT 'VND',
  transaction_type text NOT NULL CHECK (transaction_type IN ('income', 'expense')),
  frequency text NOT NULL CHECK (frequency IN ('weekly', 'monthly', 'yearly')),
  mode text NOT NULL CHECK (mode IN ('reminderOnly', 'manualConfirm')),
  interval_count integer NOT NULL DEFAULT 1 CHECK (interval_count > 0),
  note text,
  day_of_month integer CHECK (day_of_month BETWEEN 1 AND 31),
  day_of_week integer CHECK (day_of_week BETWEEN 1 AND 7),
  month_of_year integer CHECK (month_of_year BETWEEN 1 AND 12),
  start_date timestamptz NOT NULL,
  end_date timestamptz,
  next_occurrence_at timestamptz NOT NULL,
  reminder_days_before integer NOT NULL DEFAULT 0 CHECK (reminder_days_before >= 0),
  is_active boolean NOT NULL DEFAULT true,
  created_by_user_id uuid NOT NULL REFERENCES public.profiles(id),
  updated_by_user_id uuid NOT NULL REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  deleted_by_user_id uuid REFERENCES public.profiles(id),
  CONSTRAINT recurring_transactions_period_check CHECK (
    end_date IS NULL OR end_date >= start_date
  )
);

CREATE INDEX IF NOT EXISTS idx_recurring_transactions_workspace_active
  ON public.recurring_transactions (workspace_id, is_active, next_occurrence_at)
  WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS public.recurring_transaction_occurrences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recurring_transaction_id uuid NOT NULL REFERENCES public.recurring_transactions(id) ON DELETE CASCADE,
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  scheduled_for timestamptz NOT NULL,
  remind_at timestamptz NOT NULL,
  status text NOT NULL CHECK (status IN ('pending', 'completed', 'skipped', 'dismissed')),
  generated_transaction_id uuid REFERENCES public.transactions(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (recurring_transaction_id, scheduled_for)
);

CREATE INDEX IF NOT EXISTS idx_recurring_occurrences_workspace_schedule
  ON public.recurring_transaction_occurrences (workspace_id, status, scheduled_for);

DROP TRIGGER IF EXISTS recurring_transactions_updated_at ON public.recurring_transactions;
CREATE TRIGGER recurring_transactions_updated_at
  BEFORE UPDATE ON public.recurring_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS recurring_occurrences_updated_at ON public.recurring_transaction_occurrences;
CREATE TRIGGER recurring_occurrences_updated_at
  BEFORE UPDATE ON public.recurring_transaction_occurrences
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.recurring_safe_date(
  p_year integer,
  p_month integer,
  p_day integer
)
RETURNS date AS $$
DECLARE
  max_day integer;
BEGIN
  max_day := EXTRACT(day FROM (make_date(p_year, p_month, 1) + interval '1 month - 1 day'))::integer;
  RETURN make_date(p_year, p_month, LEAST(GREATEST(p_day, 1), max_day));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.next_recurring_occurrence_at(
  p_current_occurrence_at timestamptz,
  p_frequency text,
  p_interval_count integer,
  p_day_of_month integer,
  p_day_of_week integer,
  p_month_of_year integer
)
RETURNS timestamptz AS $$
DECLARE
  safe_interval integer := GREATEST(p_interval_count, 1);
  current_date date := p_current_occurrence_at::date;
  current_time time := p_current_occurrence_at::time;
  base_date date;
  next_date date;
BEGIN
  CASE p_frequency
    WHEN 'weekly' THEN
      next_date := current_date + (safe_interval * 7);
    WHEN 'monthly' THEN
      base_date := (current_date + make_interval(months => safe_interval))::date;
      next_date := public.recurring_safe_date(
        EXTRACT(year FROM base_date)::integer,
        EXTRACT(month FROM base_date)::integer,
        COALESCE(p_day_of_month, EXTRACT(day FROM current_date)::integer)
      );
    WHEN 'yearly' THEN
      base_date := (current_date + make_interval(years => safe_interval))::date;
      next_date := public.recurring_safe_date(
        EXTRACT(year FROM base_date)::integer,
        COALESCE(p_month_of_year, EXTRACT(month FROM current_date)::integer),
        COALESCE(p_day_of_month, EXTRACT(day FROM current_date)::integer)
      );
    ELSE
      RAISE EXCEPTION 'Unsupported recurring frequency: %', p_frequency;
  END CASE;

  RETURN next_date::timestamp + current_time;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

ALTER TABLE public.recurring_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recurring_transaction_occurrences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS recurring_transactions_select_member ON public.recurring_transactions;
CREATE POLICY recurring_transactions_select_member
  ON public.recurring_transactions FOR SELECT
  USING (is_workspace_member(workspace_id) AND deleted_at IS NULL);

DROP POLICY IF EXISTS recurring_transactions_insert_member ON public.recurring_transactions;
CREATE POLICY recurring_transactions_insert_member
  ON public.recurring_transactions FOR INSERT
  WITH CHECK (
    is_workspace_member(workspace_id)
    AND created_by_user_id = auth.uid()
  );

DROP POLICY IF EXISTS recurring_transactions_update_creator ON public.recurring_transactions;
CREATE POLICY recurring_transactions_update_creator
  ON public.recurring_transactions FOR UPDATE
  USING (
    is_workspace_member(workspace_id)
    AND created_by_user_id = auth.uid()
  )
  WITH CHECK (
    is_workspace_member(workspace_id)
    AND created_by_user_id = auth.uid()
  );

DROP POLICY IF EXISTS recurring_occurrences_select_member ON public.recurring_transaction_occurrences;
CREATE POLICY recurring_occurrences_select_member
  ON public.recurring_transaction_occurrences FOR SELECT
  USING (is_workspace_member(workspace_id));

DROP POLICY IF EXISTS recurring_occurrences_insert_member ON public.recurring_transaction_occurrences;
CREATE POLICY recurring_occurrences_insert_member
  ON public.recurring_transaction_occurrences FOR INSERT
  WITH CHECK (is_workspace_member(workspace_id));

DROP POLICY IF EXISTS recurring_occurrences_update_member ON public.recurring_transaction_occurrences;
CREATE POLICY recurring_occurrences_update_member
  ON public.recurring_transaction_occurrences FOR UPDATE
  USING (is_workspace_member(workspace_id))
  WITH CHECK (is_workspace_member(workspace_id));

DROP FUNCTION IF EXISTS public.create_recurring_transaction_rpc(
  uuid, uuid, text, uuid, bigint, text, text, text, text, integer, timestamptz,
  timestamptz, integer, boolean, uuid, uuid, timestamptz, timestamptz, text,
  integer, integer, integer, timestamptz
);

CREATE OR REPLACE FUNCTION public.create_recurring_transaction_rpc(
  id uuid,
  workspace_id uuid,
  title text,
  category_id uuid,
  amount_minor bigint,
  currency_code text,
  transaction_type text,
  frequency text,
  mode text,
  interval_count integer,
  start_date timestamptz,
  next_occurrence_at timestamptz,
  reminder_days_before integer,
  is_active boolean,
  created_by_user_id uuid,
  updated_by_user_id uuid,
  created_at timestamptz,
  updated_at timestamptz,
  note text DEFAULT NULL,
  day_of_month integer DEFAULT NULL,
  day_of_week integer DEFAULT NULL,
  month_of_year integer DEFAULT NULL,
  end_date timestamptz DEFAULT NULL
)
RETURNS public.recurring_transactions AS $$
DECLARE
  inserted public.recurring_transactions;
BEGIN
  INSERT INTO public.recurring_transactions (
    id,
    workspace_id,
    title,
    category_id,
    amount_minor,
    currency_code,
    transaction_type,
    frequency,
    mode,
    interval_count,
    note,
    day_of_month,
    day_of_week,
    month_of_year,
    start_date,
    end_date,
    next_occurrence_at,
    reminder_days_before,
    is_active,
    created_by_user_id,
    updated_by_user_id,
    created_at,
    updated_at
  )
  VALUES (
    COALESCE(id, gen_random_uuid()),
    workspace_id,
    trim(title),
    category_id,
    amount_minor,
    currency_code,
    transaction_type,
    frequency,
    mode,
    interval_count,
    note,
    day_of_month,
    day_of_week,
    month_of_year,
    start_date,
    end_date,
    next_occurrence_at,
    reminder_days_before,
    is_active,
    auth.uid(),
    auth.uid(),
    created_at,
    updated_at
  )
  RETURNING * INTO inserted;

  RETURN inserted;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP FUNCTION IF EXISTS public.update_recurring_transaction_rpc(
  uuid, uuid, text, uuid, bigint, text, text, text, text, integer, timestamptz,
  timestamptz, integer, boolean, uuid, uuid, timestamptz, timestamptz, text,
  integer, integer, integer, timestamptz
);

CREATE OR REPLACE FUNCTION public.update_recurring_transaction_rpc(
  id uuid,
  workspace_id uuid,
  title text,
  category_id uuid,
  amount_minor bigint,
  currency_code text,
  transaction_type text,
  frequency text,
  mode text,
  interval_count integer,
  start_date timestamptz,
  next_occurrence_at timestamptz,
  reminder_days_before integer,
  is_active boolean,
  created_by_user_id uuid,
  updated_by_user_id uuid,
  created_at timestamptz,
  updated_at timestamptz,
  note text DEFAULT NULL,
  day_of_month integer DEFAULT NULL,
  day_of_week integer DEFAULT NULL,
  month_of_year integer DEFAULT NULL,
  end_date timestamptz DEFAULT NULL
)
RETURNS public.recurring_transactions AS $$
DECLARE
  updated_row public.recurring_transactions;
BEGIN
  DELETE FROM public.recurring_transaction_occurrences
  WHERE recurring_transaction_id = id
    AND status = 'pending';

  UPDATE public.recurring_transactions
  SET
    title = trim(update_recurring_transaction_rpc.title),
    category_id = update_recurring_transaction_rpc.category_id,
    amount_minor = update_recurring_transaction_rpc.amount_minor,
    currency_code = update_recurring_transaction_rpc.currency_code,
    transaction_type = update_recurring_transaction_rpc.transaction_type,
    frequency = update_recurring_transaction_rpc.frequency,
    mode = update_recurring_transaction_rpc.mode,
    interval_count = update_recurring_transaction_rpc.interval_count,
    note = update_recurring_transaction_rpc.note,
    day_of_month = update_recurring_transaction_rpc.day_of_month,
    day_of_week = update_recurring_transaction_rpc.day_of_week,
    month_of_year = update_recurring_transaction_rpc.month_of_year,
    start_date = update_recurring_transaction_rpc.start_date,
    end_date = update_recurring_transaction_rpc.end_date,
    next_occurrence_at = update_recurring_transaction_rpc.next_occurrence_at,
    reminder_days_before = update_recurring_transaction_rpc.reminder_days_before,
    is_active = update_recurring_transaction_rpc.is_active,
    updated_by_user_id = auth.uid(),
    updated_at = update_recurring_transaction_rpc.updated_at
  WHERE recurring_transactions.id = update_recurring_transaction_rpc.id
    AND recurring_transactions.workspace_id = update_recurring_transaction_rpc.workspace_id
    AND recurring_transactions.deleted_at IS NULL
  RETURNING * INTO updated_row;

  RETURN updated_row;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP FUNCTION IF EXISTS public.soft_delete_recurring_transaction_rpc(uuid, uuid);
CREATE OR REPLACE FUNCTION public.soft_delete_recurring_transaction_rpc(
  p_recurring_transaction_id uuid,
  p_workspace_id uuid
)
RETURNS void AS $$
BEGIN
  DELETE FROM public.recurring_transaction_occurrences
  WHERE recurring_transaction_id = p_recurring_transaction_id
    AND status = 'pending';

  UPDATE public.recurring_transactions
  SET
    deleted_at = now(),
    deleted_by_user_id = auth.uid(),
    updated_by_user_id = auth.uid(),
    updated_at = now(),
    is_active = false
  WHERE id = p_recurring_transaction_id
    AND workspace_id = p_workspace_id
    AND deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP FUNCTION IF EXISTS public.generate_recurring_occurrences_rpc(uuid, timestamptz);
CREATE OR REPLACE FUNCTION public.generate_recurring_occurrences_rpc(
  p_workspace_id uuid,
  p_through_date timestamptz
)
RETURNS void AS $$
DECLARE
  item public.recurring_transactions%ROWTYPE;
BEGIN
  FOR item IN
    SELECT *
    FROM public.recurring_transactions
    WHERE workspace_id = p_workspace_id
      AND deleted_at IS NULL
      AND is_active = true
      AND next_occurrence_at <= p_through_date
      AND (end_date IS NULL OR next_occurrence_at <= end_date)
  LOOP
    INSERT INTO public.recurring_transaction_occurrences (
      recurring_transaction_id,
      workspace_id,
      scheduled_for,
      remind_at,
      status
    )
    VALUES (
      item.id,
      item.workspace_id,
      item.next_occurrence_at,
      item.next_occurrence_at - make_interval(days => item.reminder_days_before),
      'pending'
    )
    ON CONFLICT (recurring_transaction_id, scheduled_for) DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP FUNCTION IF EXISTS public.skip_recurring_occurrence_rpc(uuid, uuid);
CREATE OR REPLACE FUNCTION public.skip_recurring_occurrence_rpc(
  p_occurrence_id uuid,
  p_workspace_id uuid
)
RETURNS void AS $$
DECLARE
  occurrence_row public.recurring_transaction_occurrences%ROWTYPE;
  recurring_row public.recurring_transactions%ROWTYPE;
BEGIN
  SELECT * INTO occurrence_row
  FROM public.recurring_transaction_occurrences
  WHERE id = p_occurrence_id
    AND workspace_id = p_workspace_id;

  IF occurrence_row.id IS NULL THEN
    RAISE EXCEPTION 'Recurring occurrence not found';
  END IF;

  SELECT * INTO recurring_row
  FROM public.recurring_transactions
  WHERE id = occurrence_row.recurring_transaction_id
    AND workspace_id = p_workspace_id
    AND deleted_at IS NULL;

  UPDATE public.recurring_transaction_occurrences
  SET status = 'skipped', updated_at = now()
  WHERE id = p_occurrence_id;

  UPDATE public.recurring_transactions
  SET
    next_occurrence_at = public.next_recurring_occurrence_at(
      recurring_row.next_occurrence_at,
      recurring_row.frequency,
      recurring_row.interval_count,
      recurring_row.day_of_month,
      recurring_row.day_of_week,
      recurring_row.month_of_year
    ),
    updated_by_user_id = auth.uid(),
    updated_at = now()
  WHERE id = recurring_row.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP FUNCTION IF EXISTS public.complete_recurring_occurrence_rpc(uuid, uuid, uuid);
CREATE OR REPLACE FUNCTION public.complete_recurring_occurrence_rpc(
  p_occurrence_id uuid,
  p_workspace_id uuid,
  p_generated_transaction_id uuid
)
RETURNS void AS $$
DECLARE
  occurrence_row public.recurring_transaction_occurrences%ROWTYPE;
  recurring_row public.recurring_transactions%ROWTYPE;
BEGIN
  SELECT * INTO occurrence_row
  FROM public.recurring_transaction_occurrences
  WHERE id = p_occurrence_id
    AND workspace_id = p_workspace_id;

  IF occurrence_row.id IS NULL THEN
    RAISE EXCEPTION 'Recurring occurrence not found';
  END IF;

  SELECT * INTO recurring_row
  FROM public.recurring_transactions
  WHERE id = occurrence_row.recurring_transaction_id
    AND workspace_id = p_workspace_id
    AND deleted_at IS NULL;

  UPDATE public.recurring_transaction_occurrences
  SET
    status = 'completed',
    generated_transaction_id = p_generated_transaction_id,
    updated_at = now()
  WHERE id = p_occurrence_id;

  UPDATE public.recurring_transactions
  SET
    next_occurrence_at = public.next_recurring_occurrence_at(
      recurring_row.next_occurrence_at,
      recurring_row.frequency,
      recurring_row.interval_count,
      recurring_row.day_of_month,
      recurring_row.day_of_week,
      recurring_row.month_of_year
    ),
    updated_by_user_id = auth.uid(),
    updated_at = now()
  WHERE id = recurring_row.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.recurring_safe_date(integer, integer, integer)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.next_recurring_occurrence_at(timestamptz, text, integer, integer, integer, integer)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.create_recurring_transaction_rpc(uuid, uuid, text, uuid, bigint, text, text, text, text, integer, timestamptz, timestamptz, integer, boolean, uuid, uuid, timestamptz, timestamptz, text, integer, integer, integer, timestamptz)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.update_recurring_transaction_rpc(uuid, uuid, text, uuid, bigint, text, text, text, text, integer, timestamptz, timestamptz, integer, boolean, uuid, uuid, timestamptz, timestamptz, text, integer, integer, integer, timestamptz)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.soft_delete_recurring_transaction_rpc(uuid, uuid)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.generate_recurring_occurrences_rpc(uuid, timestamptz)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.skip_recurring_occurrence_rpc(uuid, uuid)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.complete_recurring_occurrence_rpc(uuid, uuid, uuid)
  TO authenticated, service_role;
