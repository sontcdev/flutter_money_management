# Multi-User Architecture Implementation Plan

## Muc tieu

Chuyen ung dung tu mo hinh quan ly tai chinh ca nhan local-only sang mo hinh:

- Moi user co `personal workspace`
- Co the tao `group workspace`
- `owner` quan ly group
- `member` chi xem du lieu chung va chi sua/xoa `transaction` do chinh minh tao
- Dung `Supabase` cho auth, database, storage
- Dung `Drift` lam local cache + offline queue
- Ho tro sync nhieu thiet bi

---

## 1. Data Contract

### 1.1 Nguyen tac chung

- Dung `uuid` cho khoa chinh
- Dung `timestamptz` cho thoi gian o cloud
- Dung `bigint` cho tien, don vi `minor unit`
- Moi bang nghiep vu deu co `workspace_id`
- Moi record co ownership:
  - `created_by_user_id`
  - `updated_by_user_id`
- Moi record mutable nen co:
  - `created_at`
  - `updated_at`
  - `deleted_at`
  - `deleted_by_user_id`
  - `version`
- Khong hard delete o app flow v1, dung soft delete
- V1 dung `text + check constraint` thay vi Postgres enum de migration linh hoat hon

### 1.2 Naming conventions

- Ten bang: `snake_case`, so nhieu
- Ten cot FK: `<entity>_id`
- Tien: `*_minor`
- JSON mo rong: `metadata`, `settings`, `permissions`, `payload`
- Truong status/role/type dung `text`

---

### 1.3 Bang `profiles`

Muc dich: ho so app-level, map 1-1 voi `auth.users`

| Column | Type | Null | Default | Constraint / Notes |
|---|---|---:|---|---|
| `id` | `uuid` | no | none | PK, same as `auth.users.id` |
| `email` | `text` | no | none | unique |
| `display_name` | `text` | no | none | trimmed non-empty |
| `avatar_url` | `text` | yes | null | |
| `phone` | `text` | yes | null | |
| `default_currency_code` | `text` | no | `'VND'` | length 3 preferred |
| `locale` | `text` | no | `'vi'` | ex `vi`, `en` |
| `timezone` | `text` | no | `'Asia/Ho_Chi_Minh'` | IANA timezone |
| `status` | `text` | no | `'active'` | `active/disabled/deleted` |
| `last_active_at` | `timestamptz` | yes | null | |
| `created_at` | `timestamptz` | no | `now()` | |
| `updated_at` | `timestamptz` | no | `now()` | |

Checks:
- `status in ('active','disabled','deleted')`
- `char_length(display_name) > 0`

Indexes:
- unique(`email`)
- index(`status`)

---

### 1.4 Bang `workspaces`

Muc dich: bien du lieu chinh, gom `personal` va `group`

| Column | Type | Null | Default | Constraint / Notes |
|---|---|---:|---|---|
| `id` | `uuid` | no | none | PK |
| `type` | `text` | no | none | `personal/group` |
| `name` | `text` | no | none | |
| `slug` | `text` | yes | null | optional unique later |
| `owner_user_id` | `uuid` | no | none | FK `profiles.id` |
| `default_currency_code` | `text` | no | `'VND'` | |
| `timezone` | `text` | no | `'Asia/Ho_Chi_Minh'` | |
| `month_start_day` | `smallint` | no | `1` | 1..31 |
| `status` | `text` | no | `'active'` | `active/archived/deleted` |
| `settings` | `jsonb` | no | `'{}'::jsonb` | workspace-level config |
| `created_at` | `timestamptz` | no | `now()` | |
| `updated_at` | `timestamptz` | no | `now()` | |
| `deleted_at` | `timestamptz` | yes | null | |

Checks:
- `type in ('personal','group')`
- `status in ('active','archived','deleted')`
- `month_start_day between 1 and 31`

Indexes:
- index(`owner_user_id`)
- index(`type`, `status`)
- optional unique partial on `slug`

Rules:
- `personal` workspace luon co 1 owner la chinh user do
- `group` workspace co 1 owner, nhieu member

---

### 1.5 Bang `workspace_members`

Muc dich: membership cua user trong workspace

| Column | Type | Null | Default | Constraint / Notes |
|---|---|---:|---|---|
| `id` | `uuid` | no | none | PK |
| `workspace_id` | `uuid` | no | none | FK `workspaces.id` |
| `user_id` | `uuid` | no | none | FK `profiles.id` |
| `role` | `text` | no | none | `owner/member` |
| `membership_status` | `text` | no | `'active'` | `pending/active/removed/declined` |
| `permissions` | `jsonb` | no | `'{}'::jsonb` | reserved for future |
| `joined_at` | `timestamptz` | yes | null | |
| `invited_by_user_id` | `uuid` | yes | null | FK `profiles.id` |
| `created_at` | `timestamptz` | no | `now()` | |
| `updated_at` | `timestamptz` | no | `now()` | |
| `removed_at` | `timestamptz` | yes | null | |

Checks:
- `role in ('owner','member')`
- `membership_status in ('pending','active','removed','declined')`

Constraints:
- unique(`workspace_id`, `user_id`)

