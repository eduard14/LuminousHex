import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../models/lightcore_state.dart';
import '../models/lightcore_types.dart';
import '../services/lightcore_audio.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/lightcore_projectile_fx.dart';
import '../widgets/tower_level_hex_badge.dart';
import 'shell_promotion_presentation.dart';

part 'lightcore_battle_game/projectile_rendering.dart';
part 'lightcore_battle_game/impact_rendering.dart';
part 'lightcore_battle_game/enemy_rendering.dart';
part 'lightcore_battle_game/shot_fire_burst_models.dart';
part 'lightcore_battle_game/shell_promotion_rendering.dart';
part 'lightcore_battle_game/arena_slot_rendering.dart';
part 'lightcore_battle_game/transient_visuals.dart';
part 'lightcore_battle_game/core_rendering.dart';
part 'lightcore_battle_game/drawing_helpers.dart';

class LightcoreBattleGame extends FlameGame with ScaleDetector {
  LightcoreBattleGame({
    required this.controller,
    required this.onCenterTap,
    required this.onSlotTap,
    required this.onBackgroundTap,
    this.enableBattlefieldTaps = true,
    this.showTutorialGuides = true,
    this.showArenaSlots = true,
    this.showFoldedShellSlots = true,
  });

  final LightcoreController controller;
  final VoidCallback onCenterTap;
  final ValueChanged<int> onSlotTap;
  final VoidCallback onBackgroundTap;
  final bool enableBattlefieldTaps;
  final bool showTutorialGuides;
  final bool showArenaSlots;
  final bool showFoldedShellSlots;

  static const double _fixedStep = 1 / 60;
  static const double _hexChargePopDuration = 0.26;
  static const double _slotBuildBurstDuration = 0.68;
  static const double _slotFuseBurstDuration = 0.52;
  static const double _shotFireBurstDuration = 0.28;
  static const double _enemyHitFaceDuration = 0.28;
  static const double _enemySpawnRevealDuration = 5.0;
  static const double _coreDamageShakeDuration = 0.34;
  static const double _payloadMaxOrbitCount = 4.0;
  static const double _payloadOrbitDurationSeconds = 8.0;
  static const double _payloadTapRadiusScale = 1.32;
  static const double _tutorialPayloadTapRadiusScale = 1.72;
  static const double shellPromotionStatsDelay = 3.35;
  static const double _shellPromotionCollapseDuration = 1.15;
  static const double _shellPromotionWhiteoutDuration = 0.72;
  static const double _shellPromotionRevealDuration = 0.78;
  static const double _minViewScale = 0.72;
  static const double _maxViewScale = 1.22;

  double _accumulator = 0;
  double _viewScale = 1.0;
  ShellPromotionPresentation? _shellPromotion;
  double _shellPromotionElapsed = 0;
  String? _slotVisualLayerId;
  String? _coreVisualLayerId;
  List<double> _previousSlotCharge = <double>[];
  List<double> _slotHexChargePopRemaining = <double>[];
  List<bool> _previousSlotFabricating = <bool>[];
  List<bool> _previousSlotBuilt = <bool>[];
  List<int> _previousSlotChildBuiltCount = <int>[];
  List<double> _slotBuildBurstRemaining = <double>[];
  List<double> _slotFuseBurstRemaining = <double>[];
  Set<String> _knownCoreShotIds = <String>{};
  Set<String> _knownShotIds = <String>{};
  Set<String> _knownImpactIds = <String>{};
  Set<String> _knownEnemyIds = <String>{};
  Map<String, double> _previousEnemyHealth = <String, double>{};
  Map<String, double> _enemyHitFaceRemaining = <String, double>{};
  List<_ShotFireBurst> _shotFireBursts = <_ShotFireBurst>[];
  int _previousCoreFireSequence = 0;
  int _previousCoreDamageSequence = 0;
  int _knownLevelUpRadianceSequence = 0;
  double _coreHexFirePopRemaining = 0;
  double _screenShakeRemaining = 0;
  double _screenShakeAmplitude = 0;
  Vector2 _screenShakeOffset = Vector2.zero();
  Vector2 _baseCenter = Vector2.zero();
  Vector2 _panOffset = Vector2.zero();
  Vector2? _lastGestureFocalPoint;
  double _lastGestureScaleSignal = 1.0;
  int _gesturePointerCount = 0;
  String? _draggedPulseId;
  bool _draggedPulseCrossedSourceTower = false;
  final Map<String, Vector2> _pulseInboundStartPositions = <String, Vector2>{};

