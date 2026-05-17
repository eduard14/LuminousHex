part of '../lightcore_battle_game.dart';

extension _LightcoreBattleGameEnemyRendering on LightcoreBattleGame {
  void _renderEnemies(Canvas canvas) {
    for (final enemy in controller.enemies) {
      final position = _enemyPosition(enemy);
      final revealProgress = _enemyRevealProgress(enemy);
      if (revealProgress <= 0) {
        continue;
      }
      final radius = _enemyRadius(enemy) * (0.82 + (0.18 * revealProgress));
      final color = enemy.config.affinity.color;
      final isBoss = enemy.config.isBoss;
      final healthRatio = (enemy.health / enemy.maxHealth).clamp(0.08, 1.0);
      final spawnFadeRemaining = 1 - revealProgress;
      final spawnPulse = revealProgress < 1
          ? 0.5 +
                (math.sin(
                      (controller.elapsed * 8.4) + (enemy.id.hashCode * 0.0011),
                    ) *
                    0.5)
          : 0.0;

      if (revealProgress < 1) {
        canvas.drawCircle(
          position,
          radius * (1.38 + (spawnPulse * 0.34)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = color.withValues(
              alpha: spawnFadeRemaining * (0.18 + (spawnPulse * 0.1)),
            ),
        );
        if (!_lowPowerBattleEffects) {
          canvas.drawCircle(
            position,
            radius * (0.9 + (spawnPulse * 0.18)),
            Paint()
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
              ..color = color.withValues(
                alpha:
                    revealProgress *
                    spawnFadeRemaining *
                    0.18 *
                    _battleGlowAlphaScale,
              ),
          );
        }
      }

      if (!_lowPowerBattleEffects) {
        canvas.drawCircle(
          position,
          radius * 1.18,
          Paint()
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
            ..color = (isBoss ? LightcorePalette.solar : color).withValues(
              alpha:
                  (isBoss ? 0.24 : 0.18) *
                  revealProgress *
                  _battleGlowAlphaScale,
            ),
        );
      }
      if (isBoss) {
        canvas.drawPath(
          _hexPath(position, radius * 1.44),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..color = LightcorePalette.solar.withValues(
              alpha: 0.78 * revealProgress,
            ),
        );
      }
      if (controller.focusedEnemyId == enemy.id) {
        final focusPulse =
            0.5 + (math.sin((controller.elapsed * 9.0) + radius) * 0.5);
        canvas.drawCircle(
          position,
          radius * (1.72 + (focusPulse * 0.12)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.8
            ..color = LightcorePalette.aether.withValues(
              alpha: 0.82 * revealProgress,
            ),
        );
        canvas.drawCircle(
          position,
          radius * (1.36 + (focusPulse * 0.08)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = LightcorePalette.mist.withValues(
              alpha: 0.54 * revealProgress,
            ),
        );
      }
      canvas.drawCircle(
        position,
        radius,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: 0.9 * revealProgress),
      );
      canvas.drawCircle(
        position,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isBoss ? 3 : 2
          ..color = (isBoss ? LightcorePalette.solar : LightcorePalette.mist)
              .withValues(alpha: 0.42 * revealProgress),
      );
      _renderEnemyFace(
        canvas,
        enemy,
        position,
        radius,
        revealProgress: revealProgress,
      );

      canvas.drawArc(
        Rect.fromCircle(center: position, radius: radius * 1.24),
        -math.pi / 2,
        math.pi * 2 * healthRatio,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isBoss ? 4.6 : 3
          ..strokeCap = StrokeCap.round
          ..color = (isBoss ? LightcorePalette.layer2 : LightcorePalette.mist)
              .withValues(alpha: 0.75 * revealProgress),
      );

      if (enemy.burnRemaining > 0) {
        final emberCount = _qualityScaledCount(3, balanced: 2, lowPower: 1);
        for (var index = 0; index < emberCount; index++) {
          final angle =
              (controller.elapsed * 2.4) +
              (((math.pi * 2) / emberCount) * index) -
              (math.pi / 2);
          final emberCenter = Offset(
            position.dx + math.cos(angle) * (radius * 0.16),
            position.dy + (radius * 0.06) + math.sin(angle) * (radius * 0.12),
          );
          _drawEnergyOrb(
            canvas,
            emberCenter,
            index == 1 ? LightcorePalette.flare : LightcorePalette.ember,
            radius * (0.1 + (index * 0.015)),
            alpha: 0.68 * revealProgress,
          );
        }
      }
      if (enemy.bountyRemaining > 0) {
        canvas.drawPath(
          _hexPath(position.translate(0, -radius * 0.16), radius * 0.16),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.7
            ..color = LightcorePalette.solar.withValues(
              alpha: 0.9 * revealProgress,
            ),
        );
      }
      if (enemy.shockRemaining > 0) {
        if (enemy.slowRemaining > 0) {
          canvas.drawCircle(
            position,
            radius * 0.82,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8
              ..color = LightcorePalette.aether.withValues(
                alpha: 0.38 * revealProgress,
              ),
          );
          canvas.drawCircle(
            position,
            radius * 0.64,
            Paint()
              ..color = LightcorePalette.aether.withValues(
                alpha: 0.08 * revealProgress,
              ),
          );
        }
        _drawEnergyBolt(
          canvas,
          position.translate(-radius * 0.44, -radius * 0.06),
          position.translate(radius * 0.38, radius * 0.12),
          LightcorePalette.aether,
          width: 1.7,
          amplitude: radius * 0.12,
          seed:
              (controller.elapsed * 20.0) +
              (enemy.id.hashCode * 0.0013) +
              enemy.shockRemaining,
          alpha: 0.74 * revealProgress,
        );
        if (!_lowPowerBattleEffects) {
          final orbitAngle =
              (controller.elapsed * 6.2) + (enemy.id.hashCode * 0.003);
          final sparkCenter = Offset(
            position.dx + math.cos(orbitAngle) * (radius * 0.4),
            position.dy + math.sin(orbitAngle) * (radius * 0.34),
          );
          _drawEnergyOrb(
            canvas,
            sparkCenter,
            LightcorePalette.layer2,
            radius * 0.08,
            alpha: 0.6 * revealProgress,
          );
        }
      }
      if (enemy.slowRemaining > 0) {
        canvas.drawPath(
          _hexPath(position, radius * 0.32),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = LightcorePalette.aether.withValues(
              alpha: 0.6 * revealProgress,
            ),
        );
      }
    }
  }

  void _renderEnemyFace(
    Canvas canvas,
    EnemyState enemy,
    Offset position,
    double radius, {
    required double revealProgress,
  }) {
    if (radius < 5 || revealProgress <= 0) {
      return;
    }

    final hitProgress = _enemyHitFaceProgress(enemy.id);
    final hitEase = Curves.easeOutCubic.transform(hitProgress);
    final bodyColor = enemy.config.affinity.color;
    final bodyIsLight = bodyColor.computeLuminance() > 0.52;
    final usesDarkEyeFill = enemy.config.affinity == PrototypeAffinity.neutral;
    final faceAlpha = revealProgress.clamp(0.0, 1.0).toDouble();
    final inkColor = bodyIsLight
        ? LightcorePalette.abyss
        : LightcorePalette.mist;
    final eyeFill = usesDarkEyeFill
        ? LightcorePalette.abyss
        : LightcorePalette.layer2;
    final pupilFill = LightcorePalette.abyss;
    final browColor = Color.lerp(
      inkColor,
      LightcorePalette.warning,
      0.18 + (hitEase * 0.2),
    )!;
    final hitJitterSeed =
        (controller.elapsed * 42) + (enemy.id.hashCode * 0.0017);
    final faceCenter = position.translate(
      math.sin(hitJitterSeed) * radius * 0.035 * hitEase,
      math.cos(hitJitterSeed * 0.7) * radius * 0.025 * hitEase,
    );
    final eyeWidth =
        radius * (usesDarkEyeFill ? 0.26 : 0.31) * (1 + (hitEase * 0.08));
    final eyeHeight =
        radius * (usesDarkEyeFill ? 0.33 : 0.38) * (1 - (hitEase * 0.38));
    final leftEye = faceCenter.translate(-radius * 0.28, -radius * 0.15);
    final rightEye = faceCenter.translate(radius * 0.28, -radius * 0.15);
    final eyePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = eyeFill.withValues(alpha: 0.96 * faceAlpha);
    final eyeStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, radius * 0.035)
      ..color = inkColor.withValues(
        alpha: (usesDarkEyeFill ? 0.16 : 0.42) * faceAlpha,
      );
    final gazeSeed = (controller.elapsed * 1.3) + (enemy.id.hashCode * 0.002);
    final gaze = Offset(
      math.sin(gazeSeed) * radius * 0.025,
      math.cos(gazeSeed * 1.4) * radius * 0.018,
    );

    void drawEye(Offset center, {required bool left}) {
      final rect = Rect.fromCenter(
        center: center,
        width: eyeWidth,
        height: math.max(radius * 0.08, eyeHeight),
      );
      canvas.drawOval(rect, eyePaint);
      canvas.drawOval(rect, eyeStrokePaint);
      if (usesDarkEyeFill) {
        final highlight = center.translate(
          eyeWidth * (left ? 0.14 : -0.1),
          -eyeHeight * 0.16,
        );
        canvas.drawCircle(
          highlight,
          radius * 0.043,
          Paint()..color = LightcorePalette.layer2.withValues(alpha: faceAlpha),
        );
      } else {
        final pupilCenter = center + gaze.translate(0, hitEase * radius * 0.02);
        canvas.drawCircle(
          pupilCenter,
          radius * (0.075 + (hitEase * 0.012)),
          Paint()..color = pupilFill.withValues(alpha: 0.95 * faceAlpha),
        );
        canvas.drawCircle(
          pupilCenter.translate(radius * 0.028, -radius * 0.032),
          radius * 0.025,
          Paint()..color = LightcorePalette.layer2.withValues(alpha: faceAlpha),
        );
      }
    }

    drawEye(leftEye, left: true);
    drawEye(rightEye, left: false);

    final browPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.3, radius * (0.065 + (hitEase * 0.018)))
      ..strokeCap = StrokeCap.round
      ..color = browColor.withValues(alpha: 0.9 * faceAlpha);
    canvas.drawLine(
      faceCenter.translate(-radius * 0.48, -radius * (0.45 + hitEase * 0.05)),
      faceCenter.translate(-radius * 0.12, -radius * (0.31 - hitEase * 0.02)),
      browPaint,
    );
    canvas.drawLine(
      faceCenter.translate(radius * 0.12, -radius * (0.31 - hitEase * 0.02)),
      faceCenter.translate(radius * 0.48, -radius * (0.45 + hitEase * 0.05)),
      browPaint,
    );

    final mouthStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.1, radius * 0.05)
      ..strokeCap = StrokeCap.round
      ..color = inkColor.withValues(alpha: 0.88 * faceAlpha);
    if (hitEase > 0.04) {
      final mouthRect = Rect.fromCenter(
        center: faceCenter.translate(0, radius * (0.28 + hitEase * 0.03)),
        width: radius * (0.28 + hitEase * 0.12),
        height: radius * (0.16 + hitEase * 0.18),
      );
      canvas.drawOval(
        mouthRect,
        Paint()
          ..color =
              (bodyIsLight ? LightcorePalette.abyss : LightcorePalette.warning)
                  .withValues(alpha: 0.86 * faceAlpha),
      );
      canvas.drawOval(mouthRect, mouthStroke);
      canvas.drawLine(
        faceCenter.translate(-radius * 0.46, radius * 0.11),
        faceCenter.translate(-radius * 0.36, radius * 0.2),
        Paint()
          ..strokeWidth = math.max(1.0, radius * 0.035)
          ..strokeCap = StrokeCap.round
          ..color = LightcorePalette.warning.withValues(
            alpha: hitEase * faceAlpha,
          ),
      );
      canvas.drawLine(
        faceCenter.translate(radius * 0.46, radius * 0.11),
        faceCenter.translate(radius * 0.36, radius * 0.2),
        Paint()
          ..strokeWidth = math.max(1.0, radius * 0.035)
          ..strokeCap = StrokeCap.round
          ..color = LightcorePalette.warning.withValues(
            alpha: hitEase * faceAlpha,
          ),
      );
      return;
    }

