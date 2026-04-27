import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/lightcore_palette.dart';
import 'tower_ring_icon.dart';

class LightcoreLoadingScreen extends StatefulWidget {
  const LightcoreLoadingScreen({
    super.key,
    this.title = 'Loading',
    this.subtitle = 'Aligning the lightcore relay.',
    this.statusLabel = 'STAND BY',
    this.accent = LightcorePalette.aether,
    this.progress,
    this.compact,
    this.signalLabels = const ['BOOT', 'LINK', 'FLOW'],
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final Color accent;
  final double? progress;
  final bool? compact;
  final List<String> signalLabels;

  @override
  State<LightcoreLoadingScreen> createState() => _LightcoreLoadingScreenState();
}

class _LightcoreLoadingScreenState extends State<LightcoreLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '${widget.title}. ${widget.subtitle}',
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                LightcorePalette.night,
                LightcorePalette.abyss,
                Color(0xFF123044),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _LoadingAtmospherePainter(
                  phase: _controller.value,
                  accent: widget.accent,
                ),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          widget.compact ??
                          (constraints.maxWidth < 560 ||
                              constraints.maxHeight < 680);
                      final phase = _controller.value;

                      return Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 20 : 32,
                            vertical: compact ? 24 : 32,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: compact ? 390 : 500,
                            ),
                            child: _LoadingCard(
                              title: widget.title,
                              subtitle: widget.subtitle,
                              statusLabel: widget.statusLabel,
                              accent: widget.accent,
                              progress: widget.progress,
                              phase: phase,
                              compact: compact,
                              signalLabels: widget.signalLabels.isEmpty
                                  ? const ['BOOT', 'LINK', 'FLOW']
                                  : widget.signalLabels,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.accent,
    required this.progress,
    required this.phase,
    required this.compact,
    required this.signalLabels,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final Color accent;
  final double? progress;
  final double phase;
  final bool compact;
  final List<String> signalLabels;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;
    final activeSignal = (phase * signalLabels.length)
        .floor()
        .clamp(0, signalLabels.length - 1)
        .toInt();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 30 : 38),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.08 + (pulse * 0.03)),
            LightcorePalette.panel.withValues(alpha: 0.9),
            LightcorePalette.panelRaised.withValues(alpha: 0.76),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18 + (pulse * 0.06)),
            blurRadius: 48,
            spreadRadius: -18,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 22 : 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: compact ? 132 : 164,
              height: compact ? 132 : 164,
              child: CustomPaint(
                painter: _LoadingCorePainter(phase: phase, accent: accent),
                child: Center(
                  child: Container(
                    width: compact ? 72 : 88,
                    height: compact ? 72 : 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          LightcorePalette.layer2.withValues(alpha: 0.2),
                          accent.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(color: accent.withValues(alpha: 0.34)),
                    ),
                    child: TowerRingIcon(
                      size: compact ? 34 : 42,
                      color: LightcorePalette.layer2,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 18 : 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                color: LightcorePalette.layer2,
                fontWeight: FontWeight.w900,
                letterSpacing: compact ? -0.4 : -0.7,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.76),
              ),
            ),
            SizedBox(height: compact ? 20 : 24),
            _LoadingProgressTrack(
              accent: accent,
              phase: phase,
              progress: progress,
            ),
            SizedBox(height: compact ? 16 : 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < signalLabels.length; index += 1)
                  _LoadingSignalPill(
                    label: signalLabels[index],
                    active: index == activeSignal,
                    accent: accent,
                    compact: compact,
                  ),
              ],
            ),
            SizedBox(height: compact ? 18 : 22),
            Text(
              statusLabel.toUpperCase(),
              textAlign: TextAlign.center,
              style: textTheme.labelLarge?.copyWith(
                color: accent.withValues(alpha: 0.92),
                letterSpacing: compact ? 1.6 : 2.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingProgressTrack extends StatelessWidget {
  const _LoadingProgressTrack({
    required this.accent,
    required this.phase,
    required this.progress,
  });

  final Color accent;
  final double phase;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final value = progress?.clamp(0.0, 1.0).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.24),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor:
                  value ?? (0.24 + (math.sin(phase * math.pi * 2) + 1) * 0.18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.22),
                      LightcorePalette.layer2.withValues(alpha: 0.92),
                      LightcorePalette.solar.withValues(alpha: 0.64),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: accent.withValues(alpha: 0.22)),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSignalPill extends StatelessWidget {
  const _LoadingSignalPill({
    required this.label,
    required this.active,
    required this.accent,
    required this.compact,
  });

  final String label;
  final bool active;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active
            ? accent.withValues(alpha: 0.16)
            : Colors.black.withValues(alpha: 0.18),
        border: Border.all(
          color: active
              ? accent.withValues(alpha: 0.48)
              : LightcorePalette.stroke.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: active
              ? LightcorePalette.layer2
              : LightcorePalette.mist.withValues(alpha: 0.58),
          fontWeight: FontWeight.w800,
          letterSpacing: compact ? 1 : 1.3,
        ),
      ),
    );
  }
}

