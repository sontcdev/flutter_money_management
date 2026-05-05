-- Migration 020: RLS policies for transaction_attachments
-- Members can view, only transaction creator can manage

-- Select: active members can view attachments
CREATE POLICY transaction_attachments_select_member
  ON transaction_attachments FOR SELECT
  USING (is_workspace_member(workspace_id));

-- Insert: only transaction creator can add attachments
CREATE POLICY transaction_attachments_insert_creator
  ON transaction_attachments FOR INSERT
  WITH CHECK (
    is_workspace_member(workspace_id)
    AND EXISTS (
      SELECT 1 FROM transactions
      WHERE transactions.id = transaction_id
        AND transactions.created_by_user_id = auth.uid()
    )
  );

-- Update: no updates allowed (attachments are immutable)

-- Delete: only transaction creator can delete attachments
CREATE POLICY transaction_attachments_delete_creator
  ON transaction_attachments FOR DELETE
  USING (
    is_workspace_member(workspace_id)
    AND EXISTS (
      SELECT 1 FROM transactions
      WHERE transactions.id = transaction_id
        AND transactions.created_by_user_id = auth.uid()
    )
  );

-- Comments
COMMENT ON POLICY transaction_attachments_select_member ON transaction_attachments IS 'Members can view attachments';
COMMENT ON POLICY transaction_attachments_insert_creator ON transaction_attachments IS 'Only transaction creator can add attachments';
COMMENT ON POLICY transaction_attachments_delete_creator ON transaction_attachments IS 'Only transaction creator can delete attachments';
