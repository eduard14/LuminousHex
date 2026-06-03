import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/enemy_configs.dart';
import '../models/lightcore_config.dart';
import '../models/lightcore_state.dart';
import '../models/lightcore_types.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/aurora_panel.dart';

class ThreatMapScreen extends StatefulWidget {
  const ThreatMapScreen({
    super.key,
    required this.controller,
    required this.isActive,
    required this.onClose,
  });

  final LightcoreController controller;
  final bool isActive;
  final VoidCallback onClose;

  @override
  State<ThreatMapScreen> createState() => _ThreatMapScreenState();
}

class _ThreatMapScreenState extends State<ThreatMapScreen> {
  LightcoreController get controller => widget.controller;

  Future<void> _openRegion(ThreatRegionConfig region) async {
    final state = controller.threatRegionStateById(region.id);
    if (state?.revealed ?? false) {
      controller.selectThreatRegion(region.id);
    }
    await showThreatRegionIntelDialog(context, controller, region.id);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                LightcorePalette.night,
                LightcorePalette.abyss,
                Color(0xFF102332),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: _ThreatMapStarfield()),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Threat Map',
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: LightcorePalette.mist,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Linear area route',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: LightcorePalette.aether,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filledTonal(
                            tooltip: 'Return to Battle',
                            onPressed: widget.onClose,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ThreatMapStatusBar(controller: controller),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _ThreatSectorMap(
                          key: const ValueKey<String>('threat-map-surface'),
                          controller: controller,
                          onRegionTapped: _openRegion,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThreatMapStarfield extends StatelessWidget {
  const _ThreatMapStarfield();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ThreatMapStarfieldPainter());
  }
}

class _ThreatMapStatusBar extends StatelessWidget {
  const _ThreatMapStatusBar({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final challenge = controller.activeThreatRegionChallenge;
    final challengeRegion = challenge == null
        ? null
        : controller.threatRegionConfigById(challenge.regionId);
    final validation = controller.activeThreatRegionFarmValidation;
    final validationRegion = validation == null
        ? null
        : controller.threatRegionConfigById(validation.regionId);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MapChip(label: 'Route ${controller.fullyStabilizedRegionCount + 1}'),
        const _MapChip(label: 'One path'),
        _MapChip(label: 'Swarm ${controller.farmSwarmSize}'),
        _MapChip(label: '${controller.fullyStabilizedRegionCount} cleared'),
        if (controller.nextThreatRegionConfig != null)
          _MapChip(
            label: 'Locked next: ${controller.nextThreatRegionConfig!.name}',
            tint: LightcorePalette.warning,
          ),
        if (challengeRegion != null)
          _MapChip(
            label: 'Challenge: ${challengeRegion.name}',
            tint: LightcorePalette.warning,
          ),
        if (validationRegion != null && validation != null)
          _MapChip(
            label:
                'Farm ${validation.waveIndex + 1}/${LightcoreController.farmValidationWaveCount}: ${validationRegion.name}',
            tint: LightcorePalette.aether,
          ),
      ],
    );
  }
}

class _ThreatSectorMap extends StatefulWidget {
  const _ThreatSectorMap({
    super.key,
    required this.controller,
    required this.onRegionTapped,
  });

  final LightcoreController controller;
  final ValueChanged<ThreatRegionConfig> onRegionTapped;

  @override
  State<_ThreatSectorMap> createState() => _ThreatSectorMapState();
}

class _ThreatSectorMapState extends State<_ThreatSectorMap> {
  double _gridScale = 1;
  Offset _gridOffset = Offset.zero;
  double _startScale = 1;
  Offset _startOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  int _activePointerCount = 0;
  bool _tapCandidate = false;
  Offset _tapStartPosition = Offset.zero;
  Offset _lastPointerPosition = Offset.zero;

