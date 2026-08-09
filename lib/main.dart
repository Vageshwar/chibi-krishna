import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/audio_service.dart';
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
  Timer? _speechTimer;

  void _simulateSpeaking(BuildContext context) {
    final stageCubit = context.read<StageCubit>();
    stageCubit.setAnimationState(ChibiAnimationState.speaking);
    widget.audioService.setAudioDucked(true);

    _speechTimer?.cancel();
    final random = Random();
    int count = 0;
    _speechTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (count >= 40) { // 4 seconds speech loop
        timer.cancel();
        stageCubit.updateLipSync(0.0);
        stageCubit.setAnimationState(ChibiAnimationState.idle);
        widget.audioService.setAudioDucked(false);
      } else {
        // RMS amplitude simulation driving JawOpen morph target
        final rmsAmplitude = 0.2 + (random.nextDouble() * 0.8);
        stageCubit.updateLipSync(rmsAmplitude);
        count++;
      }
    });
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFFFFD700)),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Chibi Krishna AI',
                applicationVersion: 'v1.0 (Sprint 1)',
                applicationIcon: const Text('🪶', style: TextStyle(fontSize: 32)),
                children: [
                  const Text('Real-time voice-to-voice 3D avatar of Lord Krishna with Bhagavad Gita scriptural wisdom.'),
                ],
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 3D Stage View
          const Positioned.fill(
            child: ChibiStageView(),
          ),

          // Interactive Testing Control Bar for Sprint 1 Stage Animations
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF161824).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      label: 'Flute Idle',
                      icon: Icons.music_note,
                      onPressed: () {
                        _speechTimer?.cancel();
                        context.read<StageCubit>().setAnimationState(ChibiAnimationState.idle);
                        context.read<StageCubit>().updateLipSync(0.0);
                        widget.audioService.setAudioDucked(false);
                      },
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: 'Thinking',
                      icon: Icons.psychology,
                      onPressed: () {
                        _speechTimer?.cancel();
                        context.read<StageCubit>().setAnimationState(ChibiAnimationState.thinking);
                        context.read<StageCubit>().updateLipSync(0.0);
                        widget.audioService.setAudioDucked(false);
                      },
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: 'Simulate Voice',
                      icon: Icons.graphic_eq,
                      onPressed: () => _simulateSpeaking(context),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: 'Blessing Pose',
                      icon: Icons.auto_awesome,
                      onPressed: () {
                        _speechTimer?.cancel();
                        context.read<StageCubit>().setAnimationState(ChibiAnimationState.blessing);
                        context.read<StageCubit>().updateLipSync(0.0);
                        widget.audioService.setAudioDucked(false);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25293A),
        foregroundColor: const Color(0xFFFFD700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
