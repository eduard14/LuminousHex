import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../battle/lightcore_battle_game.dart';
import '../battle/shell_promotion_presentation.dart';
import '../models/lightcore_config.dart';
import '../models/lightcore_state.dart';
import '../models/lightcore_types.dart';
import '../services/lightcore_audio.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/aurora_panel.dart';
import '../widgets/layer_one_component_forecast_panel.dart';
import '../widgets/meter_bar.dart';
import '../widgets/projectile_symbol_glyph.dart';
import '../widgets/symbol_grid_tile.dart';
import '../widgets/tower_health_bar.dart';
import '../widgets/tower_ring_icon.dart';
import 'tower_detail_screen.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({
    super.key,
    required this.controller,
    required this.isActive,
    this.topOverlayInset = 0,
    this.bottomOverlayInset = 0,
    this.showQuestPanel = true,
    this.showBattleHud = true,
    this.enableBattlefieldTaps = true,
    this.showBattleGuides = true,
    this.showArenaSlots = true,
    this.showFoldedShellSlots = true,
    this.promotionPresentation,
    this.onPromotionPresentationComplete,
  });

  final LightcoreController controller;
  final bool isActive;
  final double topOverlayInset;
  final double bottomOverlayInset;
  final bool showQuestPanel;
  final bool showBattleHud;
  final bool enableBattlefieldTaps;
  final bool showBattleGuides;
  final bool showArenaSlots;
  final bool showFoldedShellSlots;
  final ShellPromotionPresentation? promotionPresentation;
  final VoidCallback? onPromotionPresentationComplete;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

enum _BattlePanelFocus { none, core }

enum _BattleStatsTargetKind { core, slot }

