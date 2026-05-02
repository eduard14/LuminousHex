part of '../daily_dungeons_screen.dart';

class _PrismRiftPreviewPanel extends StatelessWidget {
  const _PrismRiftPreviewPanel({
    required this.towerProfile,
    required this.towerLevel,
    required this.reward,
    required this.riftStability,
    required this.cleared,
  });

  final LightcoreDailyDungeonTowerProfile towerProfile;
  final int towerLevel;
  final LightcoreDailyDungeonReward reward;
  final double riftStability;
  final bool cleared;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = towerProfile.affinity.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: LightcorePalette.violet.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final stage = _PrismRiftPreviewStage(
              towerProfile: towerProfile,
              towerLevel: towerLevel,
            );
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBadge(icon: Icons.track_changes_rounded, tint: tint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rift Stabilizer', style: textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            cleared
                                ? 'First clear secured'
                                : 'First-clear reward ${reward.label}',
                            style: textTheme.bodySmall?.copyWith(
                              color: LightcorePalette.mist.withValues(
                                alpha: 0.68,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusCapsule(label: 'Lv $towerLevel', tint: tint),
                  ],
                ),
                const SizedBox(height: 14),
                _MeterLabelRow(
                  label: 'Rift Stability',
                  value: riftStability.round().toString(),
                ),
                const SizedBox(height: 6),
                MeterBar(value: 1, color: tint, height: 12),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: towerProjectileIcon(towerProfile.projectileType),
                      label: towerProfile.projectileType.label,
                      tint: tint,
                    ),
                    _InfoChip(
                      icon: Icons.bolt_rounded,
                      label: '${towerProfile.shotDamage.round()} base shot',
                      tint: LightcorePalette.aether,
                    ),
                    _InfoChip(
                      icon: Icons.adjust_rounded,
                      label: '${towerProfile.affinity.shortLabel} affinity',
                      tint: tint,
                    ),
                  ],
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [stage, const SizedBox(height: 14), details],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 280, child: stage),
                const SizedBox(width: 18),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PrismRiftPreviewStage extends StatelessWidget {
  const _PrismRiftPreviewStage({
    required this.towerProfile,
    required this.towerLevel,
  });

  final LightcoreDailyDungeonTowerProfile towerProfile;
  final int towerLevel;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.35,
      child: CustomPaint(
        painter: _PrismRiftPreviewPainter(
          towerProfile: towerProfile,
          towerLevel: towerLevel,
        ),
      ),
    );
  }
}

class _PrismRiftPreviewPainter extends CustomPainter {
  const _PrismRiftPreviewPainter({
    required this.towerProfile,
    required this.towerLevel,
  });

  final LightcoreDailyDungeonTowerProfile towerProfile;
  final int towerLevel;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height / 2);
    final shortest = math.min(size.width, size.height);
    final tint = towerProfile.affinity.color;
    canvas.drawRect(
      rect,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                LightcorePalette.violet.withValues(alpha: 0.16),
                LightcorePalette.night.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: shortest * 0.62),
            ),
    );
    for (var index = 0; index < 3; index += 1) {
      canvas.drawCircle(
        center,
        shortest * (0.22 + (index * 0.13)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = LightcorePalette.violet.withValues(alpha: 0.22),
      );
    }
    final shardPaint = Paint()..color = LightcorePalette.violet;
    for (var index = 0; index < 6; index += 1) {
      final angle = (-math.pi / 2) + (index * math.pi / 3);
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * shortest * 0.36;
      canvas.drawPath(_hexPath(position, shortest * 0.04), shardPaint);
      canvas.drawCircle(
        position +
            Offset(math.cos(angle + 1.2), math.sin(angle + 1.2)) *
                shortest *
                0.033,
        shortest * 0.012,
        Paint()..color = LightcorePalette.solar,
      );
    }
    _drawGlowLine(
      canvas,
      center,
      center.translate(shortest * 0.22, -shortest * 0.2),
      tint,
      width: 3.2,
    );
    canvas.drawPath(
      _hexPath(center, shortest * 0.11),
      Paint()..color = tint.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      _hexPath(center, shortest * 0.11),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = tint,
    );
    _paintIconGlyph(
      canvas,
      center,
      towerProjectileIcon(towerProfile.projectileType),
      size: shortest * 0.08,
      color: tint,
    );
  }

  void _drawGlowLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color, {
    required double width,
  }) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..strokeWidth = width + 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = color.withValues(alpha: 0.18),
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.82),
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

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (var index = 0; index < 6; index += 1) {
      final angle = (math.pi / 6) + (index * math.pi / 3);
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _PrismRiftPreviewPainter oldDelegate) {
    return oldDelegate.towerProfile != towerProfile ||
        oldDelegate.towerLevel != towerLevel;
  }
}
