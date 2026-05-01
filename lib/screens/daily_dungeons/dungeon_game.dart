part of '../daily_dungeons_screen.dart';

class _ThreatDirectorDungeonGame extends FlameGame {
  _ThreatDirectorDungeonGame({
    required this.controller,
    required this.towerProfile,
    required this.timeLimit,
    required this.anomalyCards,
    required this.apexCard,
    required this.snapshotNotifier,
    required this.onRunEnded,
  }) : _remainingSeconds = timeLimit.inSeconds.toDouble(),
       _towerHealth = towerProfile.maxHealth;

  final LightcoreController controller;
  final LightcoreDailyDungeonTowerProfile towerProfile;
  final Duration timeLimit;
  final List<EnemyCardState> anomalyCards;
  final EnemyCardState? apexCard;
  final ValueNotifier<_DungeonRunSnapshot> snapshotNotifier;
  final void Function({required bool cleared}) onRunEnded;

  final List<_DungeonRaid> _raids = <_DungeonRaid>[];
  final List<_DungeonTowerShot> _towerShots = <_DungeonTowerShot>[];
  final List<_DungeonImpact> _impacts = <_DungeonImpact>[];
  final Map<String, double> _cooldowns = <String, double>{};
  double _remainingSeconds;
  double _towerHealth;
  double _towerCharge = 0;
  double _towerCooldownRemaining = 0;
  double _launchWindowRemaining = 0;
  double _elapsed = 0;
  PrototypeAffinity? _lastLaunchAffinity;
  bool _running = true;
  bool _victory = false;
  bool _expired = false;
  bool _resultDispatched = false;
  int _raidCounter = 0;
  int _shotCounter = 0;
  int _impactCounter = 0;
  int _launchChain = 0;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  void update(double dt) {
    super.update(dt);
    final clamped = dt.clamp(0.0, 0.05).toDouble();
    _elapsed += clamped;
    if (_running) {
      _advanceRun(clamped);
    }
    _updateVisualEffects(clamped);
    _emitSnapshot();
  }

  void launchCard(EnemyCardState card, {required bool apex}) {
    final key = _dungeonLaunchKey(card, apex: apex);
    if (!_running || (_cooldowns[key] ?? 0) > 0) {
      return;
    }
    final lifetime = _dungeonRaidLifetime(controller, card, apex: apex);
    final raidHealth = _dungeonRaidMaxHealth(
      controller,
      card,
      towerProfile,
      apex: apex,
    );
    final chainTier = _dungeonNextLaunchChainTier(
      currentTier: _launchChain,
      windowRemaining: _launchWindowRemaining,
      previousAffinity: _lastLaunchAffinity,
      nextAffinity: card.config.affinity,
      apex: apex,
    );
    final surgeMultiplier = _dungeonLaunchChainDamageMultiplier(
      chainTier,
      apex: apex,
    );
    final raidIndex = _raidCounter++;
    _raids.add(
      _DungeonRaid(
        id: 'dungeon_raid_$raidIndex',
        damagePerSecond:
            _dungeonRaidDamagePerSecond(controller, card, apex: apex) *
            surgeMultiplier,
        totalSeconds: lifetime,
        remainingSeconds: lifetime,
        maxHealth: raidHealth,
        remainingHealth: raidHealth,
        affinity: card.config.affinity,
        laneIndex: raidIndex,
        chainTier: chainTier,
        surgeMultiplier: surgeMultiplier,
        apex: apex,
      ),
    );
    _cooldowns[key] = _dungeonDeployCooldown(controller, card, apex: apex);
    _launchChain = chainTier;
    _lastLaunchAffinity = card.config.affinity;
    _launchWindowRemaining = _dungeonLaunchChainWindow(apex: apex);
    _emitSnapshot();
  }

