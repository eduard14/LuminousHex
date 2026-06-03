part of '../daily_dungeons_screen.dart';

class _PrismRiftPreviewPanel extends StatelessWidget {
  const _PrismRiftPreviewPanel({
    required this.towerProfile,
    required this.towerLevel,
    required this.reward,
    required this.dailyReward,
    required this.riftStability,
    required this.cleared,
  });

  final LightcoreDailyDungeonTowerProfile towerProfile;
  final int towerLevel;
  final LightcoreDailyDungeonReward reward;
  final LightcoreDailyDungeonReward dailyReward;
  final double riftStability;
  final bool cleared;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = towerProfile.affinity.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: LightcorePalette.violet.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final stage = _TargetTowerBattlePreview(
              towerProfile: towerProfile,
              towerLevel: towerLevel,
              integrity: (riftStability / math.max(1.0, towerProfile.maxHealth))
                  .clamp(0.0, 1.0)
                  .toDouble(),
              tint: LightcorePalette.violet,
              cleared: cleared,
              running: false,
              expired: false,
              showLevelBadge: true,
            );
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBadge(icon: Icons.track_changes_rounded, tint: tint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rift Clear', style: textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            cleared
                                ? 'Daily clear reward ${dailyReward.label}'
                                : 'First pass reward ${reward.label}',
                            style: textTheme.bodySmall?.copyWith(
                              color: LightcorePalette.mist.withValues(
                                alpha: 0.68,
                              ),
                            ),
                          ),
                          if (!cleared) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Daily clear after first pass ${dailyReward.label}',
                              style: textTheme.bodySmall?.copyWith(
                                color: LightcorePalette.mist.withValues(
                                  alpha: 0.52,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _StatusCapsule(label: 'Lv $towerLevel', tint: tint),
                  ],
                ),
                const SizedBox(height: 14),
                _MeterLabelRow(
                  label: 'Rift Stability',
                  value: riftStability.round().toString(),
                ),
                const SizedBox(height: 6),
                MeterBar(value: 1, color: tint, height: 12),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: towerProjectileIcon(towerProfile.projectileType),
                      label: towerProfile.projectileType.label,
                      tint: tint,
                    ),
                    _InfoChip(
                      icon: Icons.bolt_rounded,
                      label: '${towerProfile.shotDamage.round()} base shot',
                      tint: LightcorePalette.aether,
                    ),
                    _InfoChip(
                      icon: Icons.adjust_rounded,
                      label: '${towerProfile.affinity.shortLabel} affinity',
                      tint: tint,
                    ),
                  ],
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [stage, const SizedBox(height: 14), details],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 280, child: stage),
                const SizedBox(width: 18),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }
}
