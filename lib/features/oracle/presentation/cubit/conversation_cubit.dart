import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../stage/presentation/cubit/stage_cubit.dart';
import '../../../stage/presentation/cubit/stage_state.dart';
import '../../data/quote_repository.dart';
import '../../data/speech_service.dart';
import '../../data/tts_service.dart';
import 'conversation_state.dart';

/// MVP-08 orchestrator: idle -> listening -> thinking -> speaking -> idle.
/// No Gemini, no quota — the "answer" is always a random local quote
/// (see QuoteRepository / MVP-06). Gemini replaces the quote pick in the
/// V1 milestone (FF-01) without needing to change this state machine shape.
class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit({
    required StageCubit stageCubit,
    required SpeechService speechService,
    required TtsService ttsService,
    required QuoteRepository quoteRepository,
  })  : _stageCubit = stageCubit,
        _speechService = speechService,
        _ttsService = ttsService,
        _quoteRepository = quoteRepository,
        super(const ConversationState());

  final StageCubit _stageCubit;
  final SpeechService _speechService;
  final TtsService _ttsService;
  final QuoteRepository _quoteRepository;

  Future<void> initialize() async {
    await _quoteRepository.load();
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
    await _respond();
  }

  Future<void> submitTypedText(String text) async {
    if (text.trim().isEmpty || state.isBusy) return;
    emit(state.copyWith(isBusy: true, lastTranscript: text, emptyTryCount: 0));
    await _respond();
  }

  Future<void> _respond() async {
    _stageCubit.setAnimationState(ChibiAnimationState.thinking);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final isHindi = _speechService.isHindiLocale;
    final quote = _quoteRepository.pickRandom();
    final responseText = _quoteRepository.textFor(quote, isHindi: isHindi);
    emit(state.copyWith(lastResponseText: responseText));

    _stageCubit.setAnimationState(ChibiAnimationState.speaking);
    await _ttsService.speak(
      text: responseText,
      isHindi: isHindi,
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
