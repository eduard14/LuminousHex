import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lightcore_guide.dart';
import '../theme/lightcore_palette.dart';
import 'cosmic_guide_avatar.dart';
import 'tower_ring_icon.dart';

const List<String> _defaultLoadingTips = <String>[
  'The optimal growth strategy may not be 100% flow.',
  'Output Efficiency can beat raw reward boosts when stability starts slipping.',
  'Threat Scans are safer when your tower colors already counter the region.',
];

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
    this.tips = _defaultLoadingTips,
    this.guide = LightcoreGuideProfile.lumo,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final Color accent;
  final double? progress;
  final bool? compact;
  final List<String> signalLabels;
  final List<String> tips;
  final LightcoreGuideProfile guide;

  @override
  State<LightcoreLoadingScreen> createState() => _LightcoreLoadingScreenState();
}

class _LightcoreLoadingScreenState extends State<LightcoreLoadingScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _tipCycleDuration = Duration(milliseconds: 3600);

  late final AnimationController _controller;
  Timer? _tipTimer;
  int _tipIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
    _startTipTimer();
  }

  @override
  void didUpdateWidget(covariant LightcoreLoadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tips != widget.tips) {
      _tipIndex = 0;
      _startTipTimer();
    }
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<String> get _normalizedTips {
    return widget.tips
        .map((tip) => tip.trim())
        .where((tip) => tip.isNotEmpty)
        .toList(growable: false);
  }

  String? get _activeTip {
    final tips = _normalizedTips;
    if (tips.isEmpty) {
      return null;
    }
    return tips[_tipIndex % tips.length];
  }

  void _startTipTimer() {
    _tipTimer?.cancel();
    final tipCount = _normalizedTips.length;
    if (tipCount < 2) {
      return;
    }
    _tipTimer = Timer.periodic(_tipCycleDuration, (_) {
      if (!mounted) {
        return;
      }
      setState(() => _tipIndex = (_tipIndex + 1) % tipCount);
    });
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
                              constraints.maxHeight < 760);
                      final phase = _controller.value;

                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 22 : 44,
                          vertical: compact ? 24 : 40,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                constraints.maxHeight -
                                MediaQuery.paddingOf(context).vertical -
                                (compact ? 48 : 80),
                          ),
                          child: _LoadingStage(
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
                            activeTip: _activeTip,
                            guide: widget.guide,
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

class _LoadingStage extends StatelessWidget {
  const _LoadingStage({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.accent,
    required this.progress,
    required this.phase,
    required this.compact,
    required this.signalLabels,
    required this.activeTip,
    required this.guide,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final Color accent;
  final double? progress;
  final double phase;
  final bool compact;
  final List<String> signalLabels;
  final String? activeTip;
  final LightcoreGuideProfile guide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;
    final activeSignal = (phase * signalLabels.length)
        .floor()
        .clamp(0, signalLabels.length - 1)
        .toInt();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _LoadingStatusRail(
          statusLabel: statusLabel,
          signalLabels: signalLabels,
          activeSignal: activeSignal,
          accent: accent,
          compact: compact,
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 26 : 44),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: compact ? 182 : 260,
                height: compact ? 182 : 260,
                child: CustomPaint(
                  painter: _LoadingCorePainter(phase: phase, accent: accent),
                  child: Center(
                    child: Container(
                      width: compact ? 92 : 124,
                      height: compact ? 92 : 124,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            LightcorePalette.layer2.withValues(
                              alpha: 0.24 + pulse * 0.08,
                            ),
                            accent.withValues(alpha: 0.14),
                            Colors.transparent,
                          ],
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.44),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.32),
                            blurRadius: 42,
                            spreadRadius: -12,
                          ),
                        ],
                      ),
                      child: TowerRingIcon(
                        size: compact ? 42 : 56,
                        color: LightcorePalette.layer2,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 24 : 32),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    (compact ? textTheme.headlineSmall : textTheme.displaySmall)
                        ?.copyWith(
                          color: LightcorePalette.layer2,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 350 : 560),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: LightcorePalette.mist.withValues(alpha: 0.78),
                    height: 1.35,
                  ),
                ),
              ),
              SizedBox(height: compact ? 24 : 34),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 360 : 620),
                child: _LoadingRelayPath(
                  accent: accent,
                  phase: phase,
                  progress: progress,
                  compact: compact,
                ),
              ),
            ],
          ),
        ),
        if (activeTip != null)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 390 : 680),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: _GuideTipCallout(
                key: ValueKey<String>(activeTip!),
                guide: guide,
                tip: activeTip!,
                accent: accent,
                compact: compact,
                phase: phase,
              ),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

class _LoadingStatusRail extends StatelessWidget {
  const _LoadingStatusRail({
    required this.statusLabel,
    required this.signalLabels,
    required this.activeSignal,
    required this.accent,
    required this.compact,
  });

  final String statusLabel;
  final List<String> signalLabels;
  final int activeSignal;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: accent.withValues(alpha: 0.22)),
        ),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.1),
            Colors.black.withValues(alpha: 0.04),
            LightcorePalette.violet.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 0 : 4,
          vertical: compact ? 12 : 14,
        ),
        child: compact
            ? Column(
                children: [
                  Text(
                    statusLabel.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: textTheme.labelLarge?.copyWith(
                      color: accent.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _LoadingSignalRow(
                    signalLabels: signalLabels,
                    activeSignal: activeSignal,
                    accent: accent,
                    compact: compact,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      statusLabel.toUpperCase(),
                      style: textTheme.labelLarge?.copyWith(
                        color: accent.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  _LoadingSignalRow(
                    signalLabels: signalLabels,
                    activeSignal: activeSignal,
                    accent: accent,
                    compact: compact,
                  ),
                ],
              ),
      ),
    );
  }
}

