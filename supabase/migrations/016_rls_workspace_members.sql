-- Migration 016: RLS policies for workspace_members
-- Members can view other members, only owner can manage

-- Select: active members can view all members in their workspace
CREATE POLICY workspace_members_select
  ON workspace_members FOR SELECT
  USING (is_workspace_member(workspace_id));

-- Insert: only owner can add members (via invite acceptance flow)
CREATE POLICY workspace_members_insert_owner
  ON workspace_members FOR INSERT
  WITH CHECK (is_workspace_owner(workspace_id));

-- Update: only owner can update membership
CREATE POLICY workspace_members_update_owner
  ON workspace_members FOR UPDATE
  USING (is_workspace_owner(workspace_id))
  WITH CHECK (is_workspace_owner(workspace_id));

-- Delete: only owner can remove members
CREATE POLICY workspace_members_delete_owner
  ON workspace_members FOR DELETE
  USING (is_workspace_owner(workspace_id));

-- Comments
COMMENT ON POLICY workspace_members_select ON workspace_members IS 'Members can view all members';
COMMENT ON POLICY workspace_members_insert_owner ON workspace_members IS 'Only owner can add members';