    final mouthPath = Path()
      ..moveTo(faceCenter.dx - (radius * 0.24), faceCenter.dy + (radius * 0.3))
      ..quadraticBezierTo(
        faceCenter.dx,
        faceCenter.dy + (radius * 0.16),
        faceCenter.dx + (radius * 0.24),
        faceCenter.dy + (radius * 0.3),
      );
    canvas.drawPath(mouthPath, mouthStroke);
  }

  double _enemyHitFaceProgress(String enemyId) {
    final remaining = _enemyHitFaceRemaining[enemyId] ?? 0;
    return (remaining / LightcoreBattleGame._enemyHitFaceDuration)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  void _renderTutorialSlotGuides(Canvas canvas) {
    for (var index = 0; index < _slotPositions.length; index++) {
      if (!controller.tutorialHighlightsBattleSlot(index)) {
        continue;
      }
      _renderGuidePulse(
        canvas,
        Offset(_slotPositions[index].x, _slotPositions[index].y),
        radius: _slotRadius * 1.2,
        tint: LightcorePalette.quest,
        tapCueLabel: controller.tutorialBattleSlotGuideLabel(index),
      );
    }
  }

  void _renderTutorialEnemyGuide(Canvas canvas) {
    final targetId = controller.tutorialHighlightedEnemyId;
    if (targetId == null) {
      return;
    }
    for (final enemy in controller.enemies) {
      if (enemy.id != targetId) {
        continue;
      }
      _renderGuidePulse(
        canvas,
        _enemyPosition(enemy),
        radius: _enemyRadius(enemy) * 1.78,
        tint: LightcorePalette.warning,
        showTapCue: false,
      );
      break;
    }
  }
}
