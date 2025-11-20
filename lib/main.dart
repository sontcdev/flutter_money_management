// path: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'src/app.dart';

// Import sqlite3_flutter_libs to ensure native library is loaded
// This is required for Drift NativeDatabase on Android
// The library will be automatically loaded when imported
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load SQLite native library for Android
  // Note: The library is automatically loaded when the package is imported
  // The workaround function is optional and may not be available in all versions
  // Database will still work correctly without it on newer Android versions
  if (Platform.isAndroid) {
    try {
      // Try to apply workaround for older Android versions if available
      // This is optional - the library will work without it on newer Android versions
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    } catch (e) {
      // Ignore - the library will still work on most Android versions
      // The MissingPluginException is expected if the workaround isn't needed
      debugPrint('SQLite workaround not available (this is OK on newer Android): $e');
    }
  }
  
  runApp(const ProviderScope(child: App()));
}
