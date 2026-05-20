import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../core/language_service.dart';
import 'eye_camera_preview.dart';

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

  String _gestureEmoji(String dir) {
    switch (dir) {
      case 'left':   return '⬅️';
      case 'right':  return '➡️';
      case 'up':     return '⬆️';
      case 'down':   return '⬇️';
      case 'closed': return '◉';
      default:       return '●';
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

    // ── i18n strings from language_service ───────────────────────────────
    final String labelHome      = AppLanguage.t('title') == 'EyeComm'
        ? (isArabic ? 'الرئيسية' : 'Home')
        : (isArabic ? 'الرئيسية' : 'Home');
    final String labelLive      = isArabic ? 'تتبع مباشر'    : 'Live Tracking';
    final String labelAwaiting  = isArabic ? 'انتظار الإشارة' : 'Awaiting Signal';
    final String labelConfirm   = isArabic ? 'جاري التأكيد...' : 'Confirming...';
    final String labelDetected  = isArabic ? 'العين محددة'   : 'Eye detected';
    final String labelNoSignal  = isArabic ? 'لا توجد إشارة' : 'No signal';
    final String labelGesture   = isArabic ? 'رُصدت حركة'   : 'GESTURE';
    final String labelStatus    = isArabic ? 'الحالة'        : 'STATUS';
    final String labelSignal    = isArabic ? 'إشارة'         : 'SIGNAL';
    final String labelSearching = isArabic ? 'بحث...'        : 'SEARCHING';
    final String labelConfirmingBar = isArabic ? 'جاري التأكيد' : 'CONFIRMING';

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
        ? labelConfirm
        : isTracking
        ? labelDetected
        : labelNoSignal;

    // ── Breadcrumb segments (dot separator, no arrows) ────────────────────
    // segments: ['Home'] or ['Home', 'Page Title']
    final List<String> crumbSegments = widget.isMainScreen
        ? [labelHome]
        : [labelHome, widget.pageTitle];

    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnim, _pulseAnim]),
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          height: 200,
          decoration: BoxDecoration(
            // ── Light surface from app_theme ──────────────────────────────
            color: kSurface1,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accent.withOpacity(0.45 + _glowAnim.value * 0.25),
              width: 1.8,
            ),
            boxShadow: [
              // Soft coloured glow (light-friendly, low opacity)
              BoxShadow(
                color: accent.withOpacity(_glowAnim.value * 0.18),
                blurRadius: 22,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
              // Subtle elevation shadow
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
                // ── Very subtle dot-grid texture (light theme version) ─────
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

                // ── Main row ──────────────────────────────────────────────
                Row(
                  // Honour RTL/LTR automatically via Directionality
                  textDirection: isArabic
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  children: [
                    // ── Camera panel ──────────────────────────────────────
                    _CameraPanel(
                      currentEye: widget.currentEye,
                      serverBase: widget.serverBase,
                      accent: accent,
                      isTracking: isTracking,
                      gestureActive: gestureActive,
                      pulseAnim: _pulseAnim,
                      glowAnim: _glowAnim,
                      isArabic: isArabic,
                    ),

                    // ── Info panel ────────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Column(
                          crossAxisAlignment: isArabic
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            // ── Row 1: Breadcrumb + DateTime ──────────────
                            Row(
                              textDirection: isArabic
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                // Dot-separated breadcrumb pill
                                Flexible(
                                  child: _BreadcrumbPill(
                                    segments: crumbSegments,
                                    accent: accent,
                                    isArabic: isArabic,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // DateTime chip
                                _DateTimeChip(
                                    timeStr: timeStr, dateStr: dateStr),
                              ],
                            ),

                            const Spacer(),

                            // ── Row 2: Orb + status text ──────────────────
                            SlideTransition(
                              position: _slideAnim,
                              child: FadeTransition(
                                opacity: _slideCtrl,
                                child: Row(
                                  textDirection: isArabic
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.center,
                                  children: [
                                    if (gestureActive)
                                      _CountdownOrb(
                                        value: widget.countdownSeconds,
                                        total: widget.totalTimer,
                                        color: accent,
                                        glowOpacity: _glowAnim.value,
                                        icon: _gestureIcon(
                                            widget.stableDirection),
                                      )
                                    else
                                      _StatusOrb(
                                        color: accent,
                                        icon: isTracking
                                            ? Icons.visibility_rounded
                                            : Icons.warning_amber_rounded,
                                        glowOpacity: _glowAnim.value,
                                        pulse: _pulseAnim.value,
                                      ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: isArabic
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (gestureActive) ...[
                                            Text(
                                              labelGesture,
                                              textDirection: isArabic
                                                  ? TextDirection.rtl
                                                  : TextDirection.ltr,
                                              style: GoogleFonts.cairo(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: accent.withOpacity(0.6),
                                                letterSpacing:
                                                isArabic ? 0 : 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              textDirection: isArabic
                                                  ? TextDirection.rtl
                                                  : TextDirection.ltr,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  mainLabel.toUpperCase(),
                                                  style: GoogleFonts.orbitron(
                                                    fontSize: 18,
                                                    fontWeight:
                                                    FontWeight.w900,
                                                    color: accent,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _gestureEmoji(
                                                      widget.stableDirection),
                                                  style: const TextStyle(
                                                      fontSize: 16),
                                                ),
                                              ],
                                            ),
                                          ] else ...[
                                            Text(
                                              labelStatus,
                                              textDirection: isArabic
                                                  ? TextDirection.rtl
                                                  : TextDirection.ltr,
                                              style: GoogleFonts.cairo(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                accent.withOpacity(0.55),
                                                letterSpacing:
                                                isArabic ? 0 : 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              mainLabel,
                                              textDirection: isArabic
                                                  ? TextDirection.rtl
                                                  : TextDirection.ltr,
                                              style: GoogleFonts.cairo(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w900,
                                                color: kTextMain1
                                                    .withOpacity(0.85),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 3),
                                          Text(
                                            subLabel,
                                            textDirection: isArabic
                                                ? TextDirection.rtl
                                                : TextDirection.ltr,
                                            style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              color: kTextSub1,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Spacer(),

                            // ── Row 3: Progress / signal ──────────────────
                            if (gestureActive)
                              _GestureProgressBar(
                                value: widget.totalTimer > 0
                                    ? (widget.totalTimer -
                                    widget.countdownSeconds) /
                                    widget.totalTimer.toDouble()
                                    : 0.0,
                                color: accent,
                                glowOpacity: _glowAnim.value,
                                label: labelConfirmingBar,
                              )
                            else
                              _SignalStrengthRow(
                                active: isTracking,
                                color: accent,
                                labelActive: labelSignal,
                                labelInactive: labelSearching,
                              ),
                          ],
                        ),
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
//  _BreadcrumbPill  –  dot-separated segments, no arrows
// ─────────────────────────────────────────────────────────────────────────────

class _BreadcrumbPill extends StatelessWidget {
  final List<String> segments;
  final Color accent;
  final bool isArabic;

  const _BreadcrumbPill({
    required this.segments,
    required this.accent,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.20), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Icon(Icons.route_rounded, size: 10, color: accent),
          const SizedBox(width: 5),
          Flexible(
            child: _BreadcrumbText(
              segments: segments,
              accent: accent,
              isArabic: isArabic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders  Home · Page  (or  الرئيسية · الصفحة ) with a small dot divider.
class _BreadcrumbText extends StatelessWidget {
  final List<String> segments;
  final Color accent;
  final bool isArabic;

  const _BreadcrumbText({
    required this.segments,
    required this.accent,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    // Build inline children: text, dot, text …
    final List<InlineSpan> spans = [];
    for (int i = 0; i < segments.length; i++) {
      final bool isLast = i == segments.length - 1;

      spans.add(TextSpan(
        text: segments[i],
        style: GoogleFonts.cairo(
          fontSize: 10,
          fontWeight: isLast ? FontWeight.w800 : FontWeight.w600,
          color: isLast ? accent : kTextSub1,
        ),
      ));

      if (!isLast) {
        // Small filled circle as separator — works perfectly in RTL too
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _DateTimeChip
// ─────────────────────────────────────────────────────────────────────────────

class _DateTimeChip extends StatelessWidget {
  final String timeStr;
  final String dateStr;

  const _DateTimeChip({required this.timeStr, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: kBg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder1, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeStr,
            style: GoogleFonts.orbitron(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kTextMain1.withOpacity(0.75),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 1,
            height: 10,
            color: kBorder1,
          ),
          Text(
            dateStr,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: kTextSub1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _DotGridOverlay  –  very subtle light-theme texture
// ─────────────────────────────────────────────────────────────────────────────

class _DotGridOverlay extends StatelessWidget {
  final Color accent;
  const _DotGridOverlay({required this.accent});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotGridPainter(color: accent.withOpacity(0.055)),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color color;
  _DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 18.0;
    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
//  _CameraPanel
// ─────────────────────────────────────────────────────────────────────────────

class _CameraPanel extends StatelessWidget {
  final String currentEye;
  final String serverBase;
  final Color accent;
  final bool isTracking;
  final bool gestureActive;
  final Animation<double> pulseAnim;
  final Animation<double> glowAnim;
  final bool isArabic;

  const _CameraPanel({
    required this.currentEye,
    required this.serverBase,
    required this.accent,
    required this.isTracking,
    required this.gestureActive,
    required this.pulseAnim,
    required this.glowAnim,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulseAnim, glowAnim]),
      builder: (context, child) {
        return Container(
          width: 190,
          decoration: BoxDecoration(
            border: Border(
              right: isArabic
                  ? BorderSide.none
                  : BorderSide(
                  color: accent.withOpacity(
                      0.18 + glowAnim.value * 0.12),
                  width: 1),
              left: isArabic
                  ? BorderSide(
                  color: accent.withOpacity(
                      0.18 + glowAnim.value * 0.12),
                  width: 1)
                  : BorderSide.none,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              EyeCameraPreview(
                currentEye: currentEye,
                serverBase: serverBase,
              ),

              // Corner brackets
              Positioned(
                top: 10, left: 10,
                child: _CornerBracket(color: accent, flipX: false, flipY: false),
              ),
              Positioned(
                bottom: 10, right: 10,
                child: _CornerBracket(color: accent, flipX: true, flipY: true),
              ),

              // LIVE badge
              if (isTracking)
                Positioned(
                  top: 12, right: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LIVE',
                        style: GoogleFonts.orbitron(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Transform.scale(
                        scale: gestureActive ? pulseAnim.value : 1.0,
                        child: Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withOpacity(0.55),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Inner-edge fade (always towards the info panel)
              Positioned.fill(
                child: Align(
                  alignment: isArabic
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    width: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kSurface1.withOpacity(0.0),
                          kSurface1.withOpacity(0.85),
                        ],
                        begin: isArabic
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        end: isArabic
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final Color color;
  final bool flipX;
  final bool flipY;
  const _CornerBracket(
      {required this.color, required this.flipX, required this.flipY});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flipX ? -1 : 1,
      scaleY: flipY ? -1 : 1,
      child: CustomPaint(
        size: const Size(16, 16),
        painter: _BracketPainter(color: color),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  _BracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, 10), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(10, 0), paint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.color != color;
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
//  _CountdownOrb
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownOrb extends StatelessWidget {
  final int value;
  final int total;
  final Color color;
  final double glowOpacity;
  final IconData icon;

  const _CountdownOrb({
    required this.value,
    required this.total,
    required this.color,
    required this.glowOpacity,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? value / total.toDouble() : 0.0;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(glowOpacity * 0.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: progress),
            duration: const Duration(milliseconds: 280),
            builder: (_, val, __) => SizedBox(
              width: 50, height: 50,
              child: CircularProgressIndicator(
                value: val,
                strokeWidth: 3.0,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.10),
              border: Border.all(color: color.withOpacity(0.30), width: 1),
            ),
            child: Center(
              child: Text(
                '$value',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _GestureProgressBar  – now receives translated label
// ─────────────────────────────────────────────────────────────────────────────

class _GestureProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double glowOpacity;
  final String label;

  const _GestureProgressBar({
    required this.value,
    required this.color,
    required this.glowOpacity,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color.withOpacity(0.65),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: GoogleFonts.orbitron(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: LayoutBuilder(
            builder: (context, _) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 250),
              builder: (_, val, __) => FractionallySizedBox(
                widthFactor: val.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.55), color],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(glowOpacity * 0.5),
                        blurRadius: 7,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _SignalStrengthRow  – now receives translated labels
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