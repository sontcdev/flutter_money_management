-- ============================================================================
-- 03_seed_demo_data.sql — demo/fake data for manual testing
-- ----------------------------------------------------------------------------
-- Run by hand in the Supabase SQL Editor, AFTER 01_create_schema.sql and
-- 02_add_wallets.sql.
--
-- Seeds one workspace with wallets, categories, ~3 months of transactions
-- (including transfers) and a couple of budgets.
--
-- Idempotent: every row it writes is tagged metadata->>'seed' = 'demo'.
-- Re-running wipes the seeded transactions and budgets and rebuilds them, so
-- the data refreshes instead of duplicating. Wallets and categories are
-- inserted once and then reused (a same-named one you already have wins).
-- Rows you created by hand are never touched.
--
-- Amounts are stored in minor units: 1 VND = 100 minor. 50.000 ₫ = 5000000.
--
-- CONFIG: set v_user_email below to the account you log in with, or leave it
-- null to pick the oldest profile in the database.
-- ============================================================================

do $$
declare
  v_user_email    text := null;  -- e.g. 'tcson.dev@gmail.com'

  v_user_id       uuid;
  v_workspace_id  uuid;

  -- Wallets
  v_cash          uuid;
  v_bank          uuid;
  v_ewallet       uuid;
  v_credit        uuid;
  v_savings       uuid;

  -- Expense categories
  v_food          uuid;
  v_transport     uuid;
  v_shopping      uuid;
  v_bills         uuid;
  v_fun           uuid;
  v_health        uuid;

  -- Income categories
  v_salary        uuid;
  v_bonus         uuid;

  v_month_offset  int;
  v_month_start   timestamptz;
  v_day           int;
  v_i             int;
