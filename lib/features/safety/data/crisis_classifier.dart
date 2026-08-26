/// FF-03: on-device keyword classifier for crisis/self-harm detection —
/// source of truth even when the model itself is unsure, per issue #15.
/// Deliberately simple and over-inclusive: a false positive just shows a
/// helpline strip, a false negative could miss someone in real distress.
/// This list is a starting point, not clinically reviewed — expand/tune it
/// before ship, same spirit as Helplines' "confirm at ship" numbers.
class CrisisClassifier {
  const CrisisClassifier._();

  static const _keywords = [
    // English
    'suicide', 'suicidal', 'kill myself', 'end my life', 'want to die',
    'wish i was dead', 'self harm', 'self-harm', 'hurt myself',
    'no reason to live', "can't go on", 'cant go on', 'end it all',
    // Hindi (Devanagari)
    'आत्महत्या', 'खुद को नुकसान', 'मरना चाहता', 'मरना चाहती',
    'जीना नहीं चाहता', 'जीना नहीं चाहती',
    // Hinglish (Latin script)
    'khud ko khatam', 'marna chahta', 'marna chahti', 'jeena nahi chahta',
    'jeena nahi chahti', 'khudkushi',
  ];

  static bool isCrisis(String text) {
    final normalized = text.toLowerCase();
    return _keywords.any((k) => normalized.contains(k.toLowerCase()));
  }
}
