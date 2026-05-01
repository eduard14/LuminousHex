part of '../tournament_screen.dart';

class _TournamentBattleStage extends StatelessWidget {
  const _TournamentBattleStage({
    required this.controller,
    required this.active,
  });

  final LightcoreController controller;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BattleScreen(
        controller: controller,
        isActive: active,
        showQuestPanel: false,
        showBattleHud: false,
      ),
    );
  }
}

class _ArenaFlowDuelStage extends StatefulWidget {
  const _ArenaFlowDuelStage({
    required this.playerLabel,
    required this.rivalLabel,
    required this.playerTowerLabel,
    required this.rivalTowerLabel,
    required this.playerTowerAffinity,
    required this.rivalTowerAffinity,
    required this.playerEnemyAffinity,
    required this.rivalEnemyAffinity,
    required this.playerEnemyProgress,
    required this.rivalEnemyProgress,
    required this.playerTowerIntegrity,
    required this.rivalTowerIntegrity,
    required this.playerNetDamage,
    required this.rivalNetDamage,
    required this.active,
  });

  final String playerLabel;
  final String rivalLabel;
  final String playerTowerLabel;
  final String rivalTowerLabel;
  final PrototypeAffinity playerTowerAffinity;
  final PrototypeAffinity rivalTowerAffinity;
  final PrototypeAffinity playerEnemyAffinity;
  final PrototypeAffinity rivalEnemyAffinity;
  final double playerEnemyProgress;
  final double rivalEnemyProgress;
  final double playerTowerIntegrity;
  final double rivalTowerIntegrity;
  final double playerNetDamage;
  final double rivalNetDamage;
  final bool active;

  @override
  State<_ArenaFlowDuelStage> createState() => _ArenaFlowDuelStageState();
}

class _ArenaFlowDuelStageState extends State<_ArenaFlowDuelStage> {
  static const double _minMapScale = 0.78;
  static const double _maxMapScale = 1.28;
  static const double _maxPanX = 170;
  static const double _maxPanY = 135;

  Offset _mapPan = Offset.zero;
  double _mapScale = 1;
  Offset? _lastFocalPoint;
  double _lastScaleSignal = 1;

  void _handleScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _lastScaleSignal = 1;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final previousFocalPoint = _lastFocalPoint;
    if (previousFocalPoint == null) {
      _lastFocalPoint = details.focalPoint;
      _lastScaleSignal = details.scale.clamp(0.01, double.infinity).toDouble();
      return;
    }

