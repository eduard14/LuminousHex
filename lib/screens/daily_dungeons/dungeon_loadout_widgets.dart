part of '../daily_dungeons_screen.dart';

class _DungeonLoadoutTile extends StatelessWidget {
  const _DungeonLoadoutTile({
    required this.card,
    required this.selected,
    required this.totalDamage,
    required this.onTap,
  });

  final EnemyCardState card;
  final bool selected;
  final double totalDamage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = card.config.affinity.color;
    return AuroraPanel(
      tint: tint,
      radius: 18,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DungeonEnemyPortrait(card: card, size: 54, selected: selected),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.config.name, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${card.config.rarity.label}  •  Lv ${card.level}',
                      style: textTheme.bodySmall?.copyWith(
                        color: LightcorePalette.mist.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onTap,
                tooltip: selected
                    ? 'Remove ${card.config.name}'
                    : 'Select ${card.config.name}',
                icon: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.whatshot_rounded,
                label: '${totalDamage.round()} tower damage',
                tint: tint,
              ),
              _InfoChip(
                icon: Icons.hub_rounded,
                label: 'Battle spawn',
                tint: LightcorePalette.aether,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MeterLabelRow(
            label: selected ? 'Dungeon Loadout' : 'Available',
            value: selected ? 'Selected' : 'Tap to swap',
          ),
          const SizedBox(height: 6),
          MeterBar(
            value: selected ? 1 : 0.32,
            color: selected ? LightcorePalette.success : tint,
            height: 8,
          ),
        ],
      ),
    );
  }
}

class _ApexLoadoutSelector extends StatelessWidget {
  const _ApexLoadoutSelector({
    required this.cards,
    required this.selectedCard,
    required this.onSelected,
  });

  final List<EnemyCardState> cards;
  final EnemyCardState? selectedCard;
  final ValueChanged<EnemyCardState> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Apex Icon', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        if (cards.isEmpty)
          AuroraPanel(
            tint: LightcorePalette.stroke,
            radius: 18,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _IconBadge(
                  icon: Icons.lock_rounded,
                  tint: LightcorePalette.stroke,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Resolve an Apex Scan to add a boss draft to dungeon runs.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: LightcorePalette.mist.withValues(alpha: 0.68),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final card in cards.take(5))
                _ApexLoadoutChip(
                  card: card,
                  selected: selectedCard?.config.id == card.config.id,
                  onTap: () => onSelected(card),
                ),
            ],
          ),
      ],
    );
  }
}

class _ApexLoadoutChip extends StatelessWidget {
  const _ApexLoadoutChip({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  final EnemyCardState card;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = card.config.affinity.color;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint.withValues(alpha: selected ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tint.withValues(alpha: selected ? 0.72 : 0.32),
            width: selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_moon_rounded, color: tint, size: 18),
              const SizedBox(width: 8),
              Text(
                card.config.name,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: LightcorePalette.mist,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle_rounded, color: tint, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EnemyManagerLoadoutSelector extends StatelessWidget {
  const _EnemyManagerLoadoutSelector({
    required this.managers,
    required this.selectedManager,
    required this.onSelected,
  });

  final List<EnemyManagerState> managers;
  final EnemyManagerState? selectedManager;
  final ValueChanged<EnemyManagerState> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enemy Manager', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        if (managers.isEmpty)
          AuroraPanel(
            tint: LightcorePalette.stroke,
            radius: 18,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _IconBadge(
                  icon: Icons.supervisor_account_rounded,
                  tint: LightcorePalette.stroke,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Forge a Threat Director manager to tune launch timing and impact pressure.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: LightcorePalette.mist.withValues(alpha: 0.68),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final manager in managers.take(6))
                _EnemyManagerLoadoutChip(
                  manager: manager,
                  selected: selectedManager?.instanceId == manager.instanceId,
                  onTap: () => onSelected(manager),
                ),
            ],
          ),
      ],
    );
  }
}

class _EnemyManagerLoadoutChip extends StatelessWidget {
  const _EnemyManagerLoadoutChip({
    required this.manager,
    required this.selected,
    required this.onTap,
  });

  final EnemyManagerState manager;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final focus = manager.targetAffinity;
    final tint = focus?.color ?? LightcorePalette.verdant;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint.withValues(alpha: selected ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tint.withValues(alpha: selected ? 0.72 : 0.32),
            width: selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.supervisor_account_rounded, color: tint, size: 18),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manager.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: LightcorePalette.mist,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${focus?.shortLabel ?? 'ANY'} • Dmg ${_managerLoadoutPercent(manager.stabilityDamageMultiplier)} • Spd ${_managerLoadoutPercent(manager.speedMultiplier)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: LightcorePalette.mist.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle_rounded, color: tint, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _managerLoadoutPercent(double multiplier) {
  final value = ((multiplier - 1) * 100).round();
  if (value == 0) {
    return '0%';
  }
  return value > 0 ? '+$value%' : '$value%';
}

class _DungeonEnemyPortrait extends StatelessWidget {
  const _DungeonEnemyPortrait({
    required this.card,
    this.size = 48,
    this.selected = false,
  });

  final EnemyCardState card;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tint =
        card.config.secondaryAffinity?.color ?? card.config.affinity.color;
    final assetPath = enemyImageAssetForConfig(card.config);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(
        color: LightcorePalette.night.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: tint.withValues(alpha: selected ? 0.84 : 0.46),
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: tint.withValues(alpha: 0.24),
              blurRadius: 14,
              spreadRadius: -4,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.17),
        child: assetPath == null
            ? Icon(Icons.adjust_rounded, color: tint, size: size * 0.48)
            : Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.adjust_rounded, color: tint, size: size * 0.48),
              ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: tint),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: LightcorePalette.mist,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCapsule extends StatelessWidget {
  const _StatusCapsule({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: tint,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.tint});

  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tint.withValues(alpha: 0.14),
        border: Border.all(color: tint.withValues(alpha: 0.32)),
      ),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(icon, color: tint, size: 22),
      ),
    );
  }
}

class _MeterLabelRow extends StatelessWidget {
  const _MeterLabelRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: LightcorePalette.mist.withValues(alpha: 0.76),
      fontWeight: FontWeight.w800,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: 10),
        Text(value, style: style),
      ],
    );
  }
}
