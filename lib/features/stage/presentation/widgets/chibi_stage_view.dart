import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show FlutterExceptionHandler;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rive/rive.dart' as rive;
import '../cubit/stage_cubit.dart';
import '../cubit/stage_state.dart';

/// One tap-to-react combo. Deliberately warm/curious, not negative — a
/// friendly poke shouldn't get a "Crying" or "Oh No" reaction back. Kept
/// subtle (per PRD: "calm nature backdrop... soothing, not slapstick"),
/// distinct from Talking Tom's poke-belly gimmick this project explicitly
/// ruled out — this is one gentle flourish, not a mash-for-giggles loop.
class _TapReaction {
  final String pose;
  final String emotion;
  final String eye;
  const _TapReaction(this.pose, this.emotion, this.eye);
}

const _tapReactions = [
  _TapReaction('Yesss', 'Happy02', 'open_big'),
  _TapReaction('is_waving', 'Happy01', 'open_big'),
  _TapReaction('is_Acceptance', 'Happy01', 'open_big'),
  _TapReaction('Idle', 'Odd', 'open_small'),
  _TapReaction('Idle', 'Neutral02', 'open_big'),
  _TapReaction('is_Denial', 'Odd', 'open_small'),
  _TapReaction('Idle', 'Exhalation', 'open_small'),
  _TapReaction('Idle', 'Happy03', 'open_big'),
  _TapReaction('Idle', 'Opps01', 'open_big'),
  _TapReaction('Yesss', 'Happy03', 'open_big'),
];

/// This character's .riv (assets/rive/chibi_krishna.riv) uses Rive **Data
/// Binding**, not legacy state-machine number/trigger inputs — the artboard
/// ("krishna_ai_teacher_master", state machine "KrishnaJI_SM") has a
/// ViewModel with three enum properties, verified live against the real
/// asset (see docs/krishna_rive_integration_summary.md for the source of
/// these values, and progress/ for how they were verified):
///   - poses:   Yesss | idle_lookaround | is_waving | talk_visemes |
///              is_Denial | is_Acceptance | Idle
///   - emotion: Exhalation | Thniking (sic, typo baked into the .riv) |
///              Happy01 | Happy02 | Happy03 | Sad | Opps01 | Opps02 |
///              Neutral01 | Neutral02 | Aaaaah | Odd | Crying | Oh No
///   - eye:     close | open_big | open_small
/// `poses: talk_visemes` is itself a self-contained talking animation, so
/// unlike a number-driven jawOpen rig, we only need to switch the enum once
/// per app-state change, not push a value every frame.
class ChibiStageView extends StatefulWidget {
  const ChibiStageView({super.key});

  @override
  State<ChibiStageView> createState() => _ChibiStageViewState();
}

class _ChibiStageViewState extends State<ChibiStageView> with SingleTickerProviderStateMixin {
  rive.RiveWidgetController? _controller;
  rive.ViewModelInstanceEnum? _posesInput;
  rive.ViewModelInstanceEnum? _emotionInput;
  rive.ViewModelInstanceEnum? _eyeInput;
  ChibiAnimationState? _lastAppliedPose;

  final Random _random = Random();
  Timer? _reactionTimer;
  bool _isReacting = false;

  // Defensive guard kept from before, in case a future file revision trips a
  // rendering incompatibility — costs nothing while rendering is healthy.
  bool _renderBroken = false;
  FlutterExceptionHandler? _previousOnError;

