part of '../daily_dungeons_screen.dart';

class _PrismRiftDungeonRunScreen extends StatefulWidget {
  const _PrismRiftDungeonRunScreen({
    required this.controller,
    required this.towerLevel,
  });

  final LightcoreController controller;
  final int towerLevel;

  @override
  State<_PrismRiftDungeonRunScreen> createState() =>
      _PrismRiftDungeonRunScreenState();
}

class _PrismRiftDungeonRunScreenState
    extends State<_PrismRiftDungeonRunScreen> {
  static const Duration _timeLimit = Duration(seconds: 45);

  late final LightcoreDailyDungeonTowerProfile _towerProfile;
  late final ValueNotifier<_PrismRiftRunSnapshot> _snapshotNotifier;
  late final _PrismRiftDungeonGame _game;
  bool _resultHandled = false;

  @override
  void initState() {
    super.initState();
    _towerProfile = widget.controller.dailyDungeonTowerProfileForLevel(
      widget.towerLevel,
    );
    _snapshotNotifier = ValueNotifier<_PrismRiftRunSnapshot>(
      _PrismRiftRunSnapshot.initial(
        riftMaxStability: _prismRiftMaxStabilityFor(_towerProfile),
        remainingSeconds: _timeLimit.inSeconds.toDouble(),
      ),
    );
    _game = _PrismRiftDungeonGame(
      controller: widget.controller,
      towerProfile: _towerProfile,
      timeLimit: _timeLimit,
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
      body: ValueListenableBuilder<_PrismRiftRunSnapshot>(
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
                        Color(0xFF201D3C),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GameWidget<_PrismRiftDungeonGame>(game: _game),
                      ),
                      Positioned(
                        top: compact ? 8 : 12,
                        left: compact ? 10 : 16,
                        right: compact ? 10 : 16,
                        child: _PrismRiftRunTopBar(
                          towerProfile: _towerProfile,
                          towerLevel: widget.towerLevel,
                          remainingSeconds: snapshot.remainingSeconds,
                          timeProgress: snapshot.timeProgress,
                          riftStability: snapshot.riftStability,
                          riftMaxStability: snapshot.riftMaxStability,
                          riftIntegrity: snapshot.riftIntegrity,
                          onExit: _exitRun,
                        ),
                      ),
                      Positioned(
                        left: compact ? 10 : 16,
                        right: compact ? 10 : 16,
                        bottom: compact ? 8 : 12,
                        child: _PrismRiftStatusDock(
                          snapshot: snapshot,
                          compact: compact,
                          tint: _towerProfile.affinity.color,
                          onAimChanged: _game.handleAimDirection,
                          onFire: _game.fireManualShotFromAim,
                        ),
                      ),
                      if (!snapshot.running)
                        Positioned.fill(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: _PrismRiftResultPanel(
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
        ? 'Prism Rift Lv ${widget.towerLevel} stabilized: ${reward.label}. Lv $nextLevel unlocked.'
        : 'Prism Rift Lv ${widget.towerLevel} stabilized. Lv $nextLevel is ready.';
    widget.controller.pushNotification(
      cleared
          ? clearMessage
          : 'Prism Rift Lv ${widget.towerLevel} collapsed. Upgrade the tower ladder before the next run.',
      duration: 3.2,
    );
  }
}

class _PrismRiftRunSnapshot {
  const _PrismRiftRunSnapshot({
    required this.remainingSeconds,
    required this.riftStability,
    required this.riftMaxStability,
    required this.charge,
    required this.heat,
    required this.combo,
    required this.wave,
    required this.activeShards,
    required this.aiming,
    required this.running,
    required this.victory,
    required this.expired,
  });

  factory _PrismRiftRunSnapshot.initial({
    required double riftMaxStability,
    required double remainingSeconds,
  }) {
    return _PrismRiftRunSnapshot(
      remainingSeconds: remainingSeconds,
      riftStability: riftMaxStability,
      riftMaxStability: riftMaxStability,
      charge: 1,
      heat: 0,
      combo: 0,
      wave: 1,
      activeShards: 0,
      aiming: false,
      running: true,
      victory: false,
      expired: false,
    );
  }

  final double remainingSeconds;
  final double riftStability;
  final double riftMaxStability;
  final double charge;
  final double heat;
  final int combo;
  final int wave;
  final int activeShards;
  final bool aiming;
  final bool running;
  final bool victory;
  final bool expired;

  double get riftIntegrity => riftMaxStability <= 0
      ? 0
      : (riftStability / riftMaxStability).clamp(0.0, 1.0).toDouble();

  double get timeProgress => remainingSeconds <= 0
      ? 0
      : (remainingSeconds /
                _PrismRiftDungeonRunScreenState._timeLimit.inSeconds)
            .clamp(0.0, 1.0)
            .toDouble();
}

class _PrismRiftRunTopBar extends StatelessWidget {
  const _PrismRiftRunTopBar({
    required this.towerProfile,
    required this.towerLevel,
    required this.remainingSeconds,
    required this.timeProgress,
    required this.riftStability,
    required this.riftMaxStability,
    required this.riftIntegrity,
    required this.onExit,
  });

  final LightcoreDailyDungeonTowerProfile towerProfile;
  final int towerLevel;
  final double remainingSeconds;
  final double timeProgress;
  final double riftStability;
  final double riftMaxStability;
  final double riftIntegrity;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = towerProfile.affinity.color;
    return AuroraPanel(
      tint: LightcorePalette.violet,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          _IconBadge(
            icon: Icons.terrain_rounded,
            tint: LightcorePalette.violet,
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
                        'Prism Rift Lv $towerLevel',
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
                        value: riftIntegrity,
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

class _PrismRiftStatusDock extends StatelessWidget {
  const _PrismRiftStatusDock({
    required this.snapshot,
    required this.compact,
    required this.tint,
    required this.onAimChanged,
    required this.onFire,
  });

  final _PrismRiftRunSnapshot snapshot;
  final bool compact;
  final Color tint;
  final ValueChanged<Offset> onAimChanged;
  final VoidCallback onFire;

  @override
  Widget build(BuildContext context) {
    final heatTint = snapshot.heat >= 0.72
        ? LightcorePalette.warning
        : LightcorePalette.solar;
    final canFire =
        snapshot.running && snapshot.charge >= 1 && snapshot.heat < 0.98;
    return AuroraPanel(
      tint: LightcorePalette.violet,
      radius: 20,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 10,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final aimControls = _PrismRiftAimControls(
            enabled: snapshot.running,
            canFire: canFire,
            tint: tint,
            compact: compact,
            onAimChanged: onAimChanged,
            onFire: onFire,
          );
          final bars = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MeterLabelRow(
                label: 'Charge',
                value: snapshot.charge >= 1
                    ? 'Ready'
                    : '${(snapshot.charge * 100).round()}%',
              ),
              const SizedBox(height: 5),
              MeterBar(value: snapshot.charge, color: tint, height: 9),
              const SizedBox(height: 8),
              _MeterLabelRow(
                label: 'Heat',
                value: '${(snapshot.heat * 100).round()}%',
              ),
              const SizedBox(height: 5),
              MeterBar(value: snapshot.heat, color: heatTint, height: 8),
            ],
          );
          final chips = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.waves_rounded,
                label: 'Wave ${snapshot.wave}',
                tint: LightcorePalette.aether,
              ),
              _InfoChip(
                icon: Icons.track_changes_rounded,
                label: '${snapshot.activeShards} shards',
                tint: LightcorePalette.violet,
              ),
              _InfoChip(
                icon: Icons.local_fire_department_rounded,
                label: '${snapshot.combo} combo',
                tint: LightcorePalette.solar,
              ),
              _InfoChip(
                icon: snapshot.aiming
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                label: snapshot.aiming ? 'Locked' : 'Open',
                tint: snapshot.aiming ? tint : LightcorePalette.stroke,
              ),
            ],
          );

          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                aimControls,
                const SizedBox(height: 10),
                chips,
                const SizedBox(height: 10),
                bars,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: chips),
              const SizedBox(width: 16),
              SizedBox(width: 260, child: bars),
              const SizedBox(width: 16),
              aimControls,
            ],
          );
        },
      ),
    );
  }
}