Indexes:
- index(`workspace_id`)
- index(`user_id`)
- index(`workspace_id`, `membership_status`)

---

### 1.6 Bang `workspace_invites`

Muc dich: loi moi vao group workspace

| Column | Type | Null | Default | Constraint / Notes |
|---|---|---:|---|---|
| `id` | `uuid` | no | none | PK |
| `workspace_id` | `uuid` | no | none | FK |
| `email` | `text` | no | none | normalized lower-case |
| `role` | `text` | no | `'member'` | v1 only member |
| `token` | `text` | no | none | unique secure token |
| `status` | `text` | no | `'pending'` | `pending/accepted/expired/revoked` |
| `invited_by_user_id` | `uuid` | no | none | FK |
| `accepted_by_user_id` | `uuid` | yes | null | FK |
| `expires_at` | `timestamptz` | no | none | |
| `created_at` | `timestamptz` | no | `now()` | |
| `updated_at` | `timestamptz` | no | `now()` | |

Checks:
- `role in ('member')`
- `status in ('pending','accepted','expired','revoked')`

Indexes:
- unique(`token`)
- index(`workspace_id`)
- index(`email`)
- index(`status`)

---

### 1.7 Bang `categories`

Muc dich: danh muc thu/chi theo workspace

| Column | Type | Null | Default | Constraint / Notes |
|---|---|---:|---|---|
| `id` | `uuid` | no | none | PK |
| `workspace_id` | `uuid` | no | none | FK |
| `name` | `text` | no | none | |
| `normalized_name` | `text` | no | none | lower+trim |
| `type` | `text` | no | none | `expense/income` |
| `icon_name` | `text` | no | none | |
| `color_value` | `integer` | no | none | ARGB int |
| `is_system` | `boolean` | no | `false` | default categories |
| `is_archived` | `boolean` | no | `false` | |
| `sort_order` | `integer` | no | `0` | |
| `created_by_user_id` | `uuid` | no | none | FK |
| `updated_by_user_id` | `uuid` | no | none | FK |
| `created_at` | `timestamptz` | no | `now()` | |
| `updated_at` | `timestamptz` | no | `now()` | |
| `deleted_at` | `timestamptz` | yes | null | |
| `deleted_by_user_id` | `uuid` | yes | null | FK |
| `version` | `integer` | no | `1` | optimistic version |
| `metadata` | `jsonb` | no | `'{}'::jsonb` | |

Checks:
- `type in ('expense','income')`
- `version > 0`

Constraints:
- partial unique index on active rows: (`workspace_id`, `normalized_name`, `type`) where `deleted_at is null`

Indexes:
- index(`workspace_id`)
- index(`workspace_id`, `type`)

Rule:
- Group workspace: only owner can insert/update/delete categories
- Personal workspace: owner can fully manage

---

### 1.8 Bang `transactions`

Muc dich: giao dich tai chinh

| Column | Type | Null | Default | Constraint / Notes |
|---|---|---:|---|---|
| `id` | `uuid` | no | none | PK |
| `workspace_id` | `uuid` | no | none | FK |
| `category_id` | `uuid` | no | none | FK |
| `amount_minor` | `bigint` | no | none | > 0 |
| `currency_code` | `text` | no | none | |
| `transaction_type` | `text` | no | none | `expense/income` |
| `transaction_at` | `timestamptz` | no | none | business datetime |
| `note` | `text` | yes | null | |
| `source` | `text` | no | `'manual'` | `manual/import/system` |
| `client_reference_id` | `text` | yes | null | offline id hint |
| `created_by_user_id` | `uuid` | no | none | FK |
| `updated_by_user_id` | `uuid` | no | none | FK |
| `created_at` | `timestamptz` | no | `now()` | |
| `updated_at` | `timestamptz` | no | `now()` | |
| `deleted_at` | `timestamptz` | yes | null | |
| `deleted_by_user_id` | `uuid` | yes | null | FK |
| `version` | `integer` | no | `1` | |
| `metadata` | `jsonb` | no | `'{}'::jsonb` | |

Checks:
- `transaction_type in ('expense','income')`
- `source in ('manual','import','system')`
- `amount_minor > 0`
- `version > 0`

Indexes:
- index(`workspace_id`)
- index(`workspace_id`, `transaction_at desc`)
- index(`workspace_id`, `category_id`, `transaction_at desc`)
- index(`workspace_id`, `created_by_user_id`, `transaction_at desc`)
- partial index(`workspace_id`, `transaction_type`, `transaction_at desc`) where `deleted_at is null`

Rules:
- Member in group can see all workspace transactions
- Member can only update/delete their own transaction
- Owner also cannot update member transaction in v1

---

### 1.9 Bang `transaction_attachments`

Muc dich: metadata file hoa don/bien lai

| Column | Type | Null | Default | Constraint / Notes |
|---|---|---:|---|---|
| `id` | `uuid` | no | none | PK |
| `workspace_id` | `uuid` | no | none | FK |
| `transaction_id` | `uuid` | no | none | FK |
| `storage_bucket` | `text` | no | none | |
| `storage_path` | `text` | no | none | unique enough per file |
| `file_name` | `text` | no | none | |
| `mime_type` | `text` | yes | null | |
| `file_size` | `bigint` | yes | null | |
| `checksum` | `text` | yes | null | |
| `uploaded_by_user_id` | `uuid` | no | none | FK |
| `created_at` | `timestamptz` | no | `now()` | |
| `deleted_at` | `timestamptz` | yes | null | |

