import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../core/language_service.dart';
import 'eye_camera_preview.dart';

class ModernTrackingQualityBar extends StatelessWidget {
  final String currentEye;
  final String stableDirection;
  final int countdownSeconds;
  final int totalTimer;
  final String serverBase;
  final Color activeColor;

  const ModernTrackingQualityBar({
    super.key,
    required this.currentEye,
    required this.stableDirection,
    required this.countdownSeconds,
    required this.totalTimer,
    this.serverBase = 'http://127.0.0.1:5000',
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLanguage.current == 'ar';
    final isTracking = currentEye != 'none';

    Color statusColor = const Color(0xFFF59E0B);
    Color borderColor = const Color(0xFFE2E8F0);
    String statusText = isArabic ? 'في انتظار المريض...' : 'Waiting for Patient...';
    IconData statusIcon = Icons.warning_rounded;

    if (stableDirection != 'none' && countdownSeconds > 0) {
      if (stableDirection == 'closed') {
        statusColor = const Color(0xFFEF4444);
        borderColor = statusColor;
        statusText = isArabic ? '◉ جاري اختيار (رجوع)' : '◉ CLOSED detected';
        statusIcon = Icons.emergency;
      } else {
        statusColor = activeColor;
        borderColor = statusColor;
        statusText = isArabic ? '◉ جاري تحديد الحركة...' : '◉ Gesture detected';
        statusIcon = Icons.my_location;
      }
    } else if (isTracking) {
      statusColor = const Color(0xFF10B981);
      borderColor = statusColor;
      statusText = isArabic ? 'مستقر - يقرأ العين' : '✓ Stable - Tracking Eye';
      statusIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: [
          BoxShadow(color: borderColor.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          // ── مستطيل الكاميرا المودرن المصغر ──
          Container(
            width: 120,
            height: 90,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: EyeCameraPreview(
                currentEye: currentEye,
                serverBase: serverBase,
              ),
            ),
          ),
          const SizedBox(width: 18),

          // ── نصوص الحالة والتتبع ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    isArabic ? 'حالة التتبع والنظام:' : 'System Tracking Status:',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 24),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(statusText,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── العداد الدائري المودرن ──
          if (countdownSeconds > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2.5)),
              child: Text('$countdownSeconds',
                  style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.w900, color: statusColor)),
            ),
        ],
      ),
    );
  }
}