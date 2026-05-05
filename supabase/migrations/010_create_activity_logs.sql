-- Migration 010: Create activity_logs table
-- Audit trail for workspace activities

CREATE TABLE activity_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  actor_user_id uuid NOT NULL REFERENCES profiles(id),
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  action text NOT NULL,
  summary text,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX activity_logs_workspace_id_idx ON activity_logs(workspace_id);
CREATE INDEX activity_logs_workspace_created_idx ON activity_logs(workspace_id, created_at DESC);
CREATE INDEX activity_logs_entity_idx ON activity_logs(entity_type, entity_id);

-- Comments
COMMENT ON TABLE activity_logs IS 'Audit trail for workspace activities';
COMMENT ON COLUMN activity_logs.entity_type IS 'transaction, category, budget, invite, member, workspace';
COMMENT ON COLUMN activity_logs.action IS 'created, updated, deleted, joined, etc.';