Indexes:
- index(`transaction_id`)
- index(`workspace_id`)

Rules:
- select if active member
- insert/delete only by transaction creator in v1

---

### 1.10 Bang `budgets`

Muc dich: ngan sach theo category va khoang thoi gian

| Column | Type | Null | Default | Constraint / Notes |
|---|---|---:|---|---|
| `id` | `uuid` | no | none | PK |
| `workspace_id` | `uuid` | no | none | FK |
| `category_id` | `uuid` | no | none | FK |
| `name` | `text` | yes | null | optional label |
| `period_type` | `text` | no | none | `monthly/yearly/custom` |
| `period_start` | `timestamptz` | no | none | |
| `period_end` | `timestamptz` | no | none | |
| `limit_minor` | `bigint` | no | none | > 0 |
| `currency_code` | `text` | no | none | |
| `allow_overdraft` | `boolean` | no | `false` | |
| `is_archived` | `boolean` | no | `false` | |
| `created_by_user_id` | `uuid` | no | none | FK |
| `updated_by_user_id` | `uuid` | no | none | FK |
| `created_at` | `timestamptz` | no | `now()` | |
| `updated_at` | `timestamptz` | no | `now()` | |
| `deleted_at` | `timestamptz` | yes | null | |
| `deleted_by_user_id` | `uuid` | yes | null | FK |
| `version` | `integer` | no | `1` | |
| `metadata` | `jsonb` | no | `'{}'::jsonb` | |

Checks:
- `period_type in ('monthly','yearly','custom')`
- `period_end >= period_start`
- `limit_minor > 0`
- `version > 0`

Indexes:
- index(`workspace_id`)
- index(`workspace_id`, `category_id`)
- index(`workspace_id`, `period_start`, `period_end`)

Rule:
- Group workspace: owner only insert/update/delete
- Member: select only

---

### 1.11 Bang `activity_logs`

Muc dich: audit trail

| Column | Type | Null | Default | Constraint / Notes |
|---|---|---:|---|---|
| `id` | `uuid` | no | none | PK |
| `workspace_id` | `uuid` | no | none | FK |
| `actor_user_id` | `uuid` | no | none | FK |
| `entity_type` | `text` | no | none | ex `transaction`,`category`,`budget`,`invite`,`member`,`workspace` |
| `entity_id` | `uuid` | no | none | |
| `action` | `text` | no | none | ex `created`,`updated`,`deleted`,`joined` |
| `summary` | `text` | yes | null | |
| `payload` | `jsonb` | no | `'{}'::jsonb` | |
| `created_at` | `timestamptz` | no | `now()` | |

Indexes:
- index(`workspace_id`)
- index(`workspace_id`, `created_at desc`)
- index(`entity_type`, `entity_id`)

Rule:
- active member can select
- insert by backend/app service only
- no update/delete from client

---

### 1.12 Bang `user_workspace_preferences`

Muc dich: preference theo user trong tung workspace

| Column | Type | Null | Default | Constraint / Notes |
|---|---|---:|---|---|
| `id` | `uuid` | no | none | PK |
| `user_id` | `uuid` | no | none | FK |
| `workspace_id` | `uuid` | no | none | FK |
| `preferred_report_range` | `text` | yes | null | |
| `preferred_chart_type` | `text` | yes | null | |
| `last_selected_tab` | `text` | yes | null | |
| `created_at` | `timestamptz` | no | `now()` | |
| `updated_at` | `timestamptz` | no | `now()` | |

Constraint:
- unique(`user_id`, `workspace_id`)

Rule:
- user chi select/insert/update row cua chinh minh

---

### 1.13 Local Drift-only tables

#### `sync_queue`

| Column | Type | Null | Notes |
|---|---|---:|---|
| `id` | `text` | no | UUID string |
| `entity_type` | `text` | no | `workspace/category/transaction/budget/...` |
| `entity_id` | `text` | no | local/cloud uuid |
| `workspace_id` | `text` | no | |
| `operation` | `text` | no | `insert/update/delete` |
| `payload_json` | `text` | no | serialized record |
| `base_version` | `integer` | yes | version at edit time |
| `status` | `text` | no | `pending/processing/failed` |
| `retry_count` | `integer` | no | default 0 |
| `last_error` | `text` | yes | |
| `created_at` | `datetime` | no | |
| `updated_at` | `datetime` | no | |

#### `sync_state`

| Column | Type | Null | Notes |
|---|---|---:|---|
| `workspace_id` | `text` | no | PK |
| `last_pulled_at` | `datetime` | yes | |
| `last_pushed_at` | `datetime` | yes | |
| `last_remote_updated_at_cursor` | `datetime` | yes | |
| `full_sync_completed` | `boolean` | no | default false |
| `updated_at` | `datetime` | no | |

---

## 2. Permission Matrix

### 2.1 Quy uoc role

- `Owner`: owner cua workspace
- `Member`: member active
- `Self`: record do chinh user tao
- `Others`: record do user khac tao trong cung workspace

