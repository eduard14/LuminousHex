import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/lightcore_palette.dart';
import 'aurora_panel.dart';

class LightcoreRunLoading extends StatefulWidget {
  const LightcoreRunLoading({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tint,
    this.icon = Icons.play_circle_fill_rounded,
    this.tips = const <String>[],
  });

  final String title;
  final String subtitle;
  final Color tint;
  final IconData icon;
  final List<String> tips;

  @override
  State<LightcoreRunLoading> createState() => _LightcoreRunLoadingState();
}

class _LightcoreRunLoadingState extends State<LightcoreRunLoading> {
  static const Duration _tipCycleDuration = Duration(milliseconds: 2400);

  Timer? _tipTimer;
  int _tipIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTipTimer();
  }

  @override
  void didUpdateWidget(covariant LightcoreRunLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tips != widget.tips) {
      _tipIndex = 0;
      _startTipTimer();
    }
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  void _startTipTimer() {
    _tipTimer?.cancel();
    if (widget.tips.length < 2) {
      return;
    }
    _tipTimer = Timer.periodic(_tipCycleDuration, (_) {
      if (!mounted) {
        return;
      }
      setState(() => _tipIndex = (_tipIndex + 1) % widget.tips.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tips = widget.tips;
    final currentTip = tips.isEmpty ? null : tips[_tipIndex % tips.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            LightcorePalette.night,
            LightcorePalette.abyss,
            Color.lerp(LightcorePalette.abyss, widget.tint, 0.18)!,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: AuroraPanel(
                tint: widget.tint,
                radius: 22,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 42, color: widget.tint),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: LightcorePalette.mist.withValues(alpha: 0.76),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(widget.tint),
                      ),
                    ),
                    if (currentTip != null) ...[
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: Text(
                          currentTip,
                          key: ValueKey<String>(currentTip),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: LightcorePalette.mist.withValues(
                                  alpha: 0.8,
                                ),
                                height: 1.28,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
