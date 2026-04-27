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
  final ValueChanged<LightcoreTournamentModeId> onJoinMode;
  final ValueChanged<LightcoreTournamentModeId> onClaimReward;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
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
          const SizedBox(height: 12),
          AuroraPanel(
            tint: LightcorePalette.aether,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Same game, compressed clock.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tournament events live on their own screen and run from normalized event shells. Weekly scores come from draft choices and run execution, not permanent tower power.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ModeSummaryChip(
                      tint: LightcorePalette.flare,
                      label: 'Anomaly Blitz',
                      summary:
                          'Weekend survival sprint with rapid reinvestment.',
                    ),
                    _ModeSummaryChip(
                      tint: LightcorePalette.solar,
                      label: 'Hex',
                      summary:
                          'Solo weekly path climb on the global leaderboard.',
                    ),
                    _ModeSummaryChip(
                      tint: LightcorePalette.violet,
                      label: 'Arena Flow',
                      summary:
                          'Weekly duel ladder. Highest flow after 20 seconds wins.',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final mode in LightcoreTournamentModeId.values) ...[
            if (overview != null)
              _TournamentModeHubCard(
                modeState: overview!.modeFor(mode),
                busy: busy,
                highlighted: controller.tutorialHighlightsTournamentModeCard(
                  mode,
                ),
                onOpen: () => onOpenMode(mode),
                onJoin: () => onJoinMode(mode),
                onClaim: () => onClaimReward(mode),
              ),
            if (overview != null) const SizedBox(height: 12),
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
                      overview?.seasonLabel ?? 'Weekly event rotation',
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
              _HeaderChip(
                label: 'Event Seed',
                value: '${controller.tournamentPowerIndex}',
              ),
            ],
          ),
          if (overview != null) ...[
            const SizedBox(height: 12),
            Text(
              overview!.statusMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.78),
              ),
            ),
          ],
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
              letterSpacing: 1.2,
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

class _ModeSummaryChip extends StatelessWidget {
  const _ModeSummaryChip({
    required this.tint,
    required this.label,
    required this.summary,
  });

  final Color tint;
  final String label;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: tint.withValues(alpha: 0.12),
        border: Border.all(color: tint.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(summary, style: Theme.of(context).textTheme.bodySmall),
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
    required this.onJoin,
    required this.onClaim,
  });

  final LightcoreTournamentModeState modeState;
  final bool busy;
  final bool highlighted;
  final VoidCallback onOpen;
  final VoidCallback onJoin;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final tint = _modeTint(modeState.mode);
    return GuidedFocusFrame(
      active: highlighted,
      tint: LightcorePalette.quest,
      radius: 24,
      child: AuroraPanel(
        tint: tint,
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
                        modeState.mode.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        modeState.mode.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: tint.withValues(alpha: 0.14),
                  ),
                  child: Text(
                    modeState.mode.eventCadenceLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: tint,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _HeaderChip(
                  label: 'Board',
                  value:
                      modeState.matchBucketLabel ?? modeState.mode.queueLabel,
                ),
                _HeaderChip(label: 'Focus', value: modeState.mode.focusLabel),
                _HeaderChip(label: 'Entries', value: '${modeState.groupSize}'),
                _HeaderChip(
                  label: 'Best',
                  value: modeState.joined
                      ? '${modeState.playerBestScore}'
                      : 'Not joined',
                ),
                _HeaderChip(
                  label: 'Window',
                  value: modeState.isOpen
                      ? 'Live'
                      : 'Opens ${_formatCountdown(modeState.startsAt)}',
                ),
                _HeaderChip(
                  label: 'Rank',
                  value: modeState.playerRank == null
                      ? 'Pending'
                      : '#${modeState.playerRank}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              modeState.mode.compressedLoopLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tint,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${modeState.mode.mechanicLabel}: ${modeState.mechanicSummary}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              modeState.statusMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (modeState.leaderboard.isNotEmpty) ...[
              const SizedBox(height: 12),
              AuroraPanel(
                tint: tint,
                radius: 20,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Leaderboard Snapshot',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (
                      var index = 0;
                      index < min(modeState.leaderboard.length, 3);
                      index += 1
                    ) ...[
                      _LeaderboardRow(
                        rank: index + 1,
                        entry: modeState.leaderboard[index],
                      ),
                      if (index < min(modeState.leaderboard.length, 3) - 1)
                        const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(
                    modeState.joined ? 'Enter Event' : 'Inspect Event',
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: busy || modeState.joined || !modeState.isOpen
                      ? null
                      : onJoin,
                  icon: const Icon(Icons.rocket_launch_rounded),
                  label: Text(
                    modeState.isOpen
                        ? _joinButtonLabel(modeState.mode)
                        : 'Event Closed',
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed:
                      busy || !modeState.rewardReady || modeState.rewardClaimed
                      ? null
                      : onClaim,
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: Text(
                    modeState.rewardClaimed ? 'Claimed' : 'Claim Reward',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
