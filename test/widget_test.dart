import 'package:flutter_test/flutter_test.dart';
import 'package:chibi_krishna/main.dart';
import 'package:chibi_krishna/core/services/audio_service.dart';
import 'package:chibi_krishna/features/monetization/data/ad_service.dart';

void main() {
  testWidgets('Chibi Krishna App initializes smoke test', (WidgetTester tester) async {
    final audioService = BackgroundAudioService();
    final adService = AdService();
    await tester.pumpWidget(ChibiKrishnaApp(audioService: audioService, adService: adService));
    expect(find.text('Chibi Krishna AI'), findsOneWidget);
  });
}
