part of '../lightcore_battle_game.dart';

extension _LightcoreBattleGameProjectileRendering on LightcoreBattleGame {
  void _renderShotFireBursts(Canvas canvas) {
    for (final burst in _shotFireBursts) {
      final progress =
          (burst.elapsed / LightcoreBattleGame._shotFireBurstDuration)
              .clamp(0.0, 1.0)
              .toDouble();
      if (progress >= 1) {
        continue;
      }

      final origin = _shotStartOffset(layer2: burst.layer2);
      final spec = _fireBurstSpecForProjectile(burst.projectileType);
      final color = burst.layer2
          ? LightcorePalette.layer2
          : _signatureColor(burst.affinity, burst.secondaryAffinity);
      final open = Curves.easeOutCubic.transform(progress);
      final fade =
          Curves.easeOutQuad.transform(1 - progress) * _battleEffectAlphaScale;
      final baseRadius = _coreRadius * spec.scale;
      final muzzle = origin + _angleOffset(burst.aimAngle, baseRadius * 0.3);

      if (!_lowPowerBattleEffects) {
        canvas.drawCircle(
          origin,
          baseRadius * (0.16 + (open * 0.16)),
          Paint()
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
            ..color = color.withValues(alpha: 0.22 * fade),
        );
      }

      final sparkCount = _qualityScaledCount(
        spec.sparkCount,
        balanced: math.max(1, spec.sparkCount - 1),
        lowPower: math.max(0, spec.sparkCount ~/ 2),
      );
      final ringCount = _qualityScaledCount(
        spec.ringCount,
        balanced: math.max(1, spec.ringCount),
        lowPower: math.min(1, spec.ringCount),
      );

      switch (spec.style) {
        case _ShotFireBurstStyle.spark:
          _renderSparkFireBurst(
            canvas,
            origin: origin,
            color: color,
            aimAngle: burst.aimAngle,
            baseRadius: baseRadius,
            open: open,
            fade: fade,
            sparkCount: sparkCount,
            spread: spec.spread,
          );
        case _ShotFireBurstStyle.needle:
          _renderNeedleFireBurst(
            canvas,
            origin: origin,
            color: color,
            aimAngle: burst.aimAngle,
            baseRadius: baseRadius,
            open: open,
            fade: fade,
          );
        case _ShotFireBurstStyle.heavy:
          _renderHeavyFireBurst(
            canvas,
            origin: origin,
            color: color,
            aimAngle: burst.aimAngle,
            baseRadius: baseRadius,
            open: open,
            fade: fade,
            seed: _fireBurstSeed(burst),
          );
        case _ShotFireBurstStyle.pulse:
          _renderPulseFireBurst(
            canvas,
            origin: origin,
            muzzle: muzzle,
            color: color,
            aimAngle: burst.aimAngle,
            baseRadius: baseRadius,
            open: open,
            fade: fade,
            ringCount: ringCount,
          );
        case _ShotFireBurstStyle.cluster:
          _renderClusterFireBurst(
            canvas,
            origin: origin,
            color: color,
            aimAngle: burst.aimAngle,
            baseRadius: baseRadius,
            open: open,
            fade: fade,
            sparkCount: sparkCount,
            spread: spec.spread,
          );
        case _ShotFireBurstStyle.arc:
          _renderArcFireBurst(
            canvas,
            origin: origin,
            color: color,
            aimAngle: burst.aimAngle,
            baseRadius: baseRadius,
            open: open,
            fade: fade,
            seed: _fireBurstSeed(burst),
          );
        case _ShotFireBurstStyle.split:
          _renderSplitFireBurst(
            canvas,
            origin: origin,
            color: color,
            aimAngle: burst.aimAngle,
            baseRadius: baseRadius,
            open: open,
            fade: fade,
            spread: spec.spread,
          );
        case _ShotFireBurstStyle.lance:
          _renderLanceFireBurst(
            canvas,
            origin: origin,
            color: color,
            aimAngle: burst.aimAngle,
            baseRadius: baseRadius,
            open: open,
            fade: fade,
          );
        case _ShotFireBurstStyle.blast:
          _renderBlastFireBurst(
            canvas,
            origin: origin,
            color: color,
            aimAngle: burst.aimAngle,
            baseRadius: baseRadius,
            open: open,
            fade: fade,
          );
        case _ShotFireBurstStyle.wave:
          _renderWaveFireBurst(
            canvas,
            origin: origin,
            color: color,
            aimAngle: burst.aimAngle,
            baseRadius: baseRadius,
            open: open,
            fade: fade,
            ringCount: ringCount,
          );
        case _ShotFireBurstStyle.nova:
          _renderNovaFireBurst(
            canvas,
            origin: origin,
            color: color,
            aimAngle: burst.aimAngle,
            baseRadius: baseRadius,
            open: open,
            fade: fade,
            sparkCount: sparkCount,
          );
        case _ShotFireBurstStyle.node:
          _renderNodeFireBurst(
            canvas,
            origin: origin,
            color: color,
            aimAngle: burst.aimAngle,
            baseRadius: baseRadius,
            open: open,
            fade: fade,
            seed: _fireBurstSeed(burst),
          );
      }

      if (!burst.layer2 && burst.secondaryAffinity != null) {
        _drawEnergyOrb(
          canvas,
          muzzle.translate(baseRadius * 0.05, -baseRadius * 0.05),
          burst.secondaryAffinity!.color,
          baseRadius * 0.05,
          alpha: 0.62 * fade,
        );
      }
    }
  }

