import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../core/eye_utils.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GestureBadge
// Small pill that shows the eye-gesture icon + label inside a card.
// ═══════════════════════════════════════════════════════════════════════════
class GestureBadge extends StatelessWidget {
  final String gesture;
  final Color fg;
  final double fs;
  final String eyeCmd;

  const GestureBadge({
    super.key,
    required this.gesture,
    required this.fg,
    required this.fs,
    required this.eyeCmd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: fs * 0.85, vertical: fs * 0.32),
      decoration: BoxDecoration(
        color: fg.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.25), width: 0.8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Image.asset(
          assetForEye(eyeCmd),
          width: fs + 4,
          height: fs + 4,
          color: fg,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.remove_red_eye_outlined, size: fs + 1, color: fg),
        ),
        SizedBox(width: fs * 0.35),
        Flexible(
          child: Text(
            gesture,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
                fontSize: fs, fontWeight: FontWeight.w600, color: fg),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DynamicEyeCard
// The main interactive card used on every grid screen.
// ═══════════════════════════════════════════════════════════════════════════
class DynamicEyeCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String stable;   // which eye gesture is currently held
  final int cd;          // countdown seconds remaining
  final int totalTimer;

  const DynamicEyeCard({
    super.key,
    required this.item,
    required this.stable,
    required this.cd,
    required this.totalTimer,
  });

  String _extractEmoji(String t) {
    final r = RegExp(
        r'[\u{1F300}-\u{1FAFF}]|[\u{2600}-\u{27BF}]|[\u{1F600}-\u{1F64F}]',
        unicode: true);
    return r.firstMatch(t)?.group(0) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final Color c      = item['color'] as Color;
    final String eye   = item['eye'] as String;
    final String text  = item['text'].toString();
    final String emoji = _extractEmoji(text);
    final String label = cleanForSpeech(text);
    final String ename = item['eye_name']?.toString() ?? eyeName(eye);
    final bool active  = stable == eye && cd > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: active ? c.withOpacity(0.12) : kSurface1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? c.withOpacity(0.5) : kBorder1,
          width: active ? 1.8 : 1.0,
        ),
        boxShadow: active
            ? [BoxShadow(
                color: c.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 4))]
            : [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))],
      ),
      child: LayoutBuilder(builder: (ctx, box) {
        final double iconSize  = (box.maxWidth * 0.22).clamp(24.0, 48.0);
        final double badgeSide = iconSize * 1.7;
        final double labelFs   = (box.maxWidth * 0.093).clamp(11.0, 17.0);
        final double gestureFs = (box.maxWidth * 0.072).clamp(9.0, 13.0);
        final double vGap      = (box.maxHeight * 0.04).clamp(4.0, 12.0);
        final double hPad      = box.maxWidth * 0.07;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Emoji badge ──────────────────────────────────────────────
            Container(
              width: badgeSide,
              height: badgeSide,
              decoration: BoxDecoration(
                color: c.withOpacity(0.15),
                borderRadius: BorderRadius.circular(badgeSide * 0.26),
              ),
              child: Center(
                child:
                    Text(emoji, style: TextStyle(fontSize: iconSize * 0.8)),
              ),
            ),
            SizedBox(height: vGap),

            // ── Label ────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                    fontSize: labelFs,
                    fontWeight: FontWeight.w800,
                    color: kTextMain1),
              ),
            ),
            SizedBox(height: vGap * 0.75),

            // ── Gesture badge ────────────────────────────────────────────
            GestureBadge(
                gesture: ename, fg: c, fs: gestureFs, eyeCmd: eye),

            // ── Progress bar (only while active) ────────────────────────
            if (active) ...[
              SizedBox(height: vGap),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad * 1.4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (totalTimer - cd) / totalTimer.toDouble(),
                    minHeight: 4,
                    backgroundColor: kBorder1,
                    color: c,
                  ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}
