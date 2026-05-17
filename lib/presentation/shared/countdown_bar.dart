import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../core/language_service.dart';

/// Animated countdown progress bar shown alongside the camera preview.
class CountdownBar extends StatelessWidget {
  final int countdown;
  final int totalSeconds;
  final Color color;

  const CountdownBar({
    super.key,
    required this.countdown,
    required this.totalSeconds,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double progress =
        totalSeconds > 0 ? (totalSeconds - countdown) / totalSeconds : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLanguage.current == 'ar' ? '⏱ العد التنازلي' : '⏱ Countdown',
              style: GoogleFonts.cairo(
                  color: kTextMain, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: countdown > 0 ? color : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$countdown',
                style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 400),
            builder: (_, val, __) => LinearProgressIndicator(
              value: val,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: kProgress,
            ),
          ),
        ),
      ],
    );
  }
}