### 2.2 Ma tran quyen day du theo tung bang

| Entity | Role | Select | Insert | Update | Delete |
|---|---|---|---|---|---|
| `profiles` | self | yes | system only | self limited | no |
| `profiles` | other user | no direct | no | no | no |
| `workspaces` | owner | yes | yes | yes | soft-delete/archive yes |
| `workspaces` | member | yes | no | no | no |
| `workspace_members` | owner | yes | yes | yes | yes |
| `workspace_members` | member | yes | no | no | no |
| `workspace_invites` | owner | yes | yes | revoke/update status yes | yes/revoke |
| `workspace_invites` | member | no | no | no | no |
| `categories` in personal | owner | yes | yes | yes | yes |
| `categories` in group | owner | yes | yes | yes | yes |
| `categories` in group | member | yes | no | no | no |
| `transactions` in personal | owner | yes | yes | yes | yes |
| `transactions` in group self-created | owner | yes | yes | yes | yes |
| `transactions` in group self-created | member | yes | yes | yes | yes |
| `transactions` in group others-created | owner | yes | no | no | no |
| `transactions` in group others-created | member | yes | no | no | no |
| `transaction_attachments` self tx | owner/member creator | yes | yes | no | yes |
| `transaction_attachments` others tx | owner/member non-creator | yes | no | no | no |
| `budgets` in personal | owner | yes | yes | yes | yes |
| `budgets` in group | owner | yes | yes | yes | yes |
| `budgets` in group | member | yes | no | no | no |
| `activity_logs` | owner | yes | no direct | no | no |
| `activity_logs` | member | yes | no direct | no | no |
| `user_workspace_preferences` self | owner/member | yes | yes | yes | yes |
| `user_workspace_preferences` others | owner/member | no | no | no | no |

### 2.3 Policy rules chi tiet

#### `profiles`
- select: user doc profile cua chinh minh
- update: user sua `display_name`, `avatar_url`, `locale`, `timezone`, `default_currency_code`
- update `email` nen di qua auth flow rieng, khong truc tiep bang UI table update
- insert: trigger/backend only

#### `workspaces`
- owner:
  - select
  - create group workspace
  - update `name`, `month_start_day`, `default_currency_code`, `timezone`, `settings`, `status`
  - archive/delete soft
- member:
  - select workspace active minh thuoc ve
  - khong update/delete

#### `workspace_members`
- owner:
  - view all members
  - add member via invite acceptance flow/backend
  - remove member
  - cannot remove self from personal workspace
- member:
  - view all active members trong workspace
  - khong them/sua/xoa

#### `workspace_invites`
- owner:
  - create invite
  - revoke invite
  - view invites
- member:
  - khong co quyen

#### `categories`
- personal workspace owner: full CRUD
- group workspace owner: full CRUD
- group workspace member: select only

#### `transactions`
- personal workspace owner: full CRUD
- group workspace:
  - owner:
    - select all
    - insert own transactions
    - update/delete only transactions created by self
  - member:
    - select all
    - insert own transactions
    - update/delete only transactions created by self

#### `transaction_attachments`
- same ownership logic as transaction creator
- select by all active members
- insert/delete only by creator of parent transaction

#### `budgets`
- personal owner: full CRUD
- group owner: full CRUD
- group member: select only

#### `activity_logs`
- select by all active members
- insert by backend/app service only
- no update/delete

#### `user_workspace_preferences`
- each user only manages own rows

---

## 3. Sync Contract

### 3.1 Nguyen tac sync

- UI luon doc tu local Drift
- Moi write di local truoc
- Cloud la source of truth dai han
- Sync la eventual consistency
- V1 khong ho tro merge phuc tap
- V1 dung:
  - optimistic local write
  - background push
  - incremental pull
  - conflict resolution don gian, de hieu

### 3.2 Entity sync scope

Sync cho:
- `workspaces`
- `workspace_members`
- `workspace_invites`
- `categories`
- `transactions`
- `transaction_attachments` metadata
- `budgets`
- `user_workspace_preferences`

Khong sync tu client:
- `activity_logs` neu backend quan ly
- `profiles` co the sync theo API/session bootstrap rieng

---

### 3.3 Local write flow

Ap dung cho create/update/delete transaction, category, budget, preferences.

#### Create
1. Client sinh `uuid`
2. Ghi row vao local table
3. Gan:
   - `sync_status = pending_create`
   - `version = 1`
   - `updated_at = local_now`
4. Push mot row vao `sync_queue`
5. UI cap nhat ngay

#### Update
1. Doc local row hien tai
2. Apply patch local
3. Tang `version = version + 1`
4. Gan `sync_status = pending_update`
5. Push `sync_queue` item voi `base_version`
6. UI cap nhat ngay

#### Delete
1. Khong xoa local row ngay
2. Gan:
   - `deleted_at = local_now`
   - `deleted_by_user_id = current_user`
   - `sync_status = pending_delete`
3. Push queue item `delete`
4. UI mac dinh an row soft-deleted

#### Queue processing
1. Worker lay cac item `pending`
2. Chuyen `processing`
3. Goi Supabase mutation
4. Neu thanh cong:
   - update local row bang server canonical row
   - set `sync_status = synced`
   - delete queue item
