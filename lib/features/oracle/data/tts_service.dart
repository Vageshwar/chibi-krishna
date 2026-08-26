import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Wraps flutter_tts. Device TTS doesn't expose real viseme/amplitude data
/// on most platforms, so mouth movement is a timed envelope (random values
/// while speech is active, zeroed on completion) — matches PRD v3 §10's
/// "envelope is fine" allowance.
class TtsService {
  // Slightly raised from flutter_tts's neutral 1.0 to read younger — matches
  // the persona ("playful Bal Leela, roughly 6-8 in tone", PRD v3 §1). Free,
  // on-device lever; no paid voice vendor needed for this. Valid range is
  // roughly 0.5-2.0 depending on platform; stayed conservative to avoid a
  // cartoonish/chipmunk effect.
  static const double _pitch = 1.2;

  final FlutterTts _tts = FlutterTts();
  Timer? _envelopeTimer;
  final Random _random = Random();
  Map<String, String>? _hindiVoice;
  Map<String, String>? _englishVoice;

  /// Enumerates on-device voices for hi/en locales and logs them, so running
  /// on a real Android/iOS device (not web — getVoices/setVoice are
  /// unsupported there, per flutter_tts's own docs) shows what's actually
  /// available in the console. If a voice name looks like a higher-quality
  /// one (Android's Google TTS commonly suffixes enhanced voices with
  /// "-network" vs "-local" — a naming *pattern* observed in the wild, not a
  /// guaranteed API contract), prefer it; otherwise leave the platform
  /// default alone rather than guess wrong. Report back what you see in the
  /// console and we can hardcode a specific voice once we know real names.
  Future<void> initialize() async {
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) {
        debugPrint('TtsService: getVoices returned non-list ($voices) — leaving platform default voice.');
        return;
      }
      final entries = voices.whereType<Map>().map((v) => v.map((k, val) => MapEntry(k.toString(), val.toString()))).toList();

      final hindiCandidates = entries.where((v) => (v['locale'] ?? '').toLowerCase().startsWith('hi')).toList();
      final englishCandidates = entries.where((v) => (v['locale'] ?? '').toLowerCase().startsWith('en')).toList();

      debugPrint('TtsService: ${hindiCandidates.length} hi-* voices: $hindiCandidates');
      debugPrint('TtsService: ${englishCandidates.length} en-* voices (showing first 10): ${englishCandidates.take(10).toList()}');

      _hindiVoice = _pickBestVoice(hindiCandidates);
      _englishVoice = _pickBestVoice(englishCandidates);
      debugPrint('TtsService: selected hi voice: $_hindiVoice, en voice: $_englishVoice');
    } catch (e) {
      debugPrint('TtsService: voice enumeration not supported on this platform ($e) — using platform default voice.');
    }
  }

  Map<String, String>? _pickBestVoice(List<Map<String, String>> candidates) {
    if (candidates.isEmpty) return null;
    final networkVoice = candidates.where((v) => (v['name'] ?? '').toLowerCase().contains('network'));
    if (networkVoice.isNotEmpty) return networkVoice.first;
    return null; // no confident pick — leave platform default rather than guess
  }

  Future<void> speak({
    required String text,
    required bool isHindi,
    required VoidCallback onStart,
    required void Function(double jawOpen) onJawOpen,
    required VoidCallback onDone,
  }) async {
    // Rebinding each call is cheap and keeps this correct even if a future
    // caller ever passes call-specific closures instead of stable ones.
    _bindHandlers(onStart, onJawOpen, onDone);

    await _tts.setLanguage(isHindi ? 'hi-IN' : 'en-IN');
    final preferredVoice = isHindi ? _hindiVoice : _englishVoice;
    if (preferredVoice != null) {
      try {
        await _tts.setVoice(preferredVoice);
      } catch (e) {
        debugPrint('TtsService: setVoice($preferredVoice) failed, using default: $e');
      }
    }
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(_pitch);
    await _tts.speak(text);
  }

  void _bindHandlers(VoidCallback onStart, void Function(double) onJawOpen, VoidCallback onDone) {
    _tts.setStartHandler(() {
      // Fire onStart here, not before speak() is called — this is the first
      // signal that audio is actually about to play, same as onJawOpen below.
      onStart();
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
