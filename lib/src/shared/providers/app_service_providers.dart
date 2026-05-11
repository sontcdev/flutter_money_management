import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/src/services/app_lock_service.dart';
import 'package:flutter_money_management/src/services/email_persistence_service.dart';
import 'package:flutter_money_management/src/services/error_report_service.dart';
import 'package:flutter_money_management/src/shared/providers/preferences_provider.dart';

final appLockServiceProvider = Provider<AppLockService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppLockService(prefs);
});

final emailPersistenceServiceProvider =
    Provider<EmailPersistenceService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return EmailPersistenceService(prefs);
});

final errorReportServiceProvider = Provider<ErrorReportService>((ref) {
  return ErrorReportService(Supabase.instance.client);
});
