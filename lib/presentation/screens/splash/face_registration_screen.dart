import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/app_theme.dart';
import '../../core/language_service.dart';
import '../../core/voice_service.dart';
import '../../core/nav_helper.dart';
import '../language/language_selection_page.dart';
 
class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});
 
  @override
  State<FaceRegistrationScreen> createState() =>
      _FaceRegistrationScreenState();
}
 
class _FaceRegistrationScreenState extends State<FaceRegistrationScreen>
    with TickerProviderStateMixin {
  static const String _serverBase = 'http://127.0.0.1:5000';
 
  bool _isRegistering = false;
  bool _registrationDone = false;
  bool _serverConnected = false;
  String _statusMsg = 'جاري الاتصال بالسيرفر...';
  int _countdown = 10; // تعديل العداد إلى 10 ثوانٍ ليعطيك وقتاً كافياً لضبط وجهك
  Timer? _countdownTimer;
  Timer? _checkTimer;
  bool _faceDetected = false;
 
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
 
  @override
  void initState() {
    super.initState();
 
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
 
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
 
    _startChecking();
  }
 
  void _startChecking() {
    _checkTimer =
        Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final r = await http
            .get(Uri.parse('$_serverBase/face_status'))
            .timeout(const Duration(seconds: 3));
        if (r.statusCode == 200 && mounted) {
          final data = jsonDecode(r.body);
          setState(() {
            _serverConnected = true;
            _faceDetected = data['face_detected'] ?? false;
          });
          // إذا كان الوجه مسجل مسبقاً، ننتقل فوراً لصفحة اللغة
          if (data['registered'] == true) {
            _checkTimer?.cancel();
            _goToLanguage();
          }
        }
      } catch (_) {
        if (mounted) setState(() => _serverConnected = false);
      }
    });
  }
 
  Future<void> _startRegistration() async {
    if (!_faceDetected) {
      VoiceService.speak('من فضلك ضع وجهك أمام الكاميرا أولاً');
      setState(() => _statusMsg = 'لم يُكتشف وجه، ضع وجهك أمام الكاميرا');
      return;
    }
 
    setState(() {
      _isRegistering = true;
      _countdown = 10; // يبدأ العد التنازلي التلقائي من 10 ثوانٍ
      _statusMsg = 'اضبط وضعية وجهك... استعد (10)';
    });
 
    VoiceService.speak('استعد، سيتم التقاط الوجه تلقائياً خلال عشر ثوان، اضبط وجهك أمام الكاميرا');
 
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (t) async {
      if (_countdown > 1) {
        _countdown--;
        if (mounted) {
          setState(() => _statusMsg = 'اضبط وضعية وجهك... المتبقي: $_countdown ثوانٍ');
          // ننطق الأرقام الأخيرة فقط صوتياً لعدم إزعاج المستخدم طوال الـ 10 ثوانٍ
          if (_countdown <= 5) {
            VoiceService.speak(_countdown.toString());
          }
        }
      } else {
        t.cancel();
        await _doRegister(); // الالتقاط التلقائي عند انتهاء الـ 10 ثوانٍ
      }
    });
  }
 
  Future<void> _doRegister() async {
    if (!mounted) return;
    setState(() => _statusMsg = 'جاري التقاط وتسجيل وجهك الآن...');
    VoiceService.speak('جاري التقاط الصورة والتحليل');
 
    try {
      final r = await http
          .post(Uri.parse('$_serverBase/register_face'))
          .timeout(const Duration(seconds: 10));
 
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _registrationDone = true;
              _isRegistering = false;
              _statusMsg = 'تم التسجيل بنجاح! 🎉';
            });
          }
          VoiceService.speak('تم تسجيل وجهك بنجاح، أهلاً بك يا سيدي');
          await Future.delayed(const Duration(seconds: 2));
          _goToLanguage();
        } else {
          _onError(data['message'] ?? 'فشل التسجيل، تأكد من ثبات وجهك أمام الكاميرا');
        }
      } else {
        _onError('خطأ في السيرفر، حاول مرة أخرى');
      }
    } catch (_) {
      _onError('تعذر الاتصال بالسيرفر، تأكد من تشغيله');
    }
  }
 
  void _onError(String msg) {
    if (!mounted) return;
    setState(() {
      _isRegistering = false;
      _statusMsg = msg;
    });
    VoiceService.speak(msg);
  }
 
  void _goToLanguage() {
    _checkTimer?.cancel();
    if (mounted) pushReplacement(context, const LanguageSelectionPage());
  }
 
  @override
  void dispose() {
    _pulseCtrl.dispose();
    _countdownTimer?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg1,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                children: [
                  Text(
                    'تسجيل الوجه المطور',
                    style: GoogleFonts.cairo(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: kTextMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'لديك 10 ثوانٍ لضبط وجهك بعد بدء التسجيل التلقائي',
                    style: GoogleFonts.cairo(
                        fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
 
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          border: Border.all(
                            color: _faceDetected
                                ? const Color(0xFF00C853)
                                : const Color(0xFF2B8EE8),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_faceDetected
                                      ? const Color(0xFF00C853)
                                      : const Color(0xFF2B8EE8))
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _serverConnected
                              ? Image.network(
                                  '$_serverBase/capture_face_frame',
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  errorBuilder: (_, __, ___) =>
                                      _placeholder(),
                                  loadingBuilder: (_, child, progress) =>
                                      progress == null ? child : _loading(),
                                )
                              : _placeholder(),
                        ),
                      ),
                    ),
 
                    const SizedBox(height: 24),
 
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _faceDetected
                            ? const Color(0xFF00C853).withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _faceDetected
                              ? const Color(0xFF00C853)
                              : Colors.orange,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _faceDetected
                                ? Icons.face_retouching_natural
                                : Icons.face_retouching_off,
                            color: _faceDetected
                                ? const Color(0xFF00C853)
                                : Colors.orange,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _faceDetected
                                ? '✅ تم اكتشاف وجه'
                                : '⏳ لم يتم اكتشاف وجه...',
                            style: GoogleFonts.cairo(
                              color: _faceDetected
                                  ? const Color(0xFF00C853)
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
 
                    const SizedBox(height: 20),
 
                    Text(
                      _statusMsg,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: kTextMain,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
 
                    const SizedBox(height: 28),
 
                    if (!_registrationDone)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isRegistering ? null : _startRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B8EE8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                          ),
                          icon: _isRegistering
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(
                                  Icons.timer_10_select_rounded,
                                  size: 24),
                          label: Text(
                            _isRegistering
                                ? 'جاري العد التنازلي والتقاط الوجه...'
                                : 'ابدأ مؤقت الـ 10 ثوانٍ للتسجيل',
                            style: GoogleFonts.cairo(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
 
                    if (!_registrationDone && !_isRegistering) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _goToLanguage,
                        child: Text(
                          'تخطي (غير موصى به)',
                          style: GoogleFonts.cairo(
                              color: Colors.grey[500], fontSize: 13),
                        ),
                      ),
                    ],
 
                    if (_registrationDone) ...[
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF00C853), size: 64),
                      const SizedBox(height: 12),
                      Text(
                        'تم! جاري الانتقال...',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF00C853),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _placeholder() => Container(
        color: const Color(0xFF1E1E24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white38, size: 48),
            const SizedBox(height: 8),
            Text(
              _serverConnected ? 'جاري التحميل...' : 'السيرفر غير متصل',
              style: GoogleFonts.cairo(
                  color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      );
 
  Widget _loading() => Container(
        color: const Color(0xFF1E1E24),
        child: const Center(
          child: CircularProgressIndicator(
              color: Colors.blue, strokeWidth: 2),
        ),
      );
}