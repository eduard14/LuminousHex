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
  double _elapsed = 0;
  bool _running = true;
  bool _victory = false;
  bool _expired = false;
  bool _resultDispatched = false;
  int _raidCounter = 0;
  int _shotCounter = 0;
  int _impactCounter = 0;

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
    final lifetime = _dungeonRaidLifetime(card, apex: apex);
    final raidHealth = _dungeonRaidMaxHealth(
      controller,
      card,
      towerProfile,
      apex: apex,
    );
    final raidIndex = _raidCounter++;
    _raids.add(
      _DungeonRaid(
        id: 'dungeon_raid_$raidIndex',
        damagePerSecond: _dungeonRaidDamagePerSecond(
          controller,
          card,
          apex: apex,
        ),
        totalSeconds: lifetime,
        remainingSeconds: lifetime,
        maxHealth: raidHealth,
        remainingHealth: raidHealth,
        affinity: card.config.affinity,
        laneIndex: raidIndex,
        apex: apex,
      ),
    );
    _cooldowns[key] = _dungeonDeployCooldown(controller, card, apex: apex);
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
    _renderTowerShots(canvas, center, outerRadius, slots.first, coreRadius);
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
      final active = index == 0;
      final color = active ? tint : LightcorePalette.stroke;
      canvas.drawLine(
        center,
        slot,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 2.3 : 1.2
          ..color = color.withValues(alpha: active ? 0.28 : 0.08),
      );
      final hex = _hexPath(slot, slotRadius);
      canvas.drawPath(
        hex,
        Paint()
          ..style = PaintingStyle.fill
          ..color = active
              ? tint.withValues(alpha: 0.2)
              : LightcorePalette.panel.withValues(alpha: 0.42),
      );
      canvas.drawPath(
        hex,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 2.8 : 1.5
          ..color = color.withValues(alpha: active ? 0.92 : 0.32),
      );
      if (active) {
        _drawHexChargeIndicator(
          canvas,
          slot,
          color: tint,
          radius: slotRadius,
          chargeProgress: _towerCharge,
          popProgress: _towerCharge >= 0.995 ? 1 : 0,
        );
        _paintTowerGlyph(canvas, slot, radius: slotRadius, color: tint);
      } else {
        canvas.drawCircle(
          slot,
          slotRadius * 0.16,
          Paint()..color = color.withValues(alpha: 0.42),
        );
      }
    }

    final managerPulse = 0.5 + (math.sin(_elapsed * 2.1) * 0.5);
    canvas.drawPath(
      _hexPath(center, coreRadius * (1.04 + (managerPulse * 0.05))),
      Paint()
        ..style = PaintingStyle.fill
        ..color = LightcorePalette.warning.withValues(alpha: 0.1),
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
        ..color = LightcorePalette.warning.withValues(alpha: 0.74),
    );
    canvas.drawCircle(
      center,
      coreRadius * 0.34,
      Paint()..color = LightcorePalette.warning.withValues(alpha: 0.22),
    );
    _paintIconGlyph(
      canvas,
      center.translate(0, -coreRadius * 0.1),
      Icons.manage_accounts_rounded,
      size: coreRadius * 0.46,
      color: LightcorePalette.warning,
    );
    _paintBadge(
      canvas,
      center.translate(0, coreRadius * 0.46),
      'MGR',
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
    }
  }

  void _renderTowerShots(
    Canvas canvas,
    Offset center,
    double outerRadius,
    Offset towerSlot,
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
      final current = Offset.lerp(towerSlot, end, shot.progress)!;
      final color = shot.affinity.color;
      final width = switch (shot.projectileType.behaviorProfile) {
        ProjectileBehaviorProfile.thread => 3.0,
        ProjectileBehaviorProfile.pulse => 2.3,
        ProjectileBehaviorProfile.burst => 2.6,
        ProjectileBehaviorProfile.chain => 2.8,
        ProjectileBehaviorProfile.split => 2.9,
        ProjectileBehaviorProfile.lance => 3.8,
        ProjectileBehaviorProfile.explosion => 4.2,
        ProjectileBehaviorProfile.wave => 3.6,
        ProjectileBehaviorProfile.nova => 4.8,
      };
      final seed =
          (_elapsed * 14.0) +
          (shot.progress * 9.0) +
          (shot.id.hashCode * 0.0017);
      switch (shot.projectileType.behaviorProfile) {
        case ProjectileBehaviorProfile.chain:
          _drawEnergyBolt(
            canvas,
            towerSlot,
            current,
            color,
            width: width,
            amplitude: coreRadius * 0.12,
            seed: seed,
            branch: true,
          );
        case ProjectileBehaviorProfile.explosion:
          _drawGlowLine(canvas, towerSlot, current, color, width: width);
          canvas.drawCircle(
            current,
            coreRadius * 0.18,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..color = color.withValues(alpha: 0.68),
          );
        case ProjectileBehaviorProfile.wave:
          _drawGlowLine(canvas, towerSlot, current, color, width: width);
          canvas.drawCircle(
            current,
            coreRadius * (0.1 + (shot.progress * 0.08)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = color.withValues(alpha: 0.72),
          );
        case ProjectileBehaviorProfile.lance:
          _drawGlowLine(canvas, towerSlot, current, color, width: width * 1.08);
          final angle = math.atan2(
            current.dy - towerSlot.dy,
            current.dx - towerSlot.dx,
          );
          final head = Path()
            ..moveTo(current.dx, current.dy)
            ..lineTo(
              current.dx - math.cos(angle - 0.4) * (coreRadius * 0.18),
              current.dy - math.sin(angle - 0.4) * (coreRadius * 0.18),
            )
            ..lineTo(
              current.dx - math.cos(angle + 0.4) * (coreRadius * 0.18),
              current.dy - math.sin(angle + 0.4) * (coreRadius * 0.18),
            )
            ..close();
          canvas.drawPath(head, Paint()..color = color);
        case ProjectileBehaviorProfile.nova:
          _drawEnergyBolt(
            canvas,
            towerSlot,
            current,
            color,
            width: width,
            amplitude: coreRadius * 0.08,
            seed: seed,
            branch: true,
          );
          for (final angle in <double>[0, math.pi / 3, (2 * math.pi) / 3]) {
            final offset = Offset(
              math.cos(angle) * coreRadius * 0.16,
              math.sin(angle) * coreRadius * 0.16,
            );
            _drawGlowLine(
              canvas,
              current - offset,
              current + offset,
              color,
              width: width * 0.24,
              alpha: 0.38,
            );
          }
        case ProjectileBehaviorProfile.thread ||
            ProjectileBehaviorProfile.pulse ||
            ProjectileBehaviorProfile.burst ||
            ProjectileBehaviorProfile.split:
          _drawGlowLine(canvas, towerSlot, current, color, width: width);
      }
      _drawEnergyOrb(canvas, current, color, coreRadius * 0.08);
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
      size: radius * 0.44,
      color: color,
    );
    _paintBadge(
      canvas,
      center.translate(0, radius * 0.52),
      'L${towerProfile.displayLevel}',
      color: LightcorePalette.mist,
      size: radius * 0.18,
    );
  }

  void _drawGlowLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color, {
    required double width,
    double alpha = 0.84,
  }) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..strokeWidth = width + 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = color.withValues(alpha: alpha * 0.22),
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: alpha),
    );
  }

  void _drawEnergyOrb(
    Canvas canvas,
    Offset center,
    Color color,
    double radius, {
    double alpha = 0.96,
  }) {
    canvas.drawCircle(
      center,
      radius * 2.0,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = color.withValues(alpha: 0.2 * alpha),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color.withValues(alpha: alpha),
    );
  }

  void _drawEnergyBolt(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color, {
    required double width,
    required double amplitude,
    required double seed,
    bool branch = false,
  }) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance <= 0) {
      return;
    }
    final normal = Offset(-delta.dy / distance, delta.dx / distance);
    final path = Path()..moveTo(start.dx, start.dy);
    const segments = 6;
    for (var index = 1; index <= segments; index += 1) {
      final t = index / segments;
      final base = Offset.lerp(start, end, t)!;
      final jitter =
          math.sin((seed * 1.7) + (index * 2.31)) *
          amplitude *
          (1 - ((t - 0.5).abs() * 0.9));
      final point = base + (normal * jitter);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width + 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = color.withValues(alpha: 0.2),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.86),
    );
    if (!branch) {
      return;
    }
    final branchStart = Offset.lerp(start, end, 0.58)!;
    final branchEnd =
        branchStart + (normal * amplitude * (math.sin(seed) >= 0 ? 1.8 : -1.8));
    canvas.drawLine(
      branchStart,
      branchEnd,
      Paint()
        ..strokeWidth = width * 0.46
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.42),
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
