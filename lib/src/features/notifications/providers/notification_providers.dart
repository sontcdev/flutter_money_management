import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/notifications/models/user_notification.dart';
import 'package:flutter_money_management/src/features/notifications/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return NotificationService(supabase);
});

final myNotificationsProvider =
    FutureProvider<List<UserNotification>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return [];
  }

  final service = ref.watch(notificationServiceProvider);
  return service.getMyNotifications();
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return 0;
  }

  final service = ref.watch(notificationServiceProvider);
  return service.getUnreadCount();
});