  void _handlePointerDown(PointerDownEvent event) {
    _activePointerCount += 1;
    if (_activePointerCount == 1) {
      _tapCandidate = true;
      _tapStartPosition = event.localPosition;
      _lastPointerPosition = event.localPosition;
    } else {
      _tapCandidate = false;
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _lastPointerPosition = event.localPosition;
    if (_activePointerCount != 1) {
      _tapCandidate = false;
      return;
    }
    if ((event.localPosition - _tapStartPosition).distance > 8) {
      _tapCandidate = false;
    }
  }

  void _handlePointerUp(PointerUpEvent event, Size size) {
    _lastPointerPosition = event.localPosition;
    if (_activePointerCount == 1 && _tapCandidate) {
      final painter = _painter();
      final region = painter.regionAt(_lastPointerPosition, size);
      if (region != null) {
        widget.onRegionTapped(region);
      }
    }
    _activePointerCount = math.max(0, _activePointerCount - 1);
    if (_activePointerCount == 0) {
      _tapCandidate = false;
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointerCount = math.max(0, _activePointerCount - 1);
    if (_activePointerCount == 0) {
      _tapCandidate = false;
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _startScale = _gridScale;
    _startOffset = _gridOffset;
    _startFocalPoint = details.localFocalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _gridScale = (_startScale * details.scale).clamp(0.76, 3.8).toDouble();
      _gridOffset = _startOffset + details.localFocalPoint - _startFocalPoint;
    });
  }

  _ThreatSectorMapPainter _painter() {
    final regions = widget.controller.threatRegionConfigs;
    return _ThreatSectorMapPainter(
      regions: regions,
      states: {
        for (final state in widget.controller.threatRegions)
          state.regionId: state,
      },
      selectedRegionId: widget.controller.selectedThreatRegionId,
      gridScale: _gridScale,
      gridOffset: _gridOffset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Listener(
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: (event) => _handlePointerUp(event, size),
          onPointerCancel: _handlePointerCancel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CustomPaint(
                isComplex: true,
                painter: _painter(),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThreatSectorMapPainter extends CustomPainter {
  const _ThreatSectorMapPainter({
    required this.regions,
    required this.states,
    required this.selectedRegionId,
    required this.gridScale,
    required this.gridOffset,
  });

  final List<ThreatRegionConfig> regions;
  final Map<String, ThreatRegionState> states;
  final String? selectedRegionId;
  final double gridScale;
  final Offset gridOffset;

  ThreatRegionConfig? regionAt(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scenePoint = center + ((position - gridOffset - center) / gridScale);
    final radius = _hexGridRadius(size);
    for (final region in regions.reversed) {
      final point = _axialToPixel(region.q, region.r, radius, center);
      if (_hexPath(point, radius * 0.92).contains(scenePoint)) {
        return region;
      }
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = _hexGridRadius(size);
    _drawFixedBackdrop(canvas, size, center, radius);

    canvas.save();
    canvas.translate(gridOffset.dx, gridOffset.dy);
    canvas.translate(center.dx, center.dy);
    canvas.scale(gridScale);
    canvas.translate(-center.dx, -center.dy);
    _drawSpiralPath(canvas, center, radius);
    _drawSectors(canvas, center, radius);
    canvas.restore();
  }

  void _drawFixedBackdrop(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
  ) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.24, -0.35),
          radius: 1.24,
          colors: [
            LightcorePalette.stroke.withValues(alpha: 0.28),
            LightcorePalette.abyss.withValues(alpha: 0.72),
            LightcorePalette.night.withValues(alpha: 0.96),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );

    final starPaint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 86; index += 1) {
      final x = _hashUnit(index, 11) * size.width;
      final y = _hashUnit(index, 29) * size.height;
      final starRadius = 0.45 + (_hashUnit(index, 71) * 1.1);
      starPaint.color = Color.lerp(
        LightcorePalette.mist,
        LightcorePalette.aether,
        _hashUnit(index, 101),
      )!.withValues(alpha: 0.08 + (_hashUnit(index, 47) * 0.2));
      canvas.drawCircle(Offset(x, y), starRadius, starPaint);
    }

    final orbitalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = LightcorePalette.stroke.withValues(alpha: 0.18);
    for (var ring = 1; ring <= 4; ring += 1) {
      canvas.drawCircle(center, radius * (ring * 1.95 + 0.65), orbitalPaint);
    }

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = LightcorePalette.stroke.withValues(alpha: 0.48);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.6), const Radius.circular(18)),
      borderPaint,
    );
  }

  void _drawSectors(Canvas canvas, Offset center, double radius) {
    for (final region in regions) {
      final state = states[region.id];
      final point = _axialToPixel(region.q, region.r, radius, center);
      final hexRadius = radius * 0.92;
      final path = _hexPath(point, hexRadius);
      final revealed = state?.revealed ?? false;
      final full =
          state != null && state.stabilizedLevel >= region.stabilizationLayers;
      final tint = full ? LightcorePalette.success : _rarityTint(region.rarity);

      _drawSectorFill(
        canvas,
        path: path,
        center: point,
        radius: hexRadius,
        tint: tint,
        revealed: revealed,
        full: full,
      );
      _drawSectorTexture(
        canvas,
        path: path,
        center: point,
        radius: hexRadius,
        region: region,
        tint: tint,
        revealed: revealed,
      );
      _drawAnomalyMarkers(
        canvas,
        center: point,
        radius: hexRadius,
        region: region,
        revealed: revealed,
      );
      _drawSectorLabels(
        canvas,
        center: point,
        radius: hexRadius,
        region: region,
        state: state,
        revealed: revealed,
      );
      if (region.id == selectedRegionId) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.8 / gridScale.clamp(1, 2.2)
            ..strokeJoin = StrokeJoin.round
            ..color = LightcorePalette.solar,
        );
      }
    }
  }

  void _drawSpiralPath(Canvas canvas, Offset center, double radius) {
    if (regions.length < 2) {
      return;
    }
    final points = [
      for (final region in regions)
        _axialToPixel(region.q, region.r, radius, center),
    ];
    final basePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      basePath.lineTo(point.dx, point.dy);
    }
    final baseWidth = (radius * 0.2) / gridScale.clamp(1, 2.4);
    canvas.drawPath(
      basePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = baseWidth
        ..color = LightcorePalette.stroke.withValues(alpha: 0.32),
    );

    var lastRevealedIndex = 0;
    for (var index = 0; index < regions.length; index += 1) {
      if (states[regions[index].id]?.revealed ?? false) {
        lastRevealedIndex = index;
      }
    }
    if (lastRevealedIndex <= 0) {
      return;
    }
    final revealedPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index <= lastRevealedIndex; index += 1) {
      revealedPath.lineTo(points[index].dx, points[index].dy);
    }
    canvas.drawPath(
      revealedPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = baseWidth * 0.7
        ..color = LightcorePalette.solar.withValues(alpha: 0.72),
    );
  }

  void _drawSectorFill(
    Canvas canvas, {
    required Path path,
    required Offset center,
    required double radius,
    required Color tint,
    required bool revealed,
    required bool full,
  }) {
    final bounds = path.getBounds().inflate(radius * 0.14);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          center: const Alignment(-0.36, -0.42),
          radius: 1.18,
          colors: revealed
              ? [
                  tint.withValues(alpha: full ? 0.5 : 0.36),
                  LightcorePalette.panel.withValues(alpha: 0.5),
                  LightcorePalette.abyss.withValues(alpha: 0.88),
                ]
              : [
                  tint.withValues(alpha: 0.08),
                  LightcorePalette.panel.withValues(alpha: 0.26),
                  LightcorePalette.night.withValues(alpha: 0.88),
                ],
          stops: const [0, 0.5, 1],
        ).createShader(bounds),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = revealed ? 1.2 / gridScale.clamp(1, 2.2) : 0.9
        ..strokeJoin = StrokeJoin.round
        ..color = revealed
            ? tint.withValues(alpha: full ? 0.72 : 0.5)
            : LightcorePalette.mist.withValues(alpha: 0.14),
    );
    canvas.drawPath(
      _hexPath(center, radius * 0.72),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.62 / gridScale.clamp(1, 2)
        ..strokeJoin = StrokeJoin.round
        ..color = LightcorePalette.mist.withValues(
          alpha: revealed ? 0.18 : 0.08,
        ),
    );
  }

  void _drawSectorTexture(
    Canvas canvas, {
    required Path path,
    required Offset center,
    required double radius,
    required ThreatRegionConfig region,
    required Color tint,
    required bool revealed,
  }) {
    canvas.save();
    canvas.clipPath(path);
    final lanePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55 / gridScale.clamp(1, 2.2)
      ..strokeCap = StrokeCap.round
      ..color = tint.withValues(alpha: revealed ? 0.18 : 0.08);
    final laneCount = gridScale > 1.7 ? 4 : 2;
    for (var lane = -laneCount; lane <= laneCount; lane += 1) {
      final offset = lane * radius * 0.25;
      canvas.drawLine(
        center + Offset(-radius * 0.88, offset - radius * 0.58),
        center + Offset(radius * 0.88, offset + radius * 0.58),
        lanePaint,
      );
    }

    final dustPaint = Paint()..style = PaintingStyle.fill;
    final dustCount = gridScale > 2.1 ? 11 : 5;
    final seed = (region.q * 31) + (region.r * 47) + (region.ring * 83);
    for (var index = 0; index < dustCount; index += 1) {
      final angle = _hashUnit(seed + index, 17) * math.pi * 2;
      final distance = radius * (0.18 + (_hashUnit(seed + index, 43) * 0.56));
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      dustPaint.color = Color.lerp(
        tint,
        LightcorePalette.layer2,
        0.42,
      )!.withValues(alpha: revealed ? 0.28 : 0.1);
      canvas.drawCircle(
        point,
        0.55 + (_hashUnit(seed + index, 67) * 0.75),
        dustPaint,
      );
    }
    canvas.restore();
  }

  void _drawAnomalyMarkers(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required ThreatRegionConfig region,
    required bool revealed,
  }) {
    canvas.drawCircle(
      center,
      radius * 0.32,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75 / gridScale.clamp(1, 2.2)
        ..color = LightcorePalette.mist.withValues(
          alpha: revealed ? 0.16 : 0.08,
        ),
    );

    for (var index = 0; index < region.anomalyCardIds.length; index += 1) {
      final config = _enemyConfigById(region.anomalyCardIds[index]);
      final color = config?.affinity.color ?? _rarityTint(region.rarity);
      final angle = (-math.pi / 2) + (index * math.pi * 2 / 3);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.32;
      canvas.drawCircle(
        point,
        radius * (revealed ? 0.075 : 0.052),
        Paint()
          ..style = PaintingStyle.fill
          ..color = revealed
              ? color.withValues(alpha: 0.9)
              : color.withValues(alpha: 0.22),
      );
      canvas.drawCircle(
        point,
        radius * 0.11,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 / gridScale.clamp(1, 2.2)
          ..color = color.withValues(alpha: revealed ? 0.48 : 0.14),
      );
    }

    if (region.hasDoubleBoss) {
      final bossPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = LightcorePalette.warning.withValues(
          alpha: revealed ? 0.88 : 0.24,
        );
      canvas.drawCircle(center, radius * 0.13, bossPaint);
      canvas.drawCircle(
        center + Offset(radius * 0.16, -radius * 0.04),
        radius * 0.09,
        bossPaint,
      );
    }
  }

  void _drawSectorLabels(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required ThreatRegionConfig region,
    required ThreatRegionState? state,
    required bool revealed,
  }) {
    if (gridScale < 1.45) {
      return;
    }
    final spiralIndex = regions.indexWhere((item) => item.id == region.id);
    final title = spiralIndex < 0
        ? 'S--'
        : 'S${(spiralIndex + 1).toString().padLeft(2, '0')}';
    _drawCenteredText(
      canvas,
      title,
      center + Offset(0, -radius * 0.54),
      fontSize: radius * 0.18,
      color: revealed
          ? LightcorePalette.mist.withValues(alpha: 0.78)
          : LightcorePalette.mist.withValues(alpha: 0.32),
      weight: FontWeight.w700,
    );
    if (gridScale < 2.05) {
      return;
    }
    final progress = revealed && state != null
        ? 'W${state.stabilizedLevel * 5}/${region.stabilizationLayers * 5}'
        : 'UNCHARTED';
    _drawCenteredText(
      canvas,
      progress,
      center + Offset(0, radius * 0.5),
      fontSize: radius * 0.16,
      color: revealed
          ? _rarityTint(region.rarity).withValues(alpha: 0.92)
          : LightcorePalette.warning.withValues(alpha: 0.58),
      weight: FontWeight.w700,
    );
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.w500,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: 0,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  double _hexGridRadius(Size size) {
    return math.min(size.width / 11.2, size.height / 9.8);
  }

  Offset _axialToPixel(int q, int r, double radius, Offset center) {
    final x = radius * math.sqrt(3) * (q + (r / 2));
    final y = radius * 1.5 * r;
    return center + Offset(x, y);
  }

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (var index = 0; index < 6; index += 1) {
      final angle = (math.pi / 180) * (60 * index - 30);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  double _hashUnit(int seed, int salt) {
    final raw = math.sin((seed * 12.9898) + (salt * 78.233)) * 43758.5453;
    return raw - raw.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _ThreatSectorMapPainter oldDelegate) {
    return oldDelegate.regions != regions ||
        oldDelegate.states != states ||
        oldDelegate.selectedRegionId != selectedRegionId ||
        oldDelegate.gridScale != gridScale ||
        oldDelegate.gridOffset != gridOffset;
  }
}

Future<void> showThreatRegionIntelDialog(
  BuildContext context,
  LightcoreController controller,
  String regionId,
) {
  final region = controller.threatRegionConfigById(regionId);
  if (region == null) {
    return Future<void>.value();
  }
  return showDialog<void>(
    context: context,
    barrierColor: LightcorePalette.night.withValues(alpha: 0.76),
    builder: (dialogContext) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return _ThreatRegionIntelDialog(
            controller: controller,
            region: region,
          );
        },
      );
    },
  );
}

