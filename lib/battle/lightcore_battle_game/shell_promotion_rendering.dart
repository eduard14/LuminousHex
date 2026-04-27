part of '../lightcore_battle_game.dart';

extension LightcoreBattleGameShellPromotionRendering on LightcoreBattleGame {
  void _renderShellPromotion(Canvas canvas) {
    final presentation = _shellPromotion;
    if (presentation == null) {
      return;
    }

    final center = Offset(_center.x, _center.y);
    final collapseRaw =
        (_shellPromotionElapsed /
                LightcoreBattleGame._shellPromotionCollapseDuration)
            .clamp(0.0, 1.0)
            .toDouble();
    final whiteoutStart = LightcoreBattleGame._shellPromotionCollapseDuration;
    final whiteoutRaw =
        ((_shellPromotionElapsed - whiteoutStart) /
                LightcoreBattleGame._shellPromotionWhiteoutDuration)
            .clamp(0.0, 1.0)
            .toDouble();
    final revealStart =
        whiteoutStart +
        (LightcoreBattleGame._shellPromotionWhiteoutDuration * 0.72);
    final revealRaw =
        ((_shellPromotionElapsed - revealStart) /
                LightcoreBattleGame._shellPromotionRevealDuration)
            .clamp(0.0, 1.0)
            .toDouble();
    final collapse = Curves.easeInOutCubic.transform(collapseRaw);
    final whiteout = Curves.easeInOutCubic.transform(whiteoutRaw);
    final reveal = Curves.easeOutBack
        .transform(revealRaw)
        .clamp(0.0, 1.0)
        .toDouble();
    final sourceColor = _signatureColor(
      presentation.sourceCore.affinity,
      presentation.sourceCore.secondaryAffinity,
    );
    final targetColor = _signatureColor(
      presentation.targetCore.affinity,
      presentation.targetCore.secondaryAffinity,
    );
    final sourceFade = (1 - (whiteoutRaw * 0.9)).clamp(0.0, 1.0).toDouble();
    final ringFade = (1 - collapseRaw).clamp(0.0, 1.0).toDouble();

    canvas.drawCircle(
      center,
      _spawnRadiusVisual,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = LightcorePalette.stroke.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      _hexPath(center, _coreRadius * (1.24 - (collapse * 0.16))),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 + (whiteoutRaw * 1.4)
        ..color = Color.lerp(
          sourceColor,
          Colors.white,
          whiteoutRaw,
        )!.withValues(alpha: 0.3 + (whiteoutRaw * 0.36)),
    );

    if (ringFade > 0) {
      final boardPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = LightcorePalette.stroke.withValues(alpha: 0.22 * ringFade);
      for (var index = 0; index < _slotPositions.length; index++) {
        final current = Offset(
          _slotPositions[index].x,
          _slotPositions[index].y,
        );
        final nextIndex = (index + 1) % _slotPositions.length;
        final next = Offset(
          _slotPositions[nextIndex].x,
          _slotPositions[nextIndex].y,
        );
        canvas.drawLine(current, next, boardPaint);
      }
    }

    for (
      var index = 0;
      index < presentation.sourceSlots.length && index < _slotPositions.length;
      index += 1
    ) {
      final slot = presentation.sourceSlots[index];
      final start = Offset(_slotPositions[index].x, _slotPositions[index].y);
      final folded = Offset.lerp(start, center, collapse)!;
      final slotColor = _presentationSlotColor(slot);
      canvas.drawPath(
        _curvedLinkPath(
          Offset.lerp(start, center, collapse * 0.34)!,
          center,
          bend: 0.12 * (1 - collapse),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 + (collapse * 2.2)
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(
            slotColor,
            Colors.white,
            whiteoutRaw,
          )!.withValues(alpha: (0.2 + (collapse * 0.28)) * sourceFade),
      );
      _renderPromotionSourceTower(
        canvas,
        slot,
        center: folded,
        color: slotColor,
        collapse: collapse,
        whiteout: whiteoutRaw,
        alpha: sourceFade,
      );
    }

    final glowAlpha = (0.2 + (whiteout * 0.72) + (revealRaw * 0.24))
        .clamp(0.0, 1.0)
        .toDouble();
    final glowRadius =
        _coreRadius *
        (1.05 + (collapse * 0.55) + (whiteout * 0.82) + (revealRaw * 0.34));
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24)
        ..color = Colors.white.withValues(alpha: 0.34 * glowAlpha),
    );
    canvas.drawPath(
      _hexPath(center, _coreRadius * (0.58 + (whiteout * 0.62))),
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: 0.18 + (0.44 * whiteout)),
    );
    canvas.drawPath(
      _hexPath(center, _coreRadius * (1.0 + (whiteout * 0.46))),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..color = Colors.white.withValues(alpha: 0.34 + (0.4 * whiteout)),
    );

    if (revealRaw > 0) {
      _renderPromotionTargetCore(
        canvas,
        presentation,
        center: center,
        color: targetColor,
        reveal: reveal,
        revealRaw: revealRaw,
      );
    } else if (sourceFade > 0) {
      canvas.drawPath(
        _hexPath(center, _coreRadius * (0.92 - (collapse * 0.28))),
        Paint()
          ..style = PaintingStyle.fill
          ..color = sourceColor.withValues(alpha: 0.14 * sourceFade),
      );
      canvas.drawPath(
        _hexPath(center, _coreRadius * (0.26 + (collapse * 0.18))),
        Paint()
          ..style = PaintingStyle.fill
          ..color = Color.lerp(
            sourceColor,
            Colors.white,
            whiteoutRaw,
          )!.withValues(alpha: 0.84 * sourceFade),
      );
    }

    final labelAlpha = revealRaw <= 0
        ? 0.0
        : Curves.easeOut.transform(revealRaw).clamp(0.0, 1.0).toDouble();
    if (labelAlpha > 0) {
      _paintPromotionLabel(
        canvas,
        Offset(center.dx, center.dy + (_coreRadius * 1.92)),
        presentation.targetLayerLabel,
        color: Color.lerp(
          LightcorePalette.layer2,
          targetColor,
          0.34,
        )!.withValues(alpha: labelAlpha),
        size: _coreRadius * 0.22,
      );
    }
  }

  Color _presentationSlotColor(OuterTowerState slot) {
    if (slot.config != null) {
      return slot.config!.affinity.color;
    }
    if (slot.childAffinity != null) {
      return _signatureColor(slot.childAffinity!, slot.childSecondaryAffinity);
    }
    return LightcorePalette.layer2;
  }

  void _renderPromotionSourceTower(
    Canvas canvas,
    OuterTowerState slot, {
    required Offset center,
    required Color color,
    required double collapse,
    required double whiteout,
    required double alpha,
  }) {
    final foldedRadius = _slotRadius * (1 - (collapse * 0.36));
    final mixedColor = Color.lerp(color, Colors.white, whiteout)!;
    final hex = _hexPath(center, foldedRadius);
    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.fill
        ..color = mixedColor.withValues(alpha: 0.2 * alpha),
    );
    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 + (collapse * 1.4)
        ..color = mixedColor.withValues(alpha: 0.84 * alpha),
    );
    canvas.drawPath(
      _hexPath(center, foldedRadius * (0.22 + (collapse * 0.1))),
      Paint()..color = mixedColor.withValues(alpha: 0.82 * alpha),
    );
    if (alpha > 0.24) {
      _paintTowerTraitBadge(
        canvas,
        center,
        slot,
        tint: mixedColor,
        size: foldedRadius * 1.16,
        opacity: alpha,
      );
    }
  }

  void _renderPromotionTargetCore(
    Canvas canvas,
    ShellPromotionPresentation presentation, {
    required Offset center,
    required Color color,
    required double reveal,
    required double revealRaw,
  }) {
    final radius = _coreRadius * (0.62 + (reveal * 0.38));
    final haloAlpha = Curves.easeOut
        .transform(revealRaw)
        .clamp(0.0, 1.0)
        .toDouble();
    canvas.drawCircle(
      center,
      _coreRadius * (1.48 + (0.2 * revealRaw)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = LightcorePalette.layer2.withValues(alpha: 0.58 * haloAlpha),
    );
    canvas.drawPath(
      _hexPath(center, radius * 1.18),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.2 * haloAlpha),
    );
    canvas.drawPath(
      _hexPath(center, radius),
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.22 + (0.16 * haloAlpha)),
    );
    canvas.drawPath(
      _hexPath(center, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = color.withValues(alpha: 0.92 * haloAlpha),
    );
    canvas.drawPath(
      _hexPath(center, radius * 0.24),
      Paint()..color = color.withValues(alpha: 0.96 * haloAlpha),
    );
    _paintBadge(
      canvas,
      center,
      'L${presentation.targetCore.level}',
      color: LightcorePalette.mist.withValues(alpha: haloAlpha),
      size: 11,
    );
    _paintBadge(
      canvas,
      center.translate(0, radius * 0.48),
      'L${presentation.targetTier}',
      color: LightcorePalette.layer2.withValues(alpha: haloAlpha),
      size: 10,
    );
  }

  void _paintPromotionLabel(
    Canvas canvas,
    Offset center,
    String text, {
    required Color color,
    required double size,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _coreRadius * 4.8);
    painter.paint(
      canvas,
      center.translate(-painter.width / 2, -painter.height / 2),
    );
  }
}
