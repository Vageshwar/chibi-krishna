import 'package:flutter_test/flutter_test.dart';
import 'package:chibi_krishna/main.dart';
import 'package:chibi_krishna/core/services/audio_service.dart';

void main() {
  testWidgets('Chibi Krishna App initializes smoke test', (WidgetTester tester) async {
    final audioService = BackgroundAudioService();
    await tester.pumpWidget(ChibiKrishnaApp(audioService: audioService));
    expect(find.text('Chibi Krishna AI'), findsOneWidget);
  });
}
