# Drift Migration v4 to v5 Plan

## Overview
Migrate from single-user local-only schema to multi-user workspace-aware schema with sync support.

## Schema Changes

### New Tables (v5)
- `profiles` - User profiles from Supabase
- `workspaces` - Personal and group workspaces
- `workspace_members` - Membership tracking
- `sync_queue` - Offline sync queue
- `sync_state` - Sync state per workspace

### Modified Tables (v4 → v5)
- `categories` → `categories_v5`
  - `id`: int → text (UUID)
  - Add: `workspace_id`, `normalized_name`, `is_system`, `is_archived`, `sort_order`
  - Add: `created_by_user_id`, `updated_by_user_id`, `deleted_at`, `deleted_by_user_id`
  - Add: `version`, `metadata`, `sync_status`

- `transactions` → `transactions_v5`
  - `id`: int → text (UUID)
  - `amount_cents` → `amount_minor`
  - `transaction_date` → `transaction_at`
  - `type` → `transaction_type`
  - Remove: `receipt_path` (will use separate attachments table later)
  - Add: `workspace_id`, `source`, `client_reference_id`
  - Add: `created_by_user_id`, `updated_by_user_id`, `deleted_at`, `deleted_by_user_id`
  - Add: `version`, `metadata`, `sync_status`

- `budgets` → `budgets_v5`
  - `id`: int → text (UUID)
  - `limit_cents` → `limit_minor`
  - Remove: `consumed_cents`, `overdraft_cents` (calculated, not stored)
  - Add: `workspace_id`, `name`, `currency_code`, `is_archived`
  - Add: `created_by_user_id`, `updated_by_user_id`, `deleted_at`, `deleted_by_user_id`
  - Add: `version`, `metadata`, `sync_status`

## Migration Strategy

### Phase 1: Create default local user and workspace
1. Generate UUID for local user profile
2. Create profile entry with email "local@device"
3. Create personal workspace "My Workspace"
4. Create owner membership

### Phase 2: Migrate existing data
1. Migrate categories:
   - Generate UUIDs for each category
   - Set workspace_id to default workspace
   - Set created_by/updated_by to local user
   - Copy name, icon, color, type
   - Set normalized_name = lower(trim(name))
   
2. Migrate transactions:
   - Generate UUIDs for each transaction
   - Set workspace_id to default workspace
   - Set created_by/updated_by to local user
   - Map old category int ID to new UUID
   - Copy amount, currency, date, type, note
   
3. Migrate budgets:
   - Generate UUIDs for each budget
   - Set workspace_id to default workspace
   - Set created_by/updated_by to local user
   - Map old category int ID to new UUID
   - Copy period info, limits

### Phase 3: Initialize sync state
1. Create sync_state entry for default workspace
2. Set full_sync_completed = false (will sync on first cloud login)

### Phase 4: Drop old tables
1. Drop old `categories`, `transactions`, `budgets` tables
2. Rename `categories_v5` → `categories`
3. Rename `transactions_v5` → `transactions`
4. Rename `budgets_v5` → `budgets`

## Rollback Strategy
- Keep old tables until migration verified
- Test queries on new schema before dropping old tables
- User data preserved in old tables until explicit drop

## Testing Checklist
- [ ] Old data visible in new schema
- [ ] Category counts match
- [ ] Transaction counts match
- [ ] Budget counts match
- [ ] Queries work with workspace scope
- [ ] No data loss