class _ThreatRegionIntelDialog extends StatelessWidget {
  const _ThreatRegionIntelDialog({
    required this.controller,
    required this.region,
  });

  final LightcoreController controller;
  final ThreatRegionConfig region;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = controller.threatRegionStateById(region.id);
    final revealed = state?.revealed ?? false;
    final full =
        state != null && state.stabilizedLevel >= region.stabilizationLayers;
    final activeChallenge = controller.activeThreatRegionChallenge;
    final activeHere = activeChallenge?.regionId == region.id;
    final activeValidation = controller.activeThreatRegionFarmValidation;
    final validationHere = activeValidation?.regionId == region.id;
    final bossNames = _bossNames(region);
    final anomalyNames = _anomalyNames(region);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: AuroraPanel(
          tint: _rarityTint(region.rarity),
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(region.name, style: textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            revealed
                                ? 'Route step ${controller.threatRegionSpiralIndex(region.id) + 1} • Ring ${region.ring}'
                                : 'Locked route step ${controller.threatRegionSpiralIndex(region.id) + 1}',
                            style: textTheme.labelLarge?.copyWith(
                              color: revealed
                                  ? _rarityTint(region.rarity)
                                  : LightcorePalette.warning,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Close region intel',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MapChip(
                      label: revealed
                          ? 'W${state!.stabilizedLevel * 5}/${region.stabilizationLayers * 5}'
                          : 'Unrevealed',
                      tint: revealed
                          ? (full
                                ? LightcorePalette.success
                                : _rarityTint(region.rarity))
                          : LightcorePalette.warning,
                    ),
                    _MapChip(
                      label: '${region.anomalyCardIds.length} anomalies',
                    ),
                    _MapChip(label: '${bossNames.length} apex'),
                    _MapChip(label: '${region.stabilizationLayers * 5} waves'),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _threatRegionLore(region),
                  style: textTheme.bodyMedium?.copyWith(
                    color: LightcorePalette.mist.withValues(alpha: 0.82),
                    height: 1.32,
                  ),
                ),
                const SizedBox(height: 14),
                _IntelSection(
                  title: 'Anomaly signatures',
                  value: anomalyNames.join('  •  '),
                ),
                const SizedBox(height: 10),
                _IntelSection(
                  title: 'Apex return',
                  value: bossNames.join('  •  '),
                ),
                if (revealed) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MapChip(
                        label:
                            'Best ${state!.bestStabilityPercent.toStringAsFixed(0)}%',
                      ),
                      _MapChip(label: _directorStatus(controller, state)),
                      _MapChip(
                        label: controller.validatedFarmRegionId == region.id
                            ? 'Offline validated'
                            : 'Offline pending',
                        tint: controller.validatedFarmRegionId == region.id
                            ? LightcorePalette.success
                            : LightcorePalette.warning,
                      ),
                      _MapChip(
                        label: validationHere
                            ? _farmValidationStatus(controller)
                            : activeHere
                            ? _challengeStatus(controller)
                            : region.hasDoubleBoss
                            ? 'Final: 2 apex'
                            : 'Final: 1 apex',
                        tint: validationHere || activeHere
                            ? LightcorePalette.warning
                            : LightcorePalette.mist,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Layer2AreaCommandPanel(
                    controller: controller,
                    region: region,
                    state: state,
                    activeHere: activeHere,
                    validationHere: validationHere,
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Layer2AreaCommandPanel extends StatelessWidget {
  const _Layer2AreaCommandPanel({
    required this.controller,
    required this.region,
    required this.state,
    required this.activeHere,
    required this.validationHere,
  });

  final LightcoreController controller;
  final ThreatRegionConfig region;
  final ThreatRegionState state;
  final bool activeHere;
  final bool validationHere;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final component = controller.equippedLayer2ComponentForRegion(region.id);
    final nextWave = (state.stabilizedLevel + 1) * 5;
    final canPush = controller.canStartThreatRegionChallenge(region.id);
    final canLock = controller.canStartThreatRegionFarmValidation(region.id);
    final lockedHere = controller.validatedFarmRegionId == region.id;
    final offlineKills = lockedHere
        ? controller.threatRegionOfflineKillsPerHour
        : 0.0;
    final offlineLumens = lockedHere
        ? controller.threatRegionOfflineLumensPerHour
        : 0.0;
    final farmWave = math.max(
      state.bestCompletedWave,
      state.stabilizedLevel * 5,
    );
    final finalWave = region.stabilizationLayers * 5;
    final director = state.assignedThreatDirectorId == null
        ? null
        : controller.enemyManagers
              .where(
                (manager) =>
                    manager.instanceId == state.assignedThreatDirectorId,
              )
              .cast<EnemyManagerState?>()
              .firstWhere((manager) => manager != null, orElse: () => null);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LightcorePalette.layer2.withValues(alpha: 0.26),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.route_rounded,
                  color: LightcorePalette.layer2,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Layer 2 Area Command',
                    style: textTheme.titleSmall?.copyWith(
                      color: LightcorePalette.mist,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _MapChip(
                  label: lockedHere ? 'Farming' : 'Needs lock',
                  tint: lockedHere
                      ? LightcorePalette.success
                      : LightcorePalette.warning,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CommandMetric(
                  label: 'Best farm wave',
                  value: farmWave <= 0 ? 'None' : 'Wave $farmWave',
                ),
                _CommandMetric(
                  label: 'Route clear',
                  value: 'Wave ${state.stabilizedLevel * 5}/$finalWave',
                ),
                _CommandMetric(
                  label: 'Next push',
                  value: state.stabilizedLevel >= region.stabilizationLayers
                      ? 'Cleared'
                      : 'Wave $nextWave',
                ),
                _CommandMetric(
                  label: 'Offline',
                  value: lockedHere
                      ? '${offlineLumens.toStringAsFixed(0)} L/h'
                      : 'Lock wave',
                ),
                _CommandMetric(
                  label: 'Kills',
                  value: lockedHere
                      ? '${offlineKills.toStringAsFixed(0)}/h'
                      : 'Pending',
                ),
                _CommandMetric(
                  label: 'Director',
                  value: director?.name ?? 'None',
                ),
                _CommandMetric(
                  label: 'Component',
                  value: component == null
                      ? 'Unassigned'
                      : controller.layer2ComponentOutputLabel(component),
                ),
                _CommandMetric(label: 'Equipment', value: 'Layer 2+ Apex only'),
              ],
            ),
            if (component != null) ...[
              const SizedBox(height: 10),
              Text(
                component.signatureLabel,
                style: textTheme.bodySmall?.copyWith(
                  color: LightcorePalette.layer2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: canPush
                      ? () {
                          final started = controller.startThreatRegionChallenge(
                            region.id,
                          );
                          if (started) {
                            Navigator.of(context).maybePop();
                          }
                        }
                      : null,
                  icon: Icon(
                    activeHere
                        ? Icons.warning_amber_rounded
                        : Icons.flag_rounded,
                  ),
                  label: Text(
                    activeHere
                        ? 'Challenge Active'
                        : state.stabilizedLevel >= region.stabilizationLayers
                        ? 'Area Cleared'
                        : 'Push Wave $nextWave',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: canLock
                      ? () {
                          final locked = controller
                              .startThreatRegionFarmValidation(region.id);
                          if (locked) {
                            Navigator.of(context).maybePop();
                          }
                        }
                      : null,
                  icon: Icon(
                    validationHere
                        ? Icons.hourglass_top_rounded
                        : lockedHere
                        ? Icons.verified_rounded
                        : Icons.waves_rounded,
                  ),
                  label: Text(
                    validationHere
                        ? 'Locking Farm'
                        : lockedHere
                        ? 'Relock Farm Wave'
                        : 'Lock Farm Wave',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandMetric extends StatelessWidget {
  const _CommandMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 118, maxWidth: 176),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: LightcorePalette.abyss.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: LightcorePalette.stroke.withValues(alpha: 0.34),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: LightcorePalette.mist.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: LightcorePalette.mist,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntelSection extends StatelessWidget {
  const _IntelSection({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: LightcorePalette.aether,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: LightcorePalette.mist.withValues(alpha: 0.76),
          ),
        ),
      ],
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.label, this.tint});

  final String label;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? LightcorePalette.layer2;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ThreatMapStarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 90; index += 1) {
      final x = _hashUnit(index, 7) * size.width;
      final y = _hashUnit(index, 23) * size.height;
      paint.color = Color.lerp(
        LightcorePalette.mist,
        LightcorePalette.aether,
        _hashUnit(index, 41),
      )!.withValues(alpha: 0.05 + (_hashUnit(index, 53) * 0.16));
      canvas.drawCircle(
        Offset(x, y),
        0.45 + (_hashUnit(index, 67) * 1.25),
        paint,
      );
    }
  }

  double _hashUnit(int seed, int salt) {
    final raw = math.sin((seed * 12.9898) + (salt * 78.233)) * 43758.5453;
    return raw - raw.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _ThreatMapStarfieldPainter oldDelegate) => false;
}

String _challengeStatus(LightcoreController controller) {
  final challenge = controller.activeThreatRegionChallenge;
  final remaining = controller.activeThreatRegionChallengeRemainingSeconds
      .ceil();
  final defeated = controller.activeThreatRegionDefeatedBossCount;
  final required = controller.activeThreatRegionRequiredBossCount;
  final bossText = required <= 0 ? '' : ' • Apex $defeated/$required';
  final waveText = challenge == null
      ? 'Wave'
      : 'Wave ${challenge.waveIndex + 1}/${LightcoreController.threatRegionChallengeWaveCount}';
  return '$waveText • ${_formatDuration(remaining)}$bossText';
}

String _farmValidationStatus(LightcoreController controller) {
  final validation = controller.activeThreatRegionFarmValidation;
  if (validation == null) {
    return 'Farm wave idle';
  }
  final remaining = controller.activeThreatRegionFarmValidationRemainingSeconds
      .ceil();
  return 'Locking wave ${validation.waveIndex + 1}/${LightcoreController.farmValidationWaveCount} • ${_formatDuration(remaining)}';
}

String _formatDuration(int totalSeconds) {
  final safeSeconds = math.max(0, totalSeconds);
  final minutes = safeSeconds ~/ 60;
  final seconds = safeSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String _directorStatus(
  LightcoreController controller,
  ThreatRegionState state,
) {
  final assignedId = state.assignedThreatDirectorId;
  if (assignedId == null) {
    return 'No director';
  }
  final manager = controller.enemyManagers.where(
    (manager) => manager.instanceId == assignedId,
  );
  final name = manager.isEmpty ? 'Director' : manager.first.name;
  return state.hasValidatedThreatDirector ? '$name validated' : '$name pending';
}

List<String> _anomalyNames(ThreatRegionConfig region) {
  final names = region.anomalyCardIds
      .map(_enemyConfigById)
      .whereType<EnemyConfig>()
      .map((config) => config.name)
      .toList(growable: false);
  return names.isEmpty ? const ['Unresolved anomaly signatures'] : names;
}

List<String> _bossNames(ThreatRegionConfig region) {
  final bosses =
      [
            _bossConfigById(region.primaryBossId),
            if (region.secondaryBossId != null)
              _bossConfigById(region.secondaryBossId),
          ]
          .whereType<EnemyConfig>()
          .map((config) => config.name)
          .toList(growable: false);
  return bosses.isEmpty ? const ['Unresolved apex return'] : bosses;
}

EnemyConfig? _enemyConfigById(String id) {
  if (EnemyLibrary.starterDefault.id == id) {
    return EnemyLibrary.starterDefault;
  }
  for (final config in EnemyLibrary.all) {
    if (config.id == id) {
      return config;
    }
  }
  return null;
}

EnemyConfig? _bossConfigById(String? id) {
  if (id == null) {
    return null;
  }
  for (final config in BossEnemyLibrary.all) {
    if (config.id == id) {
      return config;
    }
  }
  return null;
}

String _threatRegionLore(ThreatRegionConfig region) {
  final boss = _bossConfigById(region.primaryBossId);
  final secondaryBoss = _bossConfigById(region.secondaryBossId);
  final anomalies = region.anomalyCardIds
      .map(_enemyConfigById)
      .whereType<EnemyConfig>()
      .toList(growable: false);
  final leadAffinity =
      boss?.affinity ??
      (anomalies.isEmpty
          ? PrototypeAffinity.neutral
          : anomalies.first.affinity);
  final myth = _sectorMythFor(leadAffinity, boss?.name ?? 'the apex return');
  final traits = anomalies
      .map((config) => config.traitLabel.toLowerCase())
      .toSet()
      .take(3)
      .join(', ');
  final anomalyClause = traits.isEmpty
      ? 'soft static and incomplete wake traces'
      : traits;
  final bossClause = secondaryBoss == null
      ? 'The deepest return points to ${boss?.name ?? 'an unnamed apex anomaly'}.'
      : 'Two apex returns overlap: ${boss?.name ?? 'an unnamed apex anomaly'} and ${secondaryBoss.name}.';
  return '$myth Sensor drift shows $anomalyClause. $bossClause';
}

String _sectorMythFor(PrototypeAffinity affinity, String bossName) {
  return switch (affinity) {
    PrototypeAffinity.black =>
      'This region is avoided for the myth of a leviathan-sized black hole; no scout has seen the shadow behind $bossName and returned with their clocks intact.',
    PrototypeAffinity.ember =>
      'Crews route around this sector because old hulls still glow red on approach, as if $bossName keeps a furnace awake between the lanes.',
    PrototypeAffinity.flare =>
      'Pilots call this a slingshot sector: ships enter fast, exit faster, and leave orange afterimages that point back toward $bossName.',
    PrototypeAffinity.solar =>
      'Navigation charts stutter here, repeating yellow coordinates until scouts swear $bossName is blinking through the beacon grid.',
    PrototypeAffinity.verdant =>
      'Derelict stations bloom with green light after power failure, a sign that $bossName is feeding on abandoned routes.',
    PrototypeAffinity.aether =>
      'Every rescue ping comes back blue and doubled, like $bossName is turning distress calls into bait.',
    PrototypeAffinity.violet =>
      'Expeditions report violet echoes from trips they never took, and each duplicate log places $bossName one hex closer.',
    PrototypeAffinity.neutral =>
      'This sector looks quiet on first scan, which is why crews distrust it; the clean readings keep bending back toward $bossName.',
  };
}

Color _rarityTint(EnemyCardRarity rarity) {
  return switch (rarity) {
    EnemyCardRarity.basic => LightcorePalette.layer2,
    EnemyCardRarity.uncommon => LightcorePalette.success,
    EnemyCardRarity.rare => LightcorePalette.aether,
    EnemyCardRarity.epic => LightcorePalette.solar,
    EnemyCardRarity.legendary => LightcorePalette.violet,
  };
}
