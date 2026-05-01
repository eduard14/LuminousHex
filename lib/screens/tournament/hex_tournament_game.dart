part of '../tournament_screen.dart';

class _HexTournamentGame extends FlameGame {
  _HexTournamentGame({
    required this.run,
    required this.snapshotNotifier,
    required this.onCellTap,
    required this.onCellDrop,
    required this.onRunEnded,
  });

  final HexTournamentRunController run;
  final ValueNotifier<HexTournamentSnapshot> snapshotNotifier;
  final ValueChanged<String> onCellTap;
  final void Function(String sourceCellId, String targetCellId) onCellDrop;
  final VoidCallback onRunEnded;

  static const double _dragStartDistance = 8;
  static const double _towerBurstDuration = 0.52;

  bool _endDispatched = false;
  Offset? _pointerDownPosition;
  Offset? _dragPosition;
  String? _dragSourceCellId;
  String? _dragHoverCellId;
  bool _draggingTower = false;
  double _elapsed = 0;
  Set<String> _knownTowerIds = <String>{};
  Map<String, int> _knownTowerStages = <String, int>{};
  Map<String, double> _towerBursts = <String, double>{};

  @override
  Color backgroundColor() => Colors.transparent;

  void _syncTowerVisuals(HexTournamentSnapshot snapshot, double dt) {
    final currentTowerIds = <String>{};
    final nextStages = <String, int>{};

    for (final tower in snapshot.towers) {
      currentTowerIds.add(tower.id);
      nextStages[tower.id] = tower.mergeStage;
      final previousStage = _knownTowerStages[tower.id];
      if (!_knownTowerIds.contains(tower.id) ||
          (previousStage != null && previousStage != tower.mergeStage)) {
        _towerBursts[tower.id] = _towerBurstDuration;
      }
    }

    _towerBursts.removeWhere(
      (towerId, _) => !currentTowerIds.contains(towerId),
    );
    _towerBursts = <String, double>{
      for (final entry in _towerBursts.entries)
        if (entry.value > 0) entry.key: max(0.0, entry.value - dt).toDouble(),
    };
    _knownTowerIds = currentTowerIds;
    _knownTowerStages = nextStages;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final clamped = dt.clamp(0.0, 0.05).toDouble();
    _elapsed += clamped;
    run.tick(clamped);
    final snapshot = run.snapshot;
    _syncTowerVisuals(snapshot, clamped);
    snapshotNotifier.value = snapshot;
    if (snapshot.running) {
      _endDispatched = false;
    }
    if (snapshot.defeated && !_endDispatched) {
      _endDispatched = true;
      onRunEnded();
    }
  }

  void handlePointerDown(Offset localPosition) {
    final snapshot = run.snapshot;
    final cell = _cellAt(localPosition, snapshot);
    _pointerDownPosition = localPosition;
    _dragPosition = localPosition;
    _dragSourceCellId = cell != null && _towerAt(snapshot, cell.id) != null
        ? cell.id
        : null;
    _dragHoverCellId = cell?.id;
    _draggingTower = false;
  }

  void handlePointerMove(Offset localPosition) {
    final sourceCellId = _dragSourceCellId;
    final downPosition = _pointerDownPosition;
    if (sourceCellId == null || downPosition == null) {
      return;
    }
    if (!_draggingTower &&
        (localPosition - downPosition).distance < _dragStartDistance) {
      return;
    }
    _draggingTower = true;
    _dragPosition = localPosition;
    _dragHoverCellId = _cellAt(localPosition, run.snapshot)?.id;
  }

  void handlePointerUp(Offset localPosition) {
    if (_pointerDownPosition == null) {
      return;
    }
    final cell = _cellAt(localPosition, run.snapshot);
    final sourceCellId = _dragSourceCellId;
    if (_draggingTower &&
        sourceCellId != null &&
        cell != null &&
        cell.id != sourceCellId) {
      onCellDrop(sourceCellId, cell.id);
    } else if (cell != null) {
      onCellTap(cell.id);
    }
    handlePointerCancel();
  }

