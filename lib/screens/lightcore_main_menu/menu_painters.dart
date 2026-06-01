part of '../lightcore_main_menu_screen.dart';

class _MenuAtmospherePainter extends CustomPainter {
  const _MenuAtmospherePainter({
    required this.phase,
    required this.isLoading,
    required this.canStart,
  });

  final double phase;
  final bool isLoading;
  final bool canStart;

  @override
  void paint(Canvas canvas, Size size) {
    final isWide = size.width > size.height * 1.05;
    final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;
    final spinPhase = phase * math.pi * 2;
    final accent = canStart
        ? LightcorePalette.verdant
        : (isLoading ? LightcorePalette.aether : LightcorePalette.warning);
    final secondary = canStart
        ? LightcorePalette.aether
        : (isLoading ? LightcorePalette.violet : LightcorePalette.stroke);
    final coreCenter = Offset(
      size.width / 2,
      size.height * (isWide ? 0.56 : 0.69),
    );

    final topGlowRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.08),
      width: size.width * 0.54,
      height: size.height * 0.24,
    );
    canvas.drawRect(
      topGlowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            LightcorePalette.aether.withValues(alpha: 0.16 + (pulse * 0.04)),
            Colors.transparent,
          ],
        ).createShader(topGlowRect),
    );

    final beamRect = Rect.fromCenter(
      center: Offset(coreCenter.dx, size.height * 0.6),
      width: math.max(size.width * 0.18, 180),
      height: size.height * 0.72,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(beamRect, const Radius.circular(120)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            LightcorePalette.aether.withValues(alpha: 0.04),
            secondary.withValues(alpha: 0.08 + (pulse * 0.04)),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(beamRect),
    );

    final haloRadius =
        math.min(size.width, size.height) * (isWide ? 0.2 : 0.26);
    canvas.drawCircle(
      coreCenter,
      haloRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.08 + (pulse * 0.04)),
            secondary.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: coreCenter, radius: haloRadius)),
    );

    canvas.drawLine(
      Offset(coreCenter.dx, size.height * 0.42),
      Offset(coreCenter.dx, size.height),
      Paint()
        ..strokeWidth = 1.1
        ..color = LightcorePalette.aether.withValues(
          alpha: 0.12 + (pulse * 0.05),
        ),
    );

    for (var i = 0; i < 16; i += 1) {
      final ringAngle = spinPhase + (i * 0.42);
      final radiusX = size.width * (isWide ? 0.18 : 0.31);
      final radiusY = size.height * (isWide ? 0.075 : 0.09);
      final point = Offset(
        coreCenter.dx + math.cos(ringAngle) * radiusX,
        coreCenter.dy + math.sin(ringAngle) * radiusY,
      );
      final glow = 0.08 + (((i % 4) / 4) * 0.08) + (pulse * 0.08);
      canvas.drawCircle(
        point,
        i.isEven ? 1.8 : 1.2,
        Paint()..color = LightcorePalette.layer2.withValues(alpha: glow),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MenuAtmospherePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.isLoading != isLoading ||
        oldDelegate.canStart != canStart;
  }
}

class _CorePulsePainter extends CustomPainter {
  const _CorePulsePainter({
    required this.phase,
    required this.enabled,
    required this.isLoading,
  });

  final double phase;
  final bool enabled;
  final bool isLoading;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;
    final spinPhase = phase * math.pi * 2;
    final accent = enabled
        ? LightcorePalette.aether
        : (isLoading ? LightcorePalette.aether : LightcorePalette.warning);
    final secondary = enabled
        ? LightcorePalette.verdant
        : (isLoading ? LightcorePalette.violet : LightcorePalette.stroke);
    final tertiary = enabled ? LightcorePalette.solar : secondary;
    final center = size.center(Offset.zero);

    final auraRadius = size.shortestSide * 0.48;
    canvas.drawCircle(
      center,
      auraRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.06 + (pulse * 0.04)),
            tertiary.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          stops: const [0, 0.56, 1],
        ).createShader(Rect.fromCircle(center: center, radius: auraRadius)),
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..color = accent.withValues(alpha: 0.24 + (pulse * 0.18));
    final secondaryRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = secondary.withValues(alpha: 0.18 + (pulse * 0.12));

    final outerOval = Rect.fromCenter(
      center: center,
      width: size.width * 0.88,
      height: size.height * 0.46,
    );
    final innerOval = Rect.fromCenter(
      center: center,
      width: size.width * 0.72,
      height: size.height * 0.36,
    );
    canvas.drawOval(outerOval, ringPaint);
    canvas.drawOval(innerOval, secondaryRingPaint);
    canvas.drawArc(
      outerOval,
      -math.pi * 0.1 + spinPhase,
      math.pi * 0.72,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round
        ..color = tertiary.withValues(alpha: 0.38 + (pulse * 0.18)),
    );

    final hexStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = accent.withValues(alpha: 0.28 + (pulse * 0.16));
    canvas.drawPath(_hexagonPath(center, size.shortestSide * 0.22), hexStroke);
    canvas.drawPath(
      _hexagonPath(center, size.shortestSide * 0.29),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.95
        ..color = LightcorePalette.layer2.withValues(alpha: 0.16),
    );
    canvas.drawPath(
      _hexagonPath(center, size.shortestSide * 0.36),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85
        ..color = secondary.withValues(alpha: 0.16),
    );

    canvas.drawLine(
      Offset(center.dx, size.height * 0.16),
      Offset(center.dx, size.height * 0.84),
      Paint()
        ..strokeWidth = 1
        ..color = accent.withValues(alpha: 0.12 + (pulse * 0.05)),
    );

    final nodeAngles = [
      spinPhase - 0.2,
      spinPhase + 1.65,
      spinPhase + 3.1,
      spinPhase + 4.7,
    ];

    for (var i = 0; i < nodeAngles.length; i += 1) {
      final point = Offset(
        center.dx + math.cos(nodeAngles[i]) * outerOval.width * 0.5,
        center.dy + math.sin(nodeAngles[i]) * outerOval.height * 0.5,
      );
      final color = i.isEven ? accent : tertiary;
      canvas.drawCircle(
        point,
        6,
        Paint()..color = color.withValues(alpha: 0.18 + (pulse * 0.1)),
      );
      canvas.drawCircle(
        point,
        3.2,
        Paint()..color = color.withValues(alpha: 0.72 + (pulse * 0.16)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CorePulsePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.enabled != enabled ||
        oldDelegate.isLoading != isLoading;
  }
}

Path _hexagonPath(Offset center, double radius) {
  final path = Path();
  for (var i = 0; i < 6; i += 1) {
    final angle = -math.pi / 2 + (i * math.pi / 3);
    final point = Offset(
      center.dx + (math.cos(angle) * radius),
      center.dy + (math.sin(angle) * radius),
    );
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  return path;
}
