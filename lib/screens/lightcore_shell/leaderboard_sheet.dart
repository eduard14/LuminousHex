part of '../lightcore_shell.dart';

class _GlobalLeaderboardSheet extends StatefulWidget {
  const _GlobalLeaderboardSheet({
    required this.controller,
    required this.backend,
  });

  final LightcoreController controller;
  final FirebaseLightcoreBackend backend;

  @override
  State<_GlobalLeaderboardSheet> createState() =>
      _GlobalLeaderboardSheetState();
}

class _GlobalLeaderboardSheetState extends State<_GlobalLeaderboardSheet> {
  LightcoreSocialOverview? _overview;
  bool _loading = false;
  String? _error;

  static const Duration _globalBoardRefreshCadence = Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    _overview = widget.controller.socialOverview;
    if (widget.backend.canUseCloudSave) {
      unawaited(_refreshLeaderboard());
    }
  }

  Future<void> _refreshLeaderboard() async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview = await widget.backend.fetchSocialOverview();
      if (!mounted) {
        return;
      }
      widget.controller.syncSocialOverview(overview);
      setState(() => _overview = overview);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.width < 480;
    final usableHeight = (media.size.height - media.padding.vertical)
        .clamp(360.0, media.size.height)
        .toDouble();
    final overview = _overview ?? widget.controller.socialOverview;
    final serverLeaders =
        overview?.globalTowerStrengthLeaderboard ??
        const <LightcoreSocialPlayer>[];
    final self = _localSelfProjection(overview);
    final leaders = _projectLeaderboardRows(serverLeaders, self);
    final rankedPlayers = widget.controller.globalTowerStrengthRankedPlayers;
    final ownRank = self?.towerStrengthRank;
    final ownRankLabel = ownRank == null
        ? '#--'
        : rankedPlayers > 0
        ? '#$ownRank of $rankedPlayers'
        : '#$ownRank';
    final ownStrength =
        self?.towerStrength ?? widget.controller.globalRankingTowerStrength;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 14 : 18,
          8,
          compact ? 14 : 18,
          compact ? 18 : 22,
        ),
        child: SizedBox(
          height: usableHeight * (compact ? 0.86 : 0.82),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.leaderboard_rounded,
                    color: LightcorePalette.quest,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Global Leaderboard',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => unawaited(_refreshLeaderboard()),
                    icon: _loading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                    label: const Text('Sync'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                rankedPlayers > 0
                    ? 'Your rank previews immediately from local tower changes. The rest of the global board refreshes about every ${_globalBoardRefreshCadence.inMinutes} minutes.'
                    : 'Total Strength ranking syncs after cloud save publishes your public profile.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  StatusPill(
                    label: 'Your Rank',
                    value: ownRankLabel,
                    tint: LightcorePalette.quest,
                    icon: Icons.workspace_premium_rounded,
                  ),
                  StatusPill(
                    label: 'Your TS',
                    value: _formatMetricCount(ownStrength),
                    tint: LightcorePalette.layer2,
                    icon: Icons.emoji_events_rounded,
                  ),
                  StatusPill(
                    label: 'Board',
                    value: serverLeaders.isEmpty
                        ? 'Pending'
                        : '${serverLeaders.length}',
                    tint: LightcorePalette.aether,
                    icon: Icons.public_rounded,
                  ),
                  if (widget.controller.globalTowerStrengthRankIsProjected)
                    const StatusPill(
                      label: 'Rank Source',
                      value: 'Live Preview',
                      tint: LightcorePalette.solar,
                      icon: Icons.bolt_rounded,
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LightcorePalette.warning,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: leaders.isEmpty
                    ? AuroraPanel(
                        tint: LightcorePalette.quest,
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Global leaderboard sync is pending.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: leaders.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _GlobalLeaderboardRow(
                            player: leaders[index],
                            fallbackRank: index + 1,
                            selfUid: self?.uid,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LightcoreSocialPlayer? _localSelfProjection(
    LightcoreSocialOverview? overview,
  ) {
    final self = overview?.self;
    if (self == null) {
      return null;
    }
    final localStrength = widget.controller.globalRankingTowerStrength;
    final rank = widget.controller.globalTowerStrengthRank;
    final rankedPlayers = widget.controller.globalTowerStrengthRankedPlayers;
    return self.copyWith(
      towerStrength: localStrength,
      towerStrengthRank: rank,
      towerStrengthRankedPlayers: rankedPlayers,
    );
  }

  List<LightcoreSocialPlayer> _projectLeaderboardRows(
    List<LightcoreSocialPlayer> serverLeaders,
    LightcoreSocialPlayer? self,
  ) {
    if (self == null) {
      return serverLeaders;
    }
    final rankedPlayers = widget.controller.globalTowerStrengthRankedPlayers;
    final rows =
        <LightcoreSocialPlayer>[
          for (final player in serverLeaders)
            if (player.uid != self.uid) player,
          self,
        ]..sort((a, b) {
          final byStrength = b.towerStrength.compareTo(a.towerStrength);
          if (byStrength != 0) {
            return byStrength;
          }
          return a.displayName.compareTo(b.displayName);
        });
    return List<LightcoreSocialPlayer>.unmodifiable(<LightcoreSocialPlayer>[
      for (var index = 0; index < rows.length; index += 1)
        rows[index].copyWith(
          towerStrengthRank: index + 1,
          towerStrengthRankedPlayers: rankedPlayers,
        ),
    ]);
  }
}

class _GlobalLeaderboardRow extends StatelessWidget {
  const _GlobalLeaderboardRow({
    required this.player,
    required this.fallbackRank,
    required this.selfUid,
  });

  final LightcoreSocialPlayer player;
  final int fallbackRank;
  final String? selfUid;

  @override
  Widget build(BuildContext context) {
    final isSelf = selfUid != null && player.uid == selfUid;
    final rank = player.towerStrengthRank ?? fallbackRank;
    final tint = isSelf ? LightcorePalette.solar : LightcorePalette.aether;
    final name = player.displayName.trim().isEmpty
        ? player.playerId
        : player.displayName.trim();
    final avatar = player.avatar;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: isSelf ? 0.56 : 0.28)),
        color: isSelf
            ? LightcorePalette.solar.withValues(alpha: 0.1)
            : LightcorePalette.panelRaised.withValues(alpha: 0.72),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: tint,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox.square(
            dimension: 38,
            child: LightcoreGuideBadge(
              guide: avatar.guideProfile,
              size: 38,
              equipmentLoadout: LightcoreController.equipmentReleaseEnabled
                  ? CosmicEquipmentLoadout.fromAvatarPieces(
                      avatar.equipmentPieces,
                    )
                  : CosmicEquipmentLoadout.empty,
              avatarCosmetics: avatar.cosmeticLoadout,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: LightcorePalette.mist,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 8),
                      Text(
                        'YOU',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: LightcorePalette.solar,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${player.levelLabel} • ${player.performanceLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LightcorePalette.mist.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'TS ${_formatMetricCount(player.towerStrength)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
