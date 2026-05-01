import 'package:flutter/material.dart';

import '../theme/lightcore_palette.dart';
import 'aurora_panel.dart';

class LightcoreRunLoading extends StatelessWidget {
  const LightcoreRunLoading({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tint,
    this.icon = Icons.play_circle_fill_rounded,
  });

  final String title;
  final String subtitle;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            LightcorePalette.night,
            LightcorePalette.abyss,
            Color.lerp(LightcorePalette.abyss, tint, 0.18)!,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: AuroraPanel(
                tint: tint,
                radius: 22,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 42, color: tint),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: LightcorePalette.mist.withValues(alpha: 0.76),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(tint),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