    final scaleSignal = details.scale.clamp(0.01, double.infinity).toDouble();
    final scaleDelta = scaleSignal / _lastScaleSignal;
    final focalDelta = details.focalPoint - previousFocalPoint;
    setState(() {
      _mapScale = (_mapScale * scaleDelta)
          .clamp(_minMapScale, _maxMapScale)
          .toDouble();
      _mapPan = _clampMapPan(_mapPan + (focalDelta / _mapScale));
    });
    _lastFocalPoint = details.focalPoint;
    _lastScaleSignal = scaleSignal;
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _lastFocalPoint = null;
    _lastScaleSignal = 1;
  }

  Offset _clampMapPan(Offset pan) {
    return Offset(
      pan.dx.clamp(-_maxPanX, _maxPanX).toDouble(),
      pan.dy.clamp(-_maxPanY, _maxPanY).toDouble(),
    );
  }

  void _resetMapView() {
    setState(() {
      _mapPan = Offset.zero;
      _mapScale = 1;
      _lastFocalPoint = null;
      _lastScaleSignal = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: _resetMapView,
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      child: CustomPaint(
        painter: _ArenaFlowDuelPainter(
          textDirection: Directionality.of(context),
          playerLabel: widget.playerLabel,
          rivalLabel: widget.rivalLabel,
          playerTowerLabel: widget.playerTowerLabel,
          rivalTowerLabel: widget.rivalTowerLabel,
          playerTowerAffinity: widget.playerTowerAffinity,
          rivalTowerAffinity: widget.rivalTowerAffinity,
          playerEnemyAffinity: widget.playerEnemyAffinity,
          rivalEnemyAffinity: widget.rivalEnemyAffinity,
          playerEnemyProgress: widget.playerEnemyProgress,
          rivalEnemyProgress: widget.rivalEnemyProgress,
          playerTowerIntegrity: widget.playerTowerIntegrity,
          rivalTowerIntegrity: widget.rivalTowerIntegrity,
          playerNetDamage: widget.playerNetDamage,
          rivalNetDamage: widget.rivalNetDamage,
          active: widget.active,
          mapPan: _mapPan,
          mapScale: _mapScale,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ArenaFlowDuelPainter extends CustomPainter {
  const _ArenaFlowDuelPainter({
    required this.textDirection,
    required this.playerLabel,
    required this.rivalLabel,
    required this.playerTowerLabel,
    required this.rivalTowerLabel,
    required this.playerTowerAffinity,
    required this.rivalTowerAffinity,
    required this.playerEnemyAffinity,
    required this.rivalEnemyAffinity,
    required this.playerEnemyProgress,
    required this.rivalEnemyProgress,
    required this.playerTowerIntegrity,
    required this.rivalTowerIntegrity,
    required this.playerNetDamage,
    required this.rivalNetDamage,
    required this.active,
    required this.mapPan,
    required this.mapScale,
  });

  final TextDirection textDirection;
  final String playerLabel;
  final String rivalLabel;
  final String playerTowerLabel;
  final String rivalTowerLabel;
  final PrototypeAffinity playerTowerAffinity;
  final PrototypeAffinity rivalTowerAffinity;
  final PrototypeAffinity playerEnemyAffinity;
  final PrototypeAffinity rivalEnemyAffinity;
  final double playerEnemyProgress;
  final double rivalEnemyProgress;
  final double playerTowerIntegrity;
  final double rivalTowerIntegrity;
  final double playerNetDamage;
  final double rivalNetDamage;
  final bool active;
  final Offset mapPan;
  final double mapScale;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            LightcorePalette.night,
            LightcorePalette.abyss,
            Color(0xFF241B35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final splitX = size.width / 2;
    final leftView = Rect.fromLTRB(0, 0, splitX, size.height);
    final rightView = Rect.fromLTRB(splitX, 0, size.width, size.height);

    _drawBattleView(
      canvas,
      leftView,
      label: playerLabel,
      towerLabel: playerTowerLabel,
      towerColor: playerTowerAffinity.color,
      enemyColor: rivalEnemyAffinity.color,
      enemyProgress: rivalEnemyProgress,
      integrity: playerTowerIntegrity,
      netDamage: playerNetDamage,
      mirrored: false,
    );
    _drawBattleView(
      canvas,
      rightView,
      label: rivalLabel,
      towerLabel: rivalTowerLabel,
      towerColor: rivalTowerAffinity.color,
      enemyColor: playerEnemyAffinity.color,
      enemyProgress: playerEnemyProgress,
      integrity: rivalTowerIntegrity,
      netDamage: rivalNetDamage,
      mirrored: true,
    );

    _drawWinningSpine(canvas, size, splitX);
  }

  void _drawBattleView(
    Canvas canvas,
    Rect view, {
    required String label,
    required String towerLabel,
    required Color towerColor,
    required Color enemyColor,
    required double enemyProgress,
    required double integrity,
    required double netDamage,
    required bool mirrored,
  }) {
    canvas.save();
    canvas.clipRect(view);
    canvas.drawRect(
      view,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(LightcorePalette.night, towerColor, 0.08)!,
            LightcorePalette.abyss,
            Color.lerp(LightcorePalette.abyss, enemyColor, 0.16)!,
          ],
          begin: mirrored ? Alignment.topRight : Alignment.topLeft,
          end: mirrored ? Alignment.bottomLeft : Alignment.bottomRight,
        ).createShader(view),
    );

    final shortest = min(view.width, view.height);
    final center = Offset(
      view.center.dx,
      view.center.dy + (view.height < 640 ? shortest * 0.04 : 0),
    );
    final arenaRadius = min(view.width * 0.47, view.height * 0.34);
    final spawnRadius = arenaRadius * 0.92;
    final relayRadius = arenaRadius * 0.48;
    final coreRadius = max(18.0, shortest * 0.08);
    final slotRadius = max(10.0, shortest * 0.036);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(mapScale);
    canvas.translate(mapPan.dx, mapPan.dy);
    _drawBattleGrid(
      canvas,
      arenaRadius: arenaRadius,
      spawnRadius: spawnRadius,
      relayRadius: relayRadius,
      towerColor: towerColor,
      enemyColor: enemyColor,
    );
    _drawRelayRing(
      canvas,
      radius: relayRadius,
      slotRadius: slotRadius,
      color: towerColor,
      progress: enemyProgress,
    );
    _drawIncomingEnemies(
      canvas,
      radius: spawnRadius,
      targetRadius: coreRadius * 1.42,
      color: enemyColor,
      progress: enemyProgress,
      mirrored: mirrored,
    );
    _drawTowerSlots(
      canvas,
      radius: relayRadius,
      slotRadius: slotRadius,
      color: towerColor,
      supportColor: enemyColor,
      progress: enemyProgress,
    );
    _drawCoreTower(
      canvas,
      radius: coreRadius,
      color: towerColor,
      integrity: integrity,
      progress: enemyProgress,
    );
    canvas.restore();

    _drawViewLabels(
      canvas,
      view,
      label: label,
      towerLabel: towerLabel,
      color: towerColor,
      netDamage: netDamage,
      alignRight: mirrored,
    );
    canvas.restore();
  }

  void _drawBattleGrid(
    Canvas canvas, {
    required double arenaRadius,
    required double spawnRadius,
    required double relayRadius,
    required Color towerColor,
    required Color enemyColor,
  }) {
    final pulseAlpha = active ? 0.08 : 0.035;
    canvas.drawCircle(
      Offset.zero,
      spawnRadius * 1.18,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                towerColor.withValues(alpha: pulseAlpha * 1.7),
                enemyColor.withValues(alpha: pulseAlpha),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: spawnRadius * 1.18),
            ),
    );

    for (final radius in <double>[
      spawnRadius,
      arenaRadius * 0.72,
      relayRadius,
    ]) {
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius == spawnRadius ? 2.2 : 1.2
          ..color = LightcorePalette.stroke.withValues(
            alpha: radius == spawnRadius ? 0.34 : 0.18,
          ),
      );
    }

    for (var index = 0; index < 12; index += 1) {
      final angle = (pi * 2 * index / 12) + (pi / 12);
      final inner = Offset(cos(angle), sin(angle)) * (relayRadius * 0.5);
      final outer = Offset(cos(angle), sin(angle)) * spawnRadius;
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..strokeWidth = 0.8
          ..color = LightcorePalette.stroke.withValues(alpha: 0.12),
      );
    }

    canvas.drawPath(
      _polygon(Offset.zero, relayRadius * 0.62, 6, pi / 6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = LightcorePalette.stroke.withValues(alpha: 0.36),
    );
    canvas.drawPath(
      _polygon(Offset.zero, relayRadius * 0.34, 6, -pi / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = towerColor.withValues(alpha: 0.28),
    );
  }

  void _drawRelayRing(
    Canvas canvas, {
    required double radius,
    required double slotRadius,
    required Color color,
    required double progress,
  }) {
    final pulse = active ? (0.5 + (sin(progress * pi * 2) * 0.5)) : 0.25;
    canvas.drawCircle(
      Offset.zero,
      radius - (slotRadius * 0.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = slotRadius * 0.32
        ..color = LightcorePalette.warning.withValues(
          alpha: 0.045 + (pulse * 0.04),
        ),
    );
    canvas.drawCircle(
      Offset.zero,
      radius - (slotRadius * 0.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = LightcorePalette.warning.withValues(alpha: 0.58),
    );
  }

  void _drawTowerSlots(
    Canvas canvas, {
    required double radius,
    required double slotRadius,
    required Color color,
    required Color supportColor,
    required double progress,
  }) {
    final slotCenters = <Offset>[];
    for (var index = 0; index < 6; index += 1) {
      final angle = -pi / 2 + (index * pi * 2 / 6);
      slotCenters.add(Offset(cos(angle), sin(angle)) * radius);
    }
    for (var index = 0; index < slotCenters.length; index += 1) {
      final current = slotCenters[index];
      final next = slotCenters[(index + 1) % slotCenters.length];
      canvas.drawLine(
        current,
        next,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = LightcorePalette.stroke.withValues(alpha: 0.25),
      );
      canvas.drawLine(
        current,
        Offset.zero,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = color.withValues(alpha: 0.16),
      );
    }

    for (var index = 0; index < slotCenters.length; index += 1) {
      final center = slotCenters[index];
      final slotColor = Color.lerp(
        color,
        supportColor,
        index.isEven ? 0.18 : 0,
      )!;
      final pulse = 0.5 + (sin((progress * pi * 2) + index) * 0.5);
      canvas.drawCircle(
        center,
        slotRadius * (1.9 + (pulse * 0.18)),
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9)
          ..color = slotColor.withValues(alpha: active ? 0.1 : 0.05),
      );
      canvas.drawPath(
        _polygon(center, slotRadius, 6, pi / 6),
        Paint()..color = slotColor.withValues(alpha: 0.15),
      );
      canvas.drawPath(
        _polygon(center, slotRadius, 6, pi / 6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = slotColor.withValues(alpha: active ? 0.74 : 0.42),
      );
      final packetProgress = (progress + (index * 0.12)) % 1.0;
      final packet = Offset.lerp(center, Offset.zero, packetProgress)!;
      canvas.drawCircle(
        packet,
        slotRadius * 0.18,
        Paint()..color = slotColor.withValues(alpha: active ? 0.86 : 0.5),
      );
    }
  }

  void _drawIncomingEnemies(
    Canvas canvas, {
    required double radius,
    required double targetRadius,
    required Color color,
    required double progress,
    required bool mirrored,
  }) {
    final lanes = active ? 12 : 8;
    for (var lane = 0; lane < lanes; lane += 1) {
      final laneAngle =
          (-pi / 2) +
          (lane * pi * 2 / lanes) +
          (mirrored ? pi / lanes : 0) +
          (sin((progress * pi * 2) + lane) * 0.025);
      final start = Offset(cos(laneAngle), sin(laneAngle)) * radius;
      final end = Offset(cos(laneAngle), sin(laneAngle)) * targetRadius;
      canvas.drawLine(
        start,
        end,
        Paint()
          ..strokeWidth = 1
          ..color = color.withValues(alpha: lane.isEven ? 0.14 : 0.08),
      );

      final packetCount = lane.isEven ? 2 : 1;
      for (var packet = 0; packet < packetCount; packet += 1) {
        final staggered = (progress + (lane * 0.071) + (packet * 0.43)) % 1.0;
        final eased = Curves.easeIn.transform(staggered);
        final position = Offset.lerp(start, end, eased)!;
        final packetRadius = 3.6 + ((lane + packet) % 3) * 1.1;
        final tail = Offset.lerp(position, start, 0.14)!;
        canvas.drawLine(
          tail,
          position,
          Paint()
            ..strokeCap = StrokeCap.round
            ..strokeWidth = packetRadius * 0.62
            ..color = color.withValues(alpha: active ? 0.28 : 0.16),
        );
        canvas.drawCircle(
          position,
          packetRadius * 2.4,
          Paint()
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
            ..color = color.withValues(alpha: active ? 0.15 : 0.08),
        );
        canvas.drawPath(
          _polygon(position, packetRadius, 4, laneAngle + (pi / 4)),
          Paint()..color = color.withValues(alpha: active ? 0.92 : 0.56),
        );
        canvas.drawPath(
          _polygon(position, packetRadius, 4, laneAngle + (pi / 4)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = LightcorePalette.mist.withValues(alpha: 0.34),
        );
      }
    }
  }

  void _drawCoreTower(
    Canvas canvas, {
    required double radius,
    required Color color,
    required double integrity,
    required double progress,
  }) {
    final pulse = active ? (0.5 + (sin(progress * pi * 2) * 0.5)) : 0.24;
    canvas.drawCircle(
      Offset.zero,
      radius * 2.1,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
        ..color = color.withValues(alpha: 0.18 + (pulse * 0.05)),
    );
    canvas.drawPath(
      _polygon(Offset.zero, radius * 1.22, 6, -pi / 2),
      Paint()..color = color.withValues(alpha: 0.16),
    );
    canvas.drawPath(
      _polygon(Offset.zero, radius * 1.22, 6, -pi / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = color.withValues(alpha: 0.9),
    );
    canvas.drawPath(
      _polygon(Offset.zero, radius * 0.68, 6, pi / 6),
      Paint()..color = LightcorePalette.abyss.withValues(alpha: 0.78),
    );
    canvas.drawCircle(
      Offset.zero,
      radius * 0.36,
      Paint()..color = LightcorePalette.mist.withValues(alpha: 0.9),
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius * 1.55),
      -pi / 2,
      pi * 2 * integrity.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4
        ..color = color,
    );
    for (var index = 0; index < 6; index += 1) {
      final angle = -pi / 2 + (index * pi * 2 / 6) + (progress * 0.22);
      final inner = Offset(cos(angle), sin(angle)) * (radius * 1.82);
      final outer = Offset(cos(angle), sin(angle)) * (radius * 2.2);
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.54),
      );
    }
  }

  void _drawViewLabels(
    Canvas canvas,
    Rect view, {
    required String label,
    required String towerLabel,
    required Color color,
    required double netDamage,
    required bool alignRight,
  }) {
    final maxWidth = max(48.0, min(180.0, view.width - 30));
    final x = alignRight ? view.right - 16 : view.left + 16;
    final y = view.top + (view.height < 560 ? 82 : 96);
    _drawLabel(
      canvas,
      Offset(x, y),
      label,
      LightcorePalette.mist,
      FontWeight.w900,
      alignRight: alignRight,
      maxWidth: maxWidth,
    );
    _drawLabel(
      canvas,
      Offset(x, y + 17),
      towerLabel,
      color,
      FontWeight.w800,
      alignRight: alignRight,
      small: true,
      maxWidth: maxWidth,
    );
    _drawLabel(
      canvas,
      Offset(x, y + 35),
      'Net ${netDamage.toStringAsFixed(0)}',
      netDamage >= 0 ? LightcorePalette.solar : LightcorePalette.warning,
      FontWeight.w900,
      alignRight: alignRight,
      small: true,
      maxWidth: maxWidth,
    );
  }

  void _drawWinningSpine(Canvas canvas, Size size, double splitX) {
    final lead = playerNetDamage - rivalNetDamage;
    final leadMagnitude = lead.abs();
    final winnerColor = lead >= 0
        ? playerTowerAffinity.color
        : rivalTowerAffinity.color;
    final label = leadMagnitude < 1
        ? 'EVEN'
        : lead > 0
        ? 'YOU +${leadMagnitude.toStringAsFixed(0)}'
        : 'RIVAL +${leadMagnitude.toStringAsFixed(0)}';
    final balanceTotal = max(
      100.0,
      playerNetDamage.abs() + rivalNetDamage.abs(),
    );
    final normalizedLead = (lead / balanceTotal).clamp(-1.0, 1.0).toDouble();

    canvas.drawLine(
      Offset(splitX, 0),
      Offset(splitX, size.height),
      Paint()
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
        ..color = winnerColor.withValues(alpha: active ? 0.2 : 0.1),
    );
    canvas.drawLine(
      Offset(splitX, 0),
      Offset(splitX, size.height),
      Paint()
        ..strokeWidth = 2.4
        ..color = LightcorePalette.mist.withValues(alpha: 0.38),
    );
    canvas.drawLine(
      Offset(splitX, 0),
      Offset(splitX, size.height),
      Paint()
        ..strokeWidth = 1.2
        ..color = winnerColor.withValues(alpha: 0.72),
    );

    final pillWidth = min(216.0, max(132.0, size.width * 0.34));
    const pillHeight = 42.0;
    final pillCenter = Offset(
      splitX,
      size.height * (size.height < 620 ? 0.44 : 0.48),
    );
    final pillRect = Rect.fromCenter(
      center: pillCenter,
      width: pillWidth,
      height: pillHeight,
    );
    final pillRadius = Radius.circular(pillHeight / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, pillRadius),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..color = winnerColor.withValues(alpha: 0.22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, pillRadius),
      Paint()
        ..shader = LinearGradient(
          colors: [
            LightcorePalette.night.withValues(alpha: 0.94),
            Color.lerp(
              LightcorePalette.abyss,
              winnerColor,
              0.22,
            )!.withValues(alpha: 0.94),
          ],
        ).createShader(pillRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, pillRadius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = winnerColor.withValues(alpha: 0.82),
    );

    final track = Rect.fromCenter(
      center: pillCenter.translate(0, 12),
      width: pillWidth - 34,
      height: 5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, const Radius.circular(8)),
      Paint()..color = LightcorePalette.stroke.withValues(alpha: 0.44),
    );
    final trackCenterX = track.center.dx;
    final fillRect = normalizedLead >= 0
        ? Rect.fromLTRB(
            trackCenterX,
            track.top,
            trackCenterX + ((track.width / 2) * normalizedLead.abs()),
            track.bottom,
          )
        : Rect.fromLTRB(
            trackCenterX - ((track.width / 2) * normalizedLead.abs()),
            track.top,
            trackCenterX,
            track.bottom,
          );
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, const Radius.circular(8)),
      Paint()..color = winnerColor.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      Offset(trackCenterX, track.center.dy),
      4.5,
      Paint()..color = LightcorePalette.mist.withValues(alpha: 0.88),
    );
    _drawCenteredLabel(
      canvas,
      pillCenter.translate(0, -9),
      label,
      winnerColor,
      FontWeight.w900,
      maxWidth: pillWidth - 22,
    );
  }

  void _drawCenteredLabel(
    Canvas canvas,
    Offset center,
    String text,
    Color color,
    FontWeight weight, {
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 13, fontWeight: weight),
      ),
      maxLines: 1,
      ellipsis: '...',
      textDirection: textDirection,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth);
    painter.paint(
      canvas,
      center.translate(-painter.width / 2, -painter.height / 2),
    );
  }

  void _drawLabel(
    Canvas canvas,
    Offset anchor,
    String text,
    Color color,
    FontWeight weight, {
    required bool alignRight,
    required double maxWidth,
    bool small = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: small ? 11 : 13,
          fontWeight: weight,
        ),
      ),
      maxLines: 1,
      ellipsis: '...',
      textDirection: textDirection,
    )..layout(maxWidth: maxWidth);
    painter.paint(
      canvas,
      alignRight ? anchor.translate(-painter.width, 0) : anchor,
    );
  }

  Path _polygon(Offset center, double radius, int sides, double rotation) {
    final path = Path();
    for (var index = 0; index < sides; index += 1) {
      final angle = rotation + (index * pi * 2 / sides);
      final point = center + Offset(cos(angle), sin(angle)) * radius;
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
  bool shouldRepaint(covariant _ArenaFlowDuelPainter oldDelegate) {
    return oldDelegate.playerEnemyProgress != playerEnemyProgress ||
        oldDelegate.rivalEnemyProgress != rivalEnemyProgress ||
        oldDelegate.playerTowerIntegrity != playerTowerIntegrity ||
        oldDelegate.rivalTowerIntegrity != rivalTowerIntegrity ||
        oldDelegate.playerNetDamage != playerNetDamage ||
        oldDelegate.rivalNetDamage != rivalNetDamage ||
        oldDelegate.active != active ||
        oldDelegate.mapPan != mapPan ||
        oldDelegate.mapScale != mapScale ||
        oldDelegate.playerLabel != playerLabel ||
        oldDelegate.rivalLabel != rivalLabel ||
        oldDelegate.playerTowerLabel != playerTowerLabel ||
        oldDelegate.rivalTowerLabel != rivalTowerLabel;
  }
}

class _EnemyDraftTile extends StatelessWidget {
  const _EnemyDraftTile({
    required this.card,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.boss = false,
  });

  final EnemyCardState card;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final bool boss;

  @override
  Widget build(BuildContext context) {
    final tint = selected ? accent : card.config.affinity.color;
    return SizedBox(
      width: 118,
      child: SymbolGridTile(
        tint: tint,
        semanticLabel: card.config.name,
        selected: selected,
        onTap: onTap,
        topLeading: SymbolGridBadge(tint: tint, child: Text('Lv${card.level}')),
        topTrailing: boss
            ? SymbolGridBadge(
                tint: tint,
                child: const Icon(Icons.radio_button_checked_rounded, size: 12),
              )
            : null,
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AffinityGlyph(affinity: card.config.affinity, size: 24),
            const SizedBox(height: 6),
            Text(
              card.config.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        bottomChildren: [
          SymbolGridBadge(
            tint: tint,
            child: Text(card.config.rarity.label.substring(0, 3).toUpperCase()),
          ),
        ],
      ),
    );
  }
}

class _HexGauntletPreview extends StatelessWidget {
  const _HexGauntletPreview({
    required this.laneIntegrity,
    required this.coreIntegrity,
    required this.builtLanes,
    required this.tint,
    this.onLaneTap,
  });

  final List<double> laneIntegrity;
  final double coreIntegrity;
  final List<bool> builtLanes;
  final Color tint;
  final ValueChanged<int>? onLaneTap;

  @override
  Widget build(BuildContext context) {
    const size = 260.0;
    const nodeSize = 74.0;
    const center = size / 2;
    const offset = 76.0;

    Offset positionForLane(int lane) {
      switch (lane) {
        case 0:
          return const Offset(center - (nodeSize / 2), center - offset - 10);
        case 1:
          return const Offset(center + 34, center - 46);
        case 2:
          return const Offset(center + 34, center + 24);
        case 3:
          return const Offset(center - (nodeSize / 2), center + offset - 10);
        case 4:
          return const Offset(center - 108, center + 24);
        case 5:
          return const Offset(center - 108, center - 46);
        default:
          return const Offset(center - (nodeSize / 2), center - offset - 10);
      }
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: center - (nodeSize / 2),
            top: center - (nodeSize / 2),
            child: _HexArenaNode(
              label: 'CORE',
              valueLabel: '${(coreIntegrity * 100).round()}%',
              tint: tint,
              active: true,
              size: nodeSize,
            ),
          ),
          for (var lane = 0; lane < laneIntegrity.length; lane += 1)
            Positioned(
              left: positionForLane(lane).dx,
              top: positionForLane(lane).dy,
              child: _HexArenaNode(
                label: 'L${lane + 1}',
                valueLabel: '${(laneIntegrity[lane] * 100).round()}%',
                tint: tint,
                active: builtLanes.length > lane ? builtLanes[lane] : false,
                size: nodeSize,
                onTap: onLaneTap == null ? null : () => onLaneTap!(lane),
              ),
            ),
        ],
      ),
    );
  }
}

