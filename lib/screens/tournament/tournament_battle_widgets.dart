part of '../tournament_screen.dart';

class _TournamentBattleStage extends StatelessWidget {
  const _TournamentBattleStage({
    required this.controller,
    required this.active,
  });

  final LightcoreController controller;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BattleScreen(
        controller: controller,
        isActive: active,
        showQuestPanel: false,
        showBattleHud: false,
      ),
    );
  }
}

class _EnemyDraftTile extends StatelessWidget {
  const _EnemyDraftTile({
    required this.card,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.boss = false,
  });

  final EnemyCardState card;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final bool boss;

  @override
  Widget build(BuildContext context) {
    final tint = selected ? accent : card.config.affinity.color;
    return SizedBox(
      width: 118,
      child: SymbolGridTile(
        tint: tint,
        semanticLabel: card.config.name,
        selected: selected,
        onTap: onTap,
        topLeading: SymbolGridBadge(tint: tint, child: Text('Lv${card.level}')),
        topTrailing: boss
            ? SymbolGridBadge(
                tint: tint,
                child: const Icon(Icons.radio_button_checked_rounded, size: 12),
              )
            : null,
        center: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 82,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AffinityGlyph(affinity: card.config.affinity, size: 24),
                const SizedBox(height: 6),
                Text(
                  card.config.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
        bottomChildren: [
          SymbolGridBadge(
            tint: tint,
            child: Text(card.config.rarity.label.substring(0, 3).toUpperCase()),
          ),
        ],
      ),
    );
  }
}

class _HexGauntletPreview extends StatelessWidget {
  const _HexGauntletPreview({
    required this.laneIntegrity,
    required this.coreIntegrity,
    required this.builtLanes,
    required this.tint,
    this.onLaneTap,
  });

  final List<double> laneIntegrity;
  final double coreIntegrity;
  final List<bool> builtLanes;
  final Color tint;
  final ValueChanged<int>? onLaneTap;

  @override
  Widget build(BuildContext context) {
    const size = 260.0;
    const nodeSize = 74.0;
    const center = size / 2;
    const offset = 76.0;

    Offset positionForLane(int lane) {
      switch (lane) {
        case 0:
          return const Offset(center - (nodeSize / 2), center - offset - 10);
        case 1:
          return const Offset(center + 34, center - 46);
        case 2:
          return const Offset(center + 34, center + 24);
        case 3:
          return const Offset(center - (nodeSize / 2), center + offset - 10);
        case 4:
          return const Offset(center - 108, center + 24);
        case 5:
          return const Offset(center - 108, center - 46);
        default:
          return const Offset(center - (nodeSize / 2), center - offset - 10);
      }
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: center - (nodeSize / 2),
            top: center - (nodeSize / 2),
            child: _HexArenaNode(
              label: 'CORE',
              valueLabel: '${(coreIntegrity * 100).round()}%',
              tint: tint,
              active: true,
              size: nodeSize,
            ),
          ),
          for (var lane = 0; lane < laneIntegrity.length; lane += 1)
            Positioned(
              left: positionForLane(lane).dx,
              top: positionForLane(lane).dy,
              child: _HexArenaNode(
                label: 'L${lane + 1}',
                valueLabel: '${(laneIntegrity[lane] * 100).round()}%',
                tint: tint,
                active: builtLanes.length > lane ? builtLanes[lane] : false,
                size: nodeSize,
                onTap: onLaneTap == null ? null : () => onLaneTap!(lane),
              ),
            ),
        ],
      ),
    );
  }
}

class _HexArenaNode extends StatelessWidget {
  const _HexArenaNode({
    required this.label,
    required this.valueLabel,
    required this.tint,
    required this.active,
    required this.size,
    this.onTap,
  });

  final String label;
  final String valueLabel;
  final Color tint;
  final bool active;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: (active ? tint : LightcorePalette.stroke).withValues(
              alpha: 0.5,
            ),
          ),
          color: (active ? tint : LightcorePalette.panelRaised).withValues(
            alpha: active ? 0.14 : 0.72,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hexagon_rounded,
              color: active ? tint : LightcorePalette.stroke,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: active ? tint : LightcorePalette.stroke,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              valueLabel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.entry});

  final int rank;
  final LightcoreTournamentLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.isPlayer
        ? LightcorePalette.solar
        : LightcorePalette.mist.withValues(alpha: 0.84);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: entry.isPlayer
            ? LightcorePalette.solar.withValues(alpha: 0.1)
            : LightcorePalette.panelRaised.withValues(alpha: 0.74),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              entry.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: entry.isPlayer ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${entry.globalRating} RTG',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LightcorePalette.mist.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '${entry.score}',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

Color _modeTint(LightcoreTournamentModeId mode) => switch (mode) {
  LightcoreTournamentModeId.enemyBlitz => LightcorePalette.flare,
  LightcoreTournamentModeId.hexGauntlet => LightcorePalette.solar,
  LightcoreTournamentModeId.arenaFlow => LightcorePalette.violet,
};

String _formatCountdown(DateTime endsAt) {
  final remaining = endsAt.difference(DateTime.now());
  if (remaining.isNegative) {
    return 'Ended';
  }
  if (remaining.inDays >= 1) {
    return '${remaining.inDays}d ${remaining.inHours.remainder(24)}h';
  }
  if (remaining.inHours >= 1) {
    return '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m';
  }
  return '${max(0, remaining.inMinutes)}m';
}

List<String> _modeLoadingTips(LightcoreTournamentModeId mode) => switch (mode) {
  LightcoreTournamentModeId.enemyBlitz => const <String>[
    'Tip: Start with three drafted anomalies; upgrades matter more after the first wave stabilizes.',
    'Tip: Enemy Blitz keeps running on a weekend-length clock after the session starts.',
    'Tip: Focus early anomalies so auto-charged packets stabilize the first tower unlock quickly.',
  ],
  LightcoreTournamentModeId.hexGauntlet => const <String>[
    'Tip: Merge matching towers before the lane pressure spikes.',
    'Tip: Sending waves manually raises income, but a weak board can fold fast.',
    'Tip: A deeper path clear beats a shallow economy run on the weekly board.',
  ],
  LightcoreTournamentModeId.arenaFlow => const <String>[
    'Tip: Arena Flow uses your highest-layer Home Tower as the player-side shell.',
    'Tip: Overclock when your enemy wave is already near the rival tower.',
    'Tip: Net damage matters; blocking rival pressure is as valuable as pushing your own.',
  ],
};
