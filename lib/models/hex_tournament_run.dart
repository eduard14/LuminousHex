import 'dart:math' as math;

import '../data/enemy_configs.dart';
import '../data/tower_configs.dart';
import 'lightcore_config.dart';
import 'lightcore_types.dart';

class HexTournamentCell {
  const HexTournamentCell({
    required this.q,
    required this.r,
    required this.pathIndex,
  });

  final int q;
  final int r;
  final int? pathIndex;

  String get id => '$q:$r';
  bool get isPath => pathIndex != null;
  bool get canBuild => !isPath;
}

class HexTournamentTower {
  const HexTournamentTower({
    required this.id,
    required this.cellId,
    required this.q,
    required this.r,
    required this.config,
    required this.affinity,
    required this.projectileType,
    required this.candidatePayload,
    required this.candidateImpactProjectile,
    required this.weeklyFocus,
    this.payloadType = PayloadType.none,
    this.impactProjectileType,
    this.targetPriority = TargetPriority.close,
    this.cooldownRemaining = 0,
    this.mergeStage = 0,
  });

  final String id;
  final String cellId;
  final int q;
  final int r;
  final TowerConfig config;
  final PrototypeAffinity affinity;
  final ProjectileType projectileType;
  final PayloadType payloadType;
  final PayloadType candidatePayload;
  final ProjectileType? impactProjectileType;
  final ProjectileType candidateImpactProjectile;
  final bool weeklyFocus;
  final TargetPriority targetPriority;
  final double cooldownRemaining;
  final int mergeStage;

  bool get hasPayload => payloadType != PayloadType.none;
  bool get hasImpactProjectile => impactProjectileType != null;
  double get focusDamageMultiplier => weeklyFocus ? 1.16 : 1.0;
  double get range => 1.82 + (config.baseRange / 760) + (mergeStage * 0.2);
  double get damage =>
      (18 +
          (config.basePower * 1.25) +
          (hasPayload ? 9 : 0) +
          (hasImpactProjectile ? 7 : 0)) *
      focusDamageMultiplier;
  double get cooldownSeconds =>
      (config.baseCooldown * (0.62 - (mergeStage * 0.04)))
          .clamp(0.56, 1.08)
          .toDouble();

  HexTournamentTower copyWith({
    PayloadType? payloadType,
    ProjectileType? impactProjectileType,
    TargetPriority? targetPriority,
    double? cooldownRemaining,
    int? mergeStage,
  }) {
    return HexTournamentTower(
      id: id,
      cellId: cellId,
      q: q,
      r: r,
      config: config,
      affinity: affinity,
      projectileType: projectileType,
      candidatePayload: candidatePayload,
      candidateImpactProjectile: candidateImpactProjectile,
      weeklyFocus: weeklyFocus,
      payloadType: payloadType ?? this.payloadType,
      impactProjectileType: impactProjectileType ?? this.impactProjectileType,
      targetPriority: targetPriority ?? this.targetPriority,
      cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
      mergeStage: mergeStage ?? this.mergeStage,
    );
  }
}

class HexTournamentEnemy {
  const HexTournamentEnemy({
    required this.id,
    required this.wave,
    required this.tier,
    required this.config,
    required this.affinity,
    required this.progress,
    required this.health,
    required this.maxHealth,
    required this.speed,
    required this.currencyReward,
    required this.scoreValue,
    required this.damage,
  });

  final String id;
  final int wave;
  final int tier;
  final EnemyConfig config;
  final PrototypeAffinity affinity;
  final double progress;
  final double health;
  final double maxHealth;
  final double speed;
  final int currencyReward;
  final int scoreValue;
  final int damage;

  bool get isOnBoard => progress >= 0;

  HexTournamentEnemy copyWith({double? progress, double? health}) {
    return HexTournamentEnemy(
      id: id,
      wave: wave,
      tier: tier,
      config: config,
      affinity: affinity,
      progress: progress ?? this.progress,
      health: health ?? this.health,
      maxHealth: maxHealth,
      speed: speed,
      currencyReward: currencyReward,
      scoreValue: scoreValue,
      damage: damage,
    );
  }
}

