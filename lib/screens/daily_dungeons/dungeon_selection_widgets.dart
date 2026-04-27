part of '../daily_dungeons_screen.dart';

class _DungeonSelectCard extends StatelessWidget {
  const _DungeonSelectCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.selected,
    required this.enabled,
    required this.statusLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final bool selected;
  final bool enabled;
  final String statusLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activeTint = enabled ? tint : LightcorePalette.stroke;
    return AuroraPanel(
      tint: activeTint,
      radius: 18,
      padding: const EdgeInsets.all(14),
      onTap: enabled ? onTap : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBadge(icon: icon, tint: activeTint),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: LightcorePalette.mist.withValues(
                          alpha: enabled ? 0.76 : 0.52,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusCapsule(label: statusLabel, tint: activeTint),
              const Spacer(),
              if (selected)
                Icon(Icons.check_circle_rounded, color: activeTint, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetTowerPanel extends StatelessWidget {
  const _TargetTowerPanel({
    required this.towerProfile,
    required this.towerLevel,
    required this.towerHealth,
    required this.towerMaxHealth,
    required this.towerIntegrity,
    required this.remainingSeconds,
    required this.timeProgress,
    required this.strongestRaidDamage,
    required this.activeRaids,
    required this.reward,
    required this.cleared,
    required this.running,
    required this.victory,
    required this.expired,
    required this.tint,
  });

  final LightcoreDailyDungeonTowerProfile towerProfile;
  final int towerLevel;
  final double towerHealth;
  final double towerMaxHealth;
  final double towerIntegrity;
  final double remainingSeconds;
  final double timeProgress;
  final double strongestRaidDamage;
  final List<_DungeonRaid> activeRaids;
  final LightcoreDailyDungeonReward reward;
  final bool cleared;
  final bool running;
  final bool victory;
  final bool expired;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.26)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final towerStage = _TowerBattleCanvas(
              towerProfile: towerProfile,
              towerLevel: towerLevel,
              integrity: towerIntegrity,
              activeRaids: activeRaids,
              tint: towerProfile.affinity.color,
              cleared: cleared || victory,
              running: running,
              expired: expired,
            );
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBadge(icon: Icons.account_tree_rounded, tint: tint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            towerProfile.title,
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cleared
                                ? 'First clear secured'
                                : 'First-clear reward ${reward.label}',
                            style: textTheme.bodySmall?.copyWith(
                              color: LightcorePalette.mist.withValues(
                                alpha: 0.68,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${remainingSeconds.ceil()}s',
                      style: textTheme.titleMedium?.copyWith(
                        color: LightcorePalette.aether,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _MeterLabelRow(
                  label: 'Tower Integrity',
                  value:
                      '${towerHealth.ceil().clamp(0, towerMaxHealth.ceil())}/${towerMaxHealth.round()}',
                ),
                const SizedBox(height: 6),
                MeterBar(value: towerIntegrity, color: tint, height: 12),
                const SizedBox(height: 12),
                _MeterLabelRow(
                  label: 'Time Window',
                  value: '${remainingSeconds.ceil()}s',
                ),
                const SizedBox(height: 6),
                MeterBar(
                  value: timeProgress,
                  color: LightcorePalette.aether,
                  height: 10,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: towerProjectileIcon(towerProfile.projectileType),
                      label: '${towerProfile.shotDamage.round()} counter shot',
                      tint: towerProfile.affinity.color,
                    ),
                    _InfoChip(
                      icon: Icons.bolt_rounded,
                      label: '${activeRaids.length} active',
                      tint: LightcorePalette.solar,
                    ),
                    _InfoChip(
                      icon: Icons.whatshot_rounded,
                      label: '${strongestRaidDamage.round()} top raid',
                      tint: tint,
                    ),
                  ],
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [towerStage, const SizedBox(height: 14), details],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 280, child: towerStage),
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

class _DungeonTowerLadder extends StatelessWidget {
  const _DungeonTowerLadder({
    required this.selectedLevel,
    required this.highestUnlockedLevel,
    required this.highestClearedLevel,
    required this.enabled,
    required this.onSelected,
  });

  final int selectedLevel;
  final int highestUnlockedLevel;
  final int highestClearedLevel;
  final bool enabled;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final start = math.max(1, highestUnlockedLevel - 7);
    final levels = <int>[
      for (var level = start; level <= highestUnlockedLevel; level += 1) level,
    ];
    final nextLockedLevel =
        highestUnlockedLevel < LightcoreController.dailyDungeonMaxTowerLevel
        ? highestUnlockedLevel + 1
        : null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final level in levels)
          _TowerLevelButton(
            level: level,
            selected: selectedLevel == level,
            cleared: level <= highestClearedLevel,
            locked: false,
            enabled: enabled,
            onTap: () => onSelected(level),
          ),
        if (nextLockedLevel != null)
          _TowerLevelButton(
            level: nextLockedLevel,
            selected: false,
            cleared: false,
            locked: true,
            enabled: false,
            onTap: null,
          ),
      ],
    );
  }
}

class _TowerLevelButton extends StatelessWidget {
  const _TowerLevelButton({
    required this.level,
    required this.selected,
    required this.cleared,
    required this.locked,
    required this.enabled,
    required this.onTap,
  });

  final int level;
  final bool selected;
  final bool cleared;
  final bool locked;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = locked
        ? LightcorePalette.stroke
        : cleared
        ? LightcorePalette.success
        : LightcorePalette.warning;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled && !locked ? onTap : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint.withValues(alpha: selected ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tint.withValues(alpha: selected ? 0.74 : 0.34),
            width: selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                locked
                    ? Icons.lock_rounded
                    : cleared
                    ? Icons.check_circle_rounded
                    : Icons.hexagon_rounded,
                size: 16,
                color: tint,
              ),
              const SizedBox(width: 6),
              Text(
                'Lv $level',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: locked
                      ? LightcorePalette.mist.withValues(alpha: 0.48)
                      : LightcorePalette.mist,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
