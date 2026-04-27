import 'package:flutter/material.dart';

import '../theme/lightcore_palette.dart';

class MeterBar extends StatelessWidget {
  const MeterBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 10,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0, 1).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: LightcorePalette.panelRaised.withValues(alpha: 0.72),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: clampedValue, end: clampedValue),
          builder: (context, animatedValue, child) {
            return FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: animatedValue,
              child: child,
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.72), color],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
