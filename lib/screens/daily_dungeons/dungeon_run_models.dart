part of '../daily_dungeons_screen.dart';

class _DungeonRunResult {
  const _DungeonRunResult({required this.cleared});

  final bool cleared;
}

class _DungeonRaid {
  const _DungeonRaid({
    required this.id,
    required this.damagePerSecond,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.maxHealth,
    required this.remainingHealth,
    required this.affinity,
    required this.laneIndex,
    required this.chainTier,
    required this.surgeMultiplier,
    this.apex = false,
  });

  final String id;
  final double damagePerSecond;
  final double totalSeconds;
  final double remainingSeconds;
  final double maxHealth;
  final double remainingHealth;
  final PrototypeAffinity affinity;
  final int laneIndex;
  final int chainTier;
  final double surgeMultiplier;
  final bool apex;

  double get progress => totalSeconds <= 0
      ? 1
      : ((totalSeconds - remainingSeconds) / totalSeconds)
            .clamp(0.0, 1.0)
            .toDouble();

  double get healthFraction => maxHealth <= 0
      ? 0
      : (remainingHealth / maxHealth).clamp(0.0, 1.0).toDouble();

  _DungeonRaid copyWith({double? remainingSeconds, double? remainingHealth}) {
    return _DungeonRaid(
      id: id,
      damagePerSecond: damagePerSecond,
      totalSeconds: totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      maxHealth: maxHealth,
      remainingHealth: remainingHealth ?? this.remainingHealth,
      affinity: affinity,
      laneIndex: laneIndex,
      chainTier: chainTier,
      surgeMultiplier: surgeMultiplier,
      apex: apex,
    );
  }
}

enum _DailyDungeonBattleRoute { threatDirector, prismRift }

class _DailyDungeonBattleRunScreen extends StatefulWidget {
  const _DailyDungeonBattleRunScreen({
    required this.route,
    required this.controller,
    required this.towerLevel,
    required this.anomalyCards,
    required this.apexCard,
    required this.runSeed,
  });

  final _DailyDungeonBattleRoute route;
  final LightcoreController controller;
  final int towerLevel;
  final List<EnemyCardState> anomalyCards;
  final EnemyCardState? apexCard;
  final int runSeed;

  @override
  State<_DailyDungeonBattleRunScreen> createState() =>
      _DailyDungeonBattleRunScreenState();
}

