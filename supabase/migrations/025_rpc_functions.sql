-- Migration 025: RPC functions for workspace operations
-- Secure functions for common workspace operations

-- Function to create a group workspace
CREATE OR REPLACE FUNCTION create_group_workspace(
  workspace_name text,
  workspace_settings jsonb DEFAULT '{}'::jsonb
)
RETURNS uuid AS $$
DECLARE
  new_workspace_id uuid;
BEGIN
  -- Create group workspace
  INSERT INTO workspaces (
    id, 
    type, 
    name, 
    owner_user_id, 
    settings, 
    created_at, 
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    'group',
    workspace_name,
    auth.uid(),
    workspace_settings,
    now(),
    now()
  )
  RETURNING id INTO new_workspace_id;

  -- Create owner membership
  INSERT INTO workspace_members (
    id,
    workspace_id,
    user_id,
    role,
    membership_status,
    joined_at,
    created_at,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    new_workspace_id,
    auth.uid(),
    'owner',
    'active',
    now(),
    now(),
    now()
  );

  RETURN new_workspace_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to accept workspace invite
CREATE OR REPLACE FUNCTION accept_workspace_invite(invite_token text)
RETURNS jsonb AS $$
DECLARE
  invite_record workspace_invites%ROWTYPE;
  new_member_id uuid;
BEGIN
  -- Get invite
  SELECT * INTO invite_record
  FROM workspace_invites
  WHERE token = invite_token
    AND status = 'pending'
    AND expires_at > now();

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid or expired invite');
  END IF;

  -- Check if user email matches
  IF invite_record.email != (SELECT email FROM auth.users WHERE id = auth.uid()) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Email mismatch');
  END IF;

  -- Create membership
  INSERT INTO workspace_members (
    id,
    workspace_id,
    user_id,
    role,
    membership_status,
    joined_at,
    invited_by_user_id,
    created_at,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    invite_record.workspace_id,
    auth.uid(),
    invite_record.role,
    'active',
    now(),
    invite_record.invited_by_user_id,
    now(),
    now()
  )
  RETURNING id INTO new_member_id;

  -- Update invite status
  UPDATE workspace_invites
  SET status = 'accepted',
      accepted_by_user_id = auth.uid(),
      updated_at = now()
  WHERE id = invite_record.id;

  RETURN jsonb_build_object(
    'success', true, 
    'workspace_id', invite_record.workspace_id,
    'member_id', new_member_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to revoke workspace invite
CREATE OR REPLACE FUNCTION revoke_workspace_invite(invite_id uuid)
RETURNS boolean AS $$
DECLARE
  invite_workspace_id uuid;
BEGIN
  -- Get workspace_id from invite
  SELECT workspace_id INTO invite_workspace_id
  FROM workspace_invites
  WHERE id = invite_id;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  -- Check if user is owner
  IF NOT is_workspace_owner(invite_workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner can revoke invites';
  END IF;

  -- Update invite status
  UPDATE workspace_invites
  SET status = 'revoked',
      updated_at = now()
  WHERE id = invite_id;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to archive workspace
CREATE OR REPLACE FUNCTION archive_workspace(workspace_id uuid)
RETURNS boolean AS $$
BEGIN
  -- Check if user is owner
  IF NOT is_workspace_owner(workspace_id) THEN
    RAISE EXCEPTION 'Only workspace owner can archive workspace';
  END IF;

  -- Update workspace status
  UPDATE workspaces
  SET status = 'archived',
      updated_at = now()
  WHERE id = workspace_id;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comments
COMMENT ON FUNCTION create_group_workspace IS 'Create a new group workspace with owner membership';
COMMENT ON FUNCTION accept_workspace_invite IS 'Accept a workspace invite and create membership';
COMMENT ON FUNCTION revoke_workspace_invite IS 'Revoke a pending workspace invite (owner only)';
COMMENT ON FUNCTION archive_workspace IS 'Archive a workspace (owner only)';
