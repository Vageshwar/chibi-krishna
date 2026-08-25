import 'package:flutter/material.dart';
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

  const ChibiKrishnaApp({super.key, required this.audioService, required this.adService});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<StageCubit>(
          create: (context) => StageCubit(),
        ),
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

  const HomeScreen({super.key, required this.audioService, required this.adService});

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

  @override
  void initState() {
    super.initState();
    Future.delayed(_splashGreetingDelay, () {
      if (!mounted) return;
      context.read<StageCubit>().setAnimationState(ChibiAnimationState.greeting);
    });
    Future.delayed(_splashDismissDelay, () {
      if (!mounted) return;
      setState(() => _showSplash = false);
      context.read<StageCubit>().setAnimationState(ChibiAnimationState.idle);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    widget.audioService.dispose();
    super.dispose();
  }

  Future<void> _showSupportSheet(BuildContext context) async {
    final watchedAd = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF161824),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SupportSheet(adService: widget.adService),
    );
    if (!context.mounted) return;
    context.read<ConversationCubit>().resolveSupportPrompt(watchedAd: watchedAd == true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConversationCubit, ConversationState>(
      listenWhen: (prev, curr) => curr.needsSupportPrompt && !prev.needsSupportPrompt,
      listener: (context, state) => _showSupportSheet(context),
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🪶 '),
            Text('Chibi Krishna AI'),
            Text(' 🌸'),
          ],
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ChibiStageView()),

          // Response text — shows what Krishna just said (MVP dev visibility;
          // no bespoke chat-bubble chrome yet, that's MVP-04 territory).
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: BlocBuilder<ConversationCubit, ConversationState>(
              buildWhen: (prev, curr) => prev.lastResponseText != curr.lastResponseText,
              builder: (context, state) {
                if (state.lastResponseText == null) return const SizedBox.shrink();
                return _ResponseCard(text: state.lastResponseText!);
              },
            ),
          ),

          // Mic control + text fallback.
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: BlocBuilder<ConversationCubit, ConversationState>(
              builder: (context, state) {
                if (state.showTextInput) {
                  return _TextFallback(
                    controller: _textController,
                    reason: state.fallbackReason,
                    onSubmit: (text) {
                      context.read<ConversationCubit>().submitTypedText(text);
                      _textController.clear();
                    },
                  );
                }
                return _MicButton(
                  isListening: state.isListening,
                  isBusy: state.isBusy,
                  liveTranscript: state.liveTranscript,
                  micLevel: state.micLevel,
                  onTap: () => context.read<ConversationCubit>().startListening(),
                );
              },
            ),
          ),

          // FF-06: adaptive banner, bottom chrome only — renders nothing on
          // iOS or before an ad has loaded, so it's invisible during local
          // iOS-simulator dev.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(child: AdBannerBar(adService: widget.adService)),
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
                  color: Colors.white.withValues(alpha: liveTranscript.isEmpty ? 0.6 : 1.0),
                  fontSize: 14,
                  fontStyle: liveTranscript.isEmpty ? FontStyle.italic : FontStyle.normal,
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

  const _TextFallback({required this.controller, required this.reason, required this.onSubmit});

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
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