void _showChildCoreAffinityPicker(
  BuildContext context,
  LightcoreController controller,
  int slotIndex,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final textTheme = Theme.of(sheetContext).textTheme;
      final blockedLabel = controller.childLayerCreationBlockedLabelForSlot(
        slotIndex,
      );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AuroraPanel(
            tint: LightcorePalette.aether,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Core Color', style: textTheme.titleLarge),
                if (blockedLabel != null) ...[
                  const SizedBox(height: 6),
                  Text(blockedLabel, style: textTheme.bodyMedium),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final affinity
                        in LightcoreController.childCoreAffinityChoices)
                      FilledButton.icon(
                        onPressed: blockedLabel == null
                            ? () {
                                Navigator.of(sheetContext).pop();
                                controller.createChildLayer(
                                  slotIndex,
                                  affinity,
                                );
                              }
                            : null,
                        icon: Icon(
                          affinityIconFor(affinity),
                          color: affinity.color,
                        ),
                        label: Text(controller.childCoreChoiceLabel(affinity)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _BattleStatsTarget {
  const _BattleStatsTarget.core()
    : kind = _BattleStatsTargetKind.core,
      slotIndex = null;

  const _BattleStatsTarget.slot(this.slotIndex)
    : kind = _BattleStatsTargetKind.slot;

  final _BattleStatsTargetKind kind;
  final int? slotIndex;
}

class _BattleScreenState extends State<BattleScreen> {
  static const double _canvasTapSlop = 12;

  late LightcoreBattleGame _game;
  late final FocusNode _shortcutFocusNode;
  _BattlePanelFocus _panelFocus = _BattlePanelFocus.none;
  _BattleStatsTarget? _statsTarget;
  bool _selectionControlsVisible = true;
  Timer? _promotionStatsTimer;
  int? _activePromotionSequence;
  Layer2ComponentState? _promotionResultComponent;
  int? _canvasTapPointer;
  Offset? _canvasTapStart;
  bool _canvasTapCanceled = false;
  late final AppLifecycleListener _appLifecycleListener;

  @override
  void initState() {
    super.initState();
    if (widget.controller.layerRebuildEnabled) {
      widget.controller.clearLayerRebuildBattleSelection(notify: false);
    }
    _appLifecycleListener = AppLifecycleListener(
      onHide: _handleLifecycleInterrupted,
      onInactive: _handleLifecycleInterrupted,
      onPause: _handleLifecycleInterrupted,
      onDetach: _handleLifecycleInterrupted,
      onResume: _handleLifecycleResumed,
    );
    _shortcutFocusNode = FocusNode(debugLabel: 'Battle hex shortcuts');
    _game = _createGame();
    _logBattle('init');
    _syncEngineState();
    _syncPromotionPresentation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestShortcutFocus();
    });
  }

  @override
  void didUpdateWidget(covariant BattleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.stopManualOverdrive();
      if (widget.controller.layerRebuildEnabled) {
        widget.controller.clearLayerRebuildBattleSelection(notify: false);
      }
      _promotionStatsTimer?.cancel();
      _promotionStatsTimer = null;
      _activePromotionSequence = null;
      _resetCanvasTap();
      _game.pauseEngine();
      _game = _createGame();
      _panelFocus = _BattlePanelFocus.none;
      _statsTarget = null;
      _selectionControlsVisible = true;
      _logBattle('controller-changed');
      _syncEngineState();
    }
    if (identical(oldWidget.controller, widget.controller) &&
        (oldWidget.enableBattlefieldTaps != widget.enableBattlefieldTaps ||
            oldWidget.showBattleGuides != widget.showBattleGuides ||
            oldWidget.showArenaSlots != widget.showArenaSlots ||
            oldWidget.showFoldedShellSlots != widget.showFoldedShellSlots)) {
      _resetCanvasTap();
      _game.pauseEngine();
      _game = _createGame();
      _syncEngineState();
    }
    if (oldWidget.isActive && !widget.isActive) {
      widget.controller.stopManualOverdrive();
      _panelFocus = _BattlePanelFocus.none;
      _statsTarget = null;
      _selectionControlsVisible = true;
    }
    if (oldWidget.isActive != widget.isActive) {
      _syncEngineState();
    }
    _syncPromotionPresentation();
    if (!oldWidget.isActive && widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestShortcutFocus();
      });
    }
  }

  @override
  void dispose() {
    _logBattle('dispose');
    widget.controller.stopManualOverdrive();
    _promotionStatsTimer?.cancel();
    _appLifecycleListener.dispose();
    _shortcutFocusNode.dispose();
    super.dispose();
  }

  LightcoreBattleGame _createGame() {
    return LightcoreBattleGame(
      controller: widget.controller,
      onCenterTap: _handleCenterTap,
      onSlotTap: _handleSlotTap,
      onBackgroundTap: _handleBackgroundTap,
      enableBattlefieldTaps: widget.enableBattlefieldTaps,
      showTutorialGuides: widget.showBattleGuides,
      showArenaSlots: widget.showArenaSlots,
      showFoldedShellSlots: widget.showFoldedShellSlots,
    );
  }

  void _handleLifecycleInterrupted() {
    _logBattle('lifecycle-interrupted');
    _resetTransientInputState();
    widget.controller.stopManualOverdrive();
    _game.pauseEngine();
  }

  void _handleLifecycleResumed() {
    _logBattle('lifecycle-resumed');
    _resetTransientInputState();
    _syncEngineState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestShortcutFocus();
    });
  }

  void _resetTransientInputState() {
    _resetCanvasTap();
    _game.resetTransientInputState();
  }

  void _syncEngineState() {
    if (widget.isActive) {
      _game.resumeEngine();
      _logBattle('engine-resumed');
    } else {
      _game.pauseEngine();
      _logBattle('engine-paused');
    }
  }

  void _requestShortcutFocus() {
    if (!mounted || !widget.isActive) {
      return;
    }
    _shortcutFocusNode.requestFocus();
  }

  void _syncPromotionPresentation() {
    final presentation = widget.promotionPresentation;
    if (presentation == null) {
      if (_activePromotionSequence != null) {
        _promotionStatsTimer?.cancel();
        _promotionStatsTimer = null;
        _activePromotionSequence = null;
        _game.clearShellPromotion();
      }
      return;
    }
    if (!widget.isActive || _activePromotionSequence == presentation.sequence) {
      return;
    }
    _startPromotionPresentation(presentation);
  }

  void _startPromotionPresentation(ShellPromotionPresentation presentation) {
    _promotionStatsTimer?.cancel();
    _activePromotionSequence = presentation.sequence;
    widget.controller.stopManualOverdrive();
    _game.playShellPromotion(presentation);
    setState(() {
      _panelFocus = _BattlePanelFocus.none;
      _statsTarget = null;
      _selectionControlsVisible = false;
    });
    _promotionStatsTimer = Timer(
      Duration(
        milliseconds: (LightcoreBattleGame.shellPromotionStatsDelay * 1000)
            .round(),
      ),
      () {
        if (!mounted || _activePromotionSequence != presentation.sequence) {
          return;
        }
        widget.controller.selectCenter();
        _game.clearShellPromotion();
        final resultComponent = presentation.layer2Component;
        setState(() {
          _panelFocus = _BattlePanelFocus.core;
          _statsTarget = const _BattleStatsTarget.core();
          _selectionControlsVisible = true;
          _promotionResultComponent = resultComponent;
          _activePromotionSequence = null;
          _promotionStatsTimer = null;
        });
        widget.onPromotionPresentationComplete?.call();
      },
    );
  }

  KeyEventResult _handleShortcutKey(FocusNode node, KeyEvent event) {
    if (!widget.isActive ||
        !widget.enableBattlefieldTaps ||
        event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (_activePromotionSequence != null) {
      return KeyEventResult.handled;
    }
    final slotIndex = _slotIndexForShortcutKey(event.logicalKey);
    if (slotIndex == null || slotIndex >= widget.controller.slots.length) {
      return KeyEventResult.ignored;
    }
    _handleSlotTap(slotIndex);
    return KeyEventResult.handled;
  }

  int? _slotIndexForShortcutKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      return 0;
    }
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      return 1;
    }
    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      return 2;
    }
    if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      return 3;
    }
    if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      return 4;
    }
    if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      return 5;
    }
    return null;
  }

  Widget _buildGameCanvas(double radius, {required bool dockOpen}) {
    _game.setUiFocusMode(dockOpen: dockOpen);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            ignoring: !widget.enableBattlefieldTaps,
            child: GameWidget(
              key: ValueKey<LightcoreBattleGame>(_game),
              game: _game,
            ),
          ),
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _handleCanvasPointerDown,
            onPointerMove: _handleCanvasPointerMove,
            onPointerUp: _handleCanvasPointerUp,
            onPointerCancel: _handleCanvasPointerCancel,
          ),
        ],
      ),
    );
  }

  void _handleCanvasPointerDown(PointerDownEvent event) {
    if (!widget.enableBattlefieldTaps) {
      return;
    }
    final primaryTapStart =
        event.buttons == 0 || (event.buttons & kPrimaryButton) != 0;
    if (!primaryTapStart || _canvasTapPointer != null) {
      _canvasTapCanceled = true;
      _logBattle('pointer-down-canceled', <String, Object?>{
        'buttons': event.buttons,
        'activePointer': _canvasTapPointer,
      });
      return;
    }
    _canvasTapPointer = event.pointer;
    _canvasTapStart = event.localPosition;
    _logBattle('pointer-down', <String, Object?>{
      'pointer': event.pointer,
      'x': event.localPosition.dx.toStringAsFixed(1),
      'y': event.localPosition.dy.toStringAsFixed(1),
    });
  }

  void _handleCanvasPointerMove(PointerMoveEvent event) {
    if (!widget.enableBattlefieldTaps) {
      return;
    }
    final start = _canvasTapStart;
    if (event.pointer != _canvasTapPointer || start == null) {
      return;
    }
    if ((event.localPosition - start).distance > _canvasTapSlop) {
      _canvasTapCanceled = true;
      _logBattle('pointer-move-canceled', <String, Object?>{
        'pointer': event.pointer,
      });
    }
  }

  void _handleCanvasPointerUp(PointerUpEvent event) {
    if (!widget.enableBattlefieldTaps) {
      return;
    }
    _logBattle('pointer-up', <String, Object?>{
      'pointer': event.pointer,
      'matches': event.pointer == _canvasTapPointer,
      'canceled': _canvasTapCanceled,
      'gameControllerCurrent': identical(_game.controller, widget.controller),
    });
    if (event.pointer == _canvasTapPointer && !_canvasTapCanceled) {
      _game.handleCanvasTap(event.localPosition);
    }
    _resetCanvasTap();
  }

  void _handleCanvasPointerCancel(PointerCancelEvent event) {
    if (!widget.enableBattlefieldTaps) {
      return;
    }
    if (event.pointer == _canvasTapPointer) {
      _resetCanvasTap();
    }
  }

  void _resetCanvasTap() {
    _canvasTapPointer = null;
    _canvasTapStart = null;
    _canvasTapCanceled = false;
  }

  void _handleCenterTap() {
    if (!widget.enableBattlefieldTaps) {
      return;
    }
    if (_activePromotionSequence != null) {
      _logBattle('center-tap-ignored', <String, Object?>{
        'reason': 'promotion-active',
      });
      return;
    }
    _logBattle('center-tap');
    LightcoreAudio.instance.playSfx(LightcoreSfx.uiTap);
    final controller = widget.controller;
    if (!controller.swarmActivated) {
      controller.startBattle(showBanner: false);
      setState(() {
        _statsTarget = null;
        _panelFocus = _BattlePanelFocus.none;
        _selectionControlsVisible = true;
      });
      return;
    }
    controller.handleBattleCenterTap();
    if (controller.activeThreatRegionChallenge != null) {
      setState(() {
        _statsTarget = null;
        _panelFocus = _BattlePanelFocus.none;
        _selectionControlsVisible = false;
      });
      return;
    }
    setState(() {
      _statsTarget = const _BattleStatsTarget.core();
      _panelFocus = _BattlePanelFocus.core;
      _selectionControlsVisible = true;
    });
  }

  int _resolveBattleSlotTapIndex(int slotIndex) {
    final controller = widget.controller;
    final shouldRouteToFirstRelay =
        controller.activeLayer.tier == 1 &&
        !controller.activeLayerHasParentSlot &&
        controller.builtTowerCount == 0 &&
        controller.unlockedOuterSlotCount > 0 &&
        slotIndex != 0 &&
        !controller.isOuterSlotUnlocked(slotIndex);
    return shouldRouteToFirstRelay ? 0 : slotIndex;
  }

  void _handleSlotTap(int slotIndex) {
    if (!widget.enableBattlefieldTaps) {
      return;
    }
    if (_activePromotionSequence != null) {
      _logBattle('slot-tap-ignored', <String, Object?>{
        'reason': 'promotion-active',
        'slot': slotIndex,
      });
      return;
    }
    final resolvedSlotIndex = _resolveBattleSlotTapIndex(slotIndex);
    _logBattle('slot-tap', <String, Object?>{
      'slot': slotIndex,
      'resolvedSlot': resolvedSlotIndex,
    });
    LightcoreAudio.instance.playSfx(LightcoreSfx.uiTap);
    final controller = widget.controller;
    final slot =
        resolvedSlotIndex >= 0 && resolvedSlotIndex < controller.slots.length
        ? controller.slots[resolvedSlotIndex]
        : null;
    final target = slot != null && !slot.isLayerProject
        ? _BattleStatsTarget.slot(resolvedSlotIndex)
        : null;
    if (controller.layerRebuildEnabled &&
        slot != null &&
        !slot.isBuilt &&
        !slot.isFabricating &&
        !slot.isLayerProject) {
      controller.selectSlot(resolvedSlotIndex);
      setState(() {
        _statsTarget = target;
        _panelFocus = _BattlePanelFocus.none;
        _selectionControlsVisible = true;
      });
      return;
    }
    final opensControls = slot != null && !slot.isLayerProject;
    final defersControls =
        slot != null &&
        slot.isBuilt &&
        !slot.isFabricating &&
        !slot.isLayerProject &&
        !controller.activeLayerPassiveOnly;
    if (!defersControls) {
      controller.handleBattleSlotTap(resolvedSlotIndex);
    } else {
      controller.selectSlot(resolvedSlotIndex);
    }
    if (controller.activeThreatRegionChallenge != null) {
      setState(() {
        _statsTarget = null;
        _panelFocus = _BattlePanelFocus.none;
        _selectionControlsVisible = false;
      });
      return;
    }
    setState(() {
      _statsTarget = target;
      _panelFocus = _BattlePanelFocus.none;
      _selectionControlsVisible = opensControls;
    });
  }

  void _openStatsTarget(_BattleStatsTarget target) {
    switch (target.kind) {
      case _BattleStatsTargetKind.core:
        widget.controller.selectCenter();
        setState(() {
          _statsTarget = target;
          _panelFocus = _BattlePanelFocus.core;
          _selectionControlsVisible = true;
        });
        break;
      case _BattleStatsTargetKind.slot:
        final slotIndex = target.slotIndex;
        if (slotIndex == null ||
            slotIndex < 0 ||
            slotIndex >= widget.controller.slots.length) {
          return;
        }
        widget.controller.selectSlot(slotIndex);
        setState(() {
          _statsTarget = target;
          _panelFocus = _BattlePanelFocus.none;
          _selectionControlsVisible = true;
        });
        break;
    }
  }

  bool _buildTowerAt(int slotIndex, TowerConfig config) {
    final started = widget.controller.startTowerFabricationAt(
      slotIndex,
      config,
    );
    if (!started) {
      return false;
    }
    setState(() {
      _statsTarget = _BattleStatsTarget.slot(slotIndex);
      _panelFocus = _BattlePanelFocus.none;
      _selectionControlsVisible = false;
    });
    return true;
  }

  void _handleBackgroundTap() {
    if (!widget.enableBattlefieldTaps) {
      return;
    }
    if (_activePromotionSequence != null) {
      _logBattle('background-tap-ignored', <String, Object?>{
        'reason': 'promotion-active',
      });
      return;
    }
    _logBattle('background-tap');
    if (_selectionOverlayIsOpen) {
      LightcoreAudio.instance.playSfx(LightcoreSfx.uiCancel);
      setState(() {
        _selectionControlsVisible = false;
      });
      return;
    }
  }

  bool get _selectionOverlayIsOpen {
    if (!_selectionControlsVisible) {
      return false;
    }
    return _panelFocus == _BattlePanelFocus.core ||
        widget.controller.selectedSlotOrNull != null;
  }

  void _toggleShellVisibility() {
    if (!widget.enableBattlefieldTaps) {
      return;
    }
    LightcoreAudio.instance.playSfx(LightcoreSfx.uiCancel);
    widget.controller.toggleShellVisibility();
    setState(() {
      _statsTarget = null;
      _selectionControlsVisible = false;
      _panelFocus = _BattlePanelFocus.none;
    });
  }

  void _logBattle(
    String event, [
    Map<String, Object?> values = const <String, Object?>{},
  ]) {
    if (!_battleDebugLoggingEnabled) {
      return;
    }
    final controller = widget.controller;
    final details =
        <String, Object?>{
              'isActive': widget.isActive,
              'gameControllerCurrent': identical(
                _game.controller,
                widget.controller,
              ),
              'activeLayer': controller.activeLayerLabel,
              'activeLayerId': _redact(controller.activeLayer.id),
              'viewLayerId': _redact(controller.viewedLayer.id),
              'runtimeLayerId': _redact(controller.runtimeLayer.id),
              'outerRing': controller.outerRingRevealed,
              'swarm': controller.swarmActivated,
              'enemies': controller.enemyCount,
              'target': controller.enemyTargetCount,
              'selectedSlot': controller.selectedSlotIndex,
              ...values,
            }.entries
            .where((entry) => entry.value != null)
            .map((entry) => '${entry.key}=${entry.value}')
            .join(' ');
    debugPrint('[LightcoreBattle] $event $details');
  }

  static bool get _battleDebugLoggingEnabled =>
      const bool.fromEnvironment('LIGHTCORE_BATTLE_DEBUG') ||
      Uri.base.queryParameters['battleDebug'] == '1' ||
      Uri.base.queryParameters['sessionDebug'] == '1' ||
      Uri.base.queryParameters['debugErrors'] == '1';

  static String? _redact(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (normalized.length <= 8) {
      return normalized;
    }
    return '${normalized.substring(0, 4)}...${normalized.substring(normalized.length - 4)}';
  }

  bool _isStatsTargetOpen(_BattleStatsTarget target) {
    switch (target.kind) {
      case _BattleStatsTargetKind.core:
        return widget.controller.outerRingRevealed &&
            _panelFocus == _BattlePanelFocus.core;
      case _BattleStatsTargetKind.slot:
        return widget.controller.selectedSlotOrNull?.slotIndex ==
            target.slotIndex;
    }
  }

  bool _opensTowerDetailOverlay(_BattleStatsTarget target) {
    return false;
  }

  void _openTowerDetailOverlay(
    BuildContext context,
    _BattleStatsTarget target,
  ) {
    final slotIndex = target.slotIndex;
    if (slotIndex == null ||
        slotIndex < 0 ||
        slotIndex >= widget.controller.slots.length) {
      return;
    }
    widget.controller.selectSlot(slotIndex);
    setState(() {
      _statsTarget = target;
      _panelFocus = _BattlePanelFocus.none;
      _selectionControlsVisible = false;
    });
    showTowerDetailOverlay(
      context: context,
      controller: widget.controller,
      slotIndex: slotIndex,
    );
  }

  void _toggleSelectionControlsFor(
    BuildContext context,
    _BattleStatsTarget target,
  ) {
    if (_opensTowerDetailOverlay(target)) {
      _openTowerDetailOverlay(context, target);
      return;
    }
    if (!_isStatsTargetOpen(target)) {
      _openStatsTarget(target);
      return;
    }
    setState(() {
      _selectionControlsVisible = !_selectionControlsVisible;
    });
  }

  Color _selectionTint(
    LightcoreController controller,
    OuterTowerState? selected,
    _BattlePanelFocus panelFocus,
  ) {
    if (selected == null) {
      return panelFocus == _BattlePanelFocus.core
          ? controller.coreState.affinity.color
          : LightcorePalette.stroke;
    }
    if (!selected.isBuilt) {
      return LightcorePalette.aether;
    }
    return selected.config?.affinity.color ??
        selected.childAffinity?.color ??
        LightcorePalette.layer2;
  }

  String _selectionTooltip(
    LightcoreController controller,
    OuterTowerState? selected,
    _BattlePanelFocus panelFocus,
  ) {
    if (selected == null) {
      return panelFocus == _BattlePanelFocus.core
          ? 'Core controls'
          : 'Tower controls';
    }
    if (!selected.isBuilt) {
      return 'Build Slot ${selected.slotIndex + 1}';
    }
    if (selected.isFabricating) {
      return '${controller.towerDisplayName(selected)} building';
    }
    return '${controller.towerDisplayName(selected)} controls';
  }

  Color? _statsTargetTint(
    LightcoreController controller,
    _BattleStatsTarget? target,
  ) {
    if (target == null) {
      return null;
    }
    switch (target.kind) {
      case _BattleStatsTargetKind.core:
        return controller.coreState.affinity.color;
      case _BattleStatsTargetKind.slot:
        final slotIndex = target.slotIndex;
        if (slotIndex == null ||
            slotIndex < 0 ||
            slotIndex >= controller.slots.length) {
          return null;
        }
        final slot = controller.slots[slotIndex];
        if (!slot.isBuilt || slot.isLayerProject) {
          return null;
        }
        return slot.config?.affinity.color ??
            slot.childAffinity?.color ??
            LightcorePalette.layer2;
    }
  }

  String? _statsTargetTooltip(
    LightcoreController controller,
    _BattleStatsTarget? target,
  ) {
    if (target == null) {
      return null;
    }
    switch (target.kind) {
      case _BattleStatsTargetKind.core:
        return 'Core controls';
      case _BattleStatsTargetKind.slot:
        final slotIndex = target.slotIndex;
        if (slotIndex == null ||
            slotIndex < 0 ||
            slotIndex >= controller.slots.length) {
          return null;
        }
        final slot = controller.slots[slotIndex];
        if (!slot.isBuilt || slot.isLayerProject) {
          return null;
        }
        if (slot.isFabricating) {
          return '${controller.towerDisplayName(slot)} building';
        }
        return '${controller.towerDisplayName(slot)} controls';
    }
  }

  _BattleStatsTarget? _selectionButtonTarget(
    LightcoreController controller,
    OuterTowerState? selected,
    _BattlePanelFocus panelFocus,
  ) {
    if (_statsTarget != null) {
      return _statsTarget;
    }
    if (selected != null) {
      return _BattleStatsTarget.slot(selected.slotIndex);
    }
    if (panelFocus == _BattlePanelFocus.core) {
      return const _BattleStatsTarget.core();
    }
    return null;
  }

  IconData _statsTargetIcon(_BattleStatsTarget target) {
    switch (target.kind) {
      case _BattleStatsTargetKind.core:
        return Icons.build_rounded;
      case _BattleStatsTargetKind.slot:
        return Icons.build_rounded;
    }
  }

  Widget? _buildSelectionOverlay({
    required BuildContext context,
    required LightcoreController controller,
    required OuterTowerState? selected,
    required bool compact,
  }) {
    final panelFocus = controller.outerRingRevealed
        ? _panelFocus
        : _BattlePanelFocus.none;
    final showOverlay =
        (selected != null || panelFocus == _BattlePanelFocus.core) &&
        _selectionControlsVisible;
    if (!showOverlay) {
      return null;
    }
    final target = _selectionButtonTarget(controller, selected, panelFocus);
    if (target != null && _opensTowerDetailOverlay(target)) {
      return null;
    }

    final overlayContent = _BattleControlPanel(
      controller: controller,
      selected: selected,
      panelFocus: panelFocus,
      onBuildTower: _buildTowerAt,
    );

    final tint = _selectionTint(controller, selected, panelFocus);
    final mediaSize = MediaQuery.sizeOf(context);
    final dockHeight = compact
        ? math.min(360.0, math.max(280.0, mediaSize.height * 0.38))
        : null;

    final panel = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: compact ? mediaSize.width - 20 : 500,
        maxHeight: mediaSize.height * (compact ? 0.46 : 0.42),
      ),
      child: AuroraPanel(
        tint: tint,
        radius: 16,
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: SingleChildScrollView(child: overlayContent),
      ),
    );
    return dockHeight == null
        ? panel
        : SizedBox(height: dockHeight, child: panel);
  }

  Widget _buildOverdriveHud() {
    return _ManualOverdriveHud(controller: widget.controller);
  }

  Widget? _buildShellVisibilityHud({
    required LightcoreController controller,
    required bool compact,
  }) {
    if (!widget.enableBattlefieldTaps ||
        _activePromotionSequence != null ||
        !controller.swarmActivated) {
      return null;
    }
    return _BattleShellVisibilityHud(
      compact: compact,
      expanded: controller.outerRingRevealed,
      onPressed: _toggleShellVisibility,
    );
  }

  Widget? _buildSelectionHud({
    required BuildContext context,
    required LightcoreController controller,
    required OuterTowerState? selected,
  }) {
    final panelFocus = controller.outerRingRevealed
        ? _panelFocus
        : _BattlePanelFocus.none;
    final target = _selectionButtonTarget(controller, selected, panelFocus);
    if (target == null) {
      return null;
    }
    final targetOpen = _isStatsTargetOpen(target);
    final tint = targetOpen
        ? _selectionTint(controller, selected, panelFocus)
        : _statsTargetTint(controller, target);
    final tooltip = targetOpen
        ? _selectionTooltip(controller, selected, panelFocus)
        : _statsTargetTooltip(controller, target);
    final icon = _statsTargetIcon(target);
    if (tint == null || tooltip == null) {
      return null;
    }

    return _BattleSelectionHud(
      tint: tint,
      tooltip: tooltip,
      icon: icon,
      selected: targetOpen && _selectionControlsVisible,
      onPressed: () => _toggleSelectionControlsFor(context, target),
    );
  }

  Widget? _buildPromotionResultCard({
    required LightcoreController controller,
    required bool compact,
  }) {
    final component = _promotionResultComponent;
    if (component == null || !widget.showBattleHud) {
      return null;
    }
    return _Layer2ComponentResultCard(
      controller: controller,
      component: component,
      compact: compact,
      onDismissed: () => setState(() => _promotionResultComponent = null),
    );
  }

  Widget _buildBattleLayout({
    required BuildContext context,
    required LightcoreController controller,
    required OuterTowerState? selected,
    required bool compact,
  }) {
    final inset = compact ? 12.0 : 16.0;
    final topInset = inset + widget.topOverlayInset;
    final bottomInset = inset + widget.bottomOverlayInset;
    final selectionOverlay = _buildSelectionOverlay(
      context: context,
      controller: controller,
      selected: selected,
      compact: compact,
    );
    final dockOpen = selectionOverlay != null;
    final selectionHud = dockOpen
        ? null
        : _buildSelectionHud(
            context: context,
            controller: controller,
            selected: selected,
          );
    final promotionResultCard = _buildPromotionResultCard(
      controller: controller,
      compact: compact,
    );
    final shellVisibilityHud = _buildShellVisibilityHud(
      controller: controller,
      compact: compact,
    );
    final rebuildHudVisible =
        widget.showBattleHud && controller.layerRebuildEnabled;
    final layer1ShellCompleteCard =
        rebuildHudVisible &&
            controller.layerRunState.shellReady &&
            controller.latestCompletedLayer1Shell != null
        ? _Layer1ShellCompleteCard(controller: controller)
        : null;
    final overdriveHudVisible =
        !rebuildHudVisible &&
        !dockOpen &&
        widget.showBattleHud &&
        controller.showManualOverdriveHud;

    return Stack(
      children: [
        Positioned.fill(
          child: _buildGameCanvas(compact ? 20 : 0, dockOpen: dockOpen),
        ),
        if (!rebuildHudVisible &&
            widget.showBattleHud &&
            shellVisibilityHud != null)
          Positioned(
            right: inset,
            top: math.max(inset, topInset - (compact ? 22 : 10)),
            child: shellVisibilityHud,
          ),
        if (rebuildHudVisible)
          Positioned(
            left: inset,
            right: inset,
            top: topInset,
            child: _LayerRebuildTopHud(controller: controller),
          ),
        if (layer1ShellCompleteCard != null)
          Positioned(
            left: inset,
            right: inset,
            top: topInset + (compact ? 64 : 72),
            child: layer1ShellCompleteCard,
          ),
        if (widget.showBattleHud &&
            !controller.swarmActivated &&
            !rebuildHudVisible)
          Align(
            alignment: const Alignment(0, -0.08),
            child: _BattlePlayButton(
              compact: compact,
              onPressed: () {
                LightcoreAudio.instance.playSfx(LightcoreSfx.uiTap);
                controller.startBattle(showBanner: false);
                setState(() {
                  _statsTarget = null;
                  _panelFocus = _BattlePanelFocus.none;
                  _selectionControlsVisible = true;
                });
              },
            ),
          ),
        if (widget.showBattleHud && selectionHud != null && !rebuildHudVisible)
          Positioned(left: inset, bottom: bottomInset, child: selectionHud),
        if (overdriveHudVisible)
          Positioned(
            right: inset,
            bottom: bottomInset,
            child: _buildOverdriveHud(),
          ),
        if (widget.showBattleHud && selectionOverlay != null)
          Positioned(
            left: inset,
            right: compact ? inset : null,
            bottom: bottomInset,
            child: selectionOverlay,
          ),
        if (rebuildHudVisible && selectionOverlay == null)
          Positioned(
            left: inset,
            right: inset,
            bottom: bottomInset,
            child: _LayerRebuildActionDock(controller: controller),
          ),
        if (promotionResultCard != null)
          Positioned(
            left: inset,
            right: inset,
            top: topInset + (compact ? 86 : 72),
            child: Align(
              alignment: Alignment.topCenter,
              child: promotionResultCard,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Offstage(
      offstage: !widget.isActive,
      child: Focus(
        focusNode: _shortcutFocusNode,
        autofocus: widget.isActive,
        canRequestFocus: widget.isActive,
        onKeyEvent: _handleShortcutKey,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final selected = controller.selectedSlotOrNull;

            return LayoutBuilder(
              builder: (context, constraints) {
                final useStackedLayout =
                    constraints.maxWidth < 760 || constraints.maxHeight < 760;

                return _buildBattleLayout(
                  context: context,
                  controller: controller,
                  selected: selected,
                  compact: useStackedLayout,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// L1L2_REBUILD_SAFE: Wave 10 completion is explicit without exposing a playable Layer 2 board yet.
class _Layer1ShellCompleteCard extends StatelessWidget {
  const _Layer1ShellCompleteCard({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final shell = controller.latestCompletedLayer1Shell;
    if (shell == null) {
      return const SizedBox.shrink();
    }
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LightcorePalette.solar.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: LightcorePalette.solar.withValues(alpha: 0.16),
            blurRadius: 18,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.hexagon_rounded,
                  color: LightcorePalette.solar,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Layer 1 Shell Complete',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: LightcorePalette.solar,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  controller.latestCompletedLayer1ShellLocationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: LightcorePalette.mist.withValues(alpha: 0.74),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              shell.summaryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelLarge?.copyWith(
                color: LightcorePalette.mist,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Colors: ${shell.colorOddsLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.74),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Projectile: ${shell.projectileOddsLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: LightcorePalette.aether,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Payload: ${shell.payloadOddsLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: LightcorePalette.violet,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: controller.startLayer1Run,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Start New Run'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// L1L2_REBUILD_SAFE: Always-visible Layer 1 HUD replaces old currency-forward battle chrome.
class _LayerRebuildTopHud extends StatelessWidget {
  const _LayerRebuildTopHud({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shellProgress =
        controller.layer1ShellProgressWave /
        LightcoreController.layer1CompletionWave;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.panel.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LightcorePalette.stroke.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _LayerRebuildHudChip(
                  icon: Icons.radar_rounded,
                  label: 'Wave',
                  value: '${controller.layerRunState.wave}',
                  tint: LightcorePalette.aether,
                ),
                _LayerRebuildHudChip(
                  icon: Icons.bolt_rounded,
                  label: controller.sparksLabel,
                  value: '${controller.sparks}',
                  tint: LightcorePalette.solar,
                ),
                _LayerRebuildHudChip(
                  icon: Icons.auto_awesome_rounded,
                  label: controller.starBoltsLabel,
                  value: '${controller.starBolts}',
                  tint: LightcorePalette.violet,
                ),
                _LayerRebuildHudChip(
                  icon: Icons.favorite_rounded,
                  label: 'Core',
                  value: '${controller.coreState.coreStability.round()}%',
                  tint: LightcorePalette.verdant,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              controller.layer1ShellProgressLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelLarge?.copyWith(
                color: LightcorePalette.mist,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: shellProgress.clamp(0.0, 1.0),
                backgroundColor: LightcorePalette.abyss.withValues(alpha: 0.8),
                color: LightcorePalette.solar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// L1L2_REBUILD_SAFE: Compact chip for rebuilt HUD resources and status.
class _LayerRebuildHudChip extends StatelessWidget {
  const _LayerRebuildHudChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: tint, size: 16),
        const SizedBox(width: 5),
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: LightcorePalette.mist.withValues(alpha: 0.66),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: textTheme.labelLarge?.copyWith(
            color: LightcorePalette.mist,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// L1L2_REBUILD_SAFE: Main rebuilt action dock exposes global upgrades while tower-specific actions remain on tower selection.
class _LayerRebuildActionDock extends StatefulWidget {
  const _LayerRebuildActionDock({required this.controller});

  final LightcoreController controller;

  @override
  State<_LayerRebuildActionDock> createState() =>
      _LayerRebuildActionDockState();
}

class _LayerRebuildActionDockState extends State<_LayerRebuildActionDock> {
  bool _starBoltUpgradesOpen = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.panel.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LightcorePalette.stroke.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 132,
                  child: FilledButton.icon(
                    onPressed: controller.layerRunState.active
                        ? controller.resetLayer1Run
                        : controller.startLayer1Run,
                    icon: Icon(
                      controller.layerRunState.active
                          ? Icons.restart_alt_rounded
                          : Icons.play_arrow_rounded,
                      size: 18,
                    ),
                    label: Text(
                      controller.layerRunState.active ? 'Reset' : 'Start Run',
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Global Tower Upgrades',
                    style: textTheme.labelLarge?.copyWith(
                      color: LightcorePalette.mist,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in LayerRunUpgradeType.values)
                  _LayerRunUpgradeButton(controller: controller, type: type),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(
                () => _starBoltUpgradesOpen = !_starBoltUpgradesOpen,
              ),
              icon: Icon(
                _starBoltUpgradesOpen
                    ? Icons.expand_more_rounded
                    : Icons.chevron_right_rounded,
                size: 18,
              ),
              label: Text(
                'Star Bolt Upgrades (${controller.starBolts})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (_starBoltUpgradesOpen) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in LayerPersistentUpgradeType.values)
                    _LayerPersistentUpgradeButton(
                      controller: controller,
                      type: type,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// L1L2_REBUILD_SAFE: Collapsed persistent upgrade drawer gives Star Bolts a rebuild-only spend surface.
class _LayerPersistentUpgradeButton extends StatelessWidget {
  const _LayerPersistentUpgradeButton({
    required this.controller,
    required this.type,
  });

  final LightcoreController controller;
  final LayerPersistentUpgradeType type;

  @override
  Widget build(BuildContext context) {
    final rank = controller.layerPersistentProgress.rankFor(type);
    final cost = controller.layerPersistentUpgradeCost(type);
    return SizedBox(
      width: 144,
      child: OutlinedButton(
        onPressed: controller.canBuyPersistentUpgrade(type)
            ? () => controller.buyPersistentUpgrade(type)
            : null,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text('${type.label} Lv. $rank\n$cost Star Bolts'),
      ),
    );
  }
}

// L1L2_REBUILD_SAFE: Sparks purchase button for rebuilt per-run combat upgrades.
class _LayerRunUpgradeButton extends StatelessWidget {
  const _LayerRunUpgradeButton({required this.controller, required this.type});

  final LightcoreController controller;
  final LayerRunUpgradeType type;

  @override
  Widget build(BuildContext context) {
    final rank = controller.layerRunState.rankFor(type);
    final cost = controller.layerRunUpgradeCost(type);
    return SizedBox(
      width: 144,
      child: OutlinedButton(
        onPressed: controller.canBuyRunUpgrade(type)
            ? () => controller.buyRunUpgrade(type)
            : null,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text('${type.label} Lv. $rank\n$cost Sparks'),
      ),
    );
  }
}

class _Layer2ComponentResultCard extends StatelessWidget {
  const _Layer2ComponentResultCard({
    required this.controller,
    required this.component,
    required this.compact,
    required this.onDismissed,
  });

  final LightcoreController controller;
  final Layer2ComponentState component;
  final bool compact;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final current = controller.layer2ComponentById(component.id) ?? component;
    final revealedRegions = controller.threatRegions
        .where((state) => state.revealed)
        .map((state) => controller.threatRegionConfigById(state.regionId))
        .whereType<ThreatRegionConfig>()
        .toList(growable: false);
    final assignedRegion = current.equippedRegionId == null
        ? null
        : controller.threatRegionConfigById(current.equippedRegionId!);
    final tint = current.projectileAffinity.color;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 380 : 520),
      child: AuroraPanel(
        tint: tint,
        radius: 18,
        padding: EdgeInsets.all(compact ? 12 : 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, color: tint),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Layer 2 Component Created',
                        style: textTheme.titleMedium?.copyWith(
                          color: LightcorePalette.mist,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        current.signatureLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: LightcorePalette.mist.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss result',
                  onPressed: onDismissed,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _BattleResultChip(label: 'Wave ${current.reachedWave}'),
                _BattleResultChip(
                  label: 'Layer 2 Lv ${current.reachedWave ~/ 10}',
                ),
                _BattleResultChip(
                  label:
                      '${current.subtraits.length} subtrait${current.subtraits.length == 1 ? '' : 's'}',
                ),
                _BattleResultChip(
                  label: controller.layer2ComponentOutputLabel(current),
                ),
                _BattleResultChip(
                  label: assignedRegion == null
                      ? 'Unassigned'
                      : 'Assigned: ${assignedRegion.name}',
                ),
              ],
            ),
            if (current.subtraits.isNotEmpty) ...[
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final trait in current.subtraits)
                    _BattleResultChip(
                      label:
                          '${trait.type.label} +${(trait.value * 100).toStringAsFixed(1)}%',
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      controller.toggleLayer2ComponentFavorite(current.id),
                  icon: Icon(
                    current.favorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                  ),
                  label: Text(current.favorite ? 'Kept' : 'Keep Roll'),
                ),
                if (revealedRegions.isNotEmpty)
                  PopupMenuButton<String>(
                    tooltip: 'Assign component to an area',
                    onSelected: (regionId) {
                      controller.equipLayer2ComponentToRegion(
                        componentId: current.id,
                        regionId: regionId,
                      );
                    },
                    itemBuilder: (context) => [
                      for (final region in revealedRegions)
                        PopupMenuItem(
                          value: region.id,
                          child: Text(region.name),
                        ),
                    ],
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: LightcorePalette.stroke),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.public_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Assign Area'),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleResultChip extends StatelessWidget {
  const _BattleResultChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.abyss.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LightcorePalette.stroke.withValues(alpha: 0.36),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: LightcorePalette.mist,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _BattleControlPanel extends StatelessWidget {
  const _BattleControlPanel({
    required this.controller,
    required this.selected,
    required this.panelFocus,
    required this.onBuildTower,
  });

  final LightcoreController controller;
  final OuterTowerState? selected;
  final _BattlePanelFocus panelFocus;
  final bool Function(int slotIndex, TowerConfig config) onBuildTower;

  @override
  Widget build(BuildContext context) {
    final rangePreview = controller.canUpgradeCoreRange
        ? '${controller.coreRangeLabel} -> ${controller.nextCoreRangeLabel}'
        : '${controller.coreRangeLabel} max';
    final fireSpeedPreview = controller.canUpgradeCoreFireSpeed
        ? '${controller.coreFireSpeedLabel} -> ${controller.nextCoreFireSpeedLabel}'
        : '${controller.coreFireSpeedLabel} max';
    final chargeBufferPreview = controller.canUpgradeCoreQueueLimit
        ? '${controller.coreQueueCapacityLabel} -> ${controller.nextCoreQueueCapacityLabel}'
        : '${controller.coreQueueCapacityLabel} max';
    final multiShotPreview = controller.canUpgradeCoreMultiShot
        ? '${controller.coreMultiShotLabel} -> ${controller.nextCoreMultiShotLabel}'
        : '${controller.coreMultiShotLabel} max';
    if (selected == null) {
      if (panelFocus != _BattlePanelFocus.core) {
        return const SizedBox.shrink();
      }
      return _CoreStatsPanel(
        controller: controller,
        rangePreview: rangePreview,
        fireSpeedPreview: fireSpeedPreview,
        chargeBufferPreview: chargeBufferPreview,
        multiShotPreview: multiShotPreview,
      );
    }

    if (selected!.isFabricating) {
      return _TowerFabricationPanel(controller: controller, tower: selected!);
    }

    if (selected!.isBuilt) {
      if (controller.layerRebuildEnabled) {
        return _LayerRebuildFeederPanel(
          controller: controller,
          tower: selected!,
          slotIndex: selected!.slotIndex,
        );
      }
      return _LiveTowerUpgradePanel(
        controller: controller,
        tower: selected!,
        slotIndex: selected!.slotIndex,
      );
    }

    if (controller.layerRebuildEnabled) {
      return _LayerRebuildFeederBuildPanel(
        key: ValueKey<String>(
          'layer-rebuild-feeder-choice-${selected!.slotIndex}',
        ),
        controller: controller,
        slot: selected!,
      );
    }

    return _EmptySlotPanel(
      controller: controller,
      slot: selected!,
      onBuildTower: onBuildTower,
    );
  }
}

// L1L2_REBUILD_SAFE: Empty feeder hexes require player-selected color before spending Sparks.
class _LayerRebuildFeederBuildPanel extends StatefulWidget {
  const _LayerRebuildFeederBuildPanel({
    super.key,
    required this.controller,
    required this.slot,
  });

  final LightcoreController controller;
  final OuterTowerState slot;

  @override
  State<_LayerRebuildFeederBuildPanel> createState() =>
      _LayerRebuildFeederBuildPanelState();
}

class _LayerRebuildFeederBuildPanelState
    extends State<_LayerRebuildFeederBuildPanel> {
  String? _selectedConfigId;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final slotIndex = widget.slot.slotIndex;
    final textTheme = Theme.of(context).textTheme;
    final choices = controller.layer1FeederBuildChoices;
    final selected = choices
        .where((choice) => choice.id == _selectedConfigId)
        .firstOrNull;
    final cost = controller.layer1FeederBuildCost(slotIndex);
    final canBuild =
        selected != null &&
        controller.layerRunState.active &&
        controller.sparks >= cost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.add_circle_rounded,
              color: LightcorePalette.aether,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Choose Feeder ${slotIndex + 1}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: LightcorePalette.mist,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '$cost Sparks',
              style: textTheme.labelLarge?.copyWith(
                color: LightcorePalette.solar,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Choose this feeder color. The selected color, projectile, and payload are added to the completed Layer 1 shell odds.',
          style: textTheme.labelSmall?.copyWith(
            color: LightcorePalette.mist.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: choices.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final choice = choices[index];
              return SizedBox(
                width: 116,
                child: _TowerPrismChoiceTile(
                  config: choice,
                  selected: choice.id == _selectedConfigId,
                  onPressed: () =>
                      setState(() => _selectedConfigId = choice.id),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        if (selected == null)
          Text(
            'Select a color to install this feeder.',
            style: textTheme.bodyMedium?.copyWith(
              color: LightcorePalette.mist.withValues(alpha: 0.72),
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: selected.affinity.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected.affinity.color.withValues(alpha: 0.38),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(
                            color: selected.affinity.color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${selected.affinity.label} • ${selected.defaultProjectileType.label} • ${selected.defaultPayloadType.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(
                            color: LightcorePalette.mist.withValues(
                              alpha: 0.78,
                            ),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: canBuild
                        ? () => controller.buildLayer1FeederAt(
                            slotIndex,
                            config: selected,
                          )
                        : null,
                    icon: const Icon(Icons.hexagon_rounded, size: 18),
                    label: Text('Install ${selected.affinity.label}'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// L1L2_REBUILD_SAFE: Selected feeders use rebuilt Sparks copy/actions instead of legacy Wave Marks and Lumens.
class _LayerRebuildFeederPanel extends StatelessWidget {
  const _LayerRebuildFeederPanel({
    required this.controller,
    required this.tower,
    required this.slotIndex,
  });

  final LightcoreController controller;
  final OuterTowerState tower;
  final int slotIndex;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final config = tower.config;
    final affinity = config?.affinity ?? PrototypeAffinity.neutral;
    final tint = affinity.color;
    final projectile = config?.defaultProjectileType.label ?? 'Core Shot';
    final payload = config?.defaultPayloadType.label ?? PayloadType.none.label;
    final healthValue = controller.towerHealthFraction(tower);
    final feedLevel = tower.hasTowerProgression ? tower.level : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.hub_rounded, color: tint, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Feeder Slot ${slotIndex + 1}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              'Feeds Core',
              style: textTheme.labelMedium?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.72),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TowerHealthBar(
          value: healthValue,
          label: 'Feeder Integrity',
          color: tint,
          height: 8,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _BattleUpgradeChip(
              label: 'Color',
              value: affinity.shortLabel,
              tint: tint,
            ),
            _BattleUpgradeChip(
              label: 'Feed Level',
              value: 'Lv $feedLevel',
              tint: tint,
            ),
            _BattleUpgradeChip(
              label: 'Projectile',
              value: projectile,
              tint: tint,
            ),
            _BattleUpgradeChip(label: 'Payload', value: payload, tint: tint),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'This feeder adds its color, projectile, and payload to the Layer 1 shell odds.',
          style: textTheme.labelSmall?.copyWith(
            color: LightcorePalette.mist.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _BattleUpgradeGrid(
          children: [
            _LayerFeederTuneButton(
              controller: controller,
              type: LayerRunUpgradeType.damage,
              tint: tint,
            ),
            _LayerFeederTuneButton(
              controller: controller,
              type: LayerRunUpgradeType.fireRate,
              tint: tint,
            ),
            _LayerFeederTuneButton(
              controller: controller,
              type: LayerRunUpgradeType.multishot,
              tint: tint,
            ),
            _LayerFeederTuneButton(
              controller: controller,
              type: LayerRunUpgradeType.queueSize,
              tint: tint,
            ),
          ],
        ),
      ],
    );
  }
}

// L1L2_REBUILD_SAFE: Tower-selection tuning mirrors global core upgrades and spends Sparks only.
class _LayerFeederTuneButton extends StatelessWidget {
  const _LayerFeederTuneButton({
    required this.controller,
    required this.type,
    required this.tint,
  });

  final LightcoreController controller;
  final LayerRunUpgradeType type;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rank = controller.layerRunState.rankFor(type);
    final cost = controller.layerRunUpgradeCost(type);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.abyss.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Core Lv. $rank',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: tint,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: FilledButton(
                onPressed: controller.canBuyRunUpgrade(type)
                    ? () => controller.buyRunUpgrade(type)
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  '$cost Sparks',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveTowerUpgradePanel extends StatelessWidget {
  const _LiveTowerUpgradePanel({
    required this.controller,
    required this.tower,
    required this.slotIndex,
  });

  final LightcoreController controller;
  final OuterTowerState tower;
  final int slotIndex;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint =
        tower.config?.affinity.color ??
        tower.childAffinity?.color ??
        LightcorePalette.layer2;
    final upgradeOptions = controller.towerUpgradeOptionsFor(tower);
    final healthLabel = controller.towerHealthLabel(tower);
    final healthValue = controller.towerHealthFraction(tower);
    final showLayerOneEconomy =
        controller.activeLayer.tier == 1 &&
        !controller.activeLayerHasParentSlot;
    final levelLabel = tower.hasTowerProgression
        ? 'Lv ${tower.level}/${LightcoreController.maxTowerLevel}'
        : 'Layer ${tower.childLayerTier ?? controller.activeLayer.tier}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                controller.towerDisplayName(tower),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(color: tint),
              ),
            ),
            Tooltip(
              message: 'Full tower stats',
              child: TextButton.icon(
                key: ValueKey<String>('tower-$slotIndex-full-stats-button'),
                onPressed: () => showTowerDetailOverlay(
                  context: context,
                  controller: controller,
                  slotIndex: slotIndex,
                ),
                icon: const Icon(Icons.assessment_rounded, size: 18),
                label: const Text('Full Stats'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TowerHealthBar(
          value: healthValue,
          label: healthLabel,
          color: tint,
          height: 8,
        ),
        if (showLayerOneEconomy) ...[
          const SizedBox(height: 8),
          _LayerOneCurrencyStrip(controller: controller),
        ],
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _BattleUpgradeChip(
              label: 'Selected Slot',
              value: '${slotIndex + 1}',
              tint: tint,
            ),
            _BattleUpgradeChip(
              label: 'Tower Level',
              value: levelLabel,
              tint: tint,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (tower.hasTowerProgression) ...[
          _TowerLevelUpgradeButton(
            controller: controller,
            tower: tower,
            slotIndex: slotIndex,
            tint: tint,
          ),
          const SizedBox(height: 8),
        ],
        _BattleUpgradeGrid(
          children: [
            for (final upgrade in upgradeOptions)
              _BattleTowerStatUpgradeButton(
                controller: controller,
                tower: tower,
                slotIndex: slotIndex,
                upgrade: upgrade,
                tint: tint,
              ),
          ],
        ),
      ],
    );
  }
}

class _TowerLevelUpgradeButton extends StatelessWidget {
  const _TowerLevelUpgradeButton({
    required this.controller,
    required this.tower,
    required this.slotIndex,
    required this.tint,
  });

  final LightcoreController controller;
  final OuterTowerState tower;
  final int slotIndex;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxed = tower.level >= LightcoreController.maxTowerLevel;
    final cost = controller.towerLevelUpgradeCost(tower);
    final usesWaveMarks = controller.towerLevelUsesWaveMarks(tower);
    final canUpgrade = controller.canUpgradeTowerLevel(slotIndex);
    final nextLevel = (tower.level + 1).clamp(
      1,
      LightcoreController.maxTowerLevel,
    );
    final costLabel = maxed
        ? 'Max'
        : usesWaveMarks
        ? '$cost Wave Mark${cost == 1 ? '' : 's'}'
        : '$cost Lumens';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.42)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(Icons.keyboard_double_arrow_up_rounded, color: tint, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level Tower',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: LightcorePalette.mist,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    maxed
                        ? 'Lv ${tower.level}/5'
                        : 'Lv ${tower.level} -> $nextLevel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: tint,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 36,
              child: FilledButton(
                onPressed: canUpgrade
                    ? () => controller.upgradeTower(slotIndex)
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  costLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleTowerStatUpgradeButton extends StatelessWidget {
  const _BattleTowerStatUpgradeButton({
    required this.controller,
    required this.tower,
    required this.slotIndex,
    required this.upgrade,
    required this.tint,
  });

  final LightcoreController controller;
  final OuterTowerState tower;
  final int slotIndex;
  final TowerUpgradeOptionState upgrade;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statMaxed = upgrade.rank >= LightcoreController.maxTowerUpgradeRank;
    final cost = controller.towerStatUpgradeCost(tower, upgrade);
    final canUpgrade =
        !controller.activeLayerPassiveOnly &&
        !tower.isFabricating &&
        !statMaxed &&
        controller.lumens >= cost;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.abyss.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    upgrade.type.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${upgrade.rank}/${LightcoreController.maxTowerUpgradeRank}',
                  style: textTheme.labelSmall?.copyWith(
                    color: LightcorePalette.solar,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              controller.towerUpgradeEffectLabel(upgrade),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: tint,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: FilledButton(
                onPressed: canUpgrade
                    ? () => controller.upgradeTowerStat(slotIndex, upgrade.type)
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  statMaxed ? 'Max' : '$cost Lumens',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleUpgradeChip extends StatelessWidget {
  const _BattleUpgradeChip({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text(
          '$label $value',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: LightcorePalette.mist,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LayerOneCurrencyStrip extends StatelessWidget {
  const _LayerOneCurrencyStrip({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LayerOneCurrencyCard(
            icon: Icons.hexagon_rounded,
            label: 'Wave Marks',
            value:
                '${controller.activeLayerRoundCurrency}/${LightcoreController.slotCount - 1}',
            helper: 'Wave-earned build + level',
            tint: LightcorePalette.solar,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _LayerOneCurrencyCard(
            icon: Icons.bolt_rounded,
            label: 'Lumens',
            value: '${controller.lumens}',
            helper: 'Kill-earned stat tuning',
            tint: LightcorePalette.aether,
          ),
        ),
      ],
    );
  }
}

class _LayerOneCurrencyCard extends StatelessWidget {
  const _LayerOneCurrencyCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          children: [
            Icon(icon, color: tint, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: LightcorePalette.mist,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    helper,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: LightcorePalette.mist.withValues(alpha: 0.64),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelLarge?.copyWith(
                color: tint,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleUpgradeGrid extends StatelessWidget {
  const _BattleUpgradeGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 390 ? 3 : 2;
        const spacing = 8.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _CoreSummaryItem {
  const _CoreSummaryItem({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;
}

class _CoreSummaryGrid extends StatelessWidget {
  const _CoreSummaryGrid({required this.items});

  final List<_CoreSummaryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 460 ? 3 : 2;
        const spacing = 8.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: LightcorePalette.abyss.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.tint.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: LightcorePalette.mist.withValues(
                              alpha: 0.64,
                            ),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          item.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(
                            color: item.tint,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

void _showCoreFullStatsDialog(
  BuildContext context,
  LightcoreController controller, {
  required String rangePreview,
  required String fireSpeedPreview,
  required String chargeBufferPreview,
  required String multiShotPreview,
}) {
  final isLayerOneRoot =
      controller.activeLayer.tier == 1 && !controller.activeLayerHasParentSlot;
  showDialog<void>(
    context: context,
    builder: (context) {
      final mediaSize = MediaQuery.sizeOf(context);
      final textTheme = Theme.of(context).textTheme;
      final rows = <List<_InlineStatEntry>>[
        [
          _InlineStatEntry(
            label: 'Current Wave',
            value: '${controller.activeLayerWaveNumber}',
          ),
          _InlineStatEntry(
            label: 'Wave Progress',
            value:
                '${(controller.activeLayerWaveProgress * 100).toStringAsFixed(0)}%',
          ),
        ],
        [
          _InlineStatEntry(
            label: 'Wave Marks',
            value:
                '${controller.activeLayerRoundCurrency}/${LightcoreController.slotCount - 1}',
          ),
          _InlineStatEntry(label: 'Lumens', value: '${controller.lumens}'),
        ],
        [
          _InlineStatEntry(
            label: 'Core Level',
            value:
                '${controller.coreState.level}/${LightcoreController.maxCoreLevel}',
          ),
          _InlineStatEntry(
            label: 'Output',
            value: controller.outputEfficiencyLabel,
          ),
        ],
        [
          _InlineStatEntry(label: 'Range', value: rangePreview),
          _InlineStatEntry(label: 'Fire Rate', value: fireSpeedPreview),
        ],
        [
          _InlineStatEntry(label: 'Multi Shot', value: multiShotPreview),
          _InlineStatEntry(label: 'Power', value: controller.corePowerLabel),
        ],
        [
          _InlineStatEntry(
            label: 'Cooldown',
            value: controller.coreCooldownLabel,
          ),
          _InlineStatEntry(label: 'Crit', value: controller.coreCritLabel),
        ],
        [
          _InlineStatEntry(
            label: 'Final Damage',
            value: controller.coreFinalDamageLabel,
          ),
          _InlineStatEntry(
            label: 'Apex Damage',
            value: controller.coreBossDamageLabel,
          ),
        ],
        [
          _InlineStatEntry(
            label: 'Normal Damage',
            value: controller.coreNormalDamageLabel,
          ),
          _InlineStatEntry(
            label: 'Defense Pen',
            value: controller.coreDefensePenetrationLabel,
          ),
        ],
        [
          _InlineStatEntry(
            label: 'Min Damage',
            value: controller.coreMinDamageLabel,
          ),
          _InlineStatEntry(
            label: 'Max Damage',
            value: controller.coreMaxDamageLabel,
          ),
        ],
        if (!isLayerOneRoot)
          [
            _InlineStatEntry(label: 'Buffer', value: chargeBufferPreview),
            _InlineStatEntry(
              label: 'Queue',
              value: controller.coreQueueLoadLabel,
            ),
          ],
      ];

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 460,
            maxHeight: mediaSize.height - 48,
          ),
          child: AuroraPanel(
            tint: LightcorePalette.solar,
            radius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${controller.activeLayerLabel} Full Stats',
                        style: textTheme.titleLarge?.copyWith(
                          color: LightcorePalette.solar,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: _InlineStatList(rows: rows),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _CoreCommandButton extends StatelessWidget {
  const _CoreCommandButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final enabled = onPressed != null;
    return SizedBox(
      height: 44,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: enabled ? tint : LightcorePalette.panelRaised,
          foregroundColor: enabled
              ? LightcorePalette.night
              : LightcorePalette.mist,
          disabledBackgroundColor: LightcorePalette.panelRaised.withValues(
            alpha: 0.58,
          ),
          disabledForegroundColor: LightcorePalette.mist.withValues(
            alpha: 0.38,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$label $value',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  color: enabled
                      ? LightcorePalette.night
                      : LightcorePalette.mist.withValues(alpha: 0.42),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoreStatsPanel extends StatelessWidget {
  const _CoreStatsPanel({
    required this.controller,
    required this.rangePreview,
    required this.fireSpeedPreview,
    required this.chargeBufferPreview,
    required this.multiShotPreview,
  });

  final LightcoreController controller;
  final String rangePreview;
  final String fireSpeedPreview;
  final String chargeBufferPreview;
  final String multiShotPreview;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final openingCorePanel = controller.tutorialUsesBattleOnlyNavigation;
    final showOpeningForecast =
        controller.tutorialStep == LightcoreTutorialStep.raiseThreat ||
        controller.tutorialStep == LightcoreTutorialStep.pushNextArea;
    final showComponentForecast =
        controller.builtTowerCount > 0 &&
        (!openingCorePanel || showOpeningForecast);
    final isLayerOneRoot =
        controller.activeLayer.tier == 1 &&
        !controller.activeLayerHasParentSlot;
    final showChargeBufferControls = !openingCorePanel && !isLayerOneRoot;
    final showCoreStatUpgrades =
        controller.activeLayer.tier >= 2 &&
        controller.canTrainCoreStats &&
        controller.coreUpgradeOptions.isNotEmpty;
    final summaryItems = <_CoreSummaryItem>[
      if (!isLayerOneRoot) ...[
        _CoreSummaryItem(
          label: 'Range',
          value: rangePreview,
          tint: LightcorePalette.aether,
        ),
        _CoreSummaryItem(
          label: 'Fire Rate',
          value: fireSpeedPreview,
          tint: LightcorePalette.aether,
        ),
      ],
      _CoreSummaryItem(
        label: 'Multi Shot',
        value: multiShotPreview,
        tint: LightcorePalette.aether,
      ),
      if (showCoreStatUpgrades)
        _CoreSummaryItem(
          label: 'Stat Board',
          value:
              '${controller.coreUpgradePointsSpent}/${controller.coreUpgradePointsCap}',
          tint: LightcorePalette.solar,
        ),
    ];
    final coreActions = <Widget>[
      if (controller.canTrainCoreStats)
        _CoreCommandButton(
          icon: Icons.keyboard_double_arrow_up_rounded,
          label: isLayerOneRoot ? 'Power' : 'Shell',
          value: controller.canUpgradeCoreLevel
              ? '${controller.coreLevelUpgradeCost}L'
              : 'Max',
          tint: LightcorePalette.solar,
          onPressed:
              controller.canUpgradeCoreLevel &&
                  controller.lumens >= controller.coreLevelUpgradeCost
              ? controller.upgradeCoreLevel
              : null,
        ),
      _CoreCommandButton(
        icon: Icons.radar_rounded,
        label: 'Range',
        value: controller.canUpgradeCoreRange
            ? '${controller.coreRangeUpgradeCost}L'
            : 'Max',
        tint: LightcorePalette.aether,
        onPressed:
            controller.canUpgradeCoreRange &&
                controller.lumens >= controller.coreRangeUpgradeCost
            ? controller.upgradeCoreRange
            : null,
      ),
      _CoreCommandButton(
        icon: Icons.flash_on_rounded,
        label: 'Fire',
        value: controller.canUpgradeCoreFireSpeed
            ? '${controller.coreFireSpeedUpgradeCost}L'
            : 'Max',
        tint: LightcorePalette.aether,
        onPressed:
            controller.canUpgradeCoreFireSpeed &&
                controller.lumens >= controller.coreFireSpeedUpgradeCost
            ? controller.upgradeCoreFireSpeed
            : null,
      ),
      if (showChargeBufferControls)
        _CoreCommandButton(
          icon: Icons.all_inbox_rounded,
          label: 'Buffer',
          value: controller.canUpgradeCoreQueueLimit
              ? '${controller.coreQueueUpgradeCost}L'
              : 'Max',
          tint: LightcorePalette.aether,
          onPressed:
              controller.canUpgradeCoreQueueLimit &&
                  controller.lumens >= controller.coreQueueUpgradeCost
              ? controller.upgradeCoreQueueLimit
              : null,
        ),
      _CoreCommandButton(
        icon: Icons.hub_rounded,
        label: 'Multi',
        value: controller.canUpgradeCoreMultiShot
            ? '${controller.coreMultiShotUpgradeCost}L'
            : 'Max',
        tint: LightcorePalette.aether,
        onPressed:
            controller.canUpgradeCoreMultiShot &&
                controller.lumens >= controller.coreMultiShotUpgradeCost
            ? controller.upgradeCoreMultiShot
            : null,
      ),
      if (controller.coreEnergyUnlocked)
        _CoreCommandButton(
          icon: Icons.battery_charging_full_rounded,
          label: 'Energy',
          value: controller.canUpgradeCoreEnergyCapacity
              ? '${controller.coreEnergyCapacityUpgradeCost}L'
              : 'Max',
          tint: LightcorePalette.violet,
          onPressed:
              controller.canUpgradeCoreEnergyCapacity &&
                  controller.lumens >= controller.coreEnergyCapacityUpgradeCost
              ? controller.upgradeCoreEnergyCapacity
              : null,
        ),
      if (controller.coreEnergyUnlocked)
        _CoreCommandButton(
          icon: Icons.bolt_rounded,
          label: 'Recover',
          value: controller.canUpgradeCoreEnergyRecovery
              ? '${controller.coreEnergyRecoveryUpgradeCost}L'
              : 'Max',
          tint: LightcorePalette.violet,
          onPressed:
              controller.canUpgradeCoreEnergyRecovery &&
                  controller.lumens >= controller.coreEnergyRecoveryUpgradeCost
              ? controller.upgradeCoreEnergyRecovery
              : null,
        ),
      if (controller.hasSourceLayer)
        _CoreCommandButton(
          icon: Icons.unfold_less_double_rounded,
          label: 'Source',
          value: 'Open',
          tint: LightcorePalette.mist,
          onPressed: controller.enterSourceLayer,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '${controller.activeLayerLabel} Core',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(
                  color: LightcorePalette.solar,
                ),
              ),
            ),
            TextButton.icon(
              key: const ValueKey<String>('core-full-stats-button'),
              onPressed: () => _showCoreFullStatsDialog(
                context,
                controller,
                rangePreview: rangePreview,
                fireSpeedPreview: fireSpeedPreview,
                chargeBufferPreview: chargeBufferPreview,
                multiShotPreview: multiShotPreview,
              ),
              icon: const Icon(Icons.assessment_rounded, size: 18),
              label: const Text('Full Stats'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLayerOneRoot)
          _LayerOneCurrencyStrip(controller: controller)
        else
          _CoreSummaryGrid(items: summaryItems),
        const SizedBox(height: 10),
        _BattleUpgradeGrid(children: coreActions),
        if (showCoreStatUpgrades) ...[
          const SizedBox(height: 10),
          Text(
            'Core Stat Board',
            style: textTheme.titleSmall?.copyWith(
              color: LightcorePalette.mist.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          _BattleUpgradeGrid(
            children: [
              for (final upgrade in controller.coreUpgradeOptions)
                _CoreUpgradeStatCard(
                  controller: controller,
                  upgrade: upgrade,
                  tint: LightcorePalette.solar,
                ),
            ],
          ),
        ],
        if (controller.queuedAmmoPackets.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Shot Queue',
            style: textTheme.titleSmall?.copyWith(
              color: LightcorePalette.mist,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Charged shots auto-target anomalies. Reorder packets before they fire.',
            style: textTheme.bodySmall?.copyWith(
              color: LightcorePalette.mist.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              for (
                var index = 0;
                index < controller.queuedAmmoPackets.length;
                index += 1
              )
                _QueuedAmmoPacketRow(
                  packet: controller.queuedAmmoPackets[index],
                  index: index,
                  total: controller.queuedAmmoPackets.length,
                  onMoveEarlier: () => controller.moveQueuedAmmoPacketEarlier(
                    controller.queuedAmmoPackets[index].id,
                  ),
                  onMoveLater: () => controller.moveQueuedAmmoPacketLater(
                    controller.queuedAmmoPackets[index].id,
                  ),
                ),
            ],
          ),
        ],
        if (showComponentForecast) ...[
          const SizedBox(height: 10),
          LayerOneComponentForecastPanel(
            controller: controller,
            compact: true,
            showLatestComponent: false,
          ),
        ],
      ],
    );
  }
}

class _CoreUpgradeStatCard extends StatelessWidget {
  const _CoreUpgradeStatCard({
    required this.controller,
    required this.upgrade,
    required this.tint,
  });

  final LightcoreController controller;
  final TowerUpgradeOptionState upgrade;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statMaxed = upgrade.rank >= LightcoreController.maxTowerUpgradeRank;
    final cost = controller.coreStatUpgradeCost(upgrade);
    final canUpgrade = !statMaxed && controller.lumens >= cost;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  upgrade.type.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${upgrade.rank}/${LightcoreController.maxTowerUpgradeRank}',
                style: textTheme.labelSmall?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            controller.coreUpgradeEffectLabel(upgrade),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          MeterBar(
            value: (upgrade.rank / LightcoreController.maxTowerUpgradeRank)
                .clamp(0.0, 1.0),
            color: tint,
            height: 5,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: FilledButton(
              onPressed: canUpgrade
                  ? () => controller.upgradeCoreStat(upgrade.type)
                  : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                statMaxed ? 'Max' : '${cost}L',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueuedAmmoPacketRow extends StatelessWidget {
  const _QueuedAmmoPacketRow({
    required this.packet,
    required this.index,
    required this.total,
    required this.onMoveEarlier,
    required this.onMoveLater,
  });

  final AmmoPacket packet;
  final int index;
  final int total;
  final VoidCallback onMoveEarlier;
  final VoidCallback onMoveLater;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = packet.affinity.color;
    final payloadLabel = packet.payloadType == PayloadType.none
        ? 'No payload'
        : packet.payloadType.label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: LightcorePalette.abyss.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tint.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 5,
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: textTheme.labelMedium?.copyWith(
                      color: tint,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      packet.projectileType.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: LightcorePalette.mist,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      payloadLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: LightcorePalette.mist.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Move earlier',
                visualDensity: VisualDensity.compact,
                onPressed: index == 0 ? null : onMoveEarlier,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
              IconButton(
                tooltip: 'Move later',
                visualDensity: VisualDensity.compact,
                onPressed: index >= total - 1 ? null : onMoveLater,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TowerFabricationPanel extends StatelessWidget {
  const _TowerFabricationPanel({required this.controller, required this.tower});

  final LightcoreController controller;
  final OuterTowerState tower;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = tower.config?.affinity.color ?? LightcorePalette.solar;
    final progress = tower.fabricationProgress.clamp(0.0, 1.0).toDouble();
    final refund = (tower.investedLumens * 0.7).round();
    final payloadType = controller.towerPayloadType(tower);
    final fabricationRows = [
      [
        _InlineStatEntry(label: 'Build', value: 'Growing'),
        _InlineStatEntry(
          label: 'Online',
          value: controller.towerFabricationRemainingLabel(tower),
        ),
      ],
      [
        _InlineStatEntry(
          label: 'Projectile',
          value: controller.towerProjectileLabel(tower),
        ),
        if (payloadType != PayloadType.none)
          _InlineStatEntry(
            label: 'Payload',
            value: controller.towerPayloadLabel(tower),
          ),
      ],
      [
        _InlineStatEntry(label: 'Slot', value: '${tower.slotIndex + 1}'),
        const _InlineStatEntry(label: 'Status', value: 'Building'),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.precision_manufacturing_rounded, color: tint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.towerDisplayName(tower),
                style: textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Building', style: textTheme.titleMedium?.copyWith(color: tint)),
        const SizedBox(height: 6),
        Text(
          controller.towerFabricationProgressLabel(tower),
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        MeterBar(value: progress, color: tint),
        const SizedBox(height: 10),
        _InlineStatList(rows: fabricationRows),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () => controller.sellTower(tower.slotIndex),
          child: Text('Cancel for ${refund.clamp(1, 1 << 30)}L'),
        ),
      ],
    );
  }
}

class _EmptySlotPanel extends StatefulWidget {
  const _EmptySlotPanel({
    required this.controller,
    required this.slot,
    required this.onBuildTower,
  });

  final LightcoreController controller;
  final OuterTowerState slot;
  final bool Function(int slotIndex, TowerConfig config) onBuildTower;

  @override
  State<_EmptySlotPanel> createState() => _EmptySlotPanelState();
}

class _EmptySlotPanelState extends State<_EmptySlotPanel> {
  String? _selectedConfigId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final controller = widget.controller;
    final slot = widget.slot;
    final childLayerBlockedLabel = widget.controller.isCompositeLayer
        ? widget.controller.childLayerCreationBlockedLabelForSlot(
            widget.slot.slotIndex,
          )
        : null;
    final usesLayerOneWaveBuild =
        controller.activeLayer.tier == 1 &&
        !controller.activeLayerHasParentSlot;
    final slotTitle = usesLayerOneWaveBuild
        ? slot.slotIndex == 0 && controller.builtTowerCount == 0
              ? 'First Relay'
              : 'Hex ${slot.slotIndex + 1} Relay'
        : 'Empty Slot ${slot.slotIndex + 1}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(slotTitle, style: textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          controller.isCompositeLayer
              ? 'This empty edge can create a new lower-class shell that shares the global economy.'
              : controller.tutorialNeedsTowerPaletteGate
              ? 'Choose one of two starter projectile styles. Comet Mortar is slower area pressure; Rayline Spire is steadier beam pressure.'
              : controller.tutorialShowsStarterProjectileChoices
              ? 'Choose one of two starter projectile styles. Thread Beam is steady single-target pressure; Shield Halo is a persistent guard ring.'
              : usesLayerOneWaveBuild
              ? 'Pick a prism style to activate this relay.'
              : 'Pick one of the unlocked color prisms to activate this surrounding slot.',
          style: textTheme.bodyMedium,
        ),
        if (usesLayerOneWaveBuild) ...[
          const SizedBox(height: 10),
          _LayerOneCurrencyStrip(controller: controller),
        ],
        const SizedBox(height: 14),
        controller.isCompositeLayer
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilledButton.icon(
                    onPressed: childLayerBlockedLabel == null
                        ? () => _showChildCoreAffinityPicker(
                            context,
                            controller,
                            slot.slotIndex,
                          )
                        : null,
                    icon: const TowerRingIcon(),
                    label: Text(
                      'Create Layer ${controller.activeLayer.tier - 1} Shell',
                    ),
                  ),
                  if (childLayerBlockedLabel != null) ...[
                    const SizedBox(height: 8),
                    Text(childLayerBlockedLabel, style: textTheme.bodyMedium),
                  ],
                ],
              )
            : _TowerBuildPicker(
                choices: controller.tutorialTowerChoices,
                selectedConfigId: _selectedConfigId,
                usesLayerOneWaveBuild: usesLayerOneWaveBuild,
                controller: controller,
                onSelect: (config) {
                  setState(() {
                    _selectedConfigId = config.id;
                  });
                },
                onBuildTower: (config) =>
                    widget.onBuildTower(slot.slotIndex, config),
              ),
      ],
    );
  }
}

class _BattleShellVisibilityHud extends StatelessWidget {
  const _BattleShellVisibilityHud({
    required this.compact,
    required this.expanded,
    required this.onPressed,
  });

  final bool compact;
  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 46.0;
    final label = expanded ? 'Collapse shell' : 'Expand shell';
    final icon = expanded
        ? Icons.unfold_less_double_rounded
        : Icons.unfold_more_double_rounded;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey<String>('battle-shell-collapse-button'),
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: LightcorePalette.panelRaised.withValues(alpha: 0.78),
                border: Border.all(
                  color: LightcorePalette.stroke.withValues(alpha: 0.52),
                ),
                boxShadow: [
                  BoxShadow(
                    color: LightcorePalette.night.withValues(alpha: 0.18),
                    blurRadius: 14,
                    spreadRadius: -6,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: LightcorePalette.mist.withValues(alpha: 0.84),
                size: compact ? 22 : 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BattlePlayButton extends StatefulWidget {
  const _BattlePlayButton({required this.compact, required this.onPressed});

  final bool compact;
  final VoidCallback onPressed;

  @override
  State<_BattlePlayButton> createState() => _BattlePlayButtonState();
}

class _BattlePlayButtonState extends State<_BattlePlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 82.0 : 96.0;
    final stageSize = widget.compact ? 156.0 : 178.0;
    return Tooltip(
      message: 'Start route',
      child: Semantics(
        button: true,
        label: 'Start route',
        child: SizedBox(
          width: stageSize,
          height: stageSize,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final pulse = Curves.easeInOut.transform(
                0.5 + (math.sin(_controller.value * math.pi * 2) * 0.5),
              );
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  _BattlePlayRing(
                    size: stageSize * (0.74 + (pulse * 0.1)),
                    alpha: 0.16 + (pulse * 0.16),
                    strokeWidth: 1.4,
                  ),
                  Transform.rotate(
                    angle: _controller.value * math.pi * 2,
                    child: SizedBox(
                      width: stageSize * 0.9,
                      height: stageSize * 0.9,
                      child: CustomPaint(
                        painter: _BattlePlayOrbitPainter(progress: pulse),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const ValueKey<String>('battle-play-button'),
                      borderRadius: BorderRadius.circular(size / 2),
                      onTap: widget.onPressed,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              LightcorePalette.mist.withValues(alpha: 0.98),
                              LightcorePalette.aether,
                              LightcorePalette.aether.withValues(alpha: 0.84),
                            ],
                            stops: const [0, 0.46, 1],
                          ),
                          border: Border.all(
                            color: LightcorePalette.mist.withValues(alpha: 0.9),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: LightcorePalette.aether.withValues(
                                alpha: 0.54 + (pulse * 0.18),
                              ),
                              blurRadius: 34 + (pulse * 16),
                              spreadRadius: 3 + (pulse * 2),
                            ),
                            BoxShadow(
                              color: LightcorePalette.night.withValues(
                                alpha: 0.36,
                              ),
                              blurRadius: 22,
                              spreadRadius: -8,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: LightcorePalette.night,
                          size: widget.compact ? 52 : 62,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: widget.compact ? 2 : 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: LightcorePalette.night.withValues(alpha: 0.66),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: LightcorePalette.aether.withValues(
                            alpha: 0.42,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        child: Text(
                          'START ROUTE',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: LightcorePalette.mist,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
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

class _BattlePlayRing extends StatelessWidget {
  const _BattlePlayRing({
    required this.size,
    required this.alpha,
    required this.strokeWidth,
  });

  final double size;
  final double alpha;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: LightcorePalette.aether.withValues(alpha: alpha),
          width: strokeWidth,
        ),
      ),
    );
  }
}

class _BattlePlayOrbitPainter extends CustomPainter {
  const _BattlePlayOrbitPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.42;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = LightcorePalette.aether.withValues(alpha: 0.34);
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var index = 0; index < 3; index += 1) {
      final start = (index * math.pi * 2 / 3) + (progress * 0.28);
      canvas.drawArc(rect, start, math.pi / 5.2, false, paint);
    }
    final sparkPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = LightcorePalette.mist.withValues(alpha: 0.5);
    for (var index = 0; index < 3; index += 1) {
      final angle = index * math.pi * 2 / 3;
      canvas.drawCircle(
        center.translate(math.cos(angle) * radius, math.sin(angle) * radius),
        2.2,
        sparkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BattlePlayOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BattleSelectionHud extends StatelessWidget {
  const _BattleSelectionHud({
    required this.tint,
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final Color tint;
  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: selected ? 'Hide $tooltip' : 'Show $tooltip',
      child: Semantics(
        button: true,
        toggled: selected,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey<String>('battle-tower-selection-button'),
            borderRadius: BorderRadius.circular(22),
            onTap: onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: LightcorePalette.panelRaised.withValues(alpha: 0.92),
                border: Border.all(
                  color: tint.withValues(alpha: selected ? 0.92 : 0.64),
                  width: selected ? 1.8 : 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tint.withValues(alpha: selected ? 0.28 : 0.16),
                    blurRadius: selected ? 22 : 16,
                    spreadRadius: selected ? 2 : 0,
                  ),
                ],
              ),
              child: Icon(icon, size: 34, color: tint),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualOverdriveHud extends StatefulWidget {
  const _ManualOverdriveHud({required this.controller});

  final LightcoreController controller;

  @override
  State<_ManualOverdriveHud> createState() => _ManualOverdriveHudState();
}

class _ManualOverdriveHudState extends State<_ManualOverdriveHud> {
  static const Duration _tapThreshold = Duration(milliseconds: 220);

  DateTime? _pressedAt;
  late final AppLifecycleListener _appLifecycleListener;

  @override
  void initState() {
    super.initState();
    _appLifecycleListener = AppLifecycleListener(
      onHide: _stopForLifecycleChange,
      onInactive: _stopForLifecycleChange,
      onPause: _stopForLifecycleChange,
      onDetach: _stopForLifecycleChange,
    );
  }

  void _stopForLifecycleChange() {
    _pressedAt = null;
    widget.controller.stopManualOverdrive();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pressedAt = widget.controller.isManualOverdriveHeld
        ? null
        : DateTime.now();
    LightcoreAudio.instance.playSfx(LightcoreSfx.overdriveStart);
    widget.controller.startManualOverdrive();
  }

  void _handlePointerEnd() {
    final pressedAt = _pressedAt;
    _pressedAt = null;
    widget.controller.stopManualOverdrive();
    LightcoreAudio.instance.playSfx(LightcoreSfx.overdriveEnd);
    if (pressedAt == null) {
      return;
    }
    if (DateTime.now().difference(pressedAt) <= _tapThreshold) {
      widget.controller.burstManualOverdrive();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    // Transient UI overlays can cancel the raw pointer sequence while the
    // player is still physically holding the button. Keep the overdrive live
    // until an explicit release or a lifecycle-driven stop happens.
    _pressedAt = null;
  }

  @override
  void dispose() {
    _appLifecycleListener.dispose();
    widget.controller.stopManualOverdrive();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final textTheme = Theme.of(context).textTheme;
    final permanentOwned = controller.hasPermanentOverdrive;
    final permanentActive = controller.hasActivePermanentOverdrive;
    final enabled = controller.canUseManualOverdrive;
    final held = controller.isManualOverdriveHeld;
    final charge = controller.manualOverdriveCharge;
    final tint = permanentOwned
        ? LightcorePalette.solar
        : !enabled
        ? LightcorePalette.stroke
        : held
        ? LightcorePalette.solar
        : charge > 0.02
        ? LightcorePalette.warning
        : LightcorePalette.aether;
    final textColor = permanentActive
        ? LightcorePalette.solar
        : LightcorePalette.mist;

    return Column(
      key: const ValueKey<String>('manual-overdrive-hud'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          controller.manualOverdriveMultiplierLabel,
          style: textTheme.titleMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Listener(
          key: const ValueKey<String>('battle-overdrive-button'),
          behavior: HitTestBehavior.opaque,
          onPointerDown: enabled ? _handlePointerDown : null,
          onPointerUp: enabled ? (_) => _handlePointerEnd() : null,
          onPointerCancel: enabled ? _handlePointerCancel : null,
          child: Opacity(
            opacity: permanentOwned || enabled ? 1 : 0.76,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: LightcorePalette.panelRaised.withValues(alpha: 0.92),
                border: Border.all(
                  color: tint.withValues(alpha: permanentActive ? 0.92 : 0.75),
                  width: permanentOwned ? 1.8 : 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tint.withValues(alpha: permanentActive ? 0.34 : 0.2),
                    blurRadius: permanentActive ? 22 : 16,
                    spreadRadius: permanentActive ? 2 : 0,
                  ),
                ],
              ),
              child: Icon(Icons.flash_on_rounded, size: 34, color: tint),
            ),
          ),
        ),
      ],
    );
  }
}

class _TowerBuildPicker extends StatelessWidget {
  const _TowerBuildPicker({
    required this.choices,
    required this.selectedConfigId,
    required this.usesLayerOneWaveBuild,
    required this.controller,
    required this.onSelect,
    required this.onBuildTower,
  });

  final List<TowerConfig> choices;
  final String? selectedConfigId;
  final bool usesLayerOneWaveBuild;
  final LightcoreController controller;
  final ValueChanged<TowerConfig> onSelect;
  final bool Function(TowerConfig config) onBuildTower;

  @override
  Widget build(BuildContext context) {
    TowerConfig? selected;
    for (final choice in choices) {
      if (choice.id == selectedConfigId) {
        selected = choice;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = choices.length >= 3 ? 3 : choices.length;
            final tileWidth = columns <= 0
                ? constraints.maxWidth
                : ((constraints.maxWidth - (10 * (columns - 1))) / columns)
                      .clamp(104.0, 132.0)
                      .toDouble();
            final tileHeight = choices.length > 6 ? 58.0 : 76.0;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final choice in choices)
                  SizedBox(
                    width: tileWidth,
                    height: tileHeight,
                    child: _TowerPrismChoiceTile(
                      config: choice,
                      selected: choice.id == selectedConfigId,
                      onPressed: () => onSelect(choice),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        if (selected == null)
          Text(
            'Select a prism to inspect its projectile style.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LightcorePalette.mist.withValues(alpha: 0.72),
            ),
          )
        else
          _SelectedTowerBuildDetails(
            config: selected,
            controller: controller,
            usesLayerOneWaveBuild: usesLayerOneWaveBuild,
            onBuildTower: () => onBuildTower(selected!),
          ),
      ],
    );
  }
}

class _TowerPrismChoiceTile extends StatelessWidget {
  const _TowerPrismChoiceTile({
    required this.config,
    required this.selected,
    required this.onPressed,
  });

  final TowerConfig config;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tint = config.affinity.color;
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected
        ? LightcorePalette.night
        : LightcorePalette.mist;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: selected ? LightcorePalette.night : tint,
        backgroundColor: tint.withValues(alpha: selected ? 0.92 : 0.2),
        side: BorderSide(
          color: selected
              ? LightcorePalette.mist.withValues(alpha: 0.92)
              : tint.withValues(alpha: 0.48),
          width: selected ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.15,
                    colors: [
                      tint.withValues(alpha: selected ? 0.26 : 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _ProjectileSymbolAccentPainter(
                  projectileType: config.defaultProjectileType,
                  color: foreground.withValues(alpha: selected ? 0.38 : 0.3),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      LightcorePalette.abyss.withValues(alpha: 0.18),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                child: Text(
                  config.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectileSymbolAccentPainter extends CustomPainter {
  const _ProjectileSymbolAccentPainter({
    required this.projectileType,
    required this.color,
  });

  final ProjectileType projectileType;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 7);
    final unit = math.min(size.width, size.height);
    paintProjectileSymbolGlyph(
      canvas,
      center,
      projectileType: projectileType,
      size: unit * 0.86,
      color: color,
    );
  }

  @override
  bool shouldRepaint(covariant _ProjectileSymbolAccentPainter oldDelegate) {
    return oldDelegate.projectileType != projectileType ||
        oldDelegate.color != color;
  }
}

class _SelectedTowerBuildDetails extends StatelessWidget {
  const _SelectedTowerBuildDetails({
    required this.config,
    required this.controller,
    required this.usesLayerOneWaveBuild,
    required this.onBuildTower,
  });

  final TowerConfig config;
  final LightcoreController controller;
  final bool usesLayerOneWaveBuild;
  final VoidCallback onBuildTower;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = config.affinity.color;
    final costLabel = usesLayerOneWaveBuild
        ? 'Requires Wave Marks'
        : '${controller.buildCostForConfig(config)} Lumens';
    final buttonLabel = usesLayerOneWaveBuild ? 'Build Relay' : 'Build Tower';
    final enabled =
        usesLayerOneWaveBuild ||
        controller.lumens >= controller.buildCostForConfig(config);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tint.withValues(alpha: 0.42)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox.square(
                      dimension: 24,
                      child: CustomPaint(
                        painter: _ProjectileSymbolAccentPainter(
                          projectileType: config.defaultProjectileType,
                          color: tint,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.name,
                        style: textTheme.titleMedium?.copyWith(
                          color: tint,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$costLabel • ${config.defaultProjectileType.label} • ${config.passiveLabel} • ${controller.towerFabricationDurationLabelForConfig(config)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: LightcorePalette.mist.withValues(alpha: 0.74),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: enabled ? onBuildTower : null,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(buttonLabel),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              config.summary,
              style: textTheme.bodyMedium?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.86),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineStatList extends StatelessWidget {
  const _InlineStatList({required this.rows});

  final List<List<_InlineStatEntry>> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.bodyMedium?.copyWith(
      color: LightcorePalette.mist.withValues(alpha: 0.64),
      fontWeight: FontWeight.w700,
    );
    final valueStyle = textTheme.bodyMedium?.copyWith(
      color: LightcorePalette.mist,
      height: 1.45,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          Text.rich(
            TextSpan(
              children: [
                for (
                  var entryIndex = 0;
                  entryIndex < rows[index].length;
                  entryIndex++
                ) ...[
                  if (entryIndex > 0)
                    TextSpan(text: '  •  ', style: valueStyle),
                  TextSpan(
                    text: '${rows[index][entryIndex].label} ',
                    style: labelStyle,
                  ),
                  TextSpan(
                    text: rows[index][entryIndex].value,
                    style: valueStyle,
                  ),
                ],
              ],
            ),
          ),
          if (index < rows.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _InlineStatEntry {
  const _InlineStatEntry({required this.label, required this.value});

  final String label;
  final String value;
}