  void _advanceRun(double dt) {
    var raidDamage = 0.0;
    final nextRaids = <_DungeonRaid>[];
    for (final raid in _raids) {
      raidDamage += raid.damagePerSecond * dt;
      final remaining = raid.remainingSeconds - dt;
      if (remaining > 0 && raid.remainingHealth > 0) {
        nextRaids.add(raid.copyWith(remainingSeconds: remaining));
      }
    }
    _raids
      ..clear()
      ..addAll(nextRaids);

    for (final entry in _cooldowns.entries.toList(growable: false)) {
      _cooldowns[entry.key] = math.max(0.0, entry.value - dt);
    }
    if (_launchWindowRemaining > 0) {
      _launchWindowRemaining = math.max(0.0, _launchWindowRemaining - dt);
      if (_launchWindowRemaining <= 0) {
        _launchChain = 0;
        _lastLaunchAffinity = null;
      }
    }

    _towerHealth = math.max(0.0, _towerHealth - raidDamage);
    _remainingSeconds = math.max(0.0, _remainingSeconds - dt);
    _towerCooldownRemaining = math.max(0.0, _towerCooldownRemaining - dt);
    _towerCharge = math.min(1.0, _towerCharge + (towerProfile.chargeRate * dt));
    if (_raids.isNotEmpty &&
        _towerCharge >= 1 &&
        _towerCooldownRemaining <= 0) {
      _fireTowerShot();
    }

    final cleared = _towerHealth <= 0;
    final expired = !cleared && _remainingSeconds <= 0;
    if (cleared || expired) {
      _finishRun(cleared: cleared);
    }
  }

  void _fireTowerShot() {
    final target = _counterFireTarget();
    final damage = _towerShotDamageAgainst(target);
    final targetIndex = _raids.indexWhere((raid) => raid.id == target.id);
    if (targetIndex < 0) {
      return;
    }
    final nextHealth = target.remainingHealth - damage;
    final defeated = nextHealth <= 0;
    final targetAngle = _raidAngle(target);
    final targetDistance = _raidDistanceFactor(target);

    _towerShots.add(
      _DungeonTowerShot(
        id: 'dungeon_tower_shot_${_shotCounter++}',
        projectileType: towerProfile.projectileType,
        affinity: towerProfile.affinity,
        targetAngle: targetAngle,
        targetDistanceFactor: targetDistance,
        progress: 0,
        critical: defeated,
      ),
    );
    _impacts.add(
      _DungeonImpact(
        id: 'dungeon_tower_impact_${_impactCounter++}',
        affinity: towerProfile.affinity,
        projectileType: towerProfile.projectileType,
        angle: targetAngle,
        distanceFactor: targetDistance,
        progress: 0,
        lethal: defeated,
      ),
    );

    if (defeated) {
      _raids.removeAt(targetIndex);
    } else {
      _raids[targetIndex] = target.copyWith(remainingHealth: nextHealth);
    }
    _towerCharge = 0;
    _towerCooldownRemaining = towerProfile.cooldownSeconds;
  }

  _DungeonRaid _counterFireTarget() {
    return _raids.reduce((left, right) {
      final leftScore = left.progress + (left.apex ? 0.08 : 0);
      final rightScore = right.progress + (right.apex ? 0.08 : 0);
      if (rightScore > leftScore) {
        return right;
      }
      return left;
    });
  }

  double _towerShotDamageAgainst(_DungeonRaid raid) {
    final affinityMatch = raid.affinity == towerProfile.affinity ? 1.08 : 1.0;
    final apexGuard = raid.apex ? 0.72 : 1.0;
    return towerProfile.shotDamage * affinityMatch * apexGuard;
  }

  void _finishRun({required bool cleared}) {
    _running = false;
    _victory = cleared;
    _expired = !cleared;
    if (_resultDispatched) {
      return;
    }
    _resultDispatched = true;
    onRunEnded(cleared: cleared);
  }