5. Neu loi tam thoi:
   - set `failed`
   - tang `retry_count`
   - giu `last_error`
6. Retry with backoff

---

### 3.4 Remote pull flow

#### Bootstrap full sync
1. Sau login, load session
2. Load profile
3. Load workspace list
4. Voi workspace active:
   - pull workspace
   - pull members
   - pull categories
   - pull budgets
   - pull transactions phan trang hoac theo `updated_at`
   - pull attachment metadata
   - pull preferences
5. Ghi local
6. set `full_sync_completed = true`
7. set cursor bang `max(server updated_at)`

#### Incremental pull
1. Lay `last_remote_updated_at_cursor`
2. Query moi bang theo:
   - `workspace_id`
   - `updated_at > cursor OR deleted_at > cursor`
3. Upsert local rows
4. Neu row remote `deleted_at != null`, local cung mark deleted
5. Update cursor bang max timestamp moi nhat nhan duoc

#### Workspace switching
1. Khi doi workspace:
   - ensure local data for workspace exists
   - neu chua full sync thi sync truoc
   - invalidate providers theo workspace
   - UI reload tu local scoped data

---

### 3.5 Conflict policy

Ap dung khi local pending update gap remote row da doi.

#### Conflict definition
Xay ra khi:
- local queue item dung `base_version = X`
- remote row hien tai da `version > X`
- hoac `updated_at` remote moi hon logic edit baseline

#### V1 policy
- `server last-write-wins` cho `categories`, `transactions`, `budgets`, `preferences`
- `delete wins` neu mot phia da soft delete
- conflict duoc log noi bo de user co the biet neu can sau nay

#### Detailed behavior

##### Create conflict
- Neu create bang `uuid` moi thi hau nhu khong conflict
- Neu server tu choi do business rule:
  - mark queue `failed`
  - giu local row `conflicted` hoac `failed_create`
  - hien thong bao nhe cho user

##### Update conflict
- Neu remote version > base_version:
  - uu tien remote canonical row
  - local row bi overwrite boi remote
  - queue item mark resolved/conflicted and removed
  - ghi mot `sync_conflict_log` local neu muon theo doi

##### Delete conflict
- Neu remote row da update nhung local delete den sau:
  - delete wins
- Neu remote row da deleted:
  - coi nhu success, xoa queue

##### Business rule conflict
Vi du:
- member co update category group
- member co update transaction khong phai cua minh
- budget overlap rule fail

Xu ly:
- queue item `failed`
- local row revert ve last synced snapshot neu mutation bi server reject
- UI hien error cu the

Khuyen nghi bo sung local snapshot:
- moi row co `last_synced_payload_json` hoac co the suy ra tu sync store
- giup revert khi server reject

---

### 3.6 Soft delete handling

#### Cloud
- moi delete app flow la update:
  - `deleted_at = now()`
  - `deleted_by_user_id = auth.uid()`
  - `updated_at = now()`
  - `version = version + 1`

#### Local
- khi user delete:
  - mark soft delete local ngay
  - enqueue delete op
- queries mac dinh phai co `deleted_at is null`
- man manage co the co optional filter show deleted sau nay

#### Pull
- neu remote row co `deleted_at != null`, local update theo
- khong hard delete local ngay de tranh mat audit/sync trace

#### Purge strategy
- chua can v1
- co the them cleanup job sau:
  - hard purge local rows deleted > 30/60 ngay
  - cloud giu lau hon hoac khong purge

---

## Tai Lieu 1: Ma Tran Quyen Day Du Theo Tung Bang

### A. Account / Identity

| Table | Action | Owner | Member | Self-only note |
|---|---|---|---|---|
| `profiles` | select | self only | self only | khong xem profile nguoi la truc tiep |
| `profiles` | insert | system | system | trigger tao |
| `profiles` | update | self limited | self limited | khong update truc tiep email/auth-sensitive |
| `profiles` | delete | no | no | dung disable/soft-delete account flow sau |

### B. Workspace Core

| Table | Action | Owner | Member | Notes |
|---|---|---|---|---|
| `workspaces` | select | yes | yes | member active only |
| `workspaces` | insert | yes | yes | thuc te ai cung tao duoc workspace moi cua minh |
| `workspaces` | update | yes | no | chi owner workspace do |
| `workspaces` | delete/archive | yes | no | soft delete/archive |
| `workspace_members` | select | yes | yes | xem danh sach thanh vien cung workspace |
| `workspace_members` | insert | yes | no | qua invite accept/backend flow |
| `workspace_members` | update role/status | yes | no | v1 chu yeu remove/status |
| `workspace_members` | delete/remove | yes | no | owner only |
| `workspace_invites` | select | yes | no | owner xem invite workspace |
| `workspace_invites` | insert | yes | no | owner create invite |
| `workspace_invites` | update status | yes | no | revoke/expire |
| `workspace_invites` | delete | yes | no | optional hard cleanup admin-side |

### C. Finance Data

