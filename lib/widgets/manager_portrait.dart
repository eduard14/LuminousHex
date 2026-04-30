import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/lightcore_palette.dart';

enum ManagerPortraitFamily { core, threat }

class ManagerPortrait extends StatelessWidget {
  const ManagerPortrait({
    super.key,
    required this.seed,
    required this.name,
    required this.tint,
    required this.icon,
    required this.family,
    this.assetPath,
    this.size = 58,
  });

  final String seed;
  final String name;
  final Color tint;
  final IconData icon;
  final ManagerPortraitFamily family;
  final String? assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final badgeSize = (size * 0.28).clamp(16.0, 26.0).toDouble();

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: _ManagerPortraitArt(
              seed: seed,
              name: name,
              tint: tint,
              family: family,
              assetPath: assetPath,
            ),
          ),
          Positioned(
            right: -size * 0.02,
            bottom: -size * 0.02,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: LightcorePalette.panelRaised.withValues(alpha: 0.98),
                shape: BoxShape.circle,
                border: Border.all(color: tint.withValues(alpha: 0.62)),
                boxShadow: [
                  BoxShadow(
                    color: tint.withValues(alpha: 0.18),
                    blurRadius: 12,
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: Icon(icon, color: tint, size: badgeSize * 0.58),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagerPortraitArt extends StatelessWidget {
  const _ManagerPortraitArt({
    required this.seed,
    required this.name,
    required this.tint,
    required this.family,
    required this.assetPath,
  });

  final String seed;
  final String name;
  final Color tint;
  final ManagerPortraitFamily family;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final fallback = CustomPaint(
      painter: _ManagerPortraitPainter(
        seed: seed,
        name: name,
        tint: tint,
        family: family,
      ),
    );
    final path = assetPath;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: tint.withValues(alpha: 0.52)),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.12),
            blurRadius: 18,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: path == null
            ? fallback
            : Image.asset(
                path,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
      ),
    );
  }
}

class _ManagerPortraitPainter extends CustomPainter {
  const _ManagerPortraitPainter({
    required this.seed,
    required this.name,
    required this.tint,
    required this.family,
  });

