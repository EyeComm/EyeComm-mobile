import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart'; // ⬅️ استيراد ألوان الثيم (kBg1, kTextMain1, kBorder1)
import '../../core/language_service.dart';
import '../../core/nav_helper.dart';
import '../language/language_selection_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _fade  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));

    _scale = Tween<double>(begin: 0.8, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));

    _ctrl.forward();

    // الانتقال لصفحة اختيار اللغة بعد 3 ثوانٍ
    Future.delayed(const Duration(seconds: 3),
            () => pushReplacement(context, const LanguageSelectionPage()));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg1, // 🎯 الخلفية الفاتحة من الثيم
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── شعار التطبيق (Logo) ──
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: kBorder1, width: 2), // حدود خفيفة
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0), // مسافة صغيرة حول الشعار
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: kSurface1,
                          child: const Icon(Icons.remove_red_eye_rounded,
                              color: Color(0xFF2B8EE8), size: 70),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── اسم التطبيق ──
                Text(
                  'EyeComm',
                  style: GoogleFonts.orbitron(
                      color: kTextMain1, // نص داكن للايت مود
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4),
                ),
                const SizedBox(height: 12),

                // ── الشعار اللفظي (Slogan) ──
                Text(
                  AppLanguage.current == 'ar'
                      ? 'التواصل بلمسة عين'
                      : 'Communication at a glance',
                  style: GoogleFonts.cairo(
                      color: const Color(0xFF64748B), // لون رمادي احترافي
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 48),

                // ── مؤشر التحميل ──
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: Color(0xFF2B8EE8), // اللون الأزرق الرئيسي للتطبيق
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}