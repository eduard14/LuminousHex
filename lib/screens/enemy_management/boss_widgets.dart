part of '../enemy_management_screen.dart';

class _ThreatLibraryTabs extends StatelessWidget {
  const _ThreatLibraryTabs({
    required this.controller,
    required this.selected,
    required this.bossesUnlocked,
    required this.onChanged,
  });

  final LightcoreController controller;
  final _ThreatLibraryTab selected;
  final bool bossesUnlocked;
  final ValueChanged<_ThreatLibraryTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => onChanged(_ThreatLibraryTab.enemies),
            style: FilledButton.styleFrom(
              backgroundColor: selected == _ThreatLibraryTab.enemies
                  ? LightcorePalette.aether.withValues(alpha: 0.22)
                  : null,
            ),
            icon: const Icon(LightcoreIcons.threatScan),
            label: const Text('Knowledge Build'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GuidedFocusFrame(
            active: controller.tutorialHighlightsBossesTab(
              selected == _ThreatLibraryTab.bosses,
            ),
            tint: LightcorePalette.quest,
            child: FilledButton.tonalIcon(
              onPressed: () => onChanged(_ThreatLibraryTab.bosses),
              style: FilledButton.styleFrom(
                backgroundColor: selected == _ThreatLibraryTab.bosses
                    ? LightcorePalette.warning.withValues(alpha: 0.22)
                    : null,
              ),
              icon: Icon(
                bossesUnlocked ? Icons.shield_moon_rounded : Icons.lock_rounded,
              ),
              label: const Text('Apex Library'),
            ),
          ),
        ),
      ],
    );
  }
}

class _BossUnlockPanel extends StatelessWidget {
  const _BossUnlockPanel({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AuroraPanel(
      tint: LightcorePalette.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Regional Bosses Locked', style: textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'White Warden is already active as the starter Apex. Regional boss changes unlock in the Prism Shell.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(label: 'Current Layer ${controller.progressionLayer}'),
              _InfoChip(
                label:
                    '${controller.bossLevelsRemaining} layer${controller.bossLevelsRemaining == 1 ? '' : 's'} to go',
              ),
              _InfoChip(
                label:
                    'Unlock reward ${LightcoreCurrencyLabels.bossScanCount(LightcoreController.bossUnlockTicketGrant)}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          MeterBar(
            value: controller.bossUnlockProgress,
            color: LightcorePalette.warning,
          ),
          const SizedBox(height: 8),
          Text(
            'Create the Prism Shell to collect the unlock scans and start clearing regional Apex bosses.',
            style: textTheme.bodySmall?.copyWith(
              color: LightcorePalette.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BossDeckPanel extends StatelessWidget {
  const _BossDeckPanel({required this.controller, required this.onOpenDetails});

  final LightcoreController controller;
  final ValueChanged<String> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activeBoss = controller.activeBossEnemyCard;
    final featuredBoss = _featuredBossCard(controller);
    final tint =
        featuredBoss?.config.secondaryAffinity?.color ??
        featuredBoss?.config.affinity.color ??
        LightcorePalette.warning;

    return AuroraPanel(
      tint: tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Apex Library', style: textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Every ${LightcoreController.bossSpawnKillRequirement} anomaly clears, the armed Apex Anomaly replaces the next spawn. Found Apex cards also add positive inventory bonuses immediately.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          _BossCommandPanel(
            controller: controller,
            card: featuredBoss,
            onOpenDetails: onOpenDetails,
          ),
          const SizedBox(height: 14),
          _BulkBossLevelButton(controller: controller),
          const SizedBox(height: 14),
          _EnemySectionHeader(
            title: 'Apex Roster',
            tint: tint,
            subtitle:
                'Owned ${controller.ownedBossEnemyCardCount}/${controller.bossEnemyCards.length} • ${controller.bossTicketLabel} • ${controller.bossCoreLabel}',
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileSize = constraints.maxWidth < 390 ? 96.0 : 106.0;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final card in controller.bossEnemyCards)
                    _BossEnemyChip(
                      card: card,
                      controller: controller,
                      dimension: tileSize,
                      onOpenDetails: onOpenDetails,
                    ),
                ],
              );
            },
          ),
          if (activeBoss != null) ...[
            const SizedBox(height: 14),
            _BossEquippedEffectPanel(controller: controller, card: activeBoss),
            const SizedBox(height: 14),
            _BossInventoryEffectPanel(controller: controller, card: activeBoss),
          ],
        ],
      ),
    );
  }
}

EnemyCardState? _featuredBossCard(LightcoreController controller) {
  final active = controller.activeBossEnemyCard;
  if (active != null) {
    return active;
  }

  EnemyCardState? bestOwned;
  for (final card in controller.bossEnemyCards) {
    if (!card.isOwned) {
      continue;
    }
    if (bestOwned == null || _compareThreatDisplayPower(card, bestOwned) > 0) {
      bestOwned = card;
    }
  }

  if (bestOwned != null) {
    return bestOwned;
  }

  return controller.bossEnemyCards.isEmpty
      ? null
      : controller.bossEnemyCards.first;
}

class _BossCommandPanel extends StatelessWidget {
  const _BossCommandPanel({
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
        message: 'No Apex signatures are available yet.',
        tint: LightcorePalette.warning,
      );
    }

