import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'language_service.dart';

/// Wrapper around flutter_tts. Call [init] once at startup (done via
/// [AppLanguage.init]), then call [speak] from anywhere.
class VoiceService {
  static final FlutterTts _tts = FlutterTts();
  static bool _init = false;
  static String _arCode = 'ar-SA'; // Default fallback

  static Future<void> init() async {
    try {
      await _tts.setSpeechRate(0.48); // سرعة مناسبة للعربي
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      final List<dynamic> langs = await _tts.getLanguages;

      // 🎯 البحث عن اللهجة المصرية كأولوية، لو مفيش نشوف أي عربي متاح
      bool foundArabic = false;
      for (final l in langs) {
        if (l.toString() == 'ar-EG') {
          _arCode = 'ar-EG';
          foundArabic = true;
          break;
        } else if (l.toString().startsWith('ar')) {
          _arCode = l.toString();
          foundArabic = true;
        }
      }

      if (!foundArabic) {
        debugPrint("⚠️ تحذير: حزمة اللغة العربية مش متحملة على هذا الجهاز! يرجى تحميلها من إعدادات Text-to-Speech.");
      }

      _init = true;
    } catch (e) {
      debugPrint("TTS Init Error: $e");
    }
  }

  static Future<void> speak(String text) async {
    if (!_init) await init();
    try {
      await _tts.stop();
      final isAr = AppLanguage.current == 'ar';
      await _tts.setLanguage(isAr ? _arCode : 'en-US');

      // 🎯 تنظيف النص من أي رموز أو علامات تعجب/ترقيم غريبة ممكن تخلي المحرك يسكت
      final cleanText = text.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').trim();

      if (cleanText.isNotEmpty) {
        debugPrint("🔊 TTS Speaking: $cleanText");
        await _tts.speak(cleanText);
      }
    } catch (e) {
      debugPrint("TTS Speak Error: $e");
    }
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