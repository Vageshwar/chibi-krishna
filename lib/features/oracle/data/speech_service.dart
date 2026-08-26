import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Wraps speech_to_text: requests mic permission on initialize(), picks
/// hi-IN by default per PRD v3 §5, falling back to en-IN/en-US if the
/// device/browser doesn't offer Hindi recognition.
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  String _selectedLocaleId = 'en_US';

  bool get isAvailable => _isAvailable;
  bool get isHindiLocale => _selectedLocaleId.toLowerCase().startsWith('hi');

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (e) => debugPrint('SpeechService error: ${e.errorMsg}'),
        onStatus: (s) => debugPrint('SpeechService status: $s'),
      );
    } catch (e) {
      debugPrint('SpeechService initialize() note: $e');
      _isAvailable = false;
    }
    if (_isAvailable) {
      _selectedLocaleId = await _pickLocale();
      debugPrint('SpeechService: using locale "$_selectedLocaleId"');
    }
    return _isAvailable;
  }

  Future<String> _pickLocale() async {
    try {
      final locales = await _speech.locales();
      bool has(String id) => locales.any((l) => l.localeId.toLowerCase() == id.toLowerCase());
      if (has('hi_IN')) return 'hi_IN';
      if (has('en_IN')) return 'en_IN';
      if (has('en_US')) return 'en_US';
      final system = await _speech.systemLocale();
      return system?.localeId ?? 'en_US';
    } catch (e) {
      debugPrint('SpeechService locale lookup note: $e');
      return 'en_US';
    }
  }

  /// Starts one listening turn. [onFinalResult] fires once, with the final
  /// transcript (empty string if the recognizer heard nothing) — the pause
  /// that ends the turn is speech_to_text's own pauseFor detection (2s of
  /// silence auto-finalizes, with a 20s hard cap either way). Was cut to
  /// 1.2s to reduce dead air (see #36), but that read as cutting people off
  /// mid-thought — 2s is the floor the user asked for after trying 1.2s.
  /// [onPartialResult] fires repeatedly while listening, for live captions.
  /// [onSoundLevel] fires with a raw (platform-dependent, roughly-dB) level
  /// while listening, for a "something is being recorded" visual.
  Future<void> listen({
    required void Function(String text) onFinalResult,
    void Function(String text)? onPartialResult,
    void Function(double level)? onSoundLevel,
  }) async {
    if (!_isAvailable) {
      onFinalResult('');
      return;
    }
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onFinalResult(result.recognizedWords.trim());
        } else {
          onPartialResult?.call(result.recognizedWords.trim());
        }
      },
      onSoundLevelChange: onSoundLevel,
      listenOptions: SpeechListenOptions(
        localeId: _selectedLocaleId,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> stop() => _speech.stop();
}
