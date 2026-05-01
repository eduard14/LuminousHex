import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lightcore_types.dart';
import '../theme/lightcore_palette.dart';

class LightcoreProjectileFx {
  const LightcoreProjectileFx._();

  static double lineWidth(ProjectileType projectileType, double unit) {
    return switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.thread => unit * 0.045,
      ProjectileBehaviorProfile.pulse => unit * 0.06,
      ProjectileBehaviorProfile.burst => unit * 0.08,
      ProjectileBehaviorProfile.chain => unit * 0.055,
      ProjectileBehaviorProfile.split => unit * 0.05,
      ProjectileBehaviorProfile.lance => unit * 0.072,
      ProjectileBehaviorProfile.explosion => unit * 0.09,
      ProjectileBehaviorProfile.wave => unit * 0.066,
      ProjectileBehaviorProfile.nova => unit * 0.08,
    };
  }

  static Offset angleOffset(double angle, double distance) {
    return Offset(math.cos(angle) * distance, math.sin(angle) * distance);
  }

  static void drawGlowLine(
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

  static void drawEnergyOrb(
    Canvas canvas,
    Offset center,
    Color color,
    double radius, {
    double alpha = 1.0,
    bool core = true,
  }) {
    canvas.drawCircle(
      center,
      radius * 2.6,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = color.withValues(alpha: 0.18 * alpha),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color.withValues(alpha: 0.88 * alpha),
    );
    if (!core) {
      return;
    }
    canvas.drawCircle(
      center,
      radius * 0.42,
      Paint()..color = LightcorePalette.layer2.withValues(alpha: 0.72 * alpha),
    );
  }

  static void drawEnergyBolt(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color, {
    required double width,
    required double amplitude,
    required double seed,
    bool branch = false,
    double alpha = 1.0,
    int segments = 6,
  }) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance <= 0) {
      return;
    }
    final normal = Offset(-delta.dy / distance, delta.dx / distance);
    final path = Path()..moveTo(start.dx, start.dy);
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
        ..color = color.withValues(alpha: 0.2 * alpha),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.86 * alpha),
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
        ..color = color.withValues(alpha: 0.42 * alpha),
    );
  }

  static void drawFireBurst(
    Canvas canvas, {
    required Offset origin,
    required Color color,
    required double aimAngle,
    required ProjectileType projectileType,
    required double progress,
    required double alpha,
    required double unit,
    required double seed,
  }) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final open = Curves.easeOutCubic.transform(clamped);
    final fade = Curves.easeOutQuad.transform(1 - clamped) * alpha;
    final radius = unit * (0.22 + (open * 0.30));
    final width = lineWidth(projectileType, unit);
    canvas.drawCircle(
      origin,
      radius * 1.65,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = color.withValues(alpha: 0.18 * fade),
    );

    switch (projectileType.behaviorProfile) {
      case ProjectileBehaviorProfile.thread:
        drawGlowLine(
          canvas,
          origin,
          origin + angleOffset(aimAngle, radius * 1.15),
          color,
          width: math.max(1.4, width),
          alpha: 0.74 * fade,
        );
        if (projectileType == ProjectileType.heavyShot) {
          canvas.drawPath(
            _polygonPath(origin, radius * 0.52, 6),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(1.2, width)
              ..color = color.withValues(alpha: 0.56 * fade),
          );
        }
      case ProjectileBehaviorProfile.chain:
        drawEnergyBolt(
          canvas,
          origin,
          origin + angleOffset(aimAngle, radius * 1.1),
          Color.lerp(color, LightcorePalette.gilded, 0.5)!,
          width: math.max(1.4, width),
          amplitude: radius * 0.18,
          seed: seed,
          branch: true,
          alpha: fade,
        );
      case ProjectileBehaviorProfile.pulse:
        for (var index = 0; index < 2; index += 1) {
          canvas.drawCircle(
            origin,
            radius * (0.52 + (index * 0.22)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(1.1, width)
              ..color = color.withValues(alpha: (0.42 - index * 0.1) * fade),
          );
        }
      case ProjectileBehaviorProfile.split:
        for (final offset in <double>[-0.34, 0, 0.34]) {
          drawGlowLine(
            canvas,
            origin,
            origin + angleOffset(aimAngle + offset, radius * 1.05),
            color,
            width: math.max(1.1, width * (offset == 0 ? 1 : 0.64)),
            alpha: (offset == 0 ? 0.68 : 0.44) * fade,
          );
        }
      case ProjectileBehaviorProfile.lance:
        final tip = origin + angleOffset(aimAngle, radius * 1.22);
        final left = origin + angleOffset(aimAngle - 0.34, radius * 0.34);
        final right = origin + angleOffset(aimAngle + 0.34, radius * 0.34);
        final path = Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(left.dx, left.dy)
          ..lineTo(origin.dx, origin.dy)
          ..lineTo(right.dx, right.dy)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.2, width)
            ..color = color.withValues(alpha: 0.64 * fade),
        );
      case ProjectileBehaviorProfile.explosion:
        final forward = origin + angleOffset(aimAngle, radius * 0.46);
        canvas.drawCircle(
          forward,
          radius * 0.72,
          Paint()
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
            ..color = color.withValues(alpha: 0.18 * fade),
        );
        canvas.drawCircle(
          forward,
          radius * 0.48,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.4, width)
            ..color = color.withValues(alpha: 0.62 * fade),
        );
      case ProjectileBehaviorProfile.burst || ProjectileBehaviorProfile.nova:
        final count =
            projectileType.behaviorProfile == ProjectileBehaviorProfile.nova
            ? 7
            : 5;
        for (var index = 0; index < count; index += 1) {
          final angle = aimAngle + (((math.pi * 2) / count) * index);
          drawGlowLine(
            canvas,
            origin + angleOffset(angle, radius * 0.12),
            origin + angleOffset(angle, radius * (0.7 + open * 0.28)),
            index.isEven ? color : LightcorePalette.layer2,
            width: math.max(1.0, width * 0.56),
            alpha: 0.42 * fade,
          );
        }
      case ProjectileBehaviorProfile.wave:
        for (var index = 0; index < 3; index += 1) {
          canvas.drawArc(
            Rect.fromCircle(
              center: origin,
              radius: radius * (0.72 + index * 0.2),
            ),
            aimAngle - (math.pi * 0.86),
            math.pi * 1.72,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = math.max(1.1, width)
              ..color = color.withValues(alpha: (0.42 - index * 0.08) * fade),
          );
        }
    }
  }

  static void drawProjectileTrail(
    Canvas canvas, {
    required ProjectileType projectileType,
    required Offset start,
    required Offset end,
    required Offset current,
    required Color color,
    required double width,
    required double seed,
    required double alpha,
    required double unit,
    required double progress,
    bool includeOrb = true,
  }) {
    final origin = Offset.lerp(start, current, 0.28)!;
    if (projectileType.usesBlueLaser) {
      _drawBlueFocusLaserShot(
        canvas,
        start: start,
        end: end,
        color: color,
        width: width,
        seed: seed,
        alpha: alpha,
        unit: unit,
      );
      return;
    }
    if (projectileType == ProjectileType.shieldHalo) {
      _drawShieldHaloShot(
        canvas,
        center: start,
        radius: (end - start).distance,
        color: color,
        width: width,
        seed: seed,
        progress: progress,
        alpha: alpha,
        unit: unit,
      );
      return;
    }
    if (projectileType == ProjectileType.orbitNode) {
      _drawOrbitNodeShot(
        canvas,
        start: start,
        end: end,
        color: color,
        width: width,
        progress: progress,
        alpha: alpha,
        unit: unit,
      );
      return;
    }

    switch (projectileType.behaviorProfile) {
      case ProjectileBehaviorProfile.thread:
        if (projectileType == ProjectileType.heavyShot) {
          _renderWobbleTrail(
            canvas,
            start: start,
            current: current,
            color: color,
            width: width,
            seed: seed,
            trailLength: unit * 0.96,
            wobble: unit * 0.05,
            steps: 8,
            alpha: alpha,
          );
        } else {
          drawGlowLine(
            canvas,
            origin,
            current,
            color,
            width: width,
            alpha: 0.78 * alpha,
          );
        }
      case ProjectileBehaviorProfile.chain:
        drawEnergyBolt(
          canvas,
          origin,
          current,
          projectileType == ProjectileType.chainArc
              ? Color.lerp(color, LightcorePalette.gilded, 0.7)!
              : color,
          width: width,
          amplitude: unit * 0.13,
          seed: seed,
          branch: true,
          alpha: 0.86 * alpha,
        );
        if (projectileType == ProjectileType.chainArc) {
          drawGlowLine(
            canvas,
            origin,
            current,
            LightcorePalette.solar,
            width: math.max(1.0, width * 0.34),
            alpha: 0.5 * alpha,
          );
        }
      case ProjectileBehaviorProfile.lance:
        drawEnergyBolt(
          canvas,
          origin,
          current,
          color,
          width: width,
          amplitude: unit * 0.045,
          seed: seed,
          alpha: 0.72 * alpha,
        );
      case ProjectileBehaviorProfile.explosion:
        if (projectileType == ProjectileType.coreBomb) {
          _renderWobbleTrail(
            canvas,
            start: start,
            current: current,
            color: color,
            width: width,
            seed: seed,
            trailLength: unit * 0.44,
            wobble: unit * 0.016,
            steps: 4,
            alpha: alpha,
          );
        } else {
          drawGlowLine(
            canvas,
            origin,
            current,
            color,
            width: width,
            alpha: 0.58 * alpha,
          );
        }
        canvas.drawPath(
          _polygonPath(current, width * 2.4, 6),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.0, width * 0.42)
            ..color = LightcorePalette.layer2.withValues(alpha: 0.58 * alpha),
        );
      case ProjectileBehaviorProfile.burst:
      case ProjectileBehaviorProfile.nova:
        drawGlowLine(
          canvas,
          origin,
          current,
          color,
          width: width,
          alpha: 0.58 * alpha,
        );
        canvas.drawCircle(
          current,
          width * 2.5,
          Paint()
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
            ..color = color.withValues(alpha: 0.18 * alpha),
        );
      case ProjectileBehaviorProfile.pulse:
      case ProjectileBehaviorProfile.split:
        drawGlowLine(
          canvas,
          origin,
          current,
          color,
          width: width,
          alpha: 0.66 * alpha,
        );
      case ProjectileBehaviorProfile.wave:
        if (projectileType.usesRadialWave) {
          final waveRadius = math.max(
            unit * 0.14,
            (end - start).distance * progress,
          );
          canvas.drawCircle(
            start,
            waveRadius,
            Paint()
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
              ..style = PaintingStyle.stroke
              ..strokeWidth = width + 3
              ..color = color.withValues(alpha: 0.16 * alpha),
          );
          canvas.drawCircle(
            start,
            waveRadius,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = width
              ..color = color.withValues(alpha: 0.72 * alpha),
          );
        } else {
          drawGlowLine(
            canvas,
            origin,
            current,
            color,
            width: width,
            alpha: 0.66 * alpha,
          );
        }
    }
    if (includeOrb) {
      drawEnergyOrb(canvas, current, color, width * 1.45, alpha: 0.82 * alpha);
    }
  }

  static void _drawBlueFocusLaserShot(
    Canvas canvas, {
    required Offset start,
    required Offset end,
    required Color color,
    required double width,
    required double seed,
    required double alpha,
    required double unit,
  }) {
    final lockPulse = 0.5 + (math.sin(seed * 1.7) * 0.5);
    for (final trailScale in <double>[0.62, 0.8]) {
      drawGlowLine(
        canvas,
        start,
        Offset.lerp(start, end, trailScale)!,
        color,
        width: width * (0.36 + (trailScale * 0.24)),
        alpha: 0.2 * alpha,
      );
    }
    drawGlowLine(
      canvas,
      start,
      end,
      color,
      width: width * 1.08,
      alpha: 0.7 * alpha,
    );
    drawGlowLine(
      canvas,
      start,
      end,
      LightcorePalette.aether,
      width: math.max(1.0, width * 0.28),
      alpha: 0.5 * alpha,
    );
    canvas.drawCircle(
      end,
      unit * (0.1 + (lockPulse * 0.03)),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = color.withValues(alpha: 0.28 * alpha),
    );
  }

  static void _drawOrbitNodeShot(
    Canvas canvas, {
    required Offset start,
    required Offset end,
    required Color color,
    required double width,
    required double progress,
    required double alpha,
    required double unit,
  }) {
    final orbitCenter = Offset.lerp(start, end, progress.clamp(0.0, 1.0))!;
    final orbitRadius = unit * 0.22;
    final orbitAngle = progress * math.pi * 2;
    final orbitNode = orbitCenter.translate(
      math.cos(orbitAngle) * orbitRadius,
      math.sin(orbitAngle) * orbitRadius,
    );
    canvas.drawCircle(
      orbitCenter,
      orbitRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, width * 0.72)
        ..color = color.withValues(alpha: 0.14 * alpha),
    );
    drawGlowLine(
      canvas,
      start,
      orbitCenter,
      color,
      width: width * 0.74,
      alpha: 0.44 * alpha,
    );
    drawEnergyOrb(canvas, orbitNode, color, unit * 0.092, alpha: alpha);
  }

  static void _drawShieldHaloShot(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double width,
    required double seed,
    required double progress,
    required double alpha,
    required double unit,
  }) {
    final open = Curves.easeOutCubic.transform(
      (progress * 3.2).clamp(0.0, 1.0),
    );
    final pulse = 0.5 + (math.sin(seed * 1.3) * 0.5);
    final shieldRadius = radius * (0.96 + (open * 0.04));
    final shimmerRadius = shieldRadius + (unit * 0.04 * pulse);
    final shieldAlpha = open * math.max(0.26, alpha);
    final shieldRect = Rect.fromCircle(center: center, radius: shimmerRadius);
    canvas.drawCircle(
      center,
      shimmerRadius,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(5.0, width * 2.1)
        ..color = color.withValues(alpha: 0.18 * shieldAlpha),
    );
    canvas.drawCircle(
      center,
      shieldRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.4, width * 1.12)
        ..color = color.withValues(alpha: 0.68 * shieldAlpha),
    );
    final facetPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, width * 0.5)
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(
        color,
        LightcorePalette.mist,
        0.28,
      )!.withValues(alpha: 0.58 * shieldAlpha);
    for (var index = 0; index < 6; index += 1) {
      canvas.drawArc(
        shieldRect,
        (index * math.pi / 3) + (pulse * math.pi / 32),
        math.pi / 5.2,
        false,
        facetPaint,
      );
    }
  }

  static void _renderWobbleTrail(
    Canvas canvas, {
    required Offset start,
    required Offset current,
    required Color color,
    required double width,
    required double seed,
    required double trailLength,
    required double wobble,
    required int steps,
    required double alpha,
  }) {
    final delta = current - start;
    final distance = delta.distance;
    if (distance <= 0.001) {
      return;
    }
    final direction = Offset(delta.dx / distance, delta.dy / distance);
    final normal = Offset(-direction.dy, direction.dx);
    final clampedTrailLength = math.min(distance, trailLength);
    final trailStart = current - (direction * clampedTrailLength);
    final phase = seed * 0.42;
    final trailPath = Path();
    for (var step = 0; step <= steps; step += 1) {
      final t = step / steps;
      final base = Offset.lerp(trailStart, current, t)!;
      final offset =
          (math.sin(phase + (t * math.pi * 5.2)) * 0.72 +
              math.sin((phase * 1.7) - (t * math.pi * 3.1)) * 0.28) *
          wobble *
          (1 - (t * 0.35));
      final point = base + (normal * offset);
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
        ..color = color.withValues(alpha: 0.18 * alpha),
    );
    canvas.drawPath(
      trailPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.66 * alpha),
    );
    canvas.drawPath(
      trailPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, width * 0.28)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = LightcorePalette.layer2.withValues(alpha: 0.42 * alpha),
    );
  }

  static Path _polygonPath(Offset center, double radius, int sides) {
    final path = Path();
    for (var index = 0; index < sides; index += 1) {
      final angle = (math.pi / 6) + ((math.pi * 2 * index) / sides);
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
}