    final tint =
        featured.config.secondaryAffinity?.color ??
        featured.config.affinity.color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tint.withValues(alpha: 0.26)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final portrait = _BossPortraitCard(card: featured);
          final details = _BossCommandDetails(
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

class _BossPortraitCard extends StatelessWidget {
  const _BossPortraitCard({required this.card});

  final EnemyCardState card;

  @override
  Widget build(BuildContext context) {
    final primary = card.config.affinity.color;
    final secondary = card.config.secondaryAffinity?.color ?? primary;
    final rarityTint = _rarityTint(card.config.rarity);

    return Container(
      height: 246,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: rarityTint.withValues(alpha: 0.8), width: 2),
        gradient: LinearGradient(
          colors: [
            secondary.withValues(alpha: 0.3),
            primary.withValues(alpha: 0.18),
            LightcorePalette.night.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: secondary.withValues(alpha: 0.22),
            blurRadius: 30,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -46,
            top: -46,
            child: Icon(
              Icons.shield_moon_rounded,
              size: 170,
              color: secondary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            left: -36,
            bottom: -38,
            child: Icon(
              Icons.hexagon_rounded,
              size: 150,
              color: primary.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Lv. ${card.level}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: LightcorePalette.layer2,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const Spacer(),
                    SymbolGridBadge(
                      tint: rarityTint,
                      child: Text(card.config.rarity.label),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: _BossGlyph(
                      config: card.config,
                      size: 106,
                      locked: !card.isOwned,
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
                    color: secondary,
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

class _BossCommandDetails extends StatelessWidget {
  const _BossCommandDetails({
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
    final active = controller.isBossEnemyCardActive(card.config.id);
    final tint =
        card.config.secondaryAffinity?.color ?? card.config.affinity.color;
    final cap = controller.bossLevelCap(card);
    final canUpgrade = controller.canUpgradeBossEnemyCard(card);
    final maxed = card.level >= cap;
    final cost = controller.bossUpgradeRequirement(card);

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
                  Text('Armed Apex', style: textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    card.isOwned
                        ? '${card.config.name} is ${active ? 'armed' : 'available'} for Apex spawns.'
                        : 'Pull this Apex Anomaly before it can be armed.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: LightcorePalette.mist.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
            if (active) const _DialogStatPill(label: 'Armed'),
          ],
        ),
        const SizedBox(height: 12),
        _BossSpawnBar(
          value: controller.bossSpawnProgress,
          tint: tint,
          card: active ? card : controller.activeBossEnemyCard,
        ),
        const SizedBox(height: 8),
        Text(
          controller.bossSpawnStatusLabel,
          style: textTheme.bodySmall?.copyWith(
            color: tint,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(label: card.isOwned ? 'Owned' : 'Locked'),
            _InfoChip(label: 'Lv ${card.level}/$cap'),
            _InfoChip(label: 'Copies ${card.copies}'),
            _InfoChip(label: _bossTileProgressLabel(controller, card)),
            _InfoChip(
              label: 'Threat ${controller.enemyCardThreatRatingLabel(card)}',
            ),
            _InfoChip(
              label: 'HP ${controller.enemyCardPreviewHealthLabel(card)}',
            ),
            _InfoChip(
              label: 'Lumens +${controller.enemyCardPreviewRewardLabel(card)}',
            ),
            _InfoChip(
              label: 'EXP +${controller.enemyCardPreviewExperience(card)}',
            ),
            _InfoChip(
              label: 'Kill +${controller.enemyCardPreviewKillCredit(card)}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(card.config.summary, style: textTheme.bodyMedium),
        const SizedBox(height: 10),
        Text('Equipped Effect', style: textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          card.isOwned
              ? active
                    ? 'Armed now. This Apex replaces the next primed Apex spawn.'
                    : 'Arm this card to use its Apex spawn mechanics.'
              : 'Find this Apex before its armed spawn mechanics can be used.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              label:
                  'Every ${LightcoreController.bossSpawnKillRequirement} clears',
            ),
            for (final label in _bossMechanicLabels(card))
              _InfoChip(label: label),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            GuidedFocusFrame(
              active: controller.tutorialHighlightsBossArmButton(
                card.config.id,
              ),
              tint: LightcorePalette.quest,
              child: FilledButton(
                onPressed: !card.isOwned || active
                    ? null
                    : () => controller.tutorialArmBossEnemyCard(card.config.id),
                child: Text(
                  !card.isOwned
                      ? 'Pull To Unlock'
                      : active
                      ? 'Apex Armed'
                      : 'Arm Apex',
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: canUpgrade
                  ? () => controller.upgradeBossEnemyCard(card.config.id)
                  : null,
              icon: const Icon(Icons.arrow_circle_up_rounded),
              label: Text(maxed ? 'Maxed' : 'Lv Up • $cost'),
            ),
            TextButton(
              onPressed: () => onOpenDetails(card.config.id),
              child: const Text('Details'),
            ),
          ],
        ),
      ],
    );
  }
}

class _BossSpawnBar extends StatelessWidget {
  const _BossSpawnBar({required this.value, required this.tint, this.card});

  final double value;
  final Color tint;
  final EnemyCardState? card;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: MeterBar(value: value, color: tint, height: 12),
          ),
          Tooltip(
            message: card?.config.name ?? 'Apex Anomaly',
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LightcorePalette.panelRaised.withValues(alpha: 0.96),
                border: Border.all(
                  color: tint.withValues(alpha: 0.58),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tint.withValues(alpha: 0.2),
                    blurRadius: 14,
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: card == null
                  ? Icon(Icons.shield_moon_rounded, size: 16, color: tint)
                  : Center(
                      child: _BossGlyph(
                        config: card!.config,
                        size: 20,
                        locked: !card!.isOwned,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
