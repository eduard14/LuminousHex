part of '../daily_dungeons_screen.dart';

class _DungeonRunTopBar extends StatelessWidget {
  const _DungeonRunTopBar({
    required this.towerProfile,
    required this.towerLevel,
    required this.remainingSeconds,
    required this.timeProgress,
    required this.towerHealth,
    required this.towerMaxHealth,
    required this.towerIntegrity,
    required this.onExit,
  });

  final LightcoreDailyDungeonTowerProfile towerProfile;
  final int towerLevel;
  final double remainingSeconds;
  final double timeProgress;
  final double towerHealth;
  final double towerMaxHealth;
  final double towerIntegrity;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = towerProfile.affinity.color;
    return AuroraPanel(
      tint: tint,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          _IconBadge(icon: Icons.account_tree_rounded, tint: tint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Threat Director Lv $towerLevel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${remainingSeconds.ceil()}s',
                      style: textTheme.titleMedium?.copyWith(
                        color: LightcorePalette.aether,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: MeterBar(
                        value: timeProgress,
                        color: LightcorePalette.aether,
                        height: 8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MeterBar(
                        value: towerIntegrity,
                        color: tint,
                        height: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Exit dungeon',
            child: IconButton.filledTonal(
              onPressed: onExit,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _DungeonLaunchDock extends StatelessWidget {
  const _DungeonLaunchDock({
    required this.controller,
    required this.anomalyCards,
    required this.apexCard,
    required this.cooldowns,
    required this.running,
    required this.compact,
    required this.onLaunch,
  });

  final LightcoreController controller;
  final List<EnemyCardState> anomalyCards;
  final EnemyCardState? apexCard;
  final Map<String, double> cooldowns;
  final bool running;
  final bool compact;
  final void Function(EnemyCardState card, {required bool apex}) onLaunch;

  @override
  Widget build(BuildContext context) {
    return AuroraPanel(
      tint: LightcorePalette.aether,
      radius: 20,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 8 : 10,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final card in anomalyCards) ...[
              _DungeonLaunchButton(
                card: card,
                apex: false,
                cooldown: cooldowns[_dungeonLaunchKey(card, apex: false)] ?? 0,
                cooldownSeconds: _dungeonDeployCooldown(controller, card),
                running: running,
                compact: compact,
                onLaunch: () => onLaunch(card, apex: false),
              ),
              SizedBox(width: compact ? 8 : 10),
            ],
            if (apexCard != null)
              _DungeonLaunchButton(
                card: apexCard!,
                apex: true,
                cooldown:
                    cooldowns[_dungeonLaunchKey(apexCard!, apex: true)] ?? 0,
                cooldownSeconds: _dungeonDeployCooldown(
                  controller,
                  apexCard!,
                  apex: true,
                ),
                running: running,
                compact: compact,
                onLaunch: () => onLaunch(apexCard!, apex: true),
              )
            else
              _LockedApexButton(compact: compact),
          ],
        ),
      ),
    );
  }
}

class _DungeonLaunchButton extends StatelessWidget {
  const _DungeonLaunchButton({
    required this.card,
    required this.apex,
    required this.cooldown,
    required this.cooldownSeconds,
    required this.running,
    required this.compact,
    required this.onLaunch,
  });

  final EnemyCardState card;
  final bool apex;
  final double cooldown;
  final double cooldownSeconds;
  final bool running;
  final bool compact;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    final tint = apex ? LightcorePalette.solar : card.config.affinity.color;
    final ready = running && cooldown <= 0;
    final size = compact ? 76.0 : 90.0;
    final progress = cooldownSeconds <= 0
        ? 0.0
        : (cooldown / cooldownSeconds).clamp(0.0, 1.0).toDouble();
    return Tooltip(
      message: ready
          ? 'Launch ${card.config.name}'
          : '${card.config.name} cooldown',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: ready ? onLaunch : null,
        child: SizedBox(
          width: size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.square(
                    dimension: compact ? 50 : 58,
                    child: CircularProgressIndicator(
                      value: ready ? 1 : 1 - progress,
                      strokeWidth: 4,
                      color: ready ? LightcorePalette.success : tint,
                      backgroundColor: LightcorePalette.stroke.withValues(
                        alpha: 0.32,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tint.withValues(alpha: ready ? 0.22 : 0.1),
                      border: Border.all(color: tint.withValues(alpha: 0.42)),
                    ),
                    child: SizedBox.square(
                      dimension: compact ? 42 : 48,
                      child: Icon(
                        apex ? Icons.shield_moon_rounded : Icons.adjust_rounded,
                        color: ready
                            ? tint
                            : LightcorePalette.mist.withValues(alpha: 0.48),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                apex ? 'Apex' : card.config.affinity.shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: ready
                      ? LightcorePalette.mist
                      : LightcorePalette.mist.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                cooldown <= 0 ? 'Ready' : '${cooldown.ceil()}s',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ready ? LightcorePalette.success : tint,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedApexButton extends StatelessWidget {
  const _LockedApexButton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 76.0 : 90.0;
    return Tooltip(
      message: 'Resolve an Apex Scan to add an apex launch icon',
      child: SizedBox(
        width: size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LightcorePalette.stroke.withValues(alpha: 0.18),
                border: Border.all(
                  color: LightcorePalette.stroke.withValues(alpha: 0.46),
                ),
              ),
              child: SizedBox.square(
                dimension: compact ? 50 : 58,
                child: const Icon(Icons.lock_rounded),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Apex',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.52),
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Locked',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.42),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DungeonResultPanel extends StatelessWidget {
  const _DungeonResultPanel({
    required this.victory,
    required this.towerLevel,
    required this.onExit,
  });

  final bool victory;
  final int towerLevel;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final tint = victory ? LightcorePalette.success : LightcorePalette.warning;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: AuroraPanel(
        tint: tint,
        radius: 22,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(
              icon: victory
                  ? Icons.check_circle_rounded
                  : Icons.timer_off_rounded,
              tint: tint,
            ),
            const SizedBox(height: 12),
            Text(
              victory ? 'Tower Cleared' : 'Run Expired',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              victory
                  ? 'Threat Director Lv $towerLevel is broken. The next level is ready from the dungeon menu.'
                  : 'Threat Director Lv $towerLevel held. Upgrade anomalies or change the loadout before the next run.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onExit,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Return to Dungeon Menu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DungeonHeader extends StatelessWidget {
  const _DungeonHeader({
    required this.dailyKey,
    required this.ownedEnemyCount,
    required this.selectedLoadoutCount,
  });

  final String dailyKey;
  final int ownedEnemyCount;
  final int selectedLoadoutCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Dungeons', style: textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Event combat runs on its own screen while the base shell is parked in idle progress. The first route is live now; the other two are reserved for future rotations.',
          style: textTheme.bodyMedium?.copyWith(
            color: LightcorePalette.mist.withValues(alpha: 0.76),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoChip(
              icon: Icons.today_rounded,
              label: dailyKey,
              tint: LightcorePalette.aether,
            ),
            _InfoChip(
              icon: Icons.adjust_rounded,
              label: '$ownedEnemyCount anomalies',
              tint: LightcorePalette.verdant,
            ),
            _InfoChip(
              icon: Icons.toll_rounded,
              label: '$selectedLoadoutCount selected',
              tint: LightcorePalette.solar,
            ),
          ],
        ),
      ],
    );
  }
}
