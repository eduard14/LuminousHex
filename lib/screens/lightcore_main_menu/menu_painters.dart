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

    final shellRadius =
        math.min(size.width, size.height) * (isWide ? 0.14 : 0.2);
    final shellVertices = _hexagonVertices(coreCenter, shellRadius);
    final shellPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = LightcorePalette.layer2.withValues(alpha: 0.12 + pulse * 0.08);
    for (var edge = 0; edge < shellVertices.length; edge += 1) {
      final start = shellVertices[edge];
      final end = shellVertices[(edge + 1) % shellVertices.length];
      canvas.drawLine(
        Offset.lerp(start, end, 0.08)!,
        Offset.lerp(start, end, 0.44)!,
        shellPaint,
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

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = tertiary.withValues(alpha: 0.34 + (pulse * 0.18));
    final tickVertices = _hexagonVertices(center, size.shortestSide * 0.43);
    for (var edge = 0; edge < tickVertices.length; edge += 1) {
      final start = tickVertices[edge];
      final end = tickVertices[(edge + 1) % tickVertices.length];
      final phaseOffset = (spinPhase / (math.pi * 2) + edge / 6) % 1;
      final tickStart = 0.12 + (phaseOffset * 0.18);
      canvas.drawLine(
        Offset.lerp(start, end, tickStart.clamp(0.0, 0.7))!,
        Offset.lerp(start, end, (tickStart + 0.16).clamp(0.0, 0.86))!,
        tickPaint,
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
  final vertices = _hexagonVertices(center, radius);
  final path = Path();
  for (var i = 0; i < vertices.length; i += 1) {
    final point = vertices[i];
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  return path;
}

List<Offset> _hexagonVertices(Offset center, double radius) {
  final vertices = <Offset>[];
  for (var i = 0; i < 6; i += 1) {
    final angle = -math.pi / 2 + (i * math.pi / 3);
    vertices.add(
      Offset(
        center.dx + (math.cos(angle) * radius),
        center.dy + (math.sin(angle) * radius),
      ),
    );
  }
  return vertices;
}
