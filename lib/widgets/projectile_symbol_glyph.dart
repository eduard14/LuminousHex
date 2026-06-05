import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lightcore_types.dart';

void paintProjectileSymbolGlyph(
  Canvas canvas,
  Offset center, {
  required ProjectileType projectileType,
  required double size,
  required Color color,
  double opacity = 1,
}) {
  final resolvedOpacity = opacity.clamp(0.0, 1.0).toDouble();
  if (resolvedOpacity <= 0) {
    return;
  }

  final radius = size * 0.5;
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.4, size * 0.11)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color.withValues(alpha: resolvedOpacity);
  final thinStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.1, size * 0.07)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color.withValues(alpha: resolvedOpacity * 0.86);
  final fill = Paint()
    ..style = PaintingStyle.fill
    ..color = color.withValues(alpha: resolvedOpacity);

  switch (projectileType) {
    case ProjectileType.starBolt:
      canvas.drawCircle(center, radius * 0.34, fill);
      break;
    case ProjectileType.threadBeam:
      _drawRaylineSymbol(canvas, center, radius, stroke, fill);
      break;
    case ProjectileType.heavyShot:
      _drawWeightSymbol(canvas, center, radius, stroke, fill);
      break;
    case ProjectileType.coreBomb:
      _drawExplosionSymbol(canvas, center, radius, stroke, fill);
      break;
    case ProjectileType.chainArc:
      _drawLightningSymbol(canvas, center, radius, fill);
      break;
    case ProjectileType.pulseRing:
      _drawRippleSymbol(canvas, center, radius, stroke, thinStroke);
      break;
    case ProjectileType.shieldHalo:
      _drawShieldSymbol(canvas, center, radius, fill);
      break;
    default:
      _drawBehaviorFallback(
        canvas,
        center,
        projectileType,
        radius,
        stroke,
        fill,
      );
  }
}

void _drawRaylineSymbol(
  Canvas canvas,
  Offset center,
  double radius,
  Paint stroke,
  Paint fill,
) {
  canvas.drawLine(
    center.translate(-radius * 1.28, 0),
    center.translate(radius * 0.48, 0),
    stroke,
  );
  canvas.drawCircle(center.translate(radius * 0.46, 0), radius * 0.48, fill);

  final rayPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke.strokeWidth
    ..strokeCap = StrokeCap.round
    ..color = stroke.color;
  for (var index = 0; index < 8; index += 1) {
    final angle = (math.pi * 2 / 8) * index;
    final start = center.translate(
      radius * 0.46 + math.cos(angle) * radius * 0.48,
      math.sin(angle) * radius * 0.48,
    );
    final end = center.translate(
      radius * 0.46 + math.cos(angle) * radius * 0.82,
      math.sin(angle) * radius * 0.82,
    );
    canvas.drawLine(start, end, rayPaint);
  }
}

void _drawWeightSymbol(
  Canvas canvas,
  Offset center,
  double radius,
  Paint stroke,
  Paint fill,
) {
  final body = RRect.fromRectAndCorners(
    Rect.fromCenter(
      center: center.translate(0, radius * 0.18),
      width: radius * 1.28,
      height: radius * 1.0,
    ),
    topLeft: Radius.circular(radius * 0.22),
    topRight: Radius.circular(radius * 0.22),
    bottomLeft: Radius.circular(radius * 0.14),
    bottomRight: Radius.circular(radius * 0.14),
  );
  canvas.drawRRect(body, fill);
  canvas.drawArc(
    Rect.fromCenter(
      center: center.translate(0, -radius * 0.28),
      width: radius * 0.78,
      height: radius * 0.58,
    ),
    math.pi,
    math.pi,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = stroke.color,
  );
}

void _drawExplosionSymbol(
  Canvas canvas,
  Offset center,
  double radius,
  Paint stroke,
  Paint fill,
) {
  canvas.drawCircle(center, radius * 0.42, fill);
  for (var index = 0; index < 10; index += 1) {
    final angle = (math.pi * 2 / 10) * index;
    final start = center.translate(
      math.cos(angle) * radius * 0.44,
      math.sin(angle) * radius * 0.44,
    );
    final end = center.translate(
      math.cos(angle) * radius * 0.9,
      math.sin(angle) * radius * 0.9,
    );
    canvas.drawLine(start, end, stroke);
  }
}

void _drawLightningSymbol(
  Canvas canvas,
  Offset center,
  double radius,
  Paint fill,
) {
  final bolt = Path()
    ..moveTo(center.dx + radius * 0.18, center.dy - radius * 0.92)
    ..lineTo(center.dx - radius * 0.5, center.dy + radius * 0.02)
    ..lineTo(center.dx + radius * 0.02, center.dy + radius * 0.02)
    ..lineTo(center.dx - radius * 0.2, center.dy + radius * 0.92)
    ..lineTo(center.dx + radius * 0.58, center.dy - radius * 0.14)
    ..lineTo(center.dx + radius * 0.1, center.dy - radius * 0.14)
    ..close();
  canvas.drawPath(bolt, fill);
}

