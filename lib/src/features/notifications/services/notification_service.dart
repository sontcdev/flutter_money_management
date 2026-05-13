import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/src/features/notifications/models/user_notification.dart';

class NotificationService {
  const NotificationService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<UserNotification>> getMyNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    dynamic response;
    try {
      response = await _supabase.rpc(
        'get_my_notifications',
        params: {
          'p_limit': limit,
          'p_offset': offset,
        },
      );
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') {
        debugPrint('Warning: get_my_notifications function not found');
        return [];
      }
      rethrow;
    }

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(UserNotification.fromMap)
        .toList();
  }

  Future<int> getUnreadCount() async {
    dynamic response;
    try {
      response = await _supabase.rpc(
        'get_my_unread_notification_count',
        params: const <String, dynamic>{},
      );
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') {
        debugPrint(
          'Warning: get_my_unread_notification_count function not found',
        );
        return 0;
      }
      rethrow;
    }

    return (response as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _supabase.rpc(
        'mark_notification_read',
        params: {'p_notification_id': notificationId},
      );
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') {
        debugPrint('Warning: mark_notification_read function not found');
        return;
      }
      rethrow;
    }
  }
}
