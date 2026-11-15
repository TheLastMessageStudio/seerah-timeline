import 'package:audioplayers/audioplayers.dart';

/// Short sound effects only. No background player or music is ever started.
class Sfx {
  static final AudioPlayer _player = AudioPlayer();
  static bool enabled = true;
  static Future<void> _play(String file) async {
    if (!enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$file.wav'), volume: .72);
    } catch (_) {
      // Audio must never prevent a move or menu action from completing.
    }
  }
  static Future<void> tap() => _play('tap');
  static Future<void> move() => _play('move');
  static Future<void> attack() => _play('attack');
  static Future<void> impact() => _play('impact');
  static Future<void> victory() => _play('victory');
}