  void _updateVisualEffects(double dt) {
    _towerShots
      ..clear()
      ..addAll(
        _towerShots
            .map((shot) => shot.copyWith(progress: shot.progress + (dt * 2.9)))
            .where((shot) => shot.progress < 1)
            .toList(growable: false),
      );
    _impacts
      ..clear()
      ..addAll(
        _impacts
            .map(
              (impact) => impact.copyWith(
                progress: impact.progress + (dt * (impact.lethal ? 1.6 : 2.2)),
              ),
            )
            .where((impact) => impact.progress < 1)
            .toList(growable: false),
      );
  }

  void _emitSnapshot() {
    snapshotNotifier.value = _DungeonRunSnapshot(
      remainingSeconds: _remainingSeconds,
      towerHealth: _towerHealth,
      towerMaxHealth: towerProfile.maxHealth,
      towerCharge: _towerCharge,
      launchChain: _launchChain,
      launchWindowRemaining: _launchWindowRemaining,
      cooldowns: Map<String, double>.unmodifiable(_cooldowns),
      running: _running,
      victory: _victory,
      expired: _expired,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    _renderBackground(canvas);
    final center = Offset(size.x / 2, size.y / 2);
    final shortest = math.min(size.x, size.y);
    final outerRadius = shortest * 0.34;
    final slotRadius = shortest * 0.095;
    final coreRadius = shortest * 0.18;
    final slots = _slotPositions(center, outerRadius);

    _renderArena(canvas, center, outerRadius, slotRadius, coreRadius, slots);
    _renderRaids(canvas, center, outerRadius, shortest);
    _renderTowerShots(canvas, center, outerRadius, coreRadius);
    _renderImpacts(canvas, center, outerRadius, coreRadius);
    _renderTowerAndManager(
      canvas,
      center,
      outerRadius,
      slotRadius,
      coreRadius,
      slots,
    );
  }

  void _renderBackground(Canvas canvas) {
    final rect = Offset.zero & Size(size.x, size.y);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            LightcorePalette.night,
            LightcorePalette.abyss,
            Color(0xFF152D38),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );
    final pulse = 0.5 + (math.sin(_elapsed * 1.6) * 0.5);
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.46),
      math.min(size.x, size.y) * (0.36 + (pulse * 0.04)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = towerProfile.affinity.color.withValues(alpha: 0.12),
    );
  }

  void _renderArena(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double slotRadius,
    double coreRadius,
    List<Offset> slots,
  ) {
    final tint = towerProfile.affinity.color;
    canvas.drawCircle(
      center,
      outerRadius * 1.18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = LightcorePalette.stroke.withValues(alpha: 0.5),
    );
    final ringPath = Path()..moveTo(slots.first.dx, slots.first.dy);
    for (final slot in slots.skip(1)) {
      ringPath.lineTo(slot.dx, slot.dy);
    }
    ringPath.close();
    canvas.drawPath(
      ringPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = tint.withValues(alpha: 0.34),
    );
    canvas.drawCircle(
      center,
      outerRadius * 0.72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = coreRadius * 0.32
        ..color = LightcorePalette.warning.withValues(alpha: 0.05),
    );
    canvas.drawCircle(
      center,
      outerRadius * 0.72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = LightcorePalette.warning.withValues(alpha: 0.48),
    );
  }

  void _renderTowerAndManager(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double slotRadius,
    double coreRadius,
    List<Offset> slots,
  ) {
    final tint = towerProfile.affinity.color;
    for (var index = 0; index < slots.length; index += 1) {
      final slot = slots[index];
      final color = index == 0 ? tint : LightcorePalette.stroke;
      canvas.drawLine(
        center,
        slot,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = index == 0 ? 1.8 : 1.2
          ..color = color.withValues(alpha: index == 0 ? 0.18 : 0.08),
      );
      final hex = _hexPath(slot, slotRadius);
      canvas.drawPath(
        hex,
        Paint()
          ..style = PaintingStyle.fill
          ..color = LightcorePalette.panel.withValues(alpha: 0.42),
      );
      canvas.drawPath(
        hex,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = index == 0 ? 1.8 : 1.5
          ..color = color.withValues(alpha: index == 0 ? 0.46 : 0.32),
      );
      canvas.drawCircle(
        slot,
        slotRadius * 0.16,
        Paint()..color = color.withValues(alpha: 0.42),
      );
    }

    final towerPulse = 0.5 + (math.sin(_elapsed * 2.1) * 0.5);
    canvas.drawPath(
      _hexPath(center, coreRadius * (1.04 + (towerPulse * 0.05))),
      Paint()
        ..style = PaintingStyle.fill
        ..color = tint.withValues(alpha: 0.1),
    );
    canvas.drawPath(
      _hexPath(center, coreRadius),
      Paint()
        ..style = PaintingStyle.fill
        ..color = LightcorePalette.night.withValues(alpha: 0.62),
    );
    canvas.drawPath(
      _hexPath(center, coreRadius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = tint.withValues(alpha: 0.78),
    );
    _drawHexChargeIndicator(
      canvas,
      center,
      color: tint,
      radius: coreRadius,
      chargeProgress: _towerCharge,
      popProgress: _towerCharge >= 0.995 ? 1 : 0,
    );
    _paintTowerGlyph(canvas, center, radius: coreRadius * 1.12, color: tint);
    _paintBadge(
      canvas,
      center.translate(0, coreRadius * 0.62),
      'L${towerProfile.effectiveDisplayLevel}',
      color: LightcorePalette.mist,
      size: coreRadius * 0.16,
    );
  }

  void _renderRaids(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double shortest,
  ) {
    for (final raid in _raids) {
      final position = _raidPosition(center, outerRadius, raid);
      final color = raid.affinity.color;
      final raidRadius = shortest * (raid.apex ? 0.044 : 0.03);
      final trailTarget = Offset.lerp(position, center, 0.24)!;
      canvas.drawLine(
        position,
        trailTarget,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = raid.apex ? 3.2 : 2
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: raid.apex ? 0.72 : 0.5),
      );
      canvas.drawCircle(
        position,
        raidRadius * 1.8,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9)
          ..color = color.withValues(alpha: 0.2),
      );
      canvas.drawCircle(position, raidRadius, Paint()..color = color);
      canvas.drawArc(
        Rect.fromCircle(center: position, radius: raidRadius * 1.48),
        -math.pi / 2,
        math.pi * 2 * raid.healthFraction,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = LightcorePalette.success.withValues(alpha: 0.76),
      );
      if (raid.apex) {
        canvas.drawCircle(
          position,
          raidRadius * 1.8,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = LightcorePalette.solar.withValues(alpha: 0.68),
        );
      }
      if (raid.chainTier > 1) {
        canvas.drawCircle(
          position,
          raidRadius * (2.05 + (raid.chainTier * 0.04)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = LightcorePalette.gilded.withValues(alpha: 0.66),
        );
        _paintBadge(
          canvas,
          position.translate(0, raidRadius * 1.9),
          'x${raid.surgeMultiplier.toStringAsFixed(1)}',
          color: LightcorePalette.gilded,
          size: math.max(9, raidRadius * 0.62),
        );
      }
    }
  }

  void _renderTowerShots(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double coreRadius,
  ) {
    for (final shot in _towerShots) {
      final end = Offset(
        center.dx +
            math.cos(shot.targetAngle) *
                outerRadius *
                shot.targetDistanceFactor,
        center.dy +
            math.sin(shot.targetAngle) *
                outerRadius *
                shot.targetDistanceFactor,
      );
      final current = Offset.lerp(center, end, shot.progress)!;
      final color = shot.affinity.color;
      final width = LightcoreProjectileFx.lineWidth(
        shot.projectileType,
        coreRadius,
      ).clamp(2.2, 5.2).toDouble();
      final seed =
          (_elapsed * 14.0) +
          (shot.progress * 9.0) +
          (shot.id.hashCode * 0.0017);
      if (shot.progress < 0.42) {
        final aimAngle = math.atan2(end.dy - center.dy, end.dx - center.dx);
        LightcoreProjectileFx.drawFireBurst(
          canvas,
          origin: center,
          color: color,
          aimAngle: aimAngle,
          projectileType: shot.projectileType,
          progress: (shot.progress / 0.42).clamp(0.0, 1.0).toDouble(),
          alpha: 0.82,
          unit: coreRadius,
          seed: seed,
        );
      }
      LightcoreProjectileFx.drawProjectileTrail(
        canvas,
        projectileType: shot.projectileType,
        start: center,
        end: end,
        current: current,
        color: color,
        width: width,
        seed: seed,
        alpha: (1 - shot.progress).clamp(0.0, 1.0).toDouble(),
        unit: coreRadius,
        progress: shot.progress,
      );
      if (shot.critical) {
        canvas.drawPath(
          _hexPath(current, coreRadius * 0.14),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = LightcorePalette.solar.withValues(alpha: 0.92),
        );
      }
    }
  }

  void _renderImpacts(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double coreRadius,
  ) {
    for (final impact in _impacts) {
      final progress = Curves.easeOut.transform(impact.progress);
      final position = Offset(
        center.dx +
            math.cos(impact.angle) * outerRadius * impact.distanceFactor,
        center.dy +
            math.sin(impact.angle) * outerRadius * impact.distanceFactor,
      );
      final color = impact.affinity.color;
      canvas.drawCircle(
        position,
        coreRadius * (0.18 + (progress * (impact.lethal ? 0.36 : 0.24))),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = impact.lethal ? 3.2 : 2.2
          ..color = color.withValues(alpha: (1 - progress) * 0.74),
      );
      if (impact.lethal) {
        canvas.drawPath(
          _hexPath(position, coreRadius * (0.16 + (progress * 0.22))),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = LightcorePalette.solar.withValues(
              alpha: (1 - progress) * 0.62,
            ),
        );
      }
    }
  }

  void _drawHexChargeIndicator(
    Canvas canvas,
    Offset center, {
    required Color color,
    required double radius,
    required double chargeProgress,
    required double popProgress,
  }) {
    final clampedCharge = chargeProgress.clamp(0.0, 1.0).toDouble();
    final guideRadius = radius * 0.76;
    final chargeRadius = radius * (0.16 + (clampedCharge * 0.56));
    canvas.drawPath(
      _hexPath(center, guideRadius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = color.withValues(alpha: 0.4),
    );
    if (clampedCharge > 0) {
      canvas.drawPath(
        _hexPath(center, chargeRadius),
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: 0.16 + (clampedCharge * 0.32)),
      );
      canvas.drawPath(
        _hexPath(center, chargeRadius),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.5 + (clampedCharge * 0.28)),
      );
    }
  }

  void _paintTowerGlyph(
    Canvas canvas,
    Offset center, {
    required double radius,
    required Color color,
  }) {
    final payloadColor =
        towerProfile.payloadType.affinity?.color ?? LightcorePalette.layer2;
    final vertices = _polygonPoints(center, radius * 0.42, 6, math.pi / 6);
    final path = Path()..moveTo(vertices.first.dx, vertices.first.dy);
    for (final vertex in vertices.skip(1)) {
      path.lineTo(vertex.dx, vertex.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = payloadColor.withValues(alpha: 0.14),
    );
    for (var edge = 0; edge < 6; edge += 1) {
      _drawHexEdge(
        canvas,
        vertices,
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, radius * 0.035)
          ..strokeCap = StrokeCap.round
          ..color = LightcorePalette.stroke.withValues(alpha: 0.58),
      );
    }
    final activeEdges = math.max(
      1,
      ((towerProfile.effectiveDisplayLevel /
                  LightcoreController.maxTowerLevel) *
              6)
          .ceil(),
    );
    for (var edge = 0; edge < activeEdges; edge += 1) {
      _drawHexEdge(
        canvas,
        vertices,
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2.0, radius * 0.065)
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.96),
      );
    }
    canvas.drawCircle(
      center,
      radius * 0.3,
      Paint()..color = payloadColor.withValues(alpha: 0.24),
    );
    canvas.drawCircle(
      center,
      radius * 0.3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = payloadColor.withValues(alpha: 0.72),
    );
    _paintIconGlyph(
      canvas,
      center,
      towerProjectileIcon(towerProfile.projectileType),
      size: radius * 0.32,
      color: towerProfile.projectileType.affinity.color,
    );
  }

  void _drawHexEdge(
    Canvas canvas,
    List<Offset> vertices,
    int edge,
    Paint paint,
  ) {
    final start = vertices[edge % vertices.length];
    final end = vertices[(edge + 1) % vertices.length];
    canvas.drawLine(start, end, paint);
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

  void _paintBadge(
    Canvas canvas,
    Offset center,
    String text, {
    required Color color,
    required double size,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
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
    final points = _polygonPoints(center, radius, 6, math.pi / 6);
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    return path;
  }

  List<Offset> _polygonPoints(
    Offset center,
    double radius,
    int sides,
    double rotation,
  ) {
    return List<Offset>.generate(sides, (index) {
      final angle = rotation + ((math.pi * 2 * index) / sides);
      return Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
    }, growable: false);
  }

  List<Offset> _slotPositions(Offset center, double outerRadius) {
    return List<Offset>.generate(6, (index) {
      final angle = _slotAngle(index);
      return Offset(
        center.dx + math.cos(angle) * outerRadius,
        center.dy + math.sin(angle) * outerRadius,
      );
    }, growable: false);
  }

  Offset _raidPosition(Offset center, double outerRadius, _DungeonRaid raid) {
    final angle = _raidAngle(raid);
    final distance = outerRadius * _raidDistanceFactor(raid);
    return Offset(
      center.dx + math.cos(angle) * distance,
      center.dy + math.sin(angle) * distance,
    );
  }

  double _raidAngle(_DungeonRaid raid) {
    final lane = raid.laneIndex % 6;
    return _slotAngle(lane) +
        (math.sin((_elapsed * 1.4) + (raid.laneIndex * 0.7)) * 0.05) +
        (raid.progress * 0.12);
  }

  double _raidDistanceFactor(_DungeonRaid raid) =>
      1.34 - (raid.progress * 0.54);

  double _slotAngle(int index) => (-math.pi / 2) + (index * math.pi / 3);
}

class _DungeonTowerShot {
  const _DungeonTowerShot({
    required this.id,
    required this.projectileType,
    required this.affinity,
    required this.targetAngle,
    required this.targetDistanceFactor,
    required this.progress,
    required this.critical,
  });

  final String id;
  final ProjectileType projectileType;
  final PrototypeAffinity affinity;
  final double targetAngle;
  final double targetDistanceFactor;
  final double progress;
  final bool critical;

  _DungeonTowerShot copyWith({double? progress}) {
    return _DungeonTowerShot(
      id: id,
      projectileType: projectileType,
      affinity: affinity,
      targetAngle: targetAngle,
      targetDistanceFactor: targetDistanceFactor,
      progress: progress ?? this.progress,
      critical: critical,
    );
  }
}

class _DungeonImpact {
  const _DungeonImpact({
    required this.id,
    required this.affinity,
    required this.projectileType,
    required this.angle,
    required this.distanceFactor,
    required this.progress,
    required this.lethal,
  });

  final String id;
  final PrototypeAffinity affinity;
  final ProjectileType projectileType;
  final double angle;
  final double distanceFactor;
  final double progress;
  final bool lethal;

  _DungeonImpact copyWith({double? progress}) {
    return _DungeonImpact(
      id: id,
      affinity: affinity,
      projectileType: projectileType,
      angle: angle,
      distanceFactor: distanceFactor,
      progress: progress ?? this.progress,
      lethal: lethal,
    );
  }
}
