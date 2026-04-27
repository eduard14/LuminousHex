import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import 'guided_focus_frame.dart';

class RadianceStatAllocator extends StatelessWidget {
  const RadianceStatAllocator({
    super.key,
    required this.controller,
    this.highlighted = false,
    this.title = 'Radiance Attributes',
  });

  final LightcoreController controller;
  final bool highlighted;
  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ready = controller.unspentRadianceStatPoints;
    final earned = controller.totalRadianceStatPointsEarned;
    final spent = controller.totalRadianceStatPointsSpent;

    return GuidedFocusFrame(
      active: highlighted,
      tint: LightcorePalette.quest,
      label: 'STATS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: LightcorePalette.quest),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: LightcorePalette.mist,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _RadiancePointChip(ready: ready, spent: spent, earned: earned),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : 560.0;
              final compact = maxWidth < 520;
              final tileWidth = compact
                  ? maxWidth
                  : math.min(320.0, (maxWidth - 12) / 2);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final stat in LightcoreRadianceStat.values)
                    SizedBox(
                      width: tileWidth,
                      child: _RadianceStatTile(
                        controller: controller,
                        stat: stat,
                        ready: ready,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RadiancePointChip extends StatelessWidget {
  const _RadiancePointChip({
    required this.ready,
    required this.spent,
    required this.earned,
  });

  final int ready;
  final int spent;
  final int earned;

  @override
  Widget build(BuildContext context) {
    final tint = ready > 0 ? LightcorePalette.quest : LightcorePalette.stroke;
    final label = ready > 0 ? '$ready ready' : '$spent/$earned spent';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: ready > 0 ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.36)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: ready > 0 ? LightcorePalette.quest : LightcorePalette.mist,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RadianceStatTile extends StatelessWidget {
  const _RadianceStatTile({
    required this.controller,
    required this.stat,
    required this.ready,
  });

  final LightcoreController controller;
  final LightcoreRadianceStat stat;
  final int ready;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = _radianceStatTint(stat);
    final rank = controller.radianceStatRank(stat);
    final canUpgrade = controller.canUpgradeRadianceStat(stat);

    return Container(
      constraints: const BoxConstraints(minHeight: 144),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tint.withValues(alpha: canUpgrade ? 0.48 : 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_radianceStatIcon(stat), color: tint, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.radianceStatLabel(stat),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${controller.radianceStatShortLabel(stat)} $rank',
                style: textTheme.labelMedium?.copyWith(
                  color: LightcorePalette.mist,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            controller.radianceStatEffectLabel(stat),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: LightcorePalette.mist,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            controller.radianceStatGameplayLabel(stat),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: LightcorePalette.mist.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canUpgrade
                  ? () => controller.upgradeRadianceStat(stat)
                  : null,
              icon: Icon(
                ready > 0
                    ? Icons.add_circle_outline_rounded
                    : Icons.lock_clock_rounded,
              ),
              label: Text(ready > 0 ? 'Add Point' : 'No Points'),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _radianceStatIcon(LightcoreRadianceStat stat) => switch (stat) {
  LightcoreRadianceStat.might => Icons.fitness_center_rounded,
  LightcoreRadianceStat.focus => Icons.center_focus_strong_rounded,
  LightcoreRadianceStat.tempo => Icons.speed_rounded,
  LightcoreRadianceStat.insight => Icons.psychology_rounded,
};

Color _radianceStatTint(LightcoreRadianceStat stat) => switch (stat) {
  LightcoreRadianceStat.might => LightcorePalette.flare,
  LightcoreRadianceStat.focus => LightcorePalette.aether,
  LightcoreRadianceStat.tempo => LightcorePalette.solar,
  LightcoreRadianceStat.insight => LightcorePalette.violet,
};
