part of '../enemy_management_screen.dart';

class _ThreatCardArt extends StatelessWidget {
  const _ThreatCardArt({
    required this.config,
    required this.size,
    this.fallbackSize,
    this.fit = BoxFit.contain,
  });

  final EnemyConfig config;
  final double size;
  final double? fallbackSize;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final assetPath = enemyImageAssetForConfig(config);
    if (assetPath == null) {
      return _fallbackGlyph();
    }
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final targetCacheSize = (size * devicePixelRatio)
        .ceil()
        .clamp(96, 768)
        .toInt();

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      cacheWidth: targetCacheSize,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => _fallbackGlyph(),
    );
  }

  Widget _fallbackGlyph() {
    final fallbackDimension = fallbackSize ?? size;
    if (config.isBoss) {
      return _BossGlyph(config: config, size: fallbackDimension * 0.82);
    }
    return AffinityGlyph(
      affinity: config.affinity,
      size: fallbackDimension * 0.68,
    );
  }
}

class _ThreatPhotoChrome extends StatelessWidget {
  const _ThreatPhotoChrome({
    required this.dimension,
    required this.primary,
    required this.secondary,
    required this.rarityTint,
  });

  final double dimension;
  final Color primary;
  final Color secondary;
  final Color rarityTint;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF02040A).withValues(alpha: 0.72),
                    const Color(0xFF02040A).withValues(alpha: 0.08),
                    const Color(0xFF02040A).withValues(alpha: 0.18),
                    const Color(0xFF02040A).withValues(alpha: 0.78),
                  ],
                  stops: const [0, 0.34, 0.58, 1],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            width: dimension * 0.68,
            height: dimension * 0.68,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary.withValues(alpha: 0.5),
                    secondary.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.48, 1],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            width: dimension * 0.72,
            height: dimension * 0.72,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    rarityTint.withValues(alpha: 0.2),
                    rarityTint.withValues(alpha: 0.44),
                  ],
                  stops: const [0, 0.56, 1],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreatCardTitleOverlay extends StatelessWidget {
  const _ThreatCardTitleOverlay({
    required this.config,
    required this.dimension,
    required this.tint,
  });

  final EnemyConfig config;
  final double dimension;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final compact = dimension < 96;
    final showSubtitle = dimension >= 104;
    final typeLabel = config.isBoss ? 'Apex' : config.affinity.label;
    final title = compact ? config.rarity.label : config.name;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 6,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF080A12).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: tint.withValues(alpha: 0.24), width: 0.8),
      ),
      child: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: LightcorePalette.layer2,
          fontWeight: FontWeight.w900,
          height: 1,
          fontSize: compact ? 8.5 : 9.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (showSubtitle) ...[
              const SizedBox(height: 2),
              Text(
                '${config.rarity.label} | $typeLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tint.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w800,
                  fontSize: 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThreatSummonCard extends StatelessWidget {
  const _ThreatSummonCard({
    required this.config,
    required this.dimension,
    this.artSize,
    this.bottomLabel,
    this.bottom,
    this.topRight,
    this.locked = false,
    this.selected = false,
    this.emphasized = false,
    this.glowTint,
    this.glowStrength = 0,
    this.onTap,
    this.semanticLabel,
  });

  final EnemyConfig config;
  final double dimension;
  final double? artSize;
  final String? bottomLabel;
  final Widget? bottom;
  final Widget? topRight;
  final bool locked;
  final bool selected;
  final bool emphasized;
  final Color? glowTint;
  final double glowStrength;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final rarityTint = _rarityTint(config.rarity);
    final affinityTint = config.affinity.color;
    final secondaryTint = config.secondaryAffinity?.color ?? affinityTint;
    final radius = BorderRadius.circular(8);
    final effectiveGlow = glowStrength.clamp(0.0, 1.0).toDouble();
    final shadowTint = glowTint ?? rarityTint;
    final opacity = locked ? 0.46 : 1.0;
    final showTitleOverlay = dimension >= 82;
    final titleRightInset = topRight == null ? 6.0 : 34.0;

    Widget card = Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: rarityTint.withValues(alpha: locked ? 0.38 : 0.96),
          width: selected || emphasized ? 2.4 : 2,
        ),
        gradient: LinearGradient(
          colors: [
            rarityTint.withValues(alpha: locked ? 0.08 : 0.18),
            const Color(0xFFF7F9FC).withValues(alpha: locked ? 0.48 : 0.96),
            const Color(0xFFE5EAF2).withValues(alpha: locked ? 0.42 : 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowTint.withValues(alpha: 0.14 + (effectiveGlow * 0.22)),
            blurRadius: 16 + (effectiveGlow * 20),
            spreadRadius: -5 + (effectiveGlow * 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: opacity,
                child: Center(
                  child: _ThreatCardArt(
                    config: config,
                    size: dimension,
                    fallbackSize: artSize ?? dimension * 0.58,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: _ThreatPhotoChrome(
                dimension: dimension,
                primary: affinityTint,
                secondary: secondaryTint,
                rarityTint: rarityTint,
              ),
            ),
            if (showTitleOverlay)
              Positioned(
                top: 6,
                left: 6,
                right: titleRightInset,
                child: _ThreatCardTitleOverlay(
                  config: config,
                  dimension: dimension,
                  tint: affinityTint,
                ),
              ),
            if (topRight != null)
              Positioned(top: 5, right: 5, child: topRight!),
            if (bottomLabel != null || bottom != null)
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Container(
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF080A12).withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: rarityTint.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: IconTheme.merge(
                    data: const IconThemeData(
                      color: LightcorePalette.mist,
                      size: 11,
                    ),
                    child: DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: LightcorePalette.mist,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                      child: bottom == null
                          ? Text(
                              bottomLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            )
                          : FittedBox(fit: BoxFit.scaleDown, child: bottom!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: radius, onTap: onTap, child: card),
      );
    }

    return Semantics(
      button: onTap != null,
      label: semanticLabel ?? config.name,
      child: card,
    );
  }
}

// ignore: unused_element
class _SwarmPressurePanel extends StatelessWidget {
  const _SwarmPressurePanel({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bundle = controller.activeThreatScanBundle;
    final groupStats = controller.activeThreatAssignmentGroupStats;
    return AuroraPanel(
      tint: LightcorePalette.layer2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Knowledge Book Pressure', style: textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            '${bundle.name}: built from the active region, Knowledge Book, and Threat Director tuning. Directors adjust current spawn cadence and enemy strength for reward bonuses. Effective Gain is Threat Reward multiplied by Output Efficiency. ${bundle.counterplayLabel}',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(label: 'Risk ${bundle.riskLabel}'),
              _InfoChip(label: 'Book cards ${bundle.activeCardCount}'),
              _InfoChip(label: 'Directors ${bundle.directorCount}'),
              _InfoChip(
                label:
                    'Live ${controller.enemyCount}/${controller.enemyTargetCount}',
              ),
              const _InfoChip(label: 'Target set by region'),
              _InfoChip(label: 'Every ${controller.enemySpawnCadenceLabel}'),
              _InfoChip(label: 'Threat ${bundle.threatRewardLabel}'),
              _InfoChip(label: 'Stability ${bundle.stabilityPressureLabel}'),
              _InfoChip(label: 'DPS ${controller.activeLayerMaxDpsLabel}'),
              _InfoChip(
                label: 'Budget ${controller.activeLayerMaxDpsPerEnemyLabel}',
              ),
              _InfoChip(label: 'Output ${controller.outputEfficiencyLabel}'),
              _InfoChip(label: 'Gain ${bundle.effectiveGainLabel}'),
              if (groupStats.hasAnomalies)
                _InfoChip(
                  label:
                      '${_formatThreatStat(groupStats.lumensPerMinute)} Lumens/minute',
                ),
              if (groupStats.hasAnomalies)
                _InfoChip(
                  label:
                      '${_formatThreatStat(groupStats.experiencePerMinute)} EXP/min',
                ),
              if (groupStats.hasAnomalies)
                _InfoChip(
                  label:
                      '${_formatThreatStat(groupStats.clearsPerMinute)} clears/min',
                ),
              if (groupStats.isDpsLimited)
                const _InfoChip(label: 'DPS limited'),
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
            child: _InlineEnemyNote(
              message:
                  'Enemy quantity is no longer a manual setting. Region content and Threat Director traits define live spawn pressure.',
              tint: LightcorePalette.layer2,
            ),
          ),
        ],
      ),
    );
  }
}
