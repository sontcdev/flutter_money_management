-- Migration 023: RLS policies for user_workspace_preferences
-- Users can only manage their own preferences

-- Select: user can read their own preferences
CREATE POLICY user_workspace_preferences_select_own
  ON user_workspace_preferences FOR SELECT
  USING (user_id = auth.uid());

-- Insert: user can create their own preferences (must be member of workspace)
CREATE POLICY user_workspace_preferences_insert_own
  ON user_workspace_preferences FOR INSERT
  WITH CHECK (
    user_id = auth.uid() 
    AND is_workspace_member(workspace_id)
  );

-- Update: user can update their own preferences
CREATE POLICY user_workspace_preferences_update_own
  ON user_workspace_preferences FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Delete: user can delete their own preferences
CREATE POLICY user_workspace_preferences_delete_own
  ON user_workspace_preferences FOR DELETE
  USING (user_id = auth.uid());

-- Comments
COMMENT ON POLICY user_workspace_preferences_select_own ON user_workspace_preferences IS 'Users can read their own preferences';
COMMENT ON POLICY user_workspace_preferences_insert_own ON user_workspace_preferences IS 'Users can create their own preferences';
