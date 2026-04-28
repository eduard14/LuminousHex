import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/lightcore_state.dart';
import '../models/lightcore_types.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/aurora_panel.dart';
import '../widgets/meter_bar.dart';
import '../widgets/tower_level_hex_badge.dart';

part 'daily_dungeons/dungeon_math.dart';
part 'daily_dungeons/dungeon_run_models.dart';
part 'daily_dungeons/dungeon_game.dart';
part 'daily_dungeons/dungeon_run_widgets.dart';
part 'daily_dungeons/dungeon_selection_widgets.dart';
part 'daily_dungeons/dungeon_battle_painter.dart';
part 'daily_dungeons/dungeon_loadout_widgets.dart';
part 'daily_dungeons/prism_rift_dungeon_game.dart';
part 'daily_dungeons/prism_rift_dungeon_widgets.dart';

class DailyDungeonsScreen extends StatefulWidget {
  const DailyDungeonsScreen({
    super.key,
    required this.controller,
    required this.isActive,
    this.scrollController,
  });

  final LightcoreController controller;
  final bool isActive;
  final ScrollController? scrollController;

  @override
  State<DailyDungeonsScreen> createState() => _DailyDungeonsScreenState();
}

enum _DailyDungeonSlot { enemyManager, sealedVault, prismRift }

class _DailyDungeonsScreenState extends State<DailyDungeonsScreen> {
  static const Duration _timeLimit = Duration(seconds: 45);
  static const int _requiredAnomalyCount = 3;

  _DailyDungeonSlot _selected = _DailyDungeonSlot.enemyManager;
  int _selectedTowerLevel = LightcoreController.dailyDungeonStartingTowerLevel;
  final Set<String> _selectedAnomalyIds = <String>{};
  String? _selectedApexEnemyCardId;

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final dailyKey = _dailyKey(DateTime.now());
        final ownedCards = _ownedEnemyCards(controller);

        return ListView(
          key: const PageStorageKey<String>('daily-dungeons-scroll'),
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 28),
          children: [
            _DungeonHeader(
              dailyKey: dailyKey,
              ownedEnemyCount: ownedCards.length,
              selectedLoadoutCount: _selectedAnomalyCards(
                controller,
                ownedCards,
              ).length,
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth >= 840
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _DungeonSelectCard(
                        title: 'Threat Director',
                        subtitle:
                            'Climb the tower from Lv 1. Clear the visible level to unlock the next one.',
                        icon: Icons.shield_rounded,
                        tint: LightcorePalette.warning,
                        selected: _selected == _DailyDungeonSlot.enemyManager,
                        enabled: true,
                        statusLabel: 'Open',
                        onTap: () =>
                            _selectDungeon(_DailyDungeonSlot.enemyManager),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _DungeonSelectCard(
                        title: 'Sealed Vault',
                        subtitle:
                            'Vault route is sealed until the daily dungeon rotation opens it.',
                        icon: Icons.lock_clock_rounded,
                        tint: LightcorePalette.solar,
                        selected: _selected == _DailyDungeonSlot.sealedVault,
                        enabled: false,
                        statusLabel: 'Sealed',
                        onTap: null,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _DungeonSelectCard(
                        title: 'Prism Rift',
                        subtitle:
                            'Manual aim route. Stabilize rift shards with charged player-fired shots.',
                        icon: Icons.terrain_rounded,
                        tint: LightcorePalette.violet,
                        selected: _selected == _DailyDungeonSlot.prismRift,
                        enabled: true,
                        statusLabel: 'Open',
                        onTap: () =>
                            _selectDungeon(_DailyDungeonSlot.prismRift),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (_selected == _DailyDungeonSlot.enemyManager)
              _buildEnemyManagerDungeon(context, controller, ownedCards)
            else if (_selected == _DailyDungeonSlot.prismRift)
              _buildPrismRiftDungeon(context, controller),
          ],
        );
      },
    );
  }

  Widget _buildEnemyManagerDungeon(
    BuildContext context,
    LightcoreController controller,
    List<EnemyCardState> ownedCards,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final selectedLevel = _selectedLevelFor(controller);
    final towerProfile = controller.dailyDungeonTowerProfileForLevel(
      selectedLevel,
    );
    final towerMaxHealth = towerProfile.maxHealth;
    final selectedCards = _selectedAnomalyCards(controller, ownedCards);
    final selectedApex = _selectedApexCard(controller);
    final reward = controller.dailyDungeonRewardForLevel(selectedLevel);
    final requiredCount = math.min(_requiredAnomalyCount, ownedCards.length);
    final readyToEnter =
        selectedCards.length >= requiredCount && selectedCards.isNotEmpty;
    final strongestDamage = selectedCards.isEmpty
        ? 0.0
        : selectedCards
              .map((card) => _dungeonRaidTotalDamage(controller, card))
              .reduce(math.max);

    return AuroraPanel(
      tint: LightcorePalette.warning,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBadge(
                icon: Icons.shield_rounded,
                tint: LightcorePalette.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Threat Director', style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a tower level and lock a three-anomaly raid loadout. Combat opens as its own timed arena with launch cooldowns.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: LightcorePalette.mist.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusCapsule(label: 'Menu', tint: LightcorePalette.solar),
            ],
          ),
          const SizedBox(height: 18),
          _DungeonTowerLadder(
            selectedLevel: selectedLevel,
            highestUnlockedLevel:
                controller.dailyDungeonHighestUnlockedTowerLevel,
            highestClearedLevel:
                controller.dailyDungeonHighestClearedTowerLevel,
            enabled: true,
            onSelected: (level) => _selectTowerLevel(controller, level),
          ),
          const SizedBox(height: 14),
          _TargetTowerPanel(
            towerProfile: towerProfile,
            towerLevel: selectedLevel,
            towerHealth: towerMaxHealth,
            towerMaxHealth: towerMaxHealth,
            towerIntegrity: 1,
            remainingSeconds: _timeLimit.inSeconds.toDouble(),
            timeProgress: 1,
            strongestRaidDamage: strongestDamage,
            activeRaids: const <_DungeonRaid>[],
            reward: reward,
            cleared: controller.isDailyDungeonTowerLevelCleared(selectedLevel),
            running: false,
            victory: false,
            expired: false,
            tint: LightcorePalette.warning,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.timer_rounded,
                label: '${_timeLimit.inSeconds}s limit',
                tint: LightcorePalette.aether,
              ),
              _InfoChip(
                icon: towerProjectileIcon(towerProfile.projectileType),
                label: '${towerProfile.affinity.shortLabel} tower shoots back',
                tint: towerProfile.affinity.color,
              ),
              _InfoChip(
                icon: Icons.group_work_rounded,
                label: '$requiredCount required anomalies',
                tint: LightcorePalette.verdant,
              ),
              _InfoChip(
                icon: Icons.shield_moon_rounded,
                label: selectedApex == null ? 'No apex armed' : 'Apex ready',
                tint: LightcorePalette.solar,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Select Anomalies', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          if (ownedCards.isEmpty)
            Text(
              'Resolve Threat Scans to unlock anomalies for this dungeon.',
              style: textTheme.bodyMedium?.copyWith(
                color: LightcorePalette.warning,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 640;
                final tileWidth = compact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final card in ownedCards.take(8))
                      SizedBox(
                        width: tileWidth,
                        child: _DungeonLoadoutTile(
                          card: card,
                          selected: selectedCards.any(
                            (selected) => selected.config.id == card.config.id,
                          ),
                          totalDamage: _dungeonRaidTotalDamage(
                            controller,
                            card,
                          ),
                          cooldownSeconds: _dungeonDeployCooldown(
                            controller,
                            card,
                          ),
                          onTap: () => _toggleDungeonAnomaly(
                            controller,
                            ownedCards,
                            card,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 18),
          _ApexLoadoutSelector(
            cards: controller.ownedBossEnemyCards,
            selectedCard: selectedApex,
            onSelected: _selectApexCard,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: readyToEnter
                ? () => _openDungeonRun(
                    context,
                    controller,
                    selectedLevel,
                    selectedCards,
                    selectedApex,
                  )
                : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              readyToEnter
                  ? 'Enter Lv $selectedLevel'
                  : 'Select $requiredCount anomalies',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrismRiftDungeon(
    BuildContext context,
    LightcoreController controller,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final selectedLevel = _selectedLevelFor(controller);
    final towerProfile = controller.dailyDungeonTowerProfileForLevel(
      selectedLevel,
    );
    final reward = controller.dailyDungeonRewardForLevel(selectedLevel);
    final riftStability = _prismRiftMaxStabilityFor(towerProfile);

    return AuroraPanel(
      tint: LightcorePalette.violet,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBadge(
                icon: Icons.terrain_rounded,
                tint: LightcorePalette.violet,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prism Rift', style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Automation is offline inside the rift. Each clear uses the same daily tower ladder and first-clear reward track.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: LightcorePalette.mist.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusCapsule(label: 'Manual', tint: LightcorePalette.violet),
            ],
          ),
          const SizedBox(height: 18),
          _DungeonTowerLadder(
            selectedLevel: selectedLevel,
            highestUnlockedLevel:
                controller.dailyDungeonHighestUnlockedTowerLevel,
            highestClearedLevel:
                controller.dailyDungeonHighestClearedTowerLevel,
            enabled: true,
            onSelected: (level) => _selectTowerLevel(controller, level),
          ),
          const SizedBox(height: 14),
          _PrismRiftPreviewPanel(
            towerProfile: towerProfile,
            towerLevel: selectedLevel,
            reward: reward,
            riftStability: riftStability,
            cleared: controller.isDailyDungeonTowerLevelCleared(selectedLevel),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.timer_rounded,
                label: '${_timeLimit.inSeconds}s limit',
                tint: LightcorePalette.aether,
              ),
              _InfoChip(
                icon: towerProjectileIcon(towerProfile.projectileType),
                label: '${towerProfile.affinity.shortLabel} manual shot',
                tint: towerProfile.affinity.color,
              ),
              _InfoChip(
                icon: Icons.track_changes_rounded,
                label: '${riftStability.round()} stability',
                tint: LightcorePalette.violet,
              ),
              _InfoChip(
                icon: Icons.local_fire_department_rounded,
                label: 'combo scoring',
                tint: LightcorePalette.solar,
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () =>
                _openPrismRiftRun(context, controller, selectedLevel),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text('Enter Rift Lv $selectedLevel'),
          ),
        ],
      ),
    );
  }

  void _selectDungeon(_DailyDungeonSlot slot) {
    if (_selected == slot) {
      return;
    }
    setState(() => _selected = slot);
  }

  void _selectTowerLevel(LightcoreController controller, int level) {
    if (!controller.isDailyDungeonTowerLevelUnlocked(level)) {
      return;
    }
    final normalizedLevel = level
        .clamp(
          LightcoreController.dailyDungeonStartingTowerLevel,
          controller.dailyDungeonHighestUnlockedTowerLevel,
        )
        .toInt();
    setState(() => _selectedTowerLevel = normalizedLevel);
  }

  void _toggleDungeonAnomaly(
    LightcoreController controller,
    List<EnemyCardState> ownedCards,
    EnemyCardState card,
  ) {
    final selectedIds = _effectiveSelectedAnomalyIds(controller, ownedCards);
    setState(() {
      _selectedAnomalyIds
        ..clear()
        ..addAll(selectedIds);
      if (_selectedAnomalyIds.remove(card.config.id)) {
        return;
      }
      if (_selectedAnomalyIds.length >= _requiredAnomalyCount) {
        _selectedAnomalyIds.remove(_selectedAnomalyIds.first);
      }
      _selectedAnomalyIds.add(card.config.id);
    });
  }

  void _selectApexCard(EnemyCardState card) {
    setState(() => _selectedApexEnemyCardId = card.config.id);
  }

  Future<void> _openDungeonRun(
    BuildContext context,
    LightcoreController controller,
    int towerLevel,
    List<EnemyCardState> anomalyCards,
    EnemyCardState? apexCard,
  ) async {
    final result = await Navigator.of(context).push<_DungeonRunResult>(
      MaterialPageRoute<_DungeonRunResult>(
        fullscreenDialog: true,
        builder: (_) => _ThreatDirectorDungeonRunScreen(
          controller: controller,
          towerLevel: towerLevel,
          anomalyCards: List<EnemyCardState>.unmodifiable(anomalyCards),
          apexCard: apexCard,
        ),
      ),
    );
    if (!mounted || result == null || !result.cleared) {
      return;
    }
    setState(() {
      _selectedTowerLevel = controller.dailyDungeonHighestUnlockedTowerLevel;
    });
  }

  Future<void> _openPrismRiftRun(
    BuildContext context,
    LightcoreController controller,
    int towerLevel,
  ) async {
    final result = await Navigator.of(context).push<_DungeonRunResult>(
      MaterialPageRoute<_DungeonRunResult>(
        fullscreenDialog: true,
        builder: (_) => _PrismRiftDungeonRunScreen(
          controller: controller,
          towerLevel: towerLevel,
        ),
      ),
    );
    if (!mounted || result == null || !result.cleared) {
      return;
    }
    setState(() {
      _selectedTowerLevel = controller.dailyDungeonHighestUnlockedTowerLevel;
    });
  }

  List<EnemyCardState> _ownedEnemyCards(LightcoreController controller) {
    final activeIds = controller.activeEnemyCardIds.toSet();
    final cards = controller.enemyCards
        .where((card) => card.isOwned)
        .toList(growable: false);
    final sorted = List<EnemyCardState>.of(cards);
    sorted.sort((a, b) {
      final activeCompare = (activeIds.contains(b.config.id) ? 1 : 0).compareTo(
        activeIds.contains(a.config.id) ? 1 : 0,
      );
      if (activeCompare != 0) {
        return activeCompare;
      }
      final rarityCompare = b.config.rarity.index.compareTo(
        a.config.rarity.index,
      );
      if (rarityCompare != 0) {
        return rarityCompare;
      }
      final levelCompare = b.level.compareTo(a.level);
      if (levelCompare != 0) {
        return levelCompare;
      }
      return a.config.name.compareTo(b.config.name);
    });
    return sorted;
  }

  int _selectedLevelFor(LightcoreController controller) {
    return _selectedTowerLevel
        .clamp(
          LightcoreController.dailyDungeonStartingTowerLevel,
          controller.dailyDungeonHighestUnlockedTowerLevel,
        )
        .toInt();
  }

  List<EnemyCardState> _selectedAnomalyCards(
    LightcoreController controller,
    List<EnemyCardState> ownedCards,
  ) {
    final byId = {for (final card in ownedCards) card.config.id: card};
    return _effectiveSelectedAnomalyIds(
      controller,
      ownedCards,
    ).map((id) => byId[id]).whereType<EnemyCardState>().toList(growable: false);
  }

  List<String> _effectiveSelectedAnomalyIds(
    LightcoreController controller,
    List<EnemyCardState> ownedCards,
  ) {
    final ownedIds = ownedCards.map((card) => card.config.id).toSet();
    final selected = _selectedAnomalyIds
        .where(ownedIds.contains)
        .take(_requiredAnomalyCount)
        .toList();
    if (_selectedAnomalyIds.isNotEmpty) {
      return selected.toList(growable: false);
    }
    final defaults = _defaultAnomalyLoadoutIds(controller, ownedCards);
    for (final id in defaults) {
      if (selected.length >=
          math.min(_requiredAnomalyCount, ownedCards.length)) {
        break;
      }
      if (!selected.contains(id)) {
        selected.add(id);
      }
    }
    return selected.take(_requiredAnomalyCount).toList(growable: false);
  }

  List<String> _defaultAnomalyLoadoutIds(
    LightcoreController controller,
    List<EnemyCardState> ownedCards,
  ) {
    final ids = <String>[];
    for (final card in controller.activeEnemyDeck) {
      if (card.isOwned && !ids.contains(card.config.id)) {
        ids.add(card.config.id);
      }
    }
    for (final card in ownedCards) {
      if (!ids.contains(card.config.id)) {
        ids.add(card.config.id);
      }
    }
    return ids.take(_requiredAnomalyCount).toList(growable: false);
  }

  EnemyCardState? _selectedApexCard(LightcoreController controller) {
    final ownedApexCards = controller.ownedBossEnemyCards;
    if (ownedApexCards.isEmpty) {
      return null;
    }
    final selectedId = _selectedApexEnemyCardId;
    if (selectedId != null) {
      final selected = ownedApexCards.where(
        (card) => card.config.id == selectedId,
      );
      if (selected.isNotEmpty) {
        return selected.first;
      }
    }
    final active = controller.activeBossEnemyCard;
    if (active != null && active.isOwned) {
      return active;
    }
    return ownedApexCards.first;
  }

  String _dailyKey(DateTime now) {
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
