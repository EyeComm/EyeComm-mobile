import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../core/app_theme.dart';
import '../../core/language_service.dart';
import '../../core/voice_service.dart';
import '../../core/nav_helper.dart';
import '../../shared/dynamic_eye_card.dart';
import '../../shared/modern_tracking_quality_bar.dart';
// 📸 استيراد الكاميرا بريفيو المخصصة لكي تعمل هنا أيضاً
import '../../shared/eye_camera_preview.dart'; // ⬅️ تأكدي من صحة مسار الملف في مشروعك
import '../home/home_screen.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() =>
      _LanguageSelectionPageState();
}

class _LanguageSelectionPageState
    extends State<LanguageSelectionPage> {
  String _eye = 'none';
  int _cd = 0;
  String _stable = 'none';
  DateTime? _stableAt;
  Timer? _t;
  bool _busy = false;

  static const _cards = [
    _CardDef(
        symbol: 'Aa',
        title: 'English',
        hint: 'Look Left',
        color: Color(0xFF2B8EE8),
        eyeCmd: 'left',
        iconAsset: 'assets/en.png'),
    _CardDef(
        symbol: 'ع',
        title: 'العربية',
        hint: 'انظر يميناً',
        color: Color(0xFF0DB868),
        eyeCmd: 'right',
        iconAsset: 'assets/ar.png'),
  ];

  @override
  void initState() {
    super.initState();
    _startPoll();
  }

  void _startPoll() {
    _t?.cancel();
    _t = Timer.periodic(
        const Duration(milliseconds: 800), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_busy) return;
    _busy = true;
    try {
      final r = await http
          .get(Uri.parse('http://127.0.0.1:5000/predict'))
          .timeout(const Duration(seconds: 4));
      if (r.statusCode == 200 && mounted) {
        final String eye =
            jsonDecode(r.body)['prediction'] as String? ?? 'none';
        setState(() => _eye = eye);
        if (eye != 'none') {
          if (eye == _stable) {
            final int d =
                DateTime.now().difference(_stableAt!).inSeconds;
            final int nc = 5 - d;
            if (nc != _cd) setState(() => _cd = nc.clamp(0, 5));
            if (d >= 5) {
              _t?.cancel();
              _selectLang(eye);
            }
          } else {
            setState(() {
              _stable   = eye;
              _stableAt = DateTime.now();
              _cd       = 5;
            });
          }
        } else {
          setState(() {
            _stable   = 'none';
            _stableAt = null;
            _cd       = 0;
          });
        }
      }
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  void _selectLang(String eye) async {
    if (eye == 'left') {
      AppLanguage.current = 'en';
      await VoiceService.setLang('en-US');
      await VoiceService.speak('English selected. Welcome to EyeComm.');
    } else if (eye == 'right') {
      AppLanguage.current = 'ar';
      await VoiceService.setLang('ar');
      await VoiceService.speak('تم اختيار اللغة العربية. أهلاً بك في آي كوم.');
    } else {
      _startPoll();
      return;
    }
    if (mounted) pushReplacement(context, const MainScreen());
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg1,
      body: SafeArea(
        child: LayoutBuilder(builder: (ctx, screen) {
          final double cardSize =
          (screen.maxWidth * 0.42).clamp(140.0, 240.0);
          final double gap =
          (screen.maxWidth * 0.04).clamp(16.0, 32.0);
          final double cameraWidth =
          (screen.maxWidth * 0.50).clamp(160.0, 260.0);

          return Column(children: [
            const SizedBox(height: 12),

            // ── 🎯 بار التتبع الموحد ──
            ModernTrackingQualityBar(
              currentEye: _eye,
              stableDirection: _stable,
              countdownSeconds: _cd,
              totalTimer: 5,
              serverBase: 'http://127.0.0.1:5000',
              activeColor: const Color(0xFF2B8EE8),
            ),

            // ── المحتوى الرئيسي ────────────────────────────────────────────
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      // 2. 📸 مربع الكاميرا باستخدام الـ Preview المخصصة والمضمونة لفك التقطيع
                      Container(
                        width: cameraWidth,
                        height: cameraWidth / 1.15, // التناسق المتبع 1.15
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kBorder1, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: EyeCameraPreview(
                            serverBase: 'http://127.0.0.1:5000',
                            stableDirection: _stable,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Text('EyeComm',
                          style: GoogleFonts.orbitron(
                              color: kTextMain1,
                              fontSize: (screen.maxWidth * 0.06)
                                  .clamp(20.0, 30.0),
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Choose Language / اختر اللغة',
                        style: GoogleFonts.cairo(
                            color: const Color(0xFF606060),
                            fontSize: (screen.maxWidth * 0.035)
                                .clamp(14.0, 16.0),
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),

                      // كروت اللغات مدعومة بالصور المضافة
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            for (int i = 0;
                            i < _cards.length;
                            i++) ...[
                              if (i > 0) SizedBox(width: gap),
                              SizedBox(
                                width: cardSize,
                                height: cardSize,
                                child: DynamicEyeCard(
                                  item: {
                                    'eye':       _cards[i].eyeCmd,
                                    'text':      _cards[i].title,
                                    'color':     _cards[i].color,
                                    'eye_name':  _cards[i].hint,
                                    'iconAsset': _cards[i].iconAsset,
                                  },
                                  stable: _stable,
                                  cd: _cd,
                                  totalTimer: 5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }
}

class _CardDef {
  final String symbol, title, hint, eyeCmd, iconAsset;
  final Color color;
  const _CardDef(
      {required this.symbol,
        required this.title,
        required this.hint,
        required this.color,
        required this.eyeCmd,
        required this.iconAsset});
}