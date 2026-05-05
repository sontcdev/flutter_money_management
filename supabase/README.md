# Supabase Setup Guide

## Prerequisites
- Supabase account (sign up at https://supabase.com)

## Step 1: Create Supabase Project

1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Fill in project details:
   - **Name**: `money-management-dev` (or your preferred name)
   - **Database Password**: Choose a strong password (save it securely)
   - **Region**: Choose closest to your users
   - **Pricing Plan**: Free tier is sufficient for development

4. Wait for project to be created (~2 minutes)

## Step 2: Apply Database Migrations

### Option A: Using Supabase CLI (Recommended)

1. Install Supabase CLI:
   ```bash
   npm install -g supabase
   ```

2. Login to Supabase:
   ```bash
   supabase login
   ```

3. Link your project:
   ```bash
   supabase link --project-ref YOUR_PROJECT_REF
   ```
   (Find PROJECT_REF in your project settings URL: `https://supabase.com/dashboard/project/YOUR_PROJECT_REF`)

4. Push migrations:
   ```bash
   supabase db push
   ```

### Option B: Manual SQL Execution

1. Go to your project dashboard
2. Navigate to **SQL Editor** in the left sidebar
3. Execute each migration file in order (001 to 025):
   - Copy content from `supabase/migrations/001_extensions_and_helpers.sql`
   - Paste into SQL Editor
   - Click "Run"
   - Repeat for all 25 migration files in numerical order

**IMPORTANT:** Execute migrations in order: 001 → 002 → 003 → ... → 025

## Step 3: Get Project Credentials

1. Go to **Project Settings** → **API**
2. Copy the following values:
   - **Project URL**: `https://your-project-id.supabase.co`
   - **anon public key**: Long string starting with `eyJ...`

## Step 4: Configure Flutter App

1. Open `lib/src/config/supabase_config.dart`
2. Replace placeholder values:
   ```dart
   static const String supabaseUrl = 'https://your-project-id.supabase.co';
   static const String supabaseAnonKey = 'eyJ...your-anon-key...';
   ```

## Step 5: Verify Setup

1. Go to **Table Editor** in Supabase dashboard
2. You should see these tables:
   - profiles
   - workspaces
   - workspace_members
   - workspace_invites
   - categories
   - transactions
   - transaction_attachments
   - budgets
   - activity_logs
   - user_workspace_preferences

3. Go to **Authentication** → **Policies**
4. Verify RLS is enabled on all tables

## Step 6: Test Authentication

1. Run the Flutter app
2. Try signing up with a test email
3. Check Supabase dashboard → **Authentication** → **Users**
4. Verify:
   - User created in auth.users
   - Profile created in profiles table
   - Personal workspace created in workspaces table
   - Owner membership created in workspace_members table

## Troubleshooting

### Migration Errors
- **Error: "relation already exists"**: Table already created, skip that migration
- **Error: "function does not exist"**: Run helper function migrations first (001, 012)
- **Error: "permission denied"**: Check you're using the correct database password

### RLS Issues
- If queries fail with "permission denied", check RLS policies are applied
- Verify helper functions exist: `is_workspace_member`, `is_workspace_owner`

### Auth Issues
- Check trigger `on_auth_user_created` exists and is enabled
- Verify function `handle_new_user()` exists

## Security Notes

- **Never commit** `supabase_config.dart` with real credentials to public repos
- The anon key is safe for client apps (it's public)
- RLS policies protect your data even with the anon key
- For production, consider using environment variables or flutter_dotenv

## Next Steps

After setup is complete:
1. Test signup/login flow in the app
2. Verify workspace creation
3. Test data sync (once implemented)
4. Set up staging/production environments with separate Supabase projects
