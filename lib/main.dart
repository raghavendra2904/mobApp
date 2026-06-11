import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'app.dart';
import 'services/tilt_monitor_service.dart';
import 'widgets/overlay_bubble.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TiltMonitorService.initialize();
  runApp(const NeckAlertApp());
}

// Entry point for the floating overlay window (Android only).
// flutter_overlay_window spawns a separate engine and calls this.
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayBubble(),
  ));
}
