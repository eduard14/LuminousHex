import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/app/lightcore_bootstrap.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void _completeLayer1Coverage(LightcoreController controller) {
  controller.lumens = 100000000;
  controller.kills = LightcoreController.unlockKillsForOuterSlot(
    LightcoreController.slotCount - 1,
  );
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    final config = TowerLibrary.all[index % TowerLibrary.all.length];
    if (controller.slots[index].config == null) {
      expect(controller.buildTowerAt(index, config), isTrue);
    }
    final remaining = controller.slots[index].fabricationRemainingSeconds;
    if (remaining > 0) {
      controller.tick(remaining + 0.1);
    }
  }
  expect(controller.managerAssignmentUnlocked, isTrue);
}

void main() {
  test('version comparison handles semantic ordering', () {
    expect(compareVersionStrings('1.0.0', '1.0.0'), 0);
    expect(compareVersionStrings('1.2.0', '1.1.9'), greaterThan(0));
    expect(compareVersionStrings('1.0.8', '1.0.20'), lessThan(0));
    expect(compareVersionStrings('2.0', '2.0.0'), 0);
    expect(compareVersionStrings('1.0.2+3', '1.0.3'), lessThan(0));
    expect(compareVersionStrings('1.0.2+3', '1.0.2'), 0);
  });

  test('content manifest computes version gates', () {
    const manifest = LightcoreContentManifest(
      firebaseProjectId: 'lumicore-95c8a',
      seasonKey: 'alpha',
      contentEpoch: 1,
      minimumSupportedVersion: '1.2.0',
      recommendedVersion: '1.3.0',
      backendMode: LightcoreBackendMode.firebaseBacked,
    );

    expect(manifest.versionGateFor('1.1.9'), LightcoreVersionGate.hardBlock);
    expect(manifest.versionGateFor('1.2.4'), LightcoreVersionGate.softUpdate);
    expect(manifest.versionGateFor('1.3.0'), LightcoreVersionGate.ok);
  });

  test('content manifest can gate same-version build numbers', () {
    const manifest = LightcoreContentManifest(
      firebaseProjectId: 'lumicore-95c8a',
      seasonKey: 'alpha',
      contentEpoch: 1,
      minimumSupportedVersion: '1.0.3',
      minimumSupportedBuildNumber: '4',
      recommendedVersion: '1.0.3',
      recommendedBuildNumber: '4',
      backendMode: LightcoreBackendMode.firebaseBacked,
    );

    expect(
      manifest.versionGateFor('1.0.3', clientBuildNumber: '3'),
      LightcoreVersionGate.hardBlock,
    );
    expect(
      manifest.versionGateFor('1.0.3', clientBuildNumber: '4'),
      LightcoreVersionGate.ok,
    );
    expect(
      manifest.versionGateFor('1.0.4', clientBuildNumber: '1'),
      LightcoreVersionGate.ok,
    );
  });

  test(
    'balance tuning clamps remote multipliers and feeds controller math',
    () {
      final tuning = LightcoreBalanceTuning.fromMap(<String, dynamic>{
        'balanceEpoch': 12,
        'active': true,
        'maxSingleStatDelta': 0.25,
        'maxCumulativeStatDelta': 0.1,
        'towerMultipliers': <String, dynamic>{
          TowerLibrary.redPrism.id: <String, dynamic>{
            'buildCost': 1.2,
            'basePower': 1.08,
          },
        },
        'economyMultipliers': <String, dynamic>{'lumenReward': 0.5},
      });

      expect(tuning.balanceEpoch, 12);
      expect(tuning.maxSingleStatDelta, closeTo(0.05, 0.0001));
      expect(tuning.maxCumulativeStatDelta, closeTo(0.1, 0.0001));
      expect(
        tuning.towerMultiplier(TowerLibrary.redPrism.id, 'buildCost'),
        closeTo(1.1, 0.0001),
      );
      expect(tuning.economyMultiplier('lumenReward'), closeTo(0.9, 0.0001));

      final controller = LightcoreController(balanceTuning: tuning);
      addTearDown(controller.dispose);

      expect(controller.balanceTuning.balanceEpoch, 12);
      expect(controller.buildCostForConfig(TowerLibrary.redPrism), 11);
    },
  );

  test('remote content manifests require a matching content hash', () {
    final balanceData = <String, dynamic>{
      'balanceEpoch': 3,
      'active': true,
      'towerMultipliers': <String, dynamic>{
        TowerLibrary.redPrism.id: <String, dynamic>{'basePower': 1.03},
      },
    };
    final tuning = LightcoreBalanceTuning.fromMap(balanceData);
    const baseManifest = LightcoreContentManifest(
      firebaseProjectId: 'lumicore-95c8a',
      seasonKey: 'alpha',
      contentEpoch: 7,
      minimumSupportedVersion: '1.0.3',
      minimumSupportedBuildNumber: '4',
      recommendedVersion: '1.0.3',
      recommendedBuildNumber: '4',
      backendMode: LightcoreBackendMode.firebaseBacked,
      balanceTuning: LightcoreBalanceTuning(
        balanceEpoch: 3,
        active: true,
        towerMultipliers: <String, Map<String, double>>{
          'red_prism': <String, double>{'basePower': 1.03},
        },
      ),
    );

    final payload = <String, dynamic>{
      'seasonKey': baseManifest.seasonKey,
      'contentEpoch': baseManifest.contentEpoch,
      'minimumSupportedVersion': baseManifest.minimumSupportedVersion,
      'minimumSupportedBuildNumber': baseManifest.minimumSupportedBuildNumber,
      'recommendedVersion': baseManifest.recommendedVersion,
      'recommendedBuildNumber': baseManifest.recommendedBuildNumber,
      'functionsRegion': baseManifest.functionsRegion,
      'usesRemoteContent': true,
      'appCheckRequired': true,
      'onlineFeaturesEnabled': true,
      'offlineProgressCapSeconds': baseManifest.offlineProgressCapSeconds,
      'balanceTuning': balanceData,
      'contentHash': computeLightcoreContentHash(
        contentSchemaVersion: 1,
        seasonKey: baseManifest.seasonKey,
        contentEpoch: baseManifest.contentEpoch,
        minimumSupportedVersion: baseManifest.minimumSupportedVersion,
        minimumSupportedBuildNumber: baseManifest.minimumSupportedBuildNumber,
        recommendedVersion: baseManifest.recommendedVersion,
        recommendedBuildNumber: baseManifest.recommendedBuildNumber,
        functionsRegion: baseManifest.functionsRegion,
        maintenanceMode: baseManifest.maintenanceMode,
        requiresMandatoryUpdate: baseManifest.requiresMandatoryUpdate,
        usesRemoteContent: true,
        appCheckRequired: true,
        onlineFeaturesEnabled: true,
        offlineProgressCapSeconds: baseManifest.offlineProgressCapSeconds,
        balanceTuning: tuning,
      ),
    };
    expect(
      payload['contentHash'],
      'bf0007ffb9d3693f53dbce248d59893bf365570cad2333461912b052a0199df5',
    );

    final manifest = LightcoreContentManifest.fromMap(
      payload,
      firebaseProjectId: 'lumicore-95c8a',
      backendMode: LightcoreBackendMode.firebaseBacked,
    );

    expect(manifest.contentHashVerified, isTrue);
    expect(manifest.contentTrusted, isTrue);

    final tamperedManifest = LightcoreContentManifest.fromMap(
      <String, dynamic>{...payload, 'contentEpoch': 8},
      firebaseProjectId: 'lumicore-95c8a',
      backendMode: LightcoreBackendMode.firebaseBacked,
    );
    expect(tamperedManifest.contentHashVerified, isFalse);

    final report = LightcoreBootstrapReport(
      guestSession: LightcoreGuestSession(
        playerId: 'GX-74E2-A91C',
        createdAt: DateTime(2026, 4, 21, 12),
        authLabel: 'Guest session',
      ),
      clientVersion: '1.0.3',
      clientBuildNumber: '4',
      manifest: tamperedManifest,
      profile: const LightcorePlayerProfileSummary(playerId: 'GX-74E2-A91C'),
      offlineClaim: const LightcoreOfflineClaimResult(
        secondsClaimed: 0,
        lumensGranted: 0,
        fluxGranted: 0,
        enemyTicketsGranted: 0,
        killsGranted: 0,
        serverValidated: true,
      ),
      integrityLevel: LightcoreIntegrityLevel.secure,
      firebaseReady: true,
      serverValidated: true,
      appCheckActive: true,
    );
    expect(report.contentResolved, isFalse);
    expect(report.canEnterGame, isFalse);
    expect(report.versionLabel, 'Content manifest verification failed');
  });

  test('bootstrap report requires live version resolution before entry', () {
    final guestSession = LightcoreGuestSession(
      playerId: 'GX-74E2-A91C',
      createdAt: DateTime(2026, 4, 21, 12),
      authLabel: 'Guest session',
    );

    final report = LightcoreBootstrapReport(
      guestSession: guestSession,
      clientVersion: '1.2.4',
      manifest: const LightcoreContentManifest(
        firebaseProjectId: 'lumicore-95c8a',
        seasonKey: 'alpha',
        contentEpoch: 1,
        minimumSupportedVersion: '1.2.0',
        recommendedVersion: '1.3.0',
        backendMode: LightcoreBackendMode.firebaseBacked,
      ),
      profile: const LightcorePlayerProfileSummary(playerId: 'GX-74E2-A91C'),
      offlineClaim: const LightcoreOfflineClaimResult(
        secondsClaimed: 0,
        lumensGranted: 0,
        fluxGranted: 0,
        enemyTicketsGranted: 0,
        killsGranted: 0,
        serverValidated: false,
      ),
      integrityLevel: LightcoreIntegrityLevel.degraded,
      firebaseReady: true,
      serverValidated: false,
      appCheckActive: false,
    );

    expect(report.versionResolved, isFalse);
    expect(report.canEnterGame, isFalse);

    final validatedReport = LightcoreBootstrapReport(
      guestSession: guestSession,
      clientVersion: '1.3.1',
      clientBuildNumber: '42',
      manifest: report.manifest,
      profile: report.profile,
      offlineClaim: const LightcoreOfflineClaimResult(
        secondsClaimed: 0,
        lumensGranted: 0,
        fluxGranted: 0,
        enemyTicketsGranted: 0,
        killsGranted: 0,
        serverValidated: true,
      ),
      integrityLevel: LightcoreIntegrityLevel.secure,
      firebaseReady: true,
      serverValidated: true,
      appCheckActive: true,
    );

    expect(validatedReport.versionResolved, isTrue);
    expect(validatedReport.latestVersionSatisfied, isTrue);
    expect(validatedReport.canEnterGame, isTrue);
    expect(validatedReport.clientDisplayVersion, '1.3.1+42');
  });

  test('controller exports offline snapshot and applies validated claim', () {
    final controller = LightcoreController();

    controller.selectCenter();
    _completeLayer1Coverage(controller);
    controller.flux = LightcoreController.towerManagerFluxCost;
    expect(controller.forgeTowerManager(), isTrue);
    controller.equipCardToSlot(controller.cards.last.instanceId, 0);

    final startingLumens = controller.lumens;
    final startingFlux = controller.flux;
    final startingTickets = controller.enemyTickets;
    final startingKills = controller.kills;
    final starterRegion = controller.threatRegionConfigs.first;
    controller.debugRevealThreatRegion(
      starterRegion.id,
      stabilizedLevel: starterRegion.stabilizationLayers,
    );
    controller.debugValidateThreatRegionFarm(starterRegion.id);

    final snapshot = controller.buildOfflineProgressSnapshot();

    expect(snapshot.passiveLumensPerHour, greaterThanOrEqualTo(0));
    expect(snapshot.killsPerHour, greaterThan(0));
    expect(snapshot.activeLayerTier, 1);

    controller.applyOfflineClaim(
      const LightcoreOfflineClaimResult(
        secondsClaimed: 3600,
        lumensGranted: 25,
        fluxGranted: 8,
        enemyTicketsGranted: 2,
        killsGranted: 5,
        serverValidated: true,
      ),
    );

    expect(controller.lumens, startingLumens + 25);
    expect(controller.flux, startingFlux + 8);
    expect(controller.enemyTickets, startingTickets + 2);
    expect(controller.kills, startingKills + 5);
  });

  test('player profile sync applies premium membership entitlement', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    expect(controller.hasPremiumMembership, isFalse);

    controller.syncPlayerProfile(
      const LightcorePlayerProfileSummary(
        playerId: 'GX-74E2-A91C',
        hasPremiumMembership: true,
      ),
    );

    expect(controller.hasPremiumMembership, isTrue);
  });

  test('controller round-trips cloud save progression payload', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    controller.flux = 444;
    controller.prismShards = 321;
    controller.enemyTickets = 27;
    controller.echoSeeds = 3;
    controller.experience = LightcoreController.experienceForOverallLevel(5);
    expect(controller.upgradeRadianceStat(LightcoreRadianceStat.might), isTrue);
    expect(
      controller.upgradeRadianceStat(LightcoreRadianceStat.insight),
      isTrue,
    );
    controller.setNotificationBannersEnabled(false);
    controller.setBattleNotificationBannersEnabled(true);
    controller.setTutorialPromptsEnabled(false);

    expect(controller.buildTowerAt(0, TowerLibrary.all.first), isTrue);

    final payload = controller.buildCloudSavePayload();
    final restored = LightcoreController.fromCloudSavePayload(payload);
    addTearDown(restored.dispose);

    expect(restored.flux, controller.flux);
    expect(restored.prismShards, controller.prismShards);
    expect(restored.enemyTickets, controller.enemyTickets);
    expect(restored.echoSeeds, controller.echoSeeds);
    expect(restored.kills, controller.kills);
    expect(restored.radianceStatRank(LightcoreRadianceStat.might), 1);
    expect(restored.radianceStatRank(LightcoreRadianceStat.insight), 1);
    expect(restored.unspentRadianceStatPoints, 2);
    expect(restored.notificationBannersEnabled, isFalse);
    expect(restored.battleNotificationBannersEnabled, isTrue);
    expect(restored.tutorialPromptsEnabled, isFalse);
    expect(restored.layers.length, controller.layers.length);
    expect(restored.slots.first.config?.id, controller.slots.first.config?.id);
    expect(restored.buildCloudSavePayload()['schemaVersion'], 1);
  });

  test('restore does not replay a fresh tutorial reward', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final payload = controller.buildCloudSavePayload();
    final resources = payload['resources'] as Map<String, dynamic>;
    final layers = payload['layers'] as Map<String, dynamic>;
    final layer =
        (layers['items'] as List<dynamic>).first as Map<String, dynamic>;
    final tutorial = payload['tutorial'] as Map<String, dynamic>;
    resources['enemyTickets'] = 4;
    layer['outerRingRevealed'] = true;
    tutorial['earlyQuestChainCompleted'] = true;
    tutorial.remove('rewardedSteps');

    final restored = LightcoreController.fromCloudSavePayload(payload);
    addTearDown(restored.dispose);

    expect(restored.enemyTickets, 4);
  });

  test('restore migrates server-sanitized early tutorial state', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final payload = controller.buildCloudSavePayload();
    final resources = payload['resources'] as Map<String, dynamic>;
    final layers = payload['layers'] as Map<String, dynamic>;
    final layer =
        (layers['items'] as List<dynamic>).first as Map<String, dynamic>;
    final core = layer['core'] as Map<String, dynamic>;
    final slots = layer['slots'] as List<dynamic>;
    final firstSlot = slots.first as Map<String, dynamic>;
    final tutorial = payload['tutorial'] as Map<String, dynamic>;

    resources['enemyPullCount'] = 1;
    resources['kills'] = LightcoreController.unlockKillsForOuterSlot(0);
    layer['outerRingRevealed'] = true;
    core['rangeUpgradeLevel'] = 1;
    firstSlot['configId'] = TowerLibrary.redPrism.id;
    firstSlot['level'] = 3;
    firstSlot['fireSequence'] = 3;
    tutorial['earlyQuestChainCompleted'] = false;
    tutorial.remove('stabilityPanelOpened');
    tutorial.remove('managerAutoAimShots');
    tutorial.remove('rewardedSteps');

    final restored = LightcoreController.fromCloudSavePayload(payload);
    addTearDown(restored.dispose);

    final restoredTutorial =
        restored.buildCloudSavePayload()['tutorial'] as Map<String, dynamic>;
    expect(restoredTutorial['earlyQuestChainCompleted'], isTrue);
    expect(restoredTutorial['stabilityPanelOpened'], isTrue);
    expect(restoredTutorial['managerAutoAimShots'], greaterThanOrEqualTo(5));
    expect(restored.managerAssignmentUnlocked, isFalse);
    expect(restored.tutorialStep, isNot(LightcoreTutorialStep.unfoldShell));
  });

  test('restore accepts legacy auto queue tutorial save fields', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final payload = controller.buildCloudSavePayload();
    final tutorial = payload['tutorial'] as Map<String, dynamic>;
    tutorial.remove('managerAutoAimShots');
    tutorial['autoQueuedPulses'] = 5;
    tutorial['rewardedSteps'] = <String>['autoQueueCheck'];

    final restored = LightcoreController.fromCloudSavePayload(payload);
    addTearDown(restored.dispose);

    final restoredTutorial =
        restored.buildCloudSavePayload()['tutorial'] as Map<String, dynamic>;
    expect(restoredTutorial['managerAutoAimShots'], 5);
    expect(restoredTutorial.containsKey('autoQueuedPulses'), isFalse);
    expect(
      restoredTutorial['rewardedSteps'],
      contains(LightcoreTutorialStep.managerAutoAim.name),
    );
  });

  test('outer slots unlock from cumulative kill milestones', () {
    final controller = LightcoreController();
    controller.lumens = 1000;

    expect(controller.unlockedOuterSlotCount, 1);
    expect(controller.buildTowerAt(1, TowerLibrary.all[1]), isFalse);

    controller.kills = LightcoreController.unlockKillsForOuterSlot(1);

    expect(controller.unlockedOuterSlotCount, 2);
    expect(controller.buildTowerAt(0, TowerLibrary.all.first), isTrue);
    expect(controller.buildTowerAt(1, TowerLibrary.all[1]), isTrue);
    expect(controller.buildTowerAt(2, TowerLibrary.all[2]), isFalse);

    controller.kills = LightcoreController.unlockKillsForOuterSlot(2);

    expect(controller.unlockedOuterSlotCount, 3);
    expect(controller.buildTowerAt(2, TowerLibrary.all[2]), isTrue);
  });
}
