part of '../lightcore_main_menu_screen.dart';

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({
    required this.titleSize,
    required this.titleLetterSpacing,
    required this.compact,
  });

  final double titleSize;
  final double titleLetterSpacing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _LumiHexTitleLockup(
      titleSize: titleSize,
      titleLetterSpacing: titleLetterSpacing,
      compact: compact,
      textTheme: textTheme,
    );
  }
}

class _LumiHexTitleLockup extends StatelessWidget {
  const _LumiHexTitleLockup({
    required this.titleSize,
    required this.titleLetterSpacing,
    required this.compact,
    required this.textTheme,
  });

  final double titleSize;
  final double titleLetterSpacing;
  final bool compact;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final badgeSize = compact ? 14.0 : 17.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        CustomPaint(
          foregroundPainter: _TitleAnglePainter(compact: compact),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 20,
              compact ? 7 : 10,
              compact ? 22 : 34,
              compact ? 8 : 12,
            ),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFB7F3FF),
                    Color(0xFF49DBFF),
                    Color(0xFFE9FEFF),
                  ],
                  stops: [0, 0.32, 0.62, 1],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds);
              },
              child: Text(
                'LumiHex',
                textAlign: TextAlign.center,
                style: textTheme.headlineLarge?.copyWith(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: titleLetterSpacing,
                  color: Colors.white,
                  height: 0.92,
                  shadows: [
                    Shadow(
                      color: LightcorePalette.aether.withValues(alpha: 0.3),
                      blurRadius: compact ? 22 : 32,
                    ),
                    Shadow(
                      color: LightcorePalette.violet.withValues(alpha: 0.16),
                      blurRadius: compact ? 14 : 22,
                      offset: const Offset(2.2, 1.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: compact ? 0 : 1,
          right: compact ? 0 : 2,
          child: Transform.rotate(
            angle: -0.2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFFF3030).withValues(alpha: 0.5),
                  width: 1.2,
                ),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF3030).withValues(alpha: 0.24),
                    Colors.black.withValues(alpha: 0.18),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 6 : 7,
                  vertical: compact ? 2.5 : 3,
                ),
                child: Text(
                  'BETA',
                  style: textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFFF3030),
                    fontSize: badgeSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: compact ? 1.6 : 2.2,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFF3030).withValues(alpha: 0.56),
                        blurRadius: compact ? 12 : 18,
                      ),
                      const Shadow(
                        color: Color(0xFF3D0303),
                        blurRadius: 2,
                        offset: Offset(1.5, 1.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TitleAnglePainter extends CustomPainter {
  const _TitleAnglePainter({required this.compact});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final long = compact ? 35.0 : 52.0;
    final short = compact ? 16.0 : 24.0;
    final inset = compact ? 3.0 : 5.0;
    final strokeWidth = compact ? 1.25 : 1.55;
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square
      ..shader = const LinearGradient(
        colors: [Color(0x8849DBFF), Color(0xCCF4FBFF), Color(0x77BE7BFF)],
      ).createShader(rect);
    final warning = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square
      ..color = const Color(0xB8FF3030);

    final topLeft = Path()
      ..moveTo(inset, inset + short)
      ..lineTo(inset + short, inset)
      ..lineTo(inset + long, inset);
    final bottomLeft = Path()
      ..moveTo(inset, size.height - inset - short)
      ..lineTo(inset + short, size.height - inset)
      ..lineTo(inset + long, size.height - inset);
    final topRight = Path()
      ..moveTo(size.width - inset - long, inset)
      ..lineTo(size.width - inset - short, inset)
      ..lineTo(size.width - inset, inset + short);
    final betaBracket = Path()
      ..moveTo(size.width - inset - long * 0.74, inset + short * 1.55)
      ..lineTo(size.width - inset - short * 0.85, inset + short * 1.55)
      ..lineTo(size.width - inset, inset + short * 2.4);

    canvas.drawPath(topLeft, accent);
    canvas.drawPath(bottomLeft, accent);
    canvas.drawPath(topRight, accent);
    canvas.drawPath(betaBracket, warning);
  }

  @override
  bool shouldRepaint(covariant _TitleAnglePainter oldDelegate) {
    return oldDelegate.compact != compact;
  }
}

class _StatusGlassCard extends StatelessWidget {
  const _StatusGlassCard({
    required this.phase,
    required this.isLoading,
    required this.canStart,
    required this.canLaunch,
    required this.report,
    required this.compact,
  });

  final double phase;
  final bool isLoading;
  final bool canStart;
  final bool canLaunch;
  final LightcoreBootstrapReport? report;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = _menuStatusAccent(
      isLoading: isLoading,
      canStart: canStart,
      canLaunch: canLaunch,
      report: report,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 270 : 330),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18,
          vertical: compact ? 12 : 14,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 24 : 28),
          border: Border.all(
            color: LightcorePalette.stroke.withValues(alpha: 0.34),
          ),
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.3),
              LightcorePalette.panel.withValues(alpha: 0.44),
              LightcorePalette.panelRaised.withValues(alpha: 0.28),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 28,
              spreadRadius: -12,
            ),
          ],
        ),
        child: Semantics(
          label: 'Sync status animation',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < 4; index += 1) ...[
                _SyncHexagonNode(
                  phase: phase,
                  index: index,
                  accent: accent,
                  compact: compact,
                ),
                if (index != 3) SizedBox(width: compact ? 8 : 11),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncHexagonNode extends StatelessWidget {
  const _SyncHexagonNode({
    required this.phase,
    required this.index,
    required this.accent,
    required this.compact,
  });

  final double phase;
  final int index;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = (phase * 4) % 4;
    final directDistance = (progress - index).abs();
    final distance = math.min(directDistance, 4 - directDistance);
    final rawIntensity = (1 - distance).clamp(0.0, 1.0).toDouble();
    final intensity = Curves.easeOutCubic.transform(rawIntensity);
    final size = compact ? 42.0 : 50.0;

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SyncHexagonPainter(accent: accent, intensity: intensity),
      ),
    );
  }
}

class _SyncHexagonPainter extends CustomPainter {
  const _SyncHexagonPainter({required this.accent, required this.intensity});

  final Color accent;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width * 0.44, size.height * 0.48);
    final rect = Offset.zero & size;
    final outerPath = _hexagonPath(center, radius);
    final innerPath = _hexagonPath(center, radius * 0.68);
    final glowAlpha = 0.06 + (intensity * 0.32);
    final fillAlpha = 0.08 + (intensity * 0.3);
    final strokeAlpha = 0.22 + (intensity * 0.66);

    canvas.drawPath(
      outerPath,
      Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 + (intensity * 11))
        ..color = accent.withValues(alpha: glowAlpha),
    );
    canvas.drawPath(
      outerPath,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: fillAlpha + 0.08),
            LightcorePalette.panelRaised.withValues(alpha: 0.18),
            Colors.black.withValues(alpha: 0.26),
          ],
          stops: const [0, 0.58, 1],
        ).createShader(rect),
    );
    canvas.drawPath(
      outerPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 + (intensity * 1.35)
        ..strokeJoin = StrokeJoin.round
        ..color = accent.withValues(alpha: strokeAlpha),
    );
    canvas.drawPath(
      innerPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = LightcorePalette.layer2.withValues(
          alpha: 0.12 + (intensity * 0.28),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _SyncHexagonPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.intensity != intensity;
  }
}
