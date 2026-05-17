import 'package:flutter/material.dart';

/// Draws four semi-transparent red calibration dots at the screen edges.
/// Wrap around [MaterialApp]'s child in the builder callback.
class EyeTrackerDots extends StatelessWidget {
  final Widget child;
  const EyeTrackerDots({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          const Align(
              alignment: Alignment.topCenter,
              child: Padding(padding: EdgeInsets.only(top: 8), child: _Dot())),
          const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                  padding: EdgeInsets.only(bottom: 8), child: _Dot())),
          const Align(
              alignment: Alignment.centerLeft,
              child: Padding(padding: EdgeInsets.only(left: 8), child: _Dot())),
          const Align(
              alignment: Alignment.centerRight,
              child:
                  Padding(padding: EdgeInsets.only(right: 8), child: _Dot())),
        ],
      );
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 2)
            ],
          ),
        ),
      );
}
