part of '../daily_dungeons_screen.dart';

class _DungeonRunResult {
  const _DungeonRunResult({required this.cleared});

  final bool cleared;
}

enum _DailyDungeonBattleRoute { threatDirector, prismRift }

enum _DungeonRunFailureReason { expired, coreCollapsed }

class _DailyDungeonBattleModeDefinition {
  const _DailyDungeonBattleModeDefinition({
    required this.route,
    required this.label,
    required this.tint,
    required this.icon,
    required this.seedOffset,
    required this.killTargetPressure,
    required this.clearVerb,
    required this.failVerb,
    this.usesManualAim = false,
    this.usesManualEnemySpawns = false,
    this.showsLevelInTitle = true,
    this.successTitle,
  });

  final _DailyDungeonBattleRoute route;
  final String label;
  final Color tint;
  final IconData icon;
  final int seedOffset;
  final int killTargetPressure;
  final String clearVerb;
  final String failVerb;
  final bool usesManualAim;
  final bool usesManualEnemySpawns;
  final bool showsLevelInTitle;
  final String? successTitle;

  String titleForLevel(int towerLevel) =>
      showsLevelInTitle ? '$label Lv $towerLevel' : label;

  void configureBattleController({
    required LightcoreController battleController,
    required LightcoreController sourceController,
    required int towerLevel,
    required List<EnemyCardState> anomalyCards,
    required EnemyCardState? apexCard,
  }) {
    switch (route) {
      case _DailyDungeonBattleRoute.threatDirector:
        battleController.configureThreatDirectorDungeonBattle(
          towerLevel: towerLevel,
          enemyDraft: anomalyCards,
          bossDraft: apexCard,
        );
        break;
      case _DailyDungeonBattleRoute.prismRift:
        battleController.configurePrismRiftDungeonBattleFromHomeTower(
          source: sourceController,
          towerLevel: towerLevel,
          enemyDraft: anomalyCards,
        );
        break;
    }
  }

  int killTarget({
    required int towerLevel,
    required int anomalyCount,
    required bool hasApex,
  }) {
    final anomalyPressure = math.max(1, anomalyCount) * 2;
    final apexPressure = hasApex ? 4 : 0;
    return (7 +
            towerLevel +
            anomalyPressure +
            apexPressure +
            killTargetPressure)
        .clamp(8, 42)
        .toInt();
  }
}

