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
