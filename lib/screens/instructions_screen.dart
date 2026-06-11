import 'package:flutter/material.dart';
import '../widgets/scaffold_background.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Why it matters')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              _Section(
                title: 'What this app does',
                body:
                    'It watches the tilt of your phone using the built-in '
                    'accelerometer. When the screen is held in a near-horizontal '
                    'position (between 10° and 50° from flat, in either portrait '
                    'or landscape), it assumes you are looking down at the device — '
                    'which usually means your neck is bent forward. If this posture '
                    'is held longer than the threshold you configure, the app '
                    'alerts you with vibration, sound, or a colour-changing '
                    'floating bubble (Android only).',
              ),
              _Section(
                title: 'Why neck posture matters',
                body:
                    'The average adult head weighs about 5 kg. Tilting it forward '
                    'multiplies the load on your cervical spine: at 30° of '
                    'forward bend the load on your neck is roughly 18 kg, and at '
                    '60° it climbs to nearly 27 kg. Sustained over hours per day, '
                    'this dramatically accelerates wear on the spine.',
              ),
              _Section(
                title: 'Side effects of a chronically bent neck',
                body:
                    '• Chronic neck and upper-back pain ("tech neck").\n'
                    '• Tension headaches and migraines triggered by tight '
                    'sub-occipital muscles.\n'
                    '• Rounded shoulders and a forward-head posture that becomes '
                    'permanent over time.\n'
                    '• Reduced lung capacity, because a hunched torso compresses '
                    'the diaphragm.\n'
                    '• Pinched nerves, leading to tingling or numbness in the arms '
                    'and hands.\n'
                    '• Accelerated disc degeneration and early-onset cervical '
                    'spondylosis.\n'
                    '• Jaw tension (TMJ) and disrupted sleep from referred '
                    'muscular pain.\n'
                    '• Lower mood and energy — posture has measurable effects on '
                    'cortisol and self-reported wellbeing.',
              ),
              _Section(
                title: 'How to use the app',
                body:
                    '1. On the home screen, switch monitoring ON.\n'
                    '2. Grant the notification and (on Android) overlay '
                    'permissions when prompted.\n'
                    '3. In Settings, adjust the threshold (default 70 s), pick an '
                    'alert tone or vibration pattern, and choose whether the '
                    'floating bubble should appear on Android.\n'
                    '4. Use your phone as usual. If you stay tilted for too long, '
                    'the app will alert you.\n'
                    '5. Open the Analytics page to see how your habits trend over '
                    'the past two weeks.',
              ),
              _Section(
                title: 'Tips for a healthier neck',
                body:
                    '• Bring the phone up to eye level instead of bending your '
                    'neck down to it.\n'
                    '• Take a 30-second posture reset every 20 minutes.\n'
                    '• Strengthen the deep neck flexors with chin-tuck exercises.\n'
                    '• Stretch the chest, upper traps, and levator scapulae daily.\n'
                    '• Consider a phone stand for long reading sessions.',
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 15, height: 1.45)),
        ],
      ),
    );
  }
}
