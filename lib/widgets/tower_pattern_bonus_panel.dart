import 'package:flutter/material.dart';

import '../models/lightcore_config.dart';
import '../theme/lightcore_palette.dart';

class TowerPatternBonusPanel extends StatelessWidget {
  const TowerPatternBonusPanel({
    super.key,
    required this.achievements,
    required this.hint,
    required this.tint,
    this.title = 'Tower Achievements',
  });

  final List<TowerPatternAchievement> achievements;
  final String hint;
  final Color tint;
  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        if (achievements.isEmpty)
          Text(hint, style: textTheme.bodyMedium)
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final achievement in achievements)
                _TowerPatternAchievementCard(
                  achievement: achievement,
                  tint: tint,
                ),
            ],
          ),
      ],
    );
  }
}

class _TowerPatternAchievementCard extends StatelessWidget {
  const _TowerPatternAchievementCard({
    required this.achievement,
    required this.tint,
  });

  final TowerPatternAchievement achievement;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: LightcorePalette.panelRaised.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tint.withValues(alpha: 0.32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PATTERN',
              style: textTheme.labelSmall?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.72),
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.name,
              style: textTheme.titleMedium?.copyWith(
                color: tint,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(achievement.summary, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
