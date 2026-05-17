import 'package:flutter_tts/flutter_tts.dart';
import 'language_service.dart';

/// Wrapper around flutter_tts. Call [init] once at startup (done via
/// [AppLanguage.init]), then call [speak] from anywhere.
class VoiceService {
  static final FlutterTts _tts = FlutterTts();
  static bool _init = false;
  static String _arCode = 'ar-SA';

  static Future<void> init() async {
    try {
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      final List<dynamic> langs = await _tts.getLanguages;
      for (final l in langs) {
        if (l.toString().startsWith('ar')) {
          _arCode = l.toString();
          break;
        }
      }
      _init = true;
    } catch (_) {}
  }

  static Future<void> speak(String text) async {
    if (!_init) await init();
    try {
      await _tts.stop();
      await _tts.setLanguage(
          AppLanguage.current == 'ar' ? _arCode : 'en-US');
      await _tts.setSpeechRate(0.48);
      await _tts.speak(text);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static Future<void> setLang(String l) async {
    try {
      await _tts.setLanguage(l.startsWith('ar') ? _arCode : l);
    } catch (_) {}
  }
}
