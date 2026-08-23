import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Wraps flutter_tts. Device TTS doesn't expose real viseme/amplitude data
/// on most platforms, so mouth movement is a timed envelope (random values
/// while speech is active, zeroed on completion) — matches PRD v3 §10's
/// "envelope is fine" allowance.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  Timer? _envelopeTimer;
  final Random _random = Random();

  Future<void> speak({
    required String text,
    required bool isHindi,
    required void Function(double jawOpen) onJawOpen,
    required VoidCallback onDone,
  }) async {
    // Rebinding each call is cheap and keeps this correct even if a future
    // caller ever passes call-specific closures instead of stable ones.
    _bindHandlers(onJawOpen, onDone);

    await _tts.setLanguage(isHindi ? 'hi-IN' : 'en-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  void _bindHandlers(void Function(double) onJawOpen, VoidCallback onDone) {
    _tts.setStartHandler(() {
      _envelopeTimer?.cancel();
      _envelopeTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
        onJawOpen(0.2 + _random.nextDouble() * 0.7);
      });
    });

    _tts.setCompletionHandler(() {
      _envelopeTimer?.cancel();
      onJawOpen(0.0);
      onDone();
    });

    _tts.setErrorHandler((msg) {
      debugPrint('TtsService error: $msg');
      _envelopeTimer?.cancel();
      onJawOpen(0.0);
      onDone();
    });
  }

  Future<void> stop() async {
    _envelopeTimer?.cancel();
    await _tts.stop();
  }

  void dispose() {
    _envelopeTimer?.cancel();
  }
}
