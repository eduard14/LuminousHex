part of '../tournament_screen.dart';

class _TournamentModeDetailScreen extends StatefulWidget {
  const _TournamentModeDetailScreen({
    super.key,
    required this.controller,
    required this.modeState,
    required this.busy,
    required this.onBack,
    required this.onJoin,
    required this.onRefresh,
    required this.onClaim,
    required this.onSubmit,
    this.autoStartRun = false,
    this.onAutoStartConsumed,
    this.onBattleSurfaceActiveChanged,
  });

  final LightcoreController controller;
  final LightcoreTournamentModeState modeState;
  final bool busy;
  final VoidCallback onBack;
  final Future<void> Function() onJoin;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onClaim;
  final Future<void> Function(LightcoreTournamentModeState modeState, int score)
  onSubmit;
  final bool autoStartRun;
  final VoidCallback? onAutoStartConsumed;
  final ValueChanged<bool>? onBattleSurfaceActiveChanged;

  @override
  State<_TournamentModeDetailScreen> createState() =>
      _TournamentModeDetailScreenState();
}

class _TournamentModeDetailScreenState
    extends State<_TournamentModeDetailScreen> {
  static const Duration _standardRunDuration = Duration(seconds: 20);
  static const Duration _enemyBlitzSessionDuration = Duration(days: 2);
  static const Duration _tickRate = Duration(milliseconds: 100);
  static const Duration _launchDelay = Duration(milliseconds: 450);

  Timer? _ticker;

  final Set<String> _selectedBlitzEnemyIds = <String>{};
  final Set<String> _selectedArenaEnemyIds = <String>{};
  String? _selectedArenaBossId;

  double _elapsedSeconds = 0;
  double _score = 0;
  DateTime? _blitzSessionStartedAt;
  DateTime? _blitzSessionEndsAt;
  bool _runActive = false;
  bool _runComplete = false;
  bool _launchingRun = false;
  String _hint = 'Build your event loadout and enter the bracket.';

  int _blitzResources = 0;
  int _blitzWave = 1;
  int _blitzTowerTier = 1;
  int _blitzEnemyTier = 1;
  double _blitzShield = 1;
  double _blitzSupplyProgress = 0;

  int _gauntletWave = 1;
  int _gauntletCharges = 2;
  double _gauntletChargeProgress = 0;
  double _gauntletCoreIntegrity = 1;
  late List<double> _gauntletLaneIntegrity;

  double _arenaPlayerDamageDealt = 0;
  double _arenaPlayerDamageTaken = 0;
  double _arenaRivalDamageDealt = 0;
  double _arenaRivalDamageTaken = 0;
  double _arenaPlayerEnemyProgress = 0;
  double _arenaRivalEnemyProgress = 0;
  double _arenaOverclockCharge = 0;
  double _arenaBurstSeconds = 0;
  double _arenaPressure = 0;
  late LightcoreController _battleController;
  late HexTournamentRunController _hexRun;
  late ValueNotifier<HexTournamentSnapshot> _hexSnapshotNotifier;
  late _HexTournamentGame _hexGame;

  @override
  void initState() {
    super.initState();
    _battleController = _createBattleController();
    _hexRun = HexTournamentRunController(seedPowerIndex: _eventSeed);
    _hexSnapshotNotifier = ValueNotifier<HexTournamentSnapshot>(
      _hexRun.snapshot,
    );
    _hexGame = _createHexGame();
    _gauntletLaneIntegrity = List<double>.filled(
      LightcoreController.slotCount,
      1,
    );
    _seedSelections();
    _syncBattleController();
    if (widget.autoStartRun && widget.modeState.canStartRun) {
      _launchingRun = true;
      _hint = 'Loading ${widget.modeState.mode.label}...';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAutoStartConsumed?.call();
        _startRunAfterLaunchDelay();
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _battleController.dispose();
    _hexGame.pauseEngine();
    _hexSnapshotNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TournamentModeDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modeState.mode != widget.modeState.mode) {
      _ticker?.cancel();
      _runActive = false;
      _runComplete = false;
      _launchingRun = false;
      _elapsedSeconds = 0;
      _blitzSessionStartedAt = null;
      _blitzSessionEndsAt = null;
      _score = 0;
      _hint = 'Build your event loadout and enter the bracket.';
      _selectedBlitzEnemyIds.clear();
      _selectedArenaEnemyIds.clear();
      _selectedArenaBossId = null;
      _gauntletLaneIntegrity = List<double>.filled(
        LightcoreController.slotCount,
        1,
      );
      _battleController.dispose();
      _battleController = _createBattleController();
      _hexGame.pauseEngine();
      _hexRun.reset(seedPowerIndex: _eventSeed);
      _refreshHexSnapshot();
      _seedSelections();
      _syncBattleController();
    } else {
      _seedSelections();
      if (!_runActive) {
        _hexRun.reset(seedPowerIndex: _eventSeed);
        _refreshHexSnapshot();
        _syncBattleController();
      }
    }
    if (widget.autoStartRun && !oldWidget.autoStartRun) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _queueStartRun());
    }
  }

  LightcoreTournamentModeId get _mode => widget.modeState.mode;

  Duration get _activeRunDuration =>
      _mode == LightcoreTournamentModeId.enemyBlitz
      ? _enemyBlitzSessionDuration
      : _standardRunDuration;

  double get _runDurationSeconds => _activeRunDuration.inMilliseconds / 1000;

  Duration get _runRemaining {
    if (_mode == LightcoreTournamentModeId.enemyBlitz &&
        _blitzSessionEndsAt != null) {
      return _blitzSessionEndsAt!.difference(DateTime.now());
    }
    final remainingSeconds = max(0.0, _runDurationSeconds - _elapsedSeconds);
    return Duration(milliseconds: (remainingSeconds * 1000).ceil());
  }

  double get _runProgress {
    if (_mode == LightcoreTournamentModeId.enemyBlitz &&
        _blitzSessionStartedAt != null &&
        _blitzSessionEndsAt != null) {
      final total = _blitzSessionEndsAt!
          .difference(_blitzSessionStartedAt!)
          .inMilliseconds;
      if (total <= 0) {
        return 1;
      }
      final elapsed = DateTime.now()
          .difference(_blitzSessionStartedAt!)
          .inMilliseconds;
      return (elapsed / total).clamp(0.0, 1.0).toDouble();
    }
    return (_elapsedSeconds / _runDurationSeconds).clamp(0.0, 1.0).toDouble();
  }

  String get _runCountdownLabel => _formatRunDuration(_runRemaining);

  LightcoreController _createBattleController() {
    final seed =
        (widget.modeState.seedPowerIndex * 37) +
        (widget.modeState.mode.index * 1009);
    return LightcoreController(
      packRandom: Random(seed + 1),
      traitRandom: Random(seed + 2),
      managerRandom: Random(seed + 3),
      spawnRandom: Random(seed + 4),
      guideProfile: widget.controller.guideProfile,
      playerId: '${widget.controller.playerId}-TOURNEY',
      screenName: widget.controller.screenName,
    );
  }

  _HexTournamentGame _createHexGame() {
    return _HexTournamentGame(
      run: _hexRun,
      snapshotNotifier: _hexSnapshotNotifier,
      onCellTap: _handleHexCellTap,
      onCellDrop: _handleHexCellDrop,
      onRunEnded: _handleHexRunEnded,
    );
  }

  void _refreshHexSnapshot() {
    final snapshot = _hexRun.snapshot;
    _score = snapshot.score.toDouble();
    _hexSnapshotNotifier.value = snapshot;
  }

  void _handleHexCellTap(String cellId) {
    if (!_runActive || _runComplete) {
      return;
    }
    _hexRun.tapCell(cellId);
    _refreshHexSnapshot();
  }

  void _handleHexCellDrop(String sourceCellId, String targetCellId) {
    if (!_runActive || _runComplete || sourceCellId == targetCellId) {
      return;
    }
    if (_hexRun.mergeTowers(targetCellId, sourceCellId)) {
      _refreshHexSnapshot();
    }
  }

  void _handleHexRunEnded() {
    if (!_runActive || _runComplete || !_hexRun.defeated) {
      return;
    }
    _hexGame.pauseEngine();
    _completeHexRun(
      'Hex core broke on wave ${_hexRun.wave}. Submit the score or start over.',
    );
    _refreshHexSnapshot();
    widget.onBattleSurfaceActiveChanged?.call(false);
  }

  void _completeHexRun(String hint) {
    setState(() {
      _runActive = false;
      _runComplete = true;
      _launchingRun = false;
      _score = _hexRun.score.toDouble();
      _hint = hint;
    });
  }

  List<EnemyCardState> get _availableEnemyCards {
    final rarityLimit = _eventEnemyRarityLimit;
    final affinities = PrototypeAffinity.values;
    return List<EnemyCardState>.generate(affinities.length, (index) {
      final rarity = EnemyCardRarity.values[index % (rarityLimit + 1)];
      final affinity = affinities[index];
      final config = EnemyLibrary.all.firstWhere(
        (entry) => entry.rarity == rarity && entry.affinity == affinity,
        orElse: () => EnemyLibrary.basicWhite,
      );
      return EnemyCardState(
        config: config,
        unlocked: true,
        copies: 1,
        level: 1 + config.rarity.index,
      );
    }, growable: false);
  }

  List<EnemyCardState> get _availableBossCards {
    return BossEnemyLibrary.all
        .take(4)
        .map(
          (config) => EnemyCardState(
            config: config,
            unlocked: true,
            copies: 1,
            level: 1 + config.rarity.index,
          ),
        )
        .toList(growable: false);
  }

  int get _eventEnemyRarityLimit {
    final seed = _eventSeed;
    if (seed >= 500000000) {
      return EnemyCardRarity.legendary.index;
    }
    if (seed >= 5000000) {
      return EnemyCardRarity.epic.index;
    }
    if (seed >= 50000) {
      return EnemyCardRarity.rare.index;
    }
    if (seed >= 5000) {
      return EnemyCardRarity.uncommon.index;
    }
    return EnemyCardRarity.basic.index;
  }

  double _enemyCardTournamentThreat(EnemyCardState card) {
    final healthPressure = pow(
      max(1.0, widget.controller.enemyCardPreviewHealth(card)) / 9,
      card.config.isBoss ? 0.12 : 0.16,
    ).toDouble();
    final economyPressure = pow(
      max(
            1.0,
            widget.controller.enemyCardPreviewReward(card) +
                widget.controller.enemyCardPreviewExperience(card),
          ) /
          4,
      card.config.isBoss ? 0.08 : 0.12,
    ).toDouble();
    return healthPressure +
        economyPressure +
        (card.config.rarity.index * (card.config.isBoss ? 2.8 : 1.4));
  }

  double _enemyDraftThreatScore(Iterable<EnemyCardState> cards) {
    final list = cards.toList(growable: false);
    if (list.isEmpty) {
      return 1;
    }
    return list.fold<double>(
          0,
          (sum, card) => sum + _enemyCardTournamentThreat(card),
        ) /
        list.length;
  }

  double _enemyDraftPayoutScore(Iterable<EnemyCardState> cards) {
    final list = cards.toList(growable: false);
    if (list.isEmpty) {
      return 1;
    }
    return list.fold<double>(0, (sum, card) {
          final payout =
              widget.controller.enemyCardPreviewReward(card) +
              widget.controller.enemyCardPreviewExperience(card);
          return sum + pow(max(1.0, payout.toDouble()) / 4, 0.10).toDouble();
        }) /
        list.length;
  }

  void _seedSelections() {
    final enemyCards = _availableEnemyCards;
    if (_selectedBlitzEnemyIds.isEmpty) {
      for (final card in enemyCards.take(3)) {
        _selectedBlitzEnemyIds.add(card.config.id);
      }
    } else {
      _selectedBlitzEnemyIds.removeWhere(
        (id) => !enemyCards.any((card) => card.config.id == id),
      );
      if (_selectedBlitzEnemyIds.isEmpty && enemyCards.isNotEmpty) {
        _selectedBlitzEnemyIds.add(enemyCards.first.config.id);
      }
    }

    if (_selectedArenaEnemyIds.isEmpty) {
      for (final card in enemyCards.take(2)) {
        _selectedArenaEnemyIds.add(card.config.id);
      }
    } else {
      _selectedArenaEnemyIds.removeWhere(
        (id) => !enemyCards.any((card) => card.config.id == id),
      );
      if (_selectedArenaEnemyIds.isEmpty && enemyCards.isNotEmpty) {
        _selectedArenaEnemyIds.add(enemyCards.first.config.id);
      }
    }

    final bossCards = _availableBossCards;
    if (_selectedArenaBossId == null ||
        !bossCards.any((card) => card.config.id == _selectedArenaBossId)) {
      _selectedArenaBossId = bossCards.isEmpty
          ? null
          : bossCards.first.config.id;
    }
  }

  EnemyCardState? _enemyCardById(String id) {
    for (final card in _availableEnemyCards) {
      if (card.config.id == id) {
        return card;
      }
    }
    return null;
  }

  EnemyCardState? _bossCardById(String? id) {
    if (id == null) {
      return null;
    }
    for (final card in _availableBossCards) {
      if (card.config.id == id) {
        return card;
      }
    }
    return null;
  }

  List<EnemyCardState> _selectedEnemyCards(Set<String> ids) {
    return ids
        .map(_enemyCardById)
        .whereType<EnemyCardState>()
        .toList(growable: false);
  }

  double _averageEnemyLevel(Set<String> ids) {
    final cards = _selectedEnemyCards(ids);
    if (cards.isEmpty) {
      return 1;
    }
    final total = cards.fold<double>(0, (sum, card) => sum + card.level);
    return total / cards.length;
  }

  int get _eventSeed => max(
    LightcoreController.evenEntryTournamentPowerIndex,
    widget.modeState.seedPowerIndex,
  );

  int get _enemyBlitzStarterResources {
    final seed = max(180, _eventSeed);
    return 90 + (seed / 7).round();
  }

  double get _arenaRelayScore =>
      58 + (sqrt(_eventSeed) * 0.32) + (widget.controller.homeTowerTier * 10);

  double get _arenaPlayerNetDamage =>
      _arenaPlayerDamageDealt - _arenaPlayerDamageTaken;

  double get _arenaRivalNetDamage =>
      _arenaRivalDamageDealt - _arenaRivalDamageTaken;

  double get _arenaRivalRating {
    final rival = _arenaRivalEntry;
    return (rival?.globalRating ?? 1000).toDouble();
  }

  double get _arenaRivalPower =>
      (_eventSeed * (0.9 + ((_arenaRivalRating - 1000) / 5000))).clamp(
        LightcoreController.evenEntryTournamentPowerIndex.toDouble(),
        LightcoreController.tournamentPowerIndexCap.toDouble(),
      );

  double get _arenaPlayerTowerDurability =>
      900 + (sqrt(_eventSeed) * 2.2) + (widget.controller.homeTowerTier * 140);

  double get _arenaRivalTowerDurability =>
      900 + (sqrt(_arenaRivalPower) * 2.0) + (_arenaRivalRating * 0.05);

  double get _arenaPlayerTowerIntegrity =>
      (1 - (_arenaPlayerDamageTaken / _arenaPlayerTowerDurability))
          .clamp(0.0, 1.0)
          .toDouble();

  double get _arenaRivalTowerIntegrity =>
      (1 - (_arenaRivalDamageTaken / _arenaRivalTowerDurability))
          .clamp(0.0, 1.0)
          .toDouble();

  LightcoreTournamentLeaderboardEntry? get _arenaRivalEntry {
    for (final entry in widget.modeState.leaderboard) {
      if (!entry.isPlayer) {
        return entry;
      }
    }
    return null;
  }

  String get _arenaRivalLabel => _arenaRivalEntry?.displayName ?? 'Room Rival';

  PrototypeAffinity get _arenaRivalAffinity {
    final affinities = PrototypeAffinity.values
        .where(
          (affinity) =>
              affinity != PrototypeAffinity.neutral &&
              affinity != PrototypeAffinity.black,
        )
        .toList(growable: false);
    if (affinities.isEmpty) {
      return PrototypeAffinity.violet;
    }
    return affinities[(_arenaRivalRating ~/ 100) % affinities.length];
  }

  PrototypeAffinity get _arenaPlayerEnemyAffinity {
    final selected = _selectedEnemyCards(_selectedArenaEnemyIds);
    return selected.isEmpty
        ? PrototypeAffinity.neutral
        : selected.first.config.affinity;
  }

  PrototypeAffinity get _arenaRivalEnemyAffinity {
    final affinities = PrototypeAffinity.values
        .where(
          (affinity) =>
              affinity != PrototypeAffinity.neutral &&
              affinity != PrototypeAffinity.black,
        )
        .toList(growable: false);
    if (affinities.isEmpty) {
      return PrototypeAffinity.black;
    }
    return affinities[((_arenaRivalRating ~/ 80) + 3) % affinities.length];
  }

  List<EnemyCardState> get _battleEnemyDraft => switch (_mode) {
    LightcoreTournamentModeId.enemyBlitz => _selectedEnemyCards(
      _selectedBlitzEnemyIds,
    ),
    LightcoreTournamentModeId.hexGauntlet =>
      _availableEnemyCards.take(3).toList(growable: false),
    LightcoreTournamentModeId.arenaFlow => _selectedEnemyCards(
      _selectedArenaEnemyIds,
    ),
  };

  EnemyCardState? get _battleBossDraft =>
      _mode == LightcoreTournamentModeId.arenaFlow
      ? _bossCardById(_selectedArenaBossId)
      : null;

  int get _battleTowerTier => switch (_mode) {
    LightcoreTournamentModeId.enemyBlitz => _blitzTowerTier,
    LightcoreTournamentModeId.hexGauntlet => 1 + (_gauntletWave ~/ 3),
    LightcoreTournamentModeId.arenaFlow =>
      widget.controller.homeTowerTier + (_arenaBurstSeconds > 0 ? 1 : 0),
  };

  int get _battleEnemyPressure => switch (_mode) {
    LightcoreTournamentModeId.enemyBlitz =>
      7 +
          _blitzEnemyTier +
          _blitzWave +
          (_enemyDraftThreatScore(_selectedEnemyCards(_selectedBlitzEnemyIds)) /
                  8)
              .round(),
    LightcoreTournamentModeId.hexGauntlet => 8 + (_gauntletWave ~/ 2),
    LightcoreTournamentModeId.arenaFlow =>
      8 +
          _selectedArenaEnemyIds.length +
          (_selectedArenaBossId == null ? 0 : 4) +
          (_enemyDraftThreatScore(_selectedEnemyCards(_selectedArenaEnemyIds)) /
                  10)
              .round(),
  };

  void _syncBattleController() {
    _battleController.configureTournamentBattle(
      mode: _mode,
      seedPowerIndex: widget.modeState.seedPowerIndex,
      enemyDraft: _battleEnemyDraft,
      bossDraft: _battleBossDraft,
      towerTier: _battleTowerTier,
      enemyPressure: _battleEnemyPressure,
    );
  }

  void _queueStartRun() {
    if (_launchingRun ||
        _runActive ||
        widget.busy ||
        !widget.modeState.canStartRun) {
      return;
    }
    widget.onAutoStartConsumed?.call();
    _ticker?.cancel();
    setState(() {
      _launchingRun = true;
      _runComplete = false;
      _elapsedSeconds = 0;
      _blitzSessionStartedAt = null;
      _blitzSessionEndsAt = null;
      _score = 0;
      _hint = 'Loading ${widget.modeState.mode.label}...';
    });
    _startRunAfterLaunchDelay();
  }

  void _startRunAfterLaunchDelay() {
    Future<void>.delayed(_launchDelay, () {
      if (!mounted || !_launchingRun) {
        return;
      }
      _startRun();
    });
  }

  void _startRun() {
    if (!widget.modeState.canStartRun) {
      setState(() => _launchingRun = false);
      return;
    }
    _seedSelections();
    _ticker?.cancel();
    setState(() {
      _elapsedSeconds = 0;
      _score = 0;
      _runActive = true;
      _runComplete = false;
      _launchingRun = false;
      switch (_mode) {
        case LightcoreTournamentModeId.enemyBlitz:
          final startedAt = DateTime.now();
          _blitzSessionStartedAt = startedAt;
          _blitzSessionEndsAt = startedAt.add(_enemyBlitzSessionDuration);
          _blitzResources = _enemyBlitzStarterResources;
          _blitzWave = 1;
          _blitzTowerTier = 1;
          _blitzEnemyTier = 1;
          _blitzShield = 1;
          _blitzSupplyProgress = 0;
          _hint =
              'Weekend-length session live. Keep upgrading the tower, cash wave payouts, and make the anomaly draft greedier before the session timer ends.';
          break;
        case LightcoreTournamentModeId.hexGauntlet:
          _hexRun.start(seedPowerIndex: _eventSeed);
          _hint =
              'Hex run live. Build on open hexes, send waves manually, and push enemy tier when the economy can hold it.';
          break;
        case LightcoreTournamentModeId.arenaFlow:
          _arenaPlayerDamageDealt = 0;
          _arenaPlayerDamageTaken = 0;
          _arenaRivalDamageDealt = 0;
          _arenaRivalDamageTaken = 0;
          _arenaPlayerEnemyProgress = 0.12;
          _arenaRivalEnemyProgress = 0.62;
          _arenaOverclockCharge = 0.35;
          _arenaBurstSeconds = 0;
          _arenaPressure = 0;
          _hint =
              'Arena duel live. Your Home Tower and the rival tower are trading enemy waves. Win by dealing more damage than you take.';
          break;
      }
    });
    if (_mode == LightcoreTournamentModeId.hexGauntlet) {
      _refreshHexSnapshot();
      _hexGame.resumeEngine();
      widget.onBattleSurfaceActiveChanged?.call(true);
      return;
    }
    _syncBattleController();
    widget.onBattleSurfaceActiveChanged?.call(true);
    _ticker = Timer.periodic(_tickRate, (_) => _advanceRun());
  }

  void _advanceRun() {
    if (!mounted || !_runActive) {
      _ticker?.cancel();
      return;
    }

    const dt = 0.1;
    final nextElapsed = _mode == LightcoreTournamentModeId.enemyBlitz
        ? _elapsedSeconds + dt
        : min(_runDurationSeconds, _elapsedSeconds + dt);
    var nextScore = _score;
    var nextHint = _hint;
    var finish = false;
    var finishHint = 'Run complete. Submit the score to your weekly bracket.';

    switch (_mode) {
      case LightcoreTournamentModeId.enemyBlitz:
        final draftedEnemies = _selectedEnemyCards(_selectedBlitzEnemyIds);
        final draftedLevels = _averageEnemyLevel(_selectedBlitzEnemyIds);
        final draftThreat = _enemyDraftThreatScore(draftedEnemies);
        final draftPayout = _enemyDraftPayoutScore(draftedEnemies);
        final affinityCount = draftedEnemies
            .map((card) => card.config.affinity)
            .toSet()
            .length;
        final seed = max(200.0, _eventSeed.toDouble());
        final towerOutput = 52 + (seed / 22) + (_blitzTowerTier * 14);
        final enemyPressure =
            30 +
            (_blitzWave * 8.5) +
            (_blitzEnemyTier * (9.0 + (draftThreat * 0.28))) +
            (draftedLevels * 2.2) +
            (draftThreat * 4.4) -
            (affinityCount * 2.5);
        _blitzShield =
            (_blitzShield + ((towerOutput - enemyPressure) / 180) * dt).clamp(
              0.0,
              1.0,
            );
        _blitzSupplyProgress +=
            dt *
            (0.36 +
                (_blitzEnemyTier * 0.07) +
                (draftedLevels * 0.008) +
                (draftPayout * 0.014));
        while (_blitzSupplyProgress >= 1) {
          _blitzSupplyProgress -= 1;
          _blitzWave += 1;
          _blitzResources +=
              62 +
              (_blitzEnemyTier * 18) +
              (affinityCount * 6) +
              (draftPayout * 4).round();
          nextScore +=
              110 +
              (_blitzWave * 24) +
              (_blitzTowerTier * 18) +
              (draftPayout * 5).round();
          nextHint =
              'Wave $_blitzWave reached. Supply payout delivered. Reinvest into tower strength or make the anomaly draft greedier.';
        }
        nextScore += max(0, towerOutput - (enemyPressure * 0.3)) * dt;
        if (_blitzShield <= 0.08) {
          nextHint =
              'Shell integrity is critical. Keep investing in the tower; the Blitz session continues until the weekend-length timer ends.';
        }
        break;
      case LightcoreTournamentModeId.hexGauntlet:
        const builtCount = LightcoreController.slotCount;
        final towerSeed = max(180.0, _eventSeed.toDouble());
        for (var lane = 0; lane < _gauntletLaneIntegrity.length; lane += 1) {
          final lanePower =
              0.20 +
              (towerSeed / 16000) +
              (_gauntletLaneIntegrity[lane] * 0.03);
          final incoming =
              0.14 +
              (_gauntletWave * 0.015) +
              ((sin((nextElapsed * 1.5) + lane) + 1) * 0.024);
          final nextIntegrity =
              (_gauntletLaneIntegrity[lane] + ((lanePower - incoming) * dt))
                  .clamp(0.0, 1.0);
          _gauntletLaneIntegrity[lane] = nextIntegrity;
          if (nextIntegrity <= 0.04) {
            _gauntletCoreIntegrity =
                (_gauntletCoreIntegrity - (incoming * 0.09 * dt)).clamp(
                  0.0,
                  1.0,
                );
          }
        }
        _gauntletChargeProgress += dt * (0.24 + (builtCount * 0.012));
        while (_gauntletChargeProgress >= 1 && _gauntletCharges < 4) {
          _gauntletChargeProgress -= 1;
          _gauntletCharges += 1;
        }
        if ((nextElapsed / 3).floor() > (_elapsedSeconds / 3).floor()) {
          _gauntletWave += 1;
          nextScore += 130 + (_gauntletWave * 26);
          nextHint =
              'Wave $_gauntletWave is rolling in. Patch weak lanes before the core starts leaking pressure.';
        }
        nextScore +=
            ((_gauntletWave * 4.2) + (_gauntletCoreIntegrity * 34)) * dt;
        if (_gauntletCoreIntegrity <= 0.02) {
          finish = true;
          finishHint =
              'Hex broke at wave $_gauntletWave. Submit the run and keep your best wave on the global weekly board.';
        }
        break;
      case LightcoreTournamentModeId.arenaFlow:
        final draftedLevels = _averageEnemyLevel(_selectedArenaEnemyIds);
        final draftedEnemies = _selectedEnemyCards(_selectedArenaEnemyIds);
        final draftThreat = _enemyDraftThreatScore(draftedEnemies);
        final bossCard = _bossCardById(_selectedArenaBossId);
        final bossLevel = bossCard?.level ?? 1;
        final bossThreat = bossCard == null
            ? 0.0
            : _enemyCardTournamentThreat(bossCard);
        _arenaOverclockCharge =
            (_arenaOverclockCharge + dt * (0.22 + (_arenaRelayScore * 0.0025)))
                .clamp(0.0, 1.4);
        _arenaBurstSeconds = max(0, _arenaBurstSeconds - dt);
        final playerThreat =
            34 +
            (draftedLevels * 3.8) +
            (draftThreat * 4.6) +
            (bossLevel * 6.2) +
            (bossThreat * 1.9);
        final rivalThreat =
            35 +
            (_arenaRivalRating / 38) +
            (widget.modeState.leaderboard
                    .take(3)
                    .fold<double>(
                      0,
                      (sum, entry) => sum + (entry.score / 900),
                    ) /
                max(1, min(widget.modeState.leaderboard.length, 3))) +
            (sin(nextElapsed * 1.6) * 4.4);
        final playerTowerGuard =
            45 +
            (sqrt(_eventSeed) * 0.18) +
            (widget.controller.homeTowerTier * 12) +
            (_arenaBurstSeconds > 0 ? 30 : 0);
        final rivalTowerGuard =
            43 + (sqrt(_arenaRivalPower) * 0.17) + (_arenaRivalRating / 170);
        final playerWaveSpeed =
            0.34 + (playerThreat / 360) + (_arenaBurstSeconds > 0 ? 0.14 : 0);
        final rivalWaveSpeed = 0.32 + (rivalThreat / 380);
        _arenaPlayerEnemyProgress += dt * playerWaveSpeed;
        _arenaRivalEnemyProgress += dt * rivalWaveSpeed;
        while (_arenaPlayerEnemyProgress >= 1) {
          _arenaPlayerEnemyProgress -= 1;
          final hit =
              max(6.0, (playerThreat * 0.88) - (rivalTowerGuard * 0.22)) *
              (_arenaBurstSeconds > 0 ? 1.34 : 1.0);
          _arenaPlayerDamageDealt += hit;
          _arenaRivalDamageTaken += hit;
        }
        while (_arenaRivalEnemyProgress >= 1) {
          _arenaRivalEnemyProgress -= 1;
          final hit = max(
            5.0,
            (rivalThreat * 0.86) - (playerTowerGuard * 0.24),
          );
          _arenaRivalDamageDealt += hit;
          _arenaPlayerDamageTaken += hit;
        }
        _arenaPressure = max(playerThreat, rivalThreat);
        nextScore = max(
          0.0,
          _arenaPlayerNetDamage - max(0.0, _arenaRivalNetDamage),
        );
        nextHint = _arenaOverclockCharge >= 1
            ? 'Overclock ready. Send a faster enemy wave into the rival Home Tower.'
            : _arenaBurstSeconds > 0
            ? 'Overclock live. Your enemies are rushing directly at the rival tower.'
            : _arenaPlayerNetDamage >= _arenaRivalNetDamage
            ? 'Your net damage is ahead. Keep the rival wave off your Home Tower.'
            : 'You are behind on net damage. Time overclock before the next exchange.';
        break;
    }

    setState(() {
      _elapsedSeconds = nextElapsed;
      _score = nextScore;
      _hint = nextHint;
      final blitzSessionExpired =
          _mode == LightcoreTournamentModeId.enemyBlitz &&
          (_blitzSessionEndsAt == null ||
              !DateTime.now().isBefore(_blitzSessionEndsAt!));
      final timedOut = _mode == LightcoreTournamentModeId.enemyBlitz
          ? blitzSessionExpired
          : nextElapsed >= _runDurationSeconds;
      if (finish || timedOut) {
        _runActive = false;
        _runComplete = true;
        _hint = finish
            ? finishHint
            : _mode == LightcoreTournamentModeId.arenaFlow &&
                  _arenaPlayerNetDamage >= _arenaRivalNetDamage
            ? 'Arena Flow won on net damage. Submit before the room rotates.'
            : _mode == LightcoreTournamentModeId.arenaFlow
            ? 'Arena Flow lost on net damage. Run again to post a score.'
            : _mode == LightcoreTournamentModeId.enemyBlitz
            ? 'Weekend-length Blitz session ended. Submit the score for the testing board.'
            : 'Run complete. Submit the score to your weekly bracket.';
      }
    });

    if (!_runActive) {
      _ticker?.cancel();
    }
  }

  void _toggleBlitzEnemy(String id) {
    if (_runActive) {
      return;
    }
    setState(() {
      if (_selectedBlitzEnemyIds.contains(id)) {
        if (_selectedBlitzEnemyIds.length > 1) {
          _selectedBlitzEnemyIds.remove(id);
        }
      } else if (_selectedBlitzEnemyIds.length < 3) {
        _selectedBlitzEnemyIds.add(id);
      } else {
        final first = _selectedBlitzEnemyIds.first;
        _selectedBlitzEnemyIds
          ..remove(first)
          ..add(id);
      }
    });
    _syncBattleController();
  }

  void _toggleArenaEnemy(String id) {
    if (_runActive) {
      return;
    }
    setState(() {
      if (_selectedArenaEnemyIds.contains(id)) {
        if (_selectedArenaEnemyIds.length > 1) {
          _selectedArenaEnemyIds.remove(id);
        }
      } else if (_selectedArenaEnemyIds.length < 2) {
        _selectedArenaEnemyIds.add(id);
      } else {
        final first = _selectedArenaEnemyIds.first;
        _selectedArenaEnemyIds
          ..remove(first)
          ..add(id);
      }
    });
    _syncBattleController();
  }

  void _selectArenaBoss(String id) {
    if (_runActive) {
      return;
    }
    setState(() => _selectedArenaBossId = id);
    _syncBattleController();
  }

  int get _enemyBlitzTowerUpgradeCost => 70 + (_blitzTowerTier * 35);

  int get _enemyBlitzEnemyUpgradeCost => 55 + (_blitzEnemyTier * 30);

  void _buyBlitzTowerUpgrade() {
    if (!_runActive || _blitzResources < _enemyBlitzTowerUpgradeCost) {
      return;
    }
    setState(() {
      _blitzResources -= _enemyBlitzTowerUpgradeCost;
      _blitzTowerTier += 1;
      _score += 30;
      _hint = 'Tower upgraded. The shell can hold longer waves.';
    });
    _syncBattleController();
  }

  void _buyBlitzEnemyUpgrade() {
    if (!_runActive || _blitzResources < _enemyBlitzEnemyUpgradeCost) {
      return;
    }
    setState(() {
      _blitzResources -= _enemyBlitzEnemyUpgradeCost;
      _blitzEnemyTier += 1;
      _score += 42;
      _hint = 'Anomaly draft upgraded. Future clears will pay out harder.';
    });
    _syncBattleController();
  }

  void _reinforceGauntletLane(int lane) {
    if (!_runActive || _gauntletCharges <= 0) {
      return;
    }
    setState(() {
      _gauntletCharges -= 1;
      _gauntletLaneIntegrity[lane] = (_gauntletLaneIntegrity[lane] + 0.26)
          .clamp(0.0, 1.0);
      _score += 18;
      _hint = 'Lane ${lane + 1} reinforced. Keep the path grid intact.';
    });
  }

  void _triggerArenaOverclock() {
    if (!_runActive || _arenaOverclockCharge < 1) {
      return;
    }
    setState(() {
      _arenaOverclockCharge -= 1;
      _arenaBurstSeconds = 2.2;
      _hint =
          'Overclock fired. Your enemy wave is rushing the rival Home Tower.';
    });
    _battleController.burstManualOverdrive();
  }

  Future<void> _submitScore() async {
    if (!_runComplete) {
      return;
    }
    if (_mode == LightcoreTournamentModeId.hexGauntlet) {
      _score = _hexRun.score.toDouble();
    }
    final submittedScore = _score.round();
    if (submittedScore <= 0) {
      setState(() {
        _hint =
            'This run did not post a positive score. Start another attempt.';
      });
      return;
    }
    await widget.onSubmit(widget.modeState, submittedScore);
    if (!mounted) {
      return;
    }
    if (_mode == LightcoreTournamentModeId.hexGauntlet) {
      _hexRun.reset(seedPowerIndex: _eventSeed);
      _hexGame.pauseEngine();
      _refreshHexSnapshot();
    }
    setState(() {
      _runComplete = false;
      _launchingRun = false;
      _elapsedSeconds = 0;
      _hint =
          'Score submitted. You can rerun the event to improve your standing.';
    });
    widget.onBattleSurfaceActiveChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.modeState;
    final tint = _modeTint(state.mode);
    final helpMessage = _modeHelpMessage(state);
    if (state.joined && (_launchingRun || _runActive || _runComplete)) {
      if (_launchingRun) {
        return _buildRunLoading(context, tint);
      }
      return _buildRunPanel(context, tint);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Events'),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: widget.busy ? null : widget.onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AuroraPanel(
            tint: tint,
            padding: const EdgeInsets.all(18),
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
                          Text(
                            state.mode.label,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    LightcoreInfoButton(
                      title: '${state.mode.label} Help',
                      message: helpMessage,
                      tint: tint,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: tint.withValues(alpha: 0.16),
                      ),
                      child: Text(
                        state.mode.eventCadenceLabel,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
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
                      value: state.matchBucketLabel ?? state.mode.queueLabel,
                    ),
                    _HeaderChip(
                      label: 'Best',
                      value: state.joined
                          ? '${state.playerBestScore}'
                          : 'Join to unlock',
                    ),
                    _HeaderChip(
                      label: 'Window',
                      value: state.isOpen
                          ? 'Live'
                          : 'Opens ${_formatCountdown(state.startsAt)}',
                    ),
                    _HeaderChip(
                      label: 'Rank',
                      value: state.playerRank == null
                          ? 'Pending'
                          : '#${state.playerRank}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!state.joined)
            AuroraPanel(
              tint: tint,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join This Event',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.mode.prepLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.isOpen
                        ? 'Once joined, this event gets its own dedicated play screen and local loadout. It does not mirror the base battle view.'
                        : 'This event can be inspected while it is closed, but joining and starting runs stay locked until the next window opens.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: widget.busy || !state.isOpen
                        ? null
                        : widget.onJoin,
                    icon: const Icon(Icons.rocket_launch_rounded),
                    label: Text(
                      state.isOpen
                          ? _joinButtonLabel(state.mode)
                          : 'Event Closed',
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _buildPreparationPanel(context, tint),
          ],
          const SizedBox(height: 12),
          _buildRewardAndLeaderboard(context, tint),
        ],
      ),
    );
  }

  Widget _buildPreparationPanel(BuildContext context, Color tint) {
    final state = widget.modeState;
    return AuroraPanel(
      tint: tint,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Event Setup', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            state.mode.prepLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          switch (_mode) {
            LightcoreTournamentModeId.enemyBlitz => _buildEnemyBlitzPrep(
              context,
              tint,
            ),
            LightcoreTournamentModeId.hexGauntlet => _buildHexGauntletPrep(
              context,
              tint,
            ),
            LightcoreTournamentModeId.arenaFlow => _buildArenaFlowPrep(
              context,
              tint,
            ),
          },
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed:
                widget.busy || _launchingRun || _runActive || !state.canStartRun
                ? null
                : _queueStartRun,
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: Text(
              _runActive
                  ? 'Run Live'
                  : state.canStartRun
                  ? 'Start Run'
                  : 'Event Closed',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnemyBlitzPrep(BuildContext context, Color tint) {
    final drafted = _selectedEnemyCards(_selectedBlitzEnemyIds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HeaderChip(
              label: 'Starter Res',
              value: '$_enemyBlitzStarterResources',
            ),
            _HeaderChip(label: 'Drafted', value: '${drafted.length}/3'),
          ],
        ),
        const SizedBox(height: 12),
        Text('Anomaly Draft', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final card in _availableEnemyCards.take(8))
              _EnemyDraftTile(
                card: card,
                selected: _selectedBlitzEnemyIds.contains(card.config.id),
                accent: tint,
                onTap: () => _toggleBlitzEnemy(card.config.id),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHexGauntletPrep(BuildContext context, Color tint) {
    final preview = _hexRun.snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HeaderChip(
              label: 'Build Hexes',
              value: '${preview.cells.where((cell) => cell.canBuild).length}',
            ),
            _HeaderChip(
              label: 'Path Hexes',
              value: '${preview.pathCells.length}',
            ),
            _HeaderChip(label: 'Start Cur', value: '${preview.currency}'),
            _HeaderChip(
              label: 'Tower Pool',
              value: '${preview.towerChoices.length}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Weekly Focus', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _HexFocusChips(focusAffinities: preview.focusAffinities),
        const SizedBox(height: 12),
        _HexTournamentPreviewMap(snapshot: preview, tint: tint),
      ],
    );
  }

  Widget _buildArenaFlowPrep(BuildContext context, Color tint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HeaderChip(
              label: 'Home Tower',
              value: widget.controller.homeTowerLayerLabel,
            ),
            _HeaderChip(
              label: 'Layer',
              value: 'L${widget.controller.homeTowerTier}',
            ),
            _HeaderChip(
              label: 'Power',
              value: '${widget.controller.homeTowerPowerIndex}',
            ),
            _HeaderChip(
              label: 'Drafted',
              value:
                  '${_selectedArenaEnemyIds.length}A / ${_selectedArenaBossId == null ? 0 : 1}X',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Anomaly Pressure Draft',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final card in _availableEnemyCards.take(6))
              _EnemyDraftTile(
                card: card,
                selected: _selectedArenaEnemyIds.contains(card.config.id),
                accent: tint,
                onTap: () => _toggleArenaEnemy(card.config.id),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Apex Draft', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final boss in _availableBossCards.take(4))
              _EnemyDraftTile(
                card: boss,
                selected: _selectedArenaBossId == boss.config.id,
                accent: tint,
                onTap: () => _selectArenaBoss(boss.config.id),
                boss: true,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRunPanel(BuildContext context, Color tint) {
    if (_mode == LightcoreTournamentModeId.hexGauntlet) {
      return _buildHexTournamentRunPanel(context, tint);
    }
    final progress = _runProgress;
    final countdownLabel = _runCountdownLabel;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 720 || constraints.maxHeight < 720;
        final inset = compact ? 10.0 : 16.0;
        final controlsMaxHeight =
            constraints.maxHeight * (compact ? 0.46 : 0.38);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                LightcorePalette.night,
                LightcorePalette.abyss,
                Color.lerp(LightcorePalette.abyss, tint, 0.18)!,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: _mode == LightcoreTournamentModeId.arenaFlow
                    ? _ArenaFlowDuelStage(
                        playerLabel: widget.controller.playerDisplayName,
                        rivalLabel: _arenaRivalLabel,
                        playerTowerLabel: widget.controller.homeTowerLayerLabel,
                        rivalTowerLabel:
                            '${_arenaRivalAffinity.label} Home Tower',
                        playerTowerAffinity:
                            widget.controller.homeTowerLayer.core.affinity,
                        rivalTowerAffinity: _arenaRivalAffinity,
                        playerEnemyAffinity: _arenaPlayerEnemyAffinity,
                        rivalEnemyAffinity: _arenaRivalEnemyAffinity,
                        playerEnemyProgress: _arenaPlayerEnemyProgress,
                        rivalEnemyProgress: _arenaRivalEnemyProgress,
                        playerTowerIntegrity: _arenaPlayerTowerIntegrity,
                        rivalTowerIntegrity: _arenaRivalTowerIntegrity,
                        playerNetDamage: _arenaPlayerNetDamage,
                        rivalNetDamage: _arenaRivalNetDamage,
                        active: _runActive,
                      )
                    : _TournamentBattleStage(
                        controller: _battleController,
                        active: _runActive,
                      ),
              ),
              Positioned(
                top: inset,
                left: inset,
                right: inset,
                child: AuroraPanel(
                  tint: tint,
                  radius: 18,
                  padding: EdgeInsets.fromLTRB(
                    compact ? 10 : 12,
                    10,
                    compact ? 8 : 10,
                    10,
                  ),
                  child: Row(
                    children: [
                      Tooltip(
                        message: 'Back to events',
                        child: IconButton.filledTonal(
                          onPressed: _returnToEventSetup,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
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
                                    widget.modeState.mode.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  countdownLabel,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: tint,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            MeterBar(value: progress, color: tint, height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: inset,
                right: inset,
                bottom: inset,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: controlsMaxHeight),
                  child: AuroraPanel(
                    tint: tint,
                    radius: 20,
                    padding: EdgeInsets.all(compact ? 12 : 14),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _buildRunStatChips(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _hint,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          switch (_mode) {
                            LightcoreTournamentModeId.enemyBlitz =>
                              _buildEnemyBlitzRunControls(tint),
                            LightcoreTournamentModeId.hexGauntlet =>
                              _buildHexGauntletRunControls(tint),
                            LightcoreTournamentModeId.arenaFlow =>
                              _buildArenaFlowRunControls(tint),
                          },
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed: _runComplete ? _submitScore : null,
                                icon: const Icon(Icons.emoji_events_rounded),
                                label: const Text('Submit Score'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed:
                                    widget.busy || _launchingRun || _runActive
                                    ? null
                                    : _queueStartRun,
                                icon: const Icon(Icons.replay_rounded),
                                label: const Text('Run Again'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed:
                                    widget.busy ||
                                        !widget.modeState.rewardReady ||
                                        widget.modeState.rewardClaimed
                                    ? null
                                    : widget.onClaim,
                                icon: const Icon(
                                  Icons.workspace_premium_rounded,
                                ),
                                label: Text(
                                  widget.modeState.rewardClaimed
                                      ? 'Claimed'
                                      : 'Claim Reward',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRunLoading(BuildContext context, Color tint) {
    return LightcoreRunLoading(
      title: 'Loading ${widget.modeState.mode.label}',
      subtitle: 'Preparing the event rules, visuals, and run state.',
      tint: tint,
      icon: _modeIcon(widget.modeState.mode),
    );
  }

  void _returnToEventSetup() {
    _ticker?.cancel();
    if (_mode == LightcoreTournamentModeId.hexGauntlet) {
      _hexRun.reset(seedPowerIndex: _eventSeed);
      _hexGame.pauseEngine();
      _refreshHexSnapshot();
    }
    setState(() {
      _runActive = false;
      _runComplete = false;
      _launchingRun = false;
      _elapsedSeconds = 0;
      _blitzSessionStartedAt = null;
      _blitzSessionEndsAt = null;
      _hint = 'Build your event loadout and enter the bracket.';
    });
    _syncBattleController();
    widget.onBattleSurfaceActiveChanged?.call(false);
  }

  List<Widget> _buildRunStatChips() {
    final chips = <Widget>[
      _HeaderChip(
        label: _mode == LightcoreTournamentModeId.enemyBlitz
            ? 'Session'
            : 'Time',
        value: _runCountdownLabel,
      ),
      _HeaderChip(label: 'Score', value: '${_score.round()}'),
    ];
    switch (_mode) {
      case LightcoreTournamentModeId.enemyBlitz:
        chips.addAll(<Widget>[
          _HeaderChip(label: 'Wave', value: '$_blitzWave'),
          _HeaderChip(label: 'Res', value: '$_blitzResources'),
          _HeaderChip(label: 'Tower', value: 'T$_blitzTowerTier'),
          _HeaderChip(label: 'Anomaly', value: 'A$_blitzEnemyTier'),
        ]);
        break;
      case LightcoreTournamentModeId.hexGauntlet:
        chips.addAll(<Widget>[
          _HeaderChip(label: 'Wave', value: '$_gauntletWave'),
          _HeaderChip(
            label: 'Core',
            value: '${(_gauntletCoreIntegrity * 100).round()}%',
          ),
          _HeaderChip(label: 'Charges', value: '$_gauntletCharges'),
        ]);
        break;
      case LightcoreTournamentModeId.arenaFlow:
        chips.addAll(<Widget>[
          _HeaderChip(
            label: 'Dealt',
            value: _arenaPlayerDamageDealt.toStringAsFixed(0),
          ),
          _HeaderChip(
            label: 'Taken',
            value: _arenaPlayerDamageTaken.toStringAsFixed(0),
          ),
          _HeaderChip(
            label: 'Charge',
            value: '${(_arenaOverclockCharge * 100).round()}%',
          ),
        ]);
        break;
    }
    return chips;
  }

  Widget _buildEnemyBlitzRunControls(Color tint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Testing Survival Board',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        MeterBar(value: _blitzShield, color: tint),
        const SizedBox(height: 6),
        Text(
          'Shell integrity ${(100 * _blitzShield).round()}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.tonalIcon(
              onPressed:
                  _runActive && _blitzResources >= _enemyBlitzTowerUpgradeCost
                  ? _buyBlitzTowerUpgrade
                  : null,
              icon: const Icon(Icons.upgrade_rounded),
              label: Text('Upgrade Tower ($_enemyBlitzTowerUpgradeCost)'),
            ),
            FilledButton.tonalIcon(
              onPressed:
                  _runActive && _blitzResources >= _enemyBlitzEnemyUpgradeCost
                  ? _buyBlitzEnemyUpgrade
                  : null,
              icon: const Icon(Icons.groups_rounded),
              label: Text('Upgrade Anomalies ($_enemyBlitzEnemyUpgradeCost)'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHexGauntletRunControls(Color tint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hex Path Grid', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _HexGauntletPreview(
          laneIntegrity: _gauntletLaneIntegrity,
          coreIntegrity: _gauntletCoreIntegrity,
          builtLanes: List<bool>.generate(
            LightcoreController.slotCount,
            (_) => true,
            growable: false,
          ),
          tint: tint,
          onLaneTap: _runActive ? _reinforceGauntletLane : null,
        ),
        const SizedBox(height: 8),
        MeterBar(value: _gauntletChargeProgress, color: tint),
        const SizedBox(height: 6),
        Text(
          'Reinforcement charge ${(100 * _gauntletChargeProgress).round()}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildArenaFlowRunControls(Color tint) {
    final netLead = _arenaPlayerNetDamage - _arenaRivalNetDamage;
    final totalDamage = max(
      1.0,
      _arenaPlayerDamageDealt + _arenaPlayerDamageTaken,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Net Damage Duel', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        AuroraPanel(
          tint: tint,
          radius: 20,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Incoming pressure ${_arenaPressure.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              MeterBar(
                value: (_arenaPlayerDamageDealt / totalDamage).clamp(0.0, 1.0),
                color: tint,
              ),
              const SizedBox(height: 6),
              Text(
                netLead >= 0
                    ? 'Lead +${netLead.toStringAsFixed(0)} net damage'
                    : 'Trail ${netLead.toStringAsFixed(0)} net damage',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: _runActive && _arenaOverclockCharge >= 1
              ? _triggerArenaOverclock
              : null,
          icon: const Icon(Icons.flash_on_rounded),
          label: const Text('Overclock Enemy Wave'),
        ),
      ],
    );
  }

  Widget _buildRewardAndLeaderboard(BuildContext context, Color tint) {
    final state = widget.modeState;
    return AuroraPanel(
      tint: tint,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leaderboard And Rewards',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            state.rewardPreview.summaryLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Text(
            state.groupSize == 0
                ? 'No submitted runs are on the board yet.'
                : 'Showing the top ${min(state.capacity, state.leaderboard.length)} of ${state.groupSize} server-ranked entries. Rewards unlock after this board resets.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (state.leaderboard.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (
              var index = 0;
              index < min(state.leaderboard.length, 5);
              index += 1
            ) ...[
              _LeaderboardRow(rank: index + 1, entry: state.leaderboard[index]),
              if (index < min(state.leaderboard.length, 5) - 1)
                const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }
}

String _formatRunDuration(Duration remaining) {
  if (remaining.isNegative) {
    return 'Ended';
  }
  if (remaining.inDays >= 1) {
    return '${remaining.inDays}d ${remaining.inHours.remainder(24)}h';
  }
  if (remaining.inHours >= 1) {
    return '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m';
  }
  if (remaining.inMinutes >= 1) {
    return '${remaining.inMinutes}m ${remaining.inSeconds.remainder(60)}s';
  }
  return '${max(0, remaining.inSeconds)}s';
}