class HexTournamentShotTrace {
  const HexTournamentShotTrace({
    required this.id,
    required this.sourceCellId,
    required this.targetProgress,
    required this.projectileType,
    required this.payloadType,
    required this.progress,
    required this.secondary,
  });

  final String id;
  final String sourceCellId;
  final double targetProgress;
  final ProjectileType projectileType;
  final PayloadType payloadType;
  final double progress;
  final bool secondary;

  HexTournamentShotTrace copyWith({double? progress}) {
    return HexTournamentShotTrace(
      id: id,
      sourceCellId: sourceCellId,
      targetProgress: targetProgress,
      projectileType: projectileType,
      payloadType: payloadType,
      progress: progress ?? this.progress,
      secondary: secondary,
    );
  }
}

class HexTournamentSnapshot {
  const HexTournamentSnapshot({
    required this.cells,
    required this.pathCells,
    required this.focusAffinities,
    required this.towerChoices,
    required this.towers,
    required this.enemies,
    required this.shots,
    required this.selectedCellId,
    required this.currency,
    required this.score,
    required this.wave,
    required this.enemyTier,
    required this.health,
    required this.maxHealth,
    required this.running,
    required this.paused,
    required this.waveInProgress,
    required this.defeated,
    required this.statusLabel,
    required this.buildCost,
    required this.enemyTierCost,
    required this.mergeCandidateCount,
    required this.flawlessStreak,
    required this.waveLeakDamage,
  });

  final List<HexTournamentCell> cells;
  final List<HexTournamentCell> pathCells;
  final List<PrototypeAffinity> focusAffinities;
  final List<TowerConfig> towerChoices;
  final List<HexTournamentTower> towers;
  final List<HexTournamentEnemy> enemies;
  final List<HexTournamentShotTrace> shots;
  final String? selectedCellId;
  final int currency;
  final int score;
  final int wave;
  final int enemyTier;
  final int health;
  final int maxHealth;
  final bool running;
  final bool paused;
  final bool waveInProgress;
  final bool defeated;
  final String statusLabel;
  final int buildCost;
  final int enemyTierCost;
  final int mergeCandidateCount;
  final int flawlessStreak;
  final int waveLeakDamage;

  HexTournamentTower? get selectedTower {
    final cellId = selectedCellId;
    if (cellId == null) {
      return null;
    }
    for (final tower in towers) {
      if (tower.cellId == cellId) {
        return tower;
      }
    }
    return null;
  }

  HexTournamentCell? get selectedCell {
    final cellId = selectedCellId;
    if (cellId == null) {
      return null;
    }
    for (final cell in cells) {
      if (cell.id == cellId) {
        return cell;
      }
    }
    return null;
  }

  bool get canSendWave => running && !paused && !waveInProgress && !defeated;
  bool get canBuyEnemyTier =>
      running && !paused && !waveInProgress && currency >= enemyTierCost;
  bool get canBuildSelected {
    final cell = selectedCell;
    if (cell == null || !cell.canBuild) {
      return false;
    }
    if (selectedTower != null) {
      return false;
    }
    return running && !paused && currency >= buildCost;
  }

  bool get canMergeSelected =>
      running && !paused && selectedTower != null && mergeCandidateCount > 0;
}

class HexTournamentRunController {
  HexTournamentRunController({
    required int seedPowerIndex,
    this.startingCurrency = 180,
    this.maxHealth = 8,
  }) : _seedPowerIndex = seedPowerIndex {
    _configureSeed(seedPowerIndex);
    _resetState(running: false);
  }

  static const int boardRadius = 3;
  static const int buildCost = 70;

  static const List<(int, int)> _pathCoordinates = <(int, int)>[
    (-3, 1),
    (-2, 1),
    (-1, 0),
    (0, 0),
    (1, 0),
    (1, -1),
    (2, -1),
    (3, -2),
  ];

  final int startingCurrency;
  final int maxHealth;

