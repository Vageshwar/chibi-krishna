import 'package:equatable/equatable.dart';

enum ChibiAnimationState { idle, listening, thinking, speaking, blessing, greeting }

class StageState extends Equatable {
  final ChibiAnimationState animationState;
  final double jawOpen;
  final double smile;
  final double eyeBlink;
  final bool isAudioDucked;

  const StageState({
    this.animationState = ChibiAnimationState.idle,
    this.jawOpen = 0.0,
    this.smile = 0.5,
    this.eyeBlink = 0.0,
    this.isAudioDucked = false,
  });

  StageState copyWith({
    ChibiAnimationState? animationState,
    double? jawOpen,
    double? smile,
    double? eyeBlink,
    bool? isAudioDucked,
  }) {
    return StageState(
      animationState: animationState ?? this.animationState,
      jawOpen: jawOpen ?? this.jawOpen,
      smile: smile ?? this.smile,
      eyeBlink: eyeBlink ?? this.eyeBlink,
      isAudioDucked: isAudioDucked ?? this.isAudioDucked,
    );
  }

  @override
  List<Object?> get props => [
        animationState,
        jawOpen,
        smile,
        eyeBlink,
        isAudioDucked,
      ];
}
