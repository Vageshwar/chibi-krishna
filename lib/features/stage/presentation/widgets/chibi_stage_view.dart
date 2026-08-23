import 'package:flutter/foundation.dart' show FlutterExceptionHandler;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rive/rive.dart' as rive;
import '../cubit/stage_cubit.dart';
import '../cubit/stage_state.dart';

/// Pose contract for the Rive state machine (see docs/requirements/assets_v3.md):
/// input "pose" (number) 0=idle 1=listening 2=thinking 3=speaking 4=blessing,
/// input "jawOpen" (number 0-1), trigger "blessBurst" fired on entering blessing.
/// If the loaded .riv doesn't have a matching input, that input is simply not
/// driven; if the artboard has no state machine at all, the placeholder
/// background shows instead. Check debug console on run for what was found.
class ChibiStageView extends StatefulWidget {
  const ChibiStageView({super.key});

  @override
  State<ChibiStageView> createState() => _ChibiStageViewState();
}

class _ChibiStageViewState extends State<ChibiStageView> {
  rive.RiveWidgetController? _controller;
  rive.NumberInput? _poseInput;
  rive.NumberInput? _jawOpenInput;
  rive.TriggerInput? _blessBurstInput;
  ChibiAnimationState? _lastAppliedPose;

  // Same defensive guard as before, kept in case a *different* future .riv
  // trips a new incompatibility — costs nothing when rendering is healthy.
  bool _renderBroken = false;
  FlutterExceptionHandler? _previousOnError;

  @override
  void initState() {
    super.initState();
    _installRiveErrorGuard();
    _loadRive();
  }

  void _installRiveErrorGuard() {
    _previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final fromRive = details.stack?.toString().contains('package:rive') ?? false;
      if (fromRive && !_renderBroken) {
        _renderBroken = true;
        debugPrint(
          'Rive: this artboard is throwing during rendering — falling back '
          'to the placeholder background. Details: ${details.exception}',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
      _previousOnError?.call(details);
    };
  }

  Future<void> _loadRive() async {
    try {
      await rive.RiveNative.init();
      final file = await rive.File.asset(
        'assets/rive/chibi_krishna.riv',
        riveFactory: rive.Factory.flutter,
      );
      if (file == null) {
        debugPrint('Rive: File.asset returned null for assets/rive/chibi_krishna.riv');
        return;
      }

      final artboard = file.defaultArtboard();
      if (artboard == null) {
        debugPrint('Rive: no default artboard in this file.');
        return;
      }

      if (artboard.stateMachineCount() == 0) {
        debugPrint('Rive: artboard "${artboard.name}" has no state machine — nothing to drive yet.');
        return;
      }

      final controller = rive.RiveWidgetController(file);
      for (final input in controller.stateMachine.inputs) {
        final name = input.name.toLowerCase();
        if (name == 'pose' && input is rive.NumberInput) _poseInput = input;
        if (name == 'jawopen' && input is rive.NumberInput) _jawOpenInput = input;
        if (name == 'blessburst' && input is rive.TriggerInput) _blessBurstInput = input;
      }
      debugPrint(
        'Rive: artboard "${artboard.name}", state machine "${controller.stateMachine.name}" found. '
        'pose input: ${_poseInput != null}, jawOpen input: ${_jawOpenInput != null}, '
        'blessBurst input: ${_blessBurstInput != null}. '
        'Inputs present: ${controller.stateMachine.inputs.map((i) => i.name).join(', ')}',
      );

      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e, st) {
      debugPrint('Rive: failed to load assets/rive/chibi_krishna.riv: $e\n$st');
    }
  }

  double _poseNumber(ChibiAnimationState s) {
    switch (s) {
      case ChibiAnimationState.idle:
        return 0;
      case ChibiAnimationState.listening:
        return 1;
      case ChibiAnimationState.thinking:
        return 2;
      case ChibiAnimationState.speaking:
        return 3;
      case ChibiAnimationState.blessing:
        return 4;
    }
  }

  void _applyState(StageState state) {
    if (_controller == null) return;
    _poseInput?.value = _poseNumber(state.animationState);
    _jawOpenInput?.value = state.jawOpen;
    if (state.animationState == ChibiAnimationState.blessing && _lastAppliedPose != ChibiAnimationState.blessing) {
      _blessBurstInput?.fire();
    }
    _lastAppliedPose = state.animationState;
  }

  @override
  Widget build(BuildContext context) {
    final showRive = _controller != null && !_renderBroken;
    return BlocListener<StageCubit, StageState>(
      listener: (context, state) => _applyState(state),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9FCBE8), Color(0xFFCDE9C9)],
          ),
        ),
        child: showRive
            ? rive.RiveWidget(controller: _controller!, fit: rive.Fit.contain)
            : const SizedBox.expand(),
      ),
    );
  }

  @override
  void dispose() {
    FlutterError.onError = _previousOnError;
    _controller?.dispose();
    super.dispose();
  }
}
