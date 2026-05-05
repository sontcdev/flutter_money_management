-- Migration 006: Create categories table
-- Categories for income/expense classification per workspace

CREATE TABLE categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  normalized_name text NOT NULL,
  type text NOT NULL,
  icon_name text NOT NULL,
  color_value integer NOT NULL,
  is_system boolean NOT NULL DEFAULT false,
  is_archived boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0,
  created_by_user_id uuid NOT NULL REFERENCES profiles(id),
  updated_by_user_id uuid NOT NULL REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  deleted_by_user_id uuid REFERENCES profiles(id),
  version integer NOT NULL DEFAULT 1,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  
  CONSTRAINT categories_type_check CHECK (type IN ('expense', 'income')),
  CONSTRAINT categories_version_check CHECK (version > 0)
);

-- Partial unique index for active categories (deleted_at is null)
CREATE UNIQUE INDEX categories_workspace_name_type_unique_idx 
  ON categories(workspace_id, normalized_name, type) 
  WHERE deleted_at IS NULL;

-- Indexes
CREATE INDEX categories_workspace_id_idx ON categories(workspace_id);
CREATE INDEX categories_workspace_type_idx ON categories(workspace_id, type);

-- Trigger for updated_at
CREATE TRIGGER categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Trigger to auto-update normalized_name
CREATE OR REPLACE FUNCTION categories_normalize_name()
RETURNS TRIGGER AS $$
BEGIN
  NEW.normalized_name = normalize_name(NEW.name);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER categories_normalize_name_trigger
  BEFORE INSERT OR UPDATE OF name ON categories
  FOR EACH ROW
  EXECUTE FUNCTION categories_normalize_name();

-- Comments
COMMENT ON TABLE categories IS 'Income/expense categories scoped to workspace';
COMMENT ON COLUMN categories.normalized_name IS 'Lowercase trimmed name for uniqueness check';
COMMENT ON COLUMN categories.is_system IS 'System default categories';
