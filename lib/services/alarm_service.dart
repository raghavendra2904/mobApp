import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class AlarmService {
  static final AudioPlayer _player = AudioPlayer();

  /// Distinct vibration patterns so the user can recognize a neck-alert
  /// vs other notifications. Pattern: wait, vib, wait, vib, ...
  static const List<int> _neckPattern = [0, 400, 150, 400, 150, 700];

  static Future<void> trigger({
    required bool vibrate,
    required bool sound,
    required String tone,
  }) async {
    if (vibrate) {
      final has = await Vibration.hasVibrator() ?? false;
      if (has) {
        // Custom pattern + amplitude where supported.
        await Vibration.vibrate(
          pattern: _neckPattern,
          intensities: const [0, 255, 0, 255, 0, 255],
        );
      }
    }
    if (sound && tone != 'vibrate_only') {
      final asset = _toneAsset(tone);
      try {
        await _player.stop();
        await _player.play(AssetSource(asset), volume: 1.0);
      } catch (_) {
        // Asset may be missing on first install; vibration still fires.
      }
    }
  }

  static String _toneAsset(String tone) {
    switch (tone) {
      case 'chime':
        return 'sounds/chime.mp3';
      case 'gong':
        return 'sounds/gong.mp3';
      case 'beep':
      default:
        return 'sounds/beep.mp3';
    }
  }

  static Future<void> stop() async {
    await _player.stop();
    await Vibration.cancel();
  }

  static const List<String> availableTones = [
    'beep',
    'chime',
    'gong',
    'vibrate_only',
  ];
}
