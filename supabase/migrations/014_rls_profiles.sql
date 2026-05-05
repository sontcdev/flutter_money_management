-- Migration 014: RLS policies for profiles
-- Users can only access their own profile

-- Select: user can read their own profile
CREATE POLICY profiles_select_own
  ON profiles FOR SELECT
  USING (id = auth.uid());

-- Update: user can update their own profile (limited fields)
CREATE POLICY profiles_update_own
  ON profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Insert: handled by trigger on auth.users, not directly by users
-- Delete: not allowed directly

-- Comments
COMMENT ON POLICY profiles_select_own ON profiles IS 'Users can read their own profile';
COMMENT ON POLICY profiles_update_own ON profiles IS 'Users can update their own profile';
