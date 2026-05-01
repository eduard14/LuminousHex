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
    required this.onPlayMode,
    required this.onJoinMode,
    required this.onClaimReward,
  });

  final LightcoreTournamentOverview? overview;
  final LightcoreController controller;
  final bool loading;
  final bool busy;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final ValueChanged<LightcoreTournamentModeId> onOpenMode;
  final ValueChanged<LightcoreTournamentModeId> onPlayMode;
  final ValueChanged<LightcoreTournamentModeId> onJoinMode;
  final ValueChanged<LightcoreTournamentModeId> onClaimReward;

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
            _TournamentRankStrip(overview: overview!),
            const SizedBox(height: 12),
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
                          busy: busy,
                          highlighted: controller
                              .tutorialHighlightsTournamentModeCard(mode),
                          onOpen: () => onOpenMode(mode),
                          onPlay: () => onPlayMode(mode),
                          onJoin: () => onJoinMode(mode),
                          onClaim: () => onClaimReward(mode),
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

class _TournamentRankStrip extends StatelessWidget {
  const _TournamentRankStrip({required this.overview});

  final LightcoreTournamentOverview overview;

  @override
  Widget build(BuildContext context) {
    return AuroraPanel(
      tint: LightcorePalette.aether,
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final mode in LightcoreTournamentModeId.values)
            _TournamentRankChip(modeState: overview.modeFor(mode)),
        ],
      ),
    );
  }
}

class _TournamentRankChip extends StatelessWidget {
  const _TournamentRankChip({required this.modeState});

  final LightcoreTournamentModeState modeState;

  @override
  Widget build(BuildContext context) {
    final tint = _modeTint(modeState.mode);
    return Container(
      constraints: const BoxConstraints(minWidth: 154),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_modeIcon(modeState.mode), color: tint, size: 18),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            child: Text(
              modeState.playerRank == null
                  ? 'Rank pending'
                  : '#${modeState.playerRank}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            modeState.joined ? '${modeState.playerBestScore}' : 'Join',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: tint,
              fontWeight: FontWeight.w800,
            ),
          ),
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
    final helpMessage = [
      overview?.statusMessage ?? 'Weekly events rotate on a shared schedule.',
      _tournamentNexusHelp,
    ].join('\n\n');
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
                      overview?.seasonLabel ?? 'Weekly event rotation',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              LightcoreInfoButton(
                title: 'Tournament Help',
                message: helpMessage,
                tint: LightcorePalette.warning,
              ),
              const SizedBox(width: 4),
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

const String _tournamentNexusHelp =
    'Anomaly Blitz is open for testing with weekend-length survival sessions. Hex and Arena Flow run on the weekly rotation. Arena Flow uses each player\'s highest-layer Home Tower with server-seeded rivals, and rewards are awarded from the closed server leaderboard after reset.';

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
    required this.busy,
    required this.highlighted,
    required this.onOpen,
    required this.onPlay,
    required this.onJoin,
    required this.onClaim,
  });

  final LightcoreTournamentModeState modeState;
  final bool busy;
  final bool highlighted;
  final VoidCallback onOpen;
  final VoidCallback onPlay;
  final VoidCallback onJoin;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final tint = _modeTint(modeState.mode);
    final helpMessage = _modeHelpMessage(modeState);
    return GuidedFocusFrame(
      active: highlighted,
      tint: LightcorePalette.quest,
      radius: 18,
      child: AuroraPanel(
        tint: tint,
        padding: const EdgeInsets.all(14),
        onTap: onOpen,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 42),
              child: Row(
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          modeState.mode.eventCadenceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: tint,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: modeState.rewardReady && !modeState.rewardClaimed
                        ? 'Claim reward'
                        : modeState.joined
                        ? 'Start run'
                        : 'Join event',
                    child: IconButton.filledTonal(
                      onPressed:
                          modeState.rewardReady && !modeState.rewardClaimed
                          ? (busy ? null : onClaim)
                          : modeState.joined
                          ? onPlay
                          : busy || !modeState.isOpen
                          ? null
                          : onJoin,
                      icon: Icon(
                        modeState.rewardReady && !modeState.rewardClaimed
                            ? Icons.workspace_premium_rounded
                            : modeState.joined
                            ? Icons.play_arrow_rounded
                            : Icons.add_rounded,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: LightcoreInfoButton(
                title: '${modeState.mode.label} Details',
                message: helpMessage,
                tint: tint,
              ),
            ),
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
