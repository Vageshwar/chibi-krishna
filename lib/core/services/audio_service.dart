import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class BackgroundAudioService {
  final AudioPlayer _player = AudioPlayer();
  static const double normalVolume = 0.35;
  static const double duckedVolume = 0.08;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _player.setAsset('assets/audio/bg_flute_loop.mp3');
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(normalVolume);
      _player.play();
      _isInitialized = true;
    } catch (e) {
      // Fallback for environment without audio hardware or mock testing
      debugPrint('Audio initialization note: $e');
    }
  }

  Future<void> setAudioDucked(bool duck) async {
    if (!_isInitialized) return;
    final targetVolume = duck ? duckedVolume : normalVolume;
    final currentVolume = _player.volume;
    
    // Smooth volume fade over 300ms
    const steps = 10;
    final diff = (targetVolume - currentVolume) / steps;
    for (int i = 0; i < steps; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      await _player.setVolume(currentVolume + (diff * (i + 1)));
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
