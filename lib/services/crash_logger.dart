import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Captures every uncaught Flutter / Dart / platform error to a file the user
/// can view from the home screen ("Crash logs" tile). This means you can
/// diagnose crashes on the phone itself without needing `adb logcat` from a PC.
class CrashLogger {
  static File? _file;
  static const _maxBytes = 256 * 1024; // keep the log under 256 KB

  static Future<File> _logFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    _file = File(p.join(dir.path, 'crash_log.txt'));
    if (!await _file!.exists()) {
      await _file!.create(recursive: true);
    }
    return _file!;
  }

  /// Install global handlers. Call this at the very top of `main()`, BEFORE
  /// anything else that could throw.
  static Future<void> install() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      _write('FlutterError', details.exceptionAsString(), details.stack);
      // Also print to stderr (visible via adb) for completeness.
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _write('PlatformDispatcher', error.toString(), stack);
      return true; // mark as handled so the app doesn't die
    };

    // Catch errors thrown in zones we run.
    runZonedGuarded(() {}, (error, stack) {
      _write('Zone', error.toString(), stack);
    });
  }

  /// Wraps `runApp` so async errors during widget building are also caught.
  static void runGuarded(void Function() body) {
    runZonedGuarded(body, (error, stack) {
      _write('runGuarded', error.toString(), stack);
    });
  }

  static Future<void> log(String tag, String message) async {
    await _write(tag, message, null);
  }

  static Future<void> _write(String tag, String message, StackTrace? stack) async {
    try {
      final f = await _logFile();
      // Trim if file got too large.
      if (await f.length() > _maxBytes) {
        await f.writeAsString('-- log truncated --\n', mode: FileMode.write);
      }
      final ts = DateTime.now().toIso8601String();
      final entry = StringBuffer()
        ..writeln('=== $ts [$tag] ===')
        ..writeln(message);
      if (stack != null) {
        entry
          ..writeln('Stack:')
          ..writeln(stack);
      }
      entry.writeln();
      await f.writeAsString(entry.toString(), mode: FileMode.append);
    } catch (_) {
      // Never let the logger itself crash the app.
    }
  }

  static Future<String> readAll() async {
    try {
      final f = await _logFile();
      final s = await f.readAsString();
      if (s.trim().isEmpty) return '(no crashes logged yet)';
      return s;
    } catch (e) {
      return 'Could not read log: $e';
    }
  }

  static Future<void> clear() async {
    try {
      final f = await _logFile();
      await f.writeAsString('');
    } catch (_) {}
  }
}