void _drawRippleSymbol(
  Canvas canvas,
  Offset center,
  double radius,
  Paint stroke,
  Paint thinStroke,
) {
  for (var index = 0; index < 3; index += 1) {
    final arcRadius = radius * (0.3 + (index * 0.24));
    canvas.drawArc(
      Rect.fromCircle(
        center: center.translate(-radius * 0.22, 0),
        radius: arcRadius,
      ),
      -math.pi / 3,
      math.pi * 2 / 3,
      false,
      index == 0 ? stroke : thinStroke,
    );
  }
}

void _drawShieldSymbol(
  Canvas canvas,
  Offset center,
  double radius,
  Paint fill,
) {
  final shield = Path()
    ..moveTo(center.dx, center.dy - radius * 0.96)
    ..cubicTo(
      center.dx + radius * 0.48,
      center.dy - radius * 0.78,
      center.dx + radius * 0.72,
      center.dy - radius * 0.66,
      center.dx + radius * 0.78,
      center.dy - radius * 0.56,
    )
    ..lineTo(center.dx + radius * 0.62, center.dy + radius * 0.18)
    ..cubicTo(
      center.dx + radius * 0.52,
      center.dy + radius * 0.52,
      center.dx + radius * 0.24,
      center.dy + radius * 0.78,
      center.dx,
      center.dy + radius * 0.94,
    )
    ..cubicTo(
      center.dx - radius * 0.24,
      center.dy + radius * 0.78,
      center.dx - radius * 0.52,
      center.dy + radius * 0.52,
      center.dx - radius * 0.62,
      center.dy + radius * 0.18,
    )
    ..lineTo(center.dx - radius * 0.78, center.dy - radius * 0.56)
    ..cubicTo(
      center.dx - radius * 0.72,
      center.dy - radius * 0.66,
      center.dx - radius * 0.48,
      center.dy - radius * 0.78,
      center.dx,
      center.dy - radius * 0.96,
    )
    ..close();
  canvas.drawPath(shield, fill);
}

void _drawBehaviorFallback(
  Canvas canvas,
  Offset center,
  ProjectileType projectileType,
  double radius,
  Paint stroke,
  Paint fill,
) {
  switch (projectileType.behaviorProfile) {
    case ProjectileBehaviorProfile.thread:
      canvas.drawLine(
        center.translate(-radius * 0.86, radius * 0.32),
        center.translate(radius * 0.86, -radius * 0.32),
        stroke,
      );
      canvas.drawCircle(center, radius * 0.16, fill);
    case ProjectileBehaviorProfile.pulse:
      _drawLightningSymbol(canvas, center, radius, fill);
    case ProjectileBehaviorProfile.burst:
      for (var index = 0; index < 6; index += 1) {
        final angle = (math.pi * 2 / 6) * index;
        canvas.drawLine(
          center,
          center.translate(math.cos(angle) * radius, math.sin(angle) * radius),
          stroke,
        );
      }
      canvas.drawCircle(center, radius * 0.18, fill);
    case ProjectileBehaviorProfile.chain:
      final left = center.translate(-radius * 0.58, radius * 0.2);
      final right = center.translate(radius * 0.58, -radius * 0.2);
      canvas.drawCircle(left, radius * 0.2, stroke);
      canvas.drawCircle(right, radius * 0.2, stroke);
      canvas.drawLine(left, right, stroke);
    case ProjectileBehaviorProfile.split:
      final stem = center.translate(-radius * 0.72, radius * 0.52);
      final fork = center.translate(-radius * 0.04, -radius * 0.04);
      canvas.drawLine(stem, fork, stroke);
      canvas.drawLine(
        fork,
        center.translate(radius * 0.72, -radius * 0.52),
        stroke,
      );
      canvas.drawLine(
        fork,
        center.translate(radius * 0.74, radius * 0.34),
        stroke,
      );
    case ProjectileBehaviorProfile.lance:
      canvas.drawLine(
        center.translate(-radius * 0.9, 0),
        center.translate(radius * 0.9, 0),
        stroke,
      );
      canvas.drawCircle(center, radius * 0.42, stroke);
    case ProjectileBehaviorProfile.explosion:
      _drawExplosionSymbol(canvas, center, radius, stroke, fill);
    case ProjectileBehaviorProfile.wave:
      _drawRippleSymbol(canvas, center, radius, stroke, stroke);
    case ProjectileBehaviorProfile.nova:
      canvas.drawCircle(center, radius * 0.32, fill);
      for (var index = 0; index < 6; index += 1) {
        final angle = (math.pi * 2 / 6) * index;
        canvas.drawLine(
          center.translate(
            math.cos(angle) * radius * 0.42,
            math.sin(angle) * radius * 0.42,
          ),
          center.translate(
            math.cos(angle) * radius * 0.88,
            math.sin(angle) * radius * 0.88,
          ),
          stroke,
        );
      }
  }
}