  void handlePointerCancel() {
    _pointerDownPosition = null;
    _dragPosition = null;
    _dragSourceCellId = null;
    _dragHoverCellId = null;
    _draggingTower = false;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final snapshot = run.snapshot;
    final rect = Offset.zero & Size(size.x, size.y);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            LightcorePalette.night,
            LightcorePalette.abyss,
            Color(0xFF123044),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    if (size.x <= 0 || size.y <= 0) {
      return;
    }

    _drawPath(canvas, snapshot);
    for (final cell in snapshot.cells) {
      _drawCell(canvas, snapshot, cell);
    }
    for (final shot in snapshot.shots) {
      _drawShot(canvas, snapshot, shot);
    }
    for (final tower in snapshot.towers) {
      _drawTower(canvas, tower);
    }
    _drawDragPreview(canvas, snapshot);
    for (final enemy in snapshot.enemies.where((enemy) => enemy.isOnBoard)) {
      _drawEnemy(canvas, snapshot, enemy);
    }
    if (snapshot.paused || snapshot.defeated) {
      _drawCenterBanner(
        canvas,
        snapshot.defeated ? 'CORE BROKE' : 'PAUSED',
        snapshot.defeated ? LightcorePalette.warning : LightcorePalette.solar,
      );
    }
  }

  void _drawPath(Canvas canvas, HexTournamentSnapshot snapshot) {
    if (snapshot.pathCells.length < 2) {
      return;
    }
    final path = Path();
    for (var index = 0; index < snapshot.pathCells.length; index += 1) {
      final point = _cellCenter(snapshot.pathCells[index]);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = _hexRadius * 0.78
        ..color = LightcorePalette.night.withValues(alpha: 0.72),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = _hexRadius * 0.28
        ..color = LightcorePalette.solar.withValues(alpha: 0.34),
    );
  }

