class AppSettings {
  final int thresholdSeconds;        // e.g. 70
  final int minTiltDegrees;          // e.g. 10  (below this is ignored)
  final int maxTiltDegrees;          // e.g. 50  (above this = upright = ignored)
  final String alertTone;            // 'beep', 'chime', 'gong', or 'vibrate_only'
  final bool useFloatingOverlay;     // Android only
  final bool monitoringEnabled;      // master on/off
  final bool vibrateOnAlert;
  final bool soundOnAlert;
  final bool pauseWhenScreenOff;

  const AppSettings({
    this.thresholdSeconds = 70,
    this.minTiltDegrees = 10,
    this.maxTiltDegrees = 50,
    this.alertTone = 'beep',
    this.useFloatingOverlay = false,
    this.monitoringEnabled = false,
    this.vibrateOnAlert = true,
    this.soundOnAlert = true,
    this.pauseWhenScreenOff = true,
  });

  AppSettings copyWith({
    int? thresholdSeconds,
    int? minTiltDegrees,
    int? maxTiltDegrees,
    String? alertTone,
    bool? useFloatingOverlay,
    bool? monitoringEnabled,
    bool? vibrateOnAlert,
    bool? soundOnAlert,
    bool? pauseWhenScreenOff,
  }) =>
      AppSettings(
        thresholdSeconds: thresholdSeconds ?? this.thresholdSeconds,
        minTiltDegrees: minTiltDegrees ?? this.minTiltDegrees,
        maxTiltDegrees: maxTiltDegrees ?? this.maxTiltDegrees,
        alertTone: alertTone ?? this.alertTone,
        useFloatingOverlay: useFloatingOverlay ?? this.useFloatingOverlay,
        monitoringEnabled: monitoringEnabled ?? this.monitoringEnabled,
        vibrateOnAlert: vibrateOnAlert ?? this.vibrateOnAlert,
        soundOnAlert: soundOnAlert ?? this.soundOnAlert,
        pauseWhenScreenOff: pauseWhenScreenOff ?? this.pauseWhenScreenOff,
      );

  Map<String, dynamic> toMap() => {
        'thresholdSeconds': thresholdSeconds,
        'minTiltDegrees': minTiltDegrees,
        'maxTiltDegrees': maxTiltDegrees,
        'alertTone': alertTone,
        'useFloatingOverlay': useFloatingOverlay,
        'monitoringEnabled': monitoringEnabled,
        'vibrateOnAlert': vibrateOnAlert,
        'soundOnAlert': soundOnAlert,
        'pauseWhenScreenOff': pauseWhenScreenOff,
      };

  factory AppSettings.fromMap(Map<String, dynamic> m) => AppSettings(
        thresholdSeconds: m['thresholdSeconds'] ?? 70,
        minTiltDegrees: m['minTiltDegrees'] ?? 10,
        maxTiltDegrees: m['maxTiltDegrees'] ?? 50,
        alertTone: m['alertTone'] ?? 'beep',
        useFloatingOverlay: m['useFloatingOverlay'] ?? false,
        monitoringEnabled: m['monitoringEnabled'] ?? false,
        vibrateOnAlert: m['vibrateOnAlert'] ?? true,
        soundOnAlert: m['soundOnAlert'] ?? true,
        pauseWhenScreenOff: m['pauseWhenScreenOff'] ?? true,
      );
}
