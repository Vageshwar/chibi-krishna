import 'package:equatable/equatable.dart';

enum FallbackReason { none, permissionDenied, repeatedEmptyResults }

class ConversationState extends Equatable {
  final bool isBusy;
  final bool isListening;
  final String? lastTranscript;
  final String? lastResponseText;
  final int emptyTryCount;
  final bool showTextInput;
  final FallbackReason fallbackReason;

  /// True when the daily voice quota (FF-04) just ran out and the UI should
  /// show the Support sheet (FF-06). The pending question is held internally
  /// by ConversationCubit, not in state — resolveSupportPrompt() answers it.
  final bool needsSupportPrompt;

  /// Live partial transcript while listening — cleared once the turn ends.
  final String liveTranscript;

  /// Raw mic sound level while listening (platform-dependent scale, roughly
  /// dB), for a "something is being recorded" visual. 0 when not listening.
  final double micLevel;

  const ConversationState({
    this.isBusy = false,
    this.isListening = false,
    this.lastTranscript,
    this.lastResponseText,
    this.emptyTryCount = 0,
    this.showTextInput = false,
    this.fallbackReason = FallbackReason.none,
    this.liveTranscript = '',
    this.micLevel = 0.0,
    this.needsSupportPrompt = false,
  });

  ConversationState copyWith({
    bool? isBusy,
    bool? isListening,
    String? lastTranscript,
    String? lastResponseText,
    int? emptyTryCount,
    bool? showTextInput,
    FallbackReason? fallbackReason,
    String? liveTranscript,
    double? micLevel,
    bool? needsSupportPrompt,
  }) {
    return ConversationState(
      isBusy: isBusy ?? this.isBusy,
      isListening: isListening ?? this.isListening,
      lastTranscript: lastTranscript ?? this.lastTranscript,
      lastResponseText: lastResponseText ?? this.lastResponseText,
      emptyTryCount: emptyTryCount ?? this.emptyTryCount,
      showTextInput: showTextInput ?? this.showTextInput,
      fallbackReason: fallbackReason ?? this.fallbackReason,
      liveTranscript: liveTranscript ?? this.liveTranscript,
      micLevel: micLevel ?? this.micLevel,
      needsSupportPrompt: needsSupportPrompt ?? this.needsSupportPrompt,
    );
  }

  @override
  List<Object?> get props => [
        isBusy,
        isListening,
        lastTranscript,
        lastResponseText,
        emptyTryCount,
        showTextInput,
        fallbackReason,
        liveTranscript,
        micLevel,
        needsSupportPrompt,
      ];
}
