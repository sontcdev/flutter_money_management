-- Migration 021: RLS policies for budgets
-- Members can view, only owner can manage

-- Select: active members can view budgets
CREATE POLICY budgets_select_member
  ON budgets FOR SELECT
  USING (is_workspace_member(workspace_id) AND deleted_at IS NULL);

-- Insert: only owner can create budgets
CREATE POLICY budgets_insert_owner
  ON budgets FOR INSERT
  WITH CHECK (is_workspace_owner(workspace_id));

-- Update: only owner can update budgets
CREATE POLICY budgets_update_owner
  ON budgets FOR UPDATE
  USING (is_workspace_owner(workspace_id))
  WITH CHECK (is_workspace_owner(workspace_id));

-- Delete: only owner can soft delete (via update)
-- No separate delete policy needed

-- Comments
COMMENT ON POLICY budgets_select_member ON budgets IS 'Members can view active budgets';
COMMENT ON POLICY budgets_insert_owner ON budgets IS 'Only owner can create budgets';
COMMENT ON POLICY budgets_update_owner ON budgets IS 'Only owner can update budgets';
