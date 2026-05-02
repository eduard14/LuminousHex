part of '../daily_dungeons_screen.dart';

class _DungeonRunResult {
  const _DungeonRunResult({required this.cleared});

  final bool cleared;
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
    switch (widget.route) {
      case _DailyDungeonBattleRoute.threatDirector:
        _battleController.configureThreatDirectorDungeonBattle(
          towerLevel: widget.towerLevel,
          enemyDraft: widget.anomalyCards,
          bossDraft: widget.apexCard,
        );
        break;
      case _DailyDungeonBattleRoute.prismRift:
        _battleController.configurePrismRiftDungeonBattleFromHomeTower(
          source: widget.controller,
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

  bool get _isPrismRift => widget.route == _DailyDungeonBattleRoute.prismRift;

  double get _timeProgress =>
      (_remainingSeconds / _timeLimit.inSeconds).clamp(0.0, 1.0).toDouble();

  double get _coreIntegrity =>
      (_battleController.coreState.coreStability / 100).clamp(0.0, 1.0);

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