  Vector2 _center = Vector2.zero();
  List<Vector2> _slotPositions = <Vector2>[];
  double _hexRadius = 0;
  double _slotRadius = 0;
  double _coreRadius = 0;
  double _spawnRadiusVisual = 0;
  double _relayImpactRadiusVisual = 0;
  bool _layoutReady = false;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _recomputeLayout();
  }

  double get viewScale => _viewScale;
  Vector2 get viewPanOffset => _panOffset.clone();
  double get screenShakeRemaining => _screenShakeRemaining;
  Vector2 get screenShakeOffset => _screenShakeOffset.clone();
  int get debugActiveShotFireBurstCount => _shotFireBursts.length;
  List<ProjectileType> get debugActiveShotFireBurstTypes => _shotFireBursts
      .map((burst) => burst.projectileType)
      .toList(growable: false);
  Map<String, double> get debugEnemyHitFaceRemaining =>
      Map.unmodifiable(_enemyHitFaceRemaining);
  bool get isShellPromotionAnimating => _shellPromotion != null;
  double get debugShellPromotionElapsed => _shellPromotionElapsed;
  Vector2? debugPulsePosition(String pulseId) => _pulsePositionForId(pulseId);

  bool get _lowPowerBattleEffects =>
      controller.graphicsQuality == LightcoreGraphicsQuality.lowPower;

  double get _battleEffectAlphaScale => switch (controller.graphicsQuality) {
    LightcoreGraphicsQuality.high => 1.0,
    LightcoreGraphicsQuality.balanced => 0.78,
    LightcoreGraphicsQuality.lowPower => 0.52,
  };

  double get _battleGlowAlphaScale => switch (controller.graphicsQuality) {
    LightcoreGraphicsQuality.high => 1.0,
    LightcoreGraphicsQuality.balanced => 0.62,
    LightcoreGraphicsQuality.lowPower => 0.0,
  };

  int _qualityScaledCount(int high, {int? balanced, int? lowPower}) {
    return switch (controller.graphicsQuality) {
      LightcoreGraphicsQuality.high => high,
      LightcoreGraphicsQuality.balanced => balanced ?? math.max(1, high ~/ 2),
      LightcoreGraphicsQuality.lowPower => lowPower ?? math.max(0, high ~/ 3),
    };
  }

  void resetTransientInputState() {
    _gesturePointerCount = 0;
    _lastGestureFocalPoint = null;
    _lastGestureScaleSignal = 1.0;
    _draggedPulseId = null;
    _draggedPulseCrossedSourceTower = false;
    _pulseInboundStartPositions.clear();
  }

  void handleCanvasTap(Offset localPosition) {
    _handleTap(Vector2(localPosition.dx, localPosition.dy));
  }

  bool handleCanvasPointerDown(Offset localPosition) {
    if (!_layoutReady || !enableBattlefieldTaps || _shellPromotion != null) {
      return false;
    }
    final pulseId = _hitTestPulse(Vector2(localPosition.dx, localPosition.dy));
    if (pulseId == null) {
      return false;
    }
    _draggedPulseId = pulseId;
    _draggedPulseCrossedSourceTower = _pulseDragCrossesSourceTower(
      pulseId,
      Vector2(localPosition.dx, localPosition.dy),
    );
    return true;
  }

  bool handleCanvasPointerMove(Offset localPosition) {
    final pulseId = _draggedPulseId;
    if (pulseId == null) {
      return false;
    }
    if (_pulseDragCrossesSourceTower(
      pulseId,
      Vector2(localPosition.dx, localPosition.dy),
    )) {
      _draggedPulseCrossedSourceTower = true;
      controller.markPulseCriticalBoosted(pulseId);
    }
    return true;
  }

  bool handleCanvasPointerUp(Offset localPosition) {
    final pulseId = _draggedPulseId;
    if (pulseId == null) {
      return false;
    }
    final crossed =
        _draggedPulseCrossedSourceTower ||
        _pulseDragCrossesSourceTower(
          pulseId,
          Vector2(localPosition.dx, localPosition.dy),
        );
    final clickedPosition = _pulsePositionForId(pulseId);
    if (clickedPosition != null) {
      _pulseInboundStartPositions[pulseId] = clickedPosition;
    }
    controller.releaseDraggedPulse(pulseId, crossedSourceTower: crossed);
    _draggedPulseId = null;
    _draggedPulseCrossedSourceTower = false;
    return true;
  }

  void cancelCanvasPayloadDrag() {
    _draggedPulseId = null;
    _draggedPulseCrossedSourceTower = false;
  }

  void playShellPromotion(ShellPromotionPresentation presentation) {
    _shellPromotion = presentation;
    _shellPromotionElapsed = 0;
    _screenShakeRemaining = 0;
    _screenShakeAmplitude = 0;
    _screenShakeOffset = Vector2.zero();
  }

  void clearShellPromotion() {
    _shellPromotion = null;
    _shellPromotionElapsed = 0;
  }

  void _recomputeLayout() {
    if (size.x == 0 || size.y == 0) {
      _layoutReady = false;
      return;
    }
    final shortest = math.min(size.x, size.y);
    _baseCenter = Vector2(size.x / 2, size.y * 0.46);
    _panOffset = _clampPanOffset(_panOffset);
    _center = _baseCenter + _panOffset;
    _hexRadius = shortest * 0.108 * _viewScale;
    _slotRadius = _hexRadius * 0.95;
    _coreRadius = _hexRadius * 1.03;
    _spawnRadiusVisual = shortest * 0.58 * _viewScale;
    _slotPositions = _buildBorderingRing();
    _layoutReady = _slotPositions.isNotEmpty;
    _relayImpactRadiusVisual = _layoutReady
        ? _slotPositions.first.distanceTo(_center)
        : 0;
  }

  Vector2 _clampPanOffset(Vector2 candidate) {
    if (size.x == 0 || size.y == 0) {
      return candidate;
    }
    final candidateCenter = _baseCenter + candidate;
    final clampedCenter = Vector2(
      candidateCenter.x.clamp(0.0, size.x).toDouble(),
      candidateCenter.y.clamp(0.0, size.y).toDouble(),
    );
    return clampedCenter - _baseCenter;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final clamped = dt.clamp(0, 0.05).toDouble();
    if (_shellPromotion != null) {
      _shellPromotionElapsed = math.min(
        shellPromotionStatsDelay,
        _shellPromotionElapsed + clamped,
      );
      return;
    }
    _syncSlotVisuals();
    _syncCoreVisuals();
    _syncLevelUpRadianceVisuals();
    _accumulator += clamped;

    var safety = 0;
    while (_accumulator >= _fixedStep && safety < 5) {
      controller.tick(_fixedStep);
      _accumulator -= _fixedStep;
      safety += 1;
    }
    _syncCombatAudio();
    _retainLivePulseVisualState();
    _updateSlotVisuals(clamped);
    _updateCoreVisuals(clamped);
    _updateEnemyFaceVisuals(clamped);
    _updateShotFireBursts(clamped);
    _updateScreenShake(clamped);
  }

  void _retainLivePulseVisualState() {
    final livePulseIds = controller.pulses.map((pulse) => pulse.id).toSet();
    _pulseInboundStartPositions.removeWhere(
      (pulseId, _) => !livePulseIds.contains(pulseId),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!_layoutReady) {
      _renderFallbackBackground(canvas);
      return;
    }
    _renderBackground(canvas);
    if (_shellPromotion != null) {
      _renderShellPromotion(canvas);
      return;
    }
    canvas.save();
    canvas.translate(_screenShakeOffset.x, _screenShakeOffset.y);
    _renderArena(canvas);
    if (controller.outerRingRevealed) {
      if (showArenaSlots) {
        _renderCoreRange(canvas);
        _renderSelectedTowerRange(canvas);
        _renderPersistentShieldRings(canvas);
        _renderLinks(canvas);
      }
    }
    _renderShotFireBursts(canvas);
    _renderShots(canvas);
    _renderImpacts(canvas);
    if (showArenaSlots) {
      _renderLevelUpRadiance(canvas);
    }
    _renderEnemies(canvas);
    if (controller.outerRingRevealed && showArenaSlots) {
      _renderSlots(canvas);
    }
    if (showArenaSlots) {
      _renderRelayImpactRing(canvas);
    }
    if (showTutorialGuides) {
      if (controller.outerRingRevealed && showArenaSlots) {
        _renderTutorialSlotGuides(canvas);
      }
      _renderTutorialEnemyGuide(canvas);
    }
    _renderCore(canvas);
    if (controller.outerRingRevealed) {
      _renderPulses(canvas);
    }
    canvas.restore();
  }

  void _handleTap(Vector2 pointer) {
    if (!_layoutReady || !enableBattlefieldTaps) {
      return;
    }
    if (_shellPromotion != null) {
      return;
    }
    if (!controller.outerRingRevealed) {
      if (pointer.distanceTo(_center) <= _coreRadius * 1.15) {
        onCenterTap();
      }
      return;
    }
    final tappedPulseId = _hitTestPulse(pointer);
    if (tappedPulseId != null) {
      final pulsePosition = _pulsePositionForId(tappedPulseId);
      if (pulsePosition != null) {
        _pulseInboundStartPositions[tappedPulseId] = pulsePosition;
      }
      controller.releaseDraggedPulse(tappedPulseId, crossedSourceTower: false);
      LightcoreAudio.instance.playSfx(LightcoreSfx.relayCharge);
      return;
    }
    final tappedEnemyId = _hitTestEnemy(pointer);
    if (tappedEnemyId != null &&
        controller.fireQueuedCorePacketAtEnemy(tappedEnemyId)) {
      LightcoreAudio.instance.playSfx(LightcoreSfx.coreFire);
      return;
    }
    if (tappedEnemyId != null && controller.focusBattleEnemy(tappedEnemyId)) {
      return;
    }
    final tappedIndex = _hitTestSlot(pointer);
    if (tappedIndex != null) {
      onSlotTap(tappedIndex);
      return;
    }
    if (pointer.distanceTo(_center) <= _coreRadius * 1.15) {
      onCenterTap();
    } else {
      onBackgroundTap();
    }
  }

  String? _hitTestPulse(Vector2 pointer) {
    for (final pulse in controller.pulses.reversed) {
      final position = _pulsePosition(pulse);
      if (position == null) {
        continue;
      }
      final scale = controller.hasActiveTutorial
          ? _tutorialPayloadTapRadiusScale
          : _payloadTapRadiusScale;
      if (pointer.distanceTo(position) <= _slotRadius * scale) {
        return pulse.id;
      }
    }
    return null;
  }

  Vector2? _pulsePosition(EnergyPulseState pulse) {
    if (!_layoutReady) {
      return null;
    }
    final start = _pulseStartPosition(pulse);
    if (start == null) {
      return null;
    }
    if (pulse.progress < 0) {
      return _pulseOrbitPosition(pulse, controller.elapsed);
    }
    return _pulseInboundPosition(pulse);
  }

  Vector2? _pulseOrbitPosition(EnergyPulseState pulse, double elapsed) {
    final anchor = _pulseSourceAnchor(pulse);
    if (anchor == null) {
      return null;
    }
    final seed = pulse.id.hashCode.abs();
    final rotation = ((seed % 360) * math.pi / 180);
    final orbitProgress = _pulseOrbitProgress(pulse, elapsed);
    final theta = (orbitProgress * math.pi * 2) + ((seed % 628) / 100);
    final wide = pulse.sourceSlotIndex == null
        ? _coreRadius * 2.05
        : _slotRadius * 2.28;
    final tall = pulse.sourceSlotIndex == null
        ? _coreRadius * 1.08
        : _slotRadius * 1.22;
    final localX = math.sin(theta) * wide;
    final localY = math.sin(theta * 2) * tall;
    return _rotatedAround(anchor, localX, localY, rotation);
  }

  double _pulseOrbitProgress(EnergyPulseState pulse, double elapsed) {
    if (pulse.progress < 0) {
      return ((pulse.progress + _payloadOrbitDurationSeconds) /
                  _payloadOrbitDurationSeconds)
              .clamp(0.0, 1.0)
              .toDouble() *
          _payloadMaxOrbitCount;
    }
    return _payloadMaxOrbitCount + (elapsed * 0.12);
  }

  Vector2? _pulseInboundPosition(EnergyPulseState pulse) {
    final start = _pulseInboundStartPosition(pulse);
    if (start == null) {
      return null;
    }
    final progress = pulse.progress.clamp(0.0, 1.0).toDouble();
    final eased = progress * progress * (3 - (2 * progress));
    final seed = pulse.id.hashCode.abs();
    final missPhase = ((seed % 628) / 100);
    final wobble =
        math.sin((progress * math.pi * 2.75) + missPhase) *
        (1 - eased) *
        (pulse.sourceSlotIndex == null
            ? _coreRadius * 0.38
            : _slotRadius * 0.5);
    final direction = _center - start;
    final distance = direction.length;
    if (distance <= 0) {
      return _center.clone();
    }
    final normal = Vector2(-direction.y / distance, direction.x / distance);
    return start + (direction * eased) + (normal * wobble);
  }

  Vector2? _pulseInboundStartPosition(EnergyPulseState pulse) {
    final retainedStart = _pulseInboundStartPositions[pulse.id];
    if (retainedStart != null) {
      return retainedStart;
    }
    final startedAt = pulse.inboundStartedAtElapsed;
    if (startedAt != null) {
      return _pulseOrbitPosition(pulse, startedAt);
    }
    return _pulseOrbitPosition(pulse, controller.elapsed);
  }

  Vector2 _rotatedAround(
    Vector2 anchor,
    double localX,
    double localY,
    double rotation,
  ) {
    final cosA = math.cos(rotation);
    final sinA = math.sin(rotation);
    return Vector2(
      anchor.x + (localX * cosA) - (localY * sinA),
      anchor.y + (localX * sinA) + (localY * cosA),
    );
  }

  Vector2? _pulseSourceAnchor(EnergyPulseState pulse) {
    final sourceSlotIndex = pulse.sourceSlotIndex;
    if (sourceSlotIndex == null) {
      return _center;
    }
    if (sourceSlotIndex >= 0 && sourceSlotIndex < _slotPositions.length) {
      return _slotPositions[sourceSlotIndex];
    }
    return null;
  }

  Vector2? _pulseStartPosition(EnergyPulseState pulse) {
    final sourceSlotIndex = pulse.sourceSlotIndex;
    if (sourceSlotIndex == null) {
      return _corePulseStart(pulse);
    }
    if (sourceSlotIndex >= 0 && sourceSlotIndex < _slotPositions.length) {
      return _slotPositions[sourceSlotIndex];
    }
    return null;
  }

  bool _pulseDragCrossesSourceTower(String pulseId, Vector2 pointer) {
    EnergyPulseState? pulse;
    for (final candidate in controller.pulses) {
      if (candidate.id == pulseId) {
        pulse = candidate;
        break;
      }
    }
    final sourceSlotIndex = pulse?.sourceSlotIndex;
    if (sourceSlotIndex == null ||
        sourceSlotIndex < 0 ||
        sourceSlotIndex >= _slotPositions.length) {
      return false;
    }
    return pointer.distanceTo(_slotPositions[sourceSlotIndex]) <=
        _slotRadius * 0.72;
  }

  Vector2? _pulsePositionForId(String pulseId) {
    for (final pulse in controller.pulses) {
      if (pulse.id == pulseId) {
        return _pulsePosition(pulse);
      }
    }
    return null;
  }

  @override
  void onScaleStart(ScaleStartInfo info) {
    super.onScaleStart(info);
    if (!enableBattlefieldTaps) {
      _gesturePointerCount = 0;
      _lastGestureFocalPoint = null;
      _lastGestureScaleSignal = 1.0;
      return;
    }
    _gesturePointerCount = info.pointerCount;
    _lastGestureFocalPoint = info.eventPosition.widget.clone();
    _lastGestureScaleSignal = 1.0;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    super.onScaleUpdate(info);
    if (!enableBattlefieldTaps) {
      return;
    }
    if (size.x == 0 || size.y == 0) {
      return;
    }

    final previousFocalPoint = _lastGestureFocalPoint;
    final currentFocalPoint = info.eventPosition.widget.clone();
    final currentScaleSignal = ((info.scale.global.x + info.scale.global.y) / 2)
        .clamp(0.01, double.infinity);
    if (previousFocalPoint == null) {
      _gesturePointerCount = info.pointerCount;
      _lastGestureFocalPoint = currentFocalPoint;
      _lastGestureScaleSignal = currentScaleSignal;
      return;
    }

    if (info.pointerCount != _gesturePointerCount) {
      _gesturePointerCount = info.pointerCount;
      _lastGestureFocalPoint = currentFocalPoint;
      _lastGestureScaleSignal = currentScaleSignal;
      return;
    }

    final previousViewScale = _viewScale;
    var nextViewScale = previousViewScale;
    if (info.pointerCount >= 2) {
      final scaleRatio = currentScaleSignal / _lastGestureScaleSignal;
      nextViewScale = (previousViewScale * scaleRatio).clamp(
        _minViewScale,
        _maxViewScale,
      );
    }
    final effectiveScaleRatio = nextViewScale / previousViewScale;
    final nextPanOffset =
        currentFocalPoint -
        _baseCenter -
        ((previousFocalPoint - _baseCenter - _panOffset) * effectiveScaleRatio);
    _viewScale = nextViewScale;
    _panOffset = _clampPanOffset(nextPanOffset);
    _lastGestureFocalPoint = currentFocalPoint;
    _lastGestureScaleSignal = currentScaleSignal;
    _recomputeLayout();
  }

  @override
  void onScaleEnd(ScaleEndInfo info) {
    super.onScaleEnd(info);
    if (!enableBattlefieldTaps) {
      _gesturePointerCount = 0;
      _lastGestureFocalPoint = null;
      _lastGestureScaleSignal = 1.0;
      return;
    }
    _gesturePointerCount = 0;
    _lastGestureFocalPoint = null;
    _lastGestureScaleSignal = 1.0;
  }

  List<Vector2> _buildBorderingRing() {
    const axialNeighbors = <(int, int)>[
      (1, 0),
      (1, -1),
      (0, -1),
      (-1, 0),
      (-1, 1),
      (0, 1),
    ];

    return axialNeighbors
        .map((coord) => _axialToPixel(coord.$1, coord.$2))
        .toList();
  }

  Vector2 _axialToPixel(int q, int r) {
    final x = _hexRadius * math.sqrt(3) * (q + (r / 2));
    final y = _hexRadius * 1.5 * r;
    return Vector2(_center.x + x, _center.y + y);
  }

  Offset _axialToOffset(Offset center, int q, int r, double radius) {
    final x = radius * math.sqrt(3) * (q + (r / 2));
    final y = radius * 1.5 * r;
    return Offset(center.dx + x, center.dy + y);
  }

  Color _signatureColor(
    PrototypeAffinity primary, [
    PrototypeAffinity? secondary,
  ]) => secondary == null
      ? primary.color
      : Color.lerp(primary.color, secondary.color, 0.5)!;

  void _renderBackground(Canvas canvas) {
    final rect = Offset.zero & Size(size.x, size.y);
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          LightcorePalette.night,
          LightcorePalette.abyss,
          Color(0xFF102B3E),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    final glowAlphaScale = _battleGlowAlphaScale;
    if (glowAlphaScale > 0) {
      final upperGlow = Paint()
        ..shader =
            RadialGradient(
              colors: [
                LightcorePalette.aether.withValues(
                  alpha: 0.14 * glowAlphaScale,
                ),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(_center.x * 0.72, _center.y * 0.7),
                radius: _spawnRadiusVisual * 0.92,
              ),
            );
      canvas.drawRect(rect, upperGlow);
    }
  }

  void _renderFallbackBackground(Canvas canvas) {
    final rect = Offset.zero & Size(math.max(size.x, 1), math.max(size.y, 1));
    canvas.drawRect(rect, Paint()..color = LightcorePalette.night);
  }

  void _renderArena(Canvas canvas) {
    final spawnBaseRadiusVisual = _modelRadiusToVisual(controller.spawnRadius);
    final spawnRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = LightcorePalette.stroke.withValues(alpha: 0.35);
    final spawnBandPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = LightcorePalette.stroke.withValues(alpha: 0.18);
    if ((_spawnRadiusVisual - spawnBaseRadiusVisual).abs() > 3) {
      canvas.drawCircle(
        Offset(_center.x, _center.y),
        spawnBaseRadiusVisual,
        spawnBandPaint,
      );
    }
    canvas.drawCircle(
      Offset(_center.x, _center.y),
      _spawnRadiusVisual,
      spawnRingPaint,
    );

    final boardLinkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = LightcorePalette.stroke.withValues(alpha: 0.26);

    if (controller.outerRingRevealed && showArenaSlots) {
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
        canvas.drawLine(current, next, boardLinkPaint);
      }
    }

    canvas.drawPath(
      _hexPath(Offset(_center.x, _center.y), _coreRadius * 1.22),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = LightcorePalette.stroke.withValues(alpha: 0.42),
    );
  }

  void _updateScreenShake(double dt) {
    if (_screenShakeRemaining <= 0) {
      _screenShakeOffset = Vector2.zero();
      _screenShakeAmplitude = 0;
      return;
    }

    final elapsed = _coreDamageShakeDuration - _screenShakeRemaining;
    final progress = (elapsed / _coreDamageShakeDuration).clamp(0.0, 1.0);
    final falloff = math.pow(1 - progress, 1.8).toDouble();
    final phase = elapsed * 96;
    final shakeScale = switch (controller.graphicsQuality) {
      LightcoreGraphicsQuality.high => 1.0,
      LightcoreGraphicsQuality.balanced => 0.62,
      LightcoreGraphicsQuality.lowPower => 0.28,
    };
    final x =
        ((math.sin(phase) * 0.7) + (math.sin((phase * 1.73) + 0.8) * 0.3)) *
        _screenShakeAmplitude *
        shakeScale *
        falloff;
    final y =
        ((math.cos((phase * 1.17) + 0.4) * 0.68) +
            (math.sin(phase * 2.1) * 0.32)) *
        _screenShakeAmplitude *
        shakeScale *
        falloff;
    _screenShakeOffset = Vector2(x, y);
    _screenShakeRemaining = math.max(0, _screenShakeRemaining - dt);
  }
}
