import 'package:flutter_bloc/flutter_bloc.dart';
import 'stage_state.dart';

class StageCubit extends Cubit<StageState> {
  StageCubit() : super(const StageState());

  void setAnimationState(ChibiAnimationState animState) {
    emit(state.copyWith(
      animationState: animState,
      isAudioDucked: animState == ChibiAnimationState.speaking,
    ));
  }

  void updateLipSync(double jawOpenValue) {
    final clamped = jawOpenValue.clamp(0.0, 1.0);
    emit(state.copyWith(jawOpen: clamped));
  }

  void setExpression({double? smile, double? eyeBlink}) {
    emit(state.copyWith(
      smile: smile ?? state.smile,
      eyeBlink: eyeBlink ?? state.eyeBlink,
    ));
  }

  void reset() {
    emit(const StageState());
  }
}
