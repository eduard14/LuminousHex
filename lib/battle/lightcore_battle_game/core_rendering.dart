part of '../lightcore_battle_game.dart';

extension LightcoreBattleGameCoreRendering on LightcoreBattleGame {
  List<ProjectileType> get debugCoreQueueOrbitProjectileTypes =>
      const <ProjectileType>[];

  void _renderHexChargeIndicator(
    Canvas canvas,
    Offset center, {
    required Color color,
    required double radius,
    required double chargeProgress,
    required double popProgress,
  }) {
    final clampedCharge = chargeProgress.clamp(0, 1);
    final guideRadius = radius * 0.76;
    final chargeRadius = radius * (0.16 + (clampedCharge * 0.56));
    final popT = Curves.easeOut.transform(1 - popProgress.clamp(0, 1));

    canvas.drawPath(
      _hexPath(center, guideRadius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = color.withValues(alpha: 0.4),
    );

    if (clampedCharge > 0) {
      final chargeHex = _hexPath(center, chargeRadius);
      canvas.drawPath(
        chargeHex,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: 0.16 + (clampedCharge * 0.32)),
      );
      canvas.drawPath(
        chargeHex,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.5 + (clampedCharge * 0.28)),
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

  void _paintTowerTraitBadge(
    Canvas canvas,
    Offset center,
    OuterTowerState slot, {
    required Color tint,
    required double size,
    double opacity = 1,
    bool showLevelEdges = true,
    double? coreFacingAngle,
  }) {
    final level = slot.config != null ? slot.level : (slot.childCoreLevel ?? 1);
    _paintTraitBadge(
      canvas,
      center,
      level: level,
      maxLevel: LightcoreController.maxTowerLevel,
      projectileType: controller.towerProjectileType(slot),
      tint: tint,
      size: size,
      opacity: opacity,
      showLevelEdges: showLevelEdges,
      complete: controller.isTowerComplete(slot),
      coreFacingAngle: coreFacingAngle,
    );
  }

  void _paintCoreTowerTraitBadge(
    Canvas canvas,
    Offset center, {
    required Color tint,
    required double size,
    bool showLevelEdges = true,
    bool showLevelLabel = true,
  }) {
    _paintTraitBadge(
      canvas,
      center,
      level: controller.coreState.level,
      maxLevel: LightcoreController.maxTowerLevel,
      projectileType: _coreProjectileTypeForBadge,
      tint: tint,
      size: size,
      opacity: 1,
      showLevelEdges: showLevelEdges,
      complete: false,
      levelLabel: showLevelLabel ? 'L${controller.coreState.level}' : null,
    );
  }

  ProjectileType get _coreProjectileTypeForBadge {
    final loadout = controller.coreProjectileArsenal;
    if (loadout.isEmpty) {
      return controller.coreState.projectileType;
    }
    return loadout[controller.coreState.fireSequence % loadout.length];
  }

  void _paintTraitBadge(
    Canvas canvas,
    Offset center, {
    required int level,
    required int maxLevel,
    required ProjectileType projectileType,
    required Color tint,
    required double size,
    required double opacity,
    required bool showLevelEdges,
    required bool complete,
    String? levelLabel,
    double? coreFacingAngle,
  }) {
    final resolvedOpacity = opacity.clamp(0.0, 1.0).toDouble();
    final projectileColor = projectileType.affinity.color;
    final badgeRadius = size * 0.42;
    final vertices = _towerAlignedHexVertices(
      center,
      badgeRadius,
      coreFacingAngle: coreFacingAngle,
    );
    final path = Path()..moveTo(vertices.first.dx, vertices.first.dy);
    for (final vertex in vertices.skip(1)) {
      path.lineTo(vertex.dx, vertex.dy);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = projectileColor.withValues(alpha: 0.09 * resolvedOpacity),
    );

    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size * 0.035)
      ..strokeCap = StrokeCap.round
      ..color = LightcorePalette.stroke.withValues(
        alpha: 0.58 * resolvedOpacity,
      );
    for (var edge = 0; edge < 6; edge += 1) {
      _drawHexEdge(canvas, vertices, edge, backgroundPaint);
    }

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, size * 0.065)
      ..strokeCap = StrokeCap.round
      ..color = (complete ? LightcorePalette.success : tint).withValues(
        alpha: 0.96 * resolvedOpacity,
      );
    if (showLevelEdges) {
      for (final edge in _activeBadgeEdges(
        level,
        LightcoreController.maxTowerLevel,
      )) {
        _drawHexEdge(canvas, vertices, edge, activePaint);
      }
    }

    canvas.drawCircle(
      center,
      size * 0.24,
      Paint()
        ..color = projectileColor.withValues(alpha: 0.22 * resolvedOpacity),
    );
    canvas.drawCircle(
      center,
      size * 0.24,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, size * 0.025)
        ..color = projectileColor.withValues(alpha: 0.66 * resolvedOpacity),
    );
    _paintProjectileGlyph(
      canvas,
      center,
      projectileType,
      size: size * 0.28,
      color: projectileColor.withValues(alpha: resolvedOpacity),
    );

