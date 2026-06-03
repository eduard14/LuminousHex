import 'package:flutter/material.dart';

import '../theme/lightcore_palette.dart';
import 'meter_bar.dart';

class TowerHealthBar extends StatelessWidget {
  const TowerHealthBar({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.height = 12,
  });

  final double value;
  final String label;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final health = value.clamp(0.0, 1.0).toDouble();
    final statusColor = health >= 0.55 ? color : LightcorePalette.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.health_and_safety_rounded, size: 16, color: statusColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Tower Health',
                style: textTheme.labelLarge?.copyWith(
                  color: LightcorePalette.mist,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        MeterBar(value: health, color: statusColor, height: height),
      ],
    );
  }
}
