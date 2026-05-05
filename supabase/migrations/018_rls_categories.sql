-- Migration 018: RLS policies for categories
-- Active members can view, only owner can manage

-- Select: active members can view categories
CREATE POLICY categories_select_member
  ON categories FOR SELECT
  USING (is_workspace_member(workspace_id) AND deleted_at IS NULL);

-- Insert: only owner can create categories
CREATE POLICY categories_insert_owner
  ON categories FOR INSERT
  WITH CHECK (is_workspace_owner(workspace_id));

-- Update: only owner can update categories
CREATE POLICY categories_update_owner
  ON categories FOR UPDATE
  USING (is_workspace_owner(workspace_id))
  WITH CHECK (is_workspace_owner(workspace_id));

-- Delete: only owner can soft delete (via update setting deleted_at)
-- No separate delete policy needed as delete is done via update

-- Comments
COMMENT ON POLICY categories_select_member ON categories IS 'Members can view active categories';
COMMENT ON POLICY categories_insert_owner ON categories IS 'Only owner can create categories';
COMMENT ON POLICY categories_update_owner ON categories IS 'Only owner can update categories';
