part of '../daily_dungeons_screen.dart';

class _DungeonResultPanel extends StatelessWidget {
  const _DungeonResultPanel({
    required this.victory,
    required this.towerLevel,
    required this.onExit,
    this.successTitle,
    this.failureTitle,
    this.successMessage,
    this.failureMessage,
  });

  final bool victory;
  final int towerLevel;
  final VoidCallback onExit;
  final String? successTitle;
  final String? failureTitle;
  final String? successMessage;
  final String? failureMessage;

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
              victory
                  ? successTitle ?? 'Tower Cleared'
                  : failureTitle ?? 'Run Expired',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              victory
                  ? successMessage ??
                        'Threat Director Lv $towerLevel is broken. The next level is ready from the dungeon menu.'
                  : failureMessage ??
                        'Threat Director Lv $towerLevel held. Upgrade anomalies or change the loadout before the next run.',
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
  const _DungeonHeader({required this.dailyKey, required this.ownedEnemyCount});

  final String dailyKey;
  final int ownedEnemyCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Dungeons', style: textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Choose a route to open setup, rewards, and play.',
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
          ],
        ),
      ],
    );
  }
}
