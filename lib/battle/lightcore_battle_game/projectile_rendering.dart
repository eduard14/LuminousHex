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
      final start = _pulseSourceAnchor(pulse);
      if (start == null) {
        continue;
      }
      final color = _signatureColor(pulse.affinity, pulse.secondaryAffinity);
      final travelProgress = pulse.progress.clamp(0.0, 1.0).toDouble();
      final sourceOffset = Offset(start.x, start.y);
      final coreOffset = Offset(_center.x, _center.y);
      final chargeAlpha =
          (math.sin(travelProgress * math.pi) * _battleEffectAlphaScale)
              .clamp(0.0, 1.0)
              .toDouble();

      if (pulse.sourceSlotIndex != null) {
        _drawGlowLine(
          canvas,
          sourceOffset,
          coreOffset,
          color,
          width: math.max(1.5, _slotRadius * 0.026),
          alpha: 0.12 * chargeAlpha,
        );
        final sourceSparkProgress = (travelProgress / 0.28)
            .clamp(0.0, 1.0)
            .toDouble();
        if (sourceSparkProgress < 1) {
          final sourceFade =
              (1 - sourceSparkProgress) * _battleEffectAlphaScale;
          canvas.drawCircle(
            sourceOffset,
            _slotRadius * (0.13 + (sourceSparkProgress * 0.24)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = color.withValues(alpha: 0.34 * sourceFade),
          );
        }
      }

      if (travelProgress > 0.74) {
        final burstProgress = ((travelProgress - 0.74) / 0.26)
            .clamp(0.0, 1.0)
            .toDouble();
        final burstFade = (1 - burstProgress) * _battleEffectAlphaScale;
        canvas.drawCircle(
          coreOffset,
          _coreRadius * (0.16 + (burstProgress * 0.28)),
          Paint()
            ..shader =
                RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.12 * burstFade),
                    Colors.transparent,
                  ],
                ).createShader(
                  Rect.fromCircle(
                    center: coreOffset,
                    radius: _coreRadius * 0.48,
                  ),
                ),
        );
        canvas.drawPath(
          _hexPath(coreOffset, _coreRadius * (0.26 + burstProgress * 0.22)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = color.withValues(alpha: 0.36 * burstFade),
        );
      }
      if (pulse.criticalBoosted) {
        canvas.drawPath(
          _hexPath(coreOffset, _coreRadius * (0.34 + (0.08 * chargeAlpha))),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.7
            ..color = LightcorePalette.solar.withValues(
              alpha: 0.36 * chargeAlpha,
            ),
        );
      }
      if (pulse.secondaryAffinity != null) {
        canvas.drawCircle(
          coreOffset.translate(_coreRadius * 0.18, -_coreRadius * 0.18),
          _coreRadius * 0.035,
          Paint()
            ..color = pulse.secondaryAffinity!.color.withValues(
              alpha: 0.42 * chargeAlpha,
            ),
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
