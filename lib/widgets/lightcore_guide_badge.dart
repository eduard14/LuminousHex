import 'package:flutter/material.dart';

import '../models/lightcore_guide.dart';
import '../theme/lightcore_palette.dart';

class LightcoreGuideBadge extends StatelessWidget {
  const LightcoreGuideBadge({super.key, required this.guide, this.size = 48});

  final LightcoreGuideProfile guide;
  final double size;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.34);
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: LightcorePalette.layer2,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
    );

    // Placeholder badge until guide portrait assets are added.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          colors: [
            LightcorePalette.aether.withValues(alpha: 0.3),
            LightcorePalette.violet.withValues(alpha: 0.24),
            LightcorePalette.panelRaised,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: LightcorePalette.aether.withValues(alpha: 0.48),
        ),
        boxShadow: [
          BoxShadow(
            color: LightcorePalette.aether.withValues(alpha: 0.16),
            blurRadius: size * 0.24,
            spreadRadius: size * 0.02,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.12,
            right: size * 0.12,
            child: Icon(
              Icons.smart_toy_rounded,
              size: size * 0.24,
              color: LightcorePalette.aether.withValues(alpha: 0.9),
            ),
          ),
          Text(guide.placeholderLabel, style: labelStyle),
        ],
      ),
    );
  }
}