const Map<_DailyDungeonBattleRoute, _DailyDungeonBattleModeDefinition>
_dailyDungeonBattleModes =
    <_DailyDungeonBattleRoute, _DailyDungeonBattleModeDefinition>{
      _DailyDungeonBattleRoute.threatDirector:
          _DailyDungeonBattleModeDefinition(
            route: _DailyDungeonBattleRoute.threatDirector,
            label: 'Threat Director',
            tint: LightcorePalette.warning,
            icon: Icons.account_tree_rounded,
            seedOffset: 0,
            killTargetPressure: 0,
            clearVerb: 'cleared',
            failVerb: 'expired',
            usesManualEnemySpawns: true,
            showsLevelInTitle: false,
          ),
      _DailyDungeonBattleRoute.prismRift: _DailyDungeonBattleModeDefinition(
        route: _DailyDungeonBattleRoute.prismRift,
        label: 'Prism Rift',
        tint: LightcorePalette.violet,
        icon: Icons.terrain_rounded,
        seedOffset: 1009,
        killTargetPressure: 3,
        clearVerb: 'stabilized',
        failVerb: 'collapsed',
        usesManualAim: true,
        successTitle: 'Rift Stabilized',
      ),
    };

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
  static const double _anomalySpawnCooldownSeconds = 1.0;
  static const double _apexSpawnCooldownSeconds = 6.0;

  late final LightcoreDailyDungeonTowerProfile _towerProfile;
  late final LightcoreController _battleController;
  late final int _startingKills;
  late final int _targetKills;
  Timer? _timer;
  final Map<String, double> _manualSpawnCooldowns = <String, double>{};
  final Map<String, double> _pendingTargetTowerDamageByEnemyId =
      <String, double>{};
  late double _targetTowerMaxHealth;
  late double _targetTowerHealth;
  LightcoreDailyDungeonReward? _resultReward;
  _DungeonRunFailureReason? _failureReason;
  int _manualLaunchCount = 0;
  double _remainingSeconds = _timeLimit.inSeconds.toDouble();
  Offset _riftAimDirection = const Offset(0, -1);
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
    _mode.configureBattleController(
      battleController: _battleController,
      sourceController: widget.controller,
      towerLevel: widget.towerLevel,
      anomalyCards: widget.anomalyCards,
      apexCard: widget.apexCard,
    );
    _startingKills = _battleController.kills;
    _targetKills = _battleKillTarget();
    _targetTowerMaxHealth = _towerProfile.maxHealth;
    _targetTowerHealth = _targetTowerMaxHealth;
    _timer = Timer.periodic(_tickRate, (_) => _advanceRun());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _battleController.dispose();
    super.dispose();
  }

  _DailyDungeonBattleModeDefinition get _mode =>
      _dailyDungeonBattleModes[widget.route]!;

  LightcoreController _createBattleController() {
    final seed = widget.runSeed + _mode.seedOffset;
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
      relayHitListener: _handleBattleRelayHit,
    );
  }

  int _battleKillTarget() {
    return _mode.killTarget(
      towerLevel: widget.towerLevel,
      anomalyCount: widget.anomalyCards.length,
      hasApex: widget.apexCard != null,
    );
  }

  String get _title => _mode.titleForLevel(widget.towerLevel);

  Color get _tint => _mode.tint;

  IconData get _icon => _mode.icon;

  int get _runKills => math.max(0, _battleController.kills - _startingKills);

  bool get _isPrismRift => _mode.usesManualAim;

  bool get _usesManualEnemySpawns => _mode.usesManualEnemySpawns;

  bool get _isThreatDirector =>
      widget.route == _DailyDungeonBattleRoute.threatDirector;

  double get _timeProgress =>
      (_remainingSeconds / _timeLimit.inSeconds).clamp(0.0, 1.0).toDouble();

  double get _coreIntegrity =>
      (_battleController.coreState.coreStability / 100).clamp(0.0, 1.0);

  double get _targetTowerIntegrity =>
      (_targetTowerHealth / math.max(1.0, _targetTowerMaxHealth))
          .clamp(0.0, 1.0)
          .toDouble();

  double _raidDamageFor(EnemyCardState card, {required bool boss}) {
    return widget.controller.dailyDungeonRaidTotalDamage(card, apex: boss);
  }

  void _damageTargetTower(double damage) {
    if (!_isThreatDirector || !_running || damage <= 0) {
      return;
    }
    _targetTowerHealth = math.max(0.0, _targetTowerHealth - damage);
  }

  void _handleBattleRelayHit(EnemyState enemy) {
    if (!_isThreatDirector || !_running || !mounted) {
      return;
    }
    final damage = _pendingTargetTowerDamageByEnemyId.remove(enemy.id);
    if (damage == null || damage <= 0) {
      return;
    }
    setState(() => _damageTargetTower(damage));
  }

  void _handlePrismRiftAimChanged(Offset direction) {
    if (!_running || direction.distance <= 0.001) {
      return;
    }
    setState(() => _riftAimDirection = direction / direction.distance);
  }

  void _handlePrismRiftFire() {
    if (!_running) {
      return;
    }
    final fired = _battleController.firePrismRiftAimedShot(
      aimDx: _riftAimDirection.dx,
      aimDy: _riftAimDirection.dy,
    );
    if (fired && mounted) {
      setState(() {});
    }
  }

  String _manualSpawnCooldownKey(EnemyCardState card, {required bool boss}) =>
      '${boss ? 'boss' : 'enemy'}:${card.config.id}';

  double _manualSpawnCooldownFor(EnemyCardState card, {required bool boss}) =>
      _manualSpawnCooldowns[_manualSpawnCooldownKey(card, boss: boss)] ?? 0;

  bool _canSpawnManualAnomaly(EnemyCardState card) {
    return _running &&
        _manualSpawnCooldownFor(card, boss: false) <= 0 &&
        _battleController.canManuallySpawnBattleEnemy(cardId: card.config.id);
  }

  bool _canSpawnManualApex(EnemyCardState card) {
    return _running &&
        _manualSpawnCooldownFor(card, boss: true) <= 0 &&
        _battleController.canManuallySpawnBattleEnemy(
          cardId: card.config.id,
          boss: true,
        );
  }

  void _handleManualAnomalySpawn(EnemyCardState card) {
    if (!_canSpawnManualAnomaly(card)) {
      return;
    }
    final existingEnemyIds = _battleController.enemies
        .map((enemy) => enemy.id)
        .toSet();
    final spawned = _battleController.spawnManualBattleEnemy(
      cardId: card.config.id,
    );
    if (spawned && mounted) {
      _trackTargetTowerDamageForSpawnedEnemy(
        existingEnemyIds,
        _raidDamageFor(card, boss: false),
      );
      setState(() {
        _manualLaunchCount += 1;
        _manualSpawnCooldowns[_manualSpawnCooldownKey(card, boss: false)] =
            _anomalySpawnCooldownSeconds;
      });
    }
  }

  void _handleManualApexSpawn(EnemyCardState card) {
    if (!_canSpawnManualApex(card)) {
      return;
    }
    final existingEnemyIds = _battleController.enemies
        .map((enemy) => enemy.id)
        .toSet();
    final spawned = _battleController.spawnManualBattleEnemy(
      cardId: card.config.id,
      boss: true,
    );
    if (spawned && mounted) {
      _trackTargetTowerDamageForSpawnedEnemy(
        existingEnemyIds,
        _raidDamageFor(card, boss: true),
      );
      setState(() {
        _manualLaunchCount += 1;
        _manualSpawnCooldowns[_manualSpawnCooldownKey(card, boss: true)] =
            _apexSpawnCooldownSeconds;
      });
    }
  }

  void _trackTargetTowerDamageForSpawnedEnemy(
    Set<String> existingEnemyIds,
    double damage,
  ) {
    if (!_isThreatDirector || damage <= 0) {
      return;
    }
    final spawnedEnemies = _battleController.enemies
        .where((enemy) => !existingEnemyIds.contains(enemy.id))
        .toList(growable: false);
    if (spawnedEnemies.isEmpty) {
      return;
    }
    _pendingTargetTowerDamageByEnemyId[spawnedEnemies.last.id] = damage;
  }

  void _prunePendingTargetTowerDamage() {
    if (_pendingTargetTowerDamageByEnemyId.isEmpty) {
      return;
    }
    final liveEnemyIds = _battleController.enemies
        .map((enemy) => enemy.id)
        .toSet();
    _pendingTargetTowerDamageByEnemyId.removeWhere(
      (enemyId, _) => !liveEnemyIds.contains(enemyId),
    );
  }

  void _advanceRun() {
    if (!_running || !mounted) {
      return;
    }
    final tickSeconds = _tickRate.inMilliseconds / 1000;
    final nextRemaining = math.max(0.0, _remainingSeconds - tickSeconds);
    final cleared = _isThreatDirector
        ? _targetTowerHealth <= 0
        : _runKills >= _targetKills;
    final collapsed = _battleController.coreState.coreStability <= 0.5;
    final expired = !cleared && nextRemaining <= 0;
    setState(() {
      _remainingSeconds = nextRemaining;
      if (_manualSpawnCooldowns.isNotEmpty) {
        _manualSpawnCooldowns.updateAll(
          (_, remaining) => math.max(0.0, remaining - tickSeconds),
        );
      }
      _prunePendingTargetTowerDamage();
    });
    if (cleared || collapsed || expired) {
      _finishRun(
        cleared: cleared,
        failureReason: cleared
            ? null
            : collapsed
            ? _DungeonRunFailureReason.coreCollapsed
            : _DungeonRunFailureReason.expired,
      );
    }
  }

  void _finishRun({
    required bool cleared,
    _DungeonRunFailureReason? failureReason,
  }) {
    if (!_running || !mounted) {
      return;
    }
    _timer?.cancel();
    setState(() {
      _running = false;
      _victory = cleared;
      _expired = !cleared;
      _failureReason = failureReason;
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
        grantExperience: !_isThreatDirector,
      );
    }
    _resultReward = reward;
    final rewardMessage = reward != null && reward.hasRewards
        ? ': ${reward.label}.'
        : '.';
    final clearMessage = _isThreatDirector
        ? '$_title target broken$rewardMessage Next target is ready.'
        : '$_title ${_mode.clearVerb}$rewardMessage Lv ${widget.controller.dailyDungeonHighestUnlockedTowerLevel} is ready.';
    widget.controller.pushNotification(
      cleared ? clearMessage : _failureNotificationMessage,
      duration: 3.2,
    );
  }

  String get _failureNotificationMessage {
    if (_failureReason == _DungeonRunFailureReason.coreCollapsed) {
      return '$_title failed: core stability collapsed before the target tower broke.';
    }
    if (_isThreatDirector && _manualLaunchCount < 3) {
      return '$_title held. Launch anomalies more aggressively before the timer expires.';
    }
    return '$_title ${_mode.failVerb}. Upgrade anomalies or change the battle loadout.';
  }

  String? get _resultSuccessTitle {
    if (_isThreatDirector) {
      return 'Tower Broken';
    }
    return _mode.successTitle;
  }

  String? get _resultFailureTitle {
    if (_failureReason == _DungeonRunFailureReason.coreCollapsed) {
      return 'Core Collapsed';
    }
    if (_isThreatDirector) {
      return 'Tower Held';
    }
    return _expired ? 'Run Expired' : null;
  }

  String get _resultSuccessMessage {
    final reward = _resultReward;
    final rewardText = reward != null && reward.hasRewards
        ? ' Reward: ${reward.label}.'
        : '';
    if (_isThreatDirector) {
      return 'Your anomalies broke the target tower through the health bar.$rewardText';
    }
    return '$_title cleared through the battle field. The next level is ready from the dungeon menu.$rewardText';
  }

  String get _resultFailureMessage {
    if (_failureReason == _DungeonRunFailureReason.coreCollapsed) {
      return 'Core Stability collapsed before the target broke. Use lower-pressure anomalies or keep launches spaced out.';
    }
    if (_isThreatDirector && _manualLaunchCount < 3) {
      return 'The target tower held because too few anomalies were launched. Keep the anomaly buttons on cooldown and use stronger cards.';
    }
    if (_isThreatDirector) {
      return 'The target tower held with ${(_targetTowerIntegrity * 100).ceil()}% integrity. Upgrade anomalies, add an Apex, or launch faster.';
    }
    return '$_title held. Upgrade anomalies or change the battle loadout before the next run.';
  }

  List<String> get _resultDetails {
    if (_isThreatDirector) {
      return <String>[
        'Tower ${(_targetTowerIntegrity * 100).round()}%',
        'Launched $_manualLaunchCount',
        '${_remainingSeconds.ceil()}s left',
      ];
    }
    return <String>[
      'Clears $_runKills/$_targetKills',
      'Core ${(_coreIntegrity * 100).round()}%',
      '${_remainingSeconds.ceil()}s left',
    ];
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
                  if (_isPrismRift)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _PrismRiftAimOverlay(
                          direction: _riftAimDirection,
                          tint: _tint,
                          active: _running,
                        ),
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
                      targetIntegrity: _isThreatDirector
                          ? _targetTowerIntegrity
                          : null,
                      onExit: _exitRun,
                    ),
                  ),
                  Positioned(
                    left: compact ? 10 : 16,
                    right: compact ? 10 : 16,
                    bottom: inset,
                    child: _isPrismRift
                        ? _PrismRiftBattleStatusDock(
                            tint: _tint,
                            compact: compact,
                            sourceLayerLabel:
                                widget.controller.homeTowerLayerLabel,
                            coreState: _battleController.coreState,
                            anomalyCards: widget.anomalyCards,
                            runKills: _runKills,
                            targetKills: _targetKills,
                            coreIntegrity: _coreIntegrity,
                            charge: _battleController.prismRiftAimedShotCharge,
                            canFire:
                                _running &&
                                _battleController.canFirePrismRiftAimedShot,
                            running: _running,
                            onAimChanged: _handlePrismRiftAimChanged,
                            onFire: _handlePrismRiftFire,
                          )
                        : _usesManualEnemySpawns
                        ? _ThreatDirectorBattleStatusDock(
                            tint: _tint,
                            compact: compact,
                            towerProfile: _towerProfile,
                            anomalyCards: widget.anomalyCards,
                            apexCard: widget.apexCard,
                            targetTowerHealth: _targetTowerHealth,
                            targetTowerMaxHealth: _targetTowerMaxHealth,
                            manualLaunchCount: _manualLaunchCount,
                            coreIntegrity: _coreIntegrity,
                            running: _running,
                            damageForAnomaly: (card) =>
                                _raidDamageFor(card, boss: false),
                            damageForApex: (card) =>
                                _raidDamageFor(card, boss: true),
                            cooldownForAnomaly: (card) =>
                                _manualSpawnCooldownFor(card, boss: false),
                            cooldownForApex: (card) =>
                                _manualSpawnCooldownFor(card, boss: true),
                            canSpawnAnomaly: _canSpawnManualAnomaly,
                            canSpawnApex: _canSpawnManualApex,
                            onSpawnAnomaly: _handleManualAnomalySpawn,
                            onSpawnApex: _handleManualApexSpawn,
                          )
                        : _DailyDungeonBattleStatusDock(
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
                            successTitle: _resultSuccessTitle,
                            failureTitle: _resultFailureTitle,
                            successMessage: _resultSuccessMessage,
                            failureMessage: _resultFailureMessage,
                            details: _resultDetails,
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
    this.targetIntegrity,
  });

  final String title;
  final IconData icon;
  final Color tint;
  final double remainingSeconds;
  final double timeProgress;
  final double coreIntegrity;
  final VoidCallback onExit;
  final double? targetIntegrity;

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
                    if (targetIntegrity != null) ...[
                      Expanded(
                        child: MeterBar(
                          value: targetIntegrity!,
                          color: LightcorePalette.warning,
                          height: 8,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
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

class _ThreatDirectorBattleStatusDock extends StatelessWidget {
  const _ThreatDirectorBattleStatusDock({
    required this.tint,
    required this.compact,
    required this.towerProfile,
    required this.anomalyCards,
    required this.apexCard,
    required this.targetTowerHealth,
    required this.targetTowerMaxHealth,
    required this.manualLaunchCount,
    required this.coreIntegrity,
    required this.running,
    required this.damageForAnomaly,
    required this.damageForApex,
    required this.cooldownForAnomaly,
    required this.cooldownForApex,
    required this.canSpawnAnomaly,
    required this.canSpawnApex,
    required this.onSpawnAnomaly,
    required this.onSpawnApex,
  });

  final Color tint;
  final bool compact;
  final LightcoreDailyDungeonTowerProfile towerProfile;
  final List<EnemyCardState> anomalyCards;
  final EnemyCardState? apexCard;
  final double targetTowerHealth;
  final double targetTowerMaxHealth;
  final int manualLaunchCount;
  final double coreIntegrity;
  final bool running;
  final double Function(EnemyCardState card) damageForAnomaly;
  final double Function(EnemyCardState card) damageForApex;
  final double Function(EnemyCardState card) cooldownForAnomaly;
  final double Function(EnemyCardState card) cooldownForApex;
  final bool Function(EnemyCardState card) canSpawnAnomaly;
  final bool Function(EnemyCardState card) canSpawnApex;
  final ValueChanged<EnemyCardState> onSpawnAnomaly;
  final ValueChanged<EnemyCardState> onSpawnApex;

  @override
  Widget build(BuildContext context) {
    final cards = anomalyCards.take(3).toList(growable: false);
    final targetIntegrity =
        (targetTowerHealth / math.max(1.0, targetTowerMaxHealth))
            .clamp(0.0, 1.0)
            .toDouble();
    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(
          icon: running
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded,
          label: running ? 'Ready' : 'Done',
          tint: running ? LightcorePalette.success : LightcorePalette.stroke,
        ),
        _InfoChip(
          icon: towerProjectileIcon(towerProfile.projectileType),
          label:
              '${towerProfile.affinity.shortLabel} ${towerProfile.projectileType.label}',
          tint: towerProfile.affinity.color,
        ),
        _InfoChip(
          icon: Icons.account_tree_rounded,
          label:
              '${targetTowerHealth.ceil().clamp(0, targetTowerMaxHealth.ceil())}/${targetTowerMaxHealth.round()} tower',
          tint: LightcorePalette.aether,
        ),
        _InfoChip(
          icon: Icons.health_and_safety_rounded,
          label: '${(coreIntegrity * 100).round()}% core',
          tint: tint,
        ),
        _InfoChip(
          icon: Icons.gps_fixed_rounded,
          label: '$manualLaunchCount launched',
          tint: LightcorePalette.solar,
        ),
      ],
    );
    final towerMeter = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MeterLabelRow(
          label: 'Target Tower',
          value:
              '${targetTowerHealth.ceil().clamp(0, targetTowerMaxHealth.ceil())}/${targetTowerMaxHealth.round()}',
        ),
        const SizedBox(height: 5),
        MeterBar(
          value: targetIntegrity,
          color: LightcorePalette.warning,
          height: 9,
        ),
      ],
    );
    final controls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final card in cards)
          _ManualSpawnButton(
            card: card,
            label: card.config.affinity.shortLabel,
            icon: Icons.play_arrow_rounded,
            tint: card.config.affinity.color,
            damage: damageForAnomaly(card),
            cooldown: cooldownForAnomaly(card),
            enabled: canSpawnAnomaly(card),
            onPressed: onSpawnAnomaly,
          ),
        if (apexCard != null)
          _ManualSpawnButton(
            card: apexCard!,
            label: 'APEX',
            icon: Icons.shield_moon_rounded,
            tint: LightcorePalette.solar,
            damage: damageForApex(apexCard!),
            cooldown: cooldownForApex(apexCard!),
            enabled: canSpawnApex(apexCard!),
            onPressed: onSpawnApex,
          ),
      ],
    );

    return AuroraPanel(
      tint: tint,
      radius: 20,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 10,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 820) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                towerMeter,
                const SizedBox(height: 10),
                controls,
                const SizedBox(height: 10),
                chips,
              ],
            );
          }
          return Row(
            children: [
              SizedBox(width: 210, child: towerMeter),
              const SizedBox(width: 14),
              Expanded(child: chips),
              const SizedBox(width: 14),
              Flexible(child: controls),
            ],
          );
        },
      ),
    );
  }
}

