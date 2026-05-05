-- Migration 007: Create transactions table
-- Financial transactions (income/expense)

CREATE TABLE transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES categories(id),
  amount_minor bigint NOT NULL,
  currency_code text NOT NULL,
  transaction_type text NOT NULL,
  transaction_at timestamptz NOT NULL,
  note text,
  source text NOT NULL DEFAULT 'manual',
  client_reference_id text,
  created_by_user_id uuid NOT NULL REFERENCES profiles(id),
  updated_by_user_id uuid NOT NULL REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  deleted_by_user_id uuid REFERENCES profiles(id),
  version integer NOT NULL DEFAULT 1,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  
  CONSTRAINT transactions_type_check CHECK (transaction_type IN ('expense', 'income')),
  CONSTRAINT transactions_source_check CHECK (source IN ('manual', 'import', 'system')),
  CONSTRAINT transactions_amount_check CHECK (amount_minor > 0),
  CONSTRAINT transactions_version_check CHECK (version > 0)
);

-- Indexes
CREATE INDEX transactions_workspace_id_idx ON transactions(workspace_id);
CREATE INDEX transactions_workspace_date_idx ON transactions(workspace_id, transaction_at DESC);
CREATE INDEX transactions_workspace_category_date_idx ON transactions(workspace_id, category_id, transaction_at DESC);
CREATE INDEX transactions_workspace_creator_date_idx ON transactions(workspace_id, created_by_user_id, transaction_at DESC);

-- Partial index for active transactions
CREATE INDEX transactions_workspace_type_date_idx 
  ON transactions(workspace_id, transaction_type, transaction_at DESC) 
  WHERE deleted_at IS NULL;

-- Trigger for updated_at
CREATE TRIGGER transactions_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Comments
COMMENT ON TABLE transactions IS 'Financial transactions (income/expense)';
COMMENT ON COLUMN transactions.amount_minor IS 'Amount in minor units (cents)';
COMMENT ON COLUMN transactions.transaction_at IS 'Business datetime of transaction';
COMMENT ON COLUMN transactions.source IS 'manual, import, or system';
COMMENT ON COLUMN transactions.client_reference_id IS 'Offline ID hint for sync';
