-- Migration 012: RLS helper functions
-- Helper functions for Row Level Security policies

-- Check if user is a member of workspace
CREATE OR REPLACE FUNCTION is_workspace_member(workspace_uuid uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM workspace_members
    WHERE workspace_id = workspace_uuid
      AND user_id = auth.uid()
      AND membership_status = 'active'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is owner of workspace
CREATE OR REPLACE FUNCTION is_workspace_owner(workspace_uuid uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM workspace_members
    WHERE workspace_id = workspace_uuid
      AND user_id = auth.uid()
      AND role = 'owner'
      AND membership_status = 'active'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is active member of workspace
CREATE OR REPLACE FUNCTION is_active_member(workspace_uuid uuid)
RETURNS boolean AS $$
BEGIN
  RETURN is_workspace_member(workspace_uuid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user can edit transaction (creator only)
CREATE OR REPLACE FUNCTION can_edit_transaction(workspace_uuid uuid, creator_uuid uuid)
RETURNS boolean AS $$
BEGIN
  RETURN is_workspace_member(workspace_uuid) AND creator_uuid = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comments
COMMENT ON FUNCTION is_workspace_member IS 'Check if current user is active member of workspace';
COMMENT ON FUNCTION is_workspace_owner IS 'Check if current user is owner of workspace';
COMMENT ON FUNCTION can_edit_transaction IS 'Check if current user can edit transaction (creator only)';