| Table | Action | Owner Personal | Owner Group | Member Group | Notes |
|---|---|---|---|---|---|
| `categories` | select | yes | yes | yes | |
| `categories` | insert | yes | yes | no | group owner only |
| `categories` | update | yes | yes | no | |
| `categories` | delete | yes | yes | no | soft delete |
| `budgets` | select | yes | yes | yes | |
| `budgets` | insert | yes | yes | no | group owner only |
| `budgets` | update | yes | yes | no | |
| `budgets` | delete | yes | yes | no | soft delete |

### D. Transactions

| Table | Action | Owner Personal | Owner Group Self | Owner Group Others | Member Group Self | Member Group Others |
|---|---|---|---|---|---|---|
| `transactions` | select | yes | yes | yes | yes | yes |
| `transactions` | insert | yes | yes | n/a | yes | n/a |
| `transactions` | update | yes | yes | no | yes | no |
| `transactions` | delete | yes | yes | no | yes | no |

### E. Attachments

| Table | Action | Tx Creator | Same Workspace Non-Creator |
|---|---|---|---|
| `transaction_attachments` | select | yes | yes |
| `transaction_attachments` | insert | yes | no |
| `transaction_attachments` | update | no | no |
| `transaction_attachments` | delete | yes | no |

### F. Audit / Preference

| Table | Action | Owner | Member | Notes |
|---|---|---|---|---|
| `activity_logs` | select | yes | yes | all active members |
| `activity_logs` | insert | system/app service | system/app service | not direct user CRUD |
| `activity_logs` | update | no | no | immutable |
| `activity_logs` | delete | no | no | immutable |
| `user_workspace_preferences` | select | self only | self only | per user |
| `user_workspace_preferences` | insert | self only | self only | |
| `user_workspace_preferences` | update | self only | self only | |
| `user_workspace_preferences` | delete | self only | self only | optional |

---

## Tai Lieu 2: Danh Sach SQL Migration Theo Thu Tu Thuc Hien

### Migration 001: Extensions va helpers nen
1. enable extension `pgcrypto` neu can `gen_random_uuid()`
2. tao function `set_updated_at()`
3. tao function normalize text neu muon, vi du `normalize_name(text)`

### Migration 002: Create `profiles`
1. create table `profiles`
2. add constraints/checks
3. add indexes
4. create trigger `updated_at`

### Migration 003: Create `workspaces`
1. create table `workspaces`
2. add FK to `profiles`
3. add checks
4. add indexes
5. create trigger `updated_at`

### Migration 004: Create `workspace_members`
1. create table `workspace_members`
2. add FK to `workspaces`, `profiles`
3. add unique `(workspace_id, user_id)`
4. add checks
5. indexes
6. trigger `updated_at`

### Migration 005: Create `workspace_invites`
1. create table `workspace_invites`
2. add FK
3. add unique `token`
4. add checks
5. indexes
6. trigger `updated_at`

### Migration 006: Create `categories`
1. create table `categories`
2. add FKs to `workspaces`, `profiles`
3. add checks
4. add partial unique index active category
5. add indexes
6. trigger `updated_at`

### Migration 007: Create `transactions`
1. create table `transactions`
2. add FKs
3. add checks
4. add indexes for workspace/date/category/creator
5. trigger `updated_at`

### Migration 008: Create `transaction_attachments`
1. create table `transaction_attachments`
2. add FKs
3. add indexes

### Migration 009: Create `budgets`
1. create table `budgets`
2. add FKs
3. add checks
4. add indexes
5. trigger `updated_at`

### Migration 010: Create `activity_logs`
1. create table `activity_logs`
2. add FKs
3. add indexes

### Migration 011: Create `user_workspace_preferences`
1. create table `user_workspace_preferences`
2. add unique `(user_id, workspace_id)`
3. indexes
4. trigger `updated_at`

### Migration 012: Helper SQL functions for RLS
1. `is_workspace_member(workspace_uuid uuid)`
2. `is_workspace_owner(workspace_uuid uuid)`
3. `is_active_member(workspace_uuid uuid)`
4. optional `can_edit_transaction(workspace_uuid uuid, creator_uuid uuid)`

### Migration 013: Enable RLS on all tables
1. `alter table ... enable row level security`
2. apply for all client-facing tables

### Migration 014: RLS policies for `profiles`
1. self select
2. self update limited
3. system insert policy if needed

### Migration 015: RLS policies for `workspaces`
1. select for active members
2. insert for authenticated users creating owned workspace
3. update/delete only owner

### Migration 016: RLS policies for `workspace_members`
1. select active members of same workspace
2. insert/update/delete owner only

### Migration 017: RLS policies for `workspace_invites`
1. select owner only
2. insert/update/delete owner only

### Migration 018: RLS policies for `categories`
1. select active member
2. insert/update/delete owner only

### Migration 019: RLS policies for `transactions`
1. select active member
2. insert active member with `created_by_user_id = auth.uid()`
3. update/delete only when `created_by_user_id = auth.uid()`

### Migration 020: RLS policies for `transaction_attachments`
1. select active member
2. insert/delete only parent transaction creator or uploaded_by = auth.uid()

### Migration 021: RLS policies for `budgets`
1. select active member
2. insert/update/delete owner only

### Migration 022: RLS policies for `activity_logs`
1. select active member
2. deny direct client insert/update/delete, or insert only through secure RPC if needed

