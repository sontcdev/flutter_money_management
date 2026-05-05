-- Migration 011: Create user_workspace_preferences table
-- User-specific preferences per workspace

CREATE TABLE user_workspace_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  preferred_report_range text,
  preferred_chart_type text,
  last_selected_tab text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  CONSTRAINT user_workspace_preferences_unique UNIQUE (user_id, workspace_id)
);

-- Trigger for updated_at
CREATE TRIGGER user_workspace_preferences_updated_at
  BEFORE UPDATE ON user_workspace_preferences
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Comments
COMMENT ON TABLE user_workspace_preferences IS 'User-specific preferences per workspace';
