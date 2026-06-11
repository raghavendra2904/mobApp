import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'app.dart';
import 'services/crash_logger.dart';
import 'services/tilt_monitor_service.dart';
import 'widgets/overlay_bubble.dart';

void main() async {
  // Install the global error handlers FIRST so any later failure is recorded.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await CrashLogger.install();
    try {
      await TiltMonitorService.initialize();
    } catch (e, st) {
      await CrashLogger.log('TiltMonitorService.initialize', '$e\n$st');
    }
    runApp(const NeckAlertApp());
  }, (error, stack) {
    CrashLogger.log('top-level', '$error\n$stack');
  });
}

// Entry point for the floating overlay window (Android only).
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayBubble(),
  ));
}
