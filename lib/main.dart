import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/audio_service.dart';
import 'features/monetization/data/ad_service.dart';
import 'features/monetization/data/quota_repository.dart';
import 'features/monetization/presentation/cubit/quota_cubit.dart';
import 'features/monetization/presentation/widgets/ad_banner_bar.dart';
import 'features/monetization/presentation/widgets/support_sheet.dart';
import 'features/oracle/data/quote_repository.dart';
import 'features/oracle/data/speech_service.dart';
import 'features/oracle/data/tts_service.dart';
import 'features/oracle/presentation/cubit/conversation_cubit.dart';
import 'features/oracle/presentation/cubit/conversation_state.dart';
import 'features/stage/presentation/cubit/stage_cubit.dart';
import 'features/stage/presentation/cubit/stage_state.dart';
import 'features/stage/presentation/widgets/chibi_stage_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Dotenv init note: $e');
  }

  final audioService = BackgroundAudioService();
  await audioService.initialize();

  final adService = AdService();
  await adService.initialize();

  runApp(ChibiKrishnaApp(audioService: audioService, adService: adService));
}

class ChibiKrishnaApp extends StatelessWidget {
  final BackgroundAudioService audioService;
  final AdService adService;

  const ChibiKrishnaApp({
    super.key,
    required this.audioService,
    required this.adService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<StageCubit>(create: (context) => StageCubit()),
        BlocProvider<QuotaCubit>(
          create: (context) => QuotaCubit(quotaRepository: QuotaRepository()),
        ),
        BlocProvider<ConversationCubit>(
          create: (context) => ConversationCubit(
            stageCubit: context.read<StageCubit>(),
            speechService: SpeechService(),
            ttsService: TtsService(),
            quoteRepository: QuoteRepository(),
            quotaCubit: context.read<QuotaCubit>(),
          )..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'Chibi Krishna AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0D0E15),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFD700),
            secondary: Color(0xFF00E5FF),
            surface: Color(0xFF161824),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF161824),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        home: HomeScreen(audioService: audioService, adService: adService),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final BackgroundAudioService audioService;
  final AdService adService;

  const HomeScreen({
    super.key,
    required this.audioService,
    required this.adService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Splash choreography: matches ChibiStageView's own 900ms bottom-to-top
// entrance, then holds a wave-hi greeting before handing off to the
// interactive stage — kept as timers (not a state machine) since it's a
// fixed one-time sequence, not something the rest of the app reacts to.
const _splashGreetingDelay = Duration(milliseconds: 1000);
const _splashDismissDelay = Duration(milliseconds: 2700);

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _showSplash = true;
  Timer? _splashGreetingTimer;
  Timer? _splashDismissTimer;

  @override
  void initState() {
    super.initState();
    _splashGreetingTimer = Timer(_splashGreetingDelay, () {
      context.read<StageCubit>().setAnimationState(
        ChibiAnimationState.greeting,
      );
    });
    _splashDismissTimer = Timer(_splashDismissDelay, () {
      setState(() => _showSplash = false);
      context.read<StageCubit>().setAnimationState(ChibiAnimationState.idle);
    });
  }

  @override
  void dispose() {
    _splashGreetingTimer?.cancel();
    _splashDismissTimer?.cancel();
    _textController.dispose();
    widget.audioService.dispose();
    super.dispose();
  }

  Future<bool> _showSupportSheet(
    BuildContext context, {
    required bool isVoluntary,
  }) async {
    final watchedAd = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF161824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          SupportSheet(adService: widget.adService, isVoluntary: isVoluntary),
    );
    return watchedAd == true;
  }

  // Triggered by ConversationCubit when the daily voice quota runs out —
  // the sheet's outcome decides whether the pending question gets answered
  // normally or downgraded (see ConversationCubit.resolveSupportPrompt).
  Future<void> _handleQuotaSupportPrompt(BuildContext context) async {
    final watchedAd = await _showSupportSheet(context, isVoluntary: false);
    if (!context.mounted) return;
    context.read<ConversationCubit>().resolveSupportPrompt(
      watchedAd: watchedAd,
    );
  }

  // Triggered by the top-right support button — a voluntary "Dakshina" entry
  // point (PRD v3 §7), not gated on quota. No pending question to resolve;
  // just grants the reward turns directly if the ad was watched.
  Future<void> _handleVoluntarySupport(BuildContext context) async {
    final watchedAd = await _showSupportSheet(context, isVoluntary: true);
    if (!context.mounted || !watchedAd) return;
    context.read<QuotaCubit>().grantRewardTurns();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConversationCubit, ConversationState>(
      listenWhen: (prev, curr) =>
          curr.needsSupportPrompt && !prev.needsSupportPrompt,
      listener: (context, state) => _handleQuotaSupportPrompt(context),
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    // No app bar — the character stage fills the whole screen, per the
    // simplified "just Krishna, mic, and ad" layout. Top of the stage is a
    // light sky gradient, so status bar icons need to be dark to stay
    // legible without a dark app-bar band behind them.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: ChibiStageView()),

            // Response text — what Krishna just said. Fades out on its own a
            // few seconds after appearing rather than sitting on screen
            // indefinitely (see _ResponseBubble). SafeArea here because
            // there's no app bar anymore to clear the status bar for us.
            Positioned(
              top: 0,
              left: 16,
              right: 64, // clears the support button in the top-right corner
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: BlocBuilder<ConversationCubit, ConversationState>(
                    buildWhen: (prev, curr) =>
                        prev.lastResponseText != curr.lastResponseText,
                    builder: (context, state) =>
                        _ResponseBubble(text: state.lastResponseText),
                  ),
                ),
              ),
            ),

            // Mic control + text fallback, stacked above the banner in a
            // Column so the mic's position accounts for the banner's real
            // (adaptive, device-dependent) height instead of a guessed fixed
            // offset — that guess is exactly what let the banner sit on top
            // of the mic button before. Collapses to just the mic's own
            // spacing when no banner is showing (iOS, or before one loads).
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: BlocBuilder<ConversationCubit, ConversationState>(
                        builder: (context, state) {
                          if (state.showTextInput) {
                            return _TextFallback(
                              controller: _textController,
                              reason: state.fallbackReason,
                              onSubmit: (text) {
                                context
                                    .read<ConversationCubit>()
                                    .submitTypedText(text);
                                _textController.clear();
                              },
                            );
                          }
                          return _MicButton(
                            isListening: state.isListening,
                            isBusy: state.isBusy,
                            liveTranscript: state.liveTranscript,
                            micLevel: state.micLevel,
                            onTap: () => context
                                .read<ConversationCubit>()
                                .startListening(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // FF-06: adaptive banner, bottom chrome only — renders
                    // nothing on iOS or before an ad has loaded.
                    AdBannerBar(adService: widget.adService),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Voluntary support ("Dakshina") button, PRD v3 §7 — same
            // Support sheet as the quota-exhausted prompt, just opened by
            // choice instead of being forced. Top-right, clear of the
            // response bubble which sits top-left/center.
            Positioned(
              top: 0,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _SupportButton(
                    onTap: () => _handleVoluntarySupport(context),
                  ),
                ),
              ),
            ),

            // Splash: welcome text over Krishna's bottom-to-top entrance +
            // wave-hi greeting (see ChibiStageView / _HomeScreenState.initState).
            // Absorbs taps while shown so the mic can't be triggered mid-intro.
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: _showSplash,
                child: AnimatedOpacity(
                  opacity: _showSplash ? 1 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: const _WelcomeOverlay(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeOverlay extends StatelessWidget {
  const _WelcomeOverlay();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: const Alignment(0, -0.55),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF161824).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text(
            'Welcome to\nChibi Krishna AI',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the latest response card, then fades it out on its own a few
/// seconds later rather than leaving it on screen indefinitely. Restarts
/// the fade timer whenever a new response arrives.
class _ResponseBubble extends StatefulWidget {
  final String? text;
  const _ResponseBubble({required this.text});

  @override
  State<_ResponseBubble> createState() => _ResponseBubbleState();
}

class _ResponseBubbleState extends State<_ResponseBubble> {
  static const _visibleDuration = Duration(seconds: 7);
  static const _fadeDuration = Duration(milliseconds: 800);

  late bool _visible = widget.text != null;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    if (widget.text != null) _scheduleFade();
  }

  @override
  void didUpdateWidget(covariant _ResponseBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text && widget.text != null) {
      setState(() => _visible = true);
      _scheduleFade();
    }
  }

  void _scheduleFade() {
    _fadeTimer?.cancel();
    _fadeTimer = Timer(_visibleDuration, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text == null) return const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: _fadeDuration,
      child: _ResponseCard(text: widget.text!),
    );
  }
}

/// Voluntary "Dakshina" support entry point (PRD v3 §7) — top-right, opens
/// the same Support sheet as the quota-exhausted prompt. Publisher-voiced
/// throughout; never framed as Krishna asking for anything (locked decision).
class _SupportButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SupportButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF161824).withValues(alpha: 0.75),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.attach_money, color: Color(0xFFFFD700), size: 22),
        ),
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final String text;
  const _ResponseCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161824).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isListening;
  final bool isBusy;
  final String liveTranscript;
  final double micLevel;
  final VoidCallback onTap;

  const _MicButton({
    required this.isListening,
    required this.isBusy,
    required this.liveTranscript,
    required this.micLevel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isListening) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                liveTranscript.isEmpty ? 'Listening…' : liveTranscript,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: liveTranscript.isEmpty ? 0.6 : 1.0,
                  ),
                  fontSize: 14,
                  fontStyle: liveTranscript.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            _Equalizer(level: micLevel),
            const SizedBox(height: 10),
          ],
          // Mic-glow overlay per MVP-02: listening feedback is UI-only, not a
          // dedicated Rive pose.
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening
                  ? const Color(0xFFFFD700).withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
            child: Center(
              child: ElevatedButton(
                onPressed: isBusy ? null : onTap,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(18),
                  backgroundColor: const Color(0xFFFFD700),
                  disabledBackgroundColor: const Color(0xFF25293A),
                ),
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: isBusy ? Colors.white38 : Colors.black87,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple "something is being recorded" indicator, driven by raw mic sound
/// level (see SpeechService.listen's onSoundLevel) — gives instant feedback
/// the mic is live even before speech_to_text has recognized any words yet,
/// complementing the live-caption text above it.
class _Equalizer extends StatelessWidget {
  final double level; // normalized 0..1

  const _Equalizer({required this.level});

  static const _barMultipliers = [0.5, 0.85, 1.0, 0.7, 0.45];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final multiplier in _barMultipliers)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                width: 4,
                height: 4 + (20 * level * multiplier).clamp(0.0, 20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TextFallback extends StatelessWidget {
  final TextEditingController controller;
  final FallbackReason reason;
  final ValueChanged<String> onSubmit;

  const _TextFallback({
    required this.controller,
    required this.reason,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final hint = reason == FallbackReason.permissionDenied
        ? 'Mic unavailable — type your question instead'
        : "Didn't catch that — type your question instead";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161824).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
              ),
              onSubmitted: onSubmit,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFFFFD700)),
            onPressed: () => onSubmit(controller.text),
          ),
        ],
      ),
    );
  }
}
