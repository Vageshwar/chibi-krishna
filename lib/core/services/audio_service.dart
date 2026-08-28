import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mutedPrefKey = 'bg_music_muted';

/// #41: observes app lifecycle directly (rather than relying on a widget to
/// forward lifecycle events) so the background loop pauses whenever the app
/// leaves the foreground — previously nothing stopped it, so it kept
/// playing with the screen off or the app backgrounded.
class BackgroundAudioService with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();
  static const double normalVolume = 0.35;
  static const double duckedVolume = 0.08;
  bool _isInitialized = false;
  bool _isForeground = true;
  bool _userMuted = false;

  bool get isMuted => _userMuted;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _userMuted = prefs.getBool(_mutedPrefKey) ?? false;

      await _player.setAsset('assets/audio/bg_flute_loop.mp3');
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(normalVolume);
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
      if (!_userMuted) _player.play();
    } catch (e) {
      // Fallback for environment without audio hardware or mock testing
      debugPrint('Audio initialization note: $e');
    }
  }

  /// #40: user-facing mute toggle, persisted across app restarts.
  Future<void> setMuted(bool muted) async {
    _userMuted = muted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mutedPrefKey, muted);
    } catch (e) {
      debugPrint('Audio mute-preference save note: $e');
    }
    if (!_isInitialized) return;
    if (muted) {
      _player.pause();
    } else if (_isForeground) {
      _player.play();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _isForeground = true;
        if (!_userMuted) _player.play();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isForeground = false;
        _player.pause();
        break;
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
    WidgetsBinding.instance.removeObserver(this);
    await _player.dispose();
  }
}
