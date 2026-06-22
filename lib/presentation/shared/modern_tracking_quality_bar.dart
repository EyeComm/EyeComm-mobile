// modern_tracking_quality_bar.dart - النسخة المحسنة
// ✅ أضفنا زر تغيير اللغة في الـ bar
 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../core/language_service.dart';
import '../core/nav_helper.dart';
import '../screens/language/language_selection_page.dart';
 
class ModernTrackingQualityBar extends StatefulWidget {
  final String currentEye;
  final String stableDirection;
  final int countdownSeconds;
  final int totalTimer;
  final String serverBase;
  final Color activeColor;
  final String pageTitle;
  final bool isMainScreen;
  final String? activeIconAsset;
 
  const ModernTrackingQualityBar({
    super.key,
    required this.currentEye,
    required this.stableDirection,
    required this.countdownSeconds,
    required this.totalTimer,
    this.serverBase = 'http://127.0.0.1:5000',
    required this.activeColor,
    this.pageTitle = '',
    this.isMainScreen = false,
    this.activeIconAsset,
  });
 
  @override
  State<ModernTrackingQualityBar> createState() =>
      _ModernTrackingQualityBarState();
}
 
class _ModernTrackingQualityBarState extends State<ModernTrackingQualityBar>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _glowCtrl;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _glowAnim;
 
  @override
  void initState() {
    super.initState();
 
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
 
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
 
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
 
    _glowAnim = Tween<double>(begin: 0.08, end: 0.25).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }
 
  Color _colorForEye(String cmd) {
    switch (cmd) {
      case 'left':   return const Color(0xFF2B8EE8);
      case 'right':  return const Color(0xFFF9A825);
      case 'up':     return const Color(0xFFE53935);
      case 'down':   return const Color(0xFF7E57C2);
      case 'closed': return const Color(0xFF78909C);
      default:       return const Color(0xFF4CAF50);
    }
  }
 
  String? _assetForEye(String cmd) {
    switch (cmd) {
      case 'left':   return 'assets/look-left.png';
      case 'right':  return 'assets/look-right.png';
      case 'up':     return 'assets/look-up.png';
      case 'down':   return 'assets/look-down.png';
      case 'closed': return 'assets/close.png';
      default:       return null;
    }
  }
 
  String _gestureName(String dir, bool ar) {
    switch (dir) {
      case 'left':   return ar ? 'يسار'  : 'LEFT';
      case 'right':  return ar ? 'يمين'  : 'RIGHT';
      case 'up':     return ar ? 'أعلى'  : 'UP';
      case 'down':   return ar ? 'أسفل'  : 'DOWN';
      case 'closed': return ar ? 'إغلاق' : 'BLINK';
      default:       return dir;
    }
  }
 
  @override
  void dispose() {
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    final isArabic = AppLanguage.current == 'ar';
    final isConnected = widget.currentEye != 'none';
    final gestureActive =
        widget.stableDirection != 'none' && widget.countdownSeconds > 0;
 
    final Color dynamicAccent = gestureActive
        ? _colorForEye(widget.stableDirection)
        : (isConnected ? const Color(0xFF4CAF50) : const Color(0xFF90A4AE));
 
    final String timeStr =
        "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
    final String dateStr =
        "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}";
 
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnim, _pulseAnim]),
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          height: 88,
          decoration: BoxDecoration(
            color: kSurface1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: dynamicAccent.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: dynamicAccent.withOpacity(_glowAnim.value * 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // ─── 1. المعلومات ────────────────────────────────────────
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isMainScreen
                            ? (isArabic ? 'الرئيسية' : 'Home')
                            : '${isArabic ? 'الرئيسية' : 'Home'} › ${widget.pageTitle}',
                        style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        gestureActive
                            ? _gestureName(widget.stableDirection, isArabic)
                            : (isConnected
                                ? (isArabic ? 'التتبع متاح' : 'Tracking Ready')
                                : (isArabic ? 'أوفلاين' : 'Offline')),
                        style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: dynamicAccent),
                      ),
                      Text(
                        gestureActive
                            ? (isArabic
                                ? 'جاري التأكيد... ${widget.countdownSeconds}'
                                : 'Confirming... ${widget.countdownSeconds}')
                            : (isConnected
                                ? (isArabic
                                    ? 'السيرفر متصل'
                                    : 'Server Connected')
                                : (isArabic
                                    ? 'ابحث عن السيرفر'
                                    : 'Searching for server')),
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
 
                // ─── 2. الأيقونة الذكية ──────────────────────────────────
                Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dynamicAccent.withOpacity(0.1),
                      border: Border.all(
                          color: dynamicAccent.withOpacity(0.4), width: 1.5),
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: !isConnected
                            ? Image.asset('assets/searching.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                    Icons.search,
                                    color: dynamicAccent,
                                    size: 22))
                            : (widget.activeIconAsset != null || gestureActive
                                ? Image.asset(
                                    widget.activeIconAsset ??
                                        _assetForEye(
                                                widget.stableDirection) ??
                                            'assets/searching.png',
                                    color: dynamicAccent,
                                    colorBlendMode: BlendMode.srcIn,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                        Icons.remove_red_eye_rounded,
                                        color: dynamicAccent,
                                        size: 22),
                                  )
                                : Icon(Icons.remove_red_eye_rounded,
                                    color: dynamicAccent, size: 24)),
                      ),
                    ),
                  ),
                ),
 
                const SizedBox(width: 8),
 
                // ─── 3. الوقت + زر اللغة ────────────────────────────────
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ✅ زر تغيير اللغة
                    GestureDetector(
                      onTap: () =>
                          pushReplacement(context, const LanguageSelectionPage()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B8EE8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  const Color(0xFF2B8EE8).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ السيرفر indicator
                            Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isConnected
                                        ? Colors.green
                                        : Colors.red)),
                            const SizedBox(width: 4),
                            Text(
                              isArabic ? 'ع' : 'EN',
                              style: const TextStyle(
                                color: Color(0xFF2B8EE8),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.language,
                                size: 12, color: Color(0xFF2B8EE8)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(timeStr,
                        style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800])),
                    Text(dateStr,
                        style: GoogleFonts.orbitron(
                            fontSize: 9, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}