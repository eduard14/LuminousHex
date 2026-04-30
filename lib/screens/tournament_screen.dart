import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/enemy_configs.dart';
import '../models/hex_tournament_run.dart';
import '../models/lightcore_state.dart';
import '../models/lightcore_tournament.dart';
import '../models/lightcore_types.dart';
import '../services/lightcore_firebase_backend.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/aurora_panel.dart';
import '../widgets/guided_focus_frame.dart';
import '../widgets/meter_bar.dart';
import '../widgets/symbol_grid_tile.dart';
import 'battle_screen.dart';

part 'tournament/tournament_hub_widgets.dart';
part 'tournament/tournament_mode_detail.dart';
part 'tournament/tournament_battle_widgets.dart';
part 'tournament/hex_tournament_game.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({
    super.key,
    required this.controller,
    required this.backend,
    this.onBattleSurfaceActiveChanged,
  });

  final LightcoreController controller;
  final FirebaseLightcoreBackend backend;
  final ValueChanged<bool>? onBattleSurfaceActiveChanged;

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  LightcoreTournamentOverview? _overview;
  LightcoreTournamentModeId? _selectedMode;
  String? _errorMessage;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadOverview());
  }

  Future<void> _loadOverview() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final overview = await widget.backend.fetchTournamentOverview();
      if (!mounted) {
        return;
      }
      widget.controller.setTournamentExperienceBoost(
        multiplier: overview.activeExperienceMultiplier,
        endsAt: overview.activeExperienceBoostEndsAt,
        showBanner: false,
      );
      setState(() {
        _overview = overview;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage =
            'Tournament service is unavailable right now. Weekly events require the Firebase backend to be online.\n$error';
      });
    }
  }

  Future<void> _joinMode(LightcoreTournamentModeId mode) async {
    await _runBusyAction(() async {
      final overview = await widget.backend.joinTournamentQueue(
        mode: mode,
        snapshot: widget.controller.buildTournamentSnapshot(),
      );
      _applyOverview(overview);
    });
  }

  Future<void> _submitRun(
    LightcoreTournamentModeState modeState,
    int score,
  ) async {
    await _runBusyAction(() async {
      final overview = await widget.backend.submitTournamentRun(
        mode: modeState.mode,
        score: score,
        snapshot: widget.controller.buildTournamentSnapshot(),
      );
      _applyOverview(overview);
    });
  }

  Future<void> _claimReward(LightcoreTournamentModeId mode) async {
    await _runBusyAction(() async {
      final result = await widget.backend.claimTournamentReward(mode: mode);
      widget.controller.applyTournamentRewardPackage(result.reward);
      _applyOverview(result.overview);
    });
  }

  Future<void> _runBusyAction(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Tournament request failed.\n$error';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _applyOverview(LightcoreTournamentOverview overview) {
    widget.controller.setTournamentExperienceBoost(
      multiplier: overview.activeExperienceMultiplier,
      endsAt: overview.activeExperienceBoostEndsAt,
      showBanner: false,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _overview = overview;
      _loading = false;
      _errorMessage = null;
    });
  }

  void _openMode(LightcoreTournamentModeId mode) {
    widget.controller.markTutorialTournamentModeReviewed(mode);
    setState(() => _selectedMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    if (_loading && overview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedMode = _selectedMode;
    if (selectedMode != null && overview != null) {
      return _TournamentModeDetailScreen(
        key: ValueKey<String>('detail-${selectedMode.wireKey}'),
        controller: widget.controller,
        modeState: overview.modeFor(selectedMode),
        busy: _busy || _loading,
        onBack: () {
          widget.onBattleSurfaceActiveChanged?.call(false);
          setState(() => _selectedMode = null);
        },
        onJoin: () => _joinMode(selectedMode),
        onRefresh: _loadOverview,
        onClaim: () => _claimReward(selectedMode),
        onSubmit: _submitRun,
        onBattleSurfaceActiveChanged: widget.onBattleSurfaceActiveChanged,
      );
    }

    return _TournamentHubScreen(
      overview: overview,
      controller: widget.controller,
      loading: _loading,
      busy: _busy,
      errorMessage: _errorMessage,
      onRefresh: _loadOverview,
      onOpenMode: _openMode,
      onJoinMode: _joinMode,
      onClaimReward: _claimReward,
    );
  }
}
