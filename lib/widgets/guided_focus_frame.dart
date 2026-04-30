import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/lightcore_palette.dart';

class GuidedFocusFrame extends StatefulWidget {
  const GuidedFocusFrame({
    super.key,
    required this.active,
    required this.tint,
    required this.child,
    this.radius = 18,
    this.label = 'QUEST',
    this.showLabel = false,
    this.padding,
    this.pulseSignal = 0,
    this.showTapCue = true,
    this.tapCueLabel,
  });

  final bool active;
  final Color tint;
  final Widget child;
  final double radius;
  final String label;
  final bool showLabel;
  final EdgeInsetsGeometry? padding;
  final int pulseSignal;
  final bool showTapCue;
  final String? tapCueLabel;

  @override
  State<GuidedFocusFrame> createState() => _GuidedFocusFrameState();
}

class _GuidedFocusFrameState extends State<GuidedFocusFrame>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _tapCueController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _tapCueController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1180),
    );
    _syncTapCue();
  }

  @override
  void didUpdateWidget(covariant GuidedFocusFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active ||
        widget.showTapCue != oldWidget.showTapCue) {
      _syncTapCue();
    }
    if (!widget.active && oldWidget.active) {
      _pulseController.reset();
      return;
    }
    if (widget.active &&
        widget.pulseSignal > 0 &&
        widget.pulseSignal != oldWidget.pulseSignal) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tapCueController.dispose();
    super.dispose();
  }

  void _syncTapCue() {
    if (widget.active && widget.showTapCue) {
      if (!_tapCueController.isAnimating) {
        _tapCueController.repeat();
      }
      return;
    }
    _tapCueController.stop();
    _tapCueController.reset();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _tapCueController]),
      builder: (context, _) {
        final pulseStrength = math.sin(_pulseController.value * math.pi);
        final pulseScale = 1 + (0.04 * pulseStrength);
        final glowStrength = 0.24 + (0.14 * pulseStrength);
        final tapCueProgress = _tapCueController.value;
        final padding = (widget.padding ?? const EdgeInsets.all(6)).resolve(
          Directionality.of(context),
        );

        return Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: [
            widget.child,
            Positioned(
              left: -padding.left,
              top: -padding.top,
              right: -padding.right,
              bottom: -padding.bottom,
              child: IgnorePointer(
                child: Transform.scale(
                  scale: pulseScale,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.radius),
                      border: Border.all(
                        color: widget.tint.withValues(alpha: 0.9),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.tint.withValues(alpha: glowStrength),
                          blurRadius: 18 + (18 * pulseStrength),
                          spreadRadius: 1 + (2 * pulseStrength),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showLabel)
              Positioned(
                top: -10 - padding.top,
                right: -6 - padding.right,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: LightcorePalette.panelRaised,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: widget.tint.withValues(alpha: 0.9),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_rounded, size: 11, color: widget.tint),
                        const SizedBox(width: 4),
                        Text(
                          widget.label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: widget.tint,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (widget.showTapCue)
              Positioned(
                right: -22 - padding.right,
                bottom: -26 - padding.bottom,
                child: IgnorePointer(
                  child: _TutorialTapCue(
                    tint: widget.tint,
                    progress: tapCueProgress,
                    label: widget.tapCueLabel,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TutorialTapCue extends StatelessWidget {
  const _TutorialTapCue({
    required this.tint,
    required this.progress,
    required this.label,
  });

  final Color tint;
  final double progress;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final ringProgress = Curves.easeOutCubic.transform(progress);
    final pressProgress = math
        .sin(progress * math.pi)
        .clamp(0.0, 1.0)
        .toDouble();
    final pressOffset = Offset(0, 5 * pressProgress);
    final iconScale = 1 - (0.08 * pressProgress);

    final cueLabel = label?.trim();
    final hasLabel = cueLabel != null && cueLabel.isNotEmpty;

    return SizedBox(
      width: hasLabel ? 164 : 50,
      height: 50,
      child: Stack(
        alignment: hasLabel ? Alignment.centerRight : Alignment.center,
        children: [
          if (hasLabel)
            Positioned(
              right: 38,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 116),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: LightcorePalette.panelRaised.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tint.withValues(alpha: 0.72)),
                  boxShadow: [
                    BoxShadow(
                      color: tint.withValues(alpha: 0.18),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  cueLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: LightcorePalette.mist,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
            ),
          Align(
            alignment: hasLabel ? Alignment.centerRight : Alignment.center,
            child: SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.52 * (1 - ringProgress),
                    child: Transform.scale(
                      scale: 0.58 + (0.74 * ringProgress),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tint.withValues(alpha: 0.88),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: pressOffset,
                    child: Transform.scale(
                      scale: iconScale,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tint,
                          border: Border.all(
                            color: LightcorePalette.mist.withValues(
                              alpha: 0.82,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: tint.withValues(alpha: 0.44),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: LightcorePalette.night.withValues(
                                alpha: 0.48,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Transform.rotate(
                          angle: -0.28,
                          child: const Icon(
                            Icons.touch_app_rounded,
                            color: LightcorePalette.night,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
