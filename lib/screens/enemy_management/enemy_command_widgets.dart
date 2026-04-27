part of '../enemy_management_screen.dart';

class _EnemyCommandPanel extends StatelessWidget {
  const _EnemyCommandPanel({
    required this.controller,
    required this.card,
    required this.onOpenDetails,
  });

  final LightcoreController controller;
  final EnemyCardState? card;
  final ValueChanged<String> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final featured = card;
    if (featured == null) {
      return const _InlineEnemyNote(
        message: 'No anomaly signatures are available yet.',
        tint: LightcorePalette.aether,
      );
    }

    final tint = featured.config.affinity.color;
    return AuroraPanel(
      tint: tint,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final portrait = _EnemyPortraitCard(card: featured);
          final details = _EnemyCommandDetails(
            controller: controller,
            card: featured,
            onOpenDetails: onOpenDetails,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [portrait, const SizedBox(height: 14), details],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 220, child: portrait),
              const SizedBox(width: 16),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _EnemyCardArt extends StatelessWidget {
  const _EnemyCardArt({required this.config, required this.size});

  final EnemyConfig config;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath = enemyImageAssetForConfig(config);
    if (assetPath == null) {
      return _fallbackGlyph();
    }

    return ClipOval(
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => _fallbackGlyph(),
      ),
    );
  }

  Widget _fallbackGlyph() {
    return AffinityGlyph(affinity: config.affinity, size: size * 0.68);
  }
}

class _EnemyPortraitCard extends StatelessWidget {
  const _EnemyPortraitCard({required this.card});

  final EnemyCardState card;

