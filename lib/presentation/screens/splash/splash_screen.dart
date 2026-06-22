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
import '../face_registration/face_registration_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _voicePlayed = false;
  Timer? _eyeCheckTimer;
  Timer? _autoNavigateTimer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();

    // تشغيل الصوت
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      setState(() => _voicePlayed = true);
      await VoiceService.speak('أهلاً بك يا سيدي');
      
      // ✅ الانتقال التلقائي بعد 1 ثانية فقط (بدل 5)
      _startAutoNavigateTimer();
      
      // ✅ بدأ مراقبة العين (للانتقال السريع بالنظر يمين)
      _startEyeTracking();
    });
  }

  // ✅ الانتقال التلقائي بعد 1 ثانية
  void _startAutoNavigateTimer() {
    _autoNavigateTimer = Timer(const Duration(seconds: 1), () {  // ✅ من 5 إلى 1
      if (mounted && !_isNavigating) {
        _navigateToRegistration();
      }
    });
  }

  void _startEyeTracking() {
    _eyeCheckTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) async {
      if (_isNavigating || !mounted) return;
      
      try {
        final response = await http
            .get(Uri.parse('http://127.0.0.1:5000/predict'))
            .timeout(const Duration(seconds: 4));
            
        if (response.statusCode == 200 && mounted) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final String eye = data['prediction'] as String? ?? 'none';
          
          // ✅ لو نظر يمين، ننتقل فوراً
          if (eye == 'right' && !_isNavigating) {
            _isNavigating = true;
            _eyeCheckTimer?.cancel();
            _autoNavigateTimer?.cancel();
            if (mounted) {
              _navigateToRegistration();
            }
          }
        }
      } catch (_) {
        // لو السيرفر مش شغال، نكمل الانتظار
      }
    });
  }

  void _navigateToRegistration() {
    if (_isNavigating) return;
    _isNavigating = true;
    _eyeCheckTimer?.cancel();
    _autoNavigateTimer?.cancel();

    if (mounted) {
      pushReplacement(context, const FaceRegistrationScreen());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _eyeCheckTimer?.cancel();
    _autoNavigateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg1,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: kBorder1, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: kSurface1,
                          child: const Icon(
                            Icons.remove_red_eye_rounded,
                            color: Color(0xFF2B8EE8),
                            size: 70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'EyeComm',
                  style: GoogleFonts.orbitron(
                    color: kTextMain1,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Communication at a glance',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF64748B),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedOpacity(
                  opacity: _voicePlayed ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B8EE8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'أهلاً بك يا سيدي 👋',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF2B8EE8),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: Color(0xFF2B8EE8),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'جاري التحميل...',
                      style: GoogleFonts.cairo(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}