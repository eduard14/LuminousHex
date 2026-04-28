part of '../enemy_management_screen.dart';

class _TicketButton extends StatelessWidget {
  const _TicketButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: enabled ? onPressed : null,
      child: Text(label),
    );
  }
}

// ignore: unused_element
class _SummoningLevelTrack extends StatelessWidget {
  const _SummoningLevelTrack({
    required this.controller,
    required this.onShowRates,
  });

  final LightcoreController controller;
  final VoidCallback onShowRates;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxed = controller.isSummoningLevelMaxed;
    final summary = maxed
        ? 'Scan level maxed. Rates are capped and milestone tickets are finished.'
        : '${controller.pullsToNextSummoningLevel} scans to Scan Lv ${controller.nextSummoningLevel}.';

    Widget buildTrackBody() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            maxed
                ? 'Max progress reached'
                : '${controller.summoningLevelPullsIntoCurrent}/${controller.currentSummoningLevelPullGap} scans in this level',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          MeterBar(
            value: controller.summoningLevelProgress,
            color: LightcorePalette.solar,
            height: 12,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Lv ${controller.summoningLevel}',
                style: textTheme.bodySmall?.copyWith(
                  color: LightcorePalette.solar,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                maxed ? 'MAX' : 'Lv ${controller.nextSummoningLevel}',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: LightcorePalette.solar.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan Progress', style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(summary, style: textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: onShowRates,
                tooltip: 'Show threat rates',
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 540;
              final rewardBadge = _SummoningRewardBadge(
                level: controller.nextSummoningLevel,
                tickets: controller.nextSummoningLevelTicketReward,
                maxed: maxed,
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildTrackBody(),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: rewardBadge),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _SummoningStageBadge(level: controller.summoningLevel),
                  const SizedBox(width: 14),
                  Expanded(child: buildTrackBody()),
                  const SizedBox(width: 14),
                  rewardBadge,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummoningStageBadge extends StatelessWidget {
  const _SummoningStageBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: LightcorePalette.solar.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: LightcorePalette.solar.withValues(alpha: 0.26),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NOW',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: LightcorePalette.solar,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text('Lv $level', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _SummoningRewardBadge extends StatelessWidget {
  const _SummoningRewardBadge({
    required this.level,
    required this.tickets,
    required this.maxed,
  });

  final int level;
  final int tickets;
  final bool maxed;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 122),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: LightcorePalette.solar.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: LightcorePalette.solar.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            maxed ? 'Track reward' : 'Lv $level reward',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LightcorePalette.solar,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                maxed
                    ? Icons.workspace_premium_rounded
                    : Icons.confirmation_number_rounded,
                size: 16,
                color: LightcorePalette.solar,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  maxed
                      ? 'Complete'
                      : LightcoreCurrencyLabels.rewardThreatScans(tickets),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: LightcorePalette.layer2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PackPullSummaryCard extends StatelessWidget {
  const _PackPullSummaryCard({
    required this.summary,
    required this.itemTier,
    required this.timing,
    required this.revealAgeMilliseconds,
    required this.dimmed,
    this.emphasized = false,
    this.animateNewReveal = false,
  });

  final _PackPullSummaryEntry summary;
  final _EnemyRevealItemTier itemTier;
  final _EnemyPackRevealTiming timing;
  final double revealAgeMilliseconds;
  final bool dimmed;
  final bool emphasized;
  final bool animateNewReveal;

  @override
  Widget build(BuildContext context) {
    final rarityTint = _rarityTint(summary.config.rarity);
    final emphasisTint = _itemTierAccentColor(itemTier, fallback: rarityTint);
    final dropProgress =
        (revealAgeMilliseconds / timing.dropMillisecondsFor(itemTier))
            .clamp(0.0, 1.0)
            .toDouble();
    final scale = _itemRevealScale(dropProgress);
    final glowStrength = _itemGlowStrength(
      itemTier: itemTier,
      revealAgeMilliseconds: revealAgeMilliseconds,
      timing: timing,
    );
    final dimOpacity = dimmed ? 0.84 : 1.0;
    const tileSize = 104.0;

    return Opacity(
      opacity: dimOpacity * Curves.easeOutCubic.transform(dropProgress),
      child: Transform.scale(
        scale: scale,
        child: _ThreatSummonCard(
          config: summary.config,
          dimension: tileSize,
          artSize: 58,
          bottomLabel: 'x${summary.count}',
          emphasized: emphasized,
          glowTint: emphasisTint,
          topRight: summary.config.isBoss
              ? Icon(
                  Icons.shield_rounded,
                  size: 14,
                  color: LightcorePalette.warning.withValues(alpha: 0.9),
                )
              : null,
          semanticLabel:
              '${summary.config.name}, ${summary.config.rarity.label}, ${summary.count}',
          selected: false,
          locked: false,
          glowStrength: animateNewReveal && summary.isNew
              ? math.max(glowStrength, 0.36)
              : glowStrength,
        ),
      ),
    );
  }
}

class _PackPullSummaryEntry {
  const _PackPullSummaryEntry({
    required this.config,
    required this.count,
    required this.isNew,
  });

  final EnemyConfig config;
  final int count;
  final bool isNew;
}

List<_PackPullSummaryEntry> _summarizePulls(Iterable<PackPullResult> pulls) {
  final order = <String>[];
  final configs = <String, EnemyConfig>{};
  final counts = <String, int>{};
  final newFlags = <String, bool>{};

  for (final pull in pulls) {
    if (!counts.containsKey(pull.config.id)) {
      order.add(pull.config.id);
      configs[pull.config.id] = pull.config;
      counts[pull.config.id] = 0;
      newFlags[pull.config.id] = false;
    }
    counts[pull.config.id] = counts[pull.config.id]! + 1;
    newFlags[pull.config.id] = newFlags[pull.config.id]! || pull.isNew;
  }

  return order
      .map(
        (id) => _PackPullSummaryEntry(
          config: configs[id]!,
          count: counts[id]!,
          isNew: newFlags[id]!,
        ),
      )
      .toList(growable: false);
}

_EnemyRevealItemTier _itemTierForRarity({
  required EnemyCardRarity rarity,
  required EnemyCardRarity highestAvailableRarity,
  required EnemyCardRarity? secondHighestAvailableRarity,
}) {
  final highlightTier = resolveEnemyPackHighlightTier(
    highestDrawnRarity: rarity,
    highestAvailableRarity: highestAvailableRarity,
    secondHighestAvailableRarity: secondHighestAvailableRarity,
  );

  // Preserve the existing top/second-top reward emphasis contract, but avoid
  // jackpot theatrics when the available pool has not reached Rare yet.
  final highTierPoolUnlocked =
      highestAvailableRarity.index >= EnemyCardRarity.rare.index;
  return switch (highlightTier) {
    EnemyPackHighlightTier.highest when highTierPoolUnlocked =>
      _EnemyRevealItemTier.jackpot,
    EnemyPackHighlightTier.secondHighest when highTierPoolUnlocked =>
      _EnemyRevealItemTier.rare,
    _ => _EnemyRevealItemTier.basic,
  };
}

_EnemyRevealBatchTier _resolveRevealBatchTier({
  required List<PackPullResult> pulls,
  required EnemyCardRarity highestAvailableRarity,
  required EnemyCardRarity? secondHighestAvailableRarity,
}) {
  var hasRare = false;
  for (final pull in pulls) {
    final tier = _itemTierForRarity(
      rarity: pull.config.rarity,
      highestAvailableRarity: highestAvailableRarity,
      secondHighestAvailableRarity: secondHighestAvailableRarity,
    );
    if (tier == _EnemyRevealItemTier.jackpot) {
      return _EnemyRevealBatchTier.jackpot;
    }
    hasRare = hasRare || tier == _EnemyRevealItemTier.rare;
  }
  return hasRare ? _EnemyRevealBatchTier.rare : _EnemyRevealBatchTier.basic;
}

bool _batchContainsRareTierPulls({
  required List<PackPullResult> pulls,
  required EnemyCardRarity highestAvailableRarity,
  required EnemyCardRarity? secondHighestAvailableRarity,
}) {
  return pulls.any((pull) {
    final tier = _itemTierForRarity(
      rarity: pull.config.rarity,
      highestAvailableRarity: highestAvailableRarity,
      secondHighestAvailableRarity: secondHighestAvailableRarity,
    );
    return tier == _EnemyRevealItemTier.rare;
  });
}

List<_ScheduledPackPullSummary> _schedulePackPullSummaries({
  required List<PackPullResult> pulls,
  required _EnemyPackRevealTiming timing,
  required EnemyCardRarity highestAvailableRarity,
  required EnemyCardRarity? secondHighestAvailableRarity,
}) {
  final indexed = [
    for (final (index, summary) in _summarizePulls(pulls).indexed)
      (
        index: index,
        summary: summary,
        tier: _itemTierForRarity(
          rarity: summary.config.rarity,
          highestAvailableRarity: highestAvailableRarity,
          secondHighestAvailableRarity: secondHighestAvailableRarity,
        ),
      ),
  ];

  indexed.sort((a, b) {
    final tierCompare = a.tier.index.compareTo(b.tier.index);
    if (tierCompare != 0) {
      return tierCompare;
    }
    final rarityCompare = a.summary.config.rarity.index.compareTo(
      b.summary.config.rarity.index,
    );
    if (rarityCompare != 0) {
      return rarityCompare;
    }
    return a.index.compareTo(b.index);
  });

  final basicCount = indexed
      .where((entry) => entry.tier == _EnemyRevealItemTier.basic)
      .length;
  final rareCount = indexed
      .where((entry) => entry.tier == _EnemyRevealItemTier.rare)
      .length;
  final basicLastStart = basicCount == 0
      ? 0
      : (basicCount - 1) * timing.basicItemStaggerMilliseconds;
  final rareBaseStart = basicCount == 0
      ? 0
      : basicLastStart + timing.rareWaveDelayMilliseconds;
  final rareLastStart = rareCount == 0
      ? rareBaseStart
      : rareBaseStart + ((rareCount - 1) * timing.rareItemStaggerMilliseconds);
  final jackpotBaseStart = rareCount > 0
      ? rareLastStart + timing.jackpotWaveDelayMilliseconds
      : basicCount > 0
      ? basicLastStart + timing.jackpotWaveDelayMilliseconds
      : 0;

  var basicIndex = 0;
  var rareIndex = 0;
  var jackpotIndex = 0;
  return [
    for (final entry in indexed)
      _ScheduledPackPullSummary(
        summary: entry.summary,
        itemTier: entry.tier,
        revealStartMilliseconds: switch (entry.tier) {
          _EnemyRevealItemTier.basic =>
            basicIndex++ * timing.basicItemStaggerMilliseconds,
          _EnemyRevealItemTier.rare =>
            rareBaseStart + (rareIndex++ * timing.rareItemStaggerMilliseconds),
          _EnemyRevealItemTier.jackpot =>
            jackpotBaseStart +
                (jackpotIndex++ * timing.jackpotItemStaggerMilliseconds),
        },
      ),
  ];
}

int _resolveItemRevealMilliseconds({
  required List<_ScheduledPackPullSummary> scheduledSummaries,
  required _EnemyPackRevealTiming timing,
}) {
  var finalBeatMilliseconds = timing.itemRevealTargetMilliseconds;
  for (final scheduled in scheduledSummaries) {
    finalBeatMilliseconds = math.max(
      finalBeatMilliseconds,
      scheduled.revealStartMilliseconds +
          timing.lingerMillisecondsFor(scheduled.itemTier),
    );
  }
  return finalBeatMilliseconds;
}

Color _itemTierAccentColor(
  _EnemyRevealItemTier tier, {
  required Color fallback,
}) {
  return switch (tier) {
    _EnemyRevealItemTier.basic => fallback,
    _EnemyRevealItemTier.rare => LightcorePalette.flare,
    _EnemyRevealItemTier.jackpot => LightcorePalette.aether,
  };
}

double _itemRevealScale(double progress) {
  if (progress <= 0) {
    return 0.96;
  }
  if (progress >= 1) {
    return 1;
  }
  if (progress < 0.62) {
    final pop = Curves.easeOutCubic.transform(progress / 0.62);
    return 0.96 + (0.06 * pop);
  }
  final settle = Curves.easeOutCubic.transform((progress - 0.62) / 0.38);
  return 1.02 - (0.02 * settle);
}

double _itemGlowStrength({
  required _EnemyRevealItemTier itemTier,
  required double revealAgeMilliseconds,
  required _EnemyPackRevealTiming timing,
}) {
  final age = math.max(0.0, revealAgeMilliseconds);
  switch (itemTier) {
    case _EnemyRevealItemTier.basic:
      final fade = (1 - (age / timing.basicItemLingerMilliseconds)).clamp(
        0.0,
        1.0,
      );
      return 0.08 * fade;
    case _EnemyRevealItemTier.rare:
      final fade = (1 - (age / timing.rareItemLingerMilliseconds)).clamp(
        0.0,
        1.0,
      );
      final breath = 0.55 + (0.45 * math.sin(age / 180).abs());
      return 0.3 * fade * breath;
    case _EnemyRevealItemTier.jackpot:
      final burst = (1 - (age / timing.jackpotItemDropMilliseconds)).clamp(
        0.0,
        1.0,
      );
      final linger = (1 - (age / timing.jackpotItemLingerMilliseconds)).clamp(
        0.0,
        1.0,
      );
      return math.max(0.48 * burst, 0.34 * linger);
  }
}

EnemyCardRarity _resolveHighestPullRarity(List<PackPullResult> pulls) {
  return pulls
      .map((pull) => pull.config.rarity)
      .reduce((best, next) => next.index > best.index ? next : best);
}

// ignore: unused_element
Color _highlightAccentColor(EnemyPackHighlightTier tier) {
  return switch (tier) {
    EnemyPackHighlightTier.highest => LightcorePalette.aether,
    EnemyPackHighlightTier.secondHighest => LightcorePalette.gilded,
    EnemyPackHighlightTier.standard => LightcorePalette.layer2,
  };
}

Color _rarityTint(EnemyCardRarity rarity) {
  return switch (rarity) {
    EnemyCardRarity.basic => LightcorePalette.layer2,
    EnemyCardRarity.uncommon => LightcorePalette.success,
    EnemyCardRarity.rare => LightcorePalette.aether,
    EnemyCardRarity.epic => LightcorePalette.solar,
    EnemyCardRarity.legendary => LightcorePalette.violet,
  };
}
