-- Migration 009: Create budgets table
-- Budget limits per category and time period

CREATE TABLE budgets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES categories(id),
  name text,
  period_type text NOT NULL,
  period_start timestamptz NOT NULL,
  period_end timestamptz NOT NULL,
  limit_minor bigint NOT NULL,
  currency_code text NOT NULL,
  allow_overdraft boolean NOT NULL DEFAULT false,
  is_archived boolean NOT NULL DEFAULT false,
  created_by_user_id uuid NOT NULL REFERENCES profiles(id),
  updated_by_user_id uuid NOT NULL REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  deleted_by_user_id uuid REFERENCES profiles(id),
  version integer NOT NULL DEFAULT 1,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  
  CONSTRAINT budgets_period_type_check CHECK (period_type IN ('monthly', 'yearly', 'custom')),
  CONSTRAINT budgets_period_check CHECK (period_end >= period_start),
  CONSTRAINT budgets_limit_check CHECK (limit_minor > 0),
  CONSTRAINT budgets_version_check CHECK (version > 0)
);

-- Indexes
CREATE INDEX budgets_workspace_id_idx ON budgets(workspace_id);
CREATE INDEX budgets_workspace_category_idx ON budgets(workspace_id, category_id);
CREATE INDEX budgets_workspace_period_idx ON budgets(workspace_id, period_start, period_end);

-- Trigger for updated_at
CREATE TRIGGER budgets_updated_at
  BEFORE UPDATE ON budgets
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Comments
COMMENT ON TABLE budgets IS 'Budget limits per category and time period';
COMMENT ON COLUMN budgets.limit_minor IS 'Budget limit in minor units (cents)';
COMMENT ON COLUMN budgets.period_type IS 'monthly, yearly, or custom';
