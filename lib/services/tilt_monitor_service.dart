import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/alarm_event.dart';
import '../models/app_settings.dart';
import 'alarm_service.dart';
import 'history_service.dart';
import 'settings_service.dart';

/// Continuously samples the accelerometer (at low rate to save battery),
/// computes tilt-from-horizontal, and triggers an alarm if the device stays
/// in the "neck-bent" tilt window past a configurable threshold.
class TiltMonitorService {
  static const _notifChannelId = 'neck_alert_fg';
  static const _notifChannelName = 'Neck Alert background monitor';

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        isForegroundMode: true,
        autoStart: false,
        notificationChannelId: _notifChannelId,
        initialNotificationTitle: 'Neck Alert',
        initialNotificationContent: 'Watching your posture',
        foregroundServiceNotificationId: 8421,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<void> start() async {
    final service = FlutterBackgroundService();
    final running = await service.isRunning();
    if (!running) await service.startService();
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stop');
  }

  static Future<bool> isRunning() => FlutterBackgroundService().isRunning();
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  // iOS gives us limited background time — return true to keep alive briefly.
  return true;
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  AppSettings settings = await SettingsService.load();

  // Tilt-state machine
  DateTime? sustainedSince;
  double tiltSum = 0;
  int tiltSamples = 0;
  DateTime? lastAlarm;
  bool overlayActive = false;
  Color lastOverlayColor = Colors.green;

  service.on('stop').listen((_) async {
    await AlarmService.stop();
    if (overlayActive) {
      try {
        await FlutterOverlayWindow.closeOverlay();
      } catch (_) {}
    }
    await service.stopSelf();
  });

  service.on('settings_changed').listen((event) async {
    settings = await SettingsService.load();
  });

  // ~5 Hz sampling: SensorInterval.normalInterval is ~200ms.
  final sub = accelerometerEventStream(
          samplingPeriod: SensorInterval.normalInterval)
      .listen((event) async {
    final tilt = _tiltFromHorizontalDegrees(event.x, event.y, event.z);

    final inNeckBend =
        tilt >= settings.minTiltDegrees && tilt <= settings.maxTiltDegrees;

    if (inNeckBend) {
      sustainedSince ??= DateTime.now();
      tiltSum += tilt;
      tiltSamples += 1;
      final elapsed =
          DateTime.now().difference(sustainedSince!).inSeconds;

      // Update overlay color: green -> amber -> red as time approaches threshold.
      final newColor = _overlayColor(elapsed, settings.thresholdSeconds);
      if (settings.useFloatingOverlay && Platform.isAndroid) {
        await _ensureOverlay(overlayActive: overlayActive, color: newColor,
            onActivated: () => overlayActive = true);
        if (newColor != lastOverlayColor) {
          try {
            await FlutterOverlayWindow.shareData({
              'color': newColor.value,
              'elapsed': elapsed,
              'threshold': settings.thresholdSeconds,
            });
          } catch (_) {}
          lastOverlayColor = newColor;
        }
      }

      if (elapsed >= settings.thresholdSeconds) {
        // Throttle: don't re-trigger more than once every threshold-window.
        final now = DateTime.now();
        if (lastAlarm == null ||
            now.difference(lastAlarm!).inSeconds >= settings.thresholdSeconds) {
          lastAlarm = now;
          final avg = tiltSamples == 0 ? tilt : tiltSum / tiltSamples;
          await HistoryService.insert(AlarmEvent(
            triggeredAt: now,
            sustainedSeconds: elapsed,
            avgTiltDegrees: avg,
          ));
          await AlarmService.trigger(
            vibrate: settings.vibrateOnAlert,
            sound: settings.soundOnAlert,
            tone: settings.alertTone,
          );
          service.invoke('alarm_fired', {
            'time': now.millisecondsSinceEpoch,
            'tilt': avg,
            'sustained': elapsed,
          });
        }
      }

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Neck Alert active',
          content:
              'Tilt ${tilt.toStringAsFixed(0)}° • holding ${elapsed}s / ${settings.thresholdSeconds}s',
        );
      }
    } else {
      // Out of neck-bend window — reset accumulator.
      sustainedSince = null;
      tiltSum = 0;
      tiltSamples = 0;
      if (overlayActive && lastOverlayColor != Colors.green) {
        try {
          await FlutterOverlayWindow.shareData({
            'color': Colors.green.value,
            'elapsed': 0,
            'threshold': settings.thresholdSeconds,
          });
        } catch (_) {}
        lastOverlayColor = Colors.green;
      }
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Neck Alert active',
          content: 'Posture looks fine (${tilt.toStringAsFixed(0)}°)',
        );
      }
    }
  });

  service.on('shutdown').listen((_) async {
    await sub.cancel();
    await service.stopSelf();
  });
}

Future<void> _ensureOverlay({
  required bool overlayActive,
  required Color color,
  required VoidCallback onActivated,
}) async {
  if (overlayActive) return;
  try {
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted) return;
    final running = await FlutterOverlayWindow.isActive();
    if (!running) {
      await FlutterOverlayWindow.showOverlay(
        height: 140,
        width: 140,
        alignment: OverlayAlignment.centerRight,
        flag: OverlayFlag.defaultFlag,
        enableDrag: true,
        overlayTitle: 'Neck Alert',
        overlayContent: 'monitoring',
      );
    }
    onActivated();
  } catch (_) {}
}

Color _overlayColor(int elapsedSec, int thresholdSec) {
  final ratio = (elapsedSec / thresholdSec).clamp(0.0, 1.0);
  if (ratio < 0.5) return Colors.green;
  if (ratio < 0.9) return Colors.amber;
  return Colors.redAccent;
}

/// Returns the angle in degrees between the phone's screen-normal (Z axis)
/// and the world's vertical. A phone lying flat face-up reads (0, 0, 9.8) so
/// angle ≈ 0°. A phone held perfectly upright (portrait or landscape) reads
/// gravity mostly in X or Y, so angle ≈ 90°.
///
/// We define "tilt from horizontal" as 90° - that angle, so:
///   flat on table  -> 90° (excluded as upright? no — see below)
/// Wait: we want "0° = phone parallel to ground (face up/down)" and
/// "90° = phone perfectly vertical". So:
///   tilt = angle between gravity vector and screen plane
///        = 90° - angle(gravity, Z axis).
/// When flat, gravity is along Z, angle(g, Z)=0°, tilt = 90° (perpendicular to ground)
/// ...that's the opposite convention from what the user wants.
///
/// The user says: 0-10° = horizontal = ignore.  10-50° = "near horizontal" = neck bent.
/// 50-90° = upright = fine. So "tilt" here means "angle of the screen plane
/// away from horizontal (flat)".
///
/// If gravity vector is g and screen-normal is +Z, then the angle between the
/// SCREEN PLANE and the HORIZONTAL PLANE equals the angle between the screen
/// normal (Z) and vertical (gravity direction). Flat phone => normal == gravity
/// direction => angle = 0°. Upright phone => normal is horizontal => angle = 90°.
/// So we want:  tilt = angle(gravity, Z) in degrees.
double _tiltFromHorizontalDegrees(double ax, double ay, double az) {
  final gMag = math.sqrt(ax * ax + ay * ay + az * az);
  if (gMag < 1e-3) return 0;
  // Use |az| so face-down and face-up are equivalent.
  final cosTheta = (az.abs() / gMag).clamp(0.0, 1.0);
  final rad = math.acos(cosTheta);
  return rad * 180.0 / math.pi;
}
