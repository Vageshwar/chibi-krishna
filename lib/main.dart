import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/audio_service.dart';
import 'features/oracle/data/quote_repository.dart';
import 'features/oracle/data/speech_service.dart';
import 'features/oracle/data/tts_service.dart';
import 'features/oracle/presentation/cubit/conversation_cubit.dart';
import 'features/oracle/presentation/cubit/conversation_state.dart';
import 'features/stage/presentation/cubit/stage_cubit.dart';
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

  runApp(ChibiKrishnaApp(audioService: audioService));
}

class ChibiKrishnaApp extends StatelessWidget {
  final BackgroundAudioService audioService;

  const ChibiKrishnaApp({super.key, required this.audioService});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<StageCubit>(
          create: (context) => StageCubit(),
        ),
        BlocProvider<ConversationCubit>(
          create: (context) => ConversationCubit(
            stageCubit: context.read<StageCubit>(),
            speechService: SpeechService(),
            ttsService: TtsService(),
            quoteRepository: QuoteRepository(),
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
        home: HomeScreen(audioService: audioService),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final BackgroundAudioService audioService;

  const HomeScreen({super.key, required this.audioService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    widget.audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  onTap: () => context.read<ConversationCubit>().startListening(),
                );
              },
            ),
          ),
        ],
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
  final VoidCallback onTap;

  const _MicButton({required this.isListening, required this.isBusy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isListening)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Listening…',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
              ),
            ),
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
