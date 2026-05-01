import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/hex_tournament_run.dart';
import 'package:lightcore/models/lightcore_types.dart';

void main() {
  test('hex tournament waits for manual wave sends', () {
    final run = HexTournamentRunController(seedPowerIndex: 1400);

    run.start();
    run.tick(5);

    expect(run.wave, 0);
    expect(run.snapshot.enemies, isEmpty);

    expect(run.sendWave(), isTrue);
    expect(run.wave, 1);
    expect(run.snapshot.enemies, isNotEmpty);
  });

  test('path cells are cut out and open hexes expose all tower choices', () {
    final run = HexTournamentRunController(
      seedPowerIndex: 1400,
      startingCurrency: 500,
    )..start();
    final pathCell = run.snapshot.pathCells.first;
    final buildCell = run.snapshot.cells.firstWhere((cell) => cell.canBuild);

    expect(run.tapCell(pathCell.id), isFalse);
    expect(run.snapshot.towers, isEmpty);

    expect(run.tapCell(buildCell.id), isFalse);
    expect(run.snapshot.towers, isEmpty);
    expect(run.snapshot.canBuildSelected, isTrue);
    expect(run.snapshot.towerChoices, TowerLibrary.all);

    expect(
      run.placeTower(buildCell.id, config: TowerLibrary.purplePrism),
      isTrue,
    );
    expect(run.snapshot.towers, hasLength(1));
    expect(run.snapshot.towers.single.config, TowerLibrary.purplePrism);
    expect(run.snapshot.towers.single.payloadType, PayloadType.none);
    expect(run.snapshot.currency, 500 - HexTournamentRunController.buildCost);
  });

  test(
    'merging two base towers adds payload and payload towers add impact fire',
    () {
      final run = HexTournamentRunController(
        seedPowerIndex: 1400,
        startingCurrency: 1000,
      )..start();
      final cells = run.snapshot.cells
          .where((cell) => cell.canBuild)
          .take(4)
          .toList(growable: false);

      for (final cell in cells) {
        expect(
          run.placeTower(cell.id, config: TowerLibrary.purplePrism),
          isTrue,
        );
      }

      expect(run.mergeTowers(cells[0].id, cells[1].id), isTrue);
      expect(run.mergeTowers(cells[2].id, cells[3].id), isTrue);
      expect(run.snapshot.towers, hasLength(2));
      expect(
        run.snapshot.towers.every(
          (tower) => tower.payloadType != PayloadType.none,
        ),
        isTrue,
      );

      expect(run.mergeTowers(cells[0].id, cells[2].id), isTrue);
      final merged = run.snapshot.towers.single;
      expect(merged.mergeStage, 2);
      expect(merged.impactProjectileType, isNotNull);
    },
  );

  test('weekly focus towers carry the event damage bonus', () {
    final run = HexTournamentRunController(
      seedPowerIndex: 1400,
      startingCurrency: 1000,
    )..start();
    expect(run.snapshot.focusAffinities, contains(PrototypeAffinity.solar));

    final cells = run.snapshot.cells
        .where((cell) => cell.canBuild)
        .take(2)
        .toList(growable: false);
    expect(
      run.placeTower(cells[0].id, config: TowerLibrary.yellowPrism),
      isTrue,
    );
    expect(run.placeTower(cells[1].id, config: TowerLibrary.redPrism), isTrue);

    final focused = run.snapshot.towers.firstWhere(
      (tower) => tower.config.id == TowerLibrary.yellowPrism.id,
    );
    final offFocus = run.snapshot.towers.firstWhere(
      (tower) => tower.config.id == TowerLibrary.redPrism.id,
    );

    expect(focused.weeklyFocus, isTrue);
    expect(focused.focusDamageMultiplier, 1.16);
    expect(offFocus.weeklyFocus, isFalse);
    expect(offFocus.focusDamageMultiplier, 1.0);
  });

  test('clearing a wave without leaks awards a flawless streak', () {
    final run = HexTournamentRunController(
      seedPowerIndex: 1400,
      startingCurrency: 10000,
    )..start();
    final cells = run.snapshot.cells
        .where((cell) => cell.canBuild)
        .take(14)
        .toList(growable: false);
    for (final cell in cells) {
      expect(run.placeTower(cell.id, config: TowerLibrary.yellowPrism), isTrue);
    }

    expect(run.sendWave(), isTrue);
    for (
      var frame = 0;
      frame < 2400 && run.snapshot.waveInProgress;
      frame += 1
    ) {
      run.tick(0.05);
    }

    expect(run.snapshot.waveInProgress, isFalse);
    expect(run.snapshot.health, run.snapshot.maxHealth);
    expect(run.snapshot.waveLeakDamage, 0);
    expect(run.snapshot.flawlessStreak, 1);
    expect(run.snapshot.statusLabel, contains('flawless'));
  });

  test('buying enemy tier makes future wave enemies worth more score', () {
    final baseline = HexTournamentRunController(
      seedPowerIndex: 1400,
      startingCurrency: 1000,
    )..start();
    baseline.sendWave();
    final baselineEnemy = baseline.snapshot.enemies.first;

    final greedy = HexTournamentRunController(
      seedPowerIndex: 1400,
      startingCurrency: 1000,
    )..start();
    final scoreBeforeTierBuy = greedy.score;
    expect(greedy.buyEnemyTier(), isTrue);
    expect(greedy.score, scoreBeforeTierBuy);
    greedy.sendWave();
    final greedyEnemy = greedy.snapshot.enemies.first;

    expect(greedyEnemy.tier, greaterThan(baselineEnemy.tier));
    expect(greedyEnemy.maxHealth, greaterThan(baselineEnemy.maxHealth));
    expect(greedyEnemy.scoreValue, greaterThan(baselineEnemy.scoreValue));
  });

  test('leaked enemies can end the run without offline progress', () {
    final run = HexTournamentRunController(seedPowerIndex: 1400)..start();

    for (var frame = 0; frame < 5000 && !run.defeated; frame += 1) {
      if (run.snapshot.canSendWave) {
        expect(run.sendWave(), isTrue);
      }
      run.tick(0.05);
    }

    expect(run.defeated, isTrue);
    expect(run.running, isFalse);
  });
}
