-- Migration 017: RLS policies for workspace_invites
-- Only workspace owner can manage invites

-- Select: only owner can view invites
CREATE POLICY workspace_invites_select_owner
  ON workspace_invites FOR SELECT
  USING (is_workspace_owner(workspace_id));

-- Insert: only owner can create invites
CREATE POLICY workspace_invites_insert_owner
  ON workspace_invites FOR INSERT
  WITH CHECK (is_workspace_owner(workspace_id));

-- Update: only owner can update invite status (revoke, etc.)
CREATE POLICY workspace_invites_update_owner
  ON workspace_invites FOR UPDATE
  USING (is_workspace_owner(workspace_id))
  WITH CHECK (is_workspace_owner(workspace_id));

-- Delete: only owner can delete invites
CREATE POLICY workspace_invites_delete_owner
  ON workspace_invites FOR DELETE
  USING (is_workspace_owner(workspace_id));

-- Comments
COMMENT ON POLICY workspace_invites_select_owner ON workspace_invites IS 'Only owner can view invites';
COMMENT ON POLICY workspace_invites_insert_owner ON workspace_invites IS 'Only owner can create invites';
