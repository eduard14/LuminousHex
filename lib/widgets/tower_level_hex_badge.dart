import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lightcore_types.dart';
import '../theme/lightcore_palette.dart';

class TowerLevelHexBadge extends StatelessWidget {
  const TowerLevelHexBadge({
    super.key,
    required this.level,
    required this.maxLevel,
    required this.projectileType,
    required this.payloadType,
    required this.tint,
    required this.complete,
    this.size = 54,
    this.semanticLabel,
  });

  final int level;
  final int maxLevel;
  final ProjectileType projectileType;
  final PayloadType payloadType;
  final Color tint;
  final bool complete;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final payloadColor = payloadType.affinity?.color ?? LightcorePalette.layer2;
    final projectileColor = projectileType.affinity.color;

    return Semantics(
      label:
          semanticLabel ??
          '${projectileType.label} tower level $level of $maxLevel, ${payloadType.label} payload${complete ? ', complete' : ''}',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _TowerLevelHexBadgePainter(
                level: level,
                maxLevel: maxLevel,
                tint: tint,
                payloadColor: payloadColor,
                complete: complete,
              ),
            ),
            Container(
              width: size * 0.48,
              height: size * 0.48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: payloadColor.withValues(alpha: 0.24),
                border: Border.all(
                  color: payloadColor.withValues(alpha: 0.72),
                  width: math.max(1.0, size * 0.025),
                ),
              ),
              child: Icon(
                towerProjectileIcon(projectileType),
                size: size * 0.28,
                color: projectileColor,
              ),
            ),
            if (complete)
              Positioned(
                right: size * 0.02,
                bottom: size * 0.02,
                child: Container(
                  width: size * 0.24,
                  height: size * 0.24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: LightcorePalette.success.withValues(alpha: 0.92),
                    border: Border.all(
                      color: LightcorePalette.night.withValues(alpha: 0.8),
                      width: math.max(1.0, size * 0.018),
                    ),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: size * 0.17,
                    color: LightcorePalette.night,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TowerLevelHexBadgePainter extends CustomPainter {
  const _TowerLevelHexBadgePainter({
    required this.level,
    required this.maxLevel,
    required this.tint,
    required this.payloadColor,
    required this.complete,
  });

  final int level;
  final int maxLevel;
  final Color tint;
  final Color payloadColor;
  final bool complete;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.42;
    final vertices = _flatTopHexVertices(center, radius);
    final path = Path()..moveTo(vertices.first.dx, vertices.first.dy);
    for (final vertex in vertices.skip(1)) {
      path.lineTo(vertex.dx, vertex.dy);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = payloadColor.withValues(alpha: 0.10),
    );

    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, size.shortestSide * 0.035)
      ..strokeCap = StrokeCap.round
      ..color = LightcorePalette.stroke.withValues(alpha: 0.58);
    for (var edge = 0; edge < 6; edge += 1) {
      _drawEdge(canvas, vertices, edge, backgroundPaint);
    }

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.2, size.shortestSide * 0.065)
      ..strokeCap = StrokeCap.round
      ..color = (complete ? LightcorePalette.success : tint).withValues(
        alpha: 0.96,
      );

    for (final edge in _activeEdges(level, maxLevel)) {
      _drawEdge(canvas, vertices, edge, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TowerLevelHexBadgePainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.maxLevel != maxLevel ||
        oldDelegate.tint != tint ||
        oldDelegate.payloadColor != payloadColor ||
        oldDelegate.complete != complete;
  }

  List<Offset> _flatTopHexVertices(Offset center, double radius) {
    return <Offset>[
      for (final angle in <double>[
        -math.pi * 2 / 3,
        -math.pi / 3,
        0,
        math.pi / 3,
        math.pi * 2 / 3,
        math.pi,
      ])
        Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        ),
    ];
  }

  void _drawEdge(Canvas canvas, List<Offset> vertices, int edge, Paint paint) {
    canvas.drawLine(vertices[edge], vertices[(edge + 1) % 6], paint);
  }

  List<int> _activeEdges(int level, int maxLevel) {
    final clamped = level.clamp(0, maxLevel).toInt();
    if (clamped <= 0) {
      return const <int>[];
    }
    final normalized = ((clamped / maxLevel) * 5).ceil().clamp(1, 5).toInt();
    return switch (normalized) {
      1 => const <int>[0],
      2 => const <int>[1, 5],
      3 => const <int>[1, 3, 5],
      4 => const <int>[0, 1, 3, 5],
      _ => const <int>[0, 1, 2, 3, 4, 5],
    };
  }
}

IconData towerProjectileIcon(ProjectileType type) {
  if (type == ProjectileType.shieldHalo) {
    return Icons.shield_moon_rounded;
  }
  return switch (type.behaviorProfile) {
    ProjectileBehaviorProfile.thread => Icons.timeline_rounded,
    ProjectileBehaviorProfile.pulse => Icons.bolt_rounded,
    ProjectileBehaviorProfile.burst => Icons.auto_awesome_rounded,
    ProjectileBehaviorProfile.chain => Icons.device_hub_rounded,
    ProjectileBehaviorProfile.split => Icons.call_split_rounded,
    ProjectileBehaviorProfile.lance => Icons.center_focus_strong_rounded,
    ProjectileBehaviorProfile.explosion => Icons.flare_rounded,
    ProjectileBehaviorProfile.wave => Icons.radar_rounded,
    ProjectileBehaviorProfile.nova => Icons.blur_on_rounded,
  };
}
