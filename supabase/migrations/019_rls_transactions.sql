-- Migration 019: RLS policies for transactions
-- Members can view all, but only edit their own

-- Select: active members can view all transactions
CREATE POLICY transactions_select_member
  ON transactions FOR SELECT
  USING (is_workspace_member(workspace_id));

-- Insert: active members can create transactions (must set created_by to self)
CREATE POLICY transactions_insert_member
  ON transactions FOR INSERT
  WITH CHECK (
    is_workspace_member(workspace_id) 
    AND created_by_user_id = auth.uid()
  );

-- Update: only creator can update their own transaction
CREATE POLICY transactions_update_creator
  ON transactions FOR UPDATE
  USING (
    is_workspace_member(workspace_id) 
    AND created_by_user_id = auth.uid()
  )
  WITH CHECK (
    is_workspace_member(workspace_id) 
    AND created_by_user_id = auth.uid()
  );

-- Delete: only creator can soft delete (via update)
-- No separate delete policy needed

-- Comments
COMMENT ON POLICY transactions_select_member ON transactions IS 'Members can view all transactions';
COMMENT ON POLICY transactions_insert_member ON transactions IS 'Members can create transactions';
COMMENT ON POLICY transactions_update_creator ON transactions IS 'Only creator can update transaction';