  // One-time "rises into frame" entrance on cold start (splash moment) —
  // plays once the rig is actually loaded, not before. Built eagerly in
  // initState (not as a lazy `late final` field initializer) — if _loadRive
  // fails before ever touching these, a lazy initializer would instead run
  // for the first time inside dispose(), where the vsync ticker lookup
  // throws because the element is already deactivating.
  late final AnimationController _entranceController;
  late final Animation<Offset> _entranceOffset;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _entranceOffset = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));
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
        debugPrint('Rive: artboard "${artboard.name}" has no state machine.');
        return;
      }

      final controller = rive.RiveWidgetController(file);
      final vmi = controller.dataBind(rive.DataBind.auto());
      _posesInput = vmi.enumerator('poses');
      _emotionInput = vmi.enumerator('emotion');
      _eyeInput = vmi.enumerator('eye');

      debugPrint(
        'Rive: bound ViewModel instance "${vmi.name}" on "${artboard.name}". '
        'poses: ${_posesInput != null}, emotion: ${_emotionInput != null}, eye: ${_eyeInput != null}',
      );

      if (!mounted) return;
      setState(() => _controller = controller);
      _entranceController.forward();
    } catch (e, st) {
      debugPrint('Rive: failed to load/bind assets/rive/chibi_krishna.riv: $e\n$st');
    }
  }

  void _applyState(StageState state) {
    if (_controller == null) return;
    // poses/emotion/eye are discrete enum states, not per-frame values, so
    // only re-apply when the app's pose actually changes (StageState also
    // emits on every jawOpen tick, which this rig doesn't use).
    if (_lastAppliedPose == state.animationState) return;
    _lastAppliedPose = state.animationState;
    // Real conversation state always wins over a lingering tap-reaction.
    _reactionTimer?.cancel();
    _isReacting = false;

    switch (state.animationState) {
      case ChibiAnimationState.idle:
        _posesInput?.value = 'Idle';
        _emotionInput?.value = 'Happy01';
        _eyeInput?.value = 'open_big';
        break;
      case ChibiAnimationState.listening:
        _posesInput?.value = 'idle_lookaround';
        _emotionInput?.value = 'Happy01';
        _eyeInput?.value = 'open_big';
        break;
      case ChibiAnimationState.thinking:
        // Was poses: Idle / emotion: Thniking — read as a weird/frowning
        // expression in live testing (#39). Swapped per user's pick after
        // reviewing the ViewModel's actual pose/emotion options.
        _posesInput?.value = 'idle_lookaround';
        _emotionInput?.value = 'Opps01';
        _eyeInput?.value = 'open_small';
        break;
      case ChibiAnimationState.speaking:
        _posesInput?.value = 'talk_visemes';
        _emotionInput?.value = 'Happy01';
        _eyeInput?.value = 'open_big';
        break;
      case ChibiAnimationState.blessing:
        _posesInput?.value = 'Yesss';
        _emotionInput?.value = 'Happy03';
        _eyeInput?.value = 'open_big';
        break;
      case ChibiAnimationState.greeting:
        _posesInput?.value = 'is_waving';
        _emotionInput?.value = 'Happy02';
        _eyeInput?.value = 'open_big';
        break;
    }
  }

  /// Tap-to-react: only while genuinely idle (not mid-conversation), a
  /// random warm reaction plays, then reverts — unless the conversation
  /// moved on in the meantime, in which case _applyState already took over.
  void _handleTap() {
    if (_controller == null || _renderBroken || _isReacting) return;
    final isIdle = _lastAppliedPose == null || _lastAppliedPose == ChibiAnimationState.idle;
    if (!isIdle) return;

    final reaction = _tapReactions[_random.nextInt(_tapReactions.length)];
    _posesInput?.value = reaction.pose;
    _emotionInput?.value = reaction.emotion;
    _eyeInput?.value = reaction.eye;
    _isReacting = true;

    _reactionTimer?.cancel();
    _reactionTimer = Timer(const Duration(milliseconds: 2000), () {
      _isReacting = false;
      final stillIdle = _lastAppliedPose == null || _lastAppliedPose == ChibiAnimationState.idle;
      if (!stillIdle) return; // conversation moved on — don't stomp on it
      _posesInput?.value = 'Idle';
      _emotionInput?.value = 'Happy01';
      _eyeInput?.value = 'open_big';
    });
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
            ? SlideTransition(
                position: _entranceOffset,
                child: GestureDetector(
                  onTap: _handleTap,
                  behavior: HitTestBehavior.opaque,
                  child: rive.RiveWidget(controller: _controller!, fit: rive.Fit.contain),
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }

  @override
  void dispose() {
    FlutterError.onError = _previousOnError;
    _reactionTimer?.cancel();
    _entranceController.dispose();
    _controller?.dispose();
    super.dispose();
  }
}
