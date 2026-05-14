part of '../enemy_management_screen.dart';

class _EnemyPackRevealDialog extends StatefulWidget {
  const _EnemyPackRevealDialog({
    required this.pulls,
    required this.highestAvailableRarity,
    required this.secondHighestAvailableRarity,
  });

  final List<PackPullResult> pulls;
  final EnemyCardRarity highestAvailableRarity;
  final EnemyCardRarity? secondHighestAvailableRarity;

  @override
  State<_EnemyPackRevealDialog> createState() => _EnemyPackRevealDialogState();
}

enum _EnemyRevealBatchTier { basic, rare, jackpot }

enum _EnemyRevealItemTier { basic, rare, jackpot }

// Keep the result hidden long enough for anticipation to do the rewarding work.
const int _minimumScanAnticipationMilliseconds = 5000;

class _EnemyPackRevealTiming {
  const _EnemyPackRevealTiming({
    required this.batchTier,
    required this.hexResolutionMilliseconds,
    required this.levelHoldMilliseconds,
    required this.hexTransitionMilliseconds,
    required this.itemRevealTargetMilliseconds,
    required this.borderFastEndMilliseconds,
    required this.borderSlowEndMilliseconds,
    required this.borderSuspenseEndMilliseconds,
    required this.neutralPulseStartMilliseconds,
    required this.neutralPulseMilliseconds,
    required this.orangePulseStartMilliseconds,
    required this.orangePulseMilliseconds,
    required this.azurePulseStartMilliseconds,
    required this.azurePulseMilliseconds,
    required this.preAzureFreezeMilliseconds,
    required this.basicItemStaggerMilliseconds,
    required this.basicItemDropMilliseconds,
    required this.basicItemLingerMilliseconds,
    required this.rareWaveDelayMilliseconds,
    required this.rareItemStaggerMilliseconds,
    required this.rareItemDropMilliseconds,
    required this.rareIdentityHoldMilliseconds,
    required this.rareItemLingerMilliseconds,
    required this.jackpotWaveDelayMilliseconds,
    required this.jackpotItemStaggerMilliseconds,
    required this.jackpotItemDropMilliseconds,
    required this.jackpotIdentityHoldMilliseconds,
    required this.jackpotItemLingerMilliseconds,
    required this.jackpotDimMilliseconds,
  });

