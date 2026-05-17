import 'dart:async';

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
import '../widgets/guided_focus_frame.dart';
import '../widgets/lightcore_quest_card.dart';
import '../widgets/meter_bar.dart';
import '../widgets/symbol_grid_tile.dart';
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
  static const double _overdriveHudHeight = 92;
  static const double _canvasTapSlop = 12;

  late LightcoreBattleGame _game;
  late final FocusNode _shortcutFocusNode;
  _BattlePanelFocus _panelFocus = _BattlePanelFocus.none;
  _BattleStatsTarget? _statsTarget;
  bool _selectionControlsVisible = true;
  Timer? _promotionStatsTimer;
  int? _activePromotionSequence;
  int? _canvasTapPointer;
  Offset? _canvasTapStart;
  bool _canvasTapCanceled = false;
  late final AppLifecycleListener _appLifecycleListener;

  @override
  void initState() {
    super.initState();
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
        setState(() {
          _panelFocus = _BattlePanelFocus.core;
          _statsTarget = const _BattleStatsTarget.core();
          _selectionControlsVisible = true;
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

  VoidCallback? _buildInspectAction(
    BuildContext context,
    LightcoreController controller,
    OuterTowerState? selected,
  ) {
    if (selected == null ||
        !selected.isBuilt ||
        selected.isFabricating ||
        selected.isChildLayerNode) {
      return null;
    }

    return () {
      controller.selectSlot(selected.slotIndex);
      showTowerDetailOverlay(
        context: context,
        controller: controller,
        slotIndex: selected.slotIndex,
      );
    };
  }

  Widget _buildGameCanvas(double radius) {
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
    if (event.buttons != kPrimaryButton || _canvasTapPointer != null) {
      _canvasTapCanceled = true;
      _logBattle('pointer-down-canceled', <String, Object?>{
        'buttons': event.buttons,
        'activePointer': _canvasTapPointer,
      });
      return;
    }
    _canvasTapPointer = event.pointer;
    _canvasTapStart = event.localPosition;
    _canvasTapCanceled = false;
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

  void _clearPanelFocus() {
    if (_panelFocus == _BattlePanelFocus.none) {
      return;
    }
    setState(() {
      _panelFocus = _BattlePanelFocus.none;
    });
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
    final wasCorePanelOpen =
        _panelFocus == _BattlePanelFocus.core && _selectionControlsVisible;
    controller.handleBattleCenterTap();
    setState(() {
      _statsTarget = const _BattleStatsTarget.core();
      if (wasCorePanelOpen) {
        _panelFocus = _BattlePanelFocus.core;
        _selectionControlsVisible = true;
      } else {
        _panelFocus = _BattlePanelFocus.none;
        _selectionControlsVisible = false;
      }
    });
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
    _logBattle('slot-tap', <String, Object?>{'slot': slotIndex});
    LightcoreAudio.instance.playSfx(LightcoreSfx.uiTap);
    final controller = widget.controller;
    final slot = slotIndex >= 0 && slotIndex < controller.slots.length
        ? controller.slots[slotIndex]
        : null;
    final target = slot != null && !slot.isLayerProject
        ? _BattleStatsTarget.slot(slotIndex)
        : null;
    final opensControls =
        slot != null &&
        !slot.isLayerProject &&
        (!slot.isBuilt ||
            slot.isFabricating ||
            controller.activeLayerPassiveOnly);
    controller.handleBattleSlotTap(slotIndex);
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

  bool _buildTutorialTowerAt(int slotIndex, TowerConfig config) {
    final started = widget.controller.tutorialStartTowerFabricationAt(
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
    LightcoreAudio.instance.playSfx(LightcoreSfx.uiCancel);
    widget.controller.toggleShellVisibility();
    _statsTarget = null;
    _selectionControlsVisible = true;
    _clearPanelFocus();
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

  bool _completeTowerStatsTutorialFor(_BattleStatsTarget target) {
    if (target.kind != _BattleStatsTargetKind.slot) {
      return false;
    }
    final slotIndex = target.slotIndex;
    if (slotIndex == null ||
        !widget.controller.tutorialHighlightsTowerStatsButton(slotIndex)) {
      return false;
    }
    widget.controller.markTutorialFirstTowerStatsOpened();
    return true;
  }

  void _toggleSelectionControlsFor(_BattleStatsTarget target) {
    if (!_isStatsTargetOpen(target)) {
      _openStatsTarget(target);
      _completeTowerStatsTutorialFor(target);
      return;
    }
    if (_completeTowerStatsTutorialFor(target)) {
      setState(() {
        _selectionControlsVisible = false;
      });
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
      return 'Build Hex ${selected.slotIndex + 1}';
    }
    if (selected.isFabricating) {
      return '${controller.towerDisplayName(selected)} fabrication';
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
          return '${controller.towerDisplayName(slot)} fabrication';
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

  bool _selectionButtonHighlighted(
    LightcoreController controller,
    _BattleStatsTarget target,
  ) {
    if (_tutorialOpenPanelBlocksCurrentStep(controller) &&
        _isStatsTargetOpen(target)) {
      return true;
    }
    switch (target.kind) {
      case _BattleStatsTargetKind.core:
        return controller.tutorialHighlightsCoreStats;
      case _BattleStatsTargetKind.slot:
        final slotIndex = target.slotIndex;
        return slotIndex != null &&
            (controller.tutorialHighlightsUpgradeButton(slotIndex) ||
                controller.tutorialHighlightsTowerStatsButton(slotIndex));
    }
  }

  String? _selectionButtonTapCueLabel(
    LightcoreController controller,
    _BattleStatsTarget target,
  ) {
    final targetOpen = _isStatsTargetOpen(target) && _selectionControlsVisible;
    if (_tutorialOpenPanelBlocksCurrentStep(controller) && targetOpen) {
      return 'Close panel';
    }
    switch (target.kind) {
      case _BattleStatsTargetKind.core:
        return controller.tutorialHighlightsCoreStats
            ? targetOpen
                  ? 'Core stats'
                  : 'Open stats'
            : null;
      case _BattleStatsTargetKind.slot:
        final slotIndex = target.slotIndex;
        if (slotIndex == null) {
          return null;
        }
        if (controller.tutorialHighlightsTowerStatsButton(slotIndex)) {
          return targetOpen ? 'Done' : 'Open stats';
        }
        if (controller.tutorialHighlightsUpgradeButton(slotIndex)) {
          return targetOpen ? 'Upgrade' : 'Open upgrades';
        }
        return null;
    }
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
    required VoidCallback? onInspect,
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

    final overlayContent = _BattleControlPanel(
      controller: controller,
      selected: selected,
      onInspect: onInspect,
      panelFocus: panelFocus,
      onBuildTower: _buildTutorialTowerAt,
    );

    final tint = _selectionTint(controller, selected, panelFocus);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: compact ? MediaQuery.sizeOf(context).width - 24 : 460,
        maxHeight: MediaQuery.sizeOf(context).height * (compact ? 0.42 : 0.5),
      ),
      child: AuroraPanel(
        tint: tint,
        radius: 20,
        padding: EdgeInsets.all(compact ? 12 : 14),
        child: SingleChildScrollView(child: overlayContent),
      ),
    );
  }

  Widget _buildOverdriveHud() {
    return _ManualOverdriveHud(controller: widget.controller);
  }

  Widget? _buildSelectionHud({
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
      highlighted: _selectionButtonHighlighted(controller, target),
      tapCueLabel: _selectionButtonTapCueLabel(controller, target),
      onPressed: () => _toggleSelectionControlsFor(target),
    );
  }

  Widget? _buildQuestPanel(
    LightcoreController controller, {
    required bool compact,
    String? instructionOverride,
  }) {
    if (!widget.showBattleHud ||
        !widget.showQuestPanel ||
        !widget.showBattleGuides ||
        !controller.hasActiveTutorial) {
      return null;
    }

    return LightcoreQuestCard(
      controller: controller,
      compact: compact,
      initiallyExpanded: false,
      instructionOverride: instructionOverride,
    );
  }

  Widget? _buildRaiseThreatPrompt(
    LightcoreController controller, {
    required bool compact,
  }) {
    if (!widget.showBattleHud || !controller.tutorialShowsBattleThreatPrompt) {
      return null;
    }
    return _RaiseThreatPrompt(
      compact: compact,
      label: controller.firstThreatChallengeLabel,
      enabled: controller.canStartFirstThreatChallenge,
      onPressed: () {
        LightcoreAudio.instance.playSfx(LightcoreSfx.uiConfirm);
        final started = controller.startFirstThreatChallenge();
        if (!started) {
          return;
        }
        setState(() {
          _statsTarget = null;
          _selectionControlsVisible = false;
          _panelFocus = _BattlePanelFocus.none;
        });
      },
    );
  }

  bool _tutorialOpenPanelBlocksCurrentStep(LightcoreController controller) {
    if (!_selectionControlsVisible) {
      return false;
    }
    return switch (controller.tutorialStep) {
      LightcoreTutorialStep.tapBattleCore ||
      LightcoreTutorialStep.tapFirstTower ||
      LightcoreTutorialStep.tapSecondShellTower ||
      LightcoreTutorialStep.pullFirstWhiteEnemy ||
      LightcoreTutorialStep.pullFirstRedEnemy ||
      LightcoreTutorialStep.setFirstEnemyTarget ||
      LightcoreTutorialStep.adjustEnemyCount ||
      LightcoreTutorialStep.openTowerMatrix ||
      LightcoreTutorialStep.openStore ||
      LightcoreTutorialStep.claimBattlePassReward ||
      LightcoreTutorialStep.openBossPulls ||
      LightcoreTutorialStep.armFirstBoss ||
      LightcoreTutorialStep.defeatFirstBoss ||
      LightcoreTutorialStep.openEquipment ||
      LightcoreTutorialStep.openManagers ||
      LightcoreTutorialStep.forgeTowerManager ||
      LightcoreTutorialStep.assignTowerManager ||
      LightcoreTutorialStep.forgeEnemyManager ||
      LightcoreTutorialStep.assignEnemyManager ||
      LightcoreTutorialStep.setScreenName ||
      LightcoreTutorialStep.openFriends ||
      LightcoreTutorialStep.openMentees ||
      LightcoreTutorialStep.openMentors ||
      LightcoreTutorialStep.inspectEnemyBlitz ||
      LightcoreTutorialStep.inspectHexGauntlet ||
      LightcoreTutorialStep.inspectArenaFlow => true,
      _ => false,
    };
  }

  String? _tutorialInstructionOverride({
    required LightcoreController controller,
    required OuterTowerState? selected,
    required bool selectionOverlayVisible,
  }) {
    if (!selectionOverlayVisible) {
      return null;
    }
    final selectedSlotIndex = selected?.slotIndex;
    switch (controller.tutorialStep) {
      case LightcoreTutorialStep.buildFirstRedTower:
        if (selectedSlotIndex == 0 && selected?.isBuilt == false) {
          return 'Hex 1 build controls are already open. Choose Comet Mortar or Rayline Spire to start the first fabrication.';
        }
      case LightcoreTutorialStep.inspectFirstTowerStats:
        if (selectedSlotIndex == 0 && selected?.isBuilt == true) {
          return 'Tower Stats are already open. Read power, charge, cooldown, and the projectile type, then tap the highlighted tower-control button when done.';
        }
      case LightcoreTutorialStep.upgradeFirstTowerToLevel3:
        if (selectedSlotIndex == 0 && selected?.isBuilt == true) {
          return 'Use the Tower Level button in the open Hex 1 controls until it reaches level 3.';
        }
      case LightcoreTutorialStep.upgradeFirstTowerToLevel4:
        if (selectedSlotIndex == 0 && selected?.isBuilt == true) {
          return 'Use the Tower Level button in the open Hex 1 controls one more time before expanding.';
        }
      case LightcoreTutorialStep.tapBattleCore:
        if (_tutorialOpenPanelBlocksCurrentStep(controller)) {
          return 'Close the open battle controls, then tap the glowing Lightcore on the battlefield.';
        }
      case LightcoreTutorialStep.tapFirstTower:
        if (_tutorialOpenPanelBlocksCurrentStep(controller)) {
          return 'Close the open tower controls, then tap the charged first tower on the battlefield.';
        }
      case LightcoreTutorialStep.tapSecondShellTower:
        if (_tutorialOpenPanelBlocksCurrentStep(controller)) {
          return 'Close the open tower controls, then tap the charged child-shell tower on the battlefield.';
        }
      default:
        if (_tutorialOpenPanelBlocksCurrentStep(controller)) {
          return 'Close the open battle controls, then continue this quest.';
        }
    }
    return null;
  }

  Widget _buildBattleLayout({
    required BuildContext context,
    required LightcoreController controller,
    required OuterTowerState? selected,
    required VoidCallback? onInspect,
    required bool compact,
  }) {
    final inset = compact ? 12.0 : 16.0;
    final topInset = inset + widget.topOverlayInset;
    final bottomInset = inset + widget.bottomOverlayInset;
    final selectionOverlay = _buildSelectionOverlay(
      context: context,
      controller: controller,
      selected: selected,
      onInspect: onInspect,
      compact: compact,
    );
    final selectionHud = _buildSelectionHud(
      controller: controller,
      selected: selected,
    );
    final selectionOverlayVisible = selectionOverlay != null;
    final tutorialInstructionOverride = _tutorialInstructionOverride(
      controller: controller,
      selected: selected,
      selectionOverlayVisible: selectionOverlayVisible,
    );
    final questPanel = _buildQuestPanel(
      controller,
      compact: compact,
      instructionOverride: tutorialInstructionOverride,
    );
    final raiseThreatPrompt = _buildRaiseThreatPrompt(
      controller,
      compact: compact,
    );

    return Stack(
      children: [
        Positioned.fill(child: _buildGameCanvas(compact ? 20 : 0)),
        if (widget.showBattleHud && selectionHud != null)
          Positioned(left: inset, bottom: bottomInset, child: selectionHud),
        if (widget.showBattleHud)
          Positioned(
            right: inset,
            bottom: bottomInset,
            child: _buildOverdriveHud(),
          ),
        if (widget.showBattleHud && selectionOverlay != null)
          Positioned(
            left: inset,
            right: compact ? inset : null,
            bottom: bottomInset + _overdriveHudHeight,
            child: selectionOverlay,
          ),
        if (questPanel != null)
          Positioned(top: topInset, left: inset, child: questPanel),
        if (raiseThreatPrompt != null)
          Positioned(
            top: topInset + (compact ? 96 : 8),
            right: inset,
            child: raiseThreatPrompt,
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
            final onInspect = _buildInspectAction(
              context,
              controller,
              selected,
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                final useStackedLayout =
                    constraints.maxWidth < 760 || constraints.maxHeight < 760;

                return _buildBattleLayout(
                  context: context,
                  controller: controller,
                  selected: selected,
                  onInspect: onInspect,
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

class _RaiseThreatPrompt extends StatelessWidget {
  const _RaiseThreatPrompt({
    required this.compact,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final bool compact;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final width = compact ? 230.0 : 280.0;
    return SizedBox(
      width: width,
      child: GuidedFocusFrame(
        active: enabled,
        tint: LightcorePalette.quest,
        child: AuroraPanel(
          radius: 16,
          padding: EdgeInsets.all(compact ? 10 : 12),
          tint: LightcorePalette.quest,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag_rounded,
                    size: compact ? 17 : 19,
                    color: LightcorePalette.quest,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Threat too low',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: LightcorePalette.layer2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: enabled ? onPressed : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(label),
              ),
            ],
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
    required this.onInspect,
    required this.panelFocus,
    required this.onBuildTower,
  });

  final LightcoreController controller;
  final OuterTowerState? selected;
  final VoidCallback? onInspect;
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
    final queuePreview = controller.canUpgradeCoreQueueLimit
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
        queuePreview: queuePreview,
        multiShotPreview: multiShotPreview,
      );
    }

    if (selected!.isFabricating) {
      return _TowerFabricationPanel(controller: controller, tower: selected!);
    }

    if (selected!.isBuilt) {
      return _TowerStatsPanel(
        controller: controller,
        tower: selected!,
        onInspect: onInspect,
      );
    }

    return _EmptySlotPanel(
      controller: controller,
      slot: selected!,
      onBuildTower: onBuildTower,
    );
  }
}

class _CoreStatsPanel extends StatelessWidget {
  const _CoreStatsPanel({
    required this.controller,
    required this.rangePreview,
    required this.fireSpeedPreview,
    required this.queuePreview,
    required this.multiShotPreview,
  });

  final LightcoreController controller;
  final String rangePreview;
  final String fireSpeedPreview;
  final String queuePreview;
  final String multiShotPreview;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final coreStats = [
      [
        _InlineStatEntry(
          label: 'Level',
          value: controller.canTrainCoreStats
              ? '${controller.coreState.level}/${LightcoreController.maxCoreLevel}'
              : '${controller.coreState.level}',
        ),
        _InlineStatEntry(
          label: 'Stats',
          value:
              '${controller.coreUpgradePointsSpent}/${controller.coreUpgradePointsCap}',
        ),
        _InlineStatEntry(
          label: 'Output',
          value: controller.outputEfficiencyLabel,
        ),
        _InlineStatEntry(
          label: 'Stability',
          value: controller.coreStabilityLabel,
        ),
        _InlineStatEntry(label: 'Queue', value: controller.coreQueueLoadLabel),
        _InlineStatEntry(
          label: 'Ready',
          value:
              '${controller.promotionReadyTowerCount}/${LightcoreController.slotCount}',
        ),
        _InlineStatEntry(
          label: 'Slots',
          value:
              '${controller.unlockedOuterSlotCount}/${LightcoreController.slotCount}',
        ),
      ],
      [
        _InlineStatEntry(label: 'Power', value: controller.corePowerLabel),
        _InlineStatEntry(label: 'Range', value: controller.coreRangeLabel),
        _InlineStatEntry(label: 'Fire', value: controller.coreFireSpeedLabel),
        _InlineStatEntry(
          label: 'Cooldown',
          value: controller.coreCooldownLabel,
        ),
        _InlineStatEntry(label: 'Multi', value: controller.coreMultiShotLabel),
      ],
      [
        _InlineStatEntry(label: 'Crit', value: controller.coreCritLabel),
        _InlineStatEntry(
          label: 'Final',
          value: controller.coreFinalDamageLabel,
        ),
        _InlineStatEntry(label: 'Apex', value: controller.coreBossDamageLabel),
        _InlineStatEntry(
          label: 'Normal',
          value: controller.coreNormalDamageLabel,
        ),
        _InlineStatEntry(
          label: 'Pen',
          value: controller.coreDefensePenetrationLabel,
        ),
      ],
      [
        _InlineStatEntry(
          label: 'AR Level',
          value: '${controller.accountRadianceLevel}',
        ),
        _InlineStatEntry(
          label: 'TS',
          value: controller.towerStrengthCompactLabel,
        ),
        _InlineStatEntry(label: 'EXP', value: '${controller.experience}'),
        _InlineStatEntry(
          label: 'Apex',
          value: controller.bossAlive
              ? 'Live'
              : controller.bossKillsRemaining.toString(),
        ),
        _InlineStatEntry(label: 'Anomalies', value: '${controller.enemyCount}'),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.activeLayerLabel,
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Core Upgrades',
                    style: textTheme.titleMedium?.copyWith(
                      color: LightcorePalette.solar,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (controller.canTrainCoreStats) ...[
          const SizedBox(height: 6),
          Text(
            'Root Shell Core Training: ${controller.coreTrainingLabel}',
            style: textTheme.bodyMedium?.copyWith(
              color: LightcorePalette.solar,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          'Core upgrades: Range $rangePreview  •  Fire Speed $fireSpeedPreview  •  Queue $queuePreview  •  Multi-Shot $multiShotPreview  •  Cooldown ${controller.coreCooldownLabel}',
          style: textTheme.bodyMedium?.copyWith(
            color: LightcorePalette.solar,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (controller.coreEnergyUnlocked) ...[
          const SizedBox(height: 6),
          Text(
            'Nexus Energy: ${controller.coreEnergyLabel}  •  Recovery ${controller.coreEnergyRecoveryLabel}',
            style: textTheme.bodyMedium?.copyWith(
              color: LightcorePalette.aether,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            if (controller.canTrainCoreStats)
              FilledButton.icon(
                onPressed:
                    controller.canUpgradeCoreLevel &&
                        controller.lumens >= controller.coreLevelUpgradeCost
                    ? controller.upgradeCoreLevel
                    : null,
                icon: const Icon(Icons.keyboard_double_arrow_up_rounded),
                label: Text(
                  controller.canUpgradeCoreLevel
                      ? 'Shell Level • ${controller.coreLevelUpgradeCost}L'
                      : 'Shell Level Maxed',
                ),
              ),
            FilledButton.icon(
              onPressed:
                  controller.canUpgradeCoreRange &&
                      controller.lumens >= controller.coreRangeUpgradeCost
                  ? controller.upgradeCoreRange
                  : null,
              icon: const Icon(Icons.radar_rounded),
              label: Text(
                controller.canUpgradeCoreRange
                    ? 'Range • ${controller.coreRangeUpgradeCost}L'
                    : 'Range Maxed',
              ),
            ),
            FilledButton.icon(
              onPressed:
                  controller.canUpgradeCoreFireSpeed &&
                      controller.lumens >= controller.coreFireSpeedUpgradeCost
                  ? controller.upgradeCoreFireSpeed
                  : null,
              icon: const Icon(Icons.flash_on_rounded),
              label: Text(
                controller.canUpgradeCoreFireSpeed
                    ? 'Fire Speed • ${controller.coreFireSpeedUpgradeCost}L'
                    : 'Fire Speed Maxed',
              ),
            ),
            FilledButton.icon(
              onPressed:
                  controller.canUpgradeCoreQueueLimit &&
                      controller.lumens >= controller.coreQueueUpgradeCost
                  ? controller.upgradeCoreQueueLimit
                  : null,
              icon: const Icon(Icons.all_inbox_rounded),
              label: Text(
                controller.canUpgradeCoreQueueLimit
                    ? 'Queue • ${controller.coreQueueUpgradeCost}L'
                    : 'Queue Maxed',
              ),
            ),
            FilledButton.icon(
              onPressed:
                  controller.canUpgradeCoreMultiShot &&
                      controller.lumens >= controller.coreMultiShotUpgradeCost
                  ? controller.upgradeCoreMultiShot
                  : null,
              icon: const Icon(Icons.hub_rounded),
              label: Text(
                controller.canUpgradeCoreMultiShot
                    ? 'Multi-Shot • ${controller.coreMultiShotUpgradeCost}L'
                    : 'Multi-Shot Maxed',
              ),
            ),
            if (controller.coreEnergyUnlocked)
              FilledButton.icon(
                onPressed:
                    controller.canUpgradeCoreEnergyCapacity &&
                        controller.lumens >=
                            controller.coreEnergyCapacityUpgradeCost
                    ? controller.upgradeCoreEnergyCapacity
                    : null,
                icon: const Icon(Icons.battery_charging_full_rounded),
                label: Text(
                  controller.canUpgradeCoreEnergyCapacity
                      ? 'Energy Cap • ${controller.coreEnergyCapacityUpgradeCost}L'
                      : 'Energy Cap Maxed',
                ),
              ),
            if (controller.coreEnergyUnlocked)
              FilledButton.icon(
                onPressed:
                    controller.canUpgradeCoreEnergyRecovery &&
                        controller.lumens >=
                            controller.coreEnergyRecoveryUpgradeCost
                    ? controller.upgradeCoreEnergyRecovery
                    : null,
                icon: const Icon(Icons.bolt_rounded),
                label: Text(
                  controller.canUpgradeCoreEnergyRecovery
                      ? 'Energy Recovery • ${controller.coreEnergyRecoveryUpgradeCost}L'
                      : 'Energy Recovery Maxed',
                ),
              ),
            if (controller.hasSourceLayer)
              OutlinedButton.icon(
                onPressed: controller.enterSourceLayer,
                icon: const Icon(Icons.unfold_less_double_rounded),
                label: const Text('Enter Source Layer'),
              ),
          ],
        ),
        if (controller.canTrainCoreStats &&
            controller.coreUpgradeOptions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Root Shell Core Stat Upgrades',
            style: textTheme.titleSmall?.copyWith(
              color: LightcorePalette.mist.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
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
        const SizedBox(height: 16),
        Text(
          'Core Stats',
          style: textTheme.titleSmall?.copyWith(
            color: LightcorePalette.mist.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: controller.markTutorialStabilityPanelOpened,
          child: GuidedFocusFrame(
            active: controller.tutorialHighlightsCoreStats,
            tint: LightcorePalette.quest,
            label:
                controller.tutorialStep == LightcoreTutorialStep.autoQueueCheck
                ? 'QUEUE'
                : 'OUTPUT',
            child: _InlineStatList(rows: coreStats),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Core ${controller.coreAffinitySignatureLabel}  •  ${controller.coreProjectileArsenalLabel}  •  ${controller.corePayloadArsenalLabel}  •  ${controller.bossSpawnStatusLabel}',
          style: textTheme.bodyMedium,
        ),
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
      width: 218,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(upgrade.type.label, style: textTheme.titleSmall),
              ),
              Text(
                '${upgrade.rank}/${LightcoreController.maxTowerUpgradeRank}',
                style: textTheme.labelMedium?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            controller.coreUpgradeEffectLabel(upgrade),
            style: textTheme.bodyMedium?.copyWith(color: tint),
          ),
          const SizedBox(height: 4),
          Text(
            'Current ${controller.coreSubstatValueLabel(upgrade.type)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          MeterBar(
            value: (upgrade.rank / LightcoreController.maxTowerUpgradeRank)
                .clamp(0.0, 1.0),
            color: tint,
            height: 8,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canUpgrade
                  ? () => controller.upgradeCoreStat(upgrade.type)
                  : null,
              child: Text(statMaxed ? 'Stat Max' : 'Tune • ${cost}L'),
            ),
          ),
        ],
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
        _InlineStatEntry(
          label: 'Payload',
          value: controller.towerPayloadLabel(tower),
        ),
      ],
      [
        _InlineStatEntry(label: 'Hex', value: '${tower.slotIndex + 1}'),
        const _InlineStatEntry(label: 'Status', value: 'Fabricating'),
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
        Text(
          'Fabrication',
          style: textTheme.titleMedium?.copyWith(color: tint),
        ),
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

class _TowerStatsPanel extends StatelessWidget {
  const _TowerStatsPanel({
    required this.controller,
    required this.tower,
    required this.onInspect,
  });

  final LightcoreController controller;
  final OuterTowerState tower;
  final VoidCallback? onInspect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final manager = controller.cardForSlot(tower);
    final levelCost = controller.upgradeCost(tower);
    final hasTowerProgression = tower.hasTowerProgression;
    final towerStats = [
      [
        _InlineStatEntry(
          label: 'Level',
          value: hasTowerProgression
              ? '${tower.level}/${LightcoreController.maxTowerLevel}'
              : tower.isChildLayerNode
              ? '${tower.childCoreLevel ?? 1}'
              : '1/${LightcoreController.maxTowerLevel}',
        ),
        if (hasTowerProgression)
          _InlineStatEntry(
            label: 'Stats',
            value:
                '${controller.towerUpgradePointsSpent(tower)}/${controller.towerUpgradePointsCap(tower)}',
          ),
        _InlineStatEntry(
          label: 'Power',
          value: controller.towerPower(tower).toStringAsFixed(1),
        ),
        _InlineStatEntry(
          label: 'Charge',
          value: controller.towerLiveChargeRate(tower).toStringAsFixed(2),
        ),
        _InlineStatEntry(
          label: 'Cooldown',
          value: '${controller.towerLiveCooldown(tower).toStringAsFixed(2)}s',
        ),
        _InlineStatEntry(
          label: 'Automation',
          value: controller.towerAutomationLabel(tower),
        ),
        _InlineStatEntry(
          label: 'Load',
          value:
              '${(controller.towerDisruptionFraction(tower) * 100).round()}%',
        ),
      ],
      [
        _InlineStatEntry(
          label: 'Signature',
          value: controller.towerAffinitySignatureLabel(tower),
        ),
        _InlineStatEntry(
          label: 'Arsenal',
          value: controller.towerProjectileArsenalLabel(tower),
        ),
        _InlineStatEntry(
          label: 'Payloads',
          value: controller.towerPayloadArsenalLabel(tower),
        ),
      ],
      [
        _InlineStatEntry(
          label: 'Range',
          value: controller.towerRangeLabel(tower),
        ),
        _InlineStatEntry(
          label: 'Generation',
          value: controller.towerGenerationLabel(tower),
        ),
        _InlineStatEntry(
          label: 'Crit',
          value: controller.towerCritLabel(tower),
        ),
        _InlineStatEntry(
          label: 'Damage',
          value: controller.towerDamageRangeLabel(tower),
        ),
      ],
      [
        _InlineStatEntry(
          label: 'Final',
          value: controller.towerFinalDamageLabel(tower),
        ),
        _InlineStatEntry(
          label: 'Apex',
          value: controller.towerBossDamageLabel(tower),
        ),
        _InlineStatEntry(
          label: 'Normal',
          value: controller.towerNormalDamageLabel(tower),
        ),
        _InlineStatEntry(
          label: 'Pen',
          value: controller.towerDefensePenetrationLabel(tower),
        ),
      ],
      [
        _InlineStatEntry(
          label: 'Target',
          value: controller.towerTargetLabel(tower),
        ),
        _InlineStatEntry(
          label: 'Pattern',
          value: controller.towerPatternAchievementLabel(tower),
        ),
        if (hasTowerProgression && controller.managerAssignmentUnlocked)
          _InlineStatEntry(
            label: 'Core Manager',
            value: manager?.name ?? 'Open',
          ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(controller.towerDisplayName(tower), style: textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          tower.isLayerProject ? 'Shell Actions' : 'Tower Upgrades',
          style: textTheme.titleMedium?.copyWith(color: LightcorePalette.solar),
        ),
        const SizedBox(height: 6),
        Text(
          tower.isLayerProject
              ? '${controller.childTowerGrowthLabel(tower)}  •  ${controller.childShellProgressLabel(tower)}'
              : tower.isPromotedChildTower
              ? '${controller.towerCompletionLabel(tower)}  •  Source ${controller.childShellProgressLabel(tower)}'
              : tower.isFabricating
              ? controller.towerFabricationProgressLabel(tower)
              : tower.config!.passiveLabel,
          style: textTheme.bodyMedium,
        ),
        if (hasTowerProgression && !tower.isFabricating) ...[
          const SizedBox(height: 6),
          Text(
            'Tower Level ${tower.level}/${LightcoreController.maxTowerLevel} • Next ${levelCost}L  •  Tower stat ranks ${controller.towerUpgradePointsSpent(tower)}/${controller.towerUpgradePointsCap(tower)}',
            style: textTheme.bodyMedium?.copyWith(
              color: LightcorePalette.solar,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            GuidedFocusFrame(
              active: controller.tutorialHighlightsUpgradeButton(
                tower.slotIndex,
              ),
              tint: LightcorePalette.quest,
              child: FilledButton(
                onPressed: tower.isFabricating
                    ? null
                    : tower.isLayerProject
                    ? () => controller.enterChildLayer(tower.slotIndex)
                    : controller.activeLayerPassiveOnly
                    ? null
                    : tower.level < LightcoreController.maxTowerLevel
                    ? () => controller.tutorialUpgradeTower(tower.slotIndex)
                    : null,
                child: Text(
                  tower.isFabricating
                      ? 'Fabricating ${controller.towerFabricationRemainingLabel(tower)}'
                      : tower.isLayerProject
                      ? controller.isSlotPromotionReady(tower)
                            ? 'Inner Shell Ready'
                            : 'Open Shell'
                      : tower.level < LightcoreController.maxTowerLevel
                      ? 'Tower Level • $levelCost Lumens'
                      : controller.isTowerComplete(tower)
                      ? 'Complete'
                      : 'Level Max',
                ),
              ),
            ),
            if ((onInspect != null || tower.isChildLayerNode) &&
                manager == null)
              OutlinedButton(
                onPressed: controller.canManuallyActivateTower(tower)
                    ? () => controller.activateTowerSlot(tower.slotIndex)
                    : null,
                child: Text(
                  tower.isChildLayerNode
                      ? 'Generate Ready Packet'
                      : 'Fire Ready Packet',
                ),
              ),
            if (tower.isPromotedChildTower)
              OutlinedButton(
                onPressed: () => controller.enterChildLayer(tower.slotIndex),
                child: const Text('Source Layer'),
              ),
            if (!tower.isChildLayerNode && onInspect != null)
              OutlinedButton(onPressed: onInspect, child: const Text('Stats')),
            if (!tower.isChildLayerNode)
              OutlinedButton(
                onPressed: controller.activeLayerPassiveOnly
                    ? null
                    : () => controller.sellTower(tower.slotIndex),
                child: Text('Sell ${(tower.investedLumens * 0.7).round()}L'),
              ),
          ],
        ),
        if (!tower.isChildLayerNode) ...[
          const SizedBox(height: 16),
          Text(
            'Live Projectile Target',
            style: textTheme.titleSmall?.copyWith(
              color: LightcorePalette.mist.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final priority in TargetPriority.values)
                ChoiceChip(
                  label: Text(priority.label),
                  selected: controller.towerTargetPriority(tower) == priority,
                  onSelected: controller.activeLayerPassiveOnly
                      ? null
                      : (_) => controller.setTowerTargetPriority(
                          tower.slotIndex,
                          priority,
                        ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(
          tower.isLayerProject ? 'Shell Stats' : 'Tower Stats',
          style: textTheme.titleSmall?.copyWith(
            color: LightcorePalette.mist.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        _InlineStatList(rows: towerStats),
      ],
    );
  }
}

class _EmptySlotPanel extends StatelessWidget {
  const _EmptySlotPanel({
    required this.controller,
    required this.slot,
    required this.onBuildTower,
  });

  final LightcoreController controller;
  final OuterTowerState slot;
  final bool Function(int slotIndex, TowerConfig config) onBuildTower;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final childLayerBlockedLabel = controller.isCompositeLayer
        ? controller.childLayerCreationBlockedLabelForSlot(slot.slotIndex)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Empty Hex ${slot.slotIndex + 1}', style: textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          controller.isCompositeLayer
              ? 'This empty edge can create a new lower-class shell that shares the global economy.'
              : controller.tutorialNeedsTowerPaletteGate
              ? 'Choose one of two starter projectile styles. Comet Mortar is slower area pressure; Rayline Spire is steadier beam pressure.'
              : controller.tutorialShowsStarterProjectileChoices
              ? 'Choose one of two starter projectile styles. Thread Beam is steady single-target pressure; Shield Halo is a persistent guard ring.'
              : 'Pick one of the unlocked color prisms to activate this surrounding slot.',
          style: textTheme.bodyMedium,
        ),
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
            : Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final config in controller.tutorialTowerChoices)
                    _BuildButton(
                      config: config,
                      buildCost: controller.buildCostForConfig(config),
                      fabricationDuration: controller
                          .towerFabricationDurationLabelForConfig(config),
                      traitBias: controller.traitBiasSummary(config),
                      enabled:
                          controller.lumens >=
                          controller.buildCostForConfig(config),
                      highlighted: controller.tutorialHighlightsBuildButton(
                        config,
                      ),
                      onPressed: () => onBuildTower(slot.slotIndex, config),
                    ),
                ],
              ),
      ],
    );
  }
}

class _BattleSelectionHud extends StatelessWidget {
  const _BattleSelectionHud({
    required this.tint,
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.highlighted,
    required this.tapCueLabel,
    required this.onPressed,
  });

  final Color tint;
  final String tooltip;
  final IconData icon;
  final bool selected;
  final bool highlighted;
  final String? tapCueLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: selected ? 'Hide $tooltip' : 'Show $tooltip',
      child: GuidedFocusFrame(
        active: highlighted,
        tint: LightcorePalette.quest,
        label: 'TUNE',
        tapCueLabel: tapCueLabel,
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
    final tutorialHighlighted = controller.tutorialHighlightsOverdriveButton;
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
          child: GuidedFocusFrame(
            key: const ValueKey<String>('battle-overdrive-frame'),
            active: tutorialHighlighted,
            tint: LightcorePalette.quest,
            pulseSignal: controller.tutorialPulseSignalFor(
              LightcoreTutorialPulseTarget.overdriveButton,
            ),
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
                    color: tint.withValues(
                      alpha: permanentActive ? 0.92 : 0.75,
                    ),
                    width: permanentOwned ? 1.8 : 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tint.withValues(
                        alpha: permanentActive ? 0.34 : 0.2,
                      ),
                      blurRadius: permanentActive ? 22 : 16,
                      spreadRadius: permanentActive ? 2 : 0,
                    ),
                  ],
                ),
                child: Icon(Icons.flash_on_rounded, size: 34, color: tint),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BuildButton extends StatelessWidget {
  const _BuildButton({
    required this.config,
    required this.buildCost,
    required this.fabricationDuration,
    required this.traitBias,
    required this.enabled,
    required this.highlighted,
    required this.onPressed,
  });

  final TowerConfig config;
  final int buildCost;
  final String fabricationDuration;
  final String traitBias;
  final bool enabled;
  final bool highlighted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      child: GuidedFocusFrame(
        active: highlighted,
        tint: LightcorePalette.quest,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: config.affinity.color.withValues(alpha: 0.92),
            foregroundColor: LightcorePalette.night,
            disabledBackgroundColor: LightcorePalette.panelRaised,
          ),
          onPressed: enabled ? onPressed : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(config.name, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                '$buildCost Lumens • $fabricationDuration',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LightcorePalette.night.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                config.passiveLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LightcorePalette.night.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                traitBias,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LightcorePalette.night.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
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
