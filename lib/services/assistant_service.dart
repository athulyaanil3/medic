import 'package:google_generative_ai/google_generative_ai.dart';

class AssistantService {
  static const geminiEnvKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static GenerativeModel? _cached;

  GenerativeModel? get _model {
    if (geminiEnvKey.trim().isEmpty) return null;
    _cached ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: geminiEnvKey.trim(),
      generationConfig: GenerationConfig(temperature: 0.45, maxOutputTokens: 512),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
      systemInstruction: Content.system(
        '''You are MediVoice Coach inside a medicine-reminder Flutter app.
Only answer topics about: medicine reminders & adherence habits, breathing exercises in the app,
food/calorie logging in the app (no medical diagnosis), Firebase multi-device login at a high level,
and how to use app features.
Politely refuse unrelated topics. For emergencies urge calling local emergency services.''',
      ),
    );
    return _cached!;
  }

  Future<String> reply(String userMessage) async {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) return _fallback('Ask about reminders, breathing, nutrition, or sync.');

    final model = _model;
    if (model == null) {
      return _fallback(_offlineReply(trimmed));
    }

    try {
      final res = await model.generateContent([Content.text(trimmed)]);
      final text = res.text?.trim();
      if (text == null || text.isEmpty) return _fallback(_offlineReply(trimmed));
      return text;
    } catch (_) {
      return _fallback(_offlineReply(trimmed));
    }
  }

  String _offlineReply(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('medic') || lower.contains('pill')) {
      return 'Set daily alarms in the Meds tab; Hive keeps them offline and Firebase syncs when online.';
    }
    if (lower.contains('breath')) {
      return 'Open Breathe for a 4s inhale / 6s exhale loop to calm down before doses.';
    }
    if (lower.contains('calorie') || lower.contains('food')) {
      return 'Log meals in Food tab—totals are estimates, not clinical advice.';
    }
    return 'I only help with MediVoice reminders, breathing, nutrition logs, and app sync.';
  }

  String _fallback(String inner) => '✨ MediVoice Coach • $inner';
}
