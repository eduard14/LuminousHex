part of '../lightcore_shell.dart';

class _LayerDockButton extends StatelessWidget {
  const _LayerDockButton({
    required this.label,
    required this.statusLabel,
    required this.tint,
    required this.onTap,
  });

  final String label;
  final String statusLabel;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open shells - $statusLabel',
      child: AuroraPanel(
        tint: tint,
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_rounded, color: tint, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: tint,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: tint.withValues(alpha: 0.12),
                border: Border.all(color: tint.withValues(alpha: 0.26)),
              ),
              child: Text(
                statusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallProgressBarPanel extends StatelessWidget {
  const _OverallProgressBarPanel({
    required this.controller,
    required this.compact,
  });

  final LightcoreController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bossTint =
        controller.activeBossEnemyCard?.config.affinity.color ??
        LightcorePalette.solar;

    return Column(
      children: [
        _ProgressStrip(
          value: controller.overallLevelProgress,
          color: LightcorePalette.aether,
          compact: compact,
          semanticsLabel: controller.overallLevelProgressLabel,
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AR ${controller.accountRadianceLevel}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: LightcorePalette.mist,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'TS ${controller.towerStrengthCompactLabel}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LightcorePalette.aether,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 6 : 8),
        _ProgressStrip(
          value: controller.bossSpawnProgress,
          color: bossTint,
          compact: compact,
          semanticsLabel: controller.bossSpawnStatusLabel,
          trailing: Icon(
            Icons.shield_moon_rounded,
            size: compact ? 18 : 20,
            color: controller.bossAlive ? LightcorePalette.warning : bossTint,
          ),
        ),
      ],
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({
    required this.value,
    required this.color,
    required this.compact,
    required this.trailing,
    required this.semanticsLabel,
  });

  final double value;
  final Color color;
  final bool compact;
  final Widget trailing;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: Row(
        children: [
          Expanded(
            child: MeterBar(
              value: value,
              color: color,
              height: compact ? 8 : 10,
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }
}

class _ThreatChallengeHudBanner extends StatelessWidget {
  const _ThreatChallengeHudBanner({
    required this.controller,
    required this.onTap,
  });

  final LightcoreController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final challenge = controller.activeThreatRegionChallenge;
    if (challenge == null) {
      return const SizedBox.shrink();
    }
    final region = controller.threatRegionConfigById(challenge.regionId);
    if (region == null) {
      return const SizedBox.shrink();
    }
    final progress = controller.activeThreatRegionChallengeWaveProgress;
    final waveRemaining = controller
        .activeThreatRegionChallengeWaveRemainingSeconds
        .ceil();
    final waveLabel =
        'Wave ${challenge.waveIndex + 1}/${LightcoreController.threatRegionChallengeWaveCount}';
    final requiredBosses = controller.activeThreatRegionRequiredBossCount;
    final defeatedBosses = controller.activeThreatRegionDefeatedBossCount;
    final bossLabel = requiredBosses <= 0
        ? 'Pressure run'
        : 'Apex $defeatedBosses/$requiredBosses';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: LightcorePalette.panel.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: LightcorePalette.warning.withValues(alpha: 0.48),
            ),
            boxShadow: [
              BoxShadow(
                color: LightcorePalette.warning.withValues(alpha: 0.12),
                blurRadius: 18,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.flag_rounded,
                      size: 18,
                      color: LightcorePalette.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$waveLabel  •  ${region.name} Lv ${challenge.targetStabilizationLevel}/${region.stabilizationLayers}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: LightcorePalette.mist,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatChallengeDuration(waveRemaining),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: LightcorePalette.warning,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: progress,
                    backgroundColor: LightcorePalette.night.withValues(
                      alpha: 0.72,
                    ),
                    color: LightcorePalette.warning,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$bossLabel  •  Current wave timer',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: LightcorePalette.mist.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatChallengeDuration(int totalSeconds) {
  final safeSeconds = math.max(0, totalSeconds);
  final minutes = safeSeconds ~/ 60;
  final seconds = safeSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class _ShellBottomNavigation extends StatelessWidget {
  const _ShellBottomNavigation({
    required this.controller,
    required this.compact,
    required this.destinations,
    required this.selectedIndex,
    required this.tint,
    required this.onSelected,
  });

  final LightcoreController controller;
  final bool compact;
  final List<_ShellOverlayDestination> destinations;
  final int selectedIndex;
  final Color tint;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.panel.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 6,
          vertical: compact ? 4 : 6,
        ),
        child: Row(
          children: [
            ...List.generate(destinations.length, (index) {
              final destination = destinations[index];
              final locked = destination.lockedMessage(controller) != null;
              return Expanded(
                child: _ShellNavigationItem(
                  controller: controller,
                  destination: destination,
                  compact: compact,
                  locked: locked,
                  selected: index == selectedIndex,
                  onTap: () => onSelected(index),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ShellOverlayFrame extends StatelessWidget {
  const _ShellOverlayFrame({
    required this.controller,
    required this.destination,
    required this.onClose,
    required this.onOpenLayers,
    this.fullscreen = false,
    required this.child,
  });

  final LightcoreController controller;
  final _ShellOverlayDestination destination;
  final VoidCallback onClose;
  final VoidCallback onOpenLayers;
  final bool fullscreen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final media = MediaQuery.of(context);
        final isCompactLayout = media.size.width < 760;
        final textTheme = Theme.of(context).textTheme;
        final bottomContentPadding = isCompactLayout ? 20.0 : 18.0;
        final showLayerButton =
            controller.layerNavigationUnlocked &&
            destination != _ShellOverlayDestination.spaceRoom &&
            destination != _ShellOverlayDestination.dungeons &&
            destination != _ShellOverlayDestination.tournaments;
        if (fullscreen) {
          return DecoratedBox(
            decoration: const BoxDecoration(color: LightcorePalette.night),
            child: SafeArea(child: child),
          );
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            color: LightcorePalette.night.withValues(alpha: 0.72),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isCompactLayout ? 10 : 16,
                10,
                isCompactLayout ? 10 : 16,
                isCompactLayout ? 10 : 16,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    isCompactLayout ? 28 : 34,
                  ),
                  border: Border.all(
                    color: LightcorePalette.stroke.withValues(alpha: 0.64),
                  ),
                  color: LightcorePalette.panel.withValues(alpha: 0.98),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 28,
                      spreadRadius: -12,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isCompactLayout ? 14 : 18,
                        isCompactLayout ? 14 : 18,
                        isCompactLayout ? 14 : 18,
                        12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  destination.label,
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: LightcorePalette.mist,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (showLayerButton)
                                IconButton(
                                  tooltip: 'Shells',
                                  onPressed: onOpenLayers,
                                  icon: const Icon(Icons.layers_rounded),
                                ),
                              GuidedFocusFrame(
                                active: controller
                                    .tutorialHighlightsOverlayBackButton,
                                tint: LightcorePalette.quest,
                                radius: 20,
                                child: IconButton(
                                  tooltip: 'Return to Battle',
                                  onPressed: onClose,
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 1,
                      color: LightcorePalette.stroke.withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isCompactLayout ? 12 : 18,
                          10,
                          isCompactLayout ? 12 : 18,
                          bottomContentPadding,
                        ),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShellNavigationItem extends StatelessWidget {
  const _ShellNavigationItem({
    required this.controller,
    required this.destination,
    required this.compact,
    required this.locked,
    required this.selected,
    required this.onTap,
  });

  final LightcoreController controller;
  final _ShellOverlayDestination destination;
  final bool compact;
  final bool locked;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = locked ? LightcorePalette.stroke : destination.tint;
    final iconColor = locked
        ? LightcorePalette.warning
        : selected
        ? accent
        : LightcorePalette.mist.withValues(alpha: locked ? 0.46 : 0.72);
    final highlighted = switch (destination) {
      _ShellOverlayDestination.towers => controller.tutorialHighlightsTowersNav,
      _ShellOverlayDestination.threatMap =>
        controller.tutorialHighlightsThreatMapNav,
      _ShellOverlayDestination.enemies =>
        controller.tutorialHighlightsEnemiesNav,
      _ShellOverlayDestination.managers =>
        controller.tutorialHighlightsManagersNav,
      _ShellOverlayDestination.mentees =>
        controller.tutorialHighlightsMenteesNav,
      _ShellOverlayDestination.mentors =>
        controller.tutorialHighlightsMentorsNav,
      _ShellOverlayDestination.tournaments =>
        controller.tutorialHighlightsTournamentsNav,
      _ => false,
    };

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 3),
      child: GuidedFocusFrame(
        active: highlighted,
        tint: LightcorePalette.quest,
        child: Tooltip(
          message: destination.label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 6 : 8,
                  vertical: compact ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? accent.withValues(alpha: 0.6)
                        : Colors.transparent,
                  ),
                  color: selected
                      ? accent.withValues(alpha: 0.12)
                      : Colors.transparent,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.1),
                            blurRadius: 14,
                            spreadRadius: -8,
                          ),
                        ]
                      : const [],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconTheme(
                        data: IconThemeData(
                          size: compact ? 19 : 22,
                          color: iconColor,
                        ),
                        child: locked
                            ? const Icon(Icons.lock_rounded)
                            : destination.navigationIcon,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        destination.shortLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected
                              ? iconColor
                              : LightcorePalette.mist.withValues(
                                  alpha: locked ? 0.54 : 0.78,
                                ),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
