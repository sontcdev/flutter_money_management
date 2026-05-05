-- Migration 015: RLS policies for workspaces
-- Users can access workspaces they are members of

-- Select: active members can view workspace
CREATE POLICY workspaces_select_member
  ON workspaces FOR SELECT
  USING (is_workspace_member(id));

-- Insert: authenticated users can create their own workspace
CREATE POLICY workspaces_insert_own
  ON workspaces FOR INSERT
  WITH CHECK (auth.uid() = owner_user_id);

-- Update: only owner can update
CREATE POLICY workspaces_update_owner
  ON workspaces FOR UPDATE
  USING (is_workspace_owner(id))
  WITH CHECK (is_workspace_owner(id));

-- Delete: only owner can soft delete (via update)
-- Hard delete not allowed from client

-- Comments
COMMENT ON POLICY workspaces_select_member ON workspaces IS 'Members can view workspace';
COMMENT ON POLICY workspaces_insert_own ON workspaces IS 'Users can create workspace they own';
COMMENT ON POLICY workspaces_update_owner ON workspaces IS 'Only owner can update workspace';