  factory _EnemyPackRevealTiming.forBatch({
    required _EnemyRevealBatchTier batchTier,
    required bool hasRareBuildup,
  }) {
    switch (batchTier) {
      case _EnemyRevealBatchTier.basic:
        return const _EnemyPackRevealTiming(
          batchTier: _EnemyRevealBatchTier.basic,
          // Phase 1 length before the item page transition begins.
          hexResolutionMilliseconds: _minimumScanAnticipationMilliseconds,
          // Result/level hold after the border snaps complete.
          levelHoldMilliseconds: 420,
          // Hex-to-item-page crossfade duration.
          hexTransitionMilliseconds: 420,
          // Minimum time the item page remains alive after it starts.
          itemRevealTargetMilliseconds: 1380,
          // Border pacing: fast to ~70%, slower to ~92%, suspense to ~99%.
          borderFastEndMilliseconds: 850,
          borderSlowEndMilliseconds: 3000,
          borderSuspenseEndMilliseconds: 4300,
          neutralPulseStartMilliseconds: 1400,
          neutralPulseMilliseconds: 360,
          orangePulseStartMilliseconds: <int>[],
          orangePulseMilliseconds: 0,
          azurePulseStartMilliseconds: null,
          azurePulseMilliseconds: 0,
          preAzureFreezeMilliseconds: 0,
          basicItemStaggerMilliseconds: 70,
          basicItemDropMilliseconds: 320,
          basicItemLingerMilliseconds: 320,
          rareWaveDelayMilliseconds: 160,
          rareItemStaggerMilliseconds: 115,
          rareItemDropMilliseconds: 300,
          rareIdentityHoldMilliseconds: 0,
          rareItemLingerMilliseconds: 920,
          jackpotWaveDelayMilliseconds: 300,
          jackpotItemStaggerMilliseconds: 130,
          jackpotItemDropMilliseconds: 320,
          jackpotIdentityHoldMilliseconds: 0,
          jackpotItemLingerMilliseconds: 2100,
          jackpotDimMilliseconds: 360,
        );
      case _EnemyRevealBatchTier.rare:
        return const _EnemyPackRevealTiming(
          batchTier: _EnemyRevealBatchTier.rare,
          hexResolutionMilliseconds: 6100,
          levelHoldMilliseconds: 520,
          hexTransitionMilliseconds: 440,
          itemRevealTargetMilliseconds: 1900,
          borderFastEndMilliseconds: 950,
          borderSlowEndMilliseconds: 3400,
          borderSuspenseEndMilliseconds: 5200,
          neutralPulseStartMilliseconds: 1200,
          neutralPulseMilliseconds: 380,
          // Scan breaths sit near the 80-90% suspense point.
          orangePulseStartMilliseconds: <int>[3150, 4300, 5150],
          orangePulseMilliseconds: 420,
          azurePulseStartMilliseconds: null,
          azurePulseMilliseconds: 0,
          preAzureFreezeMilliseconds: 0,
          basicItemStaggerMilliseconds: 64,
          basicItemDropMilliseconds: 300,
          basicItemLingerMilliseconds: 300,
          rareWaveDelayMilliseconds: 170,
          rareItemStaggerMilliseconds: 240,
          rareItemDropMilliseconds: 840,
          rareIdentityHoldMilliseconds: 1000,
          rareItemLingerMilliseconds: 1300,
          jackpotWaveDelayMilliseconds: 300,
          jackpotItemStaggerMilliseconds: 130,
          jackpotItemDropMilliseconds: 360,
          jackpotIdentityHoldMilliseconds: 0,
          jackpotItemLingerMilliseconds: 2100,
          jackpotDimMilliseconds: 360,
        );
      case _EnemyRevealBatchTier.jackpot:
        return _EnemyPackRevealTiming(
          batchTier: _EnemyRevealBatchTier.jackpot,
          hexResolutionMilliseconds: 7600,
          levelHoldMilliseconds: 620,
          hexTransitionMilliseconds: 500,
          itemRevealTargetMilliseconds: 3000,
          borderFastEndMilliseconds: 1200,
          borderSlowEndMilliseconds: 4100,
          borderSuspenseEndMilliseconds: 6600,
          neutralPulseStartMilliseconds: 1150,
          neutralPulseMilliseconds: 420,
          // Scan glow only appears when a rare-tier item is actually in the batch.
          orangePulseStartMilliseconds: hasRareBuildup
              ? const <int>[3250, 4700, 5750]
              : const <int>[],
          orangePulseMilliseconds: hasRareBuildup ? 440 : 0,
          azurePulseStartMilliseconds: 6500,
          azurePulseMilliseconds: 520,
          preAzureFreezeMilliseconds: 320,
          basicItemStaggerMilliseconds: 54,
          basicItemDropMilliseconds: 280,
          basicItemLingerMilliseconds: 280,
          rareWaveDelayMilliseconds: 210,
          rareItemStaggerMilliseconds: 240,
          rareItemDropMilliseconds: 780,
          rareIdentityHoldMilliseconds: 1000,
          rareItemLingerMilliseconds: 1200,
          jackpotWaveDelayMilliseconds: 390,
          jackpotItemStaggerMilliseconds: 260,
          jackpotItemDropMilliseconds: 980,
          jackpotIdentityHoldMilliseconds: 1000,
          jackpotItemLingerMilliseconds: 1900,
          jackpotDimMilliseconds: 520,
        );
    }
  }

