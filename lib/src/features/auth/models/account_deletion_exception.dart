import 'package:flutter_money_management/src/features/auth/models/account_deletion_blocker.dart';

class SharedWorkspaceMembershipException implements Exception {
  const SharedWorkspaceMembershipException(this.workspaces);

  final List<AccountDeletionBlocker> workspaces;
}
