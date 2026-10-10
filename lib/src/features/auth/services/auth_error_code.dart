import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';

String? authErrorCode(Object error) {
  final source = error is SupabaseOperationException ? error.source : error;
  return source is AuthException ? source.code : null;
}
