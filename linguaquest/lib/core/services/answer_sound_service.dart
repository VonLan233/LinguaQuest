import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AnswerSoundService {
  AnswerSoundService._();

  static final AudioPlayer _player = AudioPlayer();
  static final Map<String, Uint8List> _cache = {};

  static Future<void> play({
    required bool isCorrect,
    required bool enabled,
  }) async {
    if (!enabled) return;
    final asset = isCorrect
        ? 'lib/assets/audio/correct.mp3'
        : 'lib/assets/audio/wrong.mp3';
    try {
      final bytes = await _assetBytes(asset);
      await _player.stop();
      await _player.play(BytesSource(bytes));
    } catch (error) {
      debugPrint('Failed to play answer sound: $error');
    }
  }

  static Future<Uint8List> _assetBytes(String asset) async {
    final cached = _cache[asset];
    if (cached != null) return cached;
    final data = await rootBundle.load(asset);
    final bytes = Uint8List.sublistView(data);
    _cache[asset] = bytes;
    return bytes;
  }
}
