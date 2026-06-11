class AlarmEvent {
  final int? id;
  final DateTime triggeredAt;
  final int sustainedSeconds;
  final double avgTiltDegrees;

  AlarmEvent({
    this.id,
    required this.triggeredAt,
    required this.sustainedSeconds,
    required this.avgTiltDegrees,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'triggeredAt': triggeredAt.millisecondsSinceEpoch,
        'sustainedSeconds': sustainedSeconds,
        'avgTiltDegrees': avgTiltDegrees,
      };

  factory AlarmEvent.fromMap(Map<String, dynamic> m) => AlarmEvent(
        id: m['id'] as int?,
        triggeredAt: DateTime.fromMillisecondsSinceEpoch(m['triggeredAt'] as int),
        sustainedSeconds: m['sustainedSeconds'] as int,
        avgTiltDegrees: (m['avgTiltDegrees'] as num).toDouble(),
      );
}
