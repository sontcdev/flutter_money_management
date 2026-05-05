-- Migration 005: Create workspace_invites table
-- Invitation system for group workspaces

CREATE TABLE workspace_invites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  email text NOT NULL,
  role text NOT NULL DEFAULT 'member',
  token text NOT NULL UNIQUE,
  status text NOT NULL DEFAULT 'pending',
  invited_by_user_id uuid NOT NULL REFERENCES profiles(id),
  accepted_by_user_id uuid REFERENCES profiles(id),
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  CONSTRAINT workspace_invites_role_check CHECK (role IN ('member')),
  CONSTRAINT workspace_invites_status_check CHECK (status IN ('pending', 'accepted', 'expired', 'revoked'))
);

-- Indexes
CREATE UNIQUE INDEX workspace_invites_token_idx ON workspace_invites(token);
CREATE INDEX workspace_invites_workspace_id_idx ON workspace_invites(workspace_id);
CREATE INDEX workspace_invites_email_idx ON workspace_invites(email);
CREATE INDEX workspace_invites_status_idx ON workspace_invites(status);

-- Trigger for updated_at
CREATE TRIGGER workspace_invites_updated_at
  BEFORE UPDATE ON workspace_invites
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Comments
COMMENT ON TABLE workspace_invites IS 'Invitations to join group workspaces';
COMMENT ON COLUMN workspace_invites.email IS 'Normalized lowercase email';
COMMENT ON COLUMN workspace_invites.token IS 'Unique secure token for invite link';