  late int _seedPowerIndex;
  late math.Random _random;
  late List<PrototypeAffinity> _focusAffinities;
  late List<HexTournamentCell> _cells;
  late List<HexTournamentCell> _pathCells;

  final Map<String, HexTournamentTower> _towers =
      <String, HexTournamentTower>{};
  final List<HexTournamentEnemy> _enemies = <HexTournamentEnemy>[];
  final List<HexTournamentShotTrace> _shots = <HexTournamentShotTrace>[];

  String? _selectedCellId;
  int _currency = 0;
  int _score = 0;
  int _wave = 0;
  int _enemyTier = 1;
  int _health = 0;
  int _towerCounter = 0;
  int _enemyCounter = 0;
  int _shotCounter = 0;
  int _flawlessStreak = 0;
  int _waveLeakDamage = 0;
  bool _running = false;
  bool _paused = false;
  bool _waveInProgress = false;
  bool _defeated = false;
  String _statusLabel = 'Event ready.';

  List<PrototypeAffinity> get focusAffinities =>
      List<PrototypeAffinity>.unmodifiable(_focusAffinities);
  int get score => _score;
  int get wave => _wave;
  int get enemyTier => _enemyTier;
  int get currency => _currency;
  int get health => _health;
  bool get running => _running;
  bool get paused => _paused;
  bool get defeated => _defeated;
  bool get waveInProgress => _waveInProgress;
  int get enemyTierCost => 85 + (_enemyTier * 55);

  HexTournamentSnapshot get snapshot {
    return HexTournamentSnapshot(
      cells: List<HexTournamentCell>.unmodifiable(_cells),
      pathCells: List<HexTournamentCell>.unmodifiable(_pathCells),
      focusAffinities: focusAffinities,
      towerChoices: List<TowerConfig>.unmodifiable(TowerLibrary.all),
      towers: List<HexTournamentTower>.unmodifiable(_towers.values),
      enemies: List<HexTournamentEnemy>.unmodifiable(_enemies),
      shots: List<HexTournamentShotTrace>.unmodifiable(_shots),
      selectedCellId: _selectedCellId,
      currency: _currency,
      score: _score,
      wave: _wave,
      enemyTier: _enemyTier,
      health: _health,
      maxHealth: maxHealth,
      running: _running,
      paused: _paused,
      waveInProgress: _waveInProgress,
      defeated: _defeated,
      statusLabel: _statusLabel,
      buildCost: buildCost,
      enemyTierCost: enemyTierCost,
      mergeCandidateCount: _selectedMergeCandidates().length,
      flawlessStreak: _flawlessStreak,
      waveLeakDamage: _waveLeakDamage,
    );
  }

  static List<PrototypeAffinity> focusAffinitiesForSeed(int seedPowerIndex) {
    const rotation = <PrototypeAffinity>[
      PrototypeAffinity.ember,
      PrototypeAffinity.flare,
      PrototypeAffinity.solar,
      PrototypeAffinity.verdant,
      PrototypeAffinity.aether,
      PrototypeAffinity.violet,
    ];
    final offset = (seedPowerIndex ~/ 97) % rotation.length;
    return List<PrototypeAffinity>.generate(
      3,
      (index) => rotation[(offset + index) % rotation.length],
      growable: false,
    );
  }

  void reset({int? seedPowerIndex, bool running = false}) {
    if (seedPowerIndex != null && seedPowerIndex != _seedPowerIndex) {
      _configureSeed(seedPowerIndex);
    } else {
      _random = math.Random((_seedPowerIndex * 37) + 1907);
    }
    _resetState(running: running);
  }

  void start({int? seedPowerIndex}) {
    reset(seedPowerIndex: seedPowerIndex, running: true);
    _statusLabel = 'Run live. Send the first wave when the grid is ready.';
  }

  void setPaused(bool paused) {
    if (!_running || _defeated) {
      return;
    }
    _paused = paused;
    _statusLabel = paused ? 'Paused.' : 'Run resumed.';
  }

