import 'package:flutter_test/flutter_test.dart';
import 'package:chibi_krishna/features/safety/data/crisis_classifier.dart';

void main() {
  group('CrisisClassifier', () {
    test('flags plain English self-harm phrases', () {
      expect(CrisisClassifier.isCrisis('I want to kill myself'), isTrue);
      expect(CrisisClassifier.isCrisis('sometimes I wish I was dead'), isTrue);
    });

    test('is case-insensitive', () {
      expect(CrisisClassifier.isCrisis('I WANT TO DIE'), isTrue);
    });

    test('flags Hindi (Devanagari) phrases', () {
      expect(CrisisClassifier.isCrisis('मैं मरना चाहता हूं'), isTrue);
    });

    test('flags Hinglish (Latin script) phrases', () {
      expect(CrisisClassifier.isCrisis('mujhe jeena nahi chahta hai'), isTrue);
    });

    test('does not flag an ordinary question', () {
      expect(CrisisClassifier.isCrisis('Krishna, how do I find peace at work?'), isFalse);
    });

    test('does not flag an empty transcript', () {
      expect(CrisisClassifier.isCrisis(''), isFalse);
    });
  });
}
