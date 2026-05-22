import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../core/language_service.dart';

/// 🎯 REFACTORED: Slim status-only tracking bar (camera removed).
/// The camera is now a separate grid card via TrackingCameraCard.
///
/// Changes from original:
/// - Removed EyeCameraPreview entirely (was lines 246-831)
/// - Reduced height from 200 to 84 pixels
/// - Kept all tracking status, gesture status, countdown, signal strength
/// - Removed camera aspect ratio distortion issues
/// - Faster, cleaner rendering without image processing
class ModernTrackingQualityBar extends StatefulWidget {
  final String currentEye;
  final String stableDirection;
  final int countdownSeconds;
  final int totalTimer;
  final String serverBase;
  final Color activeColor;
  final String pageTitle;
  final bool isMainScreen;

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
  });

  @override
  State<ModernTrackingQualityBar> createState() =>
      _ModernTrackingQualityBarState();
}

class _ModernTrackingQualityBarState extends State<ModernTrackingQualityBar>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _glowAnim;
  late final Animation<Offset> _slideAnim;

  String? _lastDirection;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic),
        );

    _slideCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant ModernTrackingQualityBar old) {
    super.didUpdateWidget(old);
    if (widget.stableDirection != _lastDirection) {
      _lastDirection = widget.stableDirection;
      _slideCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Gesture helpers ───────────────────────────────────────────────────────

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

  IconData _gestureIcon(String dir) {
    switch (dir) {
      case 'left':   return Icons.arrow_back_ios_new_rounded;
      case 'right':  return Icons.arrow_forward_ios_rounded;
      case 'up':     return Icons.north_rounded;
      case 'down':   return Icons.south_rounded;
      case 'closed': return Icons.emergency_rounded;
      default:       return Icons.my_location_rounded;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLanguage.current == 'ar';
    final isTracking = widget.currentEye != 'none';
    final gestureActive =
        widget.stableDirection != 'none' && widget.countdownSeconds > 0;

    // ── i18n strings ──────────────────────────────────────────────────────
    final String labelHome      = AppLanguage.t('title') == 'EyeComm'
        ? (isArabic ? 'الرئيسية' : 'Home')
        : (isArabic ? 'الرئيسية' : 'Home');
    final String labelLive      = isArabic ? 'تتبع مباشر'    : 'Live Tracking';
    final String labelAwaiting  = isArabic ? 'انتظار الإشارة' : 'Awaiting Signal';
    final String labelConfirm   = isArabic ? 'جاري التأكيد...' : 'Confirming...';
    final String labelDetected  = isArabic ? 'العين محددة'   : 'Eye detected';
    final String labelNoSignal  = isArabic ? 'لا توجد إشارة' : 'No signal';
    final String labelStatus    = isArabic ? 'الحالة'        : 'STATUS';
    final String labelSignal    = isArabic ? 'إشارة'         : 'SIGNAL';
    final String labelSearching = isArabic ? 'بحث...'        : 'SEARCHING';

    // ── Time / date ───────────────────────────────────────────────────────
    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final dateStr =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    // ── Dynamic accent colour ─────────────────────────────────────────────
    final Color accent = gestureActive
        ? widget.activeColor
        : isTracking
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

    // ── Status text ───────────────────────────────────────────────────────
    final String mainLabel = gestureActive
        ? _gestureName(widget.stableDirection, isArabic)
        : isTracking
        ? labelLive
        : labelAwaiting;

    final String subLabel = gestureActive
        ? (isArabic ? 'جاري التأكيد...' : 'Confirming...')
        : isTracking
        ? labelDetected
        : labelNoSignal;

    // ── Breadcrumb segments ───────────────────────────────────────────────
    final List<String> crumbSegments = widget.isMainScreen
        ? [labelHome]
        : [labelHome, widget.pageTitle];

    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnim, _pulseAnim, _slideAnim]),
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          height: 84, // ✅ REDUCED from 200px to slim 84px
          decoration: BoxDecoration(
            color: kSurface1,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accent.withOpacity(0.45 + _glowAnim.value * 0.25),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(_glowAnim.value * 0.18),
                blurRadius: 22,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: kTextMain1.withOpacity(0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.5),
            child: Stack(
              children: [
                // ── Subtle dot-grid texture ──────────────────────────────
                Positioned.fill(
                  child: _DotGridOverlay(accent: accent),
                ),

                // ── Accent tint wash across top edge ──────────────────────
                Positioned(
                  top: 0, left: 0, right: 0,
                  height: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withOpacity(0.0),
                          accent.withOpacity(0.7 + _glowAnim.value * 0.3),
                          accent.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Main content: Compact row layout ──────────────────────
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ┄┄ LEFT: Breadcrumb + Status ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Breadcrumb
                              Text(
                                crumbSegments.join(' › '),
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.orbitron(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: accent.withOpacity(0.55),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              // Main status label
                              Text(
                                mainLabel,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Sub status label
                              Text(
                                subLabel,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: accent.withOpacity(0.65),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // ┄┄ CENTER: Status Orb ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
                        _StatusOrb(
                          color: accent,
                          icon: _gestureIcon(widget.stableDirection),
                          glowOpacity: _glowAnim.value,
                          pulse: _pulseAnim.value,
                        ),

                        const SizedBox(width: 12),

                        // ┄┄ RIGHT: Signal Strength + Time ┄┄┄┄┄┄┄┄┄┄┄┄┄┄
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SignalStrengthRow(
                                active: isTracking,
                                color: accent,
                                labelActive: labelSignal,
                                labelInactive: labelSearching,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                timeStr,
                                style: GoogleFonts.orbitron(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: accent.withOpacity(0.7),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateStr,
                                style: GoogleFonts.orbitron(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w500,
                                  color: accent.withOpacity(0.5),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

// ─────────────────────────────────────────────────────────────────────────────
//  _DotGridOverlay
// ─────────────────────────────────────────────────────────────────────────────

class _DotGridOverlay extends StatelessWidget {
  final Color accent;
  const _DotGridOverlay({required this.accent});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotGridPainter(
        accentColor: accent,
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color accentColor;

  _DotGridPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double spacing = 18;
    final Paint paint = Paint()
      ..color = accentColor.withOpacity(0.06)
      ..strokeWidth = 0.8;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  _StatusOrb
// ─────────────────────────────────────────────────────────────────────────────

class _StatusOrb extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double glowOpacity;
  final double pulse;

  const _StatusOrb({
    required this.color,
    required this.icon,
    required this.glowOpacity,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.9 + pulse * 0.1,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.10),
          border: Border.all(color: color.withOpacity(0.45), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(glowOpacity * 0.30),
              blurRadius: 14,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _SignalStrengthRow
// ─────────────────────────────────────────────────────────────────────────────

class _SignalStrengthRow extends StatelessWidget {
  final bool active;
  final Color color;
  final String labelActive;
  final String labelInactive;

  const _SignalStrengthRow({
    required this.active,
    required this.color,
    required this.labelActive,
    required this.labelInactive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          active ? labelActive : labelInactive,
          style: GoogleFonts.cairo(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color.withOpacity(0.55),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: List.generate(5, (i) {
            final lit = active ? i < 4 : i < 1;
            return Container(
              margin: const EdgeInsets.only(right: 3),
              width: 4,
              height: 6 + i * 2.5,
              decoration: BoxDecoration(
                color: lit ? color : color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
                boxShadow: lit
                    ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 4)]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}