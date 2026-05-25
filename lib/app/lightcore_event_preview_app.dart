// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/enemy_configs.dart';
import '../data/threat_region_configs.dart';
import '../models/lightcore_tournament.dart';
import '../models/lightcore_types.dart';
import '../screens/daily_dungeons_screen.dart';
import '../screens/tournament_screen.dart';
import '../services/lightcore_firebase_backend.dart';
import '../services/lightcore_firebase_runtime_config.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../theme/lightcore_theme.dart';
import '../widgets/aurora_panel.dart';

enum LightcoreDevEventPreviewSurface { dungeons, tournaments }

class LightcoreEventPreviewApp extends StatefulWidget {
  const LightcoreEventPreviewApp({
    super.key,
    required this.initialSurface,
    this.initialDungeonRoute,
    this.initialTournamentMode,
    this.initialTowerOption,
  });

  final LightcoreDevEventPreviewSurface initialSurface;
  final LightcoreDungeonPreviewRoute? initialDungeonRoute;
  final LightcoreTournamentModeId? initialTournamentMode;
  final LightcorePreviewTowerOption? initialTowerOption;

  @override
  State<LightcoreEventPreviewApp> createState() =>
      _LightcoreEventPreviewAppState();
}

class _LightcoreEventPreviewAppState extends State<LightcoreEventPreviewApp> {
  late LightcoreDevEventPreviewSurface _surface;
  late LightcoreDungeonPreviewRoute _dungeonRoute;
  late LightcoreTournamentModeId _tournamentMode;
  late LightcorePreviewTowerOption _towerOption;
  late LightcoreController _controller;
  late _PreviewTournamentBackend _backend;
  var _screenKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _surface = widget.initialSurface;
    _dungeonRoute =
        widget.initialDungeonRoute ??
        LightcoreDungeonPreviewRoute.threatDirector;
    _tournamentMode =
        widget.initialTournamentMode ?? LightcoreTournamentModeId.enemyBlitz;
    _towerOption =
        widget.initialTowerOption ?? LightcorePreviewTowerOption.prism;
    _backend = _PreviewTournamentBackend();
    _controller = _createPreviewController(_towerOption);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reseedController(LightcorePreviewTowerOption option) {
    final next = _createPreviewController(option);
    setState(() {
      _towerOption = option;
      _controller.dispose();
      _controller = next;
      _backend = _PreviewTournamentBackend();
      _screenKey = UniqueKey();
    });
  }

  void _selectSurface(LightcoreDevEventPreviewSurface surface) {
    setState(() {
      _surface = surface;
      _screenKey = UniqueKey();
    });
  }

  void _selectDungeonRoute(LightcoreDungeonPreviewRoute route) {
    setState(() {
      _dungeonRoute = route;
      _screenKey = UniqueKey();
    });
  }

  void _selectTournamentMode(LightcoreTournamentModeId mode) {
    setState(() {
      _tournamentMode = mode;
      _screenKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LumiHex Dev Event Preview',
      theme: buildLightcoreTheme(),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _PreviewControlBar(
                surface: _surface,
                dungeonRoute: _dungeonRoute,
                tournamentMode: _tournamentMode,
                towerOption: _towerOption,
                onSurfaceChanged: _selectSurface,
                onDungeonRouteChanged: _selectDungeonRoute,
                onTournamentModeChanged: _selectTournamentMode,
                onTowerOptionChanged: _reseedController,
              ),
              Expanded(
                child: _surface == LightcoreDevEventPreviewSurface.dungeons
                    ? DailyDungeonsScreen(
                        key: _screenKey,
                        controller: _controller,
                        isActive: true,
                        initialPreviewRoute: _dungeonRoute,
                        devPreviewMode: true,
                      )
                    : TournamentScreen(
                        key: _screenKey,
                        controller: _controller,
                        backend: _backend,
                        initialPreviewMode: _tournamentMode,
                        devPreviewMode: true,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewControlBar extends StatelessWidget {
  const _PreviewControlBar({
    required this.surface,
    required this.dungeonRoute,
    required this.tournamentMode,
    required this.towerOption,
    required this.onSurfaceChanged,
    required this.onDungeonRouteChanged,
    required this.onTournamentModeChanged,
    required this.onTowerOptionChanged,
  });

  final LightcoreDevEventPreviewSurface surface;
  final LightcoreDungeonPreviewRoute dungeonRoute;
  final LightcoreTournamentModeId tournamentMode;
  final LightcorePreviewTowerOption towerOption;
  final ValueChanged<LightcoreDevEventPreviewSurface> onSurfaceChanged;
  final ValueChanged<LightcoreDungeonPreviewRoute> onDungeonRouteChanged;
  final ValueChanged<LightcoreTournamentModeId> onTournamentModeChanged;
  final ValueChanged<LightcorePreviewTowerOption> onTowerOptionChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: AuroraPanel(
        padding: const EdgeInsets.all(12),
        tint: LightcorePalette.quest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.developer_mode_rounded,
                  color: LightcorePalette.quest,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dev event preview only. URL-driven test surface; do not include this in production release copy or navigation.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<LightcoreDevEventPreviewSurface>(
                  segments: const [
                    ButtonSegment(
                      value: LightcoreDevEventPreviewSurface.dungeons,
                      icon: Icon(Icons.explore_rounded),
                      label: Text('Dungeons'),
                    ),
                    ButtonSegment(
                      value: LightcoreDevEventPreviewSurface.tournaments,
                      icon: Icon(Icons.emoji_events_rounded),
                      label: Text('Tournaments'),
                    ),
                  ],
                  selected: {surface},
                  onSelectionChanged: (value) => onSurfaceChanged(value.first),
                ),
                if (surface == LightcoreDevEventPreviewSurface.dungeons)
                  SegmentedButton<LightcoreDungeonPreviewRoute>(
                    segments: const [
                      ButtonSegment(
                        value: LightcoreDungeonPreviewRoute.hub,
                        label: Text('Hub'),
                      ),
                      ButtonSegment(
                        value: LightcoreDungeonPreviewRoute.threatDirector,
                        label: Text('Threat Director'),
                      ),
                      ButtonSegment(
                        value: LightcoreDungeonPreviewRoute.prismRift,
                        label: Text('Prism Rift'),
                      ),
                    ],
                    selected: {dungeonRoute},
                    onSelectionChanged: (value) =>
                        onDungeonRouteChanged(value.first),
                  )
                else
                  SegmentedButton<LightcoreTournamentModeId>(
                    segments: [
                      for (final mode in LightcoreTournamentModeId.values)
                        ButtonSegment(value: mode, label: Text(mode.label)),
                    ],
                    selected: {tournamentMode},
                    onSelectionChanged: (value) =>
                        onTournamentModeChanged(value.first),
                  ),
                SegmentedButton<LightcorePreviewTowerOption>(
                  segments: [
                    for (final option in LightcorePreviewTowerOption.values)
                      ButtonSegment(
                        value: option,
                        icon: Icon(option.icon),
                        label: Text(option.label),
                      ),
                  ],
                  selected: {towerOption},
                  onSelectionChanged: (value) =>
                      onTowerOptionChanged(value.first),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum LightcorePreviewTowerOption {
  starter,
  prism,
  nexus;

  String get label => switch (this) {
    LightcorePreviewTowerOption.starter => 'Starter Tower',
    LightcorePreviewTowerOption.prism => 'Prism Tower',
    LightcorePreviewTowerOption.nexus => 'Nexus Tower',
  };

  IconData get icon => switch (this) {
    LightcorePreviewTowerOption.starter => Icons.filter_1_rounded,
    LightcorePreviewTowerOption.prism => Icons.filter_2_rounded,
    LightcorePreviewTowerOption.nexus => Icons.filter_3_rounded,
  };

  int get targetLayer => switch (this) {
    LightcorePreviewTowerOption.starter => 1,
    LightcorePreviewTowerOption.prism => 2,
    LightcorePreviewTowerOption.nexus => 3,
  };

  int get dungeonTargetLevel => switch (this) {
    LightcorePreviewTowerOption.starter => 1,
    LightcorePreviewTowerOption.prism => 4,
    LightcorePreviewTowerOption.nexus => 7,
  };
}

LightcoreController _createPreviewController(
  LightcorePreviewTowerOption option,
) {
  final controller = LightcoreController(
    packRandom: Random(7101 + option.index),
    traitRandom: Random(7201 + option.index),
    managerRandom: Random(7301 + option.index),
    spawnRandom: Random(7401 + option.index),
    playerId: 'LUMI-DEVP-000${option.index + 1}',
    screenName: 'Dev Preview',
  );
  controller.debugSeedProgressionLayer(option.targetLayer);
  controller.setScreenName('Dev Preview');
  controller.grantRewardedResources(
    lumensGranted: 5000000,
    fluxGranted: 50000,
    enemyTicketsGranted: 40,
    bossTicketsGranted: 12,
    killsGranted: 5000,
    experienceGranted: LightcoreController.experienceForOverallLevel(
      LightcoreController.tournamentUnlockLevel + 8,
    ),
    sourceLabel: 'Dev preview seed',
  );
  for (var index = 0; index < LightcoreController.slotCount; index += 1) {
    final slot = controller.slots[index];
    if (slot.config == null && controller.towerConfigs.isNotEmpty) {
      controller.buildTowerAt(
        index,
        controller.towerConfigs[index % controller.towerConfigs.length],
      );
    }
  }
  for (final card in EnemyLibrary.all.take(10)) {
    controller.debugSetEnemyCardLevel(
      card.id,
      level: min(4 + option.index, card.rarity.levelCap),
      copies: 3,
    );
  }
  for (final boss in BossEnemyLibrary.all.take(4)) {
    controller.debugSetEnemyCardLevel(
      boss.id,
      level: 2 + option.index,
      copies: 2,
      boss: true,
    );
    controller.debugGrantApexCore(boss.id);
    controller.debugGrantBossTraitForBoss(boss.id);
  }
  final starter = ThreatRegionLibrary.all.first;
  controller.debugRevealThreatRegion(
    starter.id,
    stabilizedLevel: starter.stabilizationLayers,
  );
  controller.forgeEnemyManagerBatch(3);
  final firstThreatDirector = controller.enemyManagers.firstOrNull;
  if (firstThreatDirector != null) {
    controller.assignThreatDirectorToRegion(
      regionId: starter.id,
      managerId: firstThreatDirector.instanceId,
    );
  }
  controller.debugValidateThreatRegionFarm(
    starter.id,
    swarmSize: 12 + (option.index * 6),
    stabilityPercent: 100,
  );
  final anomalyIds = EnemyLibrary.all.take(3).map((card) => card.id).toList();
  controller.setActiveEnemySuite(
    apexCoreBossId: BossEnemyLibrary.all.first.id,
    bossTraitIds: [
      'trait_${BossEnemyLibrary.all.first.id}',
      'trait_${BossEnemyLibrary.all[1].id}',
    ],
    anomalyCardIds: anomalyIds,
  );
  for (
    var level = LightcoreController.dailyDungeonStartingTowerLevel;
    level < option.dungeonTargetLevel;
    level += 1
  ) {
    controller.clearDailyDungeonTowerLevel(
      level,
      showBanner: false,
      grantExperience: false,
    );
  }
  return controller;
}

class _PreviewTournamentBackend extends FirebaseLightcoreBackend {
  _PreviewTournamentBackend()
    : super(runtimeConfig: lightcoreFirebaseRuntimeConfig);

  late LightcoreTournamentOverview _overview = _buildOverview();

  @override
  Future<LightcoreTournamentOverview> fetchTournamentOverview() async {
    return _overview;
  }

  @override
  Future<LightcoreTournamentOverview> joinTournamentQueue({
    required LightcoreTournamentModeId mode,
    required LightcoreTournamentPlayerSnapshot snapshot,
  }) async {
    _overview = _replaceMode(
      mode,
      (state) => _modeState(
        mode,
        joined: true,
        playerBestScore: state.playerBestScore,
      ),
    );
    return _overview;
  }

  @override
  Future<LightcoreTournamentOverview> submitTournamentRun({
    required LightcoreTournamentModeId mode,
    required int score,
    required LightcoreTournamentPlayerSnapshot snapshot,
  }) async {
    _overview = _replaceMode(
      mode,
      (state) => _modeState(
        mode,
        joined: true,
        playerBestScore: max(score, state.playerBestScore),
        playerRank: 3,
      ),
    );
    return _overview;
  }

  @override
  Future<LightcoreTournamentClaimResult> claimTournamentReward({
    required LightcoreTournamentModeId mode,
  }) async {
    return LightcoreTournamentClaimResult(
      reward: _rewardFor(mode),
      overview: _overview,
    );
  }

  LightcoreTournamentOverview _replaceMode(
    LightcoreTournamentModeId mode,
    LightcoreTournamentModeState Function(LightcoreTournamentModeState state)
    update,
  ) {
    return LightcoreTournamentOverview(
      seasonKey: _overview.seasonKey,
      seasonLabel: _overview.seasonLabel,
      startsAt: _overview.startsAt,
      endsAt: _overview.endsAt,
      globalTournamentRating: _overview.globalTournamentRating,
      activeExperienceMultiplier: _overview.activeExperienceMultiplier,
      activeExperienceBoostEndsAt: _overview.activeExperienceBoostEndsAt,
      online: _overview.online,
      statusMessage: _overview.statusMessage,
      modes: [
        for (final state in _overview.modes)
          state.mode == mode ? update(state) : state,
      ],
    );
  }

  LightcoreTournamentOverview _buildOverview() {
    final now = DateTime.now();
    return LightcoreTournamentOverview(
      seasonKey: 'dev-preview',
      seasonLabel: 'Dev Preview Events',
      startsAt: now.subtract(const Duration(hours: 1)),
      endsAt: now.add(const Duration(days: 7)),
      globalTournamentRating: 1230,
      activeExperienceMultiplier: 1.0,
      online: true,
      statusMessage: 'Local dev preview backend.',
      modes: [
        for (final mode in LightcoreTournamentModeId.values) _modeState(mode),
      ],
    );
  }

  LightcoreTournamentModeState _modeState(
    LightcoreTournamentModeId mode, {
    bool joined = true,
    int playerBestScore = 0,
    int? playerRank,
  }) {
    final now = DateTime.now();
    return LightcoreTournamentModeState(
      mode: mode,
      statusMessage: 'Dev preview queue is open.',
      mechanicSummary: mode.compressedLoopLabel,
      rewardPreview: _rewardFor(mode),
      startsAt: now.subtract(const Duration(hours: 1)),
      endsAt: now.add(const Duration(days: 7)),
      groupId: 'dev-${mode.wireKey}',
      matchBucketLabel: 'Dev local',
      groupSize: 6,
      capacity: 15,
      playerBestScore: playerBestScore,
      playerRank: playerRank,
      joined: joined,
      isOpen: true,
      seedPowerIndex: switch (mode) {
        LightcoreTournamentModeId.enemyBlitz => 1800,
        LightcoreTournamentModeId.hexGauntlet => 2400,
        LightcoreTournamentModeId.arenaFlow => 5200,
      },
      leaderboard: _leaderboardFor(mode),
    );
  }

  LightcoreTournamentRewardPackage _rewardFor(LightcoreTournamentModeId mode) {
    return LightcoreTournamentRewardPackage(
      flux: 80 + (mode.index * 35),
      tickets: 4 + mode.index,
      experienceMultiplier: 1.15 + (mode.index * 0.05),
      experienceBuffHours: 4,
      bonusTowerManagers: mode == LightcoreTournamentModeId.hexGauntlet ? 1 : 0,
      bonusTowerManagerRarity: ManagerRarity.rare,
    );
  }

  List<LightcoreTournamentLeaderboardEntry> _leaderboardFor(
    LightcoreTournamentModeId mode,
  ) {
    return [
      LightcoreTournamentLeaderboardEntry(
        displayName: 'Dev Rival Alpha',
        score: 4200 + (mode.index * 700),
        globalRating: 1320,
        snapshot: _snapshotFor(mode, 5200 + (mode.index * 800)),
      ),
      LightcoreTournamentLeaderboardEntry(
        displayName: 'Dev Rival Beta',
        score: 3100 + (mode.index * 500),
        globalRating: 1180,
        snapshot: _snapshotFor(mode, 3900 + (mode.index * 650)),
      ),
      const LightcoreTournamentLeaderboardEntry(
        displayName: 'Dev Preview',
        score: 0,
        globalRating: 1230,
        isPlayer: true,
      ),
    ];
  }

  LightcoreTournamentPlayerSnapshot _snapshotFor(
    LightcoreTournamentModeId mode,
    int power,
  ) {
    return LightcoreTournamentPlayerSnapshot(
      overallLevel: 38,
      prestigeLevel: 0,
      activeLayerTier: mode == LightcoreTournamentModeId.arenaFlow ? 2 : 1,
      builtTowerCount: 6,
      coreLevel: 12,
      towerPowerIndex: power,
      towerAffinity: PrototypeAffinity.aether,
      enemyAffinity: PrototypeAffinity.ember,
      enemyCardIds: EnemyLibrary.all.take(3).map((enemy) => enemy.id).toList(),
      enemyCardLevels: {
        for (final enemy in EnemyLibrary.all.take(3)) enemy.id: 3,
      },
      bossEnemyCardId: BossEnemyLibrary.all.first.id,
      bossEnemyLevel: 2,
      enemySuiteApexCoreBossId: BossEnemyLibrary.all.first.id,
      enemySuiteBossTraitIds: [
        'trait_${BossEnemyLibrary.all.first.id}',
        'trait_${BossEnemyLibrary.all[1].id}',
      ],
      enemySuiteAnomalyCardIds: EnemyLibrary.all
          .take(3)
          .map((enemy) => enemy.id)
          .toList(),
      enemySuiteComplete: true,
      fullyStabilizedRegionCount: 1,
    );
  }
}

LightcoreDevEventPreviewSurface eventPreviewSurfaceFromQuery(String? value) {
  return switch (value) {
    'tournament' ||
    'tournaments' => LightcoreDevEventPreviewSurface.tournaments,
    _ => LightcoreDevEventPreviewSurface.dungeons,
  };
}

LightcoreDungeonPreviewRoute dungeonPreviewRouteFromQuery(String? value) {
  return switch (value) {
    'hub' => LightcoreDungeonPreviewRoute.hub,
    'rift' ||
    'prismRift' ||
    'prism-rift' => LightcoreDungeonPreviewRoute.prismRift,
    _ => LightcoreDungeonPreviewRoute.threatDirector,
  };
}

LightcoreTournamentModeId tournamentPreviewModeFromQuery(String? value) {
  return switch (value) {
    'hex' ||
    'hexGauntlet' ||
    'hex-gauntlet' => LightcoreTournamentModeId.hexGauntlet,
    'arena' ||
    'arenaFlow' ||
    'arena-flow' => LightcoreTournamentModeId.arenaFlow,
    _ => LightcoreTournamentModeId.enemyBlitz,
  };
}

LightcorePreviewTowerOption towerPreviewOptionFromQuery(String? value) {
  return switch (value) {
    'starter' || 'root' => LightcorePreviewTowerOption.starter,
    'nexus' || 'layer3' => LightcorePreviewTowerOption.nexus,
    _ => LightcorePreviewTowerOption.prism,
  };
}
