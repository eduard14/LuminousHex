part of '../lightcore_shell.dart';

enum _BattleResourceFlyoutKind { lumens, flux, scans }

class _BattleResourceFlyoutEntry {
  _BattleResourceFlyoutEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.controller,
    required this.sourceOffset,
  });

  final int id;
  final _BattleResourceFlyoutKind kind;
  final int amount;
  final AnimationController controller;
  final Offset sourceOffset;
}

class _BattleResourceFlyoutLayer extends StatefulWidget {
  const _BattleResourceFlyoutLayer({
    required this.controller,
    required this.compact,
  });

  final LightcoreController controller;
  final bool compact;

  @override
  State<_BattleResourceFlyoutLayer> createState() =>
      _BattleResourceFlyoutLayerState();
}

class _BattleResourceFlyoutLayerState extends State<_BattleResourceFlyoutLayer>
    with TickerProviderStateMixin {
  static const int _maxVisibleFlyouts = 8;
  static const Duration _flyoutDuration = Duration(milliseconds: 1250);

  final List<_BattleResourceFlyoutEntry> _entries = [];
  int _nextId = 0;
  late int _lastLumens;
  late int _lastFlux;
  late int _lastScans;

  @override
  void initState() {
    super.initState();
    _syncLastValues();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _BattleResourceFlyoutLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleControllerChanged);
    _clearEntries();
    _syncLastValues();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _clearEntries();
    super.dispose();
  }

  void _syncLastValues() {
    _lastLumens = widget.controller.lumens;
    _lastFlux = widget.controller.flux;
    _lastScans = widget.controller.enemyTickets;
  }

  void _handleControllerChanged() {
    final controller = widget.controller;
    final lumenDelta = controller.lumens - _lastLumens;
    final fluxDelta = controller.flux - _lastFlux;
    final scanDelta = controller.enemyTickets - _lastScans;
    _lastLumens = controller.lumens;
    _lastFlux = controller.flux;
    _lastScans = controller.enemyTickets;

    if (lumenDelta <= 0 && fluxDelta <= 0 && scanDelta <= 0) {
      return;
    }

    final pending = <({int amount, _BattleResourceFlyoutKind kind})>[
      if (fluxDelta > 0)
        (amount: fluxDelta, kind: _BattleResourceFlyoutKind.flux),
      if (scanDelta > 0)
        (amount: scanDelta, kind: _BattleResourceFlyoutKind.scans),
    ];
    for (var index = 0; index < pending.length; index++) {
      _addEntry(
        kind: pending[index].kind,
        amount: pending[index].amount,
        sourceOffset: Offset((index - 1) * 38.0, index.isEven ? -8 : 18),
      );
    }
  }

  void _addEntry({
    required _BattleResourceFlyoutKind kind,
    required int amount,
    required Offset sourceOffset,
  }) {
    final animationController = AnimationController(
      vsync: this,
      duration: _flyoutDuration,
    );
    final entry = _BattleResourceFlyoutEntry(
      id: _nextId++,
      kind: kind,
      amount: amount,
      controller: animationController,
      sourceOffset: sourceOffset,
    );
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _removeEntry(entry);
      }
    });

    setState(() {
      _entries.add(entry);
      while (_entries.length > _maxVisibleFlyouts) {
        final removed = _entries.removeAt(0);
        removed.controller.dispose();
      }
    });
    animationController.forward();
  }

  void _removeEntry(_BattleResourceFlyoutEntry entry) {
    if (!_entries.contains(entry)) {
      return;
    }
    if (mounted) {
      setState(() {
        _entries.remove(entry);
      });
    } else {
      _entries.remove(entry);
    }
    entry.controller.dispose();
  }

  void _clearEntries() {
    for (final entry in _entries) {
      entry.controller.dispose();
    }
    _entries.clear();
  }

  Offset _sourceOffset(Size size, _BattleResourceFlyoutEntry entry) {
    final center = Offset(size.width * 0.5, size.height * 0.45);
    return center + entry.sourceOffset;
  }

  Offset _targetOffset(_BattleResourceFlyoutKind kind) {
    final targetX = widget.compact ? 106.0 : 184.0;
    final rowStep = widget.compact ? 13.0 : 15.0;
    final lumenY = widget.compact ? 34.0 : 58.0;
    return switch (kind) {
      _BattleResourceFlyoutKind.lumens => Offset(targetX, lumenY),
      _BattleResourceFlyoutKind.flux => Offset(targetX, lumenY + rowStep),
      _BattleResourceFlyoutKind.scans => Offset(targetX, lumenY + rowStep * 2),
    };
  }

  double _entryOpacity(double value) {
    if (value < 0.14) {
      return (value / 0.14).clamp(0.0, 1.0);
    }
    if (value > 0.74) {
      return ((1 - value) / 0.26).clamp(0.0, 1.0);
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            key: const ValueKey<String>('battle-resource-flyouts'),
            children: [
              for (final entry in _entries)
                AnimatedBuilder(
                  key: ValueKey<int>(entry.id),
                  animation: entry.controller,
                  builder: (context, child) {
                    final raw = entry.controller.value;
                    final progress = Curves.easeInOutCubic.transform(raw);
                    final start = _sourceOffset(size, entry);
                    final end = _targetOffset(entry.kind);
                    final position = Offset.lerp(start, end, progress)!;
                    final arc = 24 * (1 - ((raw * 2) - 1).abs());
                    final opacity = _entryOpacity(raw);

                    return Positioned(
                      left: position.dx - 46,
                      top: position.dy - 16 - arc,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: 0.94 + (0.1 * opacity),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: _BattleResourceFlyoutChip(entry: entry),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BattleResourceFlyoutChip extends StatelessWidget {
  const _BattleResourceFlyoutChip({required this.entry});

  final _BattleResourceFlyoutEntry entry;

  @override
  Widget build(BuildContext context) {
    final tint = switch (entry.kind) {
      _BattleResourceFlyoutKind.lumens => LightcorePalette.solar,
      _BattleResourceFlyoutKind.flux => LightcorePalette.aether,
      _BattleResourceFlyoutKind.scans => LightcorePalette.scanGlow,
    };
    final icon = switch (entry.kind) {
      _BattleResourceFlyoutKind.lumens => Icons.monetization_on_rounded,
      _BattleResourceFlyoutKind.flux => Icons.diamond_rounded,
      _BattleResourceFlyoutKind.scans => LightcoreIcons.threatScan,
    };
    final label = switch (entry.kind) {
      _BattleResourceFlyoutKind.lumens => 'Lumens',
      _BattleResourceFlyoutKind.flux => LightcoreCurrencyLabels.flux,
      _BattleResourceFlyoutKind.scans => LightcoreCurrencyLabels.scansShort,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.56)),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.24),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: tint, size: 15),
            const SizedBox(width: 5),
            Text(
              '+${_formatMetricCount(entry.amount)} $label',
              maxLines: 1,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: tint,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