  void _drawCell(
    Canvas canvas,
    HexTournamentSnapshot snapshot,
    HexTournamentCell cell,
  ) {
    final center = _cellCenter(cell);
    final selected = snapshot.selectedCellId == cell.id;
    final tower = _towerAt(snapshot, cell.id);
    final dragSource = _dragSourceCellId == cell.id;
    final dragHover = _draggingTower && _dragHoverCellId == cell.id;
    final canDropMerge = dragHover && _canDropMerge(snapshot, cell.id);
    final path = _hexPath(center, _hexRadius * 0.92);
    final baseColor = cell.isPath
        ? LightcorePalette.night
        : tower == null
        ? LightcorePalette.panel.withValues(alpha: 0.58)
        : tower.affinity.color.withValues(alpha: 0.20);
    canvas.drawPath(path, Paint()..color = baseColor);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = dragHover || dragSource
            ? 3.4
            : selected
            ? 3.0
            : 1.2
        ..color = dragHover
            ? canDropMerge
                  ? LightcorePalette.success
                  : LightcorePalette.warning
            : dragSource
            ? LightcorePalette.aether
            : selected
            ? LightcorePalette.gilded
            : cell.isPath
            ? LightcorePalette.solar.withValues(alpha: 0.34)
            : LightcorePalette.stroke.withValues(alpha: 0.55),
    );
  }

  void _drawDragPreview(Canvas canvas, HexTournamentSnapshot snapshot) {
    if (!_draggingTower) {
      return;
    }
    final sourceCellId = _dragSourceCellId;
    final dragPosition = _dragPosition;
    if (sourceCellId == null || dragPosition == null) {
      return;
    }
    final tower = _towerAt(snapshot, sourceCellId);
    final sourceCenter = _cellCenterById(sourceCellId);
    if (tower == null || sourceCenter == null) {
      return;
    }
    final hoverCellId = _dragHoverCellId;
    final validDrop =
        hoverCellId != null &&
        hoverCellId != sourceCellId &&
        _canDropMerge(snapshot, hoverCellId);
    final tint = validDrop ? LightcorePalette.success : tower.affinity.color;
    LightcoreProjectileFx.drawGlowLine(
      canvas,
      sourceCenter,
      dragPosition,
      tint,
      width: 2.4,
      alpha: validDrop ? 0.72 : 0.42,
    );
    canvas.drawCircle(
      dragPosition,
      _hexRadius * 0.56,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = tint.withValues(alpha: 0.28),
    );
    _drawTowerTraitBadge(
      canvas,
      dragPosition,
      level: (1 + (tower.mergeStage * 2)).clamp(
        1,
        LightcoreController.maxTowerLevel,
      ),
      projectileType: tower.projectileType,
      payloadType: tower.payloadType,
      tint: tint,
      size: _hexRadius * 0.86,
    );
  }

  void _drawTower(Canvas canvas, HexTournamentTower tower) {
    final center = _cellCenterById(tower.cellId);
    if (center == null) {
      return;
    }
    final radius = _hexRadius * 0.58;
    final selected = run.snapshot.selectedCellId == tower.cellId;
    final pulse = 0.5 + (sin((_elapsed * 4.0) + tower.id.hashCode) * 0.5);
    final chargeProgress = tower.cooldownSeconds <= 0
        ? 1.0
        : (1 - (tower.cooldownRemaining / tower.cooldownSeconds))
              .clamp(0.0, 1.0)
              .toDouble();

    canvas.drawPath(
      _hexPath(center, radius * 0.96),
      Paint()
        ..style = PaintingStyle.fill
        ..color = tower.affinity.color.withValues(alpha: 0.16),
    );
    canvas.drawPath(
      _hexPath(center, radius * 0.96),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = tower.affinity.color.withValues(alpha: 0.84),
    );
    if (tower.weeklyFocus) {
      canvas.drawPath(
        _hexPath(center, radius * 1.18),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = LightcorePalette.gilded.withValues(alpha: 0.76),
      );
    }
    final burstRemaining = _towerBursts[tower.id] ?? 0;
    if (burstRemaining > 0) {
      _drawTowerBurst(
        canvas,
        center,
        color: tower.affinity.color,
        radius: radius,
        progress: 1 - (burstRemaining / _towerBurstDuration),
      );
    }
    if (tower.projectileType == ProjectileType.shieldHalo) {
      _drawPersistentShieldTowerPulse(
        canvas,
        center,
        color: tower.affinity.color,
        radius: radius,
        pulse: pulse,
      );
    } else {
      _drawHexChargeIndicator(
        canvas,
        center,
        color: tower.affinity.color,
        radius: radius,
        chargeProgress: chargeProgress,
        popProgress: burstRemaining / _towerBurstDuration,
      );
    }
    if (selected) {
      canvas.drawPath(
        _hexPath(center, radius * 1.12),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
          ..color = LightcorePalette.layer2.withValues(alpha: 0.74),
      );
    }
    _drawTowerTraitBadge(
      canvas,
      center,
      level: (1 + (tower.mergeStage * 2)).clamp(
        1,
        LightcoreController.maxTowerLevel,
      ),
      projectileType: tower.projectileType,
      payloadType: tower.payloadType,
      tint: tower.affinity.color,
      size: radius * 1.45,
      complete: tower.mergeStage >= 2,
    );
  }

  void _drawEnemy(
    Canvas canvas,
    HexTournamentSnapshot snapshot,
    HexTournamentEnemy enemy,
  ) {
    final center = _pathPosition(snapshot, enemy.progress);
    final radius = _hexRadius * (enemy.tier >= 4 ? 0.36 : 0.30);
    final revealPulse = 0.5 + (sin(enemy.progress * 2.1) * 0.5);
    final isBossLike = enemy.config.rarity.index >= EnemyCardRarity.epic.index;
    canvas.drawCircle(
      center,
      radius * (1.25 + (revealPulse * 0.16)),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = enemy.config.affinity.color.withValues(
          alpha: isBossLike ? 0.24 : 0.16,
        ),
    );
    if (isBossLike) {
      canvas.drawPath(
        _hexPath(center, radius * 1.42),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = LightcorePalette.solar.withValues(alpha: 0.78),
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = enemy.config.affinity.color.withValues(alpha: 0.92),
    );
    canvas.drawCircle(
      center,
      radius + 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = LightcorePalette.night.withValues(alpha: 0.72),
    );
    final healthWidth = radius * 1.8;
    final healthRect = Rect.fromLTWH(
      center.dx - (healthWidth / 2),
      center.dy - radius - 8,
      healthWidth,
      3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(healthRect, const Radius.circular(8)),
      Paint()..color = LightcorePalette.night.withValues(alpha: 0.72),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          healthRect.left,
          healthRect.top,
          healthRect.width * (enemy.health / enemy.maxHealth).clamp(0.0, 1.0),
          healthRect.height,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = LightcorePalette.success,
    );
  }

  void _drawShot(
    Canvas canvas,
    HexTournamentSnapshot snapshot,
    HexTournamentShotTrace shot,
  ) {
    final start = _cellCenterById(shot.sourceCellId);
    if (start == null) {
      return;
    }
    final end = _pathPosition(snapshot, shot.targetProgress);
    final color = shot.projectileType.affinity.color;
    final payloadColor = shot.payloadType.affinity?.color;
    final alpha = (1 - shot.progress).clamp(0.0, 1.0);
    final current = Offset.lerp(start, end, shot.progress.clamp(0.0, 1.0))!;
    final angle = atan2(current.dy - start.dy, current.dx - start.dx);
    final seed =
        (_elapsed * 14.0) + (shot.progress * 9.0) + (shot.id.hashCode * 0.0017);
    final width =
        LightcoreProjectileFx.lineWidth(shot.projectileType, _hexRadius) *
        (shot.secondary ? 0.74 : 1.0);

    if (shot.progress < 0.42) {
      LightcoreProjectileFx.drawFireBurst(
        canvas,
        origin: start,
        color: color,
        aimAngle: angle,
        projectileType: shot.projectileType,
        progress: (shot.progress / 0.42).clamp(0.0, 1.0).toDouble(),
        alpha: shot.secondary ? 0.62 : 1.0,
        unit: _hexRadius,
        seed: _elapsed * 9,
      );
    }

    LightcoreProjectileFx.drawProjectileTrail(
      canvas,
      projectileType: shot.projectileType,
      start: start,
      end: end,
      current: current,
      color: color,
      width: width,
      seed: seed,
      alpha: alpha.toDouble(),
      unit: _hexRadius,
      progress: shot.progress,
    );
    if (payloadColor != null && !shot.secondary) {
      LightcoreProjectileFx.drawEnergyOrb(
        canvas,
        current.translate(_hexRadius * 0.05, -_hexRadius * 0.05),
        payloadColor,
        _hexRadius * 0.045,
        alpha: 0.72 * alpha.toDouble(),
      );
    }
  }

  void _drawCenterBanner(Canvas canvas, String label, Color tint) {
    final center = Offset(size.x / 2, size.y / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: min(size.x * 0.72, 320),
      height: 54,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()..color = LightcorePalette.night.withValues(alpha: 0.82),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = tint.withValues(alpha: 0.72),
    );
    _drawText(canvas, label, center, tint, 18, FontWeight.w900);
  }

  HexTournamentCell? _cellAt(
    Offset localPosition,
    HexTournamentSnapshot snapshot,
  ) {
    HexTournamentCell? nearest;
    var nearestDistance = double.infinity;
    for (final cell in snapshot.cells) {
      final distance = (_cellCenter(cell) - localPosition).distance;
      if (distance < nearestDistance) {
        nearest = cell;
        nearestDistance = distance;
      }
    }
    return nearestDistance <= _hexRadius * 0.95 ? nearest : null;
  }

  HexTournamentTower? _towerAt(HexTournamentSnapshot snapshot, String cellId) {
    for (final tower in snapshot.towers) {
      if (tower.cellId == cellId) {
        return tower;
      }
    }
    return null;
  }

  bool _canDropMerge(HexTournamentSnapshot snapshot, String targetCellId) {
    final sourceCellId = _dragSourceCellId;
    if (sourceCellId == null || sourceCellId == targetCellId) {
      return false;
    }
    final sourceTower = _towerAt(snapshot, sourceCellId);
    final targetTower = _towerAt(snapshot, targetCellId);
    return sourceTower != null &&
        targetTower != null &&
        sourceTower.config.id == targetTower.config.id &&
        sourceTower.mergeStage == targetTower.mergeStage &&
        sourceTower.mergeStage < 2;
  }

  Offset? _cellCenterById(String cellId) {
    final snapshot = run.snapshot;
    for (final cell in snapshot.cells) {
      if (cell.id == cellId) {
        return _cellCenter(cell);
      }
    }
    return null;
  }

  Offset _pathPosition(HexTournamentSnapshot snapshot, double progress) {
    final pathCells = snapshot.pathCells;
    if (pathCells.isEmpty) {
      return Offset(size.x / 2, size.y / 2);
    }
    final clamped = progress.clamp(0.0, (pathCells.length - 1).toDouble());
    final lower = clamped.floor();
    final upper = min(pathCells.length - 1, lower + 1);
    final t = clamped - lower;
    return Offset.lerp(
      _cellCenter(pathCells[lower]),
      _cellCenter(pathCells[upper]),
      t,
    )!;
  }

  Offset _cellCenter(HexTournamentCell cell) {
    final radius = _hexRadius;
    final center = Offset(size.x / 2, size.y * 0.48);
    final x = radius * sqrt(3) * (cell.q + (cell.r / 2));
    final y = radius * 1.5 * cell.r;
    return center.translate(x, y);
  }

  double get _hexRadius {
    final shortest = min(size.x, size.y);
    return min(shortest / 8.1, size.x / 10.2).clamp(22.0, 54.0);
  }

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (var index = 0; index < 6; index += 1) {
      final angle = (-pi / 6) + (pi / 3 * index);
      final point = center.translate(cos(angle) * radius, sin(angle) * radius);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double fontSize,
    FontWeight fontWeight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _drawTowerBurst(
    Canvas canvas,
    Offset center, {
    required Color color,
    required double radius,
    required double progress,
  }) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final fade = 1 - Curves.easeOutCubic.transform(clamped);
    final burstRadius = radius * (0.82 + (0.58 * clamped));
    if (fade <= 0) {
      return;
    }
    canvas.drawPath(
      _hexPath(center, burstRadius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 - (clamped * 1.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = color.withValues(alpha: 0.68 * fade),
    );
    canvas.drawPath(
      _hexPath(center, radius * (0.42 + (0.24 * clamped))),
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.18 * fade),
    );
    for (var index = 0; index < 6; index += 1) {
      final angle = ((pi * 2) / 6) * index;
      final start = center.translate(
        cos(angle) * (radius * 0.42),
        sin(angle) * (radius * 0.42),
      );
      final end = center.translate(
        cos(angle) * burstRadius,
        sin(angle) * burstRadius,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.2
          ..color = color.withValues(alpha: 0.48 * fade),
      );
    }
  }

  void _drawPersistentShieldTowerPulse(
    Canvas canvas,
    Offset center, {
    required Color color,
    required double radius,
    required double pulse,
  }) {
    canvas.drawCircle(
      center,
      radius * (1.34 + (pulse * 0.18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2.0, radius * 0.12)
        ..color = color.withValues(alpha: 0.22 + (pulse * 0.14)),
    );
    canvas.drawCircle(
      center,
      radius * (1.65 + (pulse * 0.14)),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(3.0, radius * 0.18)
        ..color = color.withValues(alpha: 0.09 + (pulse * 0.08)),
    );
  }

  void _drawHexChargeIndicator(
    Canvas canvas,
    Offset center, {
    required Color color,
    required double radius,
    required double chargeProgress,
    required double popProgress,
  }) {
    final charge = chargeProgress.clamp(0.0, 1.0).toDouble();
    final guideRadius = radius * 0.76;
    final chargeRadius = radius * (0.16 + (charge * 0.56));
    final popT = Curves.easeOut.transform(1 - popProgress.clamp(0.0, 1.0));

    canvas.drawPath(
      _hexPath(center, guideRadius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = color.withValues(alpha: 0.4),
    );

    if (charge > 0) {
      final chargeHex = _hexPath(center, chargeRadius);
      canvas.drawPath(
        chargeHex,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: 0.16 + (charge * 0.32)),
      );
      canvas.drawPath(
        chargeHex,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.5 + (charge * 0.28)),
      );
    }

    if (popProgress > 0) {
      final flashRadius = radius * (0.78 + (0.18 * popT));
      canvas.drawPath(
        _hexPath(center, flashRadius),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 - (popT * 1.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
          ..color = color.withValues(alpha: 0.82 * (1 - popT)),
      );
      canvas.drawPath(
        _hexPath(center, radius * (0.68 + (0.12 * popT))),
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: 0.14 * (1 - popT)),
      );
    }
  }

  void _drawTowerTraitBadge(
    Canvas canvas,
    Offset center, {
    required int level,
    required ProjectileType projectileType,
    required PayloadType payloadType,
    required Color tint,
    required double size,
    bool complete = false,
  }) {
    final payloadColor = payloadType.affinity?.color ?? LightcorePalette.layer2;
    final projectileColor = projectileType.affinity.color;
    final radius = size * 0.42;
    final vertices = <Offset>[
      for (var index = 0; index < 6; index += 1)
        center.translate(
          cos((pi / 6) + (index * pi / 3)) * radius,
          sin((pi / 6) + (index * pi / 3)) * radius,
        ),
    ];
    final path = Path()..moveTo(vertices.first.dx, vertices.first.dy);
    for (final vertex in vertices.skip(1)) {
      path.lineTo(vertex.dx, vertex.dy);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = payloadColor.withValues(alpha: 0.14),
    );
    for (var edge = 0; edge < 6; edge += 1) {
      _drawHexEdge(
        canvas,
        vertices,
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.1, size * 0.035)
          ..strokeCap = StrokeCap.round
          ..color = LightcorePalette.stroke.withValues(alpha: 0.58),
      );
    }
    for (final edge in _activeBadgeEdges(
      level,
      LightcoreController.maxTowerLevel,
    )) {
      _drawHexEdge(
        canvas,
        vertices,
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2.0, size * 0.065)
          ..strokeCap = StrokeCap.round
          ..color = (complete ? LightcorePalette.success : tint).withValues(
            alpha: 0.96,
          ),
      );
    }
    canvas.drawCircle(
      center,
      size * 0.24,
      Paint()..color = payloadColor.withValues(alpha: 0.24),
    );
    canvas.drawCircle(
      center,
      size * 0.24,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, size * 0.025)
        ..color = payloadColor.withValues(alpha: 0.72),
    );
    _paintIconGlyph(
      canvas,
      center,
      towerProjectileIcon(projectileType),
      size: size * 0.28,
      color: projectileColor,
    );
    if (complete) {
      canvas.drawCircle(
        center.translate(size * 0.27, size * 0.25),
        size * 0.11,
        Paint()..color = LightcorePalette.success.withValues(alpha: 0.94),
      );
      _paintIconGlyph(
        canvas,
        center.translate(size * 0.27, size * 0.25),
        Icons.check_rounded,
        size: size * 0.13,
        color: LightcorePalette.night,
      );
    }
  }

  List<int> _activeBadgeEdges(int level, int maxLevel) {
    final clamped = level.clamp(0, maxLevel).toInt();
    if (clamped <= 0) {
      return const <int>[];
    }
    final normalized = ((clamped / maxLevel) * 5).ceil().clamp(1, 5).toInt();
    return switch (normalized) {
      1 => const <int>[0],
      2 => const <int>[1, 5],
      3 => const <int>[1, 3, 5],
      4 => const <int>[0, 1, 3, 5],
      _ => const <int>[0, 1, 2, 3, 4, 5],
    };
  }

  void _drawHexEdge(
    Canvas canvas,
    List<Offset> vertices,
    int edge,
    Paint paint,
  ) {
    final start = vertices[edge % vertices.length];
    final end = vertices[(edge + 1) % vertices.length];
    canvas.drawLine(start, end, paint);
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
}

