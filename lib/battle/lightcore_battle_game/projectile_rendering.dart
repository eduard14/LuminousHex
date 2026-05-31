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
      final currentOffset = Offset(current.x, current.y);
      final travelProgress = pulse.progress.clamp(0.0, 1.0).toDouble();
      final streakAlpha = (1 - travelProgress).clamp(0.0, 1.0).toDouble();
      final inboundStart = _pulseInboundStartPosition(pulse);
      if (inboundStart != null && travelProgress < 0.22) {
        final clickProgress = (travelProgress / 0.22).clamp(0.0, 1.0);
        final clickCenter = Offset(inboundStart.x, inboundStart.y);
        canvas.drawCircle(
          clickCenter,
          _slotRadius * (0.34 + (clickProgress * 0.5)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = LightcorePalette.mist.withValues(
              alpha: (0.72 * (1 - clickProgress) * _battleEffectAlphaScale),
            ),
        );
        canvas.drawPath(
          _hexPath(clickCenter, _slotRadius * (0.32 + clickProgress * 0.38)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..color = color.withValues(
              alpha: (0.82 * (1 - clickProgress) * _battleEffectAlphaScale),
            ),
        );
      }
      _drawGlowLine(
        canvas,
        currentOffset,
        Offset(_center.x, _center.y),
        color,
        width: math.max(2.0, _slotRadius * 0.045),
        alpha: 0.2 * streakAlpha * _battleEffectAlphaScale,
      );
      if (travelProgress > 0.74) {
        final burstProgress = ((travelProgress - 0.74) / 0.26)
            .clamp(0.0, 1.0)
            .toDouble();
        final burstFade = (1 - burstProgress) * _battleEffectAlphaScale;
        final burstCenter = Offset(_center.x, _center.y);
        canvas.drawCircle(
          burstCenter,
          _coreRadius * (0.26 + (burstProgress * 0.58)),
          Paint()
            ..shader =
                RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.2 * burstFade),
                    Colors.transparent,
                  ],
                ).createShader(
                  Rect.fromCircle(
                    center: burstCenter,
                    radius: _coreRadius * 0.9,
                  ),
                ),
        );
        canvas.drawPath(
          _hexPath(burstCenter, _coreRadius * (0.34 + burstProgress * 0.44)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = color.withValues(alpha: 0.72 * burstFade),
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