class _LoadingAtmospherePainter extends CustomPainter {
  const _LoadingAtmospherePainter({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;
    final center = size.center(Offset.zero);
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = LightcorePalette.stroke.withValues(alpha: 0.06);

    for (var x = -size.height; x < size.width + size.height; x += 54) {
      canvas.drawLine(
        Offset(x.toDouble(), 0),
        Offset(x + size.height, size.height),
        gridPaint,
      );
    }
    for (var x = 0; x < size.width + size.height; x += 54) {
      canvas.drawLine(
        Offset(x.toDouble(), 0),
        Offset(x - size.height, size.height),
        gridPaint,
      );
    }

    final auraRadius = math.min(size.width, size.height) * 0.48;
    canvas.drawCircle(
      center,
      auraRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.12 + (pulse * 0.05)),
            LightcorePalette.violet.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0, 0.48, 1],
        ).createShader(Rect.fromCircle(center: center, radius: auraRadius)),
    );

    for (var index = 0; index < 9; index += 1) {
      final angle = (phase * math.pi * 2) + (index * math.pi / 4.5);
      final distance = auraRadius * (0.72 + ((index % 3) * 0.12));
      final point = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance * 0.52,
      );
      canvas.drawCircle(
        point,
        1.4 + ((index % 2) * 1.2),
        Paint()
          ..color = LightcorePalette.layer2.withValues(
            alpha: 0.1 + (pulse * 0.14),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LoadingAtmospherePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.accent != accent;
  }
}

class _LoadingCorePainter extends CustomPainter {
  const _LoadingCorePainter({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;
    final spin = phase * math.pi * 2;
    final shortSide = size.shortestSide;

    canvas.drawCircle(
      center,
      shortSide * 0.48,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                accent.withValues(alpha: 0.08 + (pulse * 0.06)),
                LightcorePalette.solar.withValues(alpha: 0.04),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: shortSide * 0.48),
            ),
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..color = accent.withValues(alpha: 0.34 + (pulse * 0.18));
    final mutedRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = LightcorePalette.violet.withValues(alpha: 0.2 + (pulse * 0.1));

    for (var index = 0; index < 3; index += 1) {
      final radius = shortSide * (0.28 + (index * 0.1));
      final oval = Rect.fromCenter(
        center: center,
        width: radius * 2,
        height: radius * (index.isEven ? 1.12 : 0.7),
      );
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(spin * (index.isEven ? 0.22 : -0.18));
      canvas.translate(-center.dx, -center.dy);
      canvas.drawOval(oval, index.isEven ? ringPaint : mutedRingPaint);
      canvas.restore();
    }

    final hexPath = Path();
    for (var index = 0; index < 6; index += 1) {
      final angle = spin * 0.18 + (math.pi / 6) + (index * math.pi / 3);
      final point = Offset(
        center.dx + math.cos(angle) * shortSide * 0.35,
        center.dy + math.sin(angle) * shortSide * 0.35,
      );
      if (index == 0) {
        hexPath.moveTo(point.dx, point.dy);
      } else {
        hexPath.lineTo(point.dx, point.dy);
      }
    }
    hexPath.close();
    canvas.drawPath(
      hexPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = LightcorePalette.layer2.withValues(alpha: 0.22 + pulse * 0.1),
    );
  }

  @override
  bool shouldRepaint(covariant _LoadingCorePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.accent != accent;
  }
}
