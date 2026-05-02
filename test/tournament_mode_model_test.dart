import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_tournament.dart';
import 'package:lightcore/models/lightcore_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void main() {
  test('new tournament mode ids round-trip from wire keys', () {
    expect(
      tournamentModeFromWireKey('enemyBlitz'),
      LightcoreTournamentModeId.enemyBlitz,
    );
    expect(
      tournamentModeFromWireKey('hexGauntlet'),
      LightcoreTournamentModeId.hexGauntlet,
    );
    expect(
      tournamentModeFromWireKey('arenaFlow'),
      LightcoreTournamentModeId.arenaFlow,
    );
  });

  test('tournament mode metadata matches weekly event concepts', () {
    expect(LightcoreTournamentModeId.enemyBlitz.label, 'Anomaly Blitz');
    expect(
      LightcoreTournamentModeId.enemyBlitz.queueLabel,
      'Testing leaderboard',
    );
    expect(
      LightcoreTournamentModeId.enemyBlitz.eventCadenceLabel,
      'Open testing',
    );
    expect(
      LightcoreTournamentModeId.enemyBlitz.rules,
      contains('Each survival session runs on a weekend-length clock.'),
    );
    expect(LightcoreTournamentModeId.hexGauntlet.label, 'Hex');
    expect(
      LightcoreTournamentModeId.hexGauntlet.queueLabel,
      'Global leaderboard',
    );
    expect(LightcoreTournamentModeId.enemyBlitz.usesTowerSeed, isFalse);
    expect(LightcoreTournamentModeId.hexGauntlet.usesTowerSeed, isFalse);
    expect(LightcoreTournamentModeId.arenaFlow.usesTowerSeed, isTrue);
    expect(LightcoreTournamentModeId.arenaFlow.usesGlobalRating, isTrue);
    expect(LightcoreTournamentModeId.arenaFlow.supportsEnemyDraft, isFalse);
    expect(LightcoreTournamentModeId.arenaFlow.supportsBossDraft, isFalse);
  });

  test('closed events cannot start runs even when joined', () {
    final state = LightcoreTournamentModeState.fromMap(<String, dynamic>{
      'mode': 'hexGauntlet',
      'statusMessage': 'Closed for now.',
      'mechanicSummary': 'Weekly global climb.',
      'rewardPreview': const <String, dynamic>{},
      'startsAt': '2026-04-25T00:00:00.000Z',
      'endsAt': '2026-04-27T00:00:00.000Z',
      'joined': true,
      'isOpen': false,
    });

    expect(state.canStartRun, isFalse);
  });

  test('open events can start through first-run auto entry', () {
    final state = LightcoreTournamentModeState.fromMap(<String, dynamic>{
      'mode': 'hexGauntlet',
      'statusMessage': 'Open for runs.',
      'mechanicSummary': 'Weekly global climb.',
      'rewardPreview': const <String, dynamic>{},
      'startsAt': '2026-04-25T00:00:00.000Z',
      'endsAt': '2026-04-27T00:00:00.000Z',
      'joined': false,
      'isOpen': true,
    });

    expect(state.canStartRun, isTrue);
  });

  test('tournament snapshots use the highest-layer Home Tower', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.kills = LightcoreController.killsForOverallLevel(80);
    controller.lumens = 100000;
    expect(controller.debugSeedProgressionLayer(3), isTrue);

    final snapshot = controller.buildTournamentSnapshot();
    final homeLayerBuiltTowerCount = controller.homeTowerLayer.slots
        .where(
          (slot) =>
              (slot.config != null && !slot.isFabricating) ||
              slot.isPromotedChildTower,
        )
        .length;

    expect(snapshot.overallLevel, controller.overallLevel);
    expect(snapshot.prestigeLevel, controller.prestigeLevel);
    expect(snapshot.activeLayerTier, 3);
    expect(snapshot.builtTowerCount, homeLayerBuiltTowerCount);
    expect(snapshot.coreLevel, controller.homeTowerLayer.core.level);
    expect(snapshot.towerPowerIndex, controller.homeTowerPowerIndex);
    expect(
      snapshot.towerAffinity,
      controller.homeTowerAffinity ?? controller.homeTowerLayer.core.affinity,
    );
    expect(snapshot.enemyCardIds, controller.activeEnemyCardIds);
    expect(snapshot.enemyCardLevels, <String, int>{
      for (final card in controller.activeEnemyDeck) card.config.id: card.level,
    });
  });

  test('tournament battle runtime normalizes a full flame battle shell', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.configureTournamentBattle(
      mode: LightcoreTournamentModeId.arenaFlow,
      seedPowerIndex: 1400,
      enemyDraft: [
        EnemyCardState(
          config: EnemyLibrary.basicRed,
          unlocked: true,
          copies: 1,
          level: 3,
        ),
      ],
      bossDraft: EnemyCardState(
        config: BossEnemyLibrary.starterWhiteWarden,
        unlocked: true,
        copies: 1,
        level: 2,
      ),
      towerTier: 2,
      enemyPressure: 12,
    );

    expect(controller.outerRingRevealed, isTrue);
    expect(controller.swarmActivated, isTrue);
    expect(controller.slots.every((slot) => slot.isBuilt), isTrue);
    expect(controller.activeEnemyCardIds, contains(EnemyLibrary.basicRed.id));
    expect(
      controller.activeBossEnemyCard?.config.id,
      BossEnemyLibrary.starterWhiteWarden.id,
    );
    expect(controller.enemyTargetCount, 12);
    expect(controller.layer2State.unlocked, isTrue);
  });

  test('tournament battle preserves high-rarity enemy draft pressure', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    final legendary = EnemyLibrary.byRarity[EnemyCardRarity.legendary]!.first;

    controller.configureTournamentBattle(
      mode: LightcoreTournamentModeId.enemyBlitz,
      seedPowerIndex: 1400,
      enemyDraft: [
        EnemyCardState(config: legendary, unlocked: true, copies: 1, level: 1),
      ],
      towerTier: 1,
      enemyPressure: 16,
    );

    final activeCard = controller.activeEnemyDeck.single;
    expect(activeCard.config.id, legendary.id);
    expect(
      controller.enemyCardPreviewHealth(activeCard),
      greaterThan(900000000),
    );
    expect(controller.enemyCardThreatRatingLabel(activeCard), 'Overwhelming');
  });

  test('anomaly blitz starts manual and upgrades towers without reset', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.configureTournamentBattle(
      mode: LightcoreTournamentModeId.enemyBlitz,
      seedPowerIndex: 1400,
      enemyDraft: [
        EnemyCardState(
          config: EnemyLibrary.basicRed,
          unlocked: true,
          copies: 1,
          level: 1,
        ),
      ],
      towerTier: 1,
      enemyPressure: 10,
    );

    expect(controller.builtTowerCount, 0);
    expect(controller.towerCoreManager, isNull);
    expect(controller.outerRingRevealed, isTrue);
    controller.tick(1);
    expect(controller.enemies, isNotEmpty);
    final enemyIdsBeforeUpgrade = controller.enemies
        .map((enemy) => enemy.id)
        .toSet();

    controller.applyEnemyBlitzTowerUpgrade(seedPowerIndex: 1400, towerTier: 2);

    expect(controller.builtTowerCount, 1);
    expect(controller.towerCoreManager, isNull);
    expect(
      controller.enemies.map((enemy) => enemy.id).toSet(),
      containsAll(enemyIdsBeforeUpgrade),
    );

    controller.applyEnemyBlitzTowerUpgrade(seedPowerIndex: 1400, towerTier: 3);

    expect(controller.builtTowerCount, 2);

    controller.applyEnemyBlitzTowerUpgrade(seedPowerIndex: 1400, towerTier: 5);

    expect(controller.builtTowerCount, 2);
    expect(controller.slots.take(2).every((slot) => slot.level >= 3), isTrue);
  });

  test('daily dungeon battle runtime uses selected anomaly deck', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.configureThreatDirectorDungeonBattle(
      towerLevel: 1,
      enemyDraft: [
        EnemyCardState(
          config: EnemyLibrary.basicRed,
          unlocked: true,
          copies: 1,
          level: 2,
        ),
      ],
    );

    expect(controller.outerRingRevealed, isTrue);
    expect(controller.swarmActivated, isTrue);
    expect(controller.battleUsesManualEnemySpawns, isTrue);
    expect(controller.builtTowerCount, 0);
    expect(controller.experience, 0);
    expect(controller.kills, 0);
    expect(
      controller.coreState.projectileType,
      TowerLibrary.whitePrism.defaultProjectileType,
    );
    expect(controller.activeEnemyCardIds, contains(EnemyLibrary.basicRed.id));
    expect(controller.towerCoreManager, isNotNull);
    controller.tick(2);
    expect(controller.enemies, isEmpty);
    expect(
      controller.spawnManualBattleEnemy(cardId: EnemyLibrary.basicRed.id),
      isTrue,
    );
    expect(controller.enemies.single.config.id, EnemyLibrary.basicRed.id);

    controller.configureThreatDirectorDungeonBattle(
      towerLevel: 4,
      enemyDraft: [
        EnemyCardState(
          config: EnemyLibrary.basicWhite,
          unlocked: true,
          copies: 1,
          level: 1,
        ),
      ],
    );

    expect(controller.builtTowerCount, 3);
    expect(controller.slots.take(3).every((slot) => slot.isBuilt), isTrue);
    expect(controller.experience, 0);
    expect(controller.kills, 0);
  });

  test(
    'threat director apex spawns manually through shared battle runtime',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      controller.configureThreatDirectorDungeonBattle(
        towerLevel: 8,
        enemyDraft: [
          EnemyCardState(
            config: EnemyLibrary.basicWhite,
            unlocked: true,
            copies: 1,
            level: 1,
          ),
        ],
        bossDraft: EnemyCardState(
          config: BossEnemyLibrary.starterWhiteWarden,
          unlocked: true,
          copies: 1,
          level: 1,
        ),
      );

      controller.tick(2);
      expect(controller.enemies, isEmpty);
      expect(controller.activeBossEnemyCard?.config.id, isNotNull);
      expect(
        controller.spawnManualBattleEnemy(
          cardId: BossEnemyLibrary.starterWhiteWarden.id,
          boss: true,
        ),
        isTrue,
      );
      expect(controller.enemies.single.config.isBoss, isTrue);
    },
  );

  test(
    'threat director manual enemies move straight inward at boosted speed',
    () {
      final baseline = LightcoreController();
      final controller = LightcoreController();
      addTearDown(baseline.dispose);
      addTearDown(controller.dispose);

      baseline.configurePrismRiftDungeonBattle(
        towerLevel: 1,
        enemyDraft: [
          EnemyCardState(
            config: EnemyLibrary.basicWhite,
            unlocked: true,
            copies: 1,
            level: 1,
          ),
        ],
      );
      baseline.tick(0.2);
      final baselineSpeed = baseline.enemies.single.speed;

      controller.configureThreatDirectorDungeonBattle(
        towerLevel: 1,
        enemyDraft: [
          EnemyCardState(
            config: EnemyLibrary.basicWhite,
            unlocked: true,
            copies: 1,
            level: 1,
          ),
        ],
      );

      expect(
        controller.spawnManualBattleEnemy(cardId: EnemyLibrary.basicWhite.id),
        isTrue,
      );
      final spawned = controller.enemies.single;
      expect(spawned.angularVelocity, 0);
      expect(spawned.speed, closeTo(baselineSpeed * 5, 0.000001));

      controller.tick(0.5);

      final advanced = controller.enemies.single;
      expect(advanced.angle, closeTo(spawned.angle, 0.000001));
      expect(advanced.radius, lessThan(spawned.radius));
    },
  );

  test('prism rift dungeon keeps spiral enemy movement', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.configurePrismRiftDungeonBattle(
      towerLevel: 1,
      enemyDraft: [
        EnemyCardState(
          config: EnemyLibrary.basicWhite,
          unlocked: true,
          copies: 1,
          level: 1,
        ),
      ],
    );

    controller.tick(0.2);

    expect(controller.enemies, isNotEmpty);
    expect(controller.enemies.first.angularVelocity, greaterThan(0));
  });

  test('manual battle relay listener fires only on impact', () {
    final relayHits = <String>[];
    final controller = LightcoreController(
      relayHitListener: (enemy) => relayHits.add(enemy.id),
    );
    addTearDown(controller.dispose);

    controller.configureThreatDirectorDungeonBattle(
      towerLevel: 1,
      enemyDraft: [
        EnemyCardState(
          config: EnemyLibrary.basicRed,
          unlocked: true,
          copies: 1,
          level: 1,
        ),
      ],
      bossDraft: EnemyCardState(
        config: BossEnemyLibrary.starterWhiteWarden,
        unlocked: true,
        copies: 1,
        level: 20,
      ),
    );

    expect(
      controller.spawnManualBattleEnemy(
        cardId: BossEnemyLibrary.starterWhiteWarden.id,
        boss: true,
      ),
      isTrue,
    );
    final spawnedEnemyId = controller.enemies.single.id;
    expect(relayHits, isEmpty);

    controller.tick(0.1);
    expect(relayHits, isEmpty);

    for (var i = 0; i < 400 && controller.enemies.isNotEmpty; i++) {
      controller.tick(0.5);
    }
    expect(relayHits, contains(spawnedEnemyId));
    expect(controller.enemies, isEmpty);
  });

  test('prism rift battle uses highest-layer home tower shell', () {
    final source = LightcoreController();
    final controller = LightcoreController();
    addTearDown(source.dispose);
    addTearDown(controller.dispose);

    source.kills = LightcoreController.killsForOverallLevel(80);
    source.lumens = 100000;
    expect(source.debugSeedProgressionLayer(3), isTrue);

    controller.configurePrismRiftDungeonBattleFromHomeTower(
      source: source,
      towerLevel: 5,
      enemyDraft: [
        EnemyCardState(
          config: EnemyLibrary.basicRed,
          unlocked: true,
          copies: 1,
          level: 2,
        ),
      ],
    );

    expect(controller.activeLayer.tier, source.homeTowerLayer.tier);
    expect(controller.activeLayerLabel, source.homeTowerLayerLabel);
    expect(
      controller.coreState.projectileType,
      source.homeTowerLayer.core.projectileType,
    );
    expect(
      controller.builtTowerCount,
      source.homeTowerLayer.slots
          .where(
            (slot) =>
                (slot.config != null && !slot.isFabricating) ||
                slot.isPromotedChildTower,
          )
          .length,
    );
    expect(controller.towerCoreManager, isNull);
    expect(controller.activeEnemyCardIds, contains(EnemyLibrary.basicRed.id));
  });

  test('prism rift aimed fire creates battle-screen core shots', () {
    final source = LightcoreController();
    final controller = LightcoreController();
    addTearDown(source.dispose);
    addTearDown(controller.dispose);

    source.kills = LightcoreController.killsForOverallLevel(80);
    source.lumens = 100000;
    expect(source.debugSeedProgressionLayer(2), isTrue);
    controller.configurePrismRiftDungeonBattleFromHomeTower(
      source: source,
      towerLevel: 1,
      enemyDraft: [
        EnemyCardState(
          config: EnemyLibrary.basicRed,
          unlocked: true,
          copies: 1,
          level: 1,
        ),
      ],
    );
    var fired = false;
    for (var step = 0; step < 120 && !fired; step += 1) {
      controller.tick(0.1);
      if (controller.enemies.isEmpty) {
        continue;
      }
      final target = controller.enemies.first;
      fired = controller.firePrismRiftAimedShot(
        aimDx: math.cos(target.angle),
        aimDy: math.sin(target.angle),
      );
    }

    expect(fired, isTrue);
    expect(controller.shots, isNotEmpty);
    expect(controller.coreState.fireCooldownRemaining, greaterThan(0));
  });

  test('event offline progress counts as claimed offline time', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.advanceEventOfflineProgress(5);

    expect(controller.totalOfflineSecondsClaimed, 5);
  });
}