class _ManualSpawnButton extends StatelessWidget {
  const _ManualSpawnButton({
    required this.card,
    required this.label,
    required this.icon,
    required this.tint,
    required this.damage,
    required this.cooldown,
    required this.enabled,
    required this.onPressed,
  });

  final EnemyCardState card;
  final String label;
  final IconData icon;
  final Color tint;
  final double damage;
  final double cooldown;
  final bool enabled;
  final ValueChanged<EnemyCardState> onPressed;

  @override
  Widget build(BuildContext context) {
    final cooldownActive = cooldown > 0;
    final effectiveEnabled = enabled && !cooldownActive;
    final damageLabel = damage >= 1000
        ? '${(damage / 1000).toStringAsFixed(damage >= 10000 ? 0 : 1)}K'
        : damage.round().toString();
    return Tooltip(
      message: 'Launch ${card.config.name}',
      child: SizedBox(
        width: 132,
        height: 64,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: effectiveEnabled
                ? tint.withValues(alpha: 0.92)
                : LightcorePalette.stroke.withValues(alpha: 0.24),
            foregroundColor: effectiveEnabled
                ? LightcorePalette.night
                : LightcorePalette.mist.withValues(alpha: 0.56),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: effectiveEnabled ? () => onPressed(card) : null,
          child: Row(
            children: [
              _DungeonEnemyPortrait(
                card: card,
                size: 44,
                selected: effectiveEnabled,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            cooldownActive ? '${cooldown.ceil()}s' : label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: effectiveEnabled
                                      ? LightcorePalette.night
                                      : LightcorePalette.mist.withValues(
                                          alpha: 0.56,
                                        ),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$damageLabel hit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: effectiveEnabled
                            ? LightcorePalette.night.withValues(alpha: 0.78)
                            : LightcorePalette.mist.withValues(alpha: 0.42),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrismRiftBattleStatusDock extends StatelessWidget {
  const _PrismRiftBattleStatusDock({
    required this.tint,
    required this.compact,
    required this.sourceLayerLabel,
    required this.coreState,
    required this.anomalyCards,
    required this.runKills,
    required this.targetKills,
    required this.coreIntegrity,
    required this.charge,
    required this.canFire,
    required this.running,
    required this.onAimChanged,
    required this.onFire,
  });

  final Color tint;
  final bool compact;
  final String sourceLayerLabel;
  final CoreState coreState;
  final List<EnemyCardState> anomalyCards;
  final int runKills;
  final int targetKills;
  final double coreIntegrity;
  final double charge;
  final bool canFire;
  final bool running;
  final ValueChanged<Offset> onAimChanged;
  final VoidCallback onFire;

  ProjectileType get _projectileType {
    final loadout = coreState.projectileLoadout;
    if (loadout.isEmpty) {
      return coreState.projectileType;
    }
    return loadout[coreState.fireSequence % loadout.length];
  }

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final controls = _PrismRiftBattleAimControls(
            enabled: running,
            canFire: canFire,
            tint: tint,
            compact: compact,
            onAimChanged: onAimChanged,
            onFire: onFire,
          );
          final meters = SizedBox(
            width: compact ? constraints.maxWidth : 220,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MeterLabelRow(
                  label: 'Shot',
                  value: canFire ? 'Ready' : '${(charge * 100).round()}%',
                ),
                const SizedBox(height: 5),
                MeterBar(value: charge, color: tint, height: 9),
              ],
            ),
          );
          final chips = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: running
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                label: running ? 'Aiming' : 'Done',
                tint: running
                    ? LightcorePalette.success
                    : LightcorePalette.stroke,
              ),
              _InfoChip(
                icon: Icons.layers_rounded,
                label: sourceLayerLabel,
                tint: tint,
              ),
              _InfoChip(
                icon: towerProjectileIcon(_projectileType),
                label: _projectileType.label,
                tint: _projectileType.affinity.color,
              ),
              _InfoChip(
                icon: Icons.gps_fixed_rounded,
                label: '$runKills/$targetKills clears',
                tint: LightcorePalette.aether,
              ),
              _InfoChip(
                icon: Icons.health_and_safety_rounded,
                label: '${(coreIntegrity * 100).round()}% core',
                tint: tint,
              ),
              for (final card in shownCards)
                _InfoChip(
                  icon: Icons.blur_on_rounded,
                  label: card.config.affinity.shortLabel,
                  tint: card.config.affinity.color,
                ),
            ],
          );

          if (constraints.maxWidth < 900) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                controls,
                const SizedBox(height: 10),
                chips,
                const SizedBox(height: 10),
                meters,
              ],
            );
          }
          return Row(
            children: [
              controls,
              const SizedBox(width: 14),
              Expanded(child: chips),
              const SizedBox(width: 14),
              meters,
            ],
          );
        },
      ),
    );
  }
}

