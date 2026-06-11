import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/app_settings.dart';
import '../services/settings_service.dart';
import '../services/tilt_monitor_service.dart';
import '../widgets/scaffold_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppSettings _settings = const AppSettings();
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final s = await SettingsService.load();
    final r = await TiltMonitorService.isRunning();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _running = r;
    });
  }

  Future<void> _toggleMonitoring(bool turnOn) async {
    try {
      if (turnOn) {
        // Ask runtime permissions on Android 13+. Wrap each in try so one
        // denied permission doesn't blow up the whole flow.
        if (Platform.isAndroid) {
          try {
            await Permission.notification.request();
          } catch (_) {}
          try {
            await Permission.ignoreBatteryOptimizations.request();
          } catch (_) {}
          if (_settings.useFloatingOverlay) {
            try {
              final granted =
                  await FlutterOverlayWindow.isPermissionGranted();
              if (!granted) {
                await FlutterOverlayWindow.requestPermission();
              }
            } catch (_) {}
          }
        }
        final updated = _settings.copyWith(monitoringEnabled: true);
        await SettingsService.save(updated);
        await TiltMonitorService.start();
      } else {
        final updated = _settings.copyWith(monitoringEnabled: false);
        await SettingsService.save(updated);
        await TiltMonitorService.stop();
      }
    } catch (e, st) {
      // Show the error to the user instead of crashing.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start monitoring: $e'),
            duration: const Duration(seconds: 6),
            backgroundColor: Colors.redAccent.shade700,
          ),
        );
      }
      // Print to logcat too — visible via `adb logcat | grep flutter`.
      debugPrint('Toggle failed: $e\n$st');
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Neck Alert'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                await Navigator.pushNamed(context, '/settings');
                _refresh();
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _IntroCard(),
                const SizedBox(height: 18),
                _StatusCard(
                  running: _running,
                  threshold: _settings.thresholdSeconds,
                  onToggle: _toggleMonitoring,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.bar_chart,
                        label: 'Analytics',
                        onTap: () => Navigator.pushNamed(context, '/analytics'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.history,
                        label: 'History',
                        onTap: () => Navigator.pushNamed(context, '/history'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.info_outline,
                        label: 'Why it matters',
                        onTap: () =>
                            Navigator.pushNamed(context, '/instructions'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.tune,
                        label: 'Settings',
                        onTap: () async {
                          await Navigator.pushNamed(context, '/settings');
                          _refresh();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Protect your neck.',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Holding a phone in a near-horizontal position is a strong '
            'indicator that your neck is bent forward. This app aims to alert '
            'you when your neck has been bent for too long while using your '
            'phone — so you can straighten up and avoid long-term strain.',
            style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool running;
  final int threshold;
  final ValueChanged<bool> onToggle;
  const _StatusCard(
      {required this.running, required this.threshold, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: running
            ? Colors.green.withOpacity(0.18)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: running ? Colors.greenAccent : Colors.white24, width: 1.4),
      ),
      child: Row(
        children: [
          Icon(running ? Icons.check_circle : Icons.pause_circle,
              color: running ? Colors.greenAccent : Colors.white70, size: 42),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(running ? 'Monitoring active' : 'Monitoring paused',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Alert after $threshold seconds of tilt',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Switch(value: running, onChanged: onToggle),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
