-- Migration 013: Enable Row Level Security
-- Enable RLS on all client-facing tables

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_workspace_preferences ENABLE ROW LEVEL SECURITY;

-- Comments
COMMENT ON TABLE profiles IS 'RLS enabled - users can only access their own profile';
COMMENT ON TABLE workspaces IS 'RLS enabled - users can only access workspaces they are members of';
COMMENT ON TABLE workspace_members IS 'RLS enabled - users can only see members of their workspaces';
