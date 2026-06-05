part of '../lightcore_battle_game.dart';

extension LightcoreBattleGameArenaSlotRendering on LightcoreBattleGame {
  void _renderRelayImpactRing(Canvas canvas) {
    final center = Offset(_center.x, _center.y);
    final pulse = ((math.sin(controller.elapsed * 2.4) + 1) / 2);
    final ringRadius = math.max(
      _coreRadius * 1.42,
      _relayImpactRadiusVisual - (_slotRadius * 0.26),
    );
    final bandWidth = _slotRadius * 0.3;
    final ringColor = LightcorePalette.warning;

    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bandWidth
        ..color = ringColor.withValues(alpha: 0.05 + (pulse * 0.04)),
    );
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = ringColor.withValues(alpha: 0.62),
    );
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = LightcorePalette.mist.withValues(alpha: 0.26),
    );

    final selectedSlotIndex = controller.selectedSlotIndex;
    for (var index = 0; index < _slotPositions.length; index++) {
      final slotCenter = Offset(
        _slotPositions[index].x,
        _slotPositions[index].y,
      );
      final angle = math.atan2(
        slotCenter.dy - center.dy,
        slotCenter.dx - center.dx,
      );
      final selected = selectedSlotIndex == index;
      final markerColor = selected ? LightcorePalette.mist : ringColor;
      final markerStroke = selected ? 3.4 : 2.2;
      final markerCenter = Offset(
        center.dx + (math.cos(angle) * (ringRadius - (_slotRadius * 0.28))),
        center.dy + (math.sin(angle) * (ringRadius - (_slotRadius * 0.28))),
      );
      final tangent = Offset(-math.sin(angle), math.cos(angle));
      final markerHalfLength = _slotRadius * (selected ? 0.22 : 0.17);
      final laneStart = Offset(
        markerCenter.dx - (tangent.dx * markerHalfLength),
        markerCenter.dy - (tangent.dy * markerHalfLength),
      );
      final laneEnd = Offset(
        markerCenter.dx + (tangent.dx * markerHalfLength),
        markerCenter.dy + (tangent.dy * markerHalfLength),
      );

      canvas.drawLine(
        laneStart,
        laneEnd,
        Paint()
          ..strokeWidth = markerStroke
          ..strokeCap = StrokeCap.round
          ..color = markerColor.withValues(alpha: selected ? 0.88 : 0.58),
      );
    }
  }

  void _renderCoreRange(Canvas canvas) {
    if (controller.selectedSlotIndex != null ||
        controller.towerRangePreviewSlotIndex != null) {
      return;
    }

    final coreColor = _signatureColor(
      controller.coreState.affinity,
      controller.coreState.secondaryAffinity,
    );
    final rangeVisual = _modelRadiusToVisual(
      controller.coreEffectiveRange.clamp(
        controller.relayImpactRadius + 8,
        controller.spawnCeilingRadius - 12,
      ),
    );
    final center = Offset(_center.x, _center.y);
    final pulse = ((math.sin(controller.elapsed * 2.1) + 1) / 2);

    canvas.drawCircle(
      center,
      rangeVisual,
      Paint()
        ..style = PaintingStyle.fill
        ..color = coreColor.withValues(alpha: 0.04),
    );
    canvas.drawCircle(
      center,
      rangeVisual,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = coreColor.withValues(alpha: 0.34 + (pulse * 0.12)),
    );
  }

  void _renderSelectedTowerRange(Canvas canvas) {
    final slotIndex =
        controller.towerRangePreviewSlotIndex ?? controller.selectedSlotIndex;
    if (slotIndex == null) {
      return;
    }
    final tower = controller.slots[slotIndex];
    if (!controller.isSlotActiveTower(tower)) {
      return;
    }

    final towerColor = tower.config != null
        ? tower.config!.affinity.color
        : tower.childAffinity != null
        ? _signatureColor(tower.childAffinity!, tower.childSecondaryAffinity)
        : LightcorePalette.layer2;
    final previewRadius = controller.towerUsesPersistentShieldRing(tower)
        ? controller.towerShieldRingRadius(tower)
        : controller.towerEffectiveRange(tower);
    final rangeVisual = _modelRadiusToVisual(
      previewRadius.clamp(
        controller.relayImpactRadius + 8,
        controller.spawnCeilingRadius - 12,
      ),
    );
    final arenaCenter = Offset(_center.x, _center.y);
    final towerCenter = Offset(
      _slotPositions[slotIndex].x,
      _slotPositions[slotIndex].y,
    );
    final angle = math.atan2(
      towerCenter.dy - arenaCenter.dy,
      towerCenter.dx - arenaCenter.dx,
    );
    final tetherEnd = Offset(
      arenaCenter.dx + (math.cos(angle) * rangeVisual),
      arenaCenter.dy + (math.sin(angle) * rangeVisual),
    );

    canvas.drawCircle(
      arenaCenter,
      rangeVisual,
      Paint()
        ..style = PaintingStyle.fill
        ..color = towerColor.withValues(alpha: 0.06),
    );
    canvas.drawCircle(
      arenaCenter,
      rangeVisual,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = towerColor.withValues(alpha: 0.52),
    );
    canvas.drawLine(
      towerCenter,
      tetherEnd,
      Paint()
        ..strokeWidth = 2.2
        ..color = towerColor.withValues(alpha: 0.34),
    );
  }

  void _renderPersistentShieldRings(Canvas canvas) {
    final arenaCenter = Offset(_center.x, _center.y);
    for (final slot in controller.slots) {
      if (!controller.towerUsesPersistentShieldRing(slot)) {
        continue;
      }
      final color = slot.config?.affinity.color ?? LightcorePalette.verdant;
      final ringRadius = _modelRadiusToVisual(
        controller
            .towerShieldRingRadius(slot)
            .clamp(
              controller.relayImpactRadius + 8,
              controller.spawnCeilingRadius - 12,
            ),
      );
      final phase = controller.elapsed * 2.8 + (slot.slotIndex * 0.72);
      final pulse = 0.5 + (math.sin(phase) * 0.5);
      final shimmerRadius = ringRadius + (_coreRadius * 0.035 * pulse);
      final ringRect = Rect.fromCircle(
        center: arenaCenter,
        radius: shimmerRadius,
      );

      canvas.drawCircle(
        arenaCenter,
        shimmerRadius,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(5.0, _coreRadius * 0.12)
          ..color = color.withValues(alpha: 0.1),
      );
      canvas.drawCircle(
        arenaCenter,
        ringRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2.0, _coreRadius * 0.055)
          ..color = color.withValues(alpha: 0.28 + (pulse * 0.1)),
      );
      canvas.drawCircle(
        arenaCenter,
        ringRadius - (_coreRadius * 0.1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = LightcorePalette.layer2.withValues(alpha: 0.12),
      );

      final facetPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, _coreRadius * 0.035)
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.34 + (pulse * 0.1));
      for (var index = 0; index < 6; index++) {
        final startAngle =
            (slot.slotIndex * math.pi / 15) +
            (index * math.pi / 3) +
            (pulse * math.pi / 26);
        canvas.drawArc(ringRect, startAngle, math.pi / 5.6, false, facetPaint);
      }
    }
  }

  void _renderLinks(Canvas canvas) {
    for (var index = 0; index < controller.slots.length; index++) {
      final slot = controller.slots[index];
      final activeTower = controller.isSlotActiveTower(slot);
      final projectShell = controller.isSlotLayerProject(slot);
      final unlocked = controller.isOuterSlotUnlocked(index);
      final start = Offset(_slotPositions[index].x, _slotPositions[index].y);
      final end = Offset(_center.x, _center.y);
      final color = activeTower
          ? (slot.config != null
                    ? slot.config!.affinity.color
                    : slot.childAffinity != null
                    ? _signatureColor(
                        slot.childAffinity!,
                        slot.childSecondaryAffinity,
                      )
                    : LightcorePalette.layer2)
                .withValues(alpha: 0.28)
          : projectShell
          ? _signatureColor(
              slot.childAffinity ?? PrototypeAffinity.solar,
              slot.childSecondaryAffinity,
            ).withValues(alpha: 0.16)
          : LightcorePalette.stroke.withValues(alpha: unlocked ? 0.1 : 0.04);
      final width = controller.selectedSlotIndex == index ? 3.2 : 2.0;
      canvas.drawPath(
        _curvedLinkPath(start, end, bend: slot.isChildLayerNode ? 0.2 : 0.12),
        Paint()
          ..color = color
          ..strokeWidth = width
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _renderFabricationLattice(
    Canvas canvas,
    Offset center, {
    required Color color,
    required double radius,
    required double progress,
    required double phase,
  }) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final eased = Curves.easeOutCubic.transform(clamped);
    final spin = phase * 1.55;
    final pulse = 0.5 + (math.sin(phase * math.pi * 2.2) * 0.5);
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      center,
      radius * (0.22 + (eased * 0.44)),
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.38 + (pulse * 0.08)),
            color.withValues(alpha: 0.18),
            Colors.transparent,
          ],
          stops: const [0, 0.58, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.86)),
    );

    final ringRadii = <double>[
      radius * (0.13 + (eased * 0.03)),
      radius * (0.25 + (eased * 0.08)),
      radius * (0.38 + (eased * 0.14)),
      radius * (0.51 + (eased * 0.2)),
      radius * (0.64 + (eased * 0.25)),
    ];
    final ringPoints = <List<Offset>>[];

    for (var ring = 0; ring < ringRadii.length; ring++) {
      final reveal = ((clamped - (ring * 0.1)) / 0.44)
          .clamp(0.0, 1.0)
          .toDouble();
      if (reveal <= 0) {
        ringPoints.add(const <Offset>[]);
        continue;
      }
      final sides = ring == 0 ? 3 : 6;
      final rotation =
          math.pi / 6 +
          (ring * math.pi / 6) +
          (spin * (ring.isEven ? 0.34 : -0.26));
      final ringRadius = ringRadii[ring];
      final points = _polygonPoints(center, ringRadius, 6, rotation);
      ringPoints.add(points);

      if (ring > 0) {
        final fillAlpha = (0.12 + (reveal * 0.14)) * (1 - (ring * 0.08));
        canvas.drawPath(
          _polygonPath(center, ringRadius * reveal, sides, rotation),
          Paint()
            ..style = PaintingStyle.fill
            ..color = color.withValues(alpha: fillAlpha.clamp(0.08, 0.24)),
        );
      }
      canvas.drawPath(
        _polygonPath(center, ringRadius, sides, rotation),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1 + (ring * 0.36)
          ..maskFilter = ring == ringRadii.length - 1
              ? const MaskFilter.blur(BlurStyle.normal, 5)
              : null
          ..color = color.withValues(alpha: 0.32 + (reveal * 0.34)),
      );
      _drawPolygonPerimeterProgress(
        canvas,
        center: center,
        radius: ringRadius,
        sides: sides,
        rotation: rotation,
        progress: reveal,
        paint: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 + (ring * 0.42)
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.72 + (reveal * 0.28)),
      );
    }

    for (var ring = 0; ring < ringPoints.length - 1; ring++) {
      if (ringPoints[ring].isEmpty || ringPoints[ring + 1].isEmpty) {
        continue;
      }
      for (var index = 0; index < 6; index++) {
        final reveal = ((clamped * 1.32) - (ring * 0.14) - (index * 0.025))
            .clamp(0.0, 1.0)
            .toDouble();
        if (reveal <= 0) {
          continue;
        }
        final start = ringPoints[ring][index % 6];
        final end = ringPoints[ring + 1][(index + (ring.isEven ? 0 : 1)) % 6];
        final partial = Offset.lerp(
          start,
          end,
          Curves.easeOutCubic.transform(reveal),
        )!;
        canvas.drawLine(
          start,
          partial,
          basePaint
            ..strokeWidth = 0.9 + (ring * 0.22)
            ..color = color.withValues(alpha: 0.34 + (reveal * 0.32)),
        );
      }
    }

    final coreRadius = radius * (0.08 + (eased * 0.16));
    for (var index = 0; index < 6; index++) {
      final angle = spin + (((math.pi * 2) / 6) * index);
      final inner = Offset(
        center.dx + math.cos(angle) * coreRadius,
        center.dy + math.sin(angle) * coreRadius,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * radius * (0.44 + (eased * 0.36)),
        center.dy + math.sin(angle) * radius * (0.44 + (eased * 0.36)),
      );
      final rayProgress = ((clamped * 1.24) - (index * 0.04))
          .clamp(0.0, 1.0)
          .toDouble();
      final rayEnd = Offset.lerp(
        inner,
        outer,
        Curves.easeOutCubic.transform(rayProgress),
      )!;
      canvas.drawLine(
        inner,
        rayEnd,
        basePaint
          ..strokeWidth = 1.1
          ..color = color.withValues(alpha: 0.34 + (rayProgress * 0.32)),
      );
    }

    final edgeRadius = radius * (0.44 + (eased * 0.32));
    for (var edge = 0; edge < 6; edge++) {
      final edgeProgress = ((clamped * 1.18) - (edge * 0.045))
          .clamp(0.0, 1.0)
          .toDouble();
      if (edgeProgress <= 0) {
        continue;
      }
      final vertices = _polygonPoints(
        center,
        edgeRadius,
        6,
        math.pi / 6 + (spin * 0.08),
      );
      final start = vertices[edge];
      final end = vertices[(edge + 1) % vertices.length];
      canvas.drawLine(
        start,
        Offset.lerp(start, end, edgeProgress)!,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.6, radius * 0.038)
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.48 + (pulse * 0.18)),
      );
    }

    canvas.drawPath(
      _hexPath(center, radius * 1.08),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = color.withValues(alpha: 0.38),
    );
    _drawPolygonPerimeterProgress(
      canvas,
      center: center,
      radius: radius * 1.08,
      sides: 6,
      rotation: math.pi / 6,
      progress: clamped,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.8
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 1),
    );
  }

  void _renderFabricationCoreGlyph(
    Canvas canvas,
    Offset center, {
    required Color color,
    required double radius,
    required double progress,
    required double phase,
  }) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final constructionProgress = Curves.easeOutCubic.transform(clamped);
    final coreRadius = radius * (0.08 + (constructionProgress * 0.18));
    final coreRotation = -phase * 1.85;

    canvas.drawPath(
      _polygonPath(center, coreRadius * 1.65, 3, coreRotation),
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.24 + (constructionProgress * 0.24)),
    );
    canvas.drawPath(
      _hexPath(center, coreRadius),
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.74 + (constructionProgress * 0.26)),
    );
    canvas.drawPath(
      _hexPath(center, coreRadius * 1.34),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.98),
    );

    final edgeVertices = _polygonPoints(center, coreRadius * 1.72, 6, 0);
    for (var edge = 0; edge < edgeVertices.length; edge++) {
      canvas.drawLine(
        edgeVertices[edge],
        edgeVertices[(edge + 1) % edgeVertices.length],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, radius * 0.018)
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(
            alpha: (0.24 + (constructionProgress * 0.34)),
          ),
      );
    }
  }

  void _renderSlotBurst(
    Canvas canvas,
    Offset center, {
    required Color color,
    required double radius,
    required double progress,
    double intensity = 1.0,
  }) {
    final clamped = progress.clamp(0.0, 1.0);
    final fade = (1 - Curves.easeOutCubic.transform(clamped)) * intensity;
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

    for (var index = 0; index < 6; index++) {
      final angle = ((math.pi * 2) / 6) * index;
      final start = Offset(
        center.dx + math.cos(angle) * (radius * 0.42),
        center.dy + math.sin(angle) * (radius * 0.42),
      );
      final end = Offset(
        center.dx + math.cos(angle) * burstRadius,
        center.dy + math.sin(angle) * burstRadius,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.48 * fade),
      );
    }
  }

  void _renderSlots(Canvas canvas) {
    for (var index = 0; index < controller.slots.length; index++) {
      final slot = controller.slots[index];
      final activeTower = controller.isSlotActiveTower(slot);
      final projectShell = controller.isSlotLayerProject(slot);
      final unlocked = controller.isOuterSlotUnlocked(index);
      final center = Offset(_slotPositions[index].x, _slotPositions[index].y);
      final selected = controller.selectedSlotIndex == index;
      final slotColor = slot.config != null
          ? slot.config!.affinity.color
          : activeTower
          ? slot.childAffinity != null
                ? _signatureColor(
                    slot.childAffinity!,
                    slot.childSecondaryAffinity,
                  )
                : LightcorePalette.layer2
          : projectShell
          ? _signatureColor(
              slot.childAffinity ?? PrototypeAffinity.solar,
              slot.childSecondaryAffinity,
            )
          : unlocked
          ? LightcorePalette.panelRaised
          : LightcorePalette.stroke.withValues(alpha: 0.32);

      _renderSlotHudFrame(
        canvas,
        center,
        color: slotColor,
        selected: selected,
        unlocked: unlocked,
        activeTower: activeTower,
        projectShell: projectShell,
      );

      if (slot.isBuilt) {
        final projectProgress =
            (slot.childBuiltCount / LightcoreController.slotCount).clamp(0, 1);
        final chargeProgress = slot.charge.clamp(0, 1);
        final persistentShield = controller.towerUsesPersistentShieldRing(slot);
        if (slot.isFabricating) {
          _renderFabricationLattice(
            canvas,
            center,
            color: slotColor,
            radius: _slotRadius,
            progress: slot.fabricationProgress,
            phase: controller.elapsed,
          );
        } else if (_slotBuildBurstRemaining[index] > 0) {
          _renderSlotBurst(
            canvas,
            center,
            color: slotColor,
            radius: _slotRadius,
            progress:
                1 -
                (_slotBuildBurstRemaining[index] /
                        LightcoreBattleGame._slotBuildBurstDuration)
                    .clamp(0.0, 1.0),
          );
        } else if (projectShell) {
          _renderFabricationLattice(
            canvas,
            center,
            color: slotColor,
            radius: _slotRadius,
            progress: projectProgress.toDouble(),
            phase: controller.elapsed,
          );
          if (_slotFuseBurstRemaining[index] > 0) {
            _renderSlotBurst(
              canvas,
              center,
              color: slotColor,
              radius: _slotRadius,
              progress:
                  1 -
                  (_slotFuseBurstRemaining[index] /
                          LightcoreBattleGame._slotFuseBurstDuration)
                      .clamp(0.0, 1.0),
              intensity: 0.72,
            );
          }
        }
        if (activeTower && persistentShield) {
          _renderPersistentShieldTowerPulse(
            canvas,
            center,
            color: slotColor,
            radius: _slotRadius,
          );
        } else if (activeTower) {
          _renderHexChargeIndicator(
            canvas,
            center,
            color: slotColor,
            radius: _slotRadius,
            chargeProgress: chargeProgress.toDouble(),
            popProgress:
                _slotHexChargePopRemaining[index] /
                LightcoreBattleGame._hexChargePopDuration,
          );
        }
        if (projectShell) {
          final innerHex = _hexPath(
            center,
            _slotRadius * (0.24 + (projectProgress * 0.52)),
          );
          canvas.drawPath(
            innerHex,
            Paint()
              ..style = PaintingStyle.fill
              ..color = slotColor.withValues(
                alpha: 0.16 + (projectProgress * 0.34),
              ),
          );
          canvas.drawPath(
            innerHex,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4
              ..color = slotColor.withValues(alpha: 0.92),
          );
        }
        if (slot.isFabricating) {
          _renderFabricationCoreGlyph(
            canvas,
            center,
            color: slotColor,
            radius: _slotRadius,
            progress: slot.fabricationProgress,
            phase: controller.elapsed,
          );
        } else if (projectShell) {
          _renderFabricationCoreGlyph(
            canvas,
            center,
            color: slotColor,
            radius: _slotRadius,
            progress: projectProgress.toDouble(),
            phase: controller.elapsed,
          );
        } else {
          final coreGlyph = _hexPath(center, _slotRadius * 0.21);
          canvas.drawPath(coreGlyph, Paint()..color = slotColor);
        }

        if (activeTower && slot.disruption > 0) {
          final disruption = slot.disruption.clamp(0, 1);
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: _slotRadius * 1.16),
            -math.pi / 2,
            math.pi * 2 * disruption,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..strokeCap = StrokeCap.round
              ..color = LightcorePalette.warning.withValues(
                alpha: 0.65 + (disruption * 0.25),
              ),
          );
          canvas.drawCircle(
            center,
            _slotRadius * (0.88 + (disruption * 0.18)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = LightcorePalette.warning.withValues(
                alpha: 0.24 + (disruption * 0.2),
              ),
          );
        }

        if (slot.isChildLayerNode) {
          canvas.drawCircle(
            center.translate(_slotRadius * 0.48, _slotRadius * 0.48),
            _slotRadius * 0.14,
            Paint()..color = LightcorePalette.solar,
          );
        }
      }
    }
  }

  void _renderSlotHudFrame(
    Canvas canvas,
    Offset center, {
    required Color color,
    required bool selected,
    required bool unlocked,
    required bool activeTower,
    required bool projectShell,
  }) {
    final pulse = 0.5 + (math.sin(controller.elapsed * 2.6) * 0.5);
    final baseAlpha = !unlocked
        ? 0.18
        : activeTower || projectShell
        ? 0.46
        : 0.34;
    final frameColor = selected ? LightcorePalette.layer2 : color;
    final outerRadius = _slotRadius * 0.98;
    final innerRadius = _slotRadius * 0.78;
    final hex = _hexPath(center, outerRadius);

    if (selected && _battleGlowAlphaScale > 0) {
      canvas.drawPath(
        _hexPath(center, outerRadius * 1.04),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(4, _slotRadius * 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
          ..color = LightcorePalette.layer2.withValues(
            alpha: 0.28 * _battleGlowAlphaScale,
          ),
      );
    }

    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.fill
        ..color = (activeTower || projectShell ? color : LightcorePalette.panel)
            .withValues(alpha: unlocked ? 0.07 : 0.025),
    );
    canvas.drawPath(
      _hexPath(center, innerRadius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 1.8 : 1.05
        ..color = LightcorePalette.mist.withValues(
          alpha: selected ? 0.34 : baseAlpha * 0.28,
        ),
    );
    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.6 : 1.45
        ..color = frameColor.withValues(
          alpha: selected ? 0.9 : baseAlpha + (pulse * 0.08),
        ),
    );

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.2 : 1.35
      ..strokeCap = StrokeCap.round
      ..color = frameColor.withValues(
        alpha: selected ? 0.88 : (baseAlpha * 0.72),
      );
    final points = _polygonPoints(center, outerRadius, 6, math.pi / 6);
    for (var index = 0; index < points.length; index++) {
      final previous = points[(index - 1 + points.length) % points.length];
      final current = points[index];
      final next = points[(index + 1) % points.length];
      final start = Offset.lerp(current, previous, 0.2)!;
      final end = Offset.lerp(current, next, 0.2)!;
      canvas.drawLine(start, end, tickPaint);
    }

    if (!unlocked) {
      _drawPolygonPerimeterProgress(
        canvas,
        center: center,
        radius: outerRadius * 0.86,
        sides: 6,
        rotation: math.pi / 6,
        progress: 0.5,
        paint: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.15
          ..strokeCap = StrokeCap.round
          ..color = LightcorePalette.stroke.withValues(alpha: 0.18),
      );
    }
  }

  void _renderPersistentShieldTowerPulse(
    Canvas canvas,
    Offset center, {
    required Color color,
    required double radius,
  }) {
    final phase = controller.elapsed * 4.2;
    final pulse = 0.5 + (math.sin(phase) * 0.5);
    final bloomRadius = radius * (0.48 + (pulse * 0.26));
    canvas.drawCircle(
      center,
      radius * (0.66 + (pulse * 0.2)),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(3.0, radius * 0.11)
        ..color = color.withValues(alpha: 0.18 + (pulse * 0.12)),
    );
    canvas.drawPath(
      _hexPath(center, bloomRadius),
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.12 + (pulse * 0.16)),
    );
    canvas.drawPath(
      _hexPath(center, radius * 0.72),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = color.withValues(alpha: 0.52 + (pulse * 0.24)),
    );
    canvas.drawCircle(
      center,
      radius * (0.1 + (pulse * 0.04)),
      Paint()..color = LightcorePalette.mist.withValues(alpha: 0.72),
    );
  }
}