class _LoadingSignalRow extends StatelessWidget {
  const _LoadingSignalRow({
    required this.signalLabels,
    required this.activeSignal,
    required this.accent,
    required this.compact,
  });

  final List<String> signalLabels;
  final int activeSignal;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
    );
  }
}

class _GuideTipCallout extends StatelessWidget {
  const _GuideTipCallout({
    super.key,
    required this.guide,
    required this.tip,
    required this.accent,
    required this.compact,
    required this.phase,
  });

  final LightcoreGuideProfile guide;
  final String tip;
  final Color accent;
  final bool compact;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final avatarSize = compact ? 54.0 : 62.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
        color: Colors.black.withValues(alpha: 0.2),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CosmicGuideAvatar(
              guide: guide,
              size: avatarSize,
              phase: phase,
              boosting: true,
              semanticLabel: '${guide.displayName} loading guide',
            ),
            SizedBox(width: compact ? 12 : 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${guide.displayName} tip',
                    style: textTheme.labelSmall?.copyWith(
                      color: accent.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip,
                    style: textTheme.bodySmall?.copyWith(
                      color: LightcorePalette.mist.withValues(alpha: 0.82),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingRelayPath extends StatelessWidget {
  const _LoadingRelayPath({
    required this.accent,
    required this.phase,
    required this.progress,
    required this.compact,
  });

  final Color accent;
  final double phase;
  final double? progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final value = progress?.clamp(0.0, 1.0).toDouble();
    final activeStage = value == null
        ? (phase * 6).floor().clamp(0, 5).toInt()
        : (value * 6).floor().clamp(0, 5).toInt();
    final status = value == null
        ? 'Relay alignment'
        : 'Relay alignment ${(value * 100).round()}%';

    return Semantics(
      label: status,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(compact ? 20 : 24),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 18,
            vertical: compact ? 12 : 14,
          ),
          child: Column(
            children: [
              SizedBox(
                height: compact ? 78 : 92,
                child: CustomPaint(
                  painter: _LoadingRelayPathPainter(
                    accent: accent,
                    phase: phase,
                    progress: value,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < 6; index += 1) ...[
                    _RelayStepDot(
                      active: value == null
                          ? index == activeStage
                          : index < ((value * 6).ceil()).clamp(0, 6),
                      current: index == activeStage,
                      accent: accent,
                    ),
                    if (index != 5) const SizedBox(width: 7),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                status.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: LightcorePalette.mist.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelayStepDot extends StatelessWidget {
  const _RelayStepDot({
    required this.active,
    required this.current,
    required this.accent,
  });

  final bool active;
  final bool current;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: current ? 22 : 10,
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active
            ? (current ? LightcorePalette.layer2 : accent).withValues(
                alpha: current ? 0.82 : 0.48,
              )
            : LightcorePalette.stroke.withValues(alpha: 0.3),
        boxShadow: active
            ? [
                BoxShadow(
                  color: (current ? LightcorePalette.layer2 : accent)
                      .withValues(alpha: 0.24),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

class _LoadingRelayPathPainter extends CustomPainter {
  const _LoadingRelayPathPainter({
    required this.accent,
    required this.phase,
    required this.progress,
  });

  final Color accent;
  final double phase;
  final double? progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * 0.39;
    final activeStage = progress == null
        ? (phase * 6).floor().clamp(0, 5).toInt()
        : (progress! * 6).floor().clamp(0, 5).toInt();
    final completed = progress == null
        ? 0
        : (progress! * 6).ceil().clamp(0, 6).toInt();
    final points = List<Offset>.generate(6, (index) {
      final angle = -math.pi / 2 + (index * math.pi / 3);
      return Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
    });

    final shellPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      shellPath.lineTo(point.dx, point.dy);
    }
    shellPath.close();

    canvas.drawPath(
      shellPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = LightcorePalette.stroke.withValues(alpha: 0.34),
    );

    final spokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = LightcorePalette.stroke.withValues(alpha: 0.26);
    for (final point in points) {
      canvas.drawLine(center, point, spokePaint);
    }

    for (var index = 0; index < points.length; index += 1) {
      final isActive = progress == null
          ? index == activeStage
          : index < completed;
      final isCurrent = index == activeStage;
      final nodeColor = isActive
          ? (isCurrent ? LightcorePalette.layer2 : accent)
          : LightcorePalette.mist.withValues(alpha: 0.28);
      if (isActive) {
        canvas.drawLine(
          center,
          points[index],
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isCurrent ? 2.2 : 1.7
            ..color = nodeColor.withValues(alpha: isCurrent ? 0.72 : 0.42),
        );
      }
      canvas.drawCircle(
        points[index],
        isCurrent ? 7.2 : 5.4,
        Paint()..color = nodeColor.withValues(alpha: isActive ? 0.95 : 0.42),
      );
      canvas.drawCircle(
        points[index],
        isCurrent ? 12 : 8.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCurrent ? 1.4 : 1
          ..color = nodeColor.withValues(alpha: isActive ? 0.42 : 0.16),
      );
    }

    canvas.drawCircle(
      center,
      14,
      Paint()
        ..shader = RadialGradient(
          colors: [
            LightcorePalette.layer2.withValues(alpha: 0.86),
            accent.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 22)),
    );
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = LightcorePalette.layer2.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _LoadingRelayPathPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.phase != phase ||
        oldDelegate.progress != progress;
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
          letterSpacing: 0,
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