class _PrismRiftBattleAimControls extends StatelessWidget {
  const _PrismRiftBattleAimControls({
    required this.enabled,
    required this.canFire,
    required this.tint,
    required this.compact,
    required this.onAimChanged,
    required this.onFire,
  });

  final bool enabled;
  final bool canFire;
  final Color tint;
  final bool compact;
  final ValueChanged<Offset> onAimChanged;
  final VoidCallback onFire;

  @override
  Widget build(BuildContext context) {
    final padSize = compact ? 82.0 : 96.0;
    final buttonSize = compact ? 66.0 : 76.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PrismRiftBattleAimPad(
          enabled: enabled,
          size: padSize,
          tint: tint,
          onAimChanged: onAimChanged,
        ),
        SizedBox(width: compact ? 10 : 14),
        Tooltip(
          message: canFire ? 'Fire rift shot' : 'Shot charging',
          child: SizedBox.square(
            dimension: buttonSize,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                backgroundColor: canFire
                    ? tint
                    : LightcorePalette.stroke.withValues(alpha: 0.28),
                foregroundColor: LightcorePalette.night,
              ),
              onPressed: canFire ? onFire : null,
              child: Icon(Icons.gps_fixed_rounded, size: compact ? 28 : 32),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrismRiftBattleAimPad extends StatefulWidget {
  const _PrismRiftBattleAimPad({
    required this.enabled,
    required this.size,
    required this.tint,
    required this.onAimChanged,
  });

  final bool enabled;
  final double size;
  final Color tint;
  final ValueChanged<Offset> onAimChanged;

  @override
  State<_PrismRiftBattleAimPad> createState() => _PrismRiftBattleAimPadState();
}

class _PrismRiftBattleAimPadState extends State<_PrismRiftBattleAimPad> {
  Offset _direction = const Offset(0, -1);

  void _updateAim(Offset localPosition) {
    if (!widget.enabled) {
      return;
    }
    final center = Offset(widget.size / 2, widget.size / 2);
    final delta = localPosition - center;
    if (delta.distance <= 2) {
      return;
    }
    final nextDirection = delta / delta.distance;
    setState(() => _direction = nextDirection);
    widget.onAimChanged(nextDirection);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.size / 2;
    final knobSize = widget.size * 0.36;
    final knobOffset = _direction * (radius - (knobSize * 0.72));
    final activeTint = widget.enabled
        ? widget.tint
        : LightcorePalette.stroke.withValues(alpha: 0.72);
    return Tooltip(
      message: 'Aim',
      child: GestureDetector(
        onPanStart: (details) => _updateAim(details.localPosition),
        onPanUpdate: (details) => _updateAim(details.localPosition),
        onTapDown: (details) => _updateAim(details.localPosition),
        child: SizedBox.square(
          dimension: widget.size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LightcorePalette.night.withValues(alpha: 0.72),
              border: Border.all(color: activeTint.withValues(alpha: 0.54)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.control_camera_rounded,
                  color: activeTint.withValues(alpha: 0.32),
                  size: widget.size * 0.42,
                ),
                Transform.translate(
                  offset: knobOffset,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeTint.withValues(alpha: 0.28),
                      border: Border.all(color: activeTint),
                    ),
                    child: SizedBox.square(dimension: knobSize),
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

class _PrismRiftAimOverlay extends StatelessWidget {
  const _PrismRiftAimOverlay({
    required this.direction,
    required this.tint,
    required this.active,
  });

  final Offset direction;
  final Color tint;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PrismRiftAimPainter(
        direction: direction,
        tint: tint,
        active: active,
      ),
    );
  }
}

class _PrismRiftAimPainter extends CustomPainter {
  const _PrismRiftAimPainter({
    required this.direction,
    required this.tint,
    required this.active,
  });

  final Offset direction;
  final Color tint;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final magnitude = direction.distance;
    final aim = magnitude <= 0.001
        ? const Offset(0, -1)
        : direction / magnitude;
    final shortest = math.min(size.width, size.height);
    final origin = Offset(size.width / 2, size.height * 0.46);
    final length = shortest * 0.33;
    final target = origin + (aim * length);
    final alphaScale = active ? 1.0 : 0.34;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, shortest * 0.003)
      ..strokeCap = StrokeCap.round
      ..color = tint.withValues(alpha: 0.68 * alphaScale);
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(9.0, shortest * 0.014)
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..color = tint.withValues(alpha: 0.2 * alphaScale);

    canvas.drawLine(origin, target, glowPaint);
    canvas.drawLine(origin, target, linePaint);

    final crossRadius = shortest * 0.022;
    final tangent = Offset(-aim.dy, aim.dx);
    final crossPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, shortest * 0.0024)
      ..strokeCap = StrokeCap.round
      ..color = LightcorePalette.mist.withValues(alpha: 0.82 * alphaScale);
    canvas.drawCircle(target, crossRadius, crossPaint);
    canvas.drawLine(
      target - (aim * crossRadius * 1.6),
      target + (aim * crossRadius * 1.6),
      crossPaint,
    );
    canvas.drawLine(
      target - (tangent * crossRadius * 1.6),
      target + (tangent * crossRadius * 1.6),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PrismRiftAimPainter oldDelegate) {
    return oldDelegate.direction != direction ||
        oldDelegate.tint != tint ||
        oldDelegate.active != active;
  }
}
