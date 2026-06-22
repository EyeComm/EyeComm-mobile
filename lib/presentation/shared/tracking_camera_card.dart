import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.08, end: 0.25).animate(
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
        ? _colorForEye(widget.currentEye)
        : const Color(0xFF90A4AE);

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
              fit: StackFit.expand,
              children: [
                // ✅ key ثابت يضمن إن الحالة (الستريم) متتحفظش وتتعاد
                // من غير داعي لو الـ Widget اتبنى تاني بنفس السيرفر
                EyeCameraPreview(
                  key: ValueKey('eye_cam_${widget.serverBase}'),
                  serverBase: widget.serverBase,
                  stableDirection: widget.currentEye,
                ),
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