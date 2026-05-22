import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService extends ChangeNotifier {
  final _tts = FlutterTts();
  final _stt = SpeechToText();

  bool speaking = false;
  bool listening = false;
  String interim = '';

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _stt.initialize();
    notifyListeners();
  }

  bool get sttAvailable => _stt.isAvailable;

  Future<void> speak(String text) async {
    final clean = text.replaceAll(RegExp(r'[*•#]+'), ' ').trim();
    if (clean.isEmpty) return;
    speaking = true;
    notifyListeners();
    await _tts.stop();
    await _tts.speak(clean);
    speaking = false;
    notifyListeners();
  }

  Future<void> startListen({required void Function(String) onFinal}) async {
    if (!_stt.isAvailable) return;
    interim = '';
    listening = true;
    notifyListeners();
    await _stt.listen(
      listenOptions: SpeechListenOptions(
        pauseFor: Duration(seconds: 4),
        listenFor: Duration(seconds: 30),
        cancelOnError: true,
        partialResults: true,
      ),
      onResult: (res) {
        interim = res.recognizedWords;
        notifyListeners();
        if (res.finalResult) {
          listening = false;
          onFinal(res.recognizedWords.trim());
          notifyListeners();
        }
      },
    );
  }

  Future<void> stopListen() async {
    await _stt.stop();
    listening = false;
    notifyListeners();
  }
}
