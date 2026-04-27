part of '../meta_progression_sheet.dart';

class _BattlePassTypePicker extends StatelessWidget {
  const _BattlePassTypePicker({
    required this.controller,
    required this.types,
    required this.selectedType,
    required this.onSelected,
  });

  final LightcoreController controller;
  final List<BattlePassType> types;
  final BattlePassType selectedType;
  final ValueChanged<BattlePassType> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 72;
        final columns = availableWidth >= 760 ? 4 : 2;
        final gap = availableWidth < 560 ? 10.0 : 12.0;
        final cardWidth = math.max(
          0.0,
          (availableWidth - (gap * (columns - 1))) / columns,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 18,
                  color: _passTint(selectedType),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Choose a Pass',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: LightcorePalette.mist,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (availableWidth >= 380) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Tap any card',
                    style: textTheme.labelMedium?.copyWith(
                      color: LightcorePalette.mist.withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final type in types)
                  SizedBox(
                    width: cardWidth,
                    child: _BattlePassTypeCard(
                      controller: controller,
                      type: type,
                      selected: type == selectedType,
                      compact: availableWidth < 560,
                      onTap: () => onSelected(type),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _BattlePassCopyPicker extends StatelessWidget {
  const _BattlePassCopyPicker({
    required this.controller,
    required this.passes,
    required this.selectedPass,
    required this.onSelected,
  });

  final LightcoreController controller;
  final List<BattlePassProgress> passes;
  final BattlePassProgress selectedPass;
  final ValueChanged<BattlePassProgress> onSelected;

  @override
  Widget build(BuildContext context) {
    final type = selectedPass.type;
    final tint = _passTint(type);
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 72;
        final compact = availableWidth < 560;
        final chipWidth = compact ? 132.0 : 156.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, size: 18, color: tint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pass Copies',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: LightcorePalette.mist,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final pass in passes)
                  SizedBox(
                    width: chipWidth,
                    child: _BattlePassCopyChip(
                      controller: controller,
                      pass: pass,
                      current: pass.seasonKey == passes.last.seasonKey,
                      selected: pass.seasonKey == selectedPass.seasonKey,
                      compact: compact,
                      onTap: () => onSelected(pass),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _BattlePassCopyChip extends StatelessWidget {
  const _BattlePassCopyChip({
    required this.controller,
    required this.pass,
    required this.current,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final LightcoreController controller;
  final BattlePassProgress pass;
  final bool current;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = _passTint(pass.type);
    final tiers = controller.battlePassTiersForPass(pass);
    final progressCap = tiers.last.goal;
    final progress = pass.progress.clamp(0, progressCap).toInt();
    final claimable = controller.claimableBattlePassRewardsForPass(pass);
    final label = pass.type.resetsDaily
        ? 'Today'
        : current
        ? 'Current'
        : 'Pass ${pass.generation}';
    final status = claimable > 0
        ? 'Claim $claimable'
        : pass.premiumUnlocked
        ? 'Premium on'
        : '${_premiumPrismShardCost(pass.type)} Shards';
    final statusTint = claimable > 0
        ? LightcorePalette.success
        : pass.premiumUnlocked
        ? LightcorePalette.success
        : LightcorePalette.solar;
    final textTheme = Theme.of(context).textTheme;

    return Tooltip(
      message: '${pass.type.label} $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.all(compact ? 10 : 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: tint.withValues(alpha: selected ? 0.2 : 0.1),
              border: Border.all(
                color: selected
                    ? tint.withValues(alpha: 0.86)
                    : LightcorePalette.stroke.withValues(alpha: 0.68),
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      current ? Icons.fiber_new_rounded : Icons.history_rounded,
                      size: 16,
                      color: tint,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          color: LightcorePalette.mist,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$progress/$progressCap',
                  style: textTheme.labelMedium?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _BattlePassPickerBadge(
                  icon: claimable > 0
                      ? Icons.redeem_rounded
                      : pass.premiumUnlocked
                      ? Icons.lock_open_rounded
                      : Icons.lock_rounded,
                  label: status,
                  tint: statusTint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BattlePassTypeCard extends StatelessWidget {
  const _BattlePassTypeCard({
    required this.controller,
    required this.type,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final LightcoreController controller;
  final BattlePassType type;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final passes = controller.battlePassesFor(type);
    final pass = passes.isNotEmpty
        ? passes.last
        : controller.battlePassFor(type);
    final tiers = controller.battlePassTiersForPass(pass);
    final progressCap = tiers.last.goal;
    final progress = pass.progress.clamp(0, progressCap).toInt();
    final progressFraction = progressCap <= 0 ? 0.0 : progress / progressCap;
    final claimable = controller.claimableBattlePassRewards(type);
    final tint = _passTint(type);
    final textTheme = Theme.of(context).textTheme;
    final borderColor = selected
        ? tint.withValues(alpha: 0.88)
        : LightcorePalette.stroke.withValues(alpha: 0.72);

    return Tooltip(
      message: type.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Select ${type.label}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              constraints: BoxConstraints(minHeight: compact ? 126 : 132),
              padding: EdgeInsets.all(compact ? 12 : 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: borderColor,
                  width: selected ? 1.6 : 1.0,
                ),
                gradient: LinearGradient(
                  colors: [
                    tint.withValues(alpha: selected ? 0.24 : 0.1),
                    LightcorePalette.panelRaised.withValues(alpha: 0.92),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tint.withValues(alpha: selected ? 0.16 : 0.05),
                    blurRadius: selected ? 22 : 14,
                    spreadRadius: selected ? -5 : -8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: compact ? 30 : 34,
                        height: compact ? 30 : 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tint.withValues(alpha: selected ? 0.24 : 0.14),
                          border: Border.all(
                            color: tint.withValues(alpha: 0.34),
                          ),
                        ),
                        child: Icon(
                          _battlePassTypeIcon(type),
                          size: compact ? 16 : 18,
                          color: tint,
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.chevron_right_rounded,
                        size: compact ? 18 : 20,
                        color: selected
                            ? tint
                            : LightcorePalette.mist.withValues(alpha: 0.52),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type.shortLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: LightcorePalette.mist,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            value: progressFraction,
                            color: tint,
                            backgroundColor: LightcorePalette.stroke.withValues(
                              alpha: 0.42,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$progress/$progressCap',
                        style: textTheme.labelMedium?.copyWith(
                          color: tint,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (claimable > 0)
                        _BattlePassPickerBadge(
                          icon: Icons.redeem_rounded,
                          label: 'Claim $claimable',
                          tint: LightcorePalette.success,
                        )
                      else
                        _BattlePassPickerBadge(
                          icon: pass.premiumUnlocked
                              ? Icons.lock_open_rounded
                              : Icons.lock_rounded,
                          label: pass.premiumUnlocked
                              ? 'Premium on'
                              : '${_premiumPrismShardCost(type)} Shards',
                          tint: pass.premiumUnlocked
                              ? LightcorePalette.success
                              : LightcorePalette.solar,
                        ),
                      if (passes.length > 1)
                        _BattlePassPickerBadge(
                          icon: Icons.history_rounded,
                          label: '${passes.length} passes',
                          tint: tint,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BattlePassPickerBadge extends StatelessWidget {
  const _BattlePassPickerBadge({
    required this.icon,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tint.withValues(alpha: 0.12),
        border: Border.all(color: tint.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tint),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tint,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