  final String seed;
  final String name;
  final Color tint;
  final ManagerPortraitFamily family;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final hash = _stableHash(seed);
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.shortestSide * 0.24);
    final hostile = family == ManagerPortraitFamily.threat;
    final seededAccent = HSLColor.fromAHSL(
      1,
      (hash % 360).toDouble(),
      hostile ? 0.72 : 0.58,
      hostile ? 0.52 : 0.62,
    ).toColor();
    final accent = Color.lerp(seededAccent, tint, 0.36)!;
    final base = hostile ? LightcorePalette.night : LightcorePalette.panel;
    final background = Paint()
      ..shader = LinearGradient(
        colors: [
          Color.lerp(base, accent, 0.28)!.withValues(alpha: 0.98),
          LightcorePalette.panelRaised.withValues(alpha: 0.98),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), background);

    final clip = Path()..addRRect(RRect.fromRectAndRadius(rect, radius));
    canvas.save();
    canvas.clipPath(clip);
    _drawBackdrop(canvas, size, hash, accent, hostile);
    _drawBody(canvas, size, hash, accent, hostile);
    _drawHead(canvas, size, hash, accent, hostile);
    _drawInitials(canvas, size, accent);
    canvas.restore();

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.7), radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, size.shortestSide * 0.025)
        ..color = tint.withValues(alpha: 0.52),
    );
  }

  void _drawBackdrop(
    Canvas canvas,
    Size size,
    int hash,
    Color accent,
    bool hostile,
  ) {
    final stripePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * (hostile ? 0.024 : 0.018)
      ..color = accent.withValues(alpha: hostile ? 0.24 : 0.18);
    final spacing = size.width / 4.6;
    for (var x = -size.width; x < size.width * 2; x += spacing) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.width * 0.82, 0),
        stripePaint,
      );
    }

    final nodeCount = 3 + (hash % 4);
    final nodePaint = Paint()..color = accent.withValues(alpha: 0.18);
    for (var index = 0; index < nodeCount; index += 1) {
      final dx = size.width * (0.18 + (((hash >> (index * 3)) & 7) / 11));
      final dy = size.height * (0.18 + (((hash >> (index * 4 + 1)) & 7) / 13));
      canvas.drawCircle(Offset(dx, dy), size.shortestSide * 0.035, nodePaint);
    }
  }

  void _drawBody(
    Canvas canvas,
    Size size,
    int hash,
    Color accent,
    bool hostile,
  ) {
    final centerX = size.width / 2;
    final jacketTop = size.height * 0.62;
    final jacket = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.2,
        jacketTop,
        size.width * 0.6,
        size.height * 0.45,
      ),
      Radius.circular(size.width * 0.16),
    );
    canvas.drawRRect(
      jacket,
      Paint()
        ..shader = LinearGradient(
          colors: [
            accent.withValues(alpha: hostile ? 0.72 : 0.62),
            LightcorePalette.night.withValues(alpha: 0.88),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(jacket.outerRect),
    );

    final tieWidth = size.width * (hostile ? 0.12 : 0.09);
    final tie = Path()
      ..moveTo(centerX, jacketTop + size.height * 0.05)
      ..lineTo(centerX - tieWidth, size.height * 0.97)
      ..lineTo(centerX + tieWidth, size.height * 0.97)
      ..close();
    canvas.drawPath(
      tie,
      Paint()
        ..color = (hostile ? LightcorePalette.flare : LightcorePalette.layer2)
            .withValues(alpha: 0.86),
    );

    if ((hash & 1) == 0) {
      final lanyardPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.025
        ..color = LightcorePalette.mist.withValues(alpha: 0.42);
      canvas.drawLine(
        Offset(centerX - size.width * 0.16, jacketTop + size.height * 0.02),
        Offset(centerX, size.height * 0.84),
        lanyardPaint,
      );
      canvas.drawLine(
        Offset(centerX + size.width * 0.16, jacketTop + size.height * 0.02),
        Offset(centerX, size.height * 0.84),
        lanyardPaint,
      );
    }
  }

  void _drawHead(
    Canvas canvas,
    Size size,
    int hash,
    Color accent,
    bool hostile,
  ) {
    final center = Offset(size.width / 2, size.height * 0.43);
    final headRadius = size.shortestSide * 0.24;
    final faceColor = hostile
        ? Color.lerp(LightcorePalette.night, accent, 0.54)!
        : Color.lerp(LightcorePalette.mist, accent, 0.2)!;

    canvas.drawCircle(
      center.translate(0, headRadius * 0.08),
      headRadius * 1.04,
      Paint()..color = LightcorePalette.night.withValues(alpha: 0.38),
    );
    canvas.drawCircle(center, headRadius, Paint()..color = faceColor);

    final hairPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = headRadius * (0.34 + ((hash & 3) * 0.025))
      ..strokeCap = StrokeCap.round
      ..color = hostile
          ? LightcorePalette.black.withValues(alpha: 0.78)
          : accent.withValues(alpha: 0.82);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: headRadius * 0.92),
      math.pi * (1.02 + ((hash % 3) * 0.05)),
      math.pi * (0.92 - ((hash % 2) * 0.12)),
      false,
      hairPaint,
    );

    final eyeY = center.dy - headRadius * 0.05;
    final eyeGap = headRadius * 0.42;
    final eyePaint = Paint()
      ..color = (hostile ? LightcorePalette.layer2 : LightcorePalette.night)
          .withValues(alpha: 0.9);
    final eyeRadius = math.max(1.2, headRadius * 0.105);
    canvas.drawCircle(Offset(center.dx - eyeGap, eyeY), eyeRadius, eyePaint);
    canvas.drawCircle(Offset(center.dx + eyeGap, eyeY), eyeRadius, eyePaint);

    final browPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, headRadius * 0.09)
      ..strokeCap = StrokeCap.round
      ..color = LightcorePalette.night.withValues(alpha: hostile ? 0.76 : 0.44);
    final browTilt = hostile ? headRadius * 0.18 : headRadius * 0.05;
    canvas.drawLine(
      Offset(center.dx - eyeGap - headRadius * 0.16, eyeY - browTilt),
      Offset(center.dx - eyeGap + headRadius * 0.16, eyeY - headRadius * 0.11),
      browPaint,
    );
    canvas.drawLine(
      Offset(center.dx + eyeGap - headRadius * 0.16, eyeY - headRadius * 0.11),
      Offset(center.dx + eyeGap + headRadius * 0.16, eyeY - browTilt),
      browPaint,
    );

    final mouthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, headRadius * 0.08)
      ..strokeCap = StrokeCap.round
      ..color = LightcorePalette.night.withValues(alpha: hostile ? 0.64 : 0.5);
    final smirk = ((hash >> 2) & 1) == 0 ? -1.0 : 1.0;
    final mouthRect = Rect.fromCenter(
      center: center.translate(0, headRadius * 0.38),
      width: headRadius * 0.7,
      height: headRadius * 0.34,
    );
    canvas.drawArc(
      mouthRect,
      hostile ? math.pi * 0.08 : math.pi * 0.12,
      math.pi * (0.6 + (0.06 * smirk)),
      false,
      mouthPaint,
    );

    if ((hash & 4) == 0) {
      final glassesPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, headRadius * 0.055)
        ..color = LightcorePalette.layer2.withValues(alpha: 0.7);
      final lensSize = headRadius * 0.34;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx - eyeGap, eyeY),
            width: lensSize,
            height: lensSize * 0.72,
          ),
          Radius.circular(lensSize * 0.18),
        ),
        glassesPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx + eyeGap, eyeY),
            width: lensSize,
            height: lensSize * 0.72,
          ),
          Radius.circular(lensSize * 0.18),
        ),
        glassesPaint,
      );
      canvas.drawLine(
        Offset(center.dx - eyeGap + lensSize * 0.5, eyeY),
        Offset(center.dx + eyeGap - lensSize * 0.5, eyeY),
        glassesPaint,
      );
    }
  }

  void _drawInitials(Canvas canvas, Size size, Color accent) {
    final initials = _initialsFor(name);
    if (initials.isEmpty || size.shortestSide < 46) {
      return;
    }

    final painter = TextPainter(
      text: TextSpan(
        text: initials,
        style: TextStyle(
          color: LightcorePalette.layer2.withValues(alpha: 0.88),
          fontSize: size.shortestSide * 0.16,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.12,
        painter.width + size.width * 0.12,
        painter.height + size.height * 0.08,
      ),
      Radius.circular(size.width * 0.06),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()..color = accent.withValues(alpha: 0.28),
    );
    painter.paint(
      canvas,
      Offset(
        badgeRect.left + size.width * 0.06,
        badgeRect.top + size.height * 0.04,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ManagerPortraitPainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.name != name ||
        oldDelegate.tint != tint ||
        oldDelegate.family != family;
  }
}

int _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

String _initialsFor(String name) {
  final parts = name
      .split(RegExp(r'\s+'))
      .where((part) {
        final normalized = part.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
        return normalized.isNotEmpty &&
            normalized.toLowerCase() != 'the' &&
            normalized.toLowerCase() != 'of';
      })
      .map((part) => part.replaceAll(RegExp(r'[^A-Za-z0-9]'), ''))
      .toList(growable: false);
  if (parts.isEmpty) {
    return '';
  }
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}