  double _fireBurstSeed(_ShotFireBurst burst) {
    return (burst.id.hashCode * 0.0019) + (controller.elapsed * 9);
  }

  _ShotFireBurstSpec _fireBurstSpecForProjectile(
    ProjectileType projectileType,
  ) {
    return switch (projectileType) {
      ProjectileType.starBolt => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.spark,
        scale: 0.88,
        sparkCount: 4,
        spread: 0.42,
      ),
      ProjectileType.threadBeam => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.needle,
        scale: 0.94,
      ),
      ProjectileType.heavyShot => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.heavy,
        scale: 1.08,
        sparkCount: 4,
      ),
      ProjectileType.coreBomb => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.blast,
        scale: 1.08,
        ringCount: 2,
      ),
      ProjectileType.chainArc => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.arc,
        scale: 1,
        sparkCount: 3,
      ),
      ProjectileType.pulseRing => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.wave,
        scale: 1,
        ringCount: 2,
      ),
      ProjectileType.orbitNode => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.node,
        scale: 0.98,
      ),
      ProjectileType.shieldHalo => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.wave,
        scale: 1.02,
        ringCount: 2,
      ),
      ProjectileType.rapidBolt => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.pulse,
        scale: 0.9,
        ringCount: 2,
      ),
      ProjectileType.twinBolt => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.split,
        scale: 0.92,
        spread: 0.3,
      ),
      ProjectileType.pulseBeam => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.pulse,
        scale: 0.92,
        ringCount: 2,
      ),
      ProjectileType.splitBeam => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.split,
        scale: 0.98,
        spread: 0.34,
      ),
      ProjectileType.breakerShot => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.heavy,
        scale: 1,
        sparkCount: 5,
      ),
      ProjectileType.crushShot => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.blast,
        scale: 1.18,
        ringCount: 2,
      ),
      ProjectileType.pulseBomb => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.pulse,
        scale: 1.08,
        ringCount: 2,
      ),
      ProjectileType.clusterBomb => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.cluster,
        scale: 1,
        sparkCount: 5,
        spread: 0.56,
      ),
      ProjectileType.forkArc => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.split,
        scale: 1,
        spread: 0.44,
      ),
      ProjectileType.arcNode => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.node,
        scale: 1,
      ),
      ProjectileType.echoRing => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.wave,
        scale: 0.94,
        ringCount: 3,
      ),
      ProjectileType.collapseRing => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.blast,
        scale: 1.16,
        ringCount: 3,
      ),
      ProjectileType.sweepNode => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.node,
        scale: 1.05,
        ringCount: 2,
      ),
      ProjectileType.slingNode => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.pulse,
        scale: 0.94,
      ),
      ProjectileType.sweepBeam => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.wave,
        scale: 1,
        ringCount: 2,
      ),
      ProjectileType.lanceBeam => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.lance,
        scale: 1.04,
      ),
      ProjectileType.prismBeam => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.nova,
        scale: 1.08,
        sparkCount: 6,
      ),
      ProjectileType.sentinelBeam => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.arc,
        scale: 1.02,
        sparkCount: 4,
      ),
      ProjectileType.siegeShot => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.blast,
        scale: 1.22,
        ringCount: 2,
      ),
      ProjectileType.drillShot => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.lance,
        scale: 1.1,
      ),
      ProjectileType.ricochetShot => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.arc,
        scale: 1,
        sparkCount: 5,
      ),
      ProjectileType.hunterShip => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.arc,
        scale: 1.04,
        sparkCount: 4,
      ),
      ProjectileType.novaBomb => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.nova,
        scale: 1.18,
        sparkCount: 7,
        ringCount: 2,
      ),
      ProjectileType.cascadeBomb => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.cluster,
        scale: 1.14,
        sparkCount: 6,
        spread: 0.62,
      ),
      ProjectileType.fieldBomb => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.wave,
        scale: 1.16,
        ringCount: 3,
      ),
      ProjectileType.bomberShip => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.nova,
        scale: 1.2,
        sparkCount: 6,
      ),
      ProjectileType.stormArc => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.wave,
        scale: 1.08,
        ringCount: 2,
      ),
      ProjectileType.webArc => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.split,
        scale: 1.06,
        spread: 0.5,
      ),
      ProjectileType.skyArc => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.lance,
        scale: 1.08,
      ),
      ProjectileType.interceptorShip => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.arc,
        scale: 1.04,
        sparkCount: 5,
      ),
      ProjectileType.haloWave => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.wave,
        scale: 1.12,
        ringCount: 3,
      ),
      ProjectileType.spiralWave => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.cluster,
        scale: 1.1,
        sparkCount: 6,
        spread: 0.7,
      ),
      ProjectileType.warpWave => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.lance,
        scale: 1.12,
      ),
      ProjectileType.shadeSatellite => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.arc,
        scale: 1.12,
        sparkCount: 5,
      ),
      ProjectileType.haloNodes => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.wave,
        scale: 1.1,
        ringCount: 3,
      ),
      ProjectileType.anchorNode => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.needle,
        scale: 1.04,
        sparkCount: 4,
      ),
      ProjectileType.flailNode => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.cluster,
        scale: 1.08,
        sparkCount: 5,
        spread: 0.58,
      ),
      ProjectileType.familiarShip => const _ShotFireBurstSpec(
        style: _ShotFireBurstStyle.node,
        scale: 1.08,
        ringCount: 2,
      ),
    };
  }

  void _renderSparkFireBurst(
    Canvas canvas, {
    required Offset origin,
    required Color color,
    required double aimAngle,
    required double baseRadius,
    required double open,
    required double fade,
    required int sparkCount,
    required double spread,
  }) {
    for (var index = 0; index < sparkCount; index++) {
      final offset = sparkCount == 1
          ? 0.0
          : ((index / (sparkCount - 1)) - 0.5) * spread;
      final angle = aimAngle + offset;
      final start = origin + _angleOffset(angle, baseRadius * 0.12);
      final end =
          origin + _angleOffset(angle, baseRadius * (0.4 + open * 0.28));
      _drawGlowLine(
        canvas,
        start,
        end,
        color,
        width: math.max(1.1, baseRadius * 0.035),
        alpha: fade * (0.58 + (index.isEven ? 0.2 : 0)),
      );
    }
    _drawEnergyOrb(
      canvas,
      origin + _angleOffset(aimAngle, baseRadius * (0.24 + open * 0.18)),
      color,
      baseRadius * 0.06,
      alpha: fade,
    );
  }

  void _renderNeedleFireBurst(
    Canvas canvas, {
    required Offset origin,
    required Color color,
    required double aimAngle,
    required double baseRadius,
    required double open,
    required double fade,
  }) {
    final end =
        origin + _angleOffset(aimAngle, baseRadius * (0.7 + open * 0.28));
    _drawGlowLine(
      canvas,
      origin,
      end,
      color,
      width: math.max(1.4, baseRadius * 0.055),
      alpha: fade,
    );
    canvas.drawCircle(
      origin,
      baseRadius * (0.18 + open * 0.14),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.1, baseRadius * 0.03)
        ..color = color.withValues(alpha: 0.5 * fade),
    );
  }

  void _renderHeavyFireBurst(
    Canvas canvas, {
    required Offset origin,
    required Color color,
    required double aimAngle,
    required double baseRadius,
    required double open,
    required double fade,
    required double seed,
  }) {
    final end =
        origin + _angleOffset(aimAngle, baseRadius * (0.58 + open * 0.26));
    _drawGlowLine(
      canvas,
      origin,
      end,
      color,
      width: baseRadius * 0.095,
      alpha: 0.9 * fade,
    );
    canvas.drawPath(
      _hexPath(origin, baseRadius * (0.2 + open * 0.16)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.3, baseRadius * 0.035)
        ..color = color.withValues(alpha: 0.58 * fade),
    );
    for (var index = 0; index < 4; index++) {
      final angle = aimAngle + (math.sin(seed + index) * 0.8);
      final center =
          origin + _angleOffset(angle, baseRadius * (0.24 + open * 0.2));
      canvas.drawCircle(
        center,
        baseRadius * 0.026,
        Paint()..color = LightcorePalette.layer2.withValues(alpha: 0.55 * fade),
      );
    }
  }

  void _renderPulseFireBurst(
    Canvas canvas, {
    required Offset origin,
    required Offset muzzle,
    required Color color,
    required double aimAngle,
    required double baseRadius,
    required double open,
    required double fade,
    required int ringCount,
  }) {
    for (var index = 0; index < ringCount; index++) {
      final ringOpen = (open + (index * 0.18)).clamp(0.0, 1.0).toDouble();
      canvas.drawCircle(
        origin,
        baseRadius * (0.18 + ringOpen * 0.34),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.1, baseRadius * (0.036 - index * 0.004))
          ..color = color.withValues(alpha: (0.48 - index * 0.08) * fade),
      );
    }
    _drawGlowLine(
      canvas,
      origin,
      muzzle + _angleOffset(aimAngle, baseRadius * open * 0.2),
      color,
      width: math.max(1.2, baseRadius * 0.045),
      alpha: 0.58 * fade,
    );
    _drawEnergyOrb(canvas, muzzle, color, baseRadius * 0.065, alpha: fade);
  }

  void _renderClusterFireBurst(
    Canvas canvas, {
    required Offset origin,
    required Color color,
    required double aimAngle,
    required double baseRadius,
    required double open,
    required double fade,
    required int sparkCount,
    required double spread,
  }) {
    for (var index = 0; index < sparkCount; index++) {
      final t = sparkCount == 1 ? 0.5 : index / (sparkCount - 1);
      final angle = aimAngle + ((t - 0.5) * spread);
      final start = origin + _angleOffset(angle, baseRadius * 0.08);
      final end =
          origin + _angleOffset(angle, baseRadius * (0.34 + open * 0.34));
      _drawGlowLine(
        canvas,
        start,
        end,
        index.isEven ? color : LightcorePalette.layer2,
        width: math.max(1.0, baseRadius * 0.032),
        alpha: fade * (0.5 + (0.12 * index)),
      );
      canvas.drawCircle(
        end,
        baseRadius * 0.035,
        Paint()
          ..color = color.withValues(alpha: fade * (0.32 + (0.05 * index))),
      );
    }
  }

  void _renderArcFireBurst(
    Canvas canvas, {
    required Offset origin,
    required Color color,
    required double aimAngle,
    required double baseRadius,
    required double open,
    required double fade,
    required double seed,
  }) {
    final end =
        origin + _angleOffset(aimAngle, baseRadius * (0.6 + open * 0.3));
    _drawEnergyBolt(
      canvas,
      origin,
      end,
      Color.lerp(color, LightcorePalette.gilded, 0.55)!,
      width: math.max(1.3, baseRadius * 0.052),
      amplitude: baseRadius * 0.16,
      seed: seed,
      branch: true,
      alpha: fade,
    );
    canvas.drawArc(
      Rect.fromCircle(center: origin, radius: baseRadius * (0.2 + open * 0.18)),
      aimAngle - 0.8,
      1.6,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.1, baseRadius * 0.028)
        ..color = LightcorePalette.gilded.withValues(alpha: 0.42 * fade),
    );
  }

  void _renderSplitFireBurst(
    Canvas canvas, {
    required Offset origin,
    required Color color,
    required double aimAngle,
    required double baseRadius,
    required double open,
    required double fade,
    required double spread,
  }) {
    for (final offset in <double>[-spread, 0, spread]) {
      final widthScale = offset == 0 ? 0.055 : 0.034;
      _drawGlowLine(
        canvas,
        origin,
        origin +
            _angleOffset(aimAngle + offset, baseRadius * (0.46 + open * 0.28)),
        color,
        width: math.max(1.0, baseRadius * widthScale),
        alpha: fade * (offset == 0 ? 0.74 : 0.48),
      );
    }
  }

  void _renderLanceFireBurst(
    Canvas canvas, {
    required Offset origin,
    required Color color,
    required double aimAngle,
    required double baseRadius,
    required double open,
    required double fade,
  }) {
    final tip =
        origin + _angleOffset(aimAngle, baseRadius * (0.78 + open * 0.42));
    final left = origin + _angleOffset(aimAngle - 0.34, baseRadius * 0.22);
    final right = origin + _angleOffset(aimAngle + 0.34, baseRadius * 0.22);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(origin.dx, origin.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = color.withValues(alpha: 0.24 * fade),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.3, baseRadius * 0.036)
        ..color = color.withValues(alpha: 0.72 * fade),
    );
    _drawGlowLine(
      canvas,
      origin,
      tip,
      LightcorePalette.layer2,
      width: math.max(1.0, baseRadius * 0.025),
      alpha: 0.44 * fade,
    );
  }

  void _renderBlastFireBurst(
    Canvas canvas, {
    required Offset origin,
    required Color color,
    required double aimAngle,
    required double baseRadius,
    required double open,
    required double fade,
  }) {
    final forward =
        origin + _angleOffset(aimAngle, baseRadius * (0.32 + open * 0.2));
    canvas.drawCircle(
      forward,
      baseRadius * (0.2 + open * 0.3),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
        ..color = color.withValues(alpha: 0.22 * fade),
    );
    canvas.drawCircle(
      forward,
      baseRadius * (0.14 + open * 0.24),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, baseRadius * 0.042)
        ..color = color.withValues(alpha: 0.66 * fade),
    );
    canvas.drawPath(
      _hexPath(forward, baseRadius * (0.12 + open * 0.2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, baseRadius * 0.026)
        ..color = LightcorePalette.layer2.withValues(alpha: 0.5 * fade),
    );
  }

  void _renderWaveFireBurst(
    Canvas canvas, {
    required Offset origin,
    required Color color,
    required double aimAngle,
    required double baseRadius,
    required double open,
    required double fade,
    required int ringCount,
  }) {
    for (var index = 0; index < ringCount; index++) {
      final radius = baseRadius * (0.22 + open * (0.3 + index * 0.08));
      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: radius),
        aimAngle - (math.pi * 0.86),
        math.pi * 1.72,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(1.2, baseRadius * (0.035 - index * 0.004))
          ..color = color.withValues(alpha: (0.52 - index * 0.08) * fade),
      );
    }
    canvas.drawCircle(
      origin,
      baseRadius * (0.12 + open * 0.12),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, baseRadius * 0.024)
        ..color = LightcorePalette.layer2.withValues(alpha: 0.36 * fade),
    );
  }

  void _renderNovaFireBurst(
    Canvas canvas, {
    required Offset origin,
    required Color color,
    required double aimAngle,
    required double baseRadius,
    required double open,
    required double fade,
    required int sparkCount,
  }) {
    canvas.drawCircle(
      origin,
      baseRadius * (0.22 + open * 0.3),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..color = color.withValues(alpha: 0.2 * fade),
    );
    for (var index = 0; index < sparkCount; index++) {
      final angle = aimAngle + (((math.pi * 2) / sparkCount) * index);
      _drawGlowLine(
        canvas,
        origin + _angleOffset(angle, baseRadius * 0.08),
        origin + _angleOffset(angle, baseRadius * (0.42 + open * 0.34)),
        index.isEven ? color : LightcorePalette.layer2,
        width: math.max(1.0, baseRadius * 0.032),
        alpha: 0.48 * fade,
      );
    }
    canvas.drawPath(
      _polygonPath(origin, baseRadius * (0.2 + open * 0.18), 8, aimAngle),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, baseRadius * 0.026)
        ..color = color.withValues(alpha: 0.52 * fade),
    );
  }

  void _renderNodeFireBurst(
    Canvas canvas, {
    required Offset origin,
    required Color color,
    required double aimAngle,
    required double baseRadius,
    required double open,
    required double fade,
    required double seed,
  }) {
    final radius = baseRadius * (0.24 + open * 0.18);
    canvas.drawArc(
      Rect.fromCircle(center: origin, radius: radius),
      aimAngle + seed,
      math.pi * 1.25,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.2, baseRadius * 0.038)
        ..color = color.withValues(alpha: 0.46 * fade),
    );
    final nodeAngle = aimAngle + (open * math.pi * 1.6);
    _drawEnergyOrb(
      canvas,
      origin + _angleOffset(nodeAngle, radius),
      color,
      baseRadius * 0.055,
      alpha: fade,
    );
  }

  void _renderPulses(Canvas canvas) {
    for (final pulse in controller.pulses) {
      final sourceSlotIndex = pulse.sourceSlotIndex;
      final start = sourceSlotIndex == null
          ? _corePulseStart(pulse)
          : _slotPositions[sourceSlotIndex];
      final current = start + ((_center - start) * pulse.progress);
      final color = _signatureColor(pulse.affinity, pulse.secondaryAffinity);
      final startOffset = Offset(start.x, start.y);
      final currentOffset = Offset(current.x, current.y);
      final pulsePath = _curvedLinkPath(startOffset, currentOffset, bend: 0.18);

      canvas.drawPath(
        pulsePath,
        Paint()
          ..color = color.withValues(alpha: 0.28)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
        currentOffset,
        _slotRadius * 0.12,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
          ..color = color.withValues(alpha: 0.6),
      );
      canvas.drawCircle(
        currentOffset,
        _slotRadius * 0.09,
        Paint()..color = color,
      );
      if (pulse.secondaryAffinity != null) {
        canvas.drawCircle(
          currentOffset.translate(_slotRadius * 0.04, -_slotRadius * 0.04),
          _slotRadius * 0.045,
          Paint()..color = pulse.secondaryAffinity!.color,
        );
      }
    }
  }

  Vector2 _corePulseStart(EnergyPulseState pulse) {
    final seed = pulse.id.hashCode.abs();
    final angle = (seed % 360) * (math.pi / 180);
    return Vector2(
      _center.x + (math.cos(angle) * _coreRadius * 0.92),
      _center.y + (math.sin(angle) * _coreRadius * 0.92),
    );
  }

  void _renderShots(Canvas canvas) {
    for (final shot in controller.shots) {
      final start = _shotStartOffset(layer2: shot.layer2);
      final end = Offset(
        _center.x +
            math.cos(shot.aimAngle) * _modelRadiusToVisual(shot.travelRadius),
        _center.y +
            math.sin(shot.aimAngle) * _modelRadiusToVisual(shot.travelRadius),
      );
      final current = Offset.lerp(start, end, shot.progress)!;
      final color = shot.layer2
          ? LightcorePalette.layer2
          : _signatureColor(shot.affinity, shot.secondaryAffinity);
      final seed =
          (controller.elapsed * 14.0) +
          (shot.progress * 9.0) +
          (shot.id.hashCode * 0.0017);
      final width = switch (shot.projectileType.behaviorProfile) {
        ProjectileBehaviorProfile.thread => 3.0,
        ProjectileBehaviorProfile.pulse => 2.3,
        ProjectileBehaviorProfile.burst => 2.6,
        ProjectileBehaviorProfile.chain => 2.8,
        ProjectileBehaviorProfile.split => 2.9,
        ProjectileBehaviorProfile.lance => 3.8,
        ProjectileBehaviorProfile.explosion => 4.2,
        ProjectileBehaviorProfile.wave => 3.6,
        ProjectileBehaviorProfile.nova => 4.8,
      };
      final lineWidth = shot.layer2 ? width + 0.6 : width;
      if (_shotUsesBlueFocusLaser(shot)) {
        final beamEnd = _renderBlueFocusLaserShot(
          canvas,
          shot: shot,
          color: color,
          width: lineWidth,
        );
        if (shot.critical) {
          canvas.drawPath(
            _hexPath(beamEnd, _coreRadius * 0.14),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..color = LightcorePalette.solar.withValues(alpha: 0.92),
          );
        }
        continue;
      }
      final coreBasicImpact = _shotUsesCoreBasicImpact(shot);
      if (_shotUsesShieldHalo(shot)) {
        final shieldPoint = _renderShieldHaloShot(
          canvas,
          shot: shot,
          color: color,
          width: lineWidth,
        );
        if (!shot.layer2 && shot.secondaryAffinity != null) {
          canvas.drawCircle(
            shieldPoint,
            _coreRadius * 0.045,
            Paint()
              ..color = shot.secondaryAffinity!.color.withValues(alpha: 0.72),
          );
        }
        if (shot.critical) {
          canvas.drawPath(
            _hexPath(shieldPoint, _coreRadius * 0.14),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..color = LightcorePalette.solar.withValues(alpha: 0.92),
          );
        }
        continue;
      }
      if (!coreBasicImpact && shot.projectileType.usesRadialWave) {
        final centerOffset = Offset(_center.x, _center.y);
        final waveRadius = _modelRadiusToVisual(
          shot.travelRadius * shot.progress,
        ).clamp(_coreRadius * 0.14, _spawnRadiusVisual * 0.96);
        canvas.drawCircle(
          centerOffset,
          waveRadius,
          Paint()
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = lineWidth + 3
            ..color = color.withValues(alpha: 0.18),
        );
        canvas.drawCircle(
          centerOffset,
          waveRadius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = lineWidth
            ..color = color.withValues(alpha: 0.82),
        );
        canvas.drawCircle(
          centerOffset,
          math.max(_coreRadius * 0.18, waveRadius - (_coreRadius * 0.1)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = color.withValues(alpha: 0.28),
        );
        if (shot.secondaryAffinity != null) {
          canvas.drawCircle(
            centerOffset,
            waveRadius + (_coreRadius * 0.06),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = shot.secondaryAffinity!.color.withValues(alpha: 0.52),
          );
        }
        if (shot.critical) {
          canvas.drawPath(
            _hexPath(current, _coreRadius * 0.14),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..color = LightcorePalette.solar.withValues(alpha: 0.92),
          );
        }
        continue;
      }
      if (_shotUsesOrbitNode(shot)) {
        final orbitNode = _renderOrbitNodeShot(
          canvas,
          shot: shot,
          color: color,
          width: lineWidth,
        );
        if (!shot.layer2 && shot.secondaryAffinity != null) {
          _drawEnergyOrb(
            canvas,
            orbitNode.translate(_coreRadius * 0.05, -_coreRadius * 0.05),
            shot.secondaryAffinity!.color,
            _coreRadius * 0.04,
            alpha: 0.72,
          );
        }
        if (shot.critical) {
          canvas.drawPath(
            _hexPath(orbitNode, _coreRadius * 0.14),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..color = LightcorePalette.solar.withValues(alpha: 0.92),
          );
        }
        continue;
      }
      var orbCenter = current;
      var orbRadius = shot.layer2
          ? _coreRadius * 0.1
          : shot.projectileType.behaviorProfile ==
                ProjectileBehaviorProfile.explosion
          ? _coreRadius * 0.11
          : _coreRadius * 0.075;
      var orbAlpha = shot.layer2 ? 1.0 : 0.96;

      if (coreBasicImpact) {
        _drawGlowLine(
          canvas,
          start,
          current,
          color,
          width: lineWidth * 0.72,
          alpha: 0.64,
        );
        _drawEnergyOrb(canvas, orbCenter, color, _coreRadius * 0.085);
        if (shot.critical) {
          canvas.drawPath(
            _hexPath(current, _coreRadius * 0.14),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..color = LightcorePalette.solar.withValues(alpha: 0.92),
          );
        }
        continue;
      }

      switch (shot.projectileType.behaviorProfile) {
        case ProjectileBehaviorProfile.thread:
          if (shot.projectileType == ProjectileType.heavyShot) {
            _renderHeavyShotTrail(
              canvas,
              start: start,
              current: current,
              color: color,
              width: lineWidth,
              seed: seed,
            );
            orbRadius = _coreRadius * 0.095;
          } else {
            _drawGlowLine(
              canvas,
              start,
              current,
              color,
              width: lineWidth,
              alpha: shot.layer2 ? 0.9 : 0.82,
            );
          }
        case ProjectileBehaviorProfile.burst:
          final upperTrail = Offset.lerp(start, current, 0.74)!;
          final lowerTrail = Offset.lerp(start, current, 0.58)!;
          _drawGlowLine(
            canvas,
            start,
            current,
            color,
            width: lineWidth * 0.92,
            alpha: 0.84,
          );
          _drawGlowLine(
            canvas,
            upperTrail.translate(0, -_coreRadius * 0.08),
            current.translate(_coreRadius * 0.08, -_coreRadius * 0.12),
            color,
            width: width * 0.5,
            alpha: 0.46,
          );
          _drawGlowLine(
            canvas,
            lowerTrail.translate(0, _coreRadius * 0.08),
            current.translate(_coreRadius * 0.08, _coreRadius * 0.12),
            color,
            width: width * 0.5,
            alpha: 0.46,
          );
        case ProjectileBehaviorProfile.pulse:
          final trail = Offset.lerp(start, current, 0.7)!;
          _drawGlowLine(
            canvas,
            start,
            current,
            color,
            width: lineWidth * 0.88,
            alpha: 0.86,
          );
          _drawGlowLine(
            canvas,
            trail,
            current.translate(_coreRadius * 0.08, -_coreRadius * 0.08),
            color,
            width: width * 0.74,
            alpha: 0.52,
          );
        case ProjectileBehaviorProfile.lance:
          _drawGlowLine(
            canvas,
            start,
            current,
            color,
            width: lineWidth * 1.06,
            alpha: 0.9,
          );
          final angle = math.atan2(
            current.dy - start.dy,
            current.dx - start.dx,
          );
          final head = Path()
            ..moveTo(current.dx, current.dy)
            ..lineTo(
              current.dx - math.cos(angle - 0.4) * (_coreRadius * 0.18),
              current.dy - math.sin(angle - 0.4) * (_coreRadius * 0.18),
            )
            ..lineTo(
              current.dx - math.cos(angle + 0.4) * (_coreRadius * 0.18),
              current.dy - math.sin(angle + 0.4) * (_coreRadius * 0.18),
            )
            ..close();
          canvas.drawPath(
            head,
            Paint()
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
              ..color = color.withValues(alpha: 0.34),
          );
          canvas.drawPath(head, Paint()..color = color);
        case ProjectileBehaviorProfile.chain:
          if (shot.projectileType == ProjectileType.chainArc) {
            _renderChainArcShot(
              canvas,
              start: start,
              current: current,
              color: color,
              width: lineWidth,
              seed: seed,
            );
          } else {
            _drawEnergyBolt(
              canvas,
              start,
              current,
              color,
              width: lineWidth * 0.92,
              amplitude: _coreRadius * 0.12,
              seed: seed,
              branch: true,
            );
          }
        case ProjectileBehaviorProfile.split:
          _drawGlowLine(
            canvas,
            start,
            current,
            color,
            width: lineWidth * 0.9,
            alpha: 0.84,
          );
          _drawGlowLine(
            canvas,
            start,
            current.translate(_coreRadius * 0.14, -_coreRadius * 0.12),
            color,
            width: width * 0.44,
            alpha: 0.42,
          );
          _drawGlowLine(
            canvas,
            start,
            current.translate(_coreRadius * 0.14, _coreRadius * 0.12),
            color,
            width: width * 0.44,
            alpha: 0.42,
          );
        case ProjectileBehaviorProfile.explosion:
          if (shot.projectileType == ProjectileType.coreBomb) {
            _renderCoreBombTrail(
              canvas,
              start: start,
              current: current,
              color: color,
              width: lineWidth,
              seed: seed,
            );
          } else {
            _drawGlowLine(
              canvas,
              start,
              current,
              color,
              width: lineWidth,
              alpha: 0.84,
            );
          }
          canvas.drawCircle(
            current,
            _coreRadius * 0.22,
            Paint()
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
              ..color = color.withValues(alpha: 0.24),
          );
          canvas.drawCircle(
            current,
            _coreRadius * 0.16,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..color = color.withValues(alpha: 0.68),
          );
          canvas.drawPath(
            _hexPath(current, _coreRadius * 0.11),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6
              ..color = LightcorePalette.layer2.withValues(alpha: 0.72),
          );
        case ProjectileBehaviorProfile.wave:
          _drawGlowLine(
            canvas,
            start,
            current,
            color,
            width: lineWidth * 0.94,
            alpha: 0.82,
          );
          canvas.drawCircle(
            current,
            _coreRadius * (0.1 + (shot.progress * 0.06)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = color.withValues(alpha: 0.7),
          );
        case ProjectileBehaviorProfile.nova:
          _drawEnergyBolt(
            canvas,
            start,
            current,
            color,
            width: lineWidth,
            amplitude: _coreRadius * 0.08,
            seed: seed,
            branch: true,
          );
          canvas.drawCircle(
            current,
            _coreRadius * 0.18,
            Paint()
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
              ..color = color.withValues(alpha: 0.2),
          );
          for (final angle in <double>[0, math.pi / 3, (2 * math.pi) / 3]) {
            final offset = Offset(
              math.cos(angle) * _coreRadius * 0.18,
              math.sin(angle) * _coreRadius * 0.18,
            );
            _drawGlowLine(
              canvas,
              current - offset,
              current + offset,
              color,
              width: width * 0.24,
              alpha: 0.38,
            );
          }
      }

      _drawEnergyOrb(canvas, orbCenter, color, orbRadius, alpha: orbAlpha);
      if (!shot.layer2 && shot.secondaryAffinity != null) {
        _drawEnergyOrb(
          canvas,
          orbCenter.translate(_coreRadius * 0.05, -_coreRadius * 0.05),
          shot.secondaryAffinity!.color,
          _coreRadius * 0.04,
          alpha: 0.72,
        );
      }
      if (shot.critical) {
        canvas.drawPath(
          _hexPath(current, _coreRadius * 0.14),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = LightcorePalette.solar.withValues(alpha: 0.92),
        );
      }
    }
  }
}
