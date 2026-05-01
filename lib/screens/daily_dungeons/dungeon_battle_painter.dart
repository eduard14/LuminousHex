part of '../daily_dungeons_screen.dart';

class _TowerBattleCanvas extends StatelessWidget {
  const _TowerBattleCanvas({
    required this.towerProfile,
    required this.towerLevel,
    required this.integrity,
    required this.activeRaids,
    required this.tint,
    required this.cleared,
    required this.running,
    required this.expired,
  });

  final LightcoreDailyDungeonTowerProfile towerProfile;
  final int towerLevel;
  final double integrity;
  final List<_DungeonRaid> activeRaids;
  final Color tint;
  final bool cleared;
  final bool running;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final raids = activeRaids.toList(growable: false);
    return AspectRatio(
      aspectRatio: 1.35,
      child: CustomPaint(
        painter: _TowerBattlePainter(
          towerProfile: towerProfile,
          towerLevel: towerLevel,
          integrity: integrity,
          activeRaids: raids,
          tint: tint,
          cleared: cleared,
          running: running,
          expired: expired,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _TowerBattlePainter extends CustomPainter {
  const _TowerBattlePainter({
    required this.towerProfile,
    required this.towerLevel,
    required this.integrity,
    required this.activeRaids,
    required this.tint,
    required this.cleared,
    required this.running,
    required this.expired,
  });

  final LightcoreDailyDungeonTowerProfile towerProfile;
  final int towerLevel;
  final double integrity;
  final List<_DungeonRaid> activeRaids;
  final Color tint;
  final bool cleared;
  final bool running;
  final bool expired;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shortest = math.min(size.width, size.height);
    final outerRadius = shortest * 0.34;
    final coreRadius = shortest * 0.18;
    final nodeRadius = shortest * 0.095;
    final resolvedTint = towerProfile.affinity.color;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = resolvedTint.withValues(alpha: 0.34);
    final towerFill = Paint()
      ..style = PaintingStyle.fill
      ..color = resolvedTint.withValues(alpha: expired ? 0.06 : 0.12);

    canvas.drawCircle(
      center,
      outerRadius * 1.18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = LightcorePalette.stroke.withValues(alpha: 0.5),
    );
    canvas.drawCircle(
      center,
      outerRadius * (0.32 + (integrity * 0.86)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = (cleared ? LightcorePalette.success : resolvedTint)
            .withValues(alpha: 0.22 + (integrity * 0.44)),
    );

    final nodes = List<Offset>.generate(
      6,
      (index) => Offset(
        center.dx + (outerRadius * math.cos(_angleFor(index))),
        center.dy + (outerRadius * math.sin(_angleFor(index))),
      ),
    );
    final path = Path()..moveTo(nodes.first.dx, nodes.first.dy);
    for (final node in nodes.skip(1)) {
      path.lineTo(node.dx, node.dy);
    }
    path.close();
    canvas.drawPath(path, ringPaint);

    for (var index = 0; index < nodes.length; index += 1) {
      final node = nodes[index];
      final nodeTint = Color.lerp(
        LightcorePalette.stroke,
        index == 0 ? resolvedTint : tint,
        index == 0 ? 1 : ((towerLevel + index) % 6) / 5,
      )!;
      canvas.drawLine(
        center,
        node,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = resolvedTint.withValues(alpha: index == 0 ? 0.22 : 0.1),
      );
      canvas.drawCircle(
        node,
        nodeRadius,
        Paint()..color = nodeTint.withValues(alpha: 0.16),
      );
      canvas.drawCircle(
        node,
        nodeRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = nodeTint.withValues(alpha: 0.58),
      );
    }

    canvas.drawPath(_hexPath(center, coreRadius), towerFill);
    canvas.drawPath(
      _hexPath(center, coreRadius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = (cleared ? LightcorePalette.success : resolvedTint)
            .withValues(alpha: cleared ? 0.82 : 0.72),
    );
    _drawHexChargeIndicator(
      canvas,
      center,
      color: resolvedTint,
      radius: coreRadius,
      chargeProgress: running ? 0.82 : integrity,
    );
    _paintTowerTraitBadge(
      canvas,
      center,
      projectileType: towerProfile.projectileType,
      payloadType: towerProfile.payloadType,
      level: towerProfile.effectiveDisplayLevel,
      tint: resolvedTint,
      size: coreRadius * 2.2,
    );
    _paintIconGlyph(
      canvas,
      nodes.first,
      towerProjectileIcon(towerProfile.projectileType),
      size: nodeRadius * 0.82,
      color: resolvedTint,
    );

    final raidCount = math.min(activeRaids.length, 12);
    for (var index = 0; index < raidCount; index += 1) {
      final raid = activeRaids[index];
      final angle =
          (-math.pi / 2) +
          ((math.pi * 2) *
              ((index / math.max(1, raidCount)) + (raid.progress * 0.16)));
      final distance = outerRadius * (1.34 - (raid.progress * 0.5));
      final origin = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );
      final color = raid.affinity.color;
      canvas.drawLine(
        origin,
        Offset.lerp(origin, center, 0.34 + (raid.progress * 0.38))!,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = raid.apex ? 3.2 : 2
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: raid.apex ? 0.72 : 0.5),
      );
      canvas.drawCircle(
        origin,
        shortest * (raid.apex ? 0.044 : 0.028),
        Paint()..color = color.withValues(alpha: 0.9),
      );
      if (raid.apex) {
        canvas.drawCircle(
          origin,
          shortest * 0.064,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = LightcorePalette.solar.withValues(alpha: 0.68),
        );
      }
    }

    if (!running && !cleared && !expired) {
      canvas.drawCircle(
        center,
        outerRadius * 1.36,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = LightcorePalette.aether.withValues(alpha: 0.22),
      );
    }
  }

  void _drawHexChargeIndicator(
    Canvas canvas,
    Offset center, {
    required Color color,
    required double radius,
    required double chargeProgress,
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
    canvas.drawPath(
      _hexPath(center, chargeRadius),
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.16 + (clampedCharge * 0.24)),
    );
  }

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (var index = 0; index < 6; index += 1) {
      final angle = (math.pi / 6) + (index * math.pi / 3);
      final point = center.translate(
        math.cos(angle) * radius,
        math.sin(angle) * radius,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  void _paintTowerTraitBadge(
    Canvas canvas,
    Offset center, {
    required ProjectileType projectileType,
    required PayloadType payloadType,
    required int level,
    required Color tint,
    required double size,
  }) {
    final payloadColor = payloadType.affinity?.color ?? LightcorePalette.layer2;
    final vertices = List<Offset>.generate(6, (index) {
      final angle = (math.pi / 6) + (index * math.pi / 3);
      return center.translate(
        math.cos(angle) * size * 0.38,
        math.sin(angle) * size * 0.38,
      );
    }, growable: false);
    final path = Path()..moveTo(vertices.first.dx, vertices.first.dy);
    for (final vertex in vertices.skip(1)) {
      path.lineTo(vertex.dx, vertex.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = payloadColor.withValues(alpha: 0.16),
    );
    for (var edge = 0; edge < 6; edge += 1) {
      _drawHexEdge(
        canvas,
        vertices,
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.1, size * 0.032)
          ..strokeCap = StrokeCap.round
          ..color = LightcorePalette.stroke.withValues(alpha: 0.58),
      );
    }
    final activeEdges = math.max(
      1,
      ((level / LightcoreController.maxTowerLevel) * 6).ceil(),
    );
    for (var edge = 0; edge < activeEdges; edge += 1) {
      _drawHexEdge(
        canvas,
        vertices,
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2.0, size * 0.055)
          ..strokeCap = StrokeCap.round
          ..color = tint.withValues(alpha: 0.96),
      );
    }
    canvas.drawCircle(
      center,
      size * 0.19,
      Paint()..color = payloadColor.withValues(alpha: 0.24),
    );
    _paintIconGlyph(
      canvas,
      center,
      towerProjectileIcon(projectileType),
      size: size * 0.23,
      color: projectileType.affinity.color,
    );
  }

  void _drawHexEdge(
    Canvas canvas,
    List<Offset> vertices,
    int edge,
    Paint paint,
  ) {
    canvas.drawLine(
      vertices[edge % vertices.length],
      vertices[(edge + 1) % vertices.length],
      paint,
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

  @override
  bool shouldRepaint(covariant _TowerBattlePainter oldDelegate) {
    return oldDelegate.towerLevel != towerLevel ||
        oldDelegate.integrity != integrity ||
        oldDelegate.activeRaids != activeRaids ||
        oldDelegate.tint != tint ||
        oldDelegate.towerProfile != towerProfile ||
        oldDelegate.cleared != cleared ||
        oldDelegate.running != running ||
        oldDelegate.expired != expired;
  }

  double _angleFor(int index) => (-math.pi / 2) + (index * math.pi / 3);
}
