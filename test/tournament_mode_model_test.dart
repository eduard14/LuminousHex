import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/data/enemy_configs.dart';
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
    expect(LightcoreTournamentModeId.arenaFlow.supportsBossDraft, isTrue);
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

  test('event offline progress counts as claimed offline time', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.advanceEventOfflineProgress(5);

    expect(controller.totalOfflineSecondsClaimed, 5);
  });
}
