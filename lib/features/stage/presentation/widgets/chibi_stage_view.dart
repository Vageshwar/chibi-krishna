import 'package:flutter/foundation.dart' show FlutterExceptionHandler;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import '../cubit/stage_cubit.dart';
import '../cubit/stage_state.dart';

/// Pose contract for the Rive state machine (see docs/requirements/assets_v3.md):
/// input "pose" (number) 0=idle 1=listening 2=thinking 3=speaking 4=blessing,
/// input "jawOpen" (number 0-1), trigger "blessBurst" fired on entering blessing.
/// If the loaded .riv doesn't have these yet, this widget degrades gracefully:
/// state machine found but missing an input -> that input is simply not driven;
/// no state machine but has animations -> loops the first animation as idle;
/// neither -> renders the artboard statically. Check debug console on run for
/// what was actually found in the current asset.
class ChibiStageView extends StatefulWidget {
  const ChibiStageView({super.key});

  @override
  State<ChibiStageView> createState() => _ChibiStageViewState();
}

class _ChibiStageViewState extends State<ChibiStageView> {
  Artboard? _artboard;
  StateMachineController? _smController;
  SMINumber? _poseInput;
  SMINumber? _jawOpenInput;
  SMITrigger? _blessBurstInput;
  ChibiAnimationState? _lastAppliedPose;

  // Rive throws paint-time exceptions from deep inside its own draw() calls
  // (e.g. a fill/shape type this runtime doesn't recognize, usually a file
  // exported by a newer Rive editor than this package supports). Those don't
  // propagate through a normal try/catch since they happen after build(), and
  // left unhandled they repeat on every single frame. This guard catches that
  // once and falls back to the placeholder background instead of repainting
  // a broken artboard forever.
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
          'Rive: this artboard is throwing during rendering (likely a '
          'shape/fill type this rive package version doesn\'t support — '
          'commonly means the .riv was exported by a newer Rive editor '
          'version). Falling back to the placeholder background instead of '
          'repainting a broken frame. Details: ${details.exception}',
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
      // Required before any RiveFile.import — loads the native/WASM layout
      // engine Rive's newer runtime depends on.
      await RiveFile.initialize();
      final data = await rootBundle.load('assets/rive/chibi_krishna.riv');
      final file = RiveFile.import(data);
      final artboard = file.mainArtboard;

      if (artboard.stateMachines.isNotEmpty) {
        final smName = artboard.stateMachines.first.name;
        final controller = StateMachineController.fromArtboard(artboard, smName);
        if (controller != null) {
          artboard.addController(controller);
          _smController = controller;
          for (final input in controller.inputs) {
            final name = input.name.toLowerCase();
            if (name == 'pose' && input is SMINumber) _poseInput = input;
            if (name == 'jawopen' && input is SMINumber) _jawOpenInput = input;
            if (name == 'blessburst' && input is SMITrigger) _blessBurstInput = input;
          }
          debugPrint(
            'Rive: state machine "$smName" found. '
            'pose input: ${_poseInput != null}, jawOpen input: ${_jawOpenInput != null}, '
            'blessBurst input: ${_blessBurstInput != null}. '
            'Inputs present: ${controller.inputs.map((i) => i.name).join(', ')}',
          );
        }
      } else if (artboard.animations.isNotEmpty) {
        final animName = artboard.animations.first.name;
        artboard.addController(SimpleAnimation(animName));
        debugPrint('Rive: no state machine in this file yet — looping animation "$animName" as a placeholder idle.');
      } else {
        debugPrint('Rive: no state machine or animation in this file yet — rendering static artwork.');
      }

      if (!mounted) return;
      setState(() => _artboard = artboard);
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
    if (_smController == null) return;
    _poseInput?.value = _poseNumber(state.animationState);
    _jawOpenInput?.value = state.jawOpen;
    if (state.animationState == ChibiAnimationState.blessing && _lastAppliedPose != ChibiAnimationState.blessing) {
      _blessBurstInput?.fire();
    }
    _lastAppliedPose = state.animationState;
  }

  @override
  Widget build(BuildContext context) {
    final showRive = _artboard != null && !_renderBroken;
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
            ? Rive(artboard: _artboard!, fit: BoxFit.contain)
            : const SizedBox.expand(),
      ),
    );
  }

  @override
  void dispose() {
    FlutterError.onError = _previousOnError;
    _smController?.dispose();
    super.dispose();
  }
}