  @override
  Widget build(BuildContext context) {
    final tint = card.config.affinity.color;
    final rarityTint = _rarityTint(card.config.rarity);

    return Container(
      height: 246,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: rarityTint.withValues(alpha: 0.78), width: 2),
        gradient: LinearGradient(
          colors: [
            tint.withValues(alpha: 0.28),
            LightcorePalette.panelRaised.withValues(alpha: 0.96),
            LightcorePalette.night.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.2),
            blurRadius: 28,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -38,
            child: Icon(
              Icons.hexagon_rounded,
              size: 164,
              color: tint.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            left: -26,
            bottom: -28,
            child: Icon(
              Icons.blur_on_rounded,
              size: 150,
              color: rarityTint.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lv. ${card.level}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: LightcorePalette.layer2,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: SymbolGridBadge(
                          tint: rarityTint,
                          child: Text(card.config.rarity.label),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 118,
                          height: 118,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tint.withValues(alpha: 0.12),
                            border: Border.all(
                              color: tint.withValues(alpha: 0.28),
                            ),
                          ),
                        ),
                        _EnemyCardArt(config: card.config, size: 118),
                        if (card.config.splitsOnDeath)
                          Positioned(
                            right: 46,
                            bottom: 44,
                            child: SymbolGridBadge(
                              tint: tint,
                              shape: BoxShape.circle,
                              size: 24,
                              child: const Icon(Icons.call_split_rounded),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Text(
                  card.config.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: LightcorePalette.mist,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.config.traitLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnemyCommandDetails extends StatelessWidget {
  const _EnemyCommandDetails({
    required this.controller,
    required this.card,
    required this.onOpenDetails,
  });

  final LightcoreController controller;
  final EnemyCardState card;
  final ValueChanged<String> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = card.config.affinity.color;
    final active = controller.isEnemyCardActive(card.config.id);
    final canUpgrade = controller.canUpgradeEnemyCard(card);
    final canMerge = controller.canMergeEnemyCard(card);
    final assignedManager = controller.enemyManagerForCard(card.config.id);
    final cap = controller.enemyLevelCap(card);
    final upgradeCost = controller.enemyUpgradeRequirement(card);
    final mergeCost = controller.enemyMergeRequirement(card);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Main Anomaly', style: textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    card.isOwned
                        ? '${card.config.name} is ${active ? 'live in' : 'ready for'} the active threat deck.'
                        : 'Pull this signature before it can join the active deck.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: LightcorePalette.mist.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
            if (active) const _DialogStatPill(label: 'Active'),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(label: 'Lv ${card.level}/$cap'),
            _InfoChip(label: 'Copies ${card.copies}'),
            _InfoChip(label: _enemyTileProgressLabel(controller, card)),
            _InfoChip(
              label: 'EXP +${controller.enemyCardPreviewExperience(card)}',
            ),
            _InfoChip(
              label: 'Kill +${controller.enemyCardPreviewKillCredit(card)}',
            ),
            _InfoChip(
              label: assignedManager == null
                  ? 'No Threat Director'
                  : assignedManager.name,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Inventory Effect', style: textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          card.isOwned
              ? controller.inventoryEffectSummaryLabelForCard(card)
              : 'Unlock the card first to add its permanent tower bonus.',
          style: textTheme.bodyMedium?.copyWith(
            color: card.isOwned ? LightcorePalette.solar : null,
            fontWeight: card.isOwned ? FontWeight.w800 : null,
          ),
        ),
        if (card.isOwned) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in controller.inventoryEffectHighlightsForCard(
                card,
                maxItems: 3,
              ))
                _InfoChip(label: label),
            ],
          ),
        ],
        const SizedBox(height: 14),
        _ActiveDeckStrip(controller: controller),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton(
              onPressed: card.isOwned
                  ? () => controller.toggleEnemyCardSelection(card.config.id)
                  : null,
              child: Text(
                !card.isOwned
                    ? 'Locked'
                    : active
                    ? 'Remove'
                    : 'Add To Deck',
              ),
            ),
            if (canUpgrade)
              OutlinedButton(
                onPressed: () => controller.upgradeEnemyCard(card.config.id),
                child: Text('Lv Up • $upgradeCost'),
              ),
            if (!canUpgrade && canMerge)
              _FusionActionButton(
                tint: tint,
                label: 'Fuse • $mergeCost',
                onPressed: () => controller.mergeEnemyCard(card.config.id),
              ),
            TextButton(
              onPressed: () => onOpenDetails(card.config.id),
              child: const Text('Details'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Anomaly inventory: ${controller.enemyInventoryBonusSummaryLabel}',
          style: textTheme.bodySmall?.copyWith(
            color: tint,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ActiveDeckStrip extends StatelessWidget {
  const _ActiveDeckStrip({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final deck = controller.activeEnemyDeck;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Active Deck',
                style: textTheme.titleSmall?.copyWith(
                  color: LightcorePalette.mist,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${deck.length}/${LightcoreController.enemyDeckLimit}',
              style: textTheme.labelMedium?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.72),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (deck.isEmpty)
          const _InlineEnemyNote(
            message: 'No active enemies selected yet.',
            tint: LightcorePalette.aether,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final card in deck) _MiniEnemyDeckTile(card: card)],
          ),
      ],
    );
  }
}

class _MiniEnemyDeckTile extends StatelessWidget {
  const _MiniEnemyDeckTile({required this.card});

  final EnemyCardState card;

  @override
  Widget build(BuildContext context) {
    final tint = card.config.affinity.color;

    return Tooltip(
      message: card.config.name,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          width: 58,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tint, width: 1.2),
            gradient: LinearGradient(
              colors: [
                tint.withValues(alpha: 0.12),
                LightcorePalette.panelRaised.withValues(alpha: 0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _EnemyCardArt(config: card.config, size: 30),
              const SizedBox(height: 6),
              Text(
                'Lv ${card.level}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tint,
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

class _SwarmPressurePanel extends StatelessWidget {
  const _SwarmPressurePanel({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bundle = controller.activeThreatScanBundle;
    final canUpgrade =
        controller.canUpgradeEnemyTargetMax &&
        controller.lumens >= controller.enemyTargetUpgradeCost;

    return AuroraPanel(
      tint: LightcorePalette.layer2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Threat Scan Pressure', style: textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            '${bundle.name}: Effective Gain is Threat Reward multiplied by Output Efficiency. ${bundle.counterplayLabel}',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(label: 'Risk ${bundle.riskLabel}'),
              _InfoChip(
                label:
                    'Live ${controller.enemyCount}/${controller.enemyTargetCount}',
              ),
              _InfoChip(
                label:
                    'Target ${controller.enemyTargetCount}/${controller.enemyTargetMax}',
              ),
              _InfoChip(label: 'Every ${controller.enemySpawnCadenceLabel}'),
              _InfoChip(label: 'Threat ${bundle.threatRewardLabel}'),
              _InfoChip(label: 'Stability ${bundle.stabilityPressureLabel}'),
              _InfoChip(label: 'Output ${controller.outputEfficiencyLabel}'),
              _InfoChip(label: 'Gain ${bundle.effectiveGainLabel}'),
              _InfoChip(label: controller.outputEfficiencyStatusLabel),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            controller.outputEfficiencyTip,
            style: textTheme.bodySmall?.copyWith(
              color: controller.outputEfficiencyMultiplier >= 0.55
                  ? LightcorePalette.mist.withValues(alpha: 0.82)
                  : LightcorePalette.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GuidedFocusFrame(
            active: controller.tutorialHighlightsEnemyCountControl,
            tint: LightcorePalette.quest,
            child: Slider(
              value: controller.enemyTargetCount.toDouble(),
              min: controller.enemyTargetFloor.toDouble(),
              max: controller.enemyTargetMax.toDouble(),
              divisions:
                  controller.enemyTargetMax - controller.enemyTargetFloor,
              label: '${controller.enemyTargetCount}',
              activeColor: LightcorePalette.layer2,
              inactiveColor: LightcorePalette.layer2.withValues(alpha: 0.22),
              onChanged: (value) =>
                  controller.setEnemyTargetCount(value.round()),
            ),
          ),
          Row(
            children: [
              Text(
                'Low ${controller.enemyTargetFloor}',
                style: textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                'Max ${controller.enemyTargetMax}',
                style: textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: canUpgrade ? controller.upgradeEnemyTargetMax : null,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                controller.canUpgradeEnemyTargetMax
                    ? 'Raise Ceiling • ${controller.enemyTargetUpgradeCostLabel}L'
                    : 'Swarm Maxed',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