class _PrismRiftAimControls extends StatelessWidget {
  const _PrismRiftAimControls({
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
        _PrismRiftAimPad(
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
              child: Icon(
                Icons.local_fire_department_rounded,
                size: compact ? 28 : 32,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrismRiftAimPad extends StatefulWidget {
  const _PrismRiftAimPad({
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
  State<_PrismRiftAimPad> createState() => _PrismRiftAimPadState();
}

class _PrismRiftAimPadState extends State<_PrismRiftAimPad> {
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

class _PrismRiftResultPanel extends StatelessWidget {
  const _PrismRiftResultPanel({
    required this.victory,
    required this.towerLevel,
    required this.onExit,
  });

  final bool victory;
  final int towerLevel;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final tint = victory ? LightcorePalette.success : LightcorePalette.warning;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: AuroraPanel(
        tint: tint,
        radius: 22,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(
              icon: victory
                  ? Icons.check_circle_rounded
                  : Icons.timer_off_rounded,
              tint: tint,
            ),
            const SizedBox(height: 12),
            Text(
              victory ? 'Rift Stabilized' : 'Rift Collapsed',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              victory
                  ? 'Prism Rift Lv $towerLevel is stable. The next level is ready from the dungeon menu.'
                  : 'Prism Rift Lv $towerLevel destabilized before the route was cleared.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onExit,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Return to Dungeon Menu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrismRiftPreviewPanel extends StatelessWidget {
  const _PrismRiftPreviewPanel({
    required this.towerProfile,
    required this.towerLevel,
    required this.reward,
    required this.riftStability,
    required this.cleared,
  });

  final LightcoreDailyDungeonTowerProfile towerProfile;
  final int towerLevel;
  final LightcoreDailyDungeonReward reward;
  final double riftStability;
  final bool cleared;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = towerProfile.affinity.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: LightcorePalette.violet.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final stage = _PrismRiftPreviewStage(
              towerProfile: towerProfile,
              towerLevel: towerLevel,
            );
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBadge(icon: Icons.track_changes_rounded, tint: tint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rift Stabilizer', style: textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            cleared
                                ? 'First clear secured'
                                : 'First-clear reward ${reward.label}',
                            style: textTheme.bodySmall?.copyWith(
                              color: LightcorePalette.mist.withValues(
                                alpha: 0.68,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusCapsule(label: 'Lv $towerLevel', tint: tint),
                  ],
                ),
                const SizedBox(height: 14),
                _MeterLabelRow(
                  label: 'Rift Stability',
                  value: riftStability.round().toString(),
                ),
                const SizedBox(height: 6),
                MeterBar(value: 1, color: tint, height: 12),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: towerProjectileIcon(towerProfile.projectileType),
                      label: towerProfile.projectileType.label,
                      tint: tint,
                    ),
                    _InfoChip(
                      icon: Icons.bolt_rounded,
                      label: '${towerProfile.shotDamage.round()} base shot',
                      tint: LightcorePalette.aether,
                    ),
                    _InfoChip(
                      icon: Icons.adjust_rounded,
                      label: '${towerProfile.affinity.shortLabel} affinity',
                      tint: tint,
                    ),
                  ],
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [stage, const SizedBox(height: 14), details],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 280, child: stage),
                const SizedBox(width: 18),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PrismRiftPreviewStage extends StatelessWidget {
  const _PrismRiftPreviewStage({
    required this.towerProfile,
    required this.towerLevel,
  });

  final LightcoreDailyDungeonTowerProfile towerProfile;
  final int towerLevel;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.35,
      child: CustomPaint(
        painter: _PrismRiftPreviewPainter(
          towerProfile: towerProfile,
          towerLevel: towerLevel,
        ),
      ),
    );
  }
}

class _PrismRiftPreviewPainter extends CustomPainter {
  const _PrismRiftPreviewPainter({
    required this.towerProfile,
    required this.towerLevel,
  });

  final LightcoreDailyDungeonTowerProfile towerProfile;
  final int towerLevel;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height / 2);
    final shortest = math.min(size.width, size.height);
    final tint = towerProfile.affinity.color;
    canvas.drawRect(
      rect,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                LightcorePalette.violet.withValues(alpha: 0.16),
                LightcorePalette.night.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: shortest * 0.62),
            ),
    );
    for (var index = 0; index < 3; index += 1) {
      canvas.drawCircle(
        center,
        shortest * (0.22 + (index * 0.13)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = LightcorePalette.violet.withValues(alpha: 0.22),
      );
    }
    final shardPaint = Paint()..color = LightcorePalette.violet;
    for (var index = 0; index < 6; index += 1) {
      final angle = (-math.pi / 2) + (index * math.pi / 3);
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * shortest * 0.36;
      canvas.drawPath(_hexPath(position, shortest * 0.04), shardPaint);
      canvas.drawCircle(
        position +
            Offset(math.cos(angle + 1.2), math.sin(angle + 1.2)) *
                shortest *
                0.033,
        shortest * 0.012,
        Paint()..color = LightcorePalette.solar,
      );
    }
    _drawGlowLine(
      canvas,
      center,
      center.translate(shortest * 0.22, -shortest * 0.2),
      tint,
      width: 3.2,
    );
    canvas.drawPath(
      _hexPath(center, shortest * 0.11),
      Paint()..color = tint.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      _hexPath(center, shortest * 0.11),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = tint,
    );
    _paintIconGlyph(
      canvas,
      center,
      towerProjectileIcon(towerProfile.projectileType),
      size: shortest * 0.08,
      color: tint,
    );
  }

  void _drawGlowLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color, {
    required double width,
  }) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..strokeWidth = width + 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = color.withValues(alpha: 0.18),
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.82),
    );
  }

  void _paintIconGlyph(
    Canvas canvas,
    Offset center,
    IconData icon, {
    required double size,
    required Color color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: color,
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center.translate(-painter.width / 2, -painter.height / 2),
    );
  }

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (var index = 0; index < 6; index += 1) {
      final angle = (math.pi / 6) + (index * math.pi / 3);
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _PrismRiftPreviewPainter oldDelegate) {
    return oldDelegate.towerProfile != towerProfile ||
        oldDelegate.towerLevel != towerLevel;
  }
}