  bool tapCell(String cellId) {
    final cell = _cellById(cellId);
    if (cell == null) {
      return false;
    }
    if (cell.isPath) {
      _selectedCellId = cellId;
      _statusLabel = 'Path hexes are reserved for enemy waves.';
      return false;
    }

    final tower = _towers[cellId];
    final selectedTower = _selectedTower;
    if (tower != null) {
      if (selectedTower != null &&
          selectedTower.cellId != tower.cellId &&
          _canMerge(selectedTower, tower)) {
        return mergeTowers(selectedTower.cellId, tower.cellId);
      }
      _selectedCellId = cellId;
      _statusLabel = tower.mergeStage >= 2
          ? 'Impact tower selected.'
          : tower.hasPayload
          ? 'Payload tower selected.'
          : 'Base tower selected.';
      return true;
    }

    _selectedCellId = cellId;
    _statusLabel = _running
        ? _currency >= buildCost
              ? 'Open hex selected. Choose a tower to build.'
              : 'Need $buildCost event currency for another tower.'
        : 'Open hex selected.';
    return false;
  }

  bool placeTower(String cellId, {TowerConfig? config}) {
    final cell = _cellById(cellId);
    if (!_running || _paused || cell == null || !cell.canBuild) {
      return false;
    }
    if (_towers.containsKey(cellId) || _currency < buildCost) {
      return false;
    }
    final selectedConfig =
        config ?? TowerLibrary.all[_random.nextInt(TowerLibrary.all.length)];
    final available = TowerLibrary.all.any(
      (candidate) => candidate.id == selectedConfig.id,
    );
    if (!available) {
      return false;
    }
    _currency -= buildCost;
    final tower = HexTournamentTower(
      id: 'hex_tower_${_towerCounter++}',
      cellId: cellId,
      q: cell.q,
      r: cell.r,
      config: selectedConfig,
      affinity: selectedConfig.affinity,
      projectileType: selectedConfig.defaultProjectileType,
      candidatePayload: _rollPayloadFor(selectedConfig.affinity),
      candidateImpactProjectile: _rollImpactProjectileFor(
        selectedConfig.affinity,
      ),
      weeklyFocus: _focusAffinities.contains(selectedConfig.affinity),
    );
    _towers[cellId] = tower;
    _selectedCellId = cellId;
    _statusLabel = '${selectedConfig.name} placed.';
    return true;
  }

  bool mergeSelectedWithBestCandidate() {
    final selectedTower = _selectedTower;
    if (selectedTower == null) {
      return false;
    }
    final candidates = _selectedMergeCandidates();
    if (candidates.isEmpty) {
      return false;
    }
    candidates.sort((left, right) {
      final leftDistance = _axialDistance(
        selectedTower.q.toDouble(),
        selectedTower.r.toDouble(),
        left.q.toDouble(),
        left.r.toDouble(),
      );
      final rightDistance = _axialDistance(
        selectedTower.q.toDouble(),
        selectedTower.r.toDouble(),
        right.q.toDouble(),
        right.r.toDouble(),
      );
      return leftDistance.compareTo(rightDistance);
    });
    return mergeTowers(selectedTower.cellId, candidates.first.cellId);
  }

  bool mergeTowers(String keeperCellId, String consumedCellId) {
    if (!_running || _paused) {
      return false;
    }
    final keeper = _towers[keeperCellId];
    final consumed = _towers[consumedCellId];
    if (keeper == null || consumed == null || !_canMerge(keeper, consumed)) {
      return false;
    }

    final nextStage = keeper.mergeStage + 1;
    late HexTournamentTower merged;
    if (nextStage == 1) {
      final payload = _random.nextBool()
          ? keeper.candidatePayload
          : consumed.candidatePayload;
      merged = keeper.copyWith(
        payloadType: payload,
        mergeStage: nextStage,
        cooldownRemaining: 0,
      );
      _statusLabel = '${payload.label} payload merged into the tower.';
    } else {
      final payload = _random.nextBool()
          ? keeper.payloadType
          : consumed.payloadType;
      final impactProjectile = _random.nextBool()
          ? keeper.candidateImpactProjectile
          : consumed.candidateImpactProjectile;
      merged = keeper.copyWith(
        payloadType: payload,
        impactProjectileType: impactProjectile,
        mergeStage: nextStage,
        cooldownRemaining: 0,
      );
      _statusLabel = '${impactProjectile.label} impact projectile added.';
    }

    _towers
      ..remove(consumedCellId)
      ..[keeperCellId] = merged;
    _selectedCellId = keeperCellId;
    _score += 12 + (nextStage * 10);
    return true;
  }

