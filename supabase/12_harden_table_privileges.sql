begin;

revoke all on table
  public.profiles,
  public.workspaces,
  public.workspace_members,
  public.workspace_invites,
  public.user_notifications,
  public.categories,
  public.wallets,
  public.transactions,
  public.transaction_attachments,
  public.budgets,
  public.activity_logs,
  public.user_workspace_preferences,
  public.error_reports,
  public.recurring_transactions,
  public.recurring_transaction_occurrences
from public, anon;

revoke truncate, references, trigger, maintain on table
  public.profiles,
  public.workspaces,
  public.workspace_members,
  public.workspace_invites,
  public.user_notifications,
  public.categories,
  public.wallets,
  public.transactions,
  public.transaction_attachments,
  public.budgets,
  public.activity_logs,
  public.user_workspace_preferences,
  public.error_reports,
  public.recurring_transactions,
  public.recurring_transaction_occurrences
from authenticated;

commit;