class _HexArenaNode extends StatelessWidget {
  const _HexArenaNode({
    required this.label,
    required this.valueLabel,
    required this.tint,
    required this.active,
    required this.size,
    this.onTap,
  });

  final String label;
  final String valueLabel;
  final Color tint;
  final bool active;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: (active ? tint : LightcorePalette.stroke).withValues(
              alpha: 0.5,
            ),
          ),
          color: (active ? tint : LightcorePalette.panelRaised).withValues(
            alpha: active ? 0.14 : 0.72,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hexagon_rounded,
              color: active ? tint : LightcorePalette.stroke,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: active ? tint : LightcorePalette.stroke,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              valueLabel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.entry});

  final int rank;
  final LightcoreTournamentLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.isPlayer
        ? LightcorePalette.solar
        : LightcorePalette.mist.withValues(alpha: 0.84);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: entry.isPlayer
            ? LightcorePalette.solar.withValues(alpha: 0.1)
            : LightcorePalette.panelRaised.withValues(alpha: 0.74),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              entry.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: entry.isPlayer ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${entry.globalRating} RTG',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LightcorePalette.mist.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '${entry.score}',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

Color _modeTint(LightcoreTournamentModeId mode) => switch (mode) {
  LightcoreTournamentModeId.enemyBlitz => LightcorePalette.flare,
  LightcoreTournamentModeId.hexGauntlet => LightcorePalette.solar,
  LightcoreTournamentModeId.arenaFlow => LightcorePalette.violet,
};

String _formatCountdown(DateTime endsAt) {
  final remaining = endsAt.difference(DateTime.now());
  if (remaining.isNegative) {
    return 'Ended';
  }
  if (remaining.inDays >= 1) {
    return '${remaining.inDays}d ${remaining.inHours.remainder(24)}h';
  }
  if (remaining.inHours >= 1) {
    return '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m';
  }
  return '${max(0, remaining.inMinutes)}m';
}

String _joinButtonLabel(LightcoreTournamentModeId mode) => switch (mode) {
  LightcoreTournamentModeId.enemyBlitz => 'Join Test Event',
  LightcoreTournamentModeId.hexGauntlet => 'Join Weekly Event',
  LightcoreTournamentModeId.arenaFlow => 'Join Weekly Event',
};