  bool setSelectedTowerTargetPriority(TargetPriority priority) {
    final selectedTower = _selectedTower;
    if (selectedTower == null) {
      return false;
    }
    _towers[selectedTower.cellId] = selectedTower.copyWith(
      targetPriority: priority,
    );
    _statusLabel = '${priority.label} targeting selected.';
    return true;
  }

  bool sendWave() {
    if (!_running || _paused || _waveInProgress || _defeated) {
      return false;
    }
    _wave += 1;
    _waveInProgress = true;
    _waveLeakDamage = 0;
    final count = math.min(18, 4 + _wave + _enemyTier);
    for (var index = 0; index < count; index += 1) {
      _enemies.add(_createEnemy(index));
    }
    _statusLabel = 'Wave $_wave sent.';
    return true;
  }

  bool buyEnemyTier() {
    if (!_running ||
        _paused ||
        _waveInProgress ||
        _currency < enemyTierCost ||
        _defeated) {
      return false;
    }
    _currency -= enemyTierCost;
    _enemyTier += 1;
    _statusLabel = 'Enemy tier increased. Future kills score higher.';
    return true;
  }

  bool retire() {
    if (!_running || _defeated) {
      return false;
    }
    _running = false;
    _paused = false;
    _waveInProgress = false;
    _statusLabel = 'Run retired.';
    return true;
  }

  void tick(double dt) {
    if (dt <= 0) {
      return;
    }
    _updateShotTraces(dt);
    if (!_running || _paused || _defeated) {
      return;
    }
    final clamped = dt.clamp(0.0, 0.05).toDouble();
    _advanceEnemies(clamped);
    _advanceTowers(clamped);
    if (_waveInProgress && _enemies.isEmpty && !_defeated) {
      _waveInProgress = false;
      final flawless = _waveLeakDamage == 0;
      _flawlessStreak = flawless ? _flawlessStreak + 1 : 0;
      final focusTowerCount = _towers.values
          .where((tower) => tower.weeklyFocus)
          .length;
      final flawlessBonus = flawless ? 16 + (_flawlessStreak * 8) : 0;
      final focusBonus = focusTowerCount * 4;
      final clearBonus = 18 + (_wave * 4) + (_enemyTier * 3);
      _currency += clearBonus + flawlessBonus + focusBonus;
      _score += (clearBonus * 2) + (flawlessBonus * 4) + (focusBonus * 3);
      _statusLabel = flawless
          ? 'Wave $_wave flawless. Streak x$_flawlessStreak.'
          : 'Wave $_wave cleared after $_waveLeakDamage core damage.';
    }
  }

  void _configureSeed(int seedPowerIndex) {
    _seedPowerIndex = seedPowerIndex;
    _random = math.Random((seedPowerIndex * 37) + 1907);
    _focusAffinities = focusAffinitiesForSeed(seedPowerIndex);
    _cells = _buildCells();
    _pathCells = _cells.where((cell) => cell.isPath).toList(growable: false)
      ..sort((left, right) => left.pathIndex!.compareTo(right.pathIndex!));
  }

  void _resetState({required bool running}) {
    _towers.clear();
    _enemies.clear();
    _shots.clear();
    _selectedCellId = null;
    _currency = startingCurrency;
    _score = 0;
    _wave = 0;
    _enemyTier = 1;
    _health = maxHealth;
    _towerCounter = 0;
    _enemyCounter = 0;
    _shotCounter = 0;
    _flawlessStreak = 0;
    _waveLeakDamage = 0;
    _running = running;
    _paused = false;
    _waveInProgress = false;
    _defeated = false;
    _statusLabel = running ? 'Run live.' : 'Event ready.';
  }