class _DailyDungeonBattleRunScreenState
    extends State<_DailyDungeonBattleRunScreen> {
  static const Duration _timeLimit = Duration(seconds: 45);
  static const Duration _tickRate = Duration(milliseconds: 100);

  late final LightcoreDailyDungeonTowerProfile _towerProfile;
  late final LightcoreController _battleController;
  late final int _startingKills;
  late final int _targetKills;
  Timer? _timer;
  double _remainingSeconds = _timeLimit.inSeconds.toDouble();
  bool _running = true;
  bool _victory = false;
  bool _expired = false;
  bool _resultHandled = false;

  @override
  void initState() {
    super.initState();
    _towerProfile = widget.controller.dailyDungeonTowerProfileForLevel(
      widget.towerLevel,
    );
    _battleController = _createBattleController();
    switch (widget.route) {
      case _DailyDungeonBattleRoute.threatDirector:
        _battleController.configureThreatDirectorDungeonBattle(
          towerLevel: widget.towerLevel,
          enemyDraft: widget.anomalyCards,
          bossDraft: widget.apexCard,
        );
        break;
      case _DailyDungeonBattleRoute.prismRift:
        _battleController.configurePrismRiftDungeonBattle(
          towerLevel: widget.towerLevel,
          enemyDraft: widget.anomalyCards,
        );
        break;
    }
    _startingKills = _battleController.kills;
    _targetKills = _battleKillTarget();
    _timer = Timer.periodic(_tickRate, (_) => _advanceRun());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _battleController.dispose();
    super.dispose();
  }

  LightcoreController _createBattleController() {
    final seed = widget.runSeed + (widget.route.index * 1009);
    return LightcoreController(
      packRandom: math.Random(seed + 1),
      traitRandom: math.Random(seed + 2),
      managerRandom: math.Random(seed + 3),
      spawnRandom: math.Random(seed + 4),
      guideProfile: widget.controller.guideProfile,
      playerId:
          '${widget.controller.playerId}-DUNGEON-${widget.route.name.toUpperCase()}',
      screenName: widget.controller.screenName,
      graphicsQuality: widget.controller.graphicsQuality,
    );
  }

  int _battleKillTarget() {
    final anomalyPressure = math.max(1, widget.anomalyCards.length) * 2;
    final apexPressure = widget.apexCard == null ? 0 : 4;
    final routePressure = widget.route == _DailyDungeonBattleRoute.prismRift
        ? 3
        : 0;
    return (7 +
            widget.towerLevel +
            anomalyPressure +
            apexPressure +
            routePressure)
        .clamp(8, 42)
        .toInt();
  }

  String get _title => switch (widget.route) {
    _DailyDungeonBattleRoute.threatDirector =>
      'Threat Director Lv ${widget.towerLevel}',
    _DailyDungeonBattleRoute.prismRift => 'Prism Rift Lv ${widget.towerLevel}',
  };

  Color get _tint => switch (widget.route) {
    _DailyDungeonBattleRoute.threatDirector => LightcorePalette.warning,
    _DailyDungeonBattleRoute.prismRift => LightcorePalette.violet,
  };

  IconData get _icon => switch (widget.route) {
    _DailyDungeonBattleRoute.threatDirector => Icons.account_tree_rounded,
    _DailyDungeonBattleRoute.prismRift => Icons.terrain_rounded,
  };

  int get _runKills => math.max(0, _battleController.kills - _startingKills);

  double get _timeProgress =>
      (_remainingSeconds / _timeLimit.inSeconds).clamp(0.0, 1.0).toDouble();

  double get _coreIntegrity =>
      (_battleController.coreState.coreStability / 100).clamp(0.0, 1.0);

  void _advanceRun() {
    if (!_running || !mounted) {
      return;
    }
    final nextRemaining = math.max(
      0.0,
      _remainingSeconds - (_tickRate.inMilliseconds / 1000),
    );
    final cleared = _runKills >= _targetKills;
    final collapsed = _battleController.coreState.coreStability <= 0.5;
    final expired = !cleared && nextRemaining <= 0;
    setState(() {
      _remainingSeconds = nextRemaining;
    });
    if (cleared || collapsed || expired) {
      _finishRun(cleared: cleared);
    }
  }

  void _finishRun({required bool cleared}) {
    if (!_running || !mounted) {
      return;
    }
    _timer?.cancel();
    setState(() {
      _running = false;
      _victory = cleared;
      _expired = !cleared;
    });
    _handleRunEnded(cleared: cleared);
  }

  void _exitRun() {
    _timer?.cancel();
    Navigator.of(context).pop(_DungeonRunResult(cleared: _victory));
  }

  void _handleRunEnded({required bool cleared}) {
    if (_resultHandled || !mounted) {
      return;
    }
    _resultHandled = true;
    LightcoreDailyDungeonReward? reward;
    if (cleared) {
      reward = widget.controller.clearDailyDungeonTowerLevel(
        widget.towerLevel,
        showBanner: false,
      );
    }
    final nextLevel = widget.controller.dailyDungeonHighestUnlockedTowerLevel;
    final clearVerb = widget.route == _DailyDungeonBattleRoute.prismRift
        ? 'stabilized'
        : 'cleared';
    final failVerb = widget.route == _DailyDungeonBattleRoute.prismRift
        ? 'collapsed'
        : 'expired';
    final clearMessage = reward != null && reward.hasRewards
        ? '$_title $clearVerb: ${reward.label}. Lv $nextLevel unlocked.'
        : '$_title $clearVerb. Lv $nextLevel is ready.';
    widget.controller.pushNotification(
      cleared
          ? clearMessage
          : '$_title $failVerb. Upgrade the tower ladder or change the anomaly draft.',
      duration: 3.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightcorePalette.night,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 720 || constraints.maxHeight < 720;
            final inset = compact ? 8.0 : 12.0;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    LightcorePalette.night,
                    LightcorePalette.abyss,
                    Color.lerp(LightcorePalette.abyss, _tint, 0.18)!,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: BattleScreen(
                      controller: _battleController,
                      isActive: _running,
                      showQuestPanel: false,
                      showBattleHud: false,
                    ),
                  ),
                  Positioned(
                    top: inset,
                    left: compact ? 10 : 16,
                    right: compact ? 10 : 16,
                    child: _DailyDungeonBattleTopBar(
                      title: _title,
                      icon: _icon,
                      tint: _tint,
                      remainingSeconds: _remainingSeconds,
                      timeProgress: _timeProgress,
                      coreIntegrity: _coreIntegrity,
                      onExit: _exitRun,
                    ),
                  ),
                  Positioned(
                    left: compact ? 10 : 16,
                    right: compact ? 10 : 16,
                    bottom: inset,
                    child: _DailyDungeonBattleStatusDock(
                      tint: _tint,
                      compact: compact,
                      towerProfile: _towerProfile,
                      anomalyCards: widget.anomalyCards,
                      apexCard: widget.apexCard,
                      runKills: _runKills,
                      targetKills: _targetKills,
                      coreIntegrity: _coreIntegrity,
                      running: _running,
                    ),
                  ),
                  if (!_running)
                    Positioned.fill(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: _DungeonResultPanel(
                            victory: _victory,
                            towerLevel: widget.towerLevel,
                            successTitle:
                                widget.route ==
                                    _DailyDungeonBattleRoute.prismRift
                                ? 'Rift Stabilized'
                                : null,
                            failureTitle: _expired ? 'Run Expired' : null,
                            successMessage:
                                '$_title cleared through the battle field. The next level is ready from the dungeon menu.',
                            failureMessage:
                                '$_title held. Upgrade anomalies or change the battle loadout before the next run.',
                            onExit: _exitRun,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DailyDungeonBattleTopBar extends StatelessWidget {
  const _DailyDungeonBattleTopBar({
    required this.title,
    required this.icon,
    required this.tint,
    required this.remainingSeconds,
    required this.timeProgress,
    required this.coreIntegrity,
    required this.onExit,
  });

  final String title;
  final IconData icon;
  final Color tint;
  final double remainingSeconds;
  final double timeProgress;
  final double coreIntegrity;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AuroraPanel(
      tint: tint,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          _IconBadge(icon: icon, tint: tint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${remainingSeconds.ceil()}s',
                      style: textTheme.titleMedium?.copyWith(
                        color: LightcorePalette.aether,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: MeterBar(
                        value: timeProgress,
                        color: LightcorePalette.aether,
                        height: 8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MeterBar(
                        value: coreIntegrity,
                        color: tint,
                        height: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Back to dungeons',
            child: IconButton.filledTonal(
              onPressed: onExit,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyDungeonBattleStatusDock extends StatelessWidget {
  const _DailyDungeonBattleStatusDock({
    required this.tint,
    required this.compact,
    required this.towerProfile,
    required this.anomalyCards,
    required this.apexCard,
    required this.runKills,
    required this.targetKills,
    required this.coreIntegrity,
    required this.running,
  });

  final Color tint;
  final bool compact;
  final LightcoreDailyDungeonTowerProfile towerProfile;
  final List<EnemyCardState> anomalyCards;
  final EnemyCardState? apexCard;
  final int runKills;
  final int targetKills;
  final double coreIntegrity;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final shownCards = anomalyCards.take(3).toList(growable: false);
    return AuroraPanel(
      tint: tint,
      radius: 20,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 10,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _InfoChip(
              icon: running
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              label: running ? 'Ready' : 'Done',
              tint: running
                  ? LightcorePalette.success
                  : LightcorePalette.stroke,
            ),
            const SizedBox(width: 8),
            _InfoChip(
              icon: towerProjectileIcon(towerProfile.projectileType),
              label:
                  '${towerProfile.affinity.shortLabel} ${towerProfile.projectileType.label}',
              tint: towerProfile.affinity.color,
            ),
            const SizedBox(width: 8),
            _InfoChip(
              icon: Icons.gps_fixed_rounded,
              label: '$runKills/$targetKills clears',
              tint: LightcorePalette.aether,
            ),
            const SizedBox(width: 8),
            _InfoChip(
              icon: Icons.health_and_safety_rounded,
              label: '${(coreIntegrity * 100).round()}% core',
              tint: tint,
            ),
            for (final card in shownCards) ...[
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.blur_on_rounded,
                label: card.config.affinity.shortLabel,
                tint: card.config.affinity.color,
              ),
            ],
            const SizedBox(width: 8),
            _InfoChip(
              icon: Icons.shield_moon_rounded,
              label: apexCard == null ? 'No apex' : 'Apex',
              tint: apexCard == null
                  ? LightcorePalette.stroke
                  : LightcorePalette.solar,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreatDirectorDungeonRunScreen extends StatefulWidget {
  const _ThreatDirectorDungeonRunScreen({
    required this.controller,
    required this.towerLevel,
    required this.anomalyCards,
    required this.apexCard,
  });

  final LightcoreController controller;
  final int towerLevel;
  final List<EnemyCardState> anomalyCards;
  final EnemyCardState? apexCard;

  @override
  State<_ThreatDirectorDungeonRunScreen> createState() =>
      _ThreatDirectorDungeonRunScreenState();
}

class _ThreatDirectorDungeonRunScreenState
    extends State<_ThreatDirectorDungeonRunScreen> {
  static const Duration _timeLimit = Duration(seconds: 45);
  late final LightcoreDailyDungeonTowerProfile _towerProfile;
  late final ValueNotifier<_DungeonRunSnapshot> _snapshotNotifier;
  late final _ThreatDirectorDungeonGame _game;
  bool _resultHandled = false;

  @override
  void initState() {
    super.initState();
    _towerProfile = widget.controller.dailyDungeonBattleTowerProfileForLevel(
      widget.towerLevel,
    );
    _snapshotNotifier = ValueNotifier<_DungeonRunSnapshot>(
      _DungeonRunSnapshot.initial(
        towerMaxHealth: _towerProfile.maxHealth,
        remainingSeconds: _timeLimit.inSeconds.toDouble(),
      ),
    );
    _game = _ThreatDirectorDungeonGame(
      controller: widget.controller,
      towerProfile: _towerProfile,
      timeLimit: _timeLimit,
      anomalyCards: widget.anomalyCards,
      apexCard: widget.apexCard,
      snapshotNotifier: _snapshotNotifier,
      onRunEnded: _handleRunEnded,
    );
  }

  @override
  void dispose() {
    _game.pauseEngine();
    _snapshotNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightcorePalette.night,
      body: ValueListenableBuilder<_DungeonRunSnapshot>(
        valueListenable: _snapshotNotifier,
        builder: (context, snapshot, _) {
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxWidth < 720 || constraints.maxHeight < 720;
                return DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        LightcorePalette.night,
                        LightcorePalette.abyss,
                        Color(0xFF152D38),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GameWidget<_ThreatDirectorDungeonGame>(
                          game: _game,
                        ),
                      ),
                      Positioned(
                        top: compact ? 8 : 12,
                        left: compact ? 10 : 16,
                        right: compact ? 10 : 16,
                        child: _DungeonRunTopBar(
                          towerProfile: _towerProfile,
                          towerLevel: widget.towerLevel,
                          remainingSeconds: snapshot.remainingSeconds,
                          timeProgress: snapshot.timeProgress,
                          towerHealth: snapshot.towerHealth,
                          towerMaxHealth: snapshot.towerMaxHealth,
                          towerIntegrity: snapshot.towerIntegrity,
                          launchChain: snapshot.launchChain,
                          launchWindowRemaining: snapshot.launchWindowRemaining,
                          onExit: _exitRun,
                        ),
                      ),
                      Positioned(
                        left: compact ? 10 : 16,
                        right: compact ? 10 : 16,
                        bottom: compact ? 8 : 12,
                        child: _DungeonLaunchDock(
                          controller: widget.controller,
                          anomalyCards: widget.anomalyCards,
                          apexCard: widget.apexCard,
                          cooldowns: snapshot.cooldowns,
                          launchChain: snapshot.launchChain,
                          launchWindowRemaining: snapshot.launchWindowRemaining,
                          running: snapshot.running,
                          compact: compact,
                          onLaunch: _launchCard,
                        ),
                      ),
                      if (!snapshot.running)
                        Positioned.fill(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: _DungeonResultPanel(
                                victory: snapshot.victory,
                                towerLevel: widget.towerLevel,
                                onExit: _exitRun,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _launchCard(EnemyCardState card, {required bool apex}) {
    _game.launchCard(card, apex: apex);
  }

  void _exitRun() {
    _game.pauseEngine();
    Navigator.of(
      context,
    ).pop(_DungeonRunResult(cleared: _snapshotNotifier.value.victory));
  }

  void _handleRunEnded({required bool cleared}) {
    if (_resultHandled || !mounted) {
      return;
    }
    _resultHandled = true;
    LightcoreDailyDungeonReward? reward;
    if (cleared) {
      reward = widget.controller.clearDailyDungeonTowerLevel(
        widget.towerLevel,
        showBanner: false,
      );
    }
    final nextLevel = widget.controller.dailyDungeonHighestUnlockedTowerLevel;
    final clearMessage = reward != null && reward.hasRewards
        ? 'Daily Tower Lv ${widget.towerLevel} cleared: ${reward.label}. Lv $nextLevel unlocked.'
        : 'Daily Tower Lv ${widget.towerLevel} cleared. Lv $nextLevel is ready.';
    widget.controller.pushNotification(
      cleared
          ? clearMessage
          : 'Daily Tower Lv ${widget.towerLevel} expired. Upgrade or change your dungeon loadout.',
      duration: 3.2,
    );
  }
}

class _DungeonRunSnapshot {
  const _DungeonRunSnapshot({
    required this.remainingSeconds,
    required this.towerHealth,
    required this.towerMaxHealth,
    required this.towerCharge,
    required this.launchChain,
    required this.launchWindowRemaining,
    required this.cooldowns,
    required this.running,
    required this.victory,
    required this.expired,
  });

  factory _DungeonRunSnapshot.initial({
    required double towerMaxHealth,
    required double remainingSeconds,
  }) {
    return _DungeonRunSnapshot(
      remainingSeconds: remainingSeconds,
      towerHealth: towerMaxHealth,
      towerMaxHealth: towerMaxHealth,
      towerCharge: 0,
      launchChain: 0,
      launchWindowRemaining: 0,
      cooldowns: const <String, double>{},
      running: true,
      victory: false,
      expired: false,
    );
  }

  final double remainingSeconds;
  final double towerHealth;
  final double towerMaxHealth;
  final double towerCharge;
  final int launchChain;
  final double launchWindowRemaining;
  final Map<String, double> cooldowns;
  final bool running;
  final bool victory;
  final bool expired;

  double get towerIntegrity => towerMaxHealth <= 0
      ? 0
      : (towerHealth / towerMaxHealth).clamp(0.0, 1.0).toDouble();

  double get timeProgress => remainingSeconds <= 0
      ? 0
      : (remainingSeconds /
                _ThreatDirectorDungeonRunScreenState._timeLimit.inSeconds)
            .clamp(0.0, 1.0)
            .toDouble();
}
