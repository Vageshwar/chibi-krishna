import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../monetization/presentation/cubit/quota_cubit.dart';
import '../../../stage/presentation/cubit/stage_cubit.dart';
import '../../../stage/presentation/cubit/stage_state.dart';
import '../../data/quote_repository.dart';
import '../../data/speech_service.dart';
import '../../data/tts_service.dart';
import 'conversation_state.dart';

/// MVP-08 orchestrator: idle -> listening -> thinking -> speaking -> idle.
/// No Gemini yet — the "answer" is always a random local quote (see
/// QuoteRepository / MVP-06). Gemini replaces the quote pick in the V1
/// milestone (FF-01) without needing to change this state machine shape:
/// _respond's `isDowngraded: false` branch is where that call goes: today
/// it's identical to the downgraded branch (both just pick a local quote),
/// but the split already exists so wiring Gemini in later doesn't touch the
/// quota logic at all.
///
/// Quota (FF-04) only gates voice turns — a transcript that produces a sent
/// query. Typed fallback text is uncapped, per FF-04's own spec.
class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit({
    required StageCubit stageCubit,
    required SpeechService speechService,
    required TtsService ttsService,
    required QuoteRepository quoteRepository,
    required QuotaCubit quotaCubit,
  })  : _stageCubit = stageCubit,
        _speechService = speechService,
        _ttsService = ttsService,
        _quoteRepository = quoteRepository,
        _quotaCubit = quotaCubit,
        super(const ConversationState());

  final StageCubit _stageCubit;
  final SpeechService _speechService;
  final TtsService _ttsService;
  final QuoteRepository _quoteRepository;
  final QuotaCubit _quotaCubit;

  // Set when a voice turn is waiting on the Support-sheet decision (quota
  // exhausted). Not part of ConversationState — it's plumbing, not something
  // any widget renders directly.
  bool _pendingVoiceQuery = false;

  Future<void> initialize() async {
    await _quoteRepository.load();
    await _ttsService.initialize();
    await _quotaCubit.initialize();
    final available = await _speechService.initialize();
    if (!available) {
      emit(state.copyWith(showTextInput: true, fallbackReason: FallbackReason.permissionDenied));
    }
  }

  Future<void> startListening() async {
    if (state.isBusy) return;
    if (!_speechService.isAvailable) {
      emit(state.copyWith(showTextInput: true, fallbackReason: FallbackReason.permissionDenied));
      return;
    }

    emit(state.copyWith(isBusy: true, isListening: true, liveTranscript: '', micLevel: 0.0));
    _stageCubit.setAnimationState(ChibiAnimationState.listening);
    await _speechService.listen(
      onFinalResult: _handleFinalTranscript,
      onPartialResult: _handlePartialTranscript,
      onSoundLevel: _handleSoundLevel,
    );
  }

  void _handlePartialTranscript(String text) {
    if (!state.isListening) return;
    emit(state.copyWith(liveTranscript: text));
  }

  void _handleSoundLevel(double level) {
    if (!state.isListening) return;
    // Raw level is a platform-dependent, roughly-dB scale (commonly ~-2 to
    // ~10) — normalized here purely for a decorative equalizer, not measured
    // for accuracy.
    final normalized = ((level + 2) / 12).clamp(0.0, 1.0);
    emit(state.copyWith(micLevel: normalized));
  }

  Future<void> _handleFinalTranscript(String text) async {
    emit(state.copyWith(isListening: false, lastTranscript: text, liveTranscript: '', micLevel: 0.0));

    if (text.trim().isEmpty) {
      final tries = state.emptyTryCount + 1;
      _stageCubit.setAnimationState(ChibiAnimationState.idle);
      if (tries >= 2) {
        emit(state.copyWith(
          emptyTryCount: tries,
          isBusy: false,
          showTextInput: true,
          fallbackReason: FallbackReason.repeatedEmptyResults,
        ));
      } else {
        emit(state.copyWith(emptyTryCount: tries, isBusy: false));
      }
      return;
    }

    emit(state.copyWith(emptyTryCount: 0));

    final consumed = await _quotaCubit.tryConsumeVoiceTurn();
    if (consumed) {
      await _respond(isDowngraded: false);
      return;
    }
    // Quota's out — hand off to the UI to show the Support sheet.
    // resolveSupportPrompt() picks up from here once the user decides.
    _pendingVoiceQuery = true;
    emit(state.copyWith(needsSupportPrompt: true));
  }

  /// Called by the UI once the Support sheet closes. [watchedAd] is true
  /// only after a completed rewarded-ad view (never a plain dismiss).
  Future<void> resolveSupportPrompt({required bool watchedAd}) async {
    final hadPendingQuery = _pendingVoiceQuery;
    _pendingVoiceQuery = false;
    emit(state.copyWith(needsSupportPrompt: false));
    if (!hadPendingQuery) return;

    if (watchedAd) {
      await _quotaCubit.grantRewardTurns();
      await _quotaCubit.tryConsumeVoiceTurn();
      await _respond(isDowngraded: false);
    } else {
      // Declined the ad: don't hard-block — still answer, just from the
      // local quote pool instead of the real oracle (see issue #16).
      await _respond(isDowngraded: true);
    }
  }

  /// Typed fallback is uncapped by design (FF-04) — never touches quota.
  Future<void> submitTypedText(String text) async {
    if (text.trim().isEmpty || state.isBusy) return;
    emit(state.copyWith(isBusy: true, lastTranscript: text, emptyTryCount: 0));
    await _respond(isDowngraded: false);
  }

  Future<void> _respond({required bool isDowngraded}) async {
    _stageCubit.setAnimationState(ChibiAnimationState.thinking);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // isDowngraded is unused today — both branches pick a local quote,
    // since Gemini (FF-01) doesn't exist yet. Once it does, !isDowngraded
    // calls Gemini with the pending transcript; isDowngraded keeps this path.
    final isHindi = _speechService.isHindiLocale;
    final quote = _quoteRepository.pickRandom();
    final responseText = _quoteRepository.textFor(quote, isHindi: isHindi);
    emit(state.copyWith(lastResponseText: responseText));

    await _ttsService.speak(
      text: responseText,
      isHindi: isHindi,
      onStart: () => _stageCubit.setAnimationState(ChibiAnimationState.speaking),
      onJawOpen: _stageCubit.updateLipSync,
      onDone: () {
        _stageCubit.setAnimationState(ChibiAnimationState.idle);
        emit(state.copyWith(isBusy: false));
      },
    );
  }

  void dismissTextFallback() {
    emit(state.copyWith(showTextInput: false, fallbackReason: FallbackReason.none));
  }

  @override
  Future<void> close() {
    _ttsService.dispose();
    return super.close();
  }
}
