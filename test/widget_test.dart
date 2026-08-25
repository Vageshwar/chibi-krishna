import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chibi_krishna/main.dart';
import 'package:chibi_krishna/core/services/audio_service.dart';
import 'package:chibi_krishna/features/monetization/data/ad_service.dart';

void main() {
  testWidgets('Chibi Krishna App initializes smoke test', (WidgetTester tester) async {
    final audioService = BackgroundAudioService();
    final adService = AdService();
    await tester.pumpWidget(ChibiKrishnaApp(audioService: audioService, adService: adService));
    // No app bar anymore (simplified home layout) — the mic button is the
    // stable thing to assert on instead.
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
  });
}