  List<HexTournamentCell> _buildCells() {
    final pathById = <String, int>{
      for (var index = 0; index < _pathCoordinates.length; index += 1)
        '${_pathCoordinates[index].$1}:${_pathCoordinates[index].$2}': index,
    };
    final cells = <HexTournamentCell>[];
    for (var q = -boardRadius; q <= boardRadius; q += 1) {
      final minR = math.max(-boardRadius, -q - boardRadius);
      final maxR = math.min(boardRadius, -q + boardRadius);
      for (var r = minR; r <= maxR; r += 1) {
        cells.add(HexTournamentCell(q: q, r: r, pathIndex: pathById['$q:$r']));
      }
    }
    return List<HexTournamentCell>.unmodifiable(cells);
  }

  HexTournamentCell? _cellById(String cellId) {
    for (final cell in _cells) {
      if (cell.id == cellId) {
        return cell;
      }
    }
    return null;
  }

  HexTournamentTower? get _selectedTower {
    final selectedCellId = _selectedCellId;
    if (selectedCellId == null) {
      return null;
    }
    return _towers[selectedCellId];
  }

  List<HexTournamentTower> _selectedMergeCandidates() {
    final selectedTower = _selectedTower;
    if (selectedTower == null) {
      return const <HexTournamentTower>[];
    }
    return _towers.values
        .where((tower) => _canMerge(selectedTower, tower))
        .toList(growable: false);
  }

  bool _canMerge(HexTournamentTower left, HexTournamentTower right) {
    return left.cellId != right.cellId &&
        left.config.id == right.config.id &&
        left.mergeStage == right.mergeStage &&
        left.mergeStage < 2;
  }

  HexTournamentEnemy _createEnemy(int waveIndex) {
    final focus =
        _focusAffinities[(_wave + _enemyTier + waveIndex) %
            _focusAffinities.length];
    final rarity =
        EnemyCardRarity.values[math.min(
          EnemyCardRarity.values.length - 1,
          (_enemyTier - 1) ~/ 2,
        )];
    final config = EnemyLibrary.all.firstWhere(
      (entry) =>
          !entry.isBoss && entry.affinity == focus && entry.rarity == rarity,
      orElse: () => EnemyLibrary.all.firstWhere(
        (entry) => !entry.isBoss && entry.affinity == focus,
        orElse: () => EnemyLibrary.basicWhite,
      ),
    );
    final health =
        44 +
        (_wave * 18) +
        (_enemyTier * 28) +
        (math.pow(_wave, 1.18).toDouble() * 7) +
        (waveIndex % 4) * 6;
    final scoreValue =
        36 + (_wave * 14) + (_enemyTier * 34) + (waveIndex % 3) * 8;
    return HexTournamentEnemy(
      id: 'hex_enemy_${_enemyCounter++}',
      wave: _wave,
      tier: _enemyTier,
      config: config,
      affinity: focus,
      progress: -waveIndex * 0.24,
      health: health.toDouble(),
      maxHealth: health.toDouble(),
      speed: 0.40 + (_wave * 0.014) + (_enemyTier * 0.018),
      currencyReward: 7 + _enemyTier + (_wave ~/ 2),
      scoreValue: scoreValue,
      damage: 1 + (_enemyTier ~/ 4),
    );
  }

  void _advanceEnemies(double dt) {
    final pathEnd = (_pathCells.length - 1).toDouble();
    final survivors = <HexTournamentEnemy>[];
    var leakedDamage = 0;
    for (final enemy in _enemies) {
      final nextProgress = enemy.progress + (enemy.speed * dt);
      if (nextProgress >= pathEnd) {
        leakedDamage += enemy.damage;
      } else {
        survivors.add(enemy.copyWith(progress: nextProgress));
      }
    }
    _enemies
      ..clear()
      ..addAll(survivors);
    if (leakedDamage > 0) {
      _waveLeakDamage += leakedDamage;
      _flawlessStreak = 0;
      _health = math.max(0, _health - leakedDamage);
      _statusLabel = 'Core took $leakedDamage damage.';
      if (_health <= 0) {
        _defeated = true;
        _running = false;
        _paused = false;
        _waveInProgress = false;
        _enemies.clear();
        _statusLabel = 'Core broke on wave $_wave.';
      }
    }
  }

