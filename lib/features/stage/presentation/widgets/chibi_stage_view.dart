import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sceneview_flutter/sceneview_flutter.dart';
import '../cubit/stage_cubit.dart';
import '../cubit/stage_state.dart';

class ChibiStageView extends StatefulWidget {
  const ChibiStageView({super.key});

  @override
  State<ChibiStageView> createState() => _ChibiStageViewState();
}

class _ChibiStageViewState extends State<ChibiStageView> with SingleTickerProviderStateMixin {
  late AnimationController _auraController;
  final SceneViewController _sceneViewController = SceneViewController();

  @override
  void initState() {
    super.initState();
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _auraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StageCubit, StageState>(
      builder: (context, state) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Divine Golden Aura Background Gradient
            AnimatedBuilder(
              animation: _auraController,
              builder: (context, child) {
                final isBlessing = state.animationState == ChibiAnimationState.blessing;
                final opacity = isBlessing 
                    ? 0.8 
                    : 0.3 + (0.15 * _auraController.value);
                
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: isBlessing ? 0.95 : 0.75,
                      colors: [
                        const Color(0xFFFFD700).withValues(alpha: opacity), // Divine Gold
                        const Color(0xFFFF8C00).withValues(alpha: opacity * 0.5), // Deep Amber
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),

            // SceneView 3D Model Renderer
            Positioned.fill(
              child: SceneView(_sceneViewController),
            ),

            // State & Lip Sync Overlay HUD
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Card(
                color: const Color(0xFF1E1E2C).withValues(alpha: 0.85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFFFD700), width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getIconForState(state.animationState),
                            color: const Color(0xFFFFD700),
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _getStateLabel(state.animationState),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: state.jawOpen,
                        backgroundColor: Colors.white10,
                        color: const Color(0xFFFFD700),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mouth Morph Shape (JawOpen): ${(state.jawOpen * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getIconForState(ChibiAnimationState state) {
    switch (state) {
      case ChibiAnimationState.idle:
        return Icons.music_note_rounded;
      case ChibiAnimationState.thinking:
        return Icons.psychology_rounded;
      case ChibiAnimationState.speaking:
        return Icons.record_voice_over_rounded;
      case ChibiAnimationState.blessing:
        return Icons.auto_awesome_rounded;
    }
  }

  String _getStateLabel(ChibiAnimationState state) {
    switch (state) {
      case ChibiAnimationState.idle:
        return 'Chibi Krishna — Idle (Playing Flute)';
      case ChibiAnimationState.thinking:
        return 'Chibi Krishna — Contemplating Wisdom';
      case ChibiAnimationState.speaking:
        return 'Chibi Krishna — Speaking Gita Guidance';
      case ChibiAnimationState.blessing:
        return 'Chibi Krishna — Abhaya Mudra Blessing';
    }
  }
}