begin
  -- --------------------------------------------------------------------------
  -- Resolve the target user and workspace
  -- --------------------------------------------------------------------------
  if v_user_email is null then
    select id into v_user_id from public.profiles order by created_at limit 1;
  else
    select id into v_user_id from public.profiles where email = v_user_email;
  end if;

  if v_user_id is null then
    raise exception 'No profile found. Sign in through the app once, then re-run.';
  end if;

  select id into v_workspace_id
  from public.workspaces
  where owner_user_id = v_user_id
    and deleted_at is null
    and status = 'active'
  order by case when type = 'personal' then 0 else 1 end, created_at
  limit 1;

  if v_workspace_id is null then
    raise exception 'No active workspace found for user %', v_user_id;
  end if;

  raise notice 'Seeding workspace % for user %', v_workspace_id, v_user_id;

  -- --------------------------------------------------------------------------
  -- Wipe the previous seed run (hard delete: this is throwaway demo data).
  -- Wallets and categories are deliberately kept: transactions you added by
  -- hand may point at them, and the inserts below reuse them anyway.
  -- --------------------------------------------------------------------------
  delete from public.transactions
   where workspace_id = v_workspace_id and metadata->>'seed' = 'demo';
  delete from public.budgets
   where workspace_id = v_workspace_id and metadata->>'seed' = 'demo';

  -- --------------------------------------------------------------------------
  -- Wallets. "Tiền mặt" usually already exists — 02_add_wallets.sql creates it
  -- during the backfill — so we insert on conflict do nothing and then look the
  -- row up by name, reusing whatever is already there.
  -- --------------------------------------------------------------------------
  insert into public.wallets (
    workspace_id, name, normalized_name, wallet_type, icon_name, color_value,
    opening_balance_minor, is_default, sort_order,
    created_by_user_id, updated_by_user_id, metadata
  )
  values
    (v_workspace_id, 'Tiền mặt', '', 'cash', 'wallet', 'FF00884B',
      200000000,
      -- Only claim the default slot when the workspace has none yet.
      not exists (
        select 1 from public.wallets
        where workspace_id = v_workspace_id and is_default and deleted_at is null
      ),
      0, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
    (v_workspace_id, 'Vietcombank', '', 'bank', 'account_balance', 'FF1E6FD9',
      1500000000, false, 1, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
    (v_workspace_id, 'Ví MoMo', '', 'ewallet', 'phone_android', 'FFD82D8B',
      50000000, false, 2, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
    -- Credit cards open in the red: a negative opening balance is a debt.
    (v_workspace_id, 'Thẻ tín dụng', '', 'credit_card', 'credit_card', 'FFB3261E',
      -300000000, false, 3, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
    (v_workspace_id, 'Tiết kiệm', '', 'savings', 'savings', 'FFF2A93B',
      5000000000, false, 4, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb)
  on conflict do nothing;

  select id into v_cash    from public.wallets where workspace_id = v_workspace_id and normalized_name = 'tiền mặt'     and deleted_at is null;
  select id into v_bank    from public.wallets where workspace_id = v_workspace_id and normalized_name = 'vietcombank'  and deleted_at is null;
  select id into v_ewallet from public.wallets where workspace_id = v_workspace_id and normalized_name = 'ví momo'      and deleted_at is null;
  select id into v_credit  from public.wallets where workspace_id = v_workspace_id and normalized_name = 'thẻ tín dụng' and deleted_at is null;
  select id into v_savings from public.wallets where workspace_id = v_workspace_id and normalized_name = 'tiết kiệm'    and deleted_at is null;

  -- --------------------------------------------------------------------------
  -- Categories. Same story as wallets: reuse a same-named category if the
  -- workspace already has one.
  -- --------------------------------------------------------------------------
  insert into public.categories (
    workspace_id, name, normalized_name, type, icon_name, color_value,
    sort_order, created_by_user_id, updated_by_user_id, metadata
  )
  values
    (v_workspace_id, 'Ăn uống',    '', 'expense', 'restaurant',      'FFE8590C', 0, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
    (v_workspace_id, 'Đi lại',     '', 'expense', 'directions_car',  'FF1E6FD9', 1, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
    (v_workspace_id, 'Mua sắm',    '', 'expense', 'shopping_bag',    'FFD82D8B', 2, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
    (v_workspace_id, 'Hóa đơn',    '', 'expense', 'receipt_long',    'FF7B5EA7', 3, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
    (v_workspace_id, 'Giải trí',   '', 'expense', 'movie',           'FFF2A93B', 4, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
    (v_workspace_id, 'Sức khỏe',   '', 'expense', 'favorite',        'FFB3261E', 5, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
    (v_workspace_id, 'Lương',      '', 'income',  'payments',        'FF00884B', 6, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
    (v_workspace_id, 'Thưởng',     '', 'income',  'card_giftcard',   'FF00A36C', 7, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb)
  on conflict do nothing;

  select id into v_food      from public.categories where workspace_id = v_workspace_id and normalized_name = 'ăn uống'  and deleted_at is null;
  select id into v_transport from public.categories where workspace_id = v_workspace_id and normalized_name = 'đi lại'   and deleted_at is null;
  select id into v_shopping  from public.categories where workspace_id = v_workspace_id and normalized_name = 'mua sắm'  and deleted_at is null;
  select id into v_bills     from public.categories where workspace_id = v_workspace_id and normalized_name = 'hóa đơn'  and deleted_at is null;
  select id into v_fun       from public.categories where workspace_id = v_workspace_id and normalized_name = 'giải trí' and deleted_at is null;
  select id into v_health    from public.categories where workspace_id = v_workspace_id and normalized_name = 'sức khỏe' and deleted_at is null;
  select id into v_salary    from public.categories where workspace_id = v_workspace_id and normalized_name = 'lương'    and deleted_at is null;
  select id into v_bonus     from public.categories where workspace_id = v_workspace_id and normalized_name = 'thưởng'   and deleted_at is null;

  if v_cash is null or v_bank is null or v_ewallet is null or v_credit is null
     or v_savings is null or v_food is null or v_transport is null
     or v_shopping is null or v_bills is null or v_fun is null
     or v_health is null or v_salary is null or v_bonus is null then
    raise exception 'Could not resolve every wallet/category. Did 02_add_wallets.sql run?';
  end if;

  -- --------------------------------------------------------------------------
  -- Transactions: current month plus the two before it.
  -- --------------------------------------------------------------------------
  for v_month_offset in 0..2 loop
    v_month_start := date_trunc('month', now()) - make_interval(months => v_month_offset);

    -- Salary lands in the bank on the 5th.
    insert into public.transactions (
      workspace_id, category_id, wallet_id, amount_minor, currency_code,
      transaction_type, transaction_at, note,
      created_by_user_id, updated_by_user_id, metadata
    ) values (
      v_workspace_id, v_salary, v_bank, 2500000000, 'VND',
      'income', v_month_start + interval '4 days 9 hours', 'Lương tháng',
      v_user_id, v_user_id, '{"seed":"demo"}'::jsonb
    );

    -- A quarterly-ish bonus, only on the oldest month.
    if v_month_offset = 2 then
      insert into public.transactions (
        workspace_id, category_id, wallet_id, amount_minor, currency_code,
        transaction_type, transaction_at, note,
        created_by_user_id, updated_by_user_id, metadata
      ) values (
        v_workspace_id, v_bonus, v_bank, 800000000, 'VND',
        'income', v_month_start + interval '14 days 10 hours', 'Thưởng dự án',
        v_user_id, v_user_id, '{"seed":"demo"}'::jsonb
      );
    end if;

    -- Daily-ish food spending from cash and e-wallet.
    for v_i in 1..14 loop
      v_day := 1 + (v_i * 2) % 27;
      insert into public.transactions (
        workspace_id, category_id, wallet_id, amount_minor, currency_code,
        transaction_type, transaction_at, note,
        created_by_user_id, updated_by_user_id, metadata
      ) values (
        v_workspace_id, v_food,
        case when v_i % 3 = 0 then v_ewallet else v_cash end,
        (30000 + (v_i * 13711) % 60000) * 100, 'VND',
        'expense',
        v_month_start + make_interval(days => v_day, hours => 12),
        case when v_i % 3 = 0 then 'Đặt đồ ăn' else 'Cơm trưa' end,
        v_user_id, v_user_id, '{"seed":"demo"}'::jsonb
      );
    end loop;

    -- Transport, shopping, fun, health: a handful each, spread across wallets.
    for v_i in 1..6 loop
      v_day := 2 + (v_i * 4) % 26;
      insert into public.transactions (
        workspace_id, category_id, wallet_id, amount_minor, currency_code,
        transaction_type, transaction_at, note,
        created_by_user_id, updated_by_user_id, metadata
      ) values
        (v_workspace_id, v_transport, v_cash,
          (20000 + (v_i * 17351) % 50000) * 100, 'VND', 'expense',
          v_month_start + make_interval(days => v_day, hours => 8),
          'Xăng xe', v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
        (v_workspace_id, v_shopping, v_credit,
          (150000 + (v_i * 131071) % 400000) * 100, 'VND', 'expense',
          v_month_start + make_interval(days => v_day, hours => 15),
          'Mua sắm online', v_user_id, v_user_id, '{"seed":"demo"}'::jsonb);
    end loop;

    for v_i in 1..3 loop
      v_day := 6 + (v_i * 7) % 20;
      insert into public.transactions (
        workspace_id, category_id, wallet_id, amount_minor, currency_code,
        transaction_type, transaction_at, note,
        created_by_user_id, updated_by_user_id, metadata
      ) values
        (v_workspace_id, v_fun, v_ewallet,
          (80000 + (v_i * 67891) % 200000) * 100, 'VND', 'expense',
          v_month_start + make_interval(days => v_day, hours => 20),
          'Xem phim', v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
        (v_workspace_id, v_health, v_bank,
          (120000 + (v_i * 104729) % 300000) * 100, 'VND', 'expense',
          v_month_start + make_interval(days => v_day, hours => 17),
          'Khám sức khỏe', v_user_id, v_user_id, '{"seed":"demo"}'::jsonb);
    end loop;

    -- Fixed bills paid from the bank account.
    insert into public.transactions (
      workspace_id, category_id, wallet_id, amount_minor, currency_code,
      transaction_type, transaction_at, note,
      created_by_user_id, updated_by_user_id, metadata
    ) values
      (v_workspace_id, v_bills, v_bank, 450000000, 'VND', 'expense',
        v_month_start + interval '9 days 10 hours', 'Tiền nhà',
        v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
      (v_workspace_id, v_bills, v_bank, 120000000, 'VND', 'expense',
        v_month_start + interval '11 days 10 hours', 'Điện nước',
        v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
      (v_workspace_id, v_bills, v_bank, 22000000, 'VND', 'expense',
        v_month_start + interval '12 days 10 hours', 'Internet + điện thoại',
        v_user_id, v_user_id, '{"seed":"demo"}'::jsonb);

    -- ------------------------------------------------------------------------
    -- Transfers: money moving between wallets. These must NOT show up in the
    -- income/expense totals — that is exactly what they are here to prove.
    -- ------------------------------------------------------------------------
    insert into public.transactions (
      workspace_id, category_id, wallet_id, to_wallet_id, amount_minor,
      currency_code, transaction_type, transaction_at, note,
      created_by_user_id, updated_by_user_id, metadata
    ) values
      -- ATM withdrawal: bank -> cash
      (v_workspace_id, null, v_bank, v_cash, 300000000, 'VND', 'transfer',
        v_month_start + interval '5 days 11 hours', 'Rút ATM',
        v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
      -- Top up the e-wallet: bank -> MoMo
      (v_workspace_id, null, v_bank, v_ewallet, 100000000, 'VND', 'transfer',
        v_month_start + interval '6 days 9 hours', 'Nạp tiền MoMo',
        v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
      -- Pay off the credit card: bank -> credit card
      (v_workspace_id, null, v_bank, v_credit, 180000000, 'VND', 'transfer',
        v_month_start + interval '17 days 14 hours', 'Thanh toán thẻ tín dụng',
        v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
      -- Put something aside: bank -> savings
      (v_workspace_id, null, v_bank, v_savings, 500000000, 'VND', 'transfer',
        v_month_start + interval '7 days 8 hours', 'Gửi tiết kiệm',
        v_user_id, v_user_id, '{"seed":"demo"}'::jsonb);
  end loop;

  -- --------------------------------------------------------------------------
  -- Budgets for the current month
  -- --------------------------------------------------------------------------
  insert into public.budgets (
    workspace_id, category_id, name, period_type, period_start, period_end,
    limit_minor, currency_code, allow_overdraft,
    created_by_user_id, updated_by_user_id, metadata
  )
  values
    (v_workspace_id, v_food, 'Ăn uống tháng này', 'monthly',
      date_trunc('month', now()),
      date_trunc('month', now()) + interval '1 month' - interval '1 second',
      100000000, 'VND', false, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
    (v_workspace_id, v_shopping, 'Mua sắm tháng này', 'monthly',
      date_trunc('month', now()),
      date_trunc('month', now()) + interval '1 month' - interval '1 second',
      200000000, 'VND', true, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb),
    (v_workspace_id, v_bills, 'Hóa đơn tháng này', 'monthly',
      date_trunc('month', now()),
      date_trunc('month', now()) + interval '1 month' - interval '1 second',
      600000000, 'VND', false, v_user_id, v_user_id, '{"seed":"demo"}'::jsonb);

  raise notice 'Done. Wallets: 5, categories: 8, budgets: 3, transactions: %',
    (select count(*) from public.transactions
      where workspace_id = v_workspace_id and metadata->>'seed' = 'demo');
end $$;

-- ============================================================================
-- Verification: expected wallet balances, computed the same way the Dart client
-- does (opening + income - expense + transfer_in - transfer_out).
-- ============================================================================
select
  w.name,
  w.wallet_type,
  to_char(w.opening_balance_minor / 100, 'FM999,999,999') as opening_vnd,
  to_char((
    w.opening_balance_minor
    + coalesce((select sum(t.amount_minor) from public.transactions t
        where t.wallet_id = w.id and t.transaction_type = 'income'   and t.deleted_at is null), 0)
    - coalesce((select sum(t.amount_minor) from public.transactions t
        where t.wallet_id = w.id and t.transaction_type = 'expense'  and t.deleted_at is null), 0)
    + coalesce((select sum(t.amount_minor) from public.transactions t
        where t.to_wallet_id = w.id and t.transaction_type = 'transfer' and t.deleted_at is null), 0)
    - coalesce((select sum(t.amount_minor) from public.transactions t
        where t.wallet_id = w.id and t.transaction_type = 'transfer'    and t.deleted_at is null), 0)
  ) / 100, 'FM999,999,999') as balance_vnd
from public.wallets w
where w.deleted_at is null
order by w.sort_order;