    if (complete) {
      final checkCenter = center.translate(size * 0.24, size * 0.24);
      canvas.drawCircle(
        checkCenter,
        size * 0.12,
        Paint()
          ..color = LightcorePalette.success.withValues(
            alpha: 0.92 * resolvedOpacity,
          ),
      );
      canvas.drawCircle(
        checkCenter,
        size * 0.12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, size * 0.018)
          ..color = LightcorePalette.night.withValues(
            alpha: 0.8 * resolvedOpacity,
          ),
      );
      _paintIconGlyph(
        canvas,
        checkCenter,
        Icons.check_rounded,
        size: size * 0.17,
        color: LightcorePalette.night.withValues(alpha: resolvedOpacity),
      );
    }

    final resolvedLevelLabel = levelLabel?.trim();
    if (resolvedLevelLabel != null && resolvedLevelLabel.isNotEmpty) {
      _paintTraitBadgeLevelLabel(
        canvas,
        center.translate(size * 0.25, size * 0.26),
        resolvedLevelLabel,
        tint: tint,
        size: size,
        opacity: resolvedOpacity,
      );
    }
  }

  void _paintProjectileGlyph(
    Canvas canvas,
    Offset center,
    ProjectileType projectileType, {
    required double size,
    required Color color,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, size * 0.12)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    final radius = size * 0.5;

    if (projectileType == ProjectileType.shieldHalo) {
      canvas.drawPath(_hexPath(center, radius * 0.72), paint);
      canvas.drawCircle(center, radius * 0.16, fill);
      return;
    }

    switch (projectileType.behaviorProfile) {
      case ProjectileBehaviorProfile.thread:
        canvas.drawLine(
          center.translate(-radius * 0.8, radius * 0.42),
          center.translate(radius * 0.8, -radius * 0.42),
          paint,
        );
        canvas.drawLine(
          center.translate(-radius * 0.72, -radius * 0.16),
          center.translate(radius * 0.36, -radius * 0.16),
          paint..strokeWidth = math.max(1.1, size * 0.08),
        );
      case ProjectileBehaviorProfile.pulse:
        final bolt = Path()
          ..moveTo(center.dx + radius * 0.16, center.dy - radius * 0.86)
          ..lineTo(center.dx - radius * 0.42, center.dy + radius * 0.08)
          ..lineTo(center.dx + radius * 0.1, center.dy + radius * 0.08)
          ..lineTo(center.dx - radius * 0.16, center.dy + radius * 0.86)
          ..lineTo(center.dx + radius * 0.5, center.dy - radius * 0.16)
          ..lineTo(center.dx, center.dy - radius * 0.16)
          ..close();
        canvas.drawPath(bolt, fill);
      case ProjectileBehaviorProfile.burst:
        for (var index = 0; index < 6; index += 1) {
          final angle = (math.pi * 2 / 6) * index;
          canvas.drawLine(
            center,
            center.translate(
              math.cos(angle) * radius,
              math.sin(angle) * radius,
            ),
            paint,
          );
        }
        canvas.drawCircle(center, radius * 0.18, fill);
      case ProjectileBehaviorProfile.chain:
        final left = center.translate(-radius * 0.58, radius * 0.2);
        final right = center.translate(radius * 0.58, -radius * 0.2);
        canvas.drawCircle(left, radius * 0.22, paint);
        canvas.drawCircle(right, radius * 0.22, paint);
        canvas.drawLine(left, right, paint);
      case ProjectileBehaviorProfile.split:
        final stem = center.translate(-radius * 0.72, radius * 0.52);
        final fork = center.translate(-radius * 0.04, -radius * 0.04);
        canvas.drawLine(stem, fork, paint);
        canvas.drawLine(
          fork,
          center.translate(radius * 0.72, -radius * 0.52),
          paint,
        );
        canvas.drawLine(
          fork,
          center.translate(radius * 0.74, radius * 0.34),
          paint,
        );
      case ProjectileBehaviorProfile.lance:
        canvas.drawLine(
          center.translate(-radius * 0.86, 0),
          center.translate(radius * 0.86, 0),
          paint,
        );
        canvas.drawLine(
          center.translate(0, -radius * 0.86),
          center.translate(0, radius * 0.86),
          paint,
        );
        canvas.drawCircle(center, radius * 0.44, paint);
      case ProjectileBehaviorProfile.explosion:
        canvas.drawCircle(center, radius * 0.26, fill);
        for (var index = 0; index < 5; index += 1) {
          final angle = (math.pi * 2 / 5) * index - math.pi / 2;
          canvas.drawCircle(
            center.translate(
              math.cos(angle) * radius * 0.66,
              math.sin(angle) * radius * 0.66,
            ),
            radius * 0.12,
            fill,
          );
        }
      case ProjectileBehaviorProfile.wave:
        for (var index = 0; index < 3; index += 1) {
          final arcRadius = radius * (0.32 + (index * 0.24));
          canvas.drawArc(
            Rect.fromCircle(
              center: center.translate(-radius * 0.18, 0),
              radius: arcRadius,
            ),
            -math.pi / 3,
            math.pi * 2 / 3,
            false,
            paint,
          );
        }
      case ProjectileBehaviorProfile.nova:
        canvas.drawCircle(center, radius * 0.2, fill);
        for (var index = 0; index < 6; index += 1) {
          final angle = (math.pi * 2 / 6) * index;
          canvas.drawCircle(
            center.translate(
              math.cos(angle) * radius * 0.72,
              math.sin(angle) * radius * 0.72,
            ),
            radius * 0.1,
            fill,
          );
        }
    }
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

  void _paintTraitBadgeLevelLabel(
    Canvas canvas,
    Offset center,
    String text, {
    required Color tint,
    required double size,
    required double opacity,
  }) {
    final fontSize = (size * 0.14).clamp(7.0, 10.0).toDouble();
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: LightcorePalette.mist.withValues(alpha: opacity),
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final horizontalPadding = size * 0.045;
    final verticalPadding = size * 0.02;
    final rect = Rect.fromCenter(
      center: center,
      width: math.max(size * 0.23, painter.width + (horizontalPadding * 2)),
      height: math.max(size * 0.17, painter.height + (verticalPadding * 2)),
    );
    final radius = Radius.circular(rect.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..color = LightcorePalette.panelRaised.withValues(
          alpha: 0.92 * opacity,
        ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, size * 0.018)
        ..color = tint.withValues(alpha: 0.72 * opacity),
    );
    painter.paint(
      canvas,
      Offset(
        rect.left + ((rect.width - painter.width) / 2),
        rect.top + ((rect.height - painter.height) / 2),
      ),
    );
  }

  List<Offset> _towerAlignedHexVertices(
    Offset center,
    double radius, {
    double? coreFacingAngle,
  }) {
    final rotation = coreFacingAngle == null
        ? math.pi / 6
        : coreFacingAngle - (math.pi / 6);
    return _polygonPoints(center, radius, 6, rotation);
  }

  void _drawHexEdge(
    Canvas canvas,
    List<Offset> vertices,
    int edge,
    Paint paint,
  ) {
    canvas.drawLine(vertices[edge], vertices[(edge + 1) % 6], paint);
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

  void _renderFoldedShell(
    Canvas canvas,
    Offset center, {
    required bool showSlots,
  }) {
    final shellHex = _hexPath(center, _coreRadius);
    // A face-sharing honeycomb fills the folded shell better than a loose orbit.
    final centerHexRadius = _coreRadius / 3;
    final childHexRadius = centerHexRadius;
    final foldedGridRadius = (centerHexRadius + childHexRadius) / 2;
    const foldedCoords = <(int, int)>[
      (1, 0),
      (1, -1),
      (0, -1),
      (-1, 0),
      (-1, 1),
      (0, 1),
    ];
    final shellGlowColor = _signatureColor(
      controller.coreState.affinity,
      controller.coreState.secondaryAffinity,
    );

    canvas.drawPath(
      shellHex,
      Paint()
        ..style = PaintingStyle.fill
        ..color = LightcorePalette.panelRaised.withValues(alpha: 0.96),
    );
    canvas.drawPath(
      shellHex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = LightcorePalette.layer2.withValues(alpha: 0.88),
    );
    canvas.drawPath(
      _hexPath(center, _coreRadius * 0.88),
      Paint()
        ..style = PaintingStyle.fill
        ..color = shellGlowColor.withValues(alpha: 0.08),
    );

    if (showSlots) {
      for (var index = 0; index < controller.slots.length; index++) {
        final slot = controller.slots[index];
        final coord = foldedCoords[index % foldedCoords.length];
        final childCenter = _axialToOffset(
          center,
          coord.$1,
          coord.$2,
          foldedGridRadius,
        );
        final activeTower = controller.isSlotActiveTower(slot);
        final projectShell = controller.isSlotLayerProject(slot);
        final unlocked = controller.isOuterSlotUnlocked(index);
        final childColor = activeTower
            ? slot.config != null
                  ? slot.config!.affinity.color
                  : slot.childAffinity != null
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
            : LightcorePalette.stroke.withValues(alpha: unlocked ? 0.62 : 0.32);

        canvas.drawPath(
          _hexPath(childCenter, childHexRadius),
          Paint()
            ..style = PaintingStyle.fill
            ..color = slot.isBuilt
                ? childColor.withValues(alpha: 0.22)
                : LightcorePalette.panel.withValues(
                    alpha: unlocked ? 0.9 : 0.44,
                  ),
        );
        canvas.drawPath(
          _hexPath(childCenter, childHexRadius),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = childColor.withValues(alpha: unlocked ? 1 : 0.58),
        );

        if (slot.isBuilt) {
          if (activeTower) {
            _renderHexChargeIndicator(
              canvas,
              childCenter,
              color: childColor,
              radius: childHexRadius,
              chargeProgress: slot.charge.clamp(0, 1).toDouble(),
              popProgress:
                  _slotHexChargePopRemaining[index] /
                  LightcoreBattleGame._hexChargePopDuration,
            );
          }
          if (projectShell) {
            final projectProgress =
                (slot.childBuiltCount / LightcoreController.slotCount)
                    .clamp(0, 1)
                    .toDouble();
            canvas.drawPath(
              _hexPath(
                childCenter,
                childHexRadius * (0.22 + projectProgress * 0.48),
              ),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.6
                ..color = childColor.withValues(alpha: 0.72),
            );
          }
        }
      }
    }

    final centerHex = _hexPath(center, centerHexRadius);
    canvas.drawPath(
      centerHex,
      Paint()
        ..style = PaintingStyle.fill
        ..color = shellGlowColor.withValues(alpha: 0.92),
    );
    canvas.drawPath(
      centerHex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = LightcorePalette.mist.withValues(alpha: 0.82),
    );
    _paintCoreTowerTraitBadge(
      canvas,
      center,
      tint: shellGlowColor,
      size: centerHexRadius * 1.56,
      showLevelEdges: false,
      showLevelLabel: false,
    );
  }

  void _renderCore(Canvas canvas) {
    final center = Offset(_center.x, _center.y);
    if (!controller.outerRingRevealed || !showArenaSlots) {
      _renderFoldedShell(canvas, center, showSlots: showFoldedShellSlots);
      if (showTutorialGuides && controller.tutorialHighlightsBattleCore) {
        _renderGuidePulse(
          canvas,
          center,
          radius: _coreRadius * 1.36,
          tint: LightcorePalette.quest,
          tapCueLabel: controller.tutorialBattleCoreGuideLabel,
        );
      }
      return;
    }

    final coreHex = _hexPath(center, _coreRadius);
    final coreColor = _signatureColor(
      controller.coreState.affinity,
      controller.coreState.secondaryAffinity,
    );

    canvas.drawPath(
      coreHex,
      Paint()
        ..style = PaintingStyle.fill
        ..color = coreColor.withValues(alpha: 0.2),
    );
    canvas.drawPath(
      coreHex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = coreColor.withValues(alpha: 0.92),
    );

    final coreCooldown = math.max(
      controller.coreState.fireCooldownRemaining,
      controller.coreState.packetCooldownRemaining,
    );
    final coreCooldownDuration = controller.coreShotCooldown;
    final coreReadyProgress = coreCooldownDuration <= 0
        ? 1.0
        : 1 - (coreCooldown / coreCooldownDuration).clamp(0.0, 1.0).toDouble();
    _renderHexChargeIndicator(
      canvas,
      center,
      color: coreColor,
      radius: _coreRadius,
      chargeProgress: coreReadyProgress,
      popProgress:
          _coreHexFirePopRemaining / LightcoreBattleGame._hexChargePopDuration,
    );

    _paintCoreTowerTraitBadge(
      canvas,
      center,
      tint: coreColor,
      size: _coreRadius * 1.14,
      showLevelLabel: false,
    );

    if (controller.layer2State.unlocked) {
      canvas.drawCircle(
        center,
        _coreRadius * 1.72,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = LightcorePalette.layer2.withValues(alpha: 0.7),
      );

      for (var index = 0; index < 6; index += 1) {
        final angle = (math.pi * 2 / 6) * index;
        final marker = Offset(
          center.dx + math.cos(angle) * (_coreRadius * 1.72),
          center.dy + math.sin(angle) * (_coreRadius * 1.72),
        );
        canvas.drawPath(
          _hexPath(marker, _coreRadius * 0.09),
          Paint()
            ..style = PaintingStyle.fill
            ..color = LightcorePalette.layer2.withValues(alpha: 0.5),
        );
      }
    }

    if (showTutorialGuides && controller.tutorialHighlightsBattleCore) {
      _renderGuidePulse(
        canvas,
        center,
        radius: _coreRadius * 1.34,
        tint: LightcorePalette.quest,
        tapCueLabel: controller.tutorialBattleCoreGuideLabel,
      );
    }
  }

  void _renderLevelUpRadiance(Canvas canvas) {
    if (!controller.levelUpRadianceActive) {
      return;
    }
    final rawProgress = controller.levelUpRadianceProgress
        .clamp(0.0, 1.0)
        .toDouble();
    final center = Offset(_center.x, _center.y);
    final coreColor = _signatureColor(
      controller.coreState.affinity,
      controller.coreState.secondaryAffinity,
    );
    final eased = Curves.easeOutCubic.transform(rawProgress);
    final fade =
        Curves.easeOutQuad.transform(1 - rawProgress) * _battleEffectAlphaScale;
    final maxRadius = _spawnRadiusVisual * 1.12;

    final flashRect = Rect.fromCircle(center: center, radius: maxRadius);
    if (!_lowPowerBattleEffects) {
      canvas.drawRect(
        flashRect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              LightcorePalette.mist.withValues(alpha: 0.22 * fade),
              coreColor.withValues(alpha: 0.16 * fade),
              Colors.transparent,
            ],
            stops: const [0, 0.34, 1],
          ).createShader(flashRect),
      );
    }

    final ringCount = _qualityScaledCount(4, balanced: 3, lowPower: 2);
    for (var index = 0; index < ringCount; index++) {
      final ringProgress = ((rawProgress * 1.22) - (index * 0.12))
          .clamp(0.0, 1.0)
          .toDouble();
      if (ringProgress <= 0) {
        continue;
      }
      final ringEase = Curves.easeOutCubic.transform(ringProgress);
      final ringRadius =
          (_coreRadius * (0.82 + (index * 0.2))) +
          ((maxRadius - _coreRadius) * ringEase);
      final ringAlpha =
          (1 - ringProgress) * fade * (0.72 - (index * 0.1)).clamp(0.32, 0.72);
      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _coreRadius * (0.09 - (index * 0.012))
          ..maskFilter = _lowPowerBattleEffects
              ? null
              : MaskFilter.blur(BlurStyle.normal, _coreRadius * 0.05)
          ..color = Color.lerp(
            coreColor,
            LightcorePalette.mist,
            0.42,
          )!.withValues(alpha: ringAlpha),
      );
    }

    final spokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.4, _coreRadius * 0.034)
      ..color = LightcorePalette.mist.withValues(alpha: 0.34 * fade);
    final spokeCount = _qualityScaledCount(18, balanced: 10, lowPower: 0);
    final spin = controller.elapsed * 1.8;
    for (var index = 0; index < spokeCount; index++) {
      final angle = ((math.pi * 2) / spokeCount * index) + spin;
      final phase = ((rawProgress * 1.38) - (index.isEven ? 0 : 0.08))
          .clamp(0.0, 1.0)
          .toDouble();
      final reach = _coreRadius + ((maxRadius * 0.96 - _coreRadius) * phase);
      final inner = _coreRadius * (0.62 + (0.16 * math.sin(spin + index)));
      canvas.drawLine(
        center.translate(math.cos(angle) * inner, math.sin(angle) * inner),
        center.translate(math.cos(angle) * reach, math.sin(angle) * reach),
        spokePaint..color = coreColor.withValues(alpha: 0.25 * fade),
      );
    }

    final hexPulse = _hexPath(center, _coreRadius * (1.16 + (eased * 0.32)));
    canvas.drawPath(
      hexPulse,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _coreRadius * 0.07
        ..color = LightcorePalette.mist.withValues(alpha: 0.66 * fade),
    );
    if (rawProgress < 0.78) {
      _paintBadge(
        canvas,
        center.translate(0, -_coreRadius * 1.65),
        'LV ${controller.lastLevelUpRadianceLevel}',
        color: LightcorePalette.mist,
        size: math.max(12, _coreRadius * 0.28),
      );
    }
  }
}
