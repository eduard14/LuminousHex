part of '../enemy_management_screen.dart';

class _ThreatScanSection extends StatelessWidget {
  const _ThreatScanSection({
    required this.title,
    required this.tint,
    required this.icon,
    required this.progress,
    required this.railTopLabel,
    required this.railBottomLabel,
    required this.statusLabel,
    required this.child,
    this.trailing,
  });

  final String title;
  final Color tint;
  final IconData icon;
  final double progress;
  final String railTopLabel;
  final String railBottomLabel;
  final String statusLabel;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tint.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ThreatProgressRail(
            tint: tint,
            icon: icon,
            progress: progress,
            topLabel: railTopLabel,
            bottomLabel: railBottomLabel,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(title, style: textTheme.titleMedium)),
                    ...?trailing == null ? null : <Widget>[trailing!],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: textTheme.bodySmall?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreatPullTabs extends StatelessWidget {
  const _ThreatPullTabs({
    required this.selected,
    required this.bossesUnlocked,
    required this.highlightBossTab,
    required this.onChanged,
  });

  final _ThreatPullTab selected;
  final bool bossesUnlocked;
  final bool highlightBossTab;
  final ValueChanged<_ThreatPullTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => onChanged(_ThreatPullTab.enemies),
            style: FilledButton.styleFrom(
              backgroundColor: selected == _ThreatPullTab.enemies
                  ? LightcorePalette.aether.withValues(alpha: 0.22)
                  : null,
            ),
            icon: const Icon(LightcoreIcons.threatScan),
            label: const Text('Research'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GuidedFocusFrame(
            active: highlightBossTab,
            tint: LightcorePalette.quest,
            child: FilledButton.tonalIcon(
              onPressed: () => onChanged(_ThreatPullTab.bosses),
              style: FilledButton.styleFrom(
                backgroundColor: selected == _ThreatPullTab.bosses
                    ? LightcorePalette.warning.withValues(alpha: 0.22)
                    : null,
              ),
              icon: Icon(
                bossesUnlocked ? Icons.shield_moon_rounded : Icons.lock_rounded,
              ),
              label: const Text('Apex'),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanSpendExplanation extends StatelessWidget {
  const _ScanSpendExplanation({required this.selected, required this.tint});

  final _ThreatPullTab selected;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final title = selected == _ThreatPullTab.bosses
        ? 'Threat Scans reveal region bosses'
        : 'Threat Scans resolve Knowledge Cards';
    final body = selected == _ThreatPullTab.bosses
        ? 'Bosses now sit inside cleared regions. Final clears drop Apex Cores, boss traits, and regional Knowledge Cards for books.'
        : 'Knowledge rolls use the current scan level, rarity gates, copy merges, and the existing card reveal animation.';
    final footer = selected == _ThreatPullTab.bosses
        ? 'These are encounter targets, not Core Managers.'
        : 'These are research bonuses against enemy families, not map regions.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                selected == _ThreatPullTab.bosses
                    ? Icons.shield_moon_rounded
                    : LightcoreIcons.threatScan,
                size: 17,
                color: tint,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: LightcorePalette.mist,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            footer,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreatProgressRail extends StatelessWidget {
  const _ThreatProgressRail({
    required this.tint,
    required this.icon,
    required this.progress,
    required this.topLabel,
    required this.bottomLabel,
  });

  final Color tint;
  final IconData icon;
  final double progress;
  final String topLabel;
  final String bottomLabel;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: tint.withValues(alpha: 0.24)),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(height: 10),
          Container(
            width: 14,
            height: 132,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: LightcorePalette.night.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tint.withValues(alpha: 0.18)),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: clampedProgress == 0 ? 0.04 : clampedProgress,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [tint.withValues(alpha: 0.54), tint],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tint.withValues(alpha: 0.24),
                        blurRadius: 12,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            topLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            bottomLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LightcorePalette.layer2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BossSignalOrb extends StatelessWidget {
  const _BossSignalOrb({required this.card});

  final EnemyCardState? card;

  @override
  Widget build(BuildContext context) {
    final bossCard = card;
    final config = card?.config;

    if (config != null && bossCard != null) {
      return _ThreatSummonCard(
        config: config,
        dimension: 68,
        artSize: 42,
        locked: !bossCard.isOwned,
        semanticLabel: '${config.name} active Apex card preview',
        topRight: !bossCard.isOwned
            ? const Icon(
                Icons.lock_rounded,
                size: 14,
                color: LightcorePalette.mist,
              )
            : null,
      );
    }

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LightcorePalette.warning, width: 1.6),
        color: LightcorePalette.panel.withValues(alpha: 0.84),
      ),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LightcorePalette.warning.withValues(alpha: 0.18),
            border: Border.all(
              color: LightcorePalette.warning.withValues(alpha: 0.48),
            ),
          ),
          child: const Icon(
            Icons.lock_rounded,
            size: 18,
            color: LightcorePalette.warning,
          ),
        ),
      ),
    );
  }
}

class _BossScanPreview extends StatelessWidget {
  const _BossScanPreview({
    required this.card,
    required this.active,
    this.onTap,
  });

  final EnemyCardState card;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final owned = card.isOwned;

    return Tooltip(
      message: '${card.config.name} • click for details',
      child: _ThreatSummonCard(
        config: card.config,
        dimension: 52,
        artSize: 28,
        locked: !owned,
        selected: active && owned,
        onTap: onTap,
        semanticLabel:
            '${card.config.name}, ${owned ? 'owned' : 'locked'} Apex card preview',
        topRight: Icon(
          !owned
              ? Icons.lock_rounded
              : active
              ? Icons.check_circle_rounded
              : Icons.open_in_full_rounded,
          size: 12,
          color: !owned
              ? LightcorePalette.mist
              : active
              ? LightcorePalette.warning
              : card.config.affinity.color,
        ),
      ),
    );
  }
}
