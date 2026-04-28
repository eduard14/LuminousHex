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

  @override
  State<_TournamentModeDetailScreen> createState() =>
      _TournamentModeDetailScreenState();
}

class _TournamentModeDetailScreenState
    extends State<_TournamentModeDetailScreen> {
  static const Duration _runDuration = Duration(seconds: 20);
  static const Duration _tickRate = Duration(milliseconds: 100);

  Timer? _ticker;

  final Set<String> _selectedBlitzEnemyIds = <String>{};
  final Set<String> _selectedArenaEnemyIds = <String>{};
  String? _selectedArenaBossId;

  double _elapsedSeconds = 0;
  double _score = 0;
  bool _runActive = false;
  bool _runComplete = false;
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

  double _arenaFlow = 0;
  double _arenaTargetFlow = 0;
  double _arenaOverclockCharge = 0;
  double _arenaBurstSeconds = 0;
  double _arenaPressure = 0;
  late LightcoreController _battleController;

  @override
  void initState() {
    super.initState();
    _battleController = _createBattleController();
    _gauntletLaneIntegrity = List<double>.filled(
      LightcoreController.slotCount,
      1,
    );
    _seedSelections();
    _syncBattleController();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _battleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TournamentModeDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modeState.mode != widget.modeState.mode) {
      _ticker?.cancel();
      _runActive = false;
      _runComplete = false;
      _elapsedSeconds = 0;
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
      _seedSelections();
      _syncBattleController();
    } else {
      _seedSelections();
      if (!_runActive) {
        _syncBattleController();
      }
    }
  }

  LightcoreTournamentModeId get _mode => widget.modeState.mode;

  double get _runDurationSeconds => _runDuration.inMilliseconds / 1000;

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

  double get _arenaRelayScore => 62 + (_eventSeed / 45);

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
    LightcoreTournamentModeId.arenaFlow => _arenaBurstSeconds > 0 ? 2 : 1,
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

  void _startRun() {
    if (!widget.modeState.canStartRun) {
      return;
    }
    _seedSelections();
    _ticker?.cancel();
    setState(() {
      _elapsedSeconds = 0;
      _score = 0;
      _runActive = true;
      _runComplete = false;
      switch (_mode) {
        case LightcoreTournamentModeId.enemyBlitz:
          _blitzResources = _enemyBlitzStarterResources;
          _blitzWave = 1;
          _blitzTowerTier = 1;
          _blitzEnemyTier = 1;
          _blitzShield = 1;
          _blitzSupplyProgress = 0;
          _hint =
              'Draft locked. Hold the blitz, cash wave payouts, and choose whether to upgrade the tower or the enemies.';
          break;
        case LightcoreTournamentModeId.hexGauntlet:
          _gauntletWave = 1;
          _gauntletCharges = 2;
          _gauntletChargeProgress = 0.2;
          _gauntletCoreIntegrity = 1;
          _gauntletLaneIntegrity = List<double>.filled(
            LightcoreController.slotCount,
            1,
          );
          _hint =
              'The normalized event shell is live in the hex grid. Reinforce any lane that starts to buckle.';
          break;
        case LightcoreTournamentModeId.arenaFlow:
          _arenaFlow = 0;
          _arenaTargetFlow = 0;
          _arenaOverclockCharge = 0.35;
          _arenaBurstSeconds = 0;
          _arenaPressure = 0;
          _hint =
              'Arena duel live. Build overclock charge, burst through the Apex pressure, and beat the room flow.';
          break;
      }
    });
    _syncBattleController();
    _ticker = Timer.periodic(_tickRate, (_) => _advanceRun());
  }

  void _advanceRun() {
    if (!mounted || !_runActive) {
      _ticker?.cancel();
      return;
    }

    const dt = 0.1;
    final nextElapsed = min(_runDurationSeconds, _elapsedSeconds + dt);
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
        if (_blitzShield <= 0.02) {
          finish = true;
          finishHint =
              'Anomaly Blitz collapsed on wave $_blitzWave. Submit the run and climb the weekend survival board.';
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
        _arenaPressure =
            18 +
            (draftedLevels * 1.4) +
            (draftThreat * 1.8) +
            (bossLevel * 2.4) +
            (bossThreat * 0.9) +
            (sin(nextElapsed * 1.7) * 5.2);
        final playerRate = max(
          0.0,
          (_arenaRelayScore * 0.72) +
              (100 * 0.12) +
              (_arenaBurstSeconds > 0 ? 22 : 0) -
              (_arenaPressure * 0.32),
        );
        final rivalRate = max(
          0.0,
          28 +
              (draftedLevels * 1.6) +
              (draftThreat * 1.6) +
              (bossLevel * 2.6) +
              (bossThreat * 0.86) +
              (widget.modeState.leaderboard
                      .take(3)
                      .fold<double>(
                        0,
                        (sum, entry) => sum + (entry.globalRating / 3000),
                      ) /
                  max(1, min(widget.modeState.leaderboard.length, 3))) +
              (nextElapsed * 0.8),
        );
        _arenaFlow += playerRate * dt;
        _arenaTargetFlow += rivalRate * dt;
        nextScore = _arenaFlow;
        nextHint = _arenaOverclockCharge >= 1
            ? 'Overclock ready. Burst now to claw back flow.'
            : _arenaBurstSeconds > 0
            ? 'Overclock live. Push through the Apex pressure.'
            : 'Charge the relay and wait for the pressure dip.';
        break;
    }

    setState(() {
      _elapsedSeconds = nextElapsed;
      _score = nextScore;
      _hint = nextHint;
      if (finish || nextElapsed >= _runDurationSeconds) {
        _runActive = false;
        _runComplete = true;
        _hint = finish
            ? finishHint
            : _mode == LightcoreTournamentModeId.arenaFlow &&
                  _arenaFlow >= _arenaTargetFlow
            ? 'Arena Flow won the duel. Submit the score before the room rotates.'
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
      _score += 16;
      _hint = 'Overclock fired. Push flow while the arena window is open.';
    });
    _battleController.burstManualOverdrive();
  }

  Future<void> _submitScore() async {
    if (!_runComplete) {
      return;
    }
    await widget.onSubmit(widget.modeState, _score.round());
    if (!mounted) {
      return;
    }
    setState(() {
      _runComplete = false;
      _elapsedSeconds = 0;
      _hint =
          'Score submitted. You can rerun the event to improve your standing.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.modeState;
    final tint = _modeTint(state.mode);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
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
                          const SizedBox(height: 6),
                          Text(
                            state.mode.subtitle,
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
                    _HeaderChip(label: 'Goal', value: state.mode.scoringLabel),
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
                    _HeaderChip(
                      label: 'Event',
                      value:
                          '${max(LightcoreController.evenEntryTournamentPowerIndex, state.seedPowerIndex)}',
                    ),
                    _HeaderChip(label: 'Entries', value: '${state.groupSize}'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  state.mode.compressedLoopLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.mode.mechanicLabel}: ${state.mechanicSummary}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.statusMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
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
            const SizedBox(height: 12),
            _buildRunPanel(context, tint),
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
            onPressed: widget.busy || _runActive || !state.canStartRun
                ? null
                : _startRun,
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
            _HeaderChip(label: 'Event Seed', value: '$_eventSeed'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            const _HeaderChip(label: 'Event Lanes', value: '6/6'),
            _HeaderChip(label: 'Event Power', value: '$_eventSeed'),
            _HeaderChip(
              label: 'Event Core',
              value: '${LightcoreController.evenEntryTournamentCoreLevel}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Event Hex Grid', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _HexGauntletPreview(
          laneIntegrity: const <double>[1, 1, 1, 1, 1, 1],
          coreIntegrity: 1,
          builtLanes: List<bool>.generate(
            LightcoreController.slotCount,
            (_) => true,
            growable: false,
          ),
          tint: tint,
        ),
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
              label: 'Relay Score',
              value: _arenaRelayScore.toStringAsFixed(0),
            ),
            _HeaderChip(
              label: 'Output Base',
              value: widget.controller.outputEfficiencyLabel,
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
    final progress = _elapsedSeconds / _runDurationSeconds;
    return AuroraPanel(
      tint: tint,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Live Event Run',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (_runActive)
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
                    'LIVE',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: tint,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _TournamentBattleStage(
            controller: _battleController,
            tint: tint,
            compact: MediaQuery.sizeOf(context).width < 760,
          ),
          const SizedBox(height: 12),
          MeterBar(value: progress.clamp(0.0, 1.0), color: tint, height: 12),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: _buildRunStatChips()),
          const SizedBox(height: 14),
          Text(_hint, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          switch (_mode) {
            LightcoreTournamentModeId.enemyBlitz => _buildEnemyBlitzRunControls(
              tint,
            ),
            LightcoreTournamentModeId.hexGauntlet =>
              _buildHexGauntletRunControls(tint),
            LightcoreTournamentModeId.arenaFlow => _buildArenaFlowRunControls(
              tint,
            ),
          },
          const SizedBox(height: 14),
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
                onPressed: widget.busy || _runActive ? null : _startRun,
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
                icon: const Icon(Icons.workspace_premium_rounded),
                label: Text(
                  widget.modeState.rewardClaimed ? 'Claimed' : 'Claim Reward',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRunStatChips() {
    final chips = <Widget>[
      _HeaderChip(
        label: 'Time',
        value: '${max(0, (_runDurationSeconds - _elapsedSeconds).ceil())}s',
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
          _HeaderChip(label: 'Output', value: _arenaFlow.toStringAsFixed(0)),
          _HeaderChip(
            label: 'Target',
            value: _arenaTargetFlow.toStringAsFixed(0),
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
          'Weekend Survival Board',
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
    final flowLead = _arenaFlow - _arenaTargetFlow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Arena Duel', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        AuroraPanel(
          tint: tint,
          radius: 20,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pressure ${_arenaPressure.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              MeterBar(
                value: (_arenaFlow / max(1, _arenaTargetFlow + 60)).clamp(
                  0.0,
                  1.0,
                ),
                color: tint,
              ),
              const SizedBox(height: 6),
              Text(
                flowLead >= 0
                    ? 'Lead +${flowLead.toStringAsFixed(0)} flow'
                    : 'Trail ${flowLead.toStringAsFixed(0)} flow',
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
          label: const Text('Trigger Overclock'),
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
                : 'Showing the top ${min(state.capacity, state.leaderboard.length)} of ${state.groupSize} submitted runs.',
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
