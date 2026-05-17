import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../core/eye_utils.dart';
import 'shared.dart';

class DeviceSwitchCard extends StatelessWidget {
  final String iconAsset; // ⬅️ التعديل هنا: مسار الصورة بدل الإيموجي
  final String label;
  final String gestureName;
  final String eyeCmd;
  final bool isOn;
  final Color activeColor;
  final String? statusText;
  final VoidCallback? onTap;

  final String stable;
  final int cd;
  final int totalTimer;

  const DeviceSwitchCard({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.gestureName,
    required this.eyeCmd,
    required this.isOn,
    required this.activeColor,
    this.statusText,
    this.onTap,
    required this.stable,
    required this.cd,
    required this.totalTimer,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = stable == eyeCmd && cd > 0;
    final Color cardBg = active ? activeColor.withOpacity(0.12) : kSurface1;
    final Color borderColor = active ? activeColor.withOpacity(0.5) : kBorder1;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: active ? 1.8 : 1.0),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: activeColor.withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 4))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Stack(
          children: [
            Positioned(
                top: 12,
                right: 12,
                child: _SmallSwitch(isOn: isOn, activeColor: activeColor)),
            LayoutBuilder(builder: (ctx, box) {
              final double iconSize = (box.maxWidth * 0.22).clamp(24.0, 48.0);
              final double badgeSide = iconSize * 1.7;
              final double labelFs = (box.maxWidth * 0.093).clamp(11.0, 17.0);
              final double gestureFs = (box.maxWidth * 0.072).clamp(9.0, 13.0);
              final double vGap = (box.maxHeight * 0.04).clamp(4.0, 12.0);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── 🎯 استخدام الصورة (Asset) هنا ──
                  Container(
                    width: badgeSide,
                    height: badgeSide,
                    decoration: BoxDecoration(
                      color: isOn
                          ? activeColor.withOpacity(0.15)
                          : kBorder1.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(badgeSide * 0.26),
                    ),
                    child: Center(
                      child: Image.asset(
                        iconAsset,
                        width: iconSize * 0.8,
                        height: iconSize * 0.8,
                        // الصورة هتاخد لون الكارت لو شغال، أو رمادي لو مطفي
                        color: isOn ? activeColor : kTextSub1,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.broken_image, color: kTextSub1),
                      ),
                    ),
                  ),
                  SizedBox(height: vGap),

                  Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: GoogleFonts.cairo(
                          fontSize: labelFs,
                          fontWeight: FontWeight.w800,
                          color: kTextMain1)),

                  if (statusText != null)
                    Text(statusText!,
                        style: GoogleFonts.cairo(
                            fontSize: labelFs * 0.75,
                            fontWeight: FontWeight.bold,
                            color: isOn ? activeColor : kTextSub1))
                  else
                    SizedBox(height: labelFs * 0.75),

                  SizedBox(height: vGap * 0.75),

                  GestureBadge(
                      gesture: gestureName,
                      fg: activeColor,
                      fs: gestureFs,
                      eyeCmd: eyeCmd),

                  SizedBox(height: vGap),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: box.maxWidth * 0.1),
                    child: Opacity(
                      opacity: active ? 1.0 : 0.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                            value: active
                                ? (totalTimer - cd) / totalTimer.toDouble()
                                : 0.0,
                            minHeight: 4,
                            backgroundColor: kBorder1,
                            color: activeColor),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SmallSwitch extends StatelessWidget {
  final bool isOn;
  final Color activeColor;

  const _SmallSwitch({required this.isOn, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 42,
      height: 22,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isOn ? activeColor.withOpacity(0.3) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isOn ? activeColor.withOpacity(0.5) : Colors.grey.shade400,
            width: 1.5),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOn ? activeColor : Colors.grey.shade500),
        ),
      ),
    );
  }
}
