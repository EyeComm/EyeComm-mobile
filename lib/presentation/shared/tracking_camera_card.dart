import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import 'eye_camera_preview.dart';

class TrackingCameraCard extends StatefulWidget {
  final String currentEye;
  final String serverBase;
  final Color accentColor;
  final bool showGestureLabel;

  const TrackingCameraCard({
    super.key,
    required this.currentEye,
    this.serverBase = 'http://127.0.0.1:5000',
    required this.accentColor,
    this.showGestureLabel = false,
  });

  @override
  State<TrackingCameraCard> createState() => _TrackingCameraCardState();
}

class _TrackingCameraCardState extends State<TrackingCameraCard>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // إبطاء الحركة لراحة العين
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.08, end: 0.25).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  // 🎯 دالة الألوان الموحدة والمطابقة تماماً للكروت لحماية العين من الأصفر الفاقع
  Color _colorForEye(String cmd) {
    switch (cmd) {
      case 'left':   return const Color(0xFF2B8EE8); // أزرق
      case 'right':  return const Color(0xFFF9A825); // برتقالي
      case 'up':     return const Color(0xFFE53935); // أحمر
      case 'down':   return const Color(0xFF7E57C2); // بنفسجي
      case 'closed': return const Color(0xFF78909C); // رمادي
      default:       return const Color(0xFF4CAF50); // أخضر التتبع المستقر الافتراضي
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTracking = widget.currentEye != 'none';

    // 🎨 سحب اللون ديناميكياً بناءً على اتجاه العين الحالي ليتطابق الكارت مع حركة المستخدم
    final Color glowColor = isTracking
        ? _colorForEye(widget.currentEye)
        : const Color(0xFF90A4AE); // رمادي معتدل مريح للعين أثناء وضع الاستعداد والبحث

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: kSurface1,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: glowColor.withOpacity(0.25),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(_glowAnim.value * 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [

                // ── 📸 عرض بث الكاميرا مع تمرير الحركة النشطة لتفعيل الفلتر الذكي ──
                Positioned.fill(
                  child: EyeCameraPreview(
                    serverBase: widget.serverBase,
                    stableDirection: widget.currentEye, // ⬅️ تمرير الاتجاه لغلق وعزل البيانات القديمة بنجاح
                  ),
                ),

                // ── خط سفلي انسيابي ناعم يعطي تأكيداً مرئياً بلون الحركة ──
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          glowColor.withOpacity(0.0),
                          glowColor.withOpacity(0.4),
                          glowColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}