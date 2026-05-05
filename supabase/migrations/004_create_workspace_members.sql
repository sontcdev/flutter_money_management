-- Migration 004: Create workspace_members table
-- Tracks membership of users in workspaces

CREATE TABLE workspace_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role text NOT NULL,
  membership_status text NOT NULL DEFAULT 'active',
  permissions jsonb NOT NULL DEFAULT '{}'::jsonb,
  joined_at timestamptz,
  invited_by_user_id uuid REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  removed_at timestamptz,
  
  CONSTRAINT workspace_members_role_check CHECK (role IN ('owner', 'member')),
  CONSTRAINT workspace_members_status_check CHECK (membership_status IN ('pending', 'active', 'removed', 'declined')),
  CONSTRAINT workspace_members_unique UNIQUE (workspace_id, user_id)
);

-- Indexes
CREATE INDEX workspace_members_workspace_id_idx ON workspace_members(workspace_id);
CREATE INDEX workspace_members_user_id_idx ON workspace_members(user_id);
CREATE INDEX workspace_members_workspace_status_idx ON workspace_members(workspace_id, membership_status);

-- Trigger for updated_at
CREATE TRIGGER workspace_members_updated_at
  BEFORE UPDATE ON workspace_members
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Comments
COMMENT ON TABLE workspace_members IS 'User membership in workspaces';
COMMENT ON COLUMN workspace_members.role IS 'owner or member';
COMMENT ON COLUMN workspace_members.membership_status IS 'pending, active, removed, or declined';
