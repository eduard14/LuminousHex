part of '../lightcore_battle_game.dart';

extension _LightcoreBattleGameImpactRendering on LightcoreBattleGame {
  void _renderImpacts(Canvas canvas) {
    for (final impact in controller.impacts) {
      final position = _battlePosition(
        angle: impact.angle,
        radius: impact.radius,
      );
      final impactColor = _signatureColor(
        impact.affinity,
        impact.secondaryAffinity,
      );
      final baseColor = impact.towerHit
          ? LightcorePalette.warning
          : impact.lethal
          ? Color.lerp(LightcorePalette.layer2, impactColor, 0.24)!
          : impactColor;
      final radiusScale = impact.projectileType == ProjectileType.coreBomb
          ? 0.46
          : switch (impact.projectileType.behaviorProfile) {
              ProjectileBehaviorProfile.thread => 0.18,
              ProjectileBehaviorProfile.pulse => 0.16,
              ProjectileBehaviorProfile.burst => 0.2,
              ProjectileBehaviorProfile.chain => 0.2,
              ProjectileBehaviorProfile.split => 0.22,
              ProjectileBehaviorProfile.lance => 0.22,
              ProjectileBehaviorProfile.explosion => 0.4,
              ProjectileBehaviorProfile.wave => 0.28,
              ProjectileBehaviorProfile.nova => 0.38,
            };
      final radius =
          (_coreRadius * radiusScale) + (impact.progress * _coreRadius * 0.58);
      final fade = (1 - impact.progress).clamp(0.0, 1.0);
      final fieldRadius = impact.hasLingeringField
          ? (_modelRadiusToVisual(impact.radius + impact.fieldRadius) -
                    _modelRadiusToVisual(impact.radius))
                .clamp(_coreRadius * 0.3, _coreRadius * 1.15)
          : 0.0;
      final chainArcImpact = impact.projectileType == ProjectileType.chainArc;

      if (impact.hasChainSource) {
        _renderChainLightningLink(
          canvas,
          impact: impact,
          start: _battlePosition(
            angle: impact.chainSourceAngle!,
            radius: impact.chainSourceRadius!,
          ),
          end: position,
          color: baseColor,
          fade: fade,
        );
      }

      if (impact.hasLingeringField) {
        _drawLingeringField(
          canvas,
          position,
          baseColor,
          fieldRadius,
          fade,
          seed:
              (controller.elapsed * 2.6) +
              (impact.id.hashCode * 0.0019) +
              impact.progress,
        );
      }

      if (chainArcImpact) {
        _renderChainArcImpact(
          canvas,
          impact: impact,
          position: position,
          baseColor: baseColor,
          radius: radius,
          fade: fade,
        );
        if (impact.lethal) {
          final defeatedAffinity =
              impact.defeatedEnemyAffinity ?? impact.affinity;
          final deathRadius = _enemyDeathBaseRadius(impact);
          _renderEnemyRewardDrops(
            canvas,
            impact: impact,
            position: position,
            accentColor: defeatedAffinity.color,
            radius: deathRadius,
          );
        }
        continue;
      }

      if (impact.lethal) {
        final defeatedAffinity =
            impact.defeatedEnemyAffinity ?? impact.affinity;
        final defeatedColor = defeatedAffinity.color;
        final defeatedShellColor = defeatedAffinity == PrototypeAffinity.neutral
            ? LightcorePalette.layer2
            : Color.lerp(LightcorePalette.layer2, defeatedColor, 0.38)!;
        final deathRadius = _enemyDeathBaseRadius(impact);
        _renderEnemyDestroyedImpact(
          canvas,
          impact: impact,
          position: position,
          shellColor: defeatedShellColor,
          accentColor: defeatedColor,
          radius: deathRadius,
          fade: fade,
        );
        _renderEnemyRewardDrops(
          canvas,
          impact: impact,
          position: position,
          accentColor: defeatedColor,
          radius: deathRadius,
        );
        continue;
      }

      canvas.drawCircle(
        position,
        radius * 1.12,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  baseColor.withValues(alpha: 0.18 * fade),
                  Colors.transparent,
                ],
              ).createShader(
                Rect.fromCircle(center: position, radius: radius * 1.12),
              ),
      );
      canvas.drawCircle(
        position,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = impact.towerHit ? 5 : 3
          ..color = baseColor.withValues(alpha: fade),
      );
      canvas.drawCircle(
        position,
        radius * 0.52,
        Paint()..color = baseColor.withValues(alpha: 0.12 * fade),
      );

