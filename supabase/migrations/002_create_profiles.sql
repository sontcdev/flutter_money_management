-- Migration 002: Create profiles table
-- Profile table maps 1-1 with auth.users

CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL UNIQUE,
  display_name text NOT NULL,
  avatar_url text,
  phone text,
  default_currency_code text NOT NULL DEFAULT 'VND',
  locale text NOT NULL DEFAULT 'vi',
  timezone text NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  status text NOT NULL DEFAULT 'active',
  last_active_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  CONSTRAINT profiles_status_check CHECK (status IN ('active', 'disabled', 'deleted')),
  CONSTRAINT profiles_display_name_check CHECK (char_length(display_name) > 0)
);

-- Indexes
CREATE UNIQUE INDEX profiles_email_idx ON profiles(email);
CREATE INDEX profiles_status_idx ON profiles(status);

-- Trigger for updated_at
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Comments
COMMENT ON TABLE profiles IS 'User profiles, 1-1 mapping with auth.users';
COMMENT ON COLUMN profiles.id IS 'Same as auth.users.id';
COMMENT ON COLUMN profiles.status IS 'active, disabled, or deleted';