  void _advanceTowers(double dt) {
    for (final entry in _towers.entries.toList(growable: false)) {
      var tower = entry.value.copyWith(
        cooldownRemaining: math.max(0.0, entry.value.cooldownRemaining - dt),
      );
      if (tower.cooldownRemaining <= 0) {
        final target = _targetFor(tower);
        if (target != null) {
          _fireTowerAt(tower, target);
          tower = tower.copyWith(cooldownRemaining: tower.cooldownSeconds);
        }
      }
      _towers[entry.key] = tower;
    }
  }

  HexTournamentEnemy? _targetFor(HexTournamentTower tower) {
    final candidates = _enemies
        .where((enemy) {
          if (!enemy.isOnBoard || enemy.health <= 0) {
            return false;
          }
          final position = _enemyAxialPosition(enemy.progress);
          final distance = _axialDistance(
            tower.q.toDouble(),
            tower.r.toDouble(),
            position.$1,
            position.$2,
          );
          return distance <= tower.range;
        })
        .toList(growable: false);
    if (candidates.isEmpty) {
      return null;
    }
    return candidates.reduce((left, right) {
      return switch (tower.targetPriority) {
        TargetPriority.close => right.progress > left.progress ? right : left,
        TargetPriority.strong => right.health > left.health ? right : left,
        TargetPriority.weak => right.health < left.health ? right : left,
      };
    });
  }

  void _fireTowerAt(HexTournamentTower tower, HexTournamentEnemy target) {
    final payloadMultiplier = switch (tower.payloadType.effectProfile) {
      PayloadEffectProfile.none => 1.0,
      PayloadEffectProfile.freeze => 1.08,
      PayloadEffectProfile.shock => 1.16,
      PayloadEffectProfile.knockback => 1.12,
      PayloadEffectProfile.burn => 1.18,
      PayloadEffectProfile.bounty => 1.10,
    };
    _addShotTrace(
      tower: tower,
      targetProgress: target.progress,
      projectileType: tower.projectileType,
      payloadType: tower.payloadType,
      secondary: false,
    );
    _damageEnemy(target.id, tower.damage * payloadMultiplier);
    final impactProjectile = tower.impactProjectileType;
    if (impactProjectile != null) {
      final secondaryTarget = _secondaryTargetNear(target);
      if (secondaryTarget != null) {
        _addShotTrace(
          tower: tower,
          targetProgress: secondaryTarget.progress,
          projectileType: impactProjectile,
          payloadType: tower.payloadType,
          secondary: true,
        );
        _damageEnemy(secondaryTarget.id, tower.damage * 0.52);
      }
    }
  }

  HexTournamentEnemy? _secondaryTargetNear(HexTournamentEnemy primary) {
    final primaryPosition = _enemyAxialPosition(primary.progress);
    HexTournamentEnemy? best;
    var bestDistance = double.infinity;
    for (final enemy in _enemies) {
      if (enemy.id == primary.id || !enemy.isOnBoard || enemy.health <= 0) {
        continue;
      }
      final position = _enemyAxialPosition(enemy.progress);
      final distance = _axialDistance(
        primaryPosition.$1,
        primaryPosition.$2,
        position.$1,
        position.$2,
      );
      if (distance <= 1.45 && distance < bestDistance) {
        best = enemy;
        bestDistance = distance;
      }
    }
    return best;
  }

  bool _damageEnemy(String enemyId, double damage) {
    final index = _enemies.indexWhere((enemy) => enemy.id == enemyId);
    if (index < 0) {
      return false;
    }
    final enemy = _enemies[index];
    final nextHealth = enemy.health - damage;
    if (nextHealth > 0) {
      _enemies[index] = enemy.copyWith(health: nextHealth);
      return false;
    }
    _enemies.removeAt(index);
    _currency += enemy.currencyReward;
    _score += enemy.scoreValue;
    _statusLabel = 'Enemy defeated. +${enemy.currencyReward} currency.';
    return true;
  }

