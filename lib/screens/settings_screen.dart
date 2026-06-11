import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../models/app_settings.dart';
import '../services/alarm_service.dart';
import '../services/settings_service.dart';
import '../widgets/scaffold_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings _s = const AppSettings();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SettingsService.load();
    if (!mounted) return;
    setState(() {
      _s = s;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    await SettingsService.save(_s);
    // Notify running background service if any
    FlutterBackgroundService().invoke('settings_changed');
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Settings')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Card(
                title: 'Alert threshold',
                subtitle:
                    'How many seconds of sustained tilt before alerting.',
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _s.thresholdSeconds.toDouble(),
                        min: 15,
                        max: 300,
                        divisions: 57,
                        label: '${_s.thresholdSeconds}s',
                        onChanged: (v) => setState(() {
                          _s = _s.copyWith(thresholdSeconds: v.round());
                        }),
                        onChangeEnd: (_) => _save(),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: Text('${_s.thresholdSeconds}s',
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              _Card(
                title: 'Tilt window',
                subtitle:
                    'Tilt angles inside this range count as "neck bent". '
                    '0–${_s.minTiltDegrees}° (very flat / lying on a table) is '
                    'ignored.',
                child: Column(
                  children: [
                    _RangeRow(
                      label: 'Minimum tilt',
                      value: _s.minTiltDegrees,
                      min: 5,
                      max: 30,
                      onChanged: (v) {
                        setState(() => _s = _s.copyWith(minTiltDegrees: v));
                      },
                      onEnd: _save,
                    ),
                    _RangeRow(
                      label: 'Maximum tilt',
                      value: _s.maxTiltDegrees,
                      min: 35,
                      max: 80,
                      onChanged: (v) {
                        setState(() => _s = _s.copyWith(maxTiltDegrees: v));
                      },
                      onEnd: _save,
                    ),
                  ],
                ),
              ),
              _Card(
                title: 'Alert tone',
                subtitle: 'Pick a tone, or vibrate only.',
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: const Color(0xFF203A43),
                  value: _s.alertTone,
                  style: const TextStyle(color: Colors.white),
                  items: AlarmService.availableTones
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(_toneLabel(t)),
                          ))
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _s = _s.copyWith(alertTone: v));
                    await _save();
                  },
                ),
              ),
              _Card(
                title: 'Alert style',
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vibrate on alert',
                          style: TextStyle(color: Colors.white)),
                      value: _s.vibrateOnAlert,
                      onChanged: (v) async {
                        setState(() => _s = _s.copyWith(vibrateOnAlert: v));
                        await _save();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Play sound on alert',
                          style: TextStyle(color: Colors.white)),
                      value: _s.soundOnAlert,
                      onChanged: (v) async {
                        setState(() => _s = _s.copyWith(soundOnAlert: v));
                        await _save();
                      },
                    ),
                  ],
                ),
              ),
              _Card(
                title: 'Floating bubble (Android only)',
                subtitle: Platform.isIOS
                    ? 'iOS does not allow apps to draw over other apps. This '
                        'option is disabled on iOS.'
                    : 'Show a small colour-changing bubble that hovers over '
                        'other apps. Requires the "Display over other apps" '
                        'permission.',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show floating bubble',
                      style: TextStyle(color: Colors.white)),
                  value: _s.useFloatingOverlay && Platform.isAndroid,
                  onChanged: Platform.isIOS
                      ? null
                      : (v) async {
                          if (v) {
                            final granted =
                                await FlutterOverlayWindow.isPermissionGranted();
                            if (!granted) {
                              await FlutterOverlayWindow.requestPermission();
                            }
                          }
                          setState(() =>
                              _s = _s.copyWith(useFloatingOverlay: v));
                          await _save();
                        },
                ),
              ),
              _Card(
                title: 'Battery saver',
                subtitle:
                    'When the screen is off you are not looking at the phone, '
                    'so monitoring can safely pause. Strongly recommended.',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pause monitoring when screen is off',
                      style: TextStyle(color: Colors.white)),
                  value: _s.pauseWhenScreenOff,
                  onChanged: (v) async {
                    setState(() => _s = _s.copyWith(pauseWhenScreenOff: v));
                    await _save();
                  },
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await AlarmService.trigger(
                    vibrate: _s.vibrateOnAlert,
                    sound: _s.soundOnAlert,
                    tone: _s.alertTone,
                  );
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text('Test alert'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _toneLabel(String t) {
    switch (t) {
      case 'beep':
        return 'Beep';
      case 'chime':
        return 'Chime';
      case 'gong':
        return 'Gong';
      case 'vibrate_only':
        return 'Vibrate only (no sound)';
      default:
        return t;
    }
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _Card({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ],
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  final String label;
  final int value;
  final int min, max;
  final ValueChanged<int> onChanged;
  final VoidCallback onEnd;
  const _RangeRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            label: '$value°',
            onChanged: (v) => onChanged(v.round()),
            onChangeEnd: (_) => onEnd(),
          ),
        ),
        SizedBox(
            width: 40,
            child: Text('$value°',
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white))),
      ],
    );
  }
}
