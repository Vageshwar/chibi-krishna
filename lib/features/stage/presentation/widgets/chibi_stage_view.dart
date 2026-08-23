import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/stage_cubit.dart';
import '../cubit/stage_state.dart';

// Placeholder until the Rive rig (MVP-05) lands — swaps for a RiveAnimation
// bound to the same StageCubit state, no other code should need to change.
class ChibiStageView extends StatelessWidget {
  const ChibiStageView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StageCubit, StageState>(
      builder: (context, state) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9FCBE8), Color(0xFFCDE9C9)],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            _labelFor(state.animationState),
            style: const TextStyle(
              color: Color(0xFF2E3B2E),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  String _labelFor(ChibiAnimationState state) {
    switch (state) {
      case ChibiAnimationState.idle:
        return 'Krishna — idle';
      case ChibiAnimationState.thinking:
        return 'Krishna — thinking';
      case ChibiAnimationState.speaking:
        return 'Krishna — speaking';
      case ChibiAnimationState.blessing:
        return 'Krishna — blessing';
    }
  }
}
