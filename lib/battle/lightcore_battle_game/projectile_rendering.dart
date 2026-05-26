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
      final color = burst.layer2
          ? LightcorePalette.layer2
          : _signatureColor(burst.affinity, burst.secondaryAffinity);
      LightcoreProjectileFx.drawFireBurst(
        canvas,
        origin: origin,
        color: color,
        aimAngle: burst.aimAngle,
        projectileType: burst.projectileType,
        progress: progress,
        alpha: _battleEffectAlphaScale,
        unit: _coreRadius,
        seed: _fireBurstSeed(burst),
      );
      if (!burst.layer2 && burst.secondaryAffinity != null) {
        LightcoreProjectileFx.drawEnergyOrb(
          canvas,
          origin +
              LightcoreProjectileFx.angleOffset(
                burst.aimAngle,
                _coreRadius * 0.32,
              ),
          burst.secondaryAffinity!.color,
          _coreRadius * 0.05,
          alpha: 0.62 * _battleEffectAlphaScale,
        );
      }
    }
  }

  double _fireBurstSeed(_ShotFireBurst burst) {
    return (burst.id.hashCode * 0.0019) + (controller.elapsed * 9);
  }

  void _renderPulses(Canvas canvas) {
    for (final pulse in controller.pulses) {
      final start = _pulseStartPosition(pulse);
      final current = _pulsePosition(pulse);
      if (start == null || current == null) {
        continue;
      }
      final color = _signatureColor(pulse.affinity, pulse.secondaryAffinity);
      final startOffset = Offset(start.x, start.y);
      final currentOffset = Offset(current.x, current.y);
      if (pulse.progress < 0) {
        final anchor = _pulseSourceAnchor(pulse);
        if (anchor != null) {
          final orbitPath = _figureEightOrbitPath(pulse, anchor);
          canvas.drawPath(
            orbitPath,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5.2
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
              ..color = color.withValues(alpha: 0.12),
          );
          canvas.drawPath(
            orbitPath,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.7
              ..color = color.withValues(alpha: 0.34),
          );
          canvas.drawCircle(
            currentOffset,
            _slotRadius * 0.28,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = LightcorePalette.mist.withValues(alpha: 0.48),
          );
        }
      } else {
        final pulsePath = _pulseInboundPath(pulse, startOffset, currentOffset);

        canvas.drawPath(
          pulsePath,
          Paint()
            ..color = color.withValues(alpha: 0.18)
            ..strokeWidth = 8
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9)
            ..style = PaintingStyle.stroke,
        );
        canvas.drawPath(
          pulsePath,
          Paint()
            ..color = color.withValues(alpha: 0.42)
            ..strokeWidth = 3.4
            ..style = PaintingStyle.stroke,
        );
      }
      final shimmer =
          0.5 +
          (math.sin((controller.elapsed * 3.2) + pulse.id.hashCode) * 0.5);
      canvas.drawCircle(
        currentOffset,
        _slotRadius * (pulse.criticalBoosted ? 0.34 : 0.28),
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
          ..color = (pulse.criticalBoosted ? LightcorePalette.solar : color)
              .withValues(alpha: 0.52 + (shimmer * 0.18)),
      );
      canvas.drawCircle(
        currentOffset,
        _slotRadius * (0.18 + (shimmer * 0.035)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = LightcorePalette.mist.withValues(alpha: 0.5),
      );
      canvas.drawCircle(
        currentOffset,
        _slotRadius * 0.16,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  LightcorePalette.mist.withValues(alpha: 0.95),
                  color.withValues(alpha: 0.94),
                  color.withValues(alpha: 0.46),
                ],
              ).createShader(
                Rect.fromCircle(
                  center: currentOffset,
                  radius: _slotRadius * 0.2,
                ),
              ),
      );
      if (pulse.criticalBoosted) {
        canvas.drawPath(
          _hexPath(currentOffset, _slotRadius * 0.32),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = LightcorePalette.solar.withValues(alpha: 0.92),
        );
      }
      if (pulse.secondaryAffinity != null) {
        canvas.drawCircle(
          currentOffset.translate(_slotRadius * 0.08, -_slotRadius * 0.08),
          _slotRadius * 0.07,
          Paint()..color = pulse.secondaryAffinity!.color,
        );
      }
    }
  }

  Path _figureEightOrbitPath(EnergyPulseState pulse, Vector2 anchor) {
    final seed = pulse.id.hashCode.abs();
    final rotation = ((seed % 360) * math.pi / 180);
    final wide = pulse.sourceSlotIndex == null
        ? _coreRadius * 1.18
        : _slotRadius * 1.16;
    final tall = pulse.sourceSlotIndex == null
        ? _coreRadius * 0.58
        : _slotRadius * 0.62;
    final path = Path();
    for (var step = 0; step <= 80; step += 1) {
      final theta = (step / 80) * math.pi * 2;
      final point = _rotatedAround(
        anchor,
        math.sin(theta) * wide,
        math.sin(theta * 2) * tall,
        rotation,
      );
      if (step == 0) {
        path.moveTo(point.x, point.y);
      } else {
        path.lineTo(point.x, point.y);
      }
    }
    return path;
  }

  Path _pulseInboundPath(
    EnergyPulseState pulse,
    Offset fallbackStart,
    Offset current,
  ) {
    final startVector = _pulseInboundStartPosition(pulse);
    final start = startVector == null
        ? fallbackStart
        : Offset(startVector.x, startVector.y);
    final seed = pulse.id.hashCode.abs();
    final bend =
        ((seed.isEven ? 1 : -1) * 0.34) +
        (math.sin((pulse.progress * math.pi * 2) + seed) * 0.16);
    return _curvedLinkPath(start, current, bend: bend);
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
      var end = Offset(
        _center.x +
            math.cos(shot.aimAngle) * _modelRadiusToVisual(shot.travelRadius),
        _center.y +
            math.sin(shot.aimAngle) * _modelRadiusToVisual(shot.travelRadius),
      );
      if (_shotUsesBlueFocusLaser(shot)) {
        final target = _enemyForShotTarget(shot);
        if (target != null) {
          end = _enemyPosition(target);
        }
      }
      final current = _shotUsesBlueFocusLaser(shot)
          ? end
          : Offset.lerp(start, end, shot.progress.clamp(0.0, 1.0))!;
      final color = shot.layer2
          ? LightcorePalette.layer2
          : _signatureColor(shot.affinity, shot.secondaryAffinity);
      final seed =
          (controller.elapsed * 14.0) +
          (shot.progress * 9.0) +
          (shot.id.hashCode * 0.0017);
      final width = math.max(
        2.0,
        LightcoreProjectileFx.lineWidth(shot.projectileType, _coreRadius) *
            (shot.layer2 ? 1.12 : 1.0),
      );

      LightcoreProjectileFx.drawProjectileTrail(
        canvas,
        projectileType: shot.projectileType,
        start: start,
        end: end,
        current: current,
        color: color,
        width: width,
        seed: seed,
        alpha: _battleEffectAlphaScale * (shot.layer2 ? 0.96 : 0.88),
        unit: _coreRadius,
        progress: shot.progress,
      );

      if (!shot.layer2 && shot.secondaryAffinity != null) {
        LightcoreProjectileFx.drawEnergyOrb(
          canvas,
          current.translate(_coreRadius * 0.05, -_coreRadius * 0.05),
          shot.secondaryAffinity!.color,
          _coreRadius * 0.04,
          alpha: 0.72 * _battleEffectAlphaScale,
        );
      }
      if (shot.critical) {
        canvas.drawPath(
          _hexPath(current, _coreRadius * 0.14),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = LightcorePalette.solar.withValues(
              alpha: 0.92 * _battleEffectAlphaScale,
            ),
        );
      }
    }
  }
}
