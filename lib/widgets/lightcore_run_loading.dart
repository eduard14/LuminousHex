import 'dart:async';

import 'package:flutter/material.dart';

import '../models/lightcore_guide.dart';
import 'lightcore_loading_screen.dart';

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
    final activeTip = tips.isEmpty ? null : tips[_tipIndex % tips.length];
    return LightcoreLoadingScreen(
      title: widget.title,
      subtitle: widget.subtitle,
      statusLabel: 'Loading',
      accent: widget.tint,
      signalLabels: const ['SYNC', 'LOAD', 'READY'],
      tips: activeTip == null ? const <String>[] : <String>[activeTip],
      guide: LightcoreGuideProfile.lumo,
    );
  }
}