  final _EnemyRevealBatchTier batchTier;
  // Phase 1: hex fill, suspense pulses, result snap, and post-result hold.
  final int hexResolutionMilliseconds;
  final int levelHoldMilliseconds;
  // Crossfade from the resolved hex into the item reveal page.
  final int hexTransitionMilliseconds;
  // Phase 2: minimum item page lifetime before the close action appears.
  final int itemRevealTargetMilliseconds;
  // Border trace waypoints: fast fill, slower fill, then 99% lock.
  final int borderFastEndMilliseconds;
  final int borderSlowEndMilliseconds;
  final int borderSuspenseEndMilliseconds;
  // Neutral, scan, and azure pulse windows inside the hex phase.
  final int neutralPulseStartMilliseconds;
  final int neutralPulseMilliseconds;
  final List<int> orangePulseStartMilliseconds;
  final int orangePulseMilliseconds;
  final int? azurePulseStartMilliseconds;
  final int azurePulseMilliseconds;
  final int preAzureFreezeMilliseconds;
  // Item wave cadence: stagger controls landing order, drop controls pop speed,
  // and linger controls how long each tier keeps its emphasis glow.
  final int basicItemStaggerMilliseconds;
  final int basicItemDropMilliseconds;
  final int basicItemLingerMilliseconds;
  final int rareWaveDelayMilliseconds;
  final int rareItemStaggerMilliseconds;
  final int rareItemDropMilliseconds;
  final int rareIdentityHoldMilliseconds;
  final int rareItemLingerMilliseconds;
  final int jackpotWaveDelayMilliseconds;
  final int jackpotItemStaggerMilliseconds;
  final int jackpotItemDropMilliseconds;
  final int jackpotIdentityHoldMilliseconds;
  final int jackpotItemLingerMilliseconds;
  final int jackpotDimMilliseconds;

  int get resultRevealStartMilliseconds =>
      hexResolutionMilliseconds - levelHoldMilliseconds;

  int? get preAzureFreezeStartMilliseconds {
    final azureStart = azurePulseStartMilliseconds;
    return azureStart == null ? null : azureStart - preAzureFreezeMilliseconds;
  }

  int dropMillisecondsFor(_EnemyRevealItemTier tier) {
    return switch (tier) {
      _EnemyRevealItemTier.basic => basicItemDropMilliseconds,
      _EnemyRevealItemTier.rare => rareItemDropMilliseconds,
      _EnemyRevealItemTier.jackpot => jackpotItemDropMilliseconds,
    };
  }

  int lingerMillisecondsFor(_EnemyRevealItemTier tier) {
    return switch (tier) {
      _EnemyRevealItemTier.basic => basicItemLingerMilliseconds,
      _EnemyRevealItemTier.rare => rareItemLingerMilliseconds,
      _EnemyRevealItemTier.jackpot => jackpotItemLingerMilliseconds,
    };
  }

  int identityHoldMillisecondsFor(_EnemyRevealItemTier tier) {
    return switch (tier) {
      _EnemyRevealItemTier.basic => 0,
      _EnemyRevealItemTier.rare => rareIdentityHoldMilliseconds,
      _EnemyRevealItemTier.jackpot => jackpotIdentityHoldMilliseconds,
    };
  }
}

class _ScheduledPackPullSummary {
  const _ScheduledPackPullSummary({
    required this.summary,
    required this.itemTier,
    required this.revealStartMilliseconds,
  });

  final _PackPullSummaryEntry summary;
  final _EnemyRevealItemTier itemTier;
  final int revealStartMilliseconds;
}

