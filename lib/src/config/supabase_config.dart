// path: lib/src/config/supabase_config.dart

/// Supabase configuration
///
/// IMPORTANT: Before using, you need to:
/// 1. Create a Supabase project at https://supabase.com
/// 2. Run supabase/01_create_schema.sql in your project
/// 3. Get your project URL and anon key from project settings
/// 4. Replace the placeholder values below with your actual credentials
///
/// For production, consider using environment variables or flutter_dotenv
class SupabaseConfig {
  // Supabase project URL
  static const String supabaseUrl = 'https://jbontdnjiobhyyrcnhaf.supabase.co';

  // Supabase anon key (public key, safe for client apps)
  static const String supabaseAnonKey =
      'sb_publishable_Wu_RrpSzP55ssxQHxaXHjQ_kRw6UKqC';

  // Mobile auth callback URI.
  // Add this exact value to Supabase Auth -> URL Configuration -> Additional Redirect URLs.
  static const String mobileAuthCallbackUrl =
      'com.sontc.financeappv1://login-callback';

  /// Check if Supabase is configured
  static bool get isConfigured {
    return supabaseUrl != 'YOUR_SUPABASE_URL' &&
        supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty;
  }
}
