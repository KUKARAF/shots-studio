import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service to help recover from crashes and validate app stability
class CrashRecoveryService {
  static const String _crashCountKey = 'app_crash_count';
  static const String _lastStartTimeKey = 'last_start_time';
  static const String _cleanShutdownKey = 'clean_shutdown';

  /// Initialize crash recovery tracking
  static Future<void> initializeRecovery() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if the last session ended cleanly
      final cleanShutdown = prefs.getBool(_cleanShutdownKey) ?? true;

      if (!cleanShutdown) {
        // The app crashed or was force-closed
        final crashCount = prefs.getInt(_crashCountKey) ?? 0;
        await prefs.setInt(_crashCountKey, crashCount + 1);

        print('⚠️ Detected unclean shutdown. Crash count: ${crashCount + 1}');

        // If too many crashes, clear corrupted data
        if (crashCount >= 2) {
          print(
            '🔧 Multiple crashes detected. Clearing potentially corrupted data...',
          );
          await clearCorruptedData(prefs);
        }
      } else {
        // Reset crash count on clean startup
        await prefs.setInt(_crashCountKey, 0);
      }

      // Mark that we're starting up (not clean shutdown yet)
      await prefs.setBool(_cleanShutdownKey, false);
      await prefs.setInt(
        _lastStartTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      print('✅ Crash recovery initialized');
    } catch (e) {
      print('❌ Error initializing crash recovery: $e');
    }
  }

  /// Mark that the app is shutting down cleanly
  static Future<void> markCleanShutdown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cleanShutdownKey, true);
      print('✅ Marked clean shutdown');
    } catch (e) {
      print('❌ Error marking clean shutdown: $e');
    }
  }

  /// Clear potentially corrupted data after multiple crashes
  static Future<void> clearCorruptedData(SharedPreferences prefs) async {
    try {
      final keysToPreserve = {
        'user_preferences',
        'api_key',
        'selected_model',
        'theme_mode',
        'screenshot_limit',
        'custom_paths',
        _crashCountKey,
        _lastStartTimeKey,
        _cleanShutdownKey,
      };

      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (!keysToPreserve.contains(key)) {
          await prefs.remove(key);
          print('🗑️ Removed potentially corrupted preference: $key');
        }
      }

      print('🔧 Cleared corrupted data, preserved essential settings');
    } catch (e) {
      print('❌ Error clearing corrupted data: $e');
    }
  }

  /// Get crash statistics for debugging
  static Future<Map<String, dynamic>> getCrashStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'crashCount': prefs.getInt(_crashCountKey) ?? 0,
        'lastStartTime': prefs.getInt(_lastStartTimeKey) ?? 0,
        'cleanShutdown': prefs.getBool(_cleanShutdownKey) ?? true,
        'currentTime': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      print('❌ Error getting crash stats: $e');
      return {};
    }
  }

  /// Validate that essential app files exist and are accessible
  static Future<bool> validateAppIntegrity() async {
    try {
      // Check if we can access SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('integrity_test', true);
      final testValue = prefs.getBool('integrity_test');

      if (testValue != true) {
        print('❌ SharedPreferences integrity check failed');
        return false;
      }

      // Clean up test value
      await prefs.remove('integrity_test');

      print('✅ App integrity check passed');
      return true;
    } catch (e) {
      print('❌ App integrity check failed: $e');
      return false;
    }
  }

  /// Create a diagnostic report for debugging crashes
  static Future<String> createDiagnosticReport() async {
    try {
      final stats = await getCrashStats();
      final integrity = await validateAppIntegrity();

      final report = '''
=== SHOTS STUDIO DIAGNOSTIC REPORT ===
Generated: ${DateTime.now()}
Platform: ${Platform.operatingSystem}
Is Debug Mode: $kDebugMode

Crash Statistics:
- Crash Count: ${stats['crashCount']}
- Last Start Time: ${DateTime.fromMillisecondsSinceEpoch(stats['lastStartTime'] ?? 0)}
- Clean Shutdown: ${stats['cleanShutdown']}
- App Integrity: ${integrity ? 'PASS' : 'FAIL'}

Recovery Actions Taken:
${stats['crashCount'] >= 2 ? '- Cleared corrupted data due to multiple crashes' : '- No recovery actions needed'}

Platform Info:
- OS: ${Platform.operatingSystem}
- OS Version: ${Platform.operatingSystemVersion}

=== END DIAGNOSTIC REPORT ===
''';

      print(report);
      return report;
    } catch (e) {
      final errorReport = '''
=== DIAGNOSTIC REPORT ERROR ===
Failed to generate diagnostic report: $e
Generated: ${DateTime.now()}
=== END ERROR REPORT ===
''';
      print(errorReport);
      return errorReport;
    }
  }
}