### Migration 023: RLS policies for `user_workspace_preferences`
1. self select
2. self insert/update/delete within owned membership

### Migration 024: Auth signup triggers
1. trigger on `auth.users` insert => create `profiles`
2. trigger / function => create personal workspace
3. insert owner membership for that personal workspace

### Migration 025: Optional RPC/functions
1. `create_group_workspace(name, settings...)`
2. `accept_workspace_invite(token)`
3. `revoke_workspace_invite(invite_id)`
4. `archive_workspace(workspace_id)`

Khuyen nghi:
- nhom cac policy theo bang, khong don het vao 1 migration khong lo
- moi migration co the rollback/review de hon

---

## Tai Lieu 3: Backlog Implementation Chi Tiet Theo Ticket Nho

### Epic A: Supabase Foundation

#### A1. Setup Supabase project
- tao project dev/staging
- lay anon key, url
- define env strategy cho Flutter
- DoD: app co the connect moi truong dev

#### A2. Create base SQL helper functions
- `set_updated_at`
- `is_workspace_member`
- `is_workspace_owner`
- DoD: functions query duoc trong SQL editor

#### A3. Create profile schema
- migration tao `profiles`
- index, check, trigger
- DoD: `profiles` table valid

#### A4. Create workspace schema
- migration tao `workspaces`, `workspace_members`, `workspace_invites`
- DoD: quan he workspace/member/invite hoan chinh

#### A5. Create finance schema
- migration tao `categories`, `transactions`, `transaction_attachments`, `budgets`
- DoD: finance schema len du

#### A6. Create support schema
- migration tao `activity_logs`, `user_workspace_preferences`
- DoD: audit/preference tables san sang

#### A7. Implement signup bootstrap triggers
- tao `profiles` khi `auth.users` insert
- tao `personal workspace`
- tao owner membership
- DoD: signup xong co day du 3 row nen

#### A8. Implement RLS policies
- viet policies tung bang
- verify owner/member/self semantics
- DoD: SQL test thu cong pass

#### A9. Add storage buckets and policies
- tao bucket receipts
- policy read active member / write creator
- DoD: upload/download test duoc

---

### Epic B: Flutter Auth and Session

#### B1. Add Supabase Flutter dependencies
- add package
- init in bootstrap
- DoD: app khoi tao Supabase thanh cong

#### B2. Create auth service layer
- `SupabaseAuthService`
- `AuthRepository`
- `SessionRepository`
- DoD: wrapper methods login/signup/logout/session refresh

#### B3. Add auth state providers
- `authStateProvider`
- `currentUserProvider`
- `profileProvider`
- DoD: app nhan biet signed-in/signed-out state

#### B4. Build sign-up screen
- email/password/register
- validation
- error mapping
- DoD: user dang ky duoc

#### B5. Build sign-in screen
- login UI
- remember session via Supabase
- DoD: login duoc va restore session

#### B6. Build auth guard routing
- splash
- unauthenticated routes
- authenticated app shell
- DoD: chua auth khong vao home

#### B7. Separate local app lock from auth
- giu PIN local neu muon
- doi `AuthService` hien tai thanh app lock service
- DoD: auth cloud va pin local khong lan vai tro

---

### Epic C: Domain Models and Repositories

#### C1. Create new domain models
- `Profile`
- `Workspace`
- `WorkspaceMember`
- `WorkspaceInvite`
- DoD: models du fields cloud contract

#### C2. Create workspace repositories
- fetch workspaces
- fetch members
- create group workspace
- accept invite
- DoD: repository contract on

#### C3. Refactor finance models to UUID and workspace-aware
- `Transaction`
- `Category`
- `Budget`
- DoD: model layer bo assumption int ids/global data

#### C4. Create attachment model/repository
- metadata model
- upload/download orchestration contract
- DoD: repository interface ready

---

### Epic D: Drift Local Schema Migration

#### D1. Design local Drift schema vNext
- mirror cloud tables
- them `sync_status`, local cache fields
- DoD: schema document hoan chinh

#### D2. Implement Drift tables for workspaces/members
- new tables
- codegen
- DoD: app compiles

#### D3. Refactor local category table
- uuid ids
- workspace scope
- ownership fields
- soft delete fields
- DoD: table migrated

#### D4. Refactor local transaction table
- uuid ids
- workspace scope
- ownership
- sync fields
- DoD: table migrated

#### D5. Refactor local budget table
- same pattern
- DoD: table migrated

#### D6. Add local attachments/sync tables
- `transaction_attachments`
- `sync_queue`
- `sync_state`
- DoD: codegen pass

#### D7. Write Drift migration from old schema
- create default personal workspace locally
- backfill all old data with workspace id
- map old int IDs strategy if needed
- DoD: old user data still accessible after migration

#### D8. Add migration tests
- seed old v4 db
- migrate to new schema
- verify counts/data integrity
- DoD: migration tests pass

---

### Epic E: Workspace-aware Data Layer

#### E1. Refactor DAOs to scoped queries
- remove global `getAll...`
- add `getByWorkspace...`
- DoD: all DAOs require workspace scope where appropriate

