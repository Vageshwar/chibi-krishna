import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

const _languagePrefKey = 'voice_language_preference';

/// User-facing override for which language Krishna listens in — surfaced in
/// the About screen. `auto` keeps the existing device-locale-based pick
/// (see `_pickLocale`); `hindi`/`english` force that language regardless of
/// what the device's system locale is.
enum VoiceLanguagePreference { auto, hindi, english }

/// Wraps speech_to_text: requests mic permission on initialize(), picks
/// hi-IN by default per PRD v3 §5, falling back to en-IN/en-US if the
/// device/browser doesn't offer Hindi recognition — unless overridden by
/// [VoiceLanguagePreference].
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  String _selectedLocaleId = 'en_US';
  VoiceLanguagePreference _preference = VoiceLanguagePreference.auto;

  // The current turn's onFinalResult, held so the global onError handler
  // below (registered once in initialize(), not per-listen()) can resolve
  // the turn if the recognizer errors out instead of finishing cleanly —
  // without this, a mid-listen error (e.g. Android's error_busy/
  // error_speech_timeout, more likely after several back-to-back turns)
  // never calls onFinalResult, and the caller is stuck in isListening/
  // isBusy forever since nothing else resets that state.
  void Function(String text)? _pendingFinalResult;
  Timer? _watchdogTimer;

  // Hard ceiling above listenFor + pauseFor (see listen()) — a safety net
  // for the case where the recognizer hangs without ever firing onResult
  // *or* onError (both already handled above), so the caller is never
  // stuck longer than this regardless of what the native side does.
  static const _watchdogDuration = Duration(seconds: 30);

  bool get isAvailable => _isAvailable;
  bool get isHindiLocale => _selectedLocaleId.toLowerCase().startsWith('hi');
  VoiceLanguagePreference get languagePreference => _preference;

  Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_languagePrefKey);
      _preference = VoiceLanguagePreference.values.firstWhere(
        (p) => p.name == saved,
        orElse: () => VoiceLanguagePreference.auto,
      );
    } catch (e) {
      debugPrint('SpeechService language-preference load note: $e');
    }
    try {
      _isAvailable = await _speech.initialize(
        onError: (e) {
          debugPrint('SpeechService error: ${e.errorMsg}');
          _resolvePending('');
        },
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

  /// #7-adjacent: manual override from the About screen. Persists and takes
  /// effect on the next `listen()` call — no restart needed. Keeps `auto`'s
  /// existing device-locale-based behavior as the default (untouched).
  Future<void> setLanguagePreference(VoiceLanguagePreference preference) async {
    _preference = preference;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languagePrefKey, preference.name);
    } catch (e) {
      debugPrint('SpeechService language-preference save note: $e');
    }
    if (_isAvailable) {
      _selectedLocaleId = await _pickLocale();
      debugPrint('SpeechService: using locale "$_selectedLocaleId" (preference: ${preference.name})');
    }
  }

  Future<String> _pickLocale() async {
    try {
      final locales = await _speech.locales();
      bool has(String id) => locales.any((l) => l.localeId.toLowerCase() == id.toLowerCase());
      switch (_preference) {
        case VoiceLanguagePreference.hindi:
          if (has('hi_IN')) return 'hi_IN';
          return 'en_US';
        case VoiceLanguagePreference.english:
          if (has('en_IN')) return 'en_IN';
          if (has('en_US')) return 'en_US';
          return 'en_US';
        case VoiceLanguagePreference.auto:
          if (has('hi_IN')) return 'hi_IN';
          if (has('en_IN')) return 'en_IN';
          if (has('en_US')) return 'en_US';
          final system = await _speech.systemLocale();
          return system?.localeId ?? 'en_US';
      }
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
    _pendingFinalResult = onFinalResult;
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(_watchdogDuration, () {
      debugPrint('SpeechService: watchdog fired — recognizer never resolved, forcing reset');
      _resolvePending('');
    });
    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _resolvePending(result.recognizedWords.trim());
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
    } catch (e) {
      // Defense in depth: _speech.listen() itself throwing (rather than
      // reporting through onError) would otherwise leave the caller stuck
      // the same way — see _pendingFinalResult's doc comment above.
      debugPrint('SpeechService.listen() note: $e');
      _resolvePending('');
    }
  }

  /// Resolves the current turn exactly once, however it ends (clean final
  /// result, recognizer error, thrown exception, or the watchdog timing
  /// out) — whichever fires first wins, the rest are no-ops.
  void _resolvePending(String text) {
    _watchdogTimer?.cancel();
    final pending = _pendingFinalResult;
    _pendingFinalResult = null;
    pending?.call(text);
  }

  Future<void> stop() => _speech.stop();
}
