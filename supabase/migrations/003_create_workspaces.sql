-- Migration 003: Create workspaces table
-- Workspace is the main data boundary (personal or group)

CREATE TABLE workspaces (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL,
  name text NOT NULL,
  slug text,
  owner_user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
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

-- Indexes
CREATE INDEX workspaces_owner_user_id_idx ON workspaces(owner_user_id);
CREATE INDEX workspaces_type_status_idx ON workspaces(type, status);

-- Trigger for updated_at
CREATE TRIGGER workspaces_updated_at
  BEFORE UPDATE ON workspaces
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Comments
COMMENT ON TABLE workspaces IS 'Main data boundary - personal or group workspace';
COMMENT ON COLUMN workspaces.type IS 'personal or group';
COMMENT ON COLUMN workspaces.status IS 'active, archived, or deleted';
COMMENT ON COLUMN workspaces.month_start_day IS 'Day of month when budget cycle starts (1-31)';
