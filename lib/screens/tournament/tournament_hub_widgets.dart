part of '../tournament_screen.dart';

class _TournamentHubScreen extends StatelessWidget {
  const _TournamentHubScreen({
    required this.overview,
    required this.controller,
    required this.loading,
    required this.busy,
    required this.errorMessage,
    required this.onRefresh,
    required this.onOpenMode,
  });

  final LightcoreTournamentOverview? overview;
  final LightcoreController controller;
  final bool loading;
  final bool busy;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final ValueChanged<LightcoreTournamentModeId> onOpenMode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TournamentHeader(
            overview: overview,
            controller: controller,
            busy: busy || loading,
            onRefresh: onRefresh,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            AuroraPanel(
              tint: LightcorePalette.warning,
              padding: const EdgeInsets.all(16),
              child: Text(
                errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          if (controller.tutorialTournamentModeTarget != null) ...[
            const SizedBox(height: 12),
            _TournamentTutorialPanel(controller: controller),
          ],
          const SizedBox(height: 14),
          if (overview != null) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final tileWidth = wide
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final mode in LightcoreTournamentModeId.values)
                      SizedBox(
                        width: tileWidth,
                        child: _TournamentModeHubCard(
                          modeState: overview!.modeFor(mode),
                          highlighted: controller
                              .tutorialHighlightsTournamentModeCard(mode),
                          onOpen: () => onOpenMode(mode),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _TournamentHeader extends StatelessWidget {
  const _TournamentHeader({
    required this.overview,
    required this.controller,
    required this.busy,
    required this.onRefresh,
  });

  final LightcoreTournamentOverview? overview;
  final LightcoreController controller;
  final bool busy;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final endsAt = overview?.endsAt;
    return AuroraPanel(
      tint: LightcorePalette.warning,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tournament Nexus',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      overview?.seasonLabel ?? 'Choose a mode to open setup.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: busy ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderChip(label: 'Pilot', value: controller.playerDisplayName),
              _HeaderChip(
                label: 'Rating',
                value: '${overview?.globalTournamentRating ?? 1000}',
              ),
              _HeaderChip(
                label: 'Ends',
                value: endsAt == null ? 'Unknown' : _formatCountdown(endsAt),
              ),
              _HeaderChip(
                label: 'Boost',
                value: controller.hasActiveTournamentExperienceBoost
                    ? controller.tournamentExperienceBoostLabel
                    : 'Inactive',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: LightcorePalette.mist.withValues(alpha: 0.72),
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TournamentTutorialPanel extends StatelessWidget {
  const _TournamentTutorialPanel({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final targetMode = controller.tutorialTournamentModeTarget;
    if (targetMode == null) {
      return const SizedBox.shrink();
    }

    final tint = _modeTint(targetMode);
    return AuroraPanel(
      tint: tint,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.tutorialHeadline ?? targetMode.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tint,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            controller.tutorialPrompt ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (controller.tutorialMechanicHint != null) ...[
            const SizedBox(height: 8),
            Text(
              controller.tutorialMechanicHint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.82),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TournamentModeHubCard extends StatelessWidget {
  const _TournamentModeHubCard({
    required this.modeState,
    required this.highlighted,
    required this.onOpen,
  });

  final LightcoreTournamentModeState modeState;
  final bool highlighted;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final tint = _modeTint(modeState.mode);
    return GuidedFocusFrame(
      active: highlighted,
      tint: LightcorePalette.quest,
      radius: 18,
      child: AuroraPanel(
        tint: tint,
        padding: const EdgeInsets.all(14),
        onTap: onOpen,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0.16),
                border: Border.all(color: tint.withValues(alpha: 0.46)),
              ),
              child: Icon(_modeIcon(modeState.mode), color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    modeState.mode.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _modeHubStatusLabel(modeState),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: tint,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded, color: tint, size: 24),
          ],
        ),
      ),
    );
  }
}

IconData _modeIcon(LightcoreTournamentModeId mode) => switch (mode) {
  LightcoreTournamentModeId.enemyBlitz => Icons.bolt_rounded,
  LightcoreTournamentModeId.hexGauntlet => Icons.hexagon_rounded,
  LightcoreTournamentModeId.arenaFlow => Icons.blur_on_rounded,
};

String _modeHubStatusLabel(LightcoreTournamentModeState modeState) {
  if (modeState.rewardReady && !modeState.rewardClaimed) {
    return 'Reward ready';
  }
  if (!modeState.isOpen) {
    return 'Opens ${_formatCountdown(modeState.startsAt)}';
  }
  return modeState.mode.eventCadenceLabel;
}

String _modeHelpMessage(LightcoreTournamentModeState modeState) {
  final leaderboard = modeState.leaderboard.isEmpty
      ? 'No leaderboard snapshot is available yet.'
      : modeState.leaderboard
            .take(3)
            .indexed
            .map(
              (entry) =>
                  '#${entry.$1 + 1} ${entry.$2.displayName} - ${entry.$2.score}',
            )
            .join('\n');

  return [
    modeState.mode.subtitle,
    modeState.mode.compressedLoopLabel,
    '${modeState.mode.mechanicLabel}: ${modeState.mechanicSummary}',
    modeState.statusMessage,
    'Focus: ${modeState.mode.focusLabel}. Entries: ${modeState.groupSize}.',
    leaderboard,
  ].join('\n\n');
}
