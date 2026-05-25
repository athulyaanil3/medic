import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/medicine.dart';

/// Speaks medicine reminders in the device language (when available on TTS).
class ReminderVoiceService {
  ReminderVoiceService._();

  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    try {
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      final lang = await _resolveLanguage();
      await _tts.setLanguage(lang);
      _ready = true;
    } catch (e) {
      if (kDebugMode) debugPrint('ReminderVoiceService.init: $e');
    }
  }

  static Future<String> _resolveLanguage() async {
    final locale = Platform.localeName.replaceAll('_', '-');
    final candidates = <String>[
      locale,
      if (locale.contains('-')) locale.split('-').first,
      'en-US',
      'en-IN',
    ];

    for (final code in candidates) {
      try {
        final ok = await _tts.isLanguageAvailable(code);
        if (ok == true) return code;
      } catch (_) {}
    }
    return 'en-US';
  }

  static String languageTag() {
    return Platform.localeName.replaceAll('_', '-');
  }

  static String buildMessage(Medicine medicine) =>
      buildMessageFromParts(name: medicine.name, dosage: medicine.dosage);

  static String buildMessageFromParts({
    required String name,
    required String dosage,
  }) {
    final n = name.trim();
    final dose = dosage.trim();
    final lang = Platform.localeName.toLowerCase();

    if (lang.startsWith('hi')) {
      return dose.isEmpty
          ? 'दवा लेने का समय है। $n।'
          : 'दवा लेने का समय है। $n। $dose।';
    }
    if (lang.startsWith('ml')) {
      return dose.isEmpty
          ? 'മരുന്ന് കുടിക്കാനുള്ള സമയമാണ്। $n।'
          : 'മരുന്ന് കുടിക്കാനുള്ള സമയമാണ്। $n। $dose।';
    }
    if (lang.startsWith('ta')) {
      return dose.isEmpty
          ? 'மருந்து எடுக்கும் நேரம்। $n।'
          : 'மருந்து எடுக்கும் நேரம்। $n। $dose।';
    }
    if (lang.startsWith('te')) {
      return dose.isEmpty
          ? 'మందు తీసుకునే సమయం। $n।'
          : 'మందు తీసుకునే సమయం। $n। $dose।';
    }
    if (lang.startsWith('kn')) {
      return dose.isEmpty
          ? 'ಔಷಧಿ ತೆಗೆದುಕೊಳ್ಳುವ ಸಮಯ। $n।'
          : 'ಔಷಧಿ ತೆಗೆದುಕೊಳ್ಳುವ ಸಮಯ। $n। $dose।';
    }
    if (lang.startsWith('bn')) {
      return dose.isEmpty
          ? 'ওষুধ খাওয়ার সময়। $n।'
          : 'ওষুধ খাওয়ার সময়। $n। $dose।';
    }
    if (lang.startsWith('mr')) {
      return dose.isEmpty
          ? 'औषध घेण्याची वेळ। $n।'
          : 'औषध घेण्याची वेळ। $n। $dose।';
    }
    return dose.isEmpty
        ? 'Time to take your medicine. $n.'
        : 'Time to take your medicine. $n. $dose.';
  }

  static Future<void> speak(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await init();
    try {
      await _tts.stop();
      await _tts.awaitSpeakCompletion(true);
      await _tts.speak(clean);
    } catch (e) {
      if (kDebugMode) debugPrint('ReminderVoiceService.speak: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
