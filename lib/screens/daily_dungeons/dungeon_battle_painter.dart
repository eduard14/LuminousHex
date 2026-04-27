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
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LightcorePalette.night.withValues(alpha: 0.58),
              border: Border.all(color: tint.withValues(alpha: 0.42)),
            ),
            child: SizedBox.square(
              dimension: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lv',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: LightcorePalette.mist.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '$towerLevel',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: cleared ? LightcorePalette.success : tint,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

    canvas.drawCircle(center, coreRadius, towerFill);
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = (cleared ? LightcorePalette.success : resolvedTint)
            .withValues(alpha: cleared ? 0.82 : 0.62),
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
