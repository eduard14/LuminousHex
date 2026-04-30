part of '../tournament_screen.dart';

class _HexTournamentGame extends FlameGame {
  _HexTournamentGame({
    required this.run,
    required this.snapshotNotifier,
    required this.onCellTap,
    required this.onRunEnded,
  });

  final HexTournamentRunController run;
  final ValueNotifier<HexTournamentSnapshot> snapshotNotifier;
  final ValueChanged<String> onCellTap;
  final VoidCallback onRunEnded;

  bool _endDispatched = false;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  void update(double dt) {
    super.update(dt);
    run.tick(dt.clamp(0.0, 0.05).toDouble());
    final snapshot = run.snapshot;
    snapshotNotifier.value = snapshot;
    if (snapshot.running) {
      _endDispatched = false;
    }
    if (snapshot.defeated && !_endDispatched) {
      _endDispatched = true;
      onRunEnded();
    }
  }

  void handleTap(Offset localPosition) {
    final cell = _cellAt(localPosition, run.snapshot);
    if (cell != null) {
      onCellTap(cell.id);
    }
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
        ..strokeWidth = selected ? 3.0 : 1.2
        ..color = selected
            ? LightcorePalette.gilded
            : cell.isPath
            ? LightcorePalette.solar.withValues(alpha: 0.34)
            : LightcorePalette.stroke.withValues(alpha: 0.55),
    );
  }

  void _drawTower(Canvas canvas, HexTournamentTower tower) {
    final center = _cellCenterById(tower.cellId);
    if (center == null) {
      return;
    }
    final radius = _hexRadius * 0.46;
    final paint = Paint()..color = tower.affinity.color.withValues(alpha: 0.86);
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(
      center,
      radius + 3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = tower.affinity.color.withValues(alpha: 0.44),
    );
    if (tower.hasPayload) {
      canvas.drawCircle(
        center.translate(radius * 0.52, -radius * 0.46),
        radius * 0.25,
        Paint()..color = (tower.payloadType.affinity ?? tower.affinity).color,
      );
    }
    if (tower.hasImpactProjectile) {
      canvas.drawCircle(
        center.translate(-radius * 0.52, radius * 0.46),
        radius * 0.22,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = tower.impactProjectileType!.affinity.color,
      );
    }
    _drawText(
      canvas,
      tower.mergeStage == 0
          ? 'T'
          : tower.mergeStage == 1
          ? 'P'
          : '2',
      center,
      LightcorePalette.night,
      _hexRadius * 0.36,
      FontWeight.w900,
    );
  }

  void _drawEnemy(
    Canvas canvas,
    HexTournamentSnapshot snapshot,
    HexTournamentEnemy enemy,
  ) {
    final center = _pathPosition(snapshot, enemy.progress);
    final radius = _hexRadius * (enemy.tier >= 4 ? 0.36 : 0.30);
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = enemy.affinity.color.withValues(alpha: 0.92),
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
    final color = shot.secondary
        ? shot.projectileType.affinity.color
        : (shot.payloadType.affinity ?? shot.projectileType.affinity).color;
    final alpha = (1 - shot.progress).clamp(0.0, 1.0);
    canvas.drawLine(
      start,
      end,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = shot.secondary ? 2.4 : 3.4
        ..color = color.withValues(alpha: 0.72 * alpha),
    );
    canvas.drawCircle(
      Offset.lerp(start, end, shot.progress.clamp(0.0, 1.0))!,
      _hexRadius * (shot.secondary ? 0.11 : 0.15),
      Paint()..color = color.withValues(alpha: 0.88 * alpha),
    );
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
                            _hexGame.handleTap(event.localPosition);
                          }
                        },
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
      return Wrap(
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
          FilledButton.tonalIcon(
            onPressed: snapshot.canBuildSelected
                ? () {
                    _hexRun.placeTower(snapshot.selectedCellId!);
                    _refreshHexSnapshot();
                  }
                : null,
            icon: const Icon(Icons.add_circle_rounded),
            label: Text('Build (${snapshot.buildCost})'),
          ),
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
            _HeaderChip(label: 'Tower', value: tower.projectileType.label),
            _HeaderChip(label: 'Payload', value: tower.payloadType.label),
            _HeaderChip(
              label: 'Impact',
              value: tower.impactProjectileType?.label ?? 'None',
            ),
            _HeaderChip(
              label: 'Merge',
              value: '${snapshot.mergeCandidateCount}',
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
          onPressed: widget.busy || _runActive ? null : _startRun,
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