extension _HexTournamentModeDetailUi on _TournamentModeDetailScreenState {
  Widget _buildHexTournamentRunPanel(BuildContext context, Color tint) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 720 || constraints.maxHeight < 720;
        final inset = compact ? 10.0 : 16.0;
        final controlsMaxHeight =
            constraints.maxHeight * (compact ? 0.50 : 0.40);
        return DecoratedBox(
          decoration: const BoxDecoration(color: LightcorePalette.night),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GameWidget<_HexTournamentGame>(
                        key: ValueKey<_HexTournamentGame>(_hexGame),
                        game: _hexGame,
                      ),
                      Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: (event) {
                          if (event.buttons == kPrimaryButton) {
                            _hexGame.handlePointerDown(event.localPosition);
                          }
                        },
                        onPointerMove: (event) {
                          if (event.buttons == kPrimaryButton) {
                            _hexGame.handlePointerMove(event.localPosition);
                          }
                        },
                        onPointerUp: (event) =>
                            _hexGame.handlePointerUp(event.localPosition),
                        onPointerCancel: (_) => _hexGame.handlePointerCancel(),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: inset,
                left: inset,
                right: inset,
                child: ValueListenableBuilder<HexTournamentSnapshot>(
                  valueListenable: _hexSnapshotNotifier,
                  builder: (context, snapshot, _) {
                    return AuroraPanel(
                      tint: tint,
                      radius: 18,
                      padding: EdgeInsets.fromLTRB(
                        compact ? 10 : 12,
                        10,
                        compact ? 8 : 10,
                        10,
                      ),
                      child: Row(
                        children: [
                          Tooltip(
                            message: 'Back to events',
                            child: IconButton.filledTonal(
                              onPressed: _returnToEventSetup,
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _HeaderChip(
                                  label: 'Score',
                                  value: '${snapshot.score}',
                                ),
                                _HeaderChip(
                                  label: 'Wave',
                                  value: '${snapshot.wave}',
                                ),
                                _HeaderChip(
                                  label: 'Cur',
                                  value: '${snapshot.currency}',
                                ),
                                _HeaderChip(
                                  label: 'Core',
                                  value:
                                      '${snapshot.health}/${snapshot.maxHealth}',
                                ),
                                _HeaderChip(
                                  label: 'Enemy',
                                  value: 'T${snapshot.enemyTier}',
                                ),
                                _HeaderChip(
                                  label: 'Streak',
                                  value: 'x${snapshot.flawlessStreak}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: snapshot.paused ? 'Resume' : 'Pause',
                            child: IconButton.filledTonal(
                              onPressed: _runActive ? _toggleHexPause : null,
                              icon: Icon(
                                snapshot.paused
                                    ? Icons.play_arrow_rounded
                                    : Icons.pause_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: inset,
                right: inset,
                bottom: inset,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: controlsMaxHeight),
                  child: ValueListenableBuilder<HexTournamentSnapshot>(
                    valueListenable: _hexSnapshotNotifier,
                    builder: (context, snapshot, _) {
                      return AuroraPanel(
                        tint: tint,
                        radius: 20,
                        padding: EdgeInsets.all(compact ? 12 : 14),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _HexFocusChips(
                                focusAffinities: snapshot.focusAffinities,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                snapshot.statusLabel,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              _buildHexSelectedTowerControls(
                                context,
                                snapshot,
                                tint,
                              ),
                              const SizedBox(height: 12),
                              _buildHexRunButtons(snapshot),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHexSelectedTowerControls(
    BuildContext context,
    HexTournamentSnapshot snapshot,
    Color tint,
  ) {
    final tower = snapshot.selectedTower;
    if (tower == null) {
      final selectedCell = snapshot.selectedCell;
      final canChooseTower = selectedCell != null && selectedCell.canBuild;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HeaderChip(
                label: 'Selected',
                value: selectedCell == null
                    ? 'None'
                    : selectedCell.isPath
                    ? 'Path'
                    : 'Open',
              ),
              _HeaderChip(label: 'Build', value: '${snapshot.buildCost}'),
            ],
          ),
          if (canChooseTower) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final config in snapshot.towerChoices)
                  _HexTowerBuildButton(
                    config: config,
                    buildCost: snapshot.buildCost,
                    enabled: snapshot.canBuildSelected,
                    onPressed: () {
                      _hexRun.placeTower(
                        snapshot.selectedCellId!,
                        config: config,
                      );
                      _refreshHexSnapshot();
                    },
                  ),
              ],
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HeaderChip(label: 'Tower', value: tower.config.name),
            _HeaderChip(label: 'Payload', value: tower.payloadType.label),
            _HeaderChip(
              label: 'Impact',
              value: tower.impactProjectileType?.label ?? 'None',
            ),
            _HeaderChip(
              label: 'Merge',
              value: '${snapshot.mergeCandidateCount}',
            ),
            _HeaderChip(
              label: 'Focus',
              value: tower.weeklyFocus ? '+16%' : 'Off',
            ),
            if (snapshot.waveLeakDamage > 0)
              _HeaderChip(
                label: 'Leaks',
                value: '${snapshot.waveLeakDamage}',
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<TargetPriority>(
              segments: [
                for (final priority in TargetPriority.values)
                  ButtonSegment<TargetPriority>(
                    value: priority,
                    label: Text(priority.label),
                  ),
              ],
              selected: <TargetPriority>{tower.targetPriority},
              onSelectionChanged: snapshot.running && !snapshot.paused
                  ? (selection) {
                      _hexRun.setSelectedTowerTargetPriority(selection.single);
                      _refreshHexSnapshot();
                    }
                  : null,
            ),
            FilledButton.tonalIcon(
              onPressed: snapshot.canMergeSelected
                  ? () {
                      _hexRun.mergeSelectedWithBestCandidate();
                      _refreshHexSnapshot();
                    }
                  : null,
              icon: const Icon(Icons.call_merge_rounded),
              label: const Text('Merge Pair'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHexRunButtons(HexTournamentSnapshot snapshot) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: snapshot.canSendWave
              ? () {
                  _hexRun.sendWave();
                  _refreshHexSnapshot();
                }
              : null,
          icon: const Icon(Icons.play_circle_fill_rounded),
          label: const Text('Send Wave'),
        ),
        FilledButton.tonalIcon(
          onPressed: snapshot.canBuyEnemyTier
              ? () {
                  _hexRun.buyEnemyTier();
                  _refreshHexSnapshot();
                }
              : null,
          icon: const Icon(Icons.trending_up_rounded),
          label: Text('Buy Enemies (${snapshot.enemyTierCost})'),
        ),
        FilledButton.tonalIcon(
          onPressed: _runActive
              ? () {
                  _hexRun.retire();
                  _hexGame.pauseEngine();
                  _completeHexRun(
                    'Run retired. Submit the score or run again.',
                  );
                  _refreshHexSnapshot();
                  widget.onBattleSurfaceActiveChanged?.call(false);
                }
              : null,
          icon: const Icon(Icons.flag_rounded),
          label: const Text('Retire'),
        ),
        FilledButton.icon(
          onPressed: _runComplete ? _submitScore : null,
          icon: const Icon(Icons.emoji_events_rounded),
          label: const Text('Submit Score'),
        ),
        FilledButton.tonalIcon(
          onPressed: widget.busy || _launchingRun || _runActive
              ? null
              : _queueStartRun,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Run Again'),
        ),
      ],
    );
  }

  void _toggleHexPause() {
    _hexRun.setPaused(!_hexRun.paused);
    if (_hexRun.paused) {
      _hexGame.pauseEngine();
    } else {
      _hexGame.resumeEngine();
    }
    _refreshHexSnapshot();
  }
}

class _HexFocusChips extends StatelessWidget {
  const _HexFocusChips({required this.focusAffinities});

  final List<PrototypeAffinity> focusAffinities;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final affinity in focusAffinities)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: affinity.color.withValues(alpha: 0.16),
              border: Border.all(color: affinity.color.withValues(alpha: 0.38)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hexagon_rounded, color: affinity.color, size: 14),
                const SizedBox(width: 6),
                Text(
                  affinity.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: affinity.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HexTowerBuildButton extends StatelessWidget {
  const _HexTowerBuildButton({
    required this.config,
    required this.buildCost,
    required this.enabled,
    required this.onPressed,
  });

  final TowerConfig config;
  final int buildCost;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 166,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: config.affinity.color.withValues(alpha: 0.92),
          foregroundColor: LightcorePalette.night,
          disabledBackgroundColor: LightcorePalette.panelRaised,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        onPressed: enabled ? onPressed : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(towerProjectileIcon(config.defaultProjectileType), size: 18),
            const SizedBox(height: 4),
            Text(
              config.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              '$buildCost Cur • ${config.defaultProjectileType.label}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LightcorePalette.night.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HexTournamentPreviewMap extends StatelessWidget {
  const _HexTournamentPreviewMap({required this.snapshot, required this.tint});

  final HexTournamentSnapshot snapshot;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: CustomPaint(
        painter: _HexTournamentPreviewPainter(snapshot: snapshot, tint: tint),
      ),
    );
  }
}

class _HexTournamentPreviewPainter extends CustomPainter {
  const _HexTournamentPreviewPainter({
    required this.snapshot,
    required this.tint,
  });

  final HexTournamentSnapshot snapshot;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()..color = LightcorePalette.panel.withValues(alpha: 0.46),
    );
    final radius = min(
      size.shortestSide / 8.2,
      size.width / 10.4,
    ).clamp(20.0, 36.0);
    Offset cellCenter(HexTournamentCell cell) {
      final center = Offset(size.width / 2, size.height * 0.50);
      return center.translate(
        radius * sqrt(3) * (cell.q + (cell.r / 2)),
        radius * 1.5 * cell.r,
      );
    }

    Path hexPath(Offset center, double hexRadius) {
      final path = Path();
      for (var index = 0; index < 6; index += 1) {
        final angle = (-pi / 6) + (pi / 3 * index);
        final point = center.translate(
          cos(angle) * hexRadius,
          sin(angle) * hexRadius,
        );
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      return path..close();
    }

    if (snapshot.pathCells.length > 1) {
      final path = Path();
      for (var index = 0; index < snapshot.pathCells.length; index += 1) {
        final point = cellCenter(snapshot.pathCells[index]);
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = radius * 0.74
          ..color = LightcorePalette.night.withValues(alpha: 0.72),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = radius * 0.25
          ..color = tint.withValues(alpha: 0.44),
      );
    }

    for (final cell in snapshot.cells) {
      final path = hexPath(cellCenter(cell), radius * 0.92);
      canvas.drawPath(
        path,
        Paint()
          ..color = cell.isPath
              ? LightcorePalette.night.withValues(alpha: 0.72)
              : LightcorePalette.panelRaised.withValues(alpha: 0.54),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = cell.isPath
              ? tint.withValues(alpha: 0.45)
              : LightcorePalette.stroke.withValues(alpha: 0.52),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HexTournamentPreviewPainter oldDelegate) {
    return oldDelegate.snapshot != snapshot || oldDelegate.tint != tint;
  }
}
