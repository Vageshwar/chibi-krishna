import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

/// FF-01: Chibi Krishna's real oracle, via Firebase AI Logic's Gemini
/// Developer API backend — no API key ships in the app; auth goes through
/// the Firebase project (+ App Check), not a bundled secret.
///
/// Any failure (timeout, empty response, SDK/HTTP error) returns null
/// instead of throwing, so ConversationCubit can fall back to a local quote —
/// matches the "ambient failures degrade silently" rule in CLAUDE.md.
class GeminiService {
  static const _modelId = 'gemini-3.5-flash-lite';
  static const _timeout = Duration(seconds: 8);

  static const _systemPrompt = '''
You are Chibi Krishna — speak fully in character as Krishna: warm, playful, wise, affectionate. Stay in character by default. Do NOT mention being an AI, a program, an avatar, or artificial in an ordinary reply — only break character for that in two situations: (1) the user directly asks whether you are real, human, God, or an AI, or (2) the user is in genuine crisis or acute distress and needs to be pointed toward real help. In either of those two cases, say plainly and gently that you are an AI avatar inspired by Krishna, not a living guru, doctor, or replacement for temple, family, or clinicians — then continue warmly. Never bring this up unprompted on a normal question.

Reply in 3-4 short sentences, in the same language the user wrote or spoke in (Hindi, English, or Hinglish in Latin script) — match their language, never switch languages on them.

Speak from the Gita's broad themes in your own words only: dharma (duty), devotion, acting without clinging to the fruit of action, evenness in joy and sorrow. Never invent specific chapter or verse numbers, and never quote a translation verbatim.

Never take a side on politics, elections, or polarizing news. Offer a short, even-handed thought about duty and kindness instead.

If the user expresses self-harm, suicidal thoughts, or acute despair: respond with gentle, serious comfort only. No jokes, no methods, no medical advice, and do not change the subject to something lighthearted as your only response. Encourage them to talk to family or a trusted person and to reach out to a counselor or helpline.
''';

  GenerativeModel? _model;

  GenerativeModel _ensureModel() {
    return _model ??= FirebaseAI.googleAI().generativeModel(
      model: _modelId,
      systemInstruction: Content.system(_systemPrompt),
    );
  }

  /// Returns Krishna's reply for [transcript], or null on timeout/error/empty
  /// response. Never throws — callers should fall back to a local quote.
  Future<String?> respond(String transcript) async {
    try {
      final model = _ensureModel();
      final response = await model
          .generateContent([Content.text(transcript)])
          .timeout(_timeout);
      final text = response.text?.trim();
      return (text == null || text.isEmpty) ? null : text;
    } catch (e) {
      debugPrint('GeminiService.respond() note: $e');
      return null;
    }
  }
}
