// path: lib/src/config/supabase_config.dart

/// Supabase configuration
///
/// IMPORTANT: Before using, you need to:
/// 1. Create a Supabase project at https://supabase.com
/// 2. Apply migrations from supabase/migrations/ to your project
/// 3. Get your project URL and anon key from project settings
/// 4. Replace the placeholder values below with your actual credentials
///
/// For production, consider using environment variables or flutter_dotenv
class SupabaseConfig {
  // Supabase project URL
  static const String supabaseUrl = 'https://mbocotktllisnoskomyo.supabase.co';

  // Supabase anon key (public key, safe for client apps)
  static const String supabaseAnonKey =
      'sb_publishable_1zD9ijsIW0Vq6MptK1ljdw_6ot8DKof';

  /// Check if Supabase is configured
  static bool get isConfigured {
    return supabaseUrl != 'YOUR_SUPABASE_URL' &&
        supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty;
  }
}
