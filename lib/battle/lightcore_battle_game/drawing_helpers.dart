part of '../lightcore_battle_game.dart';

extension LightcoreBattleGameDrawingHelpers on LightcoreBattleGame {
  Offset _shotStartOffset({required bool layer2}) {
    return layer2
        ? Offset(_center.x, _center.y - (_coreRadius * 1.55))
        : Offset(_center.x, _center.y);
  }

  Offset _angleOffset(double angle, double distance) {
    return Offset(math.cos(angle) * distance, math.sin(angle) * distance);
  }

  void _renderGuidePulse(
    Canvas canvas,
    Offset center, {
    required double radius,
    required Color tint,
    bool showTapCue = true,
  }) {
    final pulse = 0.5 + ((math.sin(controller.elapsed * 3.8) + 1) * 0.25);
    canvas.drawCircle(
      center,
      radius * (0.92 + (pulse * 0.18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = tint.withValues(alpha: 0.16 + (pulse * 0.12)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..color = LightcorePalette.mist.withValues(alpha: 0.88),
    );
    if (showTapCue) {
      _renderTapCue(
        canvas,
        center + Offset(radius * 0.48, radius * 0.48),
        radius: radius * 0.34,
        tint: tint,
      );
    }
  }

  void _renderTapCue(
    Canvas canvas,
    Offset center, {
    required double radius,
    required Color tint,
  }) {
    final cueRadius = radius.clamp(10.0, 22.0).toDouble();
    final progress = ((math.sin(controller.elapsed * 5.3) + 1) * 0.5)
        .toDouble();
    final ringProgress = Curves.easeOutCubic.transform(
      (controller.elapsed * 1.35) % 1,
    );
    final pressOffset = Offset(0, cueRadius * 0.16 * progress);
    final iconCenter = center + pressOffset;
    final outerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, cueRadius * 0.08)
      ..color = tint.withValues(alpha: 0.54 * (1 - ringProgress));

    canvas.save();
    canvas.clipRect(
      Rect.fromCircle(center: center, radius: cueRadius * 2.2).inflate(2),
    );
    canvas.drawCircle(
      center,
      cueRadius * (0.8 + (0.54 * ringProgress)),
      outerRingPaint,
    );
    canvas.drawCircle(
      iconCenter,
      cueRadius,
      Paint()
        ..style = PaintingStyle.fill
        ..color = tint.withValues(alpha: 0.96),
    );
    canvas.drawCircle(
      iconCenter,
      cueRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, cueRadius * 0.07)
        ..color = LightcorePalette.mist.withValues(alpha: 0.86),
    );

    _paintTapCueGlyph(
      canvas,
      iconCenter,
      radius: cueRadius,
      color: LightcorePalette.night,
    );
    canvas.restore();
  }

  void _paintTapCueGlyph(
    Canvas canvas,
    Offset center, {
    required double radius,
    required Color color,
  }) {
    const icon = Icons.touch_app_rounded;
    final glyphPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: color,
          fontFamily: icon.fontFamily,
          fontSize: radius * 1.5,
          package: icon.fontPackage,
          shadows: [
            Shadow(
              color: LightcorePalette.mist.withValues(alpha: 0.28),
              blurRadius: math.max(1.0, radius * 0.08),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(-0.08);
    glyphPainter.paint(
      canvas,
      Offset(-glyphPainter.width / 2, -glyphPainter.height / 2),
    );
    canvas.restore();
  }

  int? _hitTestSlot(Vector2 pointer) {
    for (var index = 0; index < _slotPositions.length; index++) {
      if (pointer.distanceTo(_slotPositions[index]) <= _slotRadius * 1.05) {
        return index;
      }
    }
    return null;
  }

  Offset _enemyPosition(EnemyState enemy) {
    return _battlePosition(angle: enemy.angle, radius: enemy.radius);
  }

  Offset _battlePosition({required double angle, required double radius}) {
    final orbitRadius = _modelRadiusToVisual(radius);
    return Offset(
      _center.x + math.cos(angle) * orbitRadius,
      _center.y + math.sin(angle) * orbitRadius,
    );
  }

  double _enemyRadius(EnemyState enemy) {
    return (_slotRadius * 0.23) * enemy.sizeScale;
  }

  double _enemyRevealProgress(EnemyState enemy) {
    if (enemy.splitDepth > 0) {
      return 1;
    }
    final timeReveal =
        (enemy.age / LightcoreBattleGame._enemySpawnRevealDuration).clamp(
          0.0,
          1.0,
        );
    final effectiveSpeed = math.max(
      0.001,
      enemy.speed * (enemy.slowRemaining > 0 ? enemy.slowFactor : 1),
    );
    final secondsUntilRelayImpact =
        math.max(0.0, enemy.radius - controller.relayImpactRadius) /
        effectiveSpeed;
    final approachReveal =
        (1.0 -
                (secondsUntilRelayImpact /
                    LightcoreBattleGame._enemySpawnRevealDuration))
            .clamp(0.0, 1.0)
            .toDouble();
    return Curves.easeOutCubic.transform(math.max(timeReveal, approachReveal));
  }

  double _modelRadiusToVisual(double modelRadius) {
    final modelSpawnRadius = controller.spawnCeilingRadius;
    final modelRelayImpactRadius = controller.relayImpactRadius;
    final normalized =
        ((modelRadius - modelRelayImpactRadius) /
                (modelSpawnRadius - modelRelayImpactRadius))
            .clamp(0, 1);
    return _relayImpactRadiusVisual +
        (normalized * (_spawnRadiusVisual - _relayImpactRadiusVisual));
  }

  double _deathNoise(double seed, int index, double salt) {
    return (math.sin(seed + (index * 12.9898) + (salt * 78.233)) + 1) * 0.5;
  }

  Path _organicBlobPath(
    Offset center,
    double radius, {
    required double seed,
    required double wobble,
  }) {
    const points = 14;
    final path = Path();
    for (var index = 0; index < points; index++) {
      final angle = ((math.pi * 2) / points) * index;
      final lobe =
          math.sin(seed + (index * 1.7)) * 0.62 +
          math.cos((seed * 0.7) - (index * 2.3)) * 0.38;
      final localRadius = math.max(radius * 0.32, radius + (wobble * lobe));
      final point = Offset(
        center.dx + math.cos(angle) * localRadius,
        center.dy + math.sin(angle) * localRadius,
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

  void _drawGlowLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color, {
    required double width,
    double alpha = 1,
  }) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..strokeWidth = width * 2.4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = color.withValues(alpha: 0.18 * alpha),
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.86 * alpha),
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..strokeWidth = math.max(1, width * 0.34)
        ..strokeCap = StrokeCap.round
        ..color = LightcorePalette.layer2.withValues(alpha: 0.54 * alpha),
    );
  }

  void _drawEnergyOrb(
    Canvas canvas,
    Offset center,
    Color color,
    double radius, {
    double alpha = 1,
  }) {
    canvas.drawCircle(
      center,
      radius * 1.95,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = color.withValues(alpha: 0.18 * alpha),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            LightcorePalette.layer2.withValues(alpha: 0.92 * alpha),
            color.withValues(alpha: 0.94 * alpha),
            color.withValues(alpha: 0.26 * alpha),
          ],
          stops: const [0, 0.42, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
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
    double alpha = 1,
  }) {
    final mainBolt = _energyBoltPath(
      start,
      end,
      amplitude: amplitude,
      seed: seed,
      segments: 6,
    );
    canvas.drawPath(
      mainBolt,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
        ..color = color.withValues(alpha: 0.24 * alpha),
    );
    canvas.drawPath(
      mainBolt,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.94 * alpha),
    );
    canvas.drawPath(
      mainBolt,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, width * 0.4)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = LightcorePalette.layer2.withValues(alpha: 0.82 * alpha),
    );

    if (branch) {
      final branchStart = Offset.lerp(start, end, 0.36)!;
      final branchAnchor = Offset.lerp(start, end, 0.58)!;
      final offset = _perpendicularOffset(
        branchStart,
        branchAnchor,
        amplitude * 1.5,
      );
      final branchEnd = branchAnchor.translate(offset.dx, offset.dy);
      final branchBolt = _energyBoltPath(
        branchStart,
        branchEnd,
        amplitude: amplitude * 0.56,
        seed: seed + 2.3,
        segments: 4,
      );
      canvas.drawPath(
        branchBolt,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, width * 0.48)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color.withValues(alpha: 0.68 * alpha),
      );
    }
  }

  void _renderCoreBombTrail(
    Canvas canvas, {
    required Offset start,
    required Offset current,
    required Color color,
    required double width,
    required double seed,
  }) {
    final dx = current.dx - start.dx;
    final dy = current.dy - start.dy;
    final distance = math.sqrt((dx * dx) + (dy * dy));
    if (distance <= 0.001) {
      return;
    }

    final direction = Offset(dx / distance, dy / distance);
    final normal = Offset(-direction.dy, direction.dx);
    final trailLength = math.min(distance, _coreRadius * 0.44);
    final trailStart = current - (direction * trailLength);
    final phase = (seed * 0.38) + (controller.elapsed * 1.7);
    final trailPath = Path();
    for (var step = 0; step <= 4; step++) {
      final t = step / 4;
      final base = Offset.lerp(trailStart, current, t)!;
      final wobble =
          math.sin(phase + (t * math.pi * 2.4)) * _coreRadius * 0.016 * (1 - t);
      final point = base + (normal * wobble);
      if (step == 0) {
        trailPath.moveTo(point.dx, point.dy);
      } else {
        trailPath.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(
      trailPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 2.35
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = color.withValues(alpha: 0.2),
    );
    canvas.drawPath(
      trailPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.92
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.66),
    );
    canvas.drawPath(
      trailPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, width * 0.25)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = LightcorePalette.layer2.withValues(alpha: 0.32),
    );
  }

  void _renderHeavyShotTrail(
    Canvas canvas, {
    required Offset start,
    required Offset current,
    required Color color,
    required double width,
    required double seed,
  }) {
    final dx = current.dx - start.dx;
    final dy = current.dy - start.dy;
    final distance = math.sqrt((dx * dx) + (dy * dy));
    if (distance <= 0.001) {
      return;
    }

    final direction = Offset(dx / distance, dy / distance);
    final normal = Offset(-direction.dy, direction.dx);
    final trailLength = math.min(distance, _coreRadius * 0.96);
    final trailStart = current - (direction * trailLength);
    final warblePhase = (seed * 0.42) + (controller.elapsed * 2.1);
    final trailPath = Path();
    for (var step = 0; step <= 8; step++) {
      final t = step / 8;
      final base = Offset.lerp(trailStart, current, t)!;
      final wobble =
          (math.sin(warblePhase + (t * math.pi * 5.2)) * 0.72 +
              math.sin((warblePhase * 1.7) - (t * math.pi * 3.1)) * 0.28) *
          _coreRadius *
          0.05 *
          (1 - (t * 0.35));
      final point = base + (normal * wobble);
      if (step == 0) {
        trailPath.moveTo(point.dx, point.dy);
      } else {
        trailPath.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(
      trailPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 2.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = color.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      trailPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 1.02
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.66),
    );
    canvas.drawPath(
      trailPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.1, width * 0.28)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = LightcorePalette.layer2.withValues(alpha: 0.42),
    );

    final travelAngle = math.atan2(direction.dy, direction.dx);
    for (var index = 0; index < 4; index++) {
      final depth = 0.1 + (index * 0.18);
      final wave = math.sin(warblePhase + (index * 1.37));
      final fracture = math.sin((warblePhase * 1.9) - (index * 0.92));
      final center =
          current -
          (direction * trailLength * depth) +
          (normal * _coreRadius * 0.04 * wave);
      final fade = (0.38 - (index * 0.055)).clamp(0.0, 1.0);
      final forwardSpan = _coreRadius * (0.13 + (fracture.abs() * 0.04));
      final crossSpan =
          _coreRadius * (0.34 + (index * 0.07) + (wave.abs() * 0.14));
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(travelAngle + (fracture * 0.22));
      canvas.drawPath(
        _warbleOvalPath(
          forwardRadius: forwardSpan * 0.5,
          crossRadius: crossSpan * 0.5,
          phase: warblePhase + index,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, width * (0.3 - (index * 0.024)))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
          ..color = color.withValues(alpha: fade),
      );
      canvas.drawPath(
        _warbleOvalPath(
          forwardRadius: forwardSpan * 0.28,
          crossRadius: crossSpan * 0.34,
          phase: warblePhase + index + math.pi,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = LightcorePalette.mist.withValues(alpha: fade * 0.42),
      );
      canvas.restore();
    }
  }

  Path _warbleOvalPath({
    required double forwardRadius,
    required double crossRadius,
    required double phase,
  }) {
    final path = Path();
    for (var step = 0; step <= 24; step++) {
      final theta = (step / 24) * math.pi * 2;
      final warp =
          1 +
          (math.sin((theta * 3.0) + phase) * 0.11) +
          (math.sin((theta * 5.0) - (phase * 0.7)) * 0.045);
      final x = math.cos(theta) * forwardRadius * warp;
      final y = math.sin(theta) * crossRadius * warp;
      if (step == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _renderChainArcShot(
    Canvas canvas, {
    required Offset start,
    required Offset current,
    required Color color,
    required double width,
    required double seed,
  }) {
    final arcColor = Color.lerp(color, LightcorePalette.gilded, 0.7)!;
    _drawEnergyBolt(
      canvas,
      start,
      current,
      arcColor,
      width: width * 1.18,
      amplitude: _coreRadius * 0.18,
      seed: seed,
      branch: true,
      alpha: 1,
    );
    _drawGlowLine(
      canvas,
      start,
      current,
      LightcorePalette.solar,
      width: math.max(1.2, width * 0.34),
      alpha: 0.58,
    );
    canvas.drawCircle(
      current,
      _coreRadius * 0.22,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..color = arcColor.withValues(alpha: 0.34),
    );
    canvas.drawCircle(
      current,
      _coreRadius * 0.12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1
        ..color = LightcorePalette.gilded.withValues(alpha: 0.88),
    );
  }

  void _renderChainLightningLink(
    Canvas canvas, {
    required ImpactState impact,
    required Offset start,
    required Offset end,
    required Color color,
    required double fade,
  }) {
    final distance = (end - start).distance;
    if (distance <= 1) {
      return;
    }
    final linkColor = Color.lerp(color, LightcorePalette.aether, 0.54)!;
    final pulse =
        0.82 +
        (math.sin((controller.elapsed * 26.0) + impact.id.hashCode) * 0.18);
    final width = math.max(2.2, _coreRadius * 0.036) * pulse;
    final amplitude = distance
        .clamp(_coreRadius * 0.12, _coreRadius * 0.34)
        .toDouble();
    final seed =
        (controller.elapsed * 30.0) +
        (impact.id.hashCode * 0.0029) +
        (impact.progress * 5.0);

    _drawEnergyBolt(
      canvas,
      start,
      end,
      linkColor,
      width: width,
      amplitude: amplitude,
      seed: seed,
      branch: true,
      alpha: 0.96 * fade,
    );
    _drawGlowLine(
      canvas,
      start,
      end,
      LightcorePalette.solar,
      width: math.max(1.1, width * 0.24),
      alpha: 0.44 * fade,
    );
  }

  bool _shotUsesOrbitNode(CoreShotState shot) =>
      !shot.layer2 &&
      shot.sourceSlotIndex != null &&
      shot.projectileType == ProjectileType.orbitNode;

  bool _shotUsesShieldHalo(CoreShotState shot) =>
      !shot.layer2 &&
      shot.sourceSlotIndex != null &&
      shot.projectileType == ProjectileType.shieldHalo;

  bool _shotUsesCoreBasicImpact(CoreShotState shot) =>
      !shot.layer2 && shot.sourceSlotIndex == null;

  bool _shotUsesBlueFocusLaser(CoreShotState shot) =>
      !shot.layer2 &&
      shot.projectileType == ProjectileType.threadBeam &&
      shot.sourceSlotIndex != null &&
      shot.affinity == PrototypeAffinity.aether;

  double _orbitNodeAngleForProgress(CoreShotState shot, double progress) =>
      shot.aimAngle + (progress * math.pi * 2);

  double _orbitNodeVisualRadius(CoreShotState shot) => _modelRadiusToVisual(
    shot.travelRadius,
  ).clamp(_coreRadius * 0.72, _spawnRadiusVisual * 0.92);

  double _shieldHaloVisualRadius(CoreShotState shot) => _modelRadiusToVisual(
    shot.travelRadius,
  ).clamp(_coreRadius * 0.8, _spawnRadiusVisual * 0.9);

  EnemyState? _enemyForShotTarget(CoreShotState shot) {
    for (final enemy in controller.enemies) {
      if (enemy.id == shot.enemyId) {
        return enemy;
      }
    }
    return null;
  }

  Offset _renderBlueFocusLaserShot(
    Canvas canvas, {
    required CoreShotState shot,
    required Color color,
    required double width,
  }) {
    final center = Offset(_center.x, _center.y);
    final target = _enemyForShotTarget(shot);
    final fallbackEnd = Offset(
      center.dx +
          math.cos(shot.aimAngle) * _modelRadiusToVisual(shot.travelRadius),
      center.dy +
          math.sin(shot.aimAngle) * _modelRadiusToVisual(shot.travelRadius),
    );
    final targetEnd = target == null ? fallbackEnd : _enemyPosition(target);
    final beamEnd = targetEnd;
    final lockPulse =
        0.5 +
        (math.sin((controller.elapsed * 13.0) + (shot.id.hashCode * 0.01)) *
            0.5);

    for (final trailScale in <double>[0.62, 0.8]) {
      final trailEnd = Offset.lerp(center, beamEnd, trailScale)!;
      _drawGlowLine(
        canvas,
        center,
        trailEnd,
        color,
        width: width * (0.36 + (trailScale * 0.24)),
        alpha: 0.2,
      );
    }

    _drawGlowLine(
      canvas,
      center,
      beamEnd,
      color,
      width: width * 1.08,
      alpha: 0.7,
    );
    _drawGlowLine(
      canvas,
      center,
      beamEnd,
      LightcorePalette.aether,
      width: math.max(1.2, width * 0.28),
      alpha: 0.5,
    );
    canvas.drawCircle(
      center,
      _coreRadius * 0.14,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = color.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      beamEnd,
      _coreRadius * (0.11 + (lockPulse * 0.03)),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..color = color.withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      beamEnd,
      _coreRadius * (0.08 + (lockPulse * 0.025)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = LightcorePalette.aether.withValues(alpha: 0.56),
    );

    return beamEnd;
  }

  Offset _renderOrbitNodeShot(
    Canvas canvas, {
    required CoreShotState shot,
    required Color color,
    required double width,
  }) {
    final center = Offset(_center.x, _center.y);
    final orbitRadius = _orbitNodeVisualRadius(shot);
    final orbitAngle = _orbitNodeAngleForProgress(shot, shot.progress);
    final orbitNode = Offset(
      center.dx + math.cos(orbitAngle) * orbitRadius,
      center.dy + math.sin(orbitAngle) * orbitRadius,
    );
    final orbitRect = Rect.fromCircle(center: center, radius: orbitRadius);

    canvas.drawCircle(
      center,
      orbitRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.2, width * 0.72)
        ..color = color.withValues(alpha: 0.14),
    );
    canvas.drawArc(
      orbitRect,
      orbitAngle - (math.pi * 0.92),
      math.pi * 1.26,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(4.2, width * 1.4)
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.44),
    );

    for (var ghostIndex = 1; ghostIndex <= 2; ghostIndex++) {
      final ghostAngle = orbitAngle - (ghostIndex * 0.34);
      final ghost = Offset(
        center.dx + math.cos(ghostAngle) * orbitRadius,
        center.dy + math.sin(ghostAngle) * orbitRadius,
      );
      _drawEnergyOrb(
        canvas,
        ghost,
        color,
        _coreRadius * (0.05 - (ghostIndex * 0.008)),
        alpha: 0.18 / ghostIndex,
      );
    }

    _drawGlowLine(
      canvas,
      orbitNode.translate(
        math.cos(orbitAngle + (math.pi / 2)) * _coreRadius * 0.12,
        math.sin(orbitAngle + (math.pi / 2)) * _coreRadius * 0.12,
      ),
      orbitNode.translate(
        math.cos(orbitAngle - (math.pi / 2)) * _coreRadius * 0.12,
        math.sin(orbitAngle - (math.pi / 2)) * _coreRadius * 0.12,
      ),
      LightcorePalette.layer2,
      width: math.max(1.2, width * 0.24),
      alpha: 0.4,
    );
    _drawEnergyOrb(canvas, orbitNode, color, _coreRadius * 0.092, alpha: 1.0);

    return orbitNode;
  }

  Offset _renderShieldHaloShot(
    Canvas canvas, {
    required CoreShotState shot,
    required Color color,
    required double width,
  }) {
    final center = Offset(_center.x, _center.y);
    final open = Curves.easeOutCubic.transform(
      (shot.progress * 3.2).clamp(0.0, 1.0).toDouble(),
    );
    final fade = Curves.easeOutQuad.transform(
      (1 - shot.progress).clamp(0.0, 1.0).toDouble(),
    );
    final pulse =
        0.5 +
        (math.sin((controller.elapsed * 9.0) + (shot.id.hashCode * 0.01)) *
            0.5);
    final shieldRadius = _shieldHaloVisualRadius(shot) * (0.96 + open * 0.04);
    final shimmerRadius = shieldRadius + (_coreRadius * 0.04 * pulse);
    final alpha = open * math.max(0.26, fade);
    final shieldRect = Rect.fromCircle(center: center, radius: shimmerRadius);

    canvas.drawCircle(
      center,
      shimmerRadius,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(7.0, width * 2.1)
        ..color = color.withValues(alpha: 0.18 * alpha),
    );
    canvas.drawCircle(
      center,
      shieldRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(3.4, width * 1.12)
        ..color = color.withValues(alpha: 0.72 * alpha),
    );
    canvas.drawCircle(
      center,
      shieldRadius - (_coreRadius * 0.1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, width * 0.42)
        ..color = LightcorePalette.layer2.withValues(alpha: 0.24 * alpha),
    );
    canvas.drawCircle(
      center,
      shieldRadius + (_coreRadius * 0.08),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, width * 0.36)
        ..color = color.withValues(alpha: 0.3 * alpha),
    );

    final facetPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, width * 0.5)
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(
        color,
        LightcorePalette.mist,
        0.28,
      )!.withValues(alpha: 0.62 * alpha);
    for (var index = 0; index < 6; index++) {
      final startAngle =
          shot.aimAngle + (index * math.pi / 3) + (pulse * math.pi / 32);
      canvas.drawArc(shieldRect, startAngle, math.pi / 5.2, false, facetPaint);
    }

    return Offset(
      center.dx + math.cos(shot.aimAngle) * shieldRadius,
      center.dy + math.sin(shot.aimAngle) * shieldRadius,
    );
  }

  Path _energyBoltPath(
    Offset start,
    Offset end, {
    required double amplitude,
    required double seed,
    required int segments,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt((dx * dx) + (dy * dy));
    if (distance <= 0.001) {
      return Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(end.dx, end.dy);
    }

    final normalX = -dy / distance;
    final normalY = dx / distance;
    final path = Path()..moveTo(start.dx, start.dy);
    for (var index = 1; index < segments; index++) {
      final t = index / segments;
      final point = Offset.lerp(start, end, t)!;
      final envelope = math.sin(math.pi * t);
      final wobble =
          ((math.sin(seed + (t * 12.7)) * 0.62) +
              (math.cos((seed * 0.8) - (t * 18.3)) * 0.38)) *
          amplitude *
          envelope;
      path.lineTo(point.dx + (normalX * wobble), point.dy + (normalY * wobble));
    }
    path.lineTo(end.dx, end.dy);
    return path;
  }

  Offset _perpendicularOffset(Offset start, Offset end, double amount) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt((dx * dx) + (dy * dy));
    if (distance <= 0.001) {
      return Offset.zero;
    }
    return Offset((-dy / distance) * amount, (dx / distance) * amount);
  }

  void _drawLingeringField(
    Canvas canvas,
    Offset center,
    Color color,
    double radius,
    double fade, {
    required double seed,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.16 * fade),
            color.withValues(alpha: 0.08 * fade),
            Colors.transparent,
          ],
          stops: const [0, 0.52, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    for (var index = 0; index < 2; index++) {
      final ripple = radius * (0.52 + (index * 0.18));
      final phase = ((controller.elapsed * 0.8) + (index * 0.28)) % 1.0;
      canvas.drawCircle(
        center,
        ripple + (radius * 0.14 * phase),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = color.withValues(alpha: (0.24 - (phase * 0.12)) * fade),
      );
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = color.withValues(alpha: 0.42 * fade),
    );

    for (var index = 0; index < 3; index++) {
      final angle = seed + (((math.pi * 2) / 3) * index);
      final sparkCenter = Offset(
        center.dx + math.cos(angle) * (radius * 0.72),
        center.dy + math.sin(angle) * (radius * 0.72),
      );
      _drawEnergyOrb(
        canvas,
        sparkCenter,
        index.isEven ? color : LightcorePalette.layer2,
        radius * 0.08,
        alpha: 0.52 * fade,
      );
    }
  }

  void _drawPolygonPerimeterProgress(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required int sides,
    required double rotation,
    required double progress,
    required Paint paint,
  }) {
    final clamped = progress.clamp(0.0, 1.0);
    if (clamped <= 0) {
      return;
    }
    final points = _polygonPoints(center, radius, sides, rotation);
    final totalEdges = sides * clamped;
    final fullEdges = totalEdges.floor();
    final partialEdge = totalEdges - fullEdges;

    for (var index = 0; index < fullEdges; index++) {
      final start = points[index % sides];
      final end = points[(index + 1) % sides];
      canvas.drawLine(start, end, paint);
    }

    if (fullEdges < sides && partialEdge > 0) {
      final start = points[fullEdges % sides];
      final end = points[(fullEdges + 1) % sides];
      final partial = Offset.lerp(start, end, partialEdge)!;
      canvas.drawLine(start, partial, paint);
    }
  }

  Path _curvedLinkPath(Offset start, Offset end, {double bend = 0.14}) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final control = Offset(
      start.dx + (dx * 0.52) + (-dy * bend),
      start.dy + (dy * 0.52) + (dx * bend),
    );
    return Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
  }

  Offset _quadraticPoint(
    Offset start,
    Offset control,
    Offset end,
    double progress,
  ) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final first = Offset.lerp(start, control, clamped)!;
    final second = Offset.lerp(control, end, clamped)!;
    return Offset.lerp(first, second, clamped)!;
  }

  Path _hexPath(Offset center, double radius) {
    return _polygonPath(center, radius, 6, math.pi / 6);
  }

  List<Offset> _polygonPoints(
    Offset center,
    double radius,
    int sides,
    double rotation,
  ) {
    return List<Offset>.generate(sides, (index) {
      final angle = rotation + ((math.pi * 2) / sides) * index;
      return Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
    });
  }

  Path _polygonPath(Offset center, double radius, int sides, double rotation) {
    final path = Path();
    final points = _polygonPoints(center, radius, sides, rotation);
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
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
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = center.translate(-painter.width / 2, -painter.height / 2);
    painter.paint(canvas, offset);
  }
}