  void _addShotTrace({
    required HexTournamentTower tower,
    required double targetProgress,
    required ProjectileType projectileType,
    required PayloadType payloadType,
    required bool secondary,
  }) {
    _shots.add(
      HexTournamentShotTrace(
        id: 'hex_shot_${_shotCounter++}',
        sourceCellId: tower.cellId,
        targetProgress: targetProgress,
        projectileType: projectileType,
        payloadType: payloadType,
        progress: 0,
        secondary: secondary,
      ),
    );
  }

  void _updateShotTraces(double dt) {
    _shots
      ..clear()
      ..addAll(
        _shots
            .map((shot) => shot.copyWith(progress: shot.progress + dt * 3.4))
            .where((shot) => shot.progress < 1)
            .toList(growable: false),
      );
  }

  (double, double) _enemyAxialPosition(double progress) {
    final clamped = progress.clamp(0.0, (_pathCells.length - 1).toDouble());
    final lower = clamped.floor();
    final upper = math.min(_pathCells.length - 1, lower + 1);
    final t = clamped - lower;
    final a = _pathCells[lower];
    final b = _pathCells[upper];
    return (a.q + ((b.q - a.q) * t), a.r + ((b.r - a.r) * t));
  }

  double _axialDistance(double q1, double r1, double q2, double r2) {
    final s1 = -q1 - r1;
    final s2 = -q2 - r2;
    return ((q1 - q2).abs() + (r1 - r2).abs() + (s1 - s2).abs()) / 2;
  }

  PayloadType _rollPayloadFor(PrototypeAffinity affinity) {
    final pool = switch (affinity) {
      PrototypeAffinity.ember => const <PayloadType>[
        PayloadType.overheat,
        PayloadType.detonate,
      ],
      PrototypeAffinity.flare => const <PayloadType>[
        PayloadType.rend,
        PayloadType.force,
      ],
      PrototypeAffinity.solar => const <PayloadType>[
        PayloadType.shock,
        PayloadType.disrupt,
      ],
      PrototypeAffinity.verdant => const <PayloadType>[
        PayloadType.corrupt,
        PayloadType.spread,
      ],
      PrototypeAffinity.aether => const <PayloadType>[
        PayloadType.chill,
        PayloadType.fracture,
      ],
      PrototypeAffinity.violet => const <PayloadType>[
        PayloadType.expose,
        PayloadType.pull,
      ],
      PrototypeAffinity.neutral || PrototypeAffinity.black =>
        const <PayloadType>[PayloadType.precision, PayloadType.doubleTap],
    };
    return pool[_random.nextInt(pool.length)];
  }

  ProjectileType _rollImpactProjectileFor(PrototypeAffinity affinity) {
    final pool = switch (affinity) {
      PrototypeAffinity.ember => const <ProjectileType>[
        ProjectileType.pulseBomb,
        ProjectileType.clusterBomb,
      ],
      PrototypeAffinity.flare => const <ProjectileType>[
        ProjectileType.breakerShot,
        ProjectileType.crushShot,
      ],
      PrototypeAffinity.solar => const <ProjectileType>[
        ProjectileType.forkArc,
        ProjectileType.arcNode,
      ],
      PrototypeAffinity.verdant => const <ProjectileType>[
        ProjectileType.sweepNode,
        ProjectileType.slingNode,
      ],
      PrototypeAffinity.aether => const <ProjectileType>[
        ProjectileType.pulseBeam,
        ProjectileType.splitBeam,
      ],
      PrototypeAffinity.violet => const <ProjectileType>[
        ProjectileType.echoRing,
        ProjectileType.collapseRing,
      ],
      PrototypeAffinity.neutral ||
      PrototypeAffinity.black => const <ProjectileType>[
        ProjectileType.rapidBolt,
        ProjectileType.twinBolt,
      ],
    };
    return pool[_random.nextInt(pool.length)];
  }
}