class _EnemyPackRevealDialogState extends State<_EnemyPackRevealDialog>
    with SingleTickerProviderStateMixin {
  static const Color _silverSignalColor = Color(0xFFCFDAE2);

  late final AnimationController _animationController;
  late final EnemyCardRarity _highestDrawnRarity;
  late final _EnemyRevealBatchTier _batchTier;
  late final _EnemyPackRevealTiming _timing;
  late final List<_ScheduledPackPullSummary> _scheduledSummaries;
  late final int _hexResolutionMilliseconds;
  late final int _revealMilliseconds;
  late final int _totalMilliseconds;

  @override
  void initState() {
    super.initState();
    _highestDrawnRarity = _resolveHighestPullRarity(widget.pulls);
    _batchTier = _resolveRevealBatchTier(
      pulls: widget.pulls,
      highestAvailableRarity: widget.highestAvailableRarity,
      secondHighestAvailableRarity: widget.secondHighestAvailableRarity,
    );
    _timing = _EnemyPackRevealTiming.forBatch(
      batchTier: _batchTier,
      hasRareBuildup: _batchContainsRareTierPulls(
        pulls: widget.pulls,
        highestAvailableRarity: widget.highestAvailableRarity,
        secondHighestAvailableRarity: widget.secondHighestAvailableRarity,
      ),
    );
    _scheduledSummaries = _schedulePackPullSummaries(
      pulls: widget.pulls,
      timing: _timing,
      highestAvailableRarity: widget.highestAvailableRarity,
      secondHighestAvailableRarity: widget.secondHighestAvailableRarity,
    );
    _hexResolutionMilliseconds = _timing.hexResolutionMilliseconds;
    _revealMilliseconds = _resolveItemRevealMilliseconds(
      scheduledSummaries: _scheduledSummaries,
      timing: _timing,
    );
    _totalMilliseconds =
        _hexResolutionMilliseconds +
        _timing.hexTransitionMilliseconds +
        _revealMilliseconds;
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalMilliseconds),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double get _elapsedMilliseconds =>
      _animationController.value * _totalMilliseconds;

  double _durationProgress(int startMilliseconds, int durationMilliseconds) {
    return ((_elapsedMilliseconds - startMilliseconds) / durationMilliseconds)
        .clamp(0.0, 1.0);
  }

  double _pulseProgress(int startMilliseconds, int durationMilliseconds) {
    if (durationMilliseconds <= 0) {
      return 0;
    }
    return _durationProgress(startMilliseconds, durationMilliseconds);
  }

  double get _neutralPulseProgress => _pulseProgress(
    _timing.neutralPulseStartMilliseconds,
    _timing.neutralPulseMilliseconds,
  );

  List<double> get _orangePulseProgresses => [
    for (final start in _timing.orangePulseStartMilliseconds)
      _pulseProgress(start, _timing.orangePulseMilliseconds),
  ];

  double get _azurePulseProgress {
    final start = _timing.azurePulseStartMilliseconds;
    return start == null
        ? 0
        : _pulseProgress(start, _timing.azurePulseMilliseconds);
  }

  bool get _orangePulseHasStarted {
    return _timing.orangePulseStartMilliseconds.any(
      (start) => _elapsedMilliseconds >= start,
    );
  }

  bool get _orangePulseIsActive {
    return _orangePulseProgresses.any(
      (progress) => progress > 0 && progress < 1,
    );
  }

  bool get _azurePulseHasStarted {
    final start = _timing.azurePulseStartMilliseconds;
    return start != null && _elapsedMilliseconds >= start;
  }

  bool get _azurePulseIsActive {
    final progress = _azurePulseProgress;
    return progress > 0 && progress < 1;
  }

  bool get _preAzureFreezeActive {
    final freezeStart = _timing.preAzureFreezeStartMilliseconds;
    final azureStart = _timing.azurePulseStartMilliseconds;
    if (freezeStart == null || azureStart == null) {
      return false;
    }
    return _elapsedMilliseconds >= freezeStart &&
        _elapsedMilliseconds < azureStart;
  }

  double _pulseVisibility(double progress) {
    if (progress <= 0 || progress >= 1) {
      return 0;
    }
    return math.sin(progress * math.pi).clamp(0.0, 1.0);
  }

  double get _hexResolutionProgress =>
      _durationProgress(0, _hexResolutionMilliseconds);

  double get _suspenseProgress {
    final suspenseStart = _timing.borderSlowEndMilliseconds;
    final suspenseDuration =
        _timing.resultRevealStartMilliseconds - suspenseStart;
    if (suspenseDuration <= 0) {
      return 0;
    }
    return _durationProgress(suspenseStart, suspenseDuration);
  }

  double get _borderProgress {
    final elapsed = math.min(
      _elapsedMilliseconds,
      _timing.resultRevealStartMilliseconds.toDouble(),
    );
    if (_elapsedMilliseconds >= _timing.resultRevealStartMilliseconds) {
      return 1;
    }

    double segmentProgress(int start, int end) {
      return ((elapsed - start) / (end - start)).clamp(0.0, 1.0).toDouble();
    }

    if (elapsed <= _timing.borderFastEndMilliseconds) {
      return 0.72 *
          Curves.easeOutCubic.transform(
            (elapsed / _timing.borderFastEndMilliseconds).clamp(0.0, 1.0),
          );
    }
    if (elapsed <= _timing.borderSlowEndMilliseconds) {
      final progress = Curves.easeOutCubic.transform(
        segmentProgress(
          _timing.borderFastEndMilliseconds,
          _timing.borderSlowEndMilliseconds,
        ),
      );
      return 0.72 + (0.2 * progress);
    }
    if (elapsed <= _timing.borderSuspenseEndMilliseconds) {
      final progress = Curves.easeInOutCubic.transform(
        segmentProgress(
          _timing.borderSlowEndMilliseconds,
          _timing.borderSuspenseEndMilliseconds,
        ),
      );
      return 0.92 + (0.07 * progress);
    }
    return 0.99;
  }

  double get _fillProgress => _borderProgress >= 1
      ? 1
      : math.min(0.99, _borderProgress * 1.02).toDouble();

  double get _hexFadeProgress => _durationProgress(
    _hexResolutionMilliseconds,
    _timing.hexTransitionMilliseconds,
  );

  double get _revealProgress => _durationProgress(
    _hexResolutionMilliseconds + _timing.hexTransitionMilliseconds,
    _revealMilliseconds,
  );

  double get _itemPageElapsedMilliseconds =>
      _elapsedMilliseconds -
      _hexResolutionMilliseconds -
      _timing.hexTransitionMilliseconds;

  Iterable<_ScheduledPackPullSummary> get _visibleSummaries =>
      _scheduledSummaries.where(
        (scheduled) =>
            _itemPageElapsedMilliseconds >= scheduled.revealStartMilliseconds,
      );

  bool get _isComplete =>
      _animationController.status == AnimationStatus.completed;

  int get _closeRemainingSeconds {
    if (_isComplete) {
      return 0;
    }
    final remainingMilliseconds = math.max(
      0.0,
      _totalMilliseconds - _elapsedMilliseconds,
    );
    return (remainingMilliseconds / 1000).ceil();
  }

  bool get _hexVisible => _hexFadeProgress < 1;

  double get _hexOpacity =>
      1 - Curves.easeInOutCubic.transform(_hexFadeProgress);

  Color get _accentColor {
    if (_azurePulseHasStarted) {
      final azureVisibility = _pulseVisibility(_azurePulseProgress);
      return Color.lerp(
        _orangePulseHasStarted ? LightcorePalette.scanGlow : _silverSignalColor,
        LightcorePalette.aether,
        0.78 + (0.22 * azureVisibility),
      )!;
    }
    if (_orangePulseHasStarted) {
      final orangeVisibility = _orangePulseProgresses.fold<double>(
        0,
        (best, progress) => math.max(best, _pulseVisibility(progress)),
      );
      return Color.lerp(
        _silverSignalColor,
        LightcorePalette.scanGlow,
        0.82 + (0.18 * orangeVisibility),
      )!;
    }
    return Color.lerp(
      _silverSignalColor,
      LightcorePalette.layer2,
      0.18 * _pulseVisibility(_neutralPulseProgress),
    )!;
  }

  String get _statusLabel {
    if (_isComplete) {
      return 'Threat Scans resolved';
    }
    if (_revealProgress > 0) {
      return 'Signatures resolving';
    }
    if (_hexFadeProgress > 0) {
      return 'Signatures opening';
    }
    if (_preAzureFreezeActive) {
      return 'Azure lock held';
    }
    if (_azurePulseIsActive) {
      return 'Azure pulse stacking';
    }
    if (_azurePulseHasStarted) {
      return 'Azure lock held';
    }
    if (_orangePulseIsActive) {
      return 'Scan pulse resolving';
    }
    if (_orangePulseHasStarted) {
      return 'Scan lock held';
    }
    if (_neutralPulseProgress > 0 && _neutralPulseProgress < 1) {
      return 'Silver pulse - no indication';
    }
    return 'Silver sweep - no indication';
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, _) {
            final glowProgress = _hexVisible
                ? (0.2 + (0.8 * _hexResolutionProgress)) * _hexOpacity
                : 0.0;
            final tensionProgress = Curves.easeInCubic.transform(
              _suspenseProgress,
            );
            final heartbeatPeriodMilliseconds = 520 - (260 * tensionProgress);
            final heartbeat = math
                .sin(
                  (_elapsedMilliseconds /
                          heartbeatPeriodMilliseconds.clamp(220, 520)) *
                      math.pi,
                )
                .abs();
            final idlePulseStrength =
                0.28 + (heartbeat * (0.18 + (0.38 * tensionProgress)));
            final visibleSummaries = _visibleSummaries.toList(growable: false);
            _ScheduledPackPullSummary? landingJackpot;
            ({Color tint, double progress, _EnemyRevealItemTier tier})?
            activeRarityWash;
            for (final scheduled in visibleSummaries) {
              final revealAge =
                  _itemPageElapsedMilliseconds -
                  scheduled.revealStartMilliseconds;
              if (scheduled.itemTier == _EnemyRevealItemTier.jackpot &&
                  revealAge >= 0 &&
                  revealAge < _timing.jackpotDimMilliseconds) {
                landingJackpot = scheduled;
                break;
              }
            }
            for (final scheduled in visibleSummaries) {
              final holdMilliseconds = _timing.identityHoldMillisecondsFor(
                scheduled.itemTier,
              );
              if (holdMilliseconds <= 0) {
                continue;
              }
              final revealAge =
                  _itemPageElapsedMilliseconds -
                  scheduled.revealStartMilliseconds;
              if (revealAge < 0 || revealAge >= holdMilliseconds) {
                continue;
              }
              activeRarityWash = (
                tint: _itemTierAccentColor(
                  scheduled.itemTier,
                  fallback: _rarityTint(scheduled.summary.config.rarity),
                ),
                progress: (revealAge / holdMilliseconds)
                    .clamp(0.0, 1.0)
                    .toDouble(),
                tier: scheduled.itemTier,
              );
            }
            return AuroraPanel(
              tint: _accentColor,
              radius: 30,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Threat Scans',
                              style: textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _statusLabel,
                        style: textTheme.bodyMedium?.copyWith(
                          color: _accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(
                          minHeight: 220,
                          maxHeight: 340,
                        ),
                        decoration: BoxDecoration(
                          color: LightcorePalette.night.withValues(alpha: 0.34),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _accentColor.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_hexVisible)
                              Opacity(
                                opacity: _hexOpacity,
                                child: Transform.scale(
                                  scale:
                                      1 + (0.018 * tensionProgress * heartbeat),
                                  child: Transform.rotate(
                                    angle:
                                        (1 -
                                            Curves.easeOut.transform(
                                              _hexResolutionProgress,
                                            )) *
                                        0.12,
                                    child: CustomPaint(
                                      size: const Size.square(220),
                                      painter: _AnticipationHexagonPainter(
                                        outlineProgress: _borderProgress,
                                        fillProgress: _fillProgress,
                                        glowProgress: glowProgress,
                                        idlePulseStrength: idlePulseStrength,
                                        tensionProgress: tensionProgress,
                                        silverPulseProgress:
                                            _neutralPulseProgress,
                                        orangePulseProgresses:
                                            _orangePulseProgresses,
                                        azurePulseProgress: _azurePulseProgress,
                                        orangeLayerVisible:
                                            _orangePulseHasStarted,
                                        azureLayerVisible:
                                            _azurePulseHasStarted,
                                        accentColor: _accentColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned.fill(
                              child: AnimatedOpacity(
                                opacity: visibleSummaries.isEmpty ? 0 : 1,
                                duration: const Duration(milliseconds: 180),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: SingleChildScrollView(
                                    child: Center(
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          for (final scheduled
                                              in visibleSummaries)
                                            _PackPullSummaryCard(
                                              summary: scheduled.summary,
                                              itemTier: scheduled.itemTier,
                                              timing: _timing,
                                              revealAgeMilliseconds:
                                                  _itemPageElapsedMilliseconds -
                                                  scheduled
                                                      .revealStartMilliseconds,
                                              dimmed:
                                                  landingJackpot != null &&
                                                  landingJackpot != scheduled,
                                              emphasized:
                                                  scheduled.itemTier !=
                                                      _EnemyRevealItemTier
                                                          .basic &&
                                                  (scheduled.itemTier ==
                                                          _EnemyRevealItemTier
                                                              .jackpot ||
                                                      scheduled
                                                              .summary
                                                              .config
                                                              .rarity ==
                                                          _highestDrawnRarity),
                                              animateNewReveal: true,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (activeRarityWash != null)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: _RarityRevealWash(
                                    key: ValueKey<String>(
                                      'rarity-wash-${activeRarityWash.tier.name}',
                                    ),
                                    tint: activeRarityWash.tint,
                                    progress: activeRarityWash.progress,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 132,
                            child: FilledButton.tonal(
                              onPressed: _isComplete ? _close : null,
                              child: Text(
                                _isComplete
                                    ? 'Close'
                                    : 'Close in ${_closeRemainingSeconds}s',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RarityRevealWash extends StatelessWidget {
  const _RarityRevealWash({
    super.key,
    required this.tint,
    required this.progress,
  });

  final Color tint;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RarityRevealWashPainter(
        tint: tint,
        progress: progress.clamp(0.0, 1.0).toDouble(),
      ),
    );
  }
}

class _RarityRevealWashPainter extends CustomPainter {
  const _RarityRevealWashPainter({required this.tint, required this.progress});

  final Color tint;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || size.isEmpty) {
      return;
    }
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(
      (size.width * size.width) + (size.height * size.height),
    );
    final expansion = Curves.easeOutCubic.transform(progress);
    final visibility = math.sin(progress * math.pi).clamp(0.0, 1.0);
    final radius = maxRadius * (0.08 + (0.92 * expansion));
    final washPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          LightcorePalette.layer2.withValues(alpha: 0.52 * visibility),
          LightcorePalette.layer2.withValues(alpha: 0.28 * visibility),
          tint.withValues(alpha: 0.2 * visibility),
          Colors.transparent,
        ],
        stops: const [0.0, 0.22, 0.56, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, washPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 + (4.4 * (1 - progress))
      ..color = LightcorePalette.layer2.withValues(alpha: 0.62 * visibility);
    canvas.drawCircle(center, radius * 0.68, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _RarityRevealWashPainter oldDelegate) {
    return tint != oldDelegate.tint || progress != oldDelegate.progress;
  }
}

class _AnticipationHexagonPainter extends CustomPainter {
  const _AnticipationHexagonPainter({
    required this.outlineProgress,
    required this.fillProgress,
    required this.glowProgress,
    required this.idlePulseStrength,
    required this.tensionProgress,
    required this.silverPulseProgress,
    required this.orangePulseProgresses,
    required this.azurePulseProgress,
    required this.orangeLayerVisible,
    required this.azureLayerVisible,
    required this.accentColor,
  });

  final double outlineProgress;
  final double fillProgress;
  final double glowProgress;
  final double idlePulseStrength;
  final double tensionProgress;
  final double silverPulseProgress;
  final List<double> orangePulseProgresses;
  final double azurePulseProgress;
  final bool orangeLayerVisible;
  final bool azureLayerVisible;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.36;
    final outerPath = _hexagonPath(center, radius);
    final innerPath = _hexagonPath(
      center,
      radius * (0.72 + (0.05 * fillProgress)),
    );
    final haloRadius = radius * 1.28;
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(
            alpha: (0.16 + (0.08 * tensionProgress)) * glowProgress,
          ),
          accentColor.withValues(
            alpha: (0.06 + (0.04 * tensionProgress)) * glowProgress,
          ),
          Colors.transparent,
        ],
        stops: const [0.0, 0.62, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: haloRadius));
    canvas.drawCircle(center, haloRadius, haloPaint);

    if (tensionProgress > 0) {
      final gatePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1 + (1.2 * idlePulseStrength)
        ..strokeJoin = StrokeJoin.round
        ..color = accentColor.withValues(
          alpha: (0.08 + (0.22 * idlePulseStrength)) * tensionProgress,
        );
      canvas.drawPath(
        _hexagonPath(center, radius * (1.06 + (0.04 * idlePulseStrength))),
        gatePaint,
      );
    }

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accentColor.withValues(alpha: 0.26 * fillProgress),
          accentColor.withValues(alpha: 0.04 * fillProgress),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(innerPath, fillPaint);

    void drawResolvedLayer(Color color, double alpha, double scale) {
      final layerPath = _hexagonPath(center, radius * scale);
      final layerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: alpha);
      canvas.drawPath(layerPath, layerPaint);
    }

    double pulseVisibility(double progress) {
      if (progress <= 0 || progress >= 1) {
        return 0;
      }
      return math.sin(progress * math.pi).clamp(0.0, 1.0);
    }

    void drawResolvePulse(
      Color color,
      double progress,
      double radiusBias, {
      double alphaScale = 1,
    }) {
      final visibility = pulseVisibility(progress);
      if (visibility <= 0) {
        return;
      }
      final expansion = Curves.easeOutCubic.transform(progress);
      final pulseRadius = radius * (0.92 + radiusBias + (0.54 * expansion));
      final pulsePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.4 - (3.8 * progress)
        ..color = color.withValues(alpha: 0.82 * visibility * alphaScale);
      canvas.drawCircle(center, pulseRadius, pulsePaint);

      final washRadius = radius * (1.0 + radiusBias + (0.46 * expansion));
      final washPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.2 * visibility * alphaScale),
            color.withValues(alpha: 0.06 * visibility * alphaScale),
            Colors.transparent,
          ],
          stops: const [0.0, 0.56, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: washRadius));
      canvas.drawCircle(center, washRadius, washPaint);
    }

    if (orangeLayerVisible) {
      drawResolvedLayer(
        LightcorePalette.scanGlow,
        azureLayerVisible ? 0.12 : 0.36,
        0.84,
      );
    }
    if (azureLayerVisible) {
      drawResolvedLayer(LightcorePalette.aether, 0.42, 0.96);
    }
    drawResolvePulse(LightcorePalette.layer2, silverPulseProgress, 0.0);
    for (final orangePulseProgress in orangePulseProgresses) {
      drawResolvePulse(
        LightcorePalette.scanGlow,
        orangePulseProgress,
        0.1,
        alphaScale: azureLayerVisible ? 0.28 : 1,
      );
    }
    drawResolvePulse(LightcorePalette.aether, azurePulseProgress, 0.2);

    final baseStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round
      ..color = LightcorePalette.stroke.withValues(alpha: 0.78);
    canvas.drawPath(outerPath, baseStroke);

    final trace = outerPath.computeMetrics().first.extractPath(
      0,
      outerPath.computeMetrics().first.length * outlineProgress,
    );
    final tracePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 + (1.4 * idlePulseStrength)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accentColor.withValues(alpha: 0.96);
    canvas.drawPath(trace, tracePaint);

    final innerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..color = accentColor.withValues(alpha: 0.42 + (0.18 * fillProgress));
    canvas.drawPath(innerPath, innerStroke);

    final corePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.48 + (0.22 * fillProgress));
    canvas.drawCircle(
      center,
      radius * 0.11 * (0.96 + (0.08 * idlePulseStrength)),
      corePaint,
    );
  }

  Path _hexagonPath(Offset center, double radius) {
    final path = Path();
    for (var index = 0; index < 6; index++) {
      final angle = (-math.pi / 2) + (((math.pi * 2) / 6) * index);
      final point = Offset(
        center.dx + (math.cos(angle) * radius),
        center.dy + (math.sin(angle) * radius),
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _AnticipationHexagonPainter oldDelegate) {
    return outlineProgress != oldDelegate.outlineProgress ||
        fillProgress != oldDelegate.fillProgress ||
        glowProgress != oldDelegate.glowProgress ||
        idlePulseStrength != oldDelegate.idlePulseStrength ||
        tensionProgress != oldDelegate.tensionProgress ||
        silverPulseProgress != oldDelegate.silverPulseProgress ||
        !listEquals(orangePulseProgresses, oldDelegate.orangePulseProgresses) ||
        azurePulseProgress != oldDelegate.azurePulseProgress ||
        orangeLayerVisible != oldDelegate.orangeLayerVisible ||
        azureLayerVisible != oldDelegate.azureLayerVisible ||
        accentColor != oldDelegate.accentColor;
  }
}

class _DialogStatPill extends StatelessWidget {
  const _DialogStatPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: LightcorePalette.stroke.withValues(alpha: 0.42),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: LightcorePalette.layer2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

int _compareThreatDisplayPower(EnemyCardState a, EnemyCardState b) {
  final rarityCompare = a.config.rarity.index.compareTo(b.config.rarity.index);
  if (rarityCompare != 0) {
    return rarityCompare;
  }
  final levelCompare = a.level.compareTo(b.level);
  if (levelCompare != 0) {
    return levelCompare;
  }
  return a.copies.compareTo(b.copies);
}
