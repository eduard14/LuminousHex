import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/lightcore_palette.dart';

class LightcoreTransitionSwitcher extends StatelessWidget {
  const LightcoreTransitionSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 520),
    this.reverseDuration,
    this.enterOffset = const Offset(0, 0.035),
    this.tint = LightcorePalette.aether,
    this.switchInCurve = Curves.easeOutCubic,
    this.switchOutCurve = Curves.easeInCubic,
  });

  final Widget child;
  final Duration duration;
  final Duration? reverseDuration;
  final Offset enterOffset;
  final Color tint;
  final Curve switchInCurve;
  final Curve switchOutCurve;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: reverseDuration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          children: [...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (child, animation) {
        return LightcoreScreenTransition(
          animation: animation,
          enterOffset: enterOffset,
          tint: tint,
          curve: switchInCurve,
          reverseCurve: switchOutCurve,
          child: child,
        );
      },
      child: child,
    );
  }
}

class LightcoreScreenTransition extends StatelessWidget {
  const LightcoreScreenTransition({
    super.key,
    required this.animation,
    required this.child,
    this.enterOffset = const Offset(0, 0.035),
    this.beginScale = 0.985,
    this.tint = LightcorePalette.aether,
    this.curve = Curves.easeOutCubic,
    this.reverseCurve = Curves.easeInCubic,
  });

  final Animation<double> animation;
  final Widget child;
  final Offset enterOffset;
  final double beginScale;
  final Color tint;
  final Curve curve;
  final Curve reverseCurve;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: curve,
      reverseCurve: reverseCurve,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: enterOffset,
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: beginScale, end: 1).animate(curved),
          child: AnimatedBuilder(
            animation: curved,
            child: child,
            builder: (context, child) {
              final sweepStrength = math.sin(curved.value * math.pi).abs();
              return Stack(
                fit: StackFit.passthrough,
                children: [
                  child!,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              tint.withValues(alpha: 0.12 * sweepStrength),
                              Colors.transparent,
                            ],
                            stops: const [0.08, 0.5, 0.92],
                            begin: Alignment(-1.2 + (curved.value * 0.7), -1),
                            end: Alignment(0.8 + (curved.value * 0.7), 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class LightcorePageTransitionsBuilder extends PageTransitionsBuilder {
  const LightcorePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return LightcoreScreenTransition(
      animation: animation,
      tint: LightcorePalette.aether,
      child: child,
    );
  }
}