#### E2. Refactor repositories to require workspace context
- pass `workspaceId`
- enforce creator metadata on writes
- DoD: repository public APIs workspace-aware

#### E3. Refactor Riverpod providers
- add `workspaceListProvider`
- add `activeWorkspaceProvider`
- make categories/transactions/budgets depend on active workspace
- DoD: switching workspace reloads data correctly

#### E4. Refactor reports queries
- query DB by workspace/date/member
- remove load-all-then-filter patterns
- DoD: report providers scoped and efficient

#### E5. Refactor budget calculation
- calculate within workspace only
- define owner-only group budget management
- DoD: no cross-workspace contamination

---

### Epic F: Workspace UX

#### F1. Build workspace selector UI
- list personal and group workspaces
- active workspace switch
- DoD: user doi workspace duoc

#### F2. Build create group workspace flow
- form create name/settings
- DoD: owner tao group moi duoc

#### F3. Build member list screen
- list members
- owner controls visible only to owner
- DoD: membership screen usable

#### F4. Build invite member flow
- invite by email
- pending invites list
- revoke invite
- DoD: invite lifecycle hoat dong

#### F5. Refactor settings screen
- split `Account`, `Workspace`, `App`
- move month start day to workspace settings
- DoD: settings semantics dung mo hinh moi

---

### Epic G: Sync Engine

#### G1. Implement local sync queue write path
- create/update/delete enqueue logic
- DoD: writes tao queue items chinh xac

#### G2. Implement sync worker
- pending -> processing -> success/fail
- backoff retry
- DoD: queue engine chay nen on

#### G3. Implement full sync bootstrap
- profile/workspaces/members/categories/budgets/transactions
- DoD: login moi co local cache hoan chinh

#### G4. Implement incremental pull
- by `updated_at` cursor
- upsert local rows
- DoD: remote changes duoc keo ve

#### G5. Implement push mutations
- per entity type
- handle create/update/delete
- DoD: local changes len cloud thanh cong

#### G6. Implement conflict handling
- server last-write-wins
- delete wins
- revert local on permission/business rule failure
- DoD: conflict cases deterministic

#### G7. Implement sync status UX
- badge/loading/manual refresh
- error feedback when sync fails
- DoD: user hieu duoc trang thai sync co ban

---

### Epic H: Transaction and Attachment UX

#### H1. Refactor add transaction flow
- create with workspaceId + creatorId
- DoD: save transaction in active workspace

#### H2. Refactor transaction detail/edit permissions
- disable edit/delete for non-creator in group
- show record creator
- DoD: UI matches permission model

#### H3. Implement receipt upload to Storage
- upload image
- create attachment metadata
- DoD: receipt lives in cloud

#### H4. Implement receipt download/cache
- local cached path management
- DoD: attachment usable cross-device

---

### Epic I: Category and Budget UX

#### I1. Refactor category management by role
- group member read-only
- owner editable
- DoD: UI lock dung role

#### I2. Refactor budget management by role
- group member read-only
- owner editable
- DoD: UI lock dung role

#### I3. Update import/export scope
- export current workspace only
- import current workspace only
- restrict group import to owner
- DoD: import/export semantics dung

---

### Epic J: Reports and Filters

#### J1. Add report filter by member
- `all members`
- `me only`
- `specific member`
- DoD: filters work for group workspace

#### J2. Update calendar/monthly summary queries
- workspace-aware
- optional member filter
- DoD: summaries dung du lieu

#### J3. Budget/report integration review
- ensure budgets read-only for members in groups
- DoD: report calculations consistent

---

### Epic K: Testing

#### K1. SQL policy tests
- verify select/update restrictions
- owner/member scenarios
- DoD: no data leakage

#### K2. Auth bootstrap tests
- signup creates profile + personal workspace + membership
- DoD: backend bootstrap stable

#### K3. Drift migration tests
- old schema data migrated safely
- DoD: regression-safe

#### K4. Repository isolation tests
- workspace scoping
- creator scoping
- DoD: no cross-workspace access

#### K5. Sync unit tests
- enqueue/create/update/delete
- conflict handling
- soft delete handling
- DoD: sync core logic tested

#### K6. Widget tests
- auth gate
- workspace switcher
- role-based edit lock
- DoD: critical UI behavior covered

#### K7. End-to-end manual test script
- signup
- create personal data
- login on second device
- create group
- invite member
- member sees but cannot edit others' transactions
- DoD: release checklist exists

---

## Thu Tu Trien Khai Khuyen Dung

1. Supabase schema + RLS
2. Auth/session Flutter
3. Workspace state
4. Drift schema refactor + migration
5. Workspace-aware repositories/providers
6. Sync engine cho personal workspace
7. Group workspace + invites
8. Role-based UI restrictions
9. Attachments
10. Reports by member
11. Hardening tests

---

## Diem Nen Giu Ky Luat Khi Implement

- Khong them bang `accounts` hay `tags` luc nay neu chua co roadmap gan
- Khong dung global providers khong co `workspaceId`
- Khong hard delete trong app flow
- Khong de category/budget group editable boi member
- Khong de owner sua transaction cua member khac o v1
- Khong load tat ca transaction roi loc memory cho report lau dai
