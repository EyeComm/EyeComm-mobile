import 'package:flutter/material.dart';

/// Large, high-contrast card for quadriplegic users controlling the app by eye.
/// Behaves as a toggle (ON/OFF visual) when [isNav] = false,
/// or as a navigation button when [isNav] = true.
class AccessibleCard extends StatelessWidget {
  final String text;
  final Color color;
  final bool isActive;
  final bool isNav;
  final VoidCallback? onTap;

  const AccessibleCard({
    super.key,
    required this.text,
    required this.color,
    this.isActive = false,
    this.isNav = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double cardW = (screen.width / 2) - 20.0;
    final double cardH = (screen.height / 3) - 24.0;

    final Color bg = isActive
        ? color
        : (isNav ? color.withOpacity(0.85) : Colors.grey.shade800);
    final Color borderColor =
        isActive ? Colors.white : Colors.transparent;
    final Color glow =
        isActive ? color.withOpacity(0.6) : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: cardW,
        height: cardH,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(color: glow, blurRadius: 24, spreadRadius: 4),
            BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isNav) _TogglePill(isActive: isActive),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.25,
                  shadows: [
                    Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8)
                  ],
                ),
              ),
            ),
            if (isNav) ...[
              const SizedBox(height: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white70, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final bool isActive;
  const _TogglePill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 80,
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withOpacity(0.25)
            : Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: isActive
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color:
                  isActive ? Colors.white : Colors.grey.shade600,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4)
              ],
            ),
            child: Icon(
              isActive
                  ? Icons.power_settings_new
                  : Icons.power_off,
              color: isActive
                  ? Colors.green.shade700
                  : Colors.grey.shade400,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
