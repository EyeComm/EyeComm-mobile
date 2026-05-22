import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import 'eye_camera_preview.dart';

/// 🎯 NEW WIDGET: TrackingCameraCard
///
/// A large, dedicated camera preview card designed to be placed in the grid layout.
/// - Extracted from ModernTrackingQualityBar to solve aspect ratio distortion
/// - Non-interactive (cannot trigger eye actions)
/// - Includes LIVE indicator and subtle tracking glow
/// - Maintains proper aspect ratio on Windows desktop
/// - Matches DynamicEyeCard visual style
///
/// Usage in BaseGridPage:
/// ```dart
/// if (showCameraCard) {
///   itemBuilder: (ctx, i, item, stable, cd, timer) {
///     if (i == 0) {
///       return TrackingCameraCard(
///         currentEye: stable,
///         serverBase: widget.serverBase,
///         accentColor: widget.color,
///       );
///     }
///     return DynamicEyeCard(item: item, stable: stable, cd: cd, totalTimer: timer);
///   }
/// }
/// ```
class TrackingCameraCard extends StatefulWidget {
  /// The current eye direction (for glow effect feedback)
  final String currentEye;

  /// API endpoint for eye tracking data
  final String serverBase;

  /// Primary accent color matching the screen theme
  final Color accentColor;

  /// Optional: Show subtle gesture label if eye is detected
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
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTracking = widget.currentEye != 'none';
    final Color glowColor = isTracking
        ? widget.accentColor
        : const Color(0xFFF59E0B); // Yellow when searching

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: kSurface1,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: glowColor.withOpacity(0.35 + _glowAnim.value * 0.2),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(_glowAnim.value * 0.15),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // ── Camera preview (fills entire card) ─────────────────────
                Positioned.fill(
                  child: EyeCameraPreview(
                    serverBase: widget.serverBase,
                  ),
                ),

                // ── LIVE badge (top-left corner) ──────────────────────────
                Positioned(
                  top: 12,
                  left: 12,
                  child: _LiveIndicator(
                    isTracking: isTracking,
                    glowColor: glowColor,
                    glowOpacity: _glowAnim.value,
                  ),
                ),

                // ── Optional: Gesture indicator (top-right corner) ────────
                if (widget.showGestureLabel && isTracking)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _GestureIndicator(
                      eyeDirection: widget.currentEye,
                      color: glowColor,
                    ),
                  ),

                // ── Subtle tracking indicator bar (bottom) ────────────────
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
                          glowColor.withOpacity(0.5 + _glowAnim.value * 0.4),
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

// ─────────────────────────────────────────────────────────────────────────────
//  _LiveIndicator – Shows "LIVE" badge with pulsing glow
// ─────────────────────────────────────────────────────────────────────────────

class _LiveIndicator extends StatelessWidget {
  final bool isTracking;
  final Color glowColor;
  final double glowOpacity;

  const _LiveIndicator({
    required this.isTracking,
    required this.glowColor,
    required this.glowOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: glowColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glowColor.withOpacity(0.35), width: 1),
        boxShadow: [
          if (isTracking)
            BoxShadow(
              color: glowColor.withOpacity(glowOpacity * 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: glowColor,
              boxShadow: isTracking
                  ? [
                BoxShadow(
                  color: glowColor.withOpacity(glowOpacity * 0.5),
                  blurRadius: 4,
                ),
              ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isTracking ? 'LIVE' : 'OFF',
            style: GoogleFonts.orbitron(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: glowColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _GestureIndicator – Shows current eye direction
// ─────────────────────────────────────────────────────────────────────────────

class _GestureIndicator extends StatelessWidget {
  final String eyeDirection;
  final Color color;

  const _GestureIndicator({
    required this.eyeDirection,
    required this.color,
  });

  String _directionEmoji(String dir) {
    switch (dir) {
      case 'left':   return '⬅️';
      case 'right':  return '➡️';
      case 'up':     return '⬆️';
      case 'down':   return '⬇️';
      case 'closed': return '◉';
      default:       return '●';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Text(
        _directionEmoji(eyeDirection),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}