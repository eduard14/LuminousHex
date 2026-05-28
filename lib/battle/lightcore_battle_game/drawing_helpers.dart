part of '../lightcore_battle_game.dart';

extension LightcoreBattleGameDrawingHelpers on LightcoreBattleGame {
  Offset _shotStartOffset({required bool layer2}) {
    return layer2
        ? Offset(_center.x, _center.y - (_coreRadius * 1.55))
        : Offset(_center.x, _center.y);
  }

  void _renderGuidePulse(
    Canvas canvas,
    Offset center, {
    required double radius,
    required Color tint,
    bool showTapCue = true,
    String? tapCueLabel,
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
        label: tapCueLabel,
      );
    }
  }

  void _renderTapCue(
    Canvas canvas,
    Offset center, {
    required double radius,
    required Color tint,
    String? label,
  }) {
    final cueRadius = radius.clamp(10.0, 22.0).toDouble();
    final progress = ((math.sin(controller.elapsed * 5.3) + 1) * 0.5)
        .toDouble();
    final ringProgress = Curves.easeOutCubic.transform(
      (controller.elapsed * 1.35) % 1,
    );
    final pressOffset = Offset(0, cueRadius * 0.16 * progress);
    final iconCenter = center + pressOffset;
    final cueLabel = label?.trim();
    final hasLabel = cueLabel != null && cueLabel.isNotEmpty;
    final outerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, cueRadius * 0.08)
      ..color = tint.withValues(alpha: 0.54 * (1 - ringProgress));
    final cueClip = Rect.fromCircle(
      center: center,
      radius: cueRadius * 2.2,
    ).inflate(2);
    final labelClip = Rect.fromLTWH(iconCenter.dx, iconCenter.dy - 32, 132, 64);

    canvas.save();
    canvas.clipRect(hasLabel ? cueClip.expandToInclude(labelClip) : cueClip);
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
    if (hasLabel) {
      _paintTapCueLabel(canvas, iconCenter, cueLabel, cueRadius, tint);
    }
    canvas.restore();
  }

  void _paintTapCueLabel(
    Canvas canvas,
    Offset iconCenter,
    String label,
    double cueRadius,
    Color tint,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: LightcorePalette.mist,
          fontSize: cueRadius.clamp(10.0, 13.0).toDouble(),
          fontWeight: FontWeight.w900,
          height: 1.05,
          shadows: [
            Shadow(
              color: LightcorePalette.night.withValues(alpha: 0.7),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      maxLines: 2,
      ellipsis: '...',
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 96);
    final labelRect = Rect.fromLTWH(
      iconCenter.dx + (cueRadius * 0.82),
      iconCenter.dy - (textPainter.height / 2) - 6,
      textPainter.width + 18,
      textPainter.height + 12,
    );
    final rounded = RRect.fromRectAndRadius(
      labelRect,
      Radius.circular(labelRect.height / 2),
    );

    canvas.drawRRect(
      rounded,
      Paint()..color = LightcorePalette.panelRaised.withValues(alpha: 0.94),
    );
    canvas.drawRRect(
      rounded,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = tint.withValues(alpha: 0.72),
    );
    textPainter.paint(
      canvas,
      Offset(
        labelRect.left + ((labelRect.width - textPainter.width) / 2),
        labelRect.top + 6,
      ),
    );
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
      final hitScale = controller.tutorialHighlightsBattleSlot(index)
          ? 1.55
          : 1.05;
      if (pointer.distanceTo(_slotPositions[index]) <= _slotRadius * hitScale) {
        return index;
      }
    }
    return null;
  }

  String? _hitTestEnemy(Vector2 pointer) {
    for (final enemy in controller.enemies.toList().reversed) {
      if (_enemyRevealProgress(enemy) <= 0) {
        continue;
      }
      final position = _enemyPosition(enemy);
      final targetRadius =
          _enemyRadius(enemy) * (enemy.config.isBoss ? 2.1 : 1.7);
      final dx = pointer.x - position.dx;
      final dy = pointer.y - position.dy;
      if (math.sqrt((dx * dx) + (dy * dy)) <= targetRadius) {
        return enemy.id;
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

  bool _shotUsesBlueFocusLaser(CoreShotState shot) =>
      !shot.layer2 &&
      shot.projectileType.usesBlueLaser &&
      shot.affinity == PrototypeAffinity.aether;

  EnemyState? _enemyForShotTarget(CoreShotState shot) {
    for (final enemy in controller.enemies) {
      if (enemy.id == shot.enemyId) {
        return enemy;
      }
    }
    return null;
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