      if (impact.projectileType.behaviorProfile ==
          ProjectileBehaviorProfile.explosion) {
        canvas.drawCircle(
          position,
          radius * 1.36,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2
            ..color = LightcorePalette.flare.withValues(alpha: 0.44 * fade),
        );
        for (var index = 0; index < 6; index++) {
          final angle =
              ((math.pi * 2) / 6) * index +
              (impact.id.hashCode * 0.0007) +
              (impact.progress * 0.4);
          final inner = position.translate(
            math.cos(angle) * (radius * 0.38),
            math.sin(angle) * (radius * 0.38),
          );
          final outer = position.translate(
            math.cos(angle) * (radius * 1.18),
            math.sin(angle) * (radius * 1.18),
          );
          _drawGlowLine(
            canvas,
            inner,
            outer,
            baseColor,
            width: 1.4,
            alpha: 0.22 * fade,
          );
        }
      }

      if (impact.critical) {
        canvas.drawPath(
          _hexPath(position, radius * 0.92),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = LightcorePalette.solar.withValues(
              alpha: 0.92 * (1 - impact.progress),
            ),
        );
      }

      switch (impact.payloadType.effectProfile) {
        case PayloadEffectProfile.none:
          break;
        case PayloadEffectProfile.burn:
          for (var index = 0; index < 3; index++) {
            final angle =
                ((math.pi * 2) / 3) * index - (math.pi / 2) + (fade * 0.3);
            final emberCenter = Offset(
              position.dx + math.cos(angle) * (radius * 0.42),
              position.dy + math.sin(angle) * (radius * 0.42),
            );
            _drawEnergyOrb(
              canvas,
              emberCenter,
              LightcorePalette.ember,
              radius * (0.16 + (index * 0.02)),
              alpha: 0.72 * fade,
            );
          }
          canvas.drawCircle(
            position,
            radius * 1.12,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = LightcorePalette.flare.withValues(alpha: 0.58 * fade),
          );
        case PayloadEffectProfile.freeze:
          canvas.drawPath(
            _hexPath(position, radius * 0.7),
            Paint()
              ..style = PaintingStyle.fill
              ..color = LightcorePalette.aether.withValues(alpha: 0.12 * fade),
          );
          canvas.drawCircle(
            position,
            radius * 0.72,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = LightcorePalette.aether.withValues(alpha: 0.72 * fade),
          );
        case PayloadEffectProfile.shock:
          _drawEnergyBolt(
            canvas,
            position.translate(-radius * 0.76, -radius * 0.16),
            position.translate(radius * 0.7, radius * 0.2),
            LightcorePalette.aether,
            width: 2.6,
            amplitude: radius * 0.26,
            seed:
                (controller.elapsed * 18.0) +
                (impact.id.hashCode * 0.0023) +
                impact.progress,
            alpha: fade,
          );
          _drawEnergyBolt(
            canvas,
            position.translate(-radius * 0.38, radius * 0.66),
            position.translate(radius * 0.36, -radius * 0.62),
            LightcorePalette.layer2,
            width: 1.8,
            amplitude: radius * 0.16,
            seed:
                (controller.elapsed * 20.0) +
                (impact.id.hashCode * 0.0011) +
                impact.progress,
            alpha: 0.68 * fade,
          );
        case PayloadEffectProfile.knockback:
          canvas.drawArc(
            Rect.fromCircle(center: position, radius: radius * 1.2),
            -math.pi / 5,
            math.pi / 1.8,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = LightcorePalette.solar.withValues(alpha: 0.72 * fade),
          );
          canvas.drawArc(
            Rect.fromCircle(center: position, radius: radius * 0.92),
            -math.pi / 4,
            math.pi / 1.5,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6
              ..color = LightcorePalette.layer2.withValues(alpha: 0.54 * fade),
          );
        case PayloadEffectProfile.bounty:
          canvas.drawPath(
            _hexPath(position, radius * 0.84),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = LightcorePalette.solar.withValues(alpha: 0.82 * fade),
          );
          _drawEnergyOrb(
            canvas,
            position,
            LightcorePalette.flare,
            radius * 0.3,
            alpha: 0.72 * fade,
          );
      }
    }
  }

  void _renderChainArcImpact(
    Canvas canvas, {
    required ImpactState impact,
    required Offset position,
    required Color baseColor,
    required double radius,
    required double fade,
  }) {
    final zapColor = Color.lerp(baseColor, LightcorePalette.aether, 0.42)!;
    _drawEnergyBolt(
      canvas,
      position.translate(-radius * 0.92, -radius * 0.14),
      position.translate(radius * 0.86, radius * 0.18),
      zapColor,
      width: 2.2,
      amplitude: radius * 0.18,
      seed:
          (controller.elapsed * 18.0) +
          (impact.id.hashCode * 0.0021) +
          impact.progress,
      alpha: 0.9 * fade,
    );
    _drawEnergyBolt(
      canvas,
      position.translate(-radius * 0.2, -radius * 0.96),
      position.translate(radius * 0.28, radius * 0.92),
      LightcorePalette.layer2,
      width: 1.6,
      amplitude: radius * 0.14,
      seed:
          (controller.elapsed * 22.0) +
          (impact.id.hashCode * 0.0017) +
          (impact.progress * 3),
      alpha: 0.5 * fade,
    );
  }

  double _enemyDeathBaseRadius(ImpactState impact) {
    final sizeScale = impact.defeatedEnemySizeScale.clamp(0.36, 1.8).toDouble();
    return math.max(_coreRadius * 0.2, _coreRadius * 0.34 * sizeScale);
  }

  void _renderEnemyDestroyedImpact(
    Canvas canvas, {
    required ImpactState impact,
    required Offset position,
    required Color shellColor,
    required Color accentColor,
    required double radius,
    required double fade,
  }) {
    final defeatedAffinity = impact.defeatedEnemyAffinity ?? impact.affinity;
    if (defeatedAffinity == PrototypeAffinity.neutral ||
        defeatedAffinity == PrototypeAffinity.solar ||
        defeatedAffinity == PrototypeAffinity.verdant) {
      _renderDustEnemyDeathImpact(
        canvas,
        impact: impact,
        position: position,
        shellColor: shellColor,
        accentColor: accentColor,
        radius: radius,
        fade: fade,
      );
      return;
    }
    if (defeatedAffinity == PrototypeAffinity.ember) {
      _renderThermalImplosionDeathImpact(
        canvas,
        impact: impact,
        position: position,
        shellColor: shellColor,
        accentColor: accentColor,
        radius: radius,
        fade: fade,
      );
      return;
    }
    if (defeatedAffinity == PrototypeAffinity.aether) {
      _renderRadiationWaveDeathImpact(
        canvas,
        impact: impact,
        position: position,
        shellColor: shellColor,
        accentColor: accentColor,
        radius: radius,
        fade: fade,
      );
      return;
    }
    if (defeatedAffinity == PrototypeAffinity.violet) {
      _renderBlobPopDeathImpact(
        canvas,
        impact: impact,
        position: position,
        shellColor: shellColor,
        accentColor: accentColor,
        radius: radius,
        fade: fade,
      );
      return;
    }

    final progress = impact.progress.clamp(0.0, 1.0);
    final collapse = Curves.easeInCubic.transform(progress);
    final shatter = Curves.easeOutCubic.transform(progress);
    final spinDirection = impact.id.hashCode.isEven ? 1.0 : -1.0;
    final shellRotation = (math.pi / 6) + (progress * 0.42 * spinDirection);
    final shellRadius = radius * (0.96 - (collapse * 0.34));
    final innerRadius = math.max(radius * 0.18, shellRadius - (radius * 0.26));
    final voidRadius = radius * (0.18 + (collapse * 0.28));
    final shardTravel = radius * (0.24 + (shatter * 1.06));
    final strokeColor = Color.lerp(shellColor, LightcorePalette.mist, 0.38)!;
    final shardColor = Color.lerp(accentColor, LightcorePalette.mist, 0.34)!;

    canvas.drawPath(
      _polygonPath(position, shellRadius * 1.12, 6, shellRotation),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..color = shellColor.withValues(alpha: 0.14 * fade),
    );
    canvas.drawPath(
      _polygonPath(position, shellRadius, 6, shellRotation),
      Paint()
        ..shader = RadialGradient(
          colors: [
            LightcorePalette.layer2.withValues(alpha: 0.26 * fade),
            shellColor.withValues(alpha: 0.14 * fade),
            Colors.transparent,
          ],
          stops: const [0.08, 0.52, 1],
        ).createShader(Rect.fromCircle(center: position, radius: shellRadius)),
    );
    canvas.drawPath(
      _polygonPath(position, shellRadius, 6, shellRotation),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = strokeColor.withValues(alpha: 0.82 * fade),
    );
    canvas.drawPath(
      _polygonPath(position, innerRadius, 6, shellRotation - 0.12),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = accentColor.withValues(alpha: 0.44 * fade),
    );
    canvas.drawPath(
      _polygonPath(position, voidRadius, 6, shellRotation + 0.08),
      Paint()..color = LightcorePalette.abyss.withValues(alpha: 0.62 * fade),
    );

    for (final breakAngle in <double>[
      shellRotation,
      shellRotation + (math.pi / 3),
      shellRotation + ((2 * math.pi) / 3),
    ]) {
      final start = position.translate(
        -math.cos(breakAngle) * (radius * 0.16),
        -math.sin(breakAngle) * (radius * 0.16),
      );
      final end = position.translate(
        math.cos(breakAngle) * (radius * 0.34),
        math.sin(breakAngle) * (radius * 0.34),
      );
      _drawGlowLine(
        canvas,
        start,
        end,
        accentColor,
        width: 1.3,
        alpha: 0.18 * fade,
      );
    }

    for (var index = 0; index < 6; index++) {
      final angle =
          shellRotation +
          (((math.pi * 2) / 6) * index) +
          (spinDirection * shatter * 0.12);
      final origin = position.translate(
        math.cos(angle) * (shellRadius * 0.34),
        math.sin(angle) * (shellRadius * 0.34),
      );
      final shardCenter = position.translate(
        math.cos(angle) * shardTravel,
        math.sin(angle) * shardTravel,
      );
      final tip = shardCenter.translate(
        math.cos(angle) * (radius * 0.18),
        math.sin(angle) * (radius * 0.18),
      );
      final back = shardCenter.translate(
        -math.cos(angle) * (radius * 0.12),
        -math.sin(angle) * (radius * 0.12),
      );
      final tangent = Offset(-math.sin(angle), math.cos(angle));
      final wingSpan = radius * (0.08 + ((5 - index) * 0.005));
      final shard = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          back.dx + (tangent.dx * wingSpan),
          back.dy + (tangent.dy * wingSpan),
        )
        ..lineTo(
          back.dx - (tangent.dx * wingSpan),
          back.dy - (tangent.dy * wingSpan),
        )
        ..close();

      _drawGlowLine(
        canvas,
        origin,
        shardCenter,
        shellColor,
        width: 1.2 + ((1 - progress) * 0.7),
        alpha: 0.24 * fade,
      );
      canvas.drawPath(
        shard,
        Paint()
          ..color = shardColor.withValues(
            alpha: (0.74 - (index * 0.05)) * fade,
          ),
      );
      if (index.isEven) {
        _drawEnergyOrb(
          canvas,
          shardCenter,
          index % 3 == 0 ? accentColor : LightcorePalette.layer2,
          radius * 0.055,
          alpha: 0.42 * fade,
        );
      }
    }

    if (impact.critical) {
      canvas.drawPath(
        _polygonPath(position, shellRadius * 1.04, 6, shellRotation + 0.14),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = LightcorePalette.solar.withValues(alpha: 0.78 * fade),
      );
    }
  }

  void _renderEnemyRewardDrops(
    Canvas canvas, {
    required ImpactState impact,
    required Offset position,
    required Color accentColor,
    required double radius,
  }) {
    final progress = impact.progress.clamp(0.0, 1.0).toDouble();
    if (progress <= 0 || size.x <= 0) {
      return;
    }

    final seed = impact.id.hashCode * 0.017;
    final dropCount =
        6 + (impact.defeatedEnemySizeScale * 2).round().clamp(0, 5);
    final compact = size.x < 760 || size.y < 760;
    final targetX = compact ? 106.0 : 184.0;
    final targetY = compact ? 34.0 : 58.0;
    final maxTargetX = math.max(12.0, size.x - 12.0);

    for (var index = 0; index < dropCount; index++) {
      final noiseA = _deathNoise(seed, index, 0.19);
      final noiseB = _deathNoise(seed, index, 0.47);
      final noiseC = _deathNoise(seed, index, 0.83);
      final angle =
          seed +
          (((math.pi * 2) / dropCount) * index) +
          ((noiseA - 0.5) * 0.52);
      final direction = Offset(math.cos(angle), math.sin(angle));
      final origin = position + (direction * radius * (0.36 + (noiseA * 0.48)));
      final scatterTarget =
          position +
          (direction * radius * (0.78 + (noiseB * 0.7))) +
          Offset(0, radius * (0.34 + (noiseC * 0.34)));
      final target = Offset(
        (targetX + ((noiseA - 0.5) * (compact ? 22 : 28)))
            .clamp(12.0, maxTargetX)
            .toDouble(),
        targetY + ((noiseB - 0.5) * (compact ? 8 : 10)),
      );
      final scatterT = (progress / 0.22).clamp(0.0, 1.0).toDouble();
      final collectT = ((progress - 0.18) / 0.82).clamp(0.0, 1.0).toDouble();
      final scatter = Offset.lerp(
        origin,
        scatterTarget,
        Curves.easeOutCubic.transform(scatterT),
      )!;
      final control = Offset(
        ((scatterTarget.dx + target.dx) / 2) + ((noiseC - 0.5) * radius * 1.4),
        math.min(scatterTarget.dy, target.dy) - (radius * (1.4 + noiseB)),
      );
      final lifted = _quadraticPoint(
        scatterTarget,
        control,
        target,
        Curves.easeInOutCubic.transform(collectT),
      );
      final center = Offset.lerp(
        scatter,
        lifted,
        Curves.easeInCubic.transform(collectT),
      )!;
      final introAlpha = (progress / 0.08).clamp(0.0, 1.0).toDouble();
      final exitAlpha = ((1 - progress) / 0.16).clamp(0.0, 1.0).toDouble();
      final dropAlpha = introAlpha * exitAlpha * (0.74 + (noiseC * 0.2));
      final dropRadius = math.max(
        2.1,
        radius * (0.05 + (noiseB * 0.028)) * (1 - (collectT * 0.32)),
      );
      final dropColor = Color.lerp(
        LightcorePalette.gilded,
        accentColor,
        0.28 + (noiseA * 0.24),
      )!;

      canvas.drawCircle(
        center,
        dropRadius * 2.2,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
          ..color = dropColor.withValues(alpha: 0.16 * dropAlpha),
      );
      canvas.drawCircle(
        center,
        dropRadius,
        Paint()..color = dropColor.withValues(alpha: 0.88 * dropAlpha),
      );
      canvas.drawCircle(
        center.translate(-dropRadius * 0.28, -dropRadius * 0.32),
        dropRadius * 0.32,
        Paint()
          ..color = LightcorePalette.layer2.withValues(alpha: 0.72 * dropAlpha),
      );
    }
  }

  void _renderDustEnemyDeathImpact(
    Canvas canvas, {
    required ImpactState impact,
    required Offset position,
    required Color shellColor,
    required Color accentColor,
    required double radius,
    required double fade,
  }) {
    final progress = impact.progress.clamp(0.0, 1.0).toDouble();
    final burst = Curves.easeOutCubic.transform(progress);
    final seed = impact.id.hashCode * 0.013;
    final dustColor = Color.lerp(accentColor, LightcorePalette.mist, 0.62)!;
    final innerDustColor = Color.lerp(shellColor, LightcorePalette.mist, 0.72)!;

    canvas.drawCircle(
      position,
      radius * (0.56 + (burst * 0.48)),
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                innerDustColor.withValues(alpha: 0.32 * fade),
                dustColor.withValues(alpha: 0.16 * fade),
                Colors.transparent,
              ],
              stops: const [0, 0.48, 1],
            ).createShader(
              Rect.fromCircle(center: position, radius: radius * 1.12),
            ),
    );
    canvas.drawCircle(
      position,
      radius * (0.34 + (burst * 1.16)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = dustColor.withValues(alpha: 0.26 * fade),
    );

    const particleCount = 22;
    for (var index = 0; index < particleCount; index++) {
      final noiseA = _deathNoise(seed, index, 0.17);
      final noiseB = _deathNoise(seed, index, 0.61);
      final angle =
          (((math.pi * 2) / particleCount) * index) +
          ((noiseA - 0.5) * 0.62) +
          (progress * (impact.id.hashCode.isEven ? 0.08 : -0.08));
      final direction = Offset(math.cos(angle), math.sin(angle));
      final tangent = Offset(-direction.dy, direction.dx);
      final travel = radius * (0.24 + (burst * 2.12)) * (0.54 + noiseB);
      final drift =
          radius *
          0.13 *
          math.sin(seed + (index * 1.37) + (progress * math.pi * 2));
      final gravity = radius * 0.34 * progress * progress;
      final particleCenter = position.translate(
        (direction.dx * travel) + (tangent.dx * drift),
        (direction.dy * travel) + (tangent.dy * drift) + gravity,
      );
      final particleFade = (fade * (0.54 + (noiseA * 0.38))).clamp(0.0, 1.0);
      final particleRadius =
          radius *
          (0.026 + (noiseB * 0.044)) *
          (1 - (progress * 0.72)).clamp(0.18, 1.0).toDouble();
      final particleColor = index.isEven
          ? dustColor
          : Color.lerp(dustColor, LightcorePalette.gilded, 0.26)!;

      if (index % 3 == 0) {
        _drawGlowLine(
          canvas,
          particleCenter - (direction * radius * 0.11),
          particleCenter + (direction * radius * 0.05),
          particleColor,
          width: math.max(0.8, radius * 0.018),
          alpha: 0.28 * particleFade,
        );
      }
      canvas.drawCircle(
        particleCenter,
        particleRadius * 2.2,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
          ..color = particleColor.withValues(alpha: 0.1 * particleFade),
      );
      canvas.drawCircle(
        particleCenter,
        particleRadius,
        Paint()..color = particleColor.withValues(alpha: 0.78 * particleFade),
      );
    }
  }

  void _renderThermalImplosionDeathImpact(
    Canvas canvas, {
    required ImpactState impact,
    required Offset position,
    required Color shellColor,
    required Color accentColor,
    required double radius,
    required double fade,
  }) {
    final progress = impact.progress.clamp(0.0, 1.0).toDouble();
    final expandT = (progress / 0.42).clamp(0.0, 1.0).toDouble();
    final collapseT = ((progress - 0.34) / 0.66).clamp(0.0, 1.0).toDouble();
    final expand = Curves.easeOutBack.transform(expandT);
    final collapse = Curves.easeInCubic.transform(collapseT);
    final collapseScale = (1 - (collapse * 0.94)).clamp(0.08, 1.0).toDouble();
    final heatRadius = radius * (0.34 + (expand * 1.24)) * collapseScale;
    final ringRadius = radius * (0.72 + (expand * 1.08) + (collapse * 0.74));
    final seed = impact.id.hashCode * 0.009;

    canvas.drawCircle(
      position,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..color = LightcorePalette.flare.withValues(
          alpha: 0.34 * fade * (1 - (collapse * 0.58)),
        ),
    );
    canvas.drawCircle(
      position,
      ringRadius * (0.66 + (collapse * 0.22)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = shellColor.withValues(alpha: 0.5 * fade),
    );
    canvas.drawCircle(
      position,
      heatRadius * 2.2,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
        ..color = accentColor.withValues(alpha: 0.2 * fade),
    );
    canvas.drawCircle(
      position,
      heatRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            LightcorePalette.gilded.withValues(alpha: 0.94 * fade),
            LightcorePalette.flare.withValues(alpha: 0.9 * fade),
            accentColor.withValues(alpha: 0.74 * fade),
            LightcorePalette.abyss.withValues(alpha: 0.5 * fade * collapse),
          ],
          stops: const [0, 0.32, 0.72, 1],
        ).createShader(Rect.fromCircle(center: position, radius: heatRadius)),
    );

    for (var index = 0; index < 10; index++) {
      final angle =
          seed +
          (((math.pi * 2) / 10) * index) +
          (progress * 0.28 * (impact.id.hashCode.isEven ? 1 : -1));
      final direction = Offset(math.cos(angle), math.sin(angle));
      if (collapse > 0.02) {
        _drawGlowLine(
          canvas,
          position + (direction * radius * (1.82 - (collapse * 0.36))),
          position + (direction * radius * (0.24 + ((1 - collapse) * 0.22))),
          index.isEven ? LightcorePalette.flare : accentColor,
          width: 1.2 + (collapse * 1.2),
          alpha: 0.46 * fade * collapse,
        );
      } else if (index.isEven) {
        _drawGlowLine(
          canvas,
          position + (direction * radius * 0.48),
          position + (direction * radius * 1.28),
          LightcorePalette.flare,
          width: 1.1,
          alpha: 0.24 * fade,
        );
      }
    }

    if (collapse > 0.12) {
      final voidRadius = radius * (0.12 + (collapse * 0.38));
      canvas.drawCircle(
        position,
        voidRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              LightcorePalette.abyss.withValues(alpha: 0.86 * fade),
              LightcorePalette.night.withValues(alpha: 0.72 * fade),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: position, radius: voidRadius)),
      );
      _drawEnergyOrb(
        canvas,
        position,
        LightcorePalette.gilded,
        radius * (0.05 + ((1 - collapse) * 0.08)),
        alpha: 0.74 * fade,
      );
    }
  }

  void _renderRadiationWaveDeathImpact(
    Canvas canvas, {
    required ImpactState impact,
    required Offset position,
    required Color shellColor,
    required Color accentColor,
    required double radius,
    required double fade,
  }) {
    final progress = impact.progress.clamp(0.0, 1.0).toDouble();
    final seed = impact.id.hashCode * 0.006;
    final waveColor = Color.lerp(accentColor, LightcorePalette.layer2, 0.24)!;

    canvas.drawCircle(
      position,
      radius * (0.72 + (progress * 0.24)),
      Paint()
        ..shader = RadialGradient(
          colors: [
            LightcorePalette.layer2.withValues(alpha: 0.34 * fade),
            accentColor.withValues(alpha: 0.24 * fade),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: position, radius: radius)),
    );

    for (var index = 0; index < 4; index++) {
      final ringT = ((progress * 1.24) - (index * 0.13)).clamp(0.0, 1.0);
      if (ringT <= 0) {
        continue;
      }
      final eased = Curves.easeOutCubic.transform(ringT.toDouble());
      final ringRadius = radius * (0.38 + (eased * (2.2 + (index * 0.28))));
      final ringAlpha =
          fade * (1 - ringT) * (0.62 - (index * 0.08)).clamp(0.18, 0.62);
      canvas.drawCircle(
        position,
        ringRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.1, radius * (0.035 - (index * 0.004)))
          ..color = waveColor.withValues(alpha: ringAlpha),
      );
    }

    for (var index = 0; index < 3; index++) {
      final angle = seed + (((math.pi * 2) / 3) * index) + (progress * 0.42);
      canvas.drawArc(
        Rect.fromCircle(center: position, radius: radius * (0.86 + progress)),
        angle - 0.36,
        0.72,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = shellColor.withValues(alpha: 0.34 * fade),
      );
    }

    for (var index = 0; index < 8; index++) {
      final angle =
          seed +
          (((math.pi * 2) / 8) * index) +
          (math.sin(progress * math.pi) * 0.16);
      final direction = Offset(math.cos(angle), math.sin(angle));
      _drawEnergyBolt(
        canvas,
        position + (direction * radius * 0.32),
        position + (direction * radius * (1.18 + (progress * 1.04))),
        index.isEven ? accentColor : LightcorePalette.layer2,
        width: 1.1,
        amplitude: radius * 0.08,
        seed: seed + index,
        alpha: 0.2 * fade,
      );
    }
  }

  void _renderBlobPopDeathImpact(
    Canvas canvas, {
    required ImpactState impact,
    required Offset position,
    required Color shellColor,
    required Color accentColor,
    required double radius,
    required double fade,
  }) {
    final progress = impact.progress.clamp(0.0, 1.0).toDouble();
    final blobT = (progress / 0.52).clamp(0.0, 1.0).toDouble();
    final popT = ((progress - 0.42) / 0.58).clamp(0.0, 1.0).toDouble();
    final blob = Curves.easeOutBack.transform(blobT);
    final pop = Curves.easeOutCubic.transform(popT);
    final seed = impact.id.hashCode * 0.011;
    final blobRadius = radius * (0.44 + (blob * 0.78)) * (1 - (pop * 0.7));
    final wobble =
        radius *
        (0.12 + (0.06 * math.sin((controller.elapsed * 9.0) + seed))) *
        (1 - pop);

    if (pop < 0.96) {
      final blobPath = _organicBlobPath(
        position,
        math.max(radius * 0.12, blobRadius),
        seed: seed + (progress * 4.8),
        wobble: wobble,
      );
      canvas.drawPath(
        blobPath,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
          ..color = accentColor.withValues(alpha: 0.18 * fade),
      );
      canvas.drawPath(
        blobPath,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  LightcorePalette.layer2.withValues(alpha: 0.44 * fade),
                  shellColor.withValues(alpha: 0.62 * fade),
                  accentColor.withValues(alpha: 0.72 * fade),
                ],
                stops: const [0.02, 0.5, 1],
              ).createShader(
                Rect.fromCircle(center: position, radius: blobRadius * 1.2),
              ),
      );
      canvas.drawPath(
        blobPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = LightcorePalette.layer2.withValues(alpha: 0.38 * fade),
      );
    }

    if (pop <= 0) {
      return;
    }

    for (var index = 0; index < 11; index++) {
      final noiseA = _deathNoise(seed, index, 0.33);
      final noiseB = _deathNoise(seed, index, 0.79);
      final angle =
          (((math.pi * 2) / 11) * index) +
          ((noiseA - 0.5) * 0.46) -
          (progress * 0.18);
      final direction = Offset(math.cos(angle), math.sin(angle));
      final dropletCenter =
          position +
          (direction * radius * (0.42 + (pop * (1.42 + noiseB * 0.74))));
      final dropletRadius =
          radius * (0.045 + (noiseA * 0.06)) * (1 - (popT * 0.48));
      final dropletAlpha = (fade * (0.82 - (noiseB * 0.22))).clamp(0.0, 1.0);
      if (index % 2 == 0) {
        _drawGlowLine(
          canvas,
          position + (direction * radius * 0.34),
          dropletCenter - (direction * radius * 0.08),
          accentColor,
          width: 1,
          alpha: 0.18 * dropletAlpha,
        );
      }
      canvas.drawCircle(
        dropletCenter,
        dropletRadius * 2.1,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
          ..color = accentColor.withValues(alpha: 0.16 * dropletAlpha),
      );
      _drawEnergyOrb(
        canvas,
        dropletCenter,
        Color.lerp(accentColor, LightcorePalette.layer2, 0.18)!,
        dropletRadius,
        alpha: 0.72 * dropletAlpha,
      );
    }
  }
}
