-- Migration 022: RLS policies for activity_logs
-- Members can view, no direct client insert/update/delete

-- Select: active members can view activity logs
CREATE POLICY activity_logs_select_member
  ON activity_logs FOR SELECT
  USING (is_workspace_member(workspace_id));

-- Insert: deny direct client insert (use backend/RPC only)
-- No insert policy = no client insert allowed

-- Update: not allowed (immutable)
-- No update policy = no updates allowed

-- Delete: not allowed (immutable)
-- No delete policy = no deletes allowed

-- Comments
COMMENT ON POLICY activity_logs_select_member ON activity_logs IS 'Members can view activity logs';
COMMENT ON TABLE activity_logs IS 'Immutable audit trail - no client insert/update/delete';
