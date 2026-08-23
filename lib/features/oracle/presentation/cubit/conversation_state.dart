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

  const ConversationState({
    this.isBusy = false,
    this.isListening = false,
    this.lastTranscript,
    this.lastResponseText,
    this.emptyTryCount = 0,
    this.showTextInput = false,
    this.fallbackReason = FallbackReason.none,
  });

  ConversationState copyWith({
    bool? isBusy,
    bool? isListening,
    String? lastTranscript,
    String? lastResponseText,
    int? emptyTryCount,
    bool? showTextInput,
    FallbackReason? fallbackReason,
  }) {
    return ConversationState(
      isBusy: isBusy ?? this.isBusy,
      isListening: isListening ?? this.isListening,
      lastTranscript: lastTranscript ?? this.lastTranscript,
      lastResponseText: lastResponseText ?? this.lastResponseText,
      emptyTryCount: emptyTryCount ?? this.emptyTryCount,
      showTextInput: showTextInput ?? this.showTextInput,
      fallbackReason: fallbackReason ?? this.fallbackReason,
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
      ];
}
