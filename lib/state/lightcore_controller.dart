import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../app/lightcore_bootstrap.dart';
import '../data/card_configs.dart';
import '../data/equipment_configs.dart';
import '../data/enemy_configs.dart';
import '../data/enemy_manager_configs.dart';
import '../data/lumicore_trait_catalog.dart';
import '../data/medal_configs.dart';
import '../data/tower_configs.dart';
import '../models/lightcore_config.dart';
import '../models/lightcore_cloud_save.dart';
import '../models/lightcore_currency_labels.dart';
import '../models/lightcore_friend_state.dart';
import '../models/lightcore_guide.dart';
import '../models/lightcore_guild_state.dart';
import '../models/lightcore_progression.dart';
import '../models/lightcore_social_state.dart';
import '../models/lightcore_state.dart';
import '../models/lightcore_tournament.dart';
import '../models/lightcore_types.dart';
part 'lightcore_controller/state_accessors.dart';
part 'lightcore_controller/save_restore.dart';
part 'lightcore_controller/save_restore_payload.dart';
part 'lightcore_controller/save_inventory_serialization.dart';
part 'lightcore_controller/save_layer_serialization.dart';
part 'lightcore_controller/save_social_balance.dart';
part 'lightcore_controller/save_tournament_cloud.dart';
part 'lightcore_controller/save_accessors.dart';
part 'lightcore_controller/rewards_social.dart';
part 'lightcore_controller/rewards_battle_pass_setup.dart';
part 'lightcore_controller/rewards_social_relay_private.dart';
part 'lightcore_controller/rewards_status_battle_pass.dart';
part 'lightcore_controller/rewards_social_guild.dart';
part 'lightcore_controller/rewards_economy_store.dart';
part 'lightcore_controller/rewards_patterns.dart';
part 'lightcore_controller/progression_layers.dart';
part 'lightcore_controller/layer_traits.dart';
part 'lightcore_controller/battle_actions.dart';
part 'lightcore_controller/battle_unlocks.dart';
part 'lightcore_controller/battle_tower_actions.dart';
part 'lightcore_controller/battle_enemy_actions.dart';
part 'lightcore_controller/battle_reset_actions.dart';
part 'lightcore_controller/tower_math.dart';
part 'lightcore_controller/combat_loop.dart';
part 'lightcore_controller/combat_projectiles.dart';
part 'lightcore_controller/combat_enemies.dart';
part 'lightcore_controller/combat_firing.dart';
part 'lightcore_controller/combat_damage.dart';
part 'lightcore_controller/combat_equipment.dart';
part 'lightcore_controller/combat_followups.dart';
part 'lightcore_controller/inventory_runtime.dart';

enum LightcoreTutorialStep {
  none,
  unfoldShell,
  waitForFirstHex,
  selectFirstHex,
  buildFirstRedTower,
  tapBattleCore,
  tapFirstTower,
  tapSecondShellTower,
  upgradeFirstTowerToLevel3,
  pullFirstWhiteEnemy,
  readEffectiveGain,
  autoQueueCheck,
  upgradeFirstTowerToLevel4,
  pullFirstRedEnemy,
  setFirstEnemyTarget,
  adjustEnemyCount,
  openTowerMatrix,
  upgradeCoreRange,
  openStore,
  claimBattlePassReward,
  openBossPulls,
  armFirstBoss,
  defeatFirstBoss,
  openEquipment,
  openManagers,
  forgeTowerManager,
  assignTowerManager,
  forgeEnemyManager,
  assignEnemyManager,
  holdOverdrive,
  setScreenName,
  openFriends,
  openMentees,
  openMentors,
  inspectEnemyBlitz,
  inspectHexGauntlet,
  inspectArenaFlow,
}

enum LightcoreTutorialPulseTarget {
  pullsButton,
  playerManagerButton,
  overdriveButton,
}

enum LightcoreTimeWarpCurrency { flux, prismShards }

enum LightcoreRadianceStat { might, focus, tempo, insight }

class LightcoreDailyDungeonReward {
  const LightcoreDailyDungeonReward({
    required this.towerLevel,
    required this.lumens,
    required this.flux,
    required this.threatScans,
    required this.experience,
  });

  final int towerLevel;
  final int lumens;
  final int flux;
  final int threatScans;
  final int experience;

  bool get hasRewards =>
      lumens > 0 || flux > 0 || threatScans > 0 || experience > 0;

  String get label {
    final parts = <String>[
      if (lumens > 0) LightcoreCurrencyLabels.rewardLumens(lumens),
      if (flux > 0) LightcoreCurrencyLabels.rewardFlux(flux),
      if (threatScans > 0)
        LightcoreCurrencyLabels.rewardThreatScans(threatScans),
      if (experience > 0) '+$experience EXP',
    ];
    return parts.join(', ');
  }
}

class LightcoreDailyDungeonTowerProfile {
  const LightcoreDailyDungeonTowerProfile({
    required this.towerLevel,
    required this.config,
    required this.displayLevel,
    required this.maxHealth,
    required this.shotDamage,
    required this.chargeRate,
    required this.cooldownSeconds,
  });

  final int towerLevel;
  final TowerConfig config;
  final int displayLevel;
  final double maxHealth;
  final double shotDamage;
  final double chargeRate;
  final double cooldownSeconds;

  PrototypeAffinity get affinity => config.affinity;
  ProjectileType get projectileType => config.defaultProjectileType;
  PayloadType get payloadType => config.defaultPayloadType;
  String get title => '${affinity.label} ${config.name}';
  String get managerLabel => 'Enemy Manager';
}

class LightcoreTimeWarpOfferDefinition {
  const LightcoreTimeWarpOfferDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.durationSeconds,
    required this.cost,
    required this.currency,
    required this.weeklyLimit,
    required this.badgeLabel,
  });

  final String id;
  final String title;
  final String subtitle;
  final int durationSeconds;
  final int cost;
  final LightcoreTimeWarpCurrency currency;
  final int weeklyLimit;
  final String badgeLabel;

  String get durationLabel {
    final duration = Duration(seconds: durationSeconds);
    if (duration.inHours >= 1) {
      final minutes = duration.inMinutes.remainder(60);
      return minutes == 0
          ? '${duration.inHours}h'
          : '${duration.inHours}h ${minutes}m';
    }
    return '${duration.inMinutes}m';
  }
}

class LightcoreTutorialQuestDefinition {
  const LightcoreTutorialQuestDefinition({
    required this.id,
    required this.title,
    required this.teachGoal,
    required this.trigger,
    required this.primaryClickTarget,
    required this.coachCopy,
    required this.completionCondition,
    required this.reward,
    required this.failureHelpState,
    required this.analyticsEvent,
  });

  final String id;
  final String title;
  final String teachGoal;
  final String trigger;
  final String primaryClickTarget;
  final String coachCopy;
  final String completionCondition;
  final String reward;
  final String failureHelpState;
  final String analyticsEvent;
}

const Map<LightcoreTutorialStep, LightcoreTutorialQuestDefinition>
_tutorialQuestDefinitions = <LightcoreTutorialStep, LightcoreTutorialQuestDefinition>{
  LightcoreTutorialStep.unfoldShell: LightcoreTutorialQuestDefinition(
    id: 'TUT-001',
    title: 'Wake the Core',
    teachGoal:
        'The core is the active battle center and only fires queued pulses.',
    trigger: 'New account',
    primaryClickTarget: 'Core Map > tap central core',
    coachCopy:
        'The center is your active light core. It fires only when its queue has pulses.',
    completionCondition: 'Tap central core',
    reward: 'Safe White Threat Scan x1',
    failureHelpState:
        'Pulse the central core again and keep nonessential UI dimmed.',
    analyticsEvent: 'tutorial_wake_core',
  ),
  LightcoreTutorialStep.buildFirstRedTower: LightcoreTutorialQuestDefinition(
    id: 'TUT-002',
    title: 'Fabricate First Light',
    teachGoal: 'Empty adjacent spaces fabricate Layer 1 towers.',
    trigger: 'After TUT-001',
    primaryClickTarget: 'Empty hex beside core > Fabricate',
    coachCopy:
        'Build a Layer 1 tower in an empty adjacent space. Fabrication is time-gated after the first free build.',
    completionCondition: 'Start or finish first Fabrication',
    reward: 'Instant first tower',
    failureHelpState:
        'Highlight the first available hex and the Fabricate button.',
    analyticsEvent: 'tutorial_fabricate_first_light',
  ),
  LightcoreTutorialStep.tapFirstTower: LightcoreTutorialQuestDefinition(
    id: 'TUT-003',
    title: 'Queue a Pulse',
    teachGoal:
        'Towers add pulses to the core queue while the player is active.',
    trigger: 'First tower exists',
    primaryClickTarget: 'Tower > Add Pulse to Queue',
    coachCopy:
        'Towers fire what is in their queue. Tap to add pulses while active.',
    completionCondition: 'Add 3 queue pulses',
    reward: 'White Drift practice scan',
    failureHelpState: 'Show charge and cooldown if the tower is not ready.',
    analyticsEvent: 'tutorial_queue_pulse',
  ),
  LightcoreTutorialStep.pullFirstWhiteEnemy: LightcoreTutorialQuestDefinition(
    id: 'TUT-004',
    title: 'Run a Safe Threat Scan',
    teachGoal: 'Threat Scans choose which anomalies enter the active deck.',
    trigger: 'Queue tutorial done',
    primaryClickTarget: 'Threat Scan flag > White Drift > Begin',
    coachCopy:
        'Threat Scans choose what anomalies spawn. Stronger scans give better gains, but pressure your core.',
    completionCondition: 'Resolve 1 Threat Scan',
    reward: 'Unlock Threat Scan panel',
    failureHelpState:
        'Use a safe White Drift scan and review the resolved signature.',
    analyticsEvent: 'tutorial_safe_threat_scan',
  ),
  LightcoreTutorialStep.readEffectiveGain: LightcoreTutorialQuestDefinition(
    id: 'TUT-005',
    title: 'Read Effective Gain',
    teachGoal:
        'Effective Gain is the real farm value after stability pressure.',
    trigger: 'After first scan',
    primaryClickTarget: 'Left stat stack > Output Efficiency %',
    coachCopy:
        'Income = Base Gain x Threat Multiplier x Output Efficiency. Bigger threats are only good if stability holds.',
    completionCondition: 'Open stability panel',
    reward: 'Small Lumen boost',
    failureHelpState:
        'Pulse the Output Efficiency stat and show the formula again.',
    analyticsEvent: 'tutorial_read_effective_gain',
  ),
  LightcoreTutorialStep.assignTowerManager: LightcoreTutorialQuestDefinition(
    id: 'TUT-006',
    title: 'Assign a Core Manager',
    teachGoal:
        'A Core Manager sockets into the Tower Core and automates every tower in the active shell.',
    trigger: 'After Output Efficiency shown',
    primaryClickTarget: 'Managers > Core Manager > Assign to Tower Core',
    coachCopy:
        'One Core Manager runs the shell. Managers create auto-queue and add tower-wide bonuses.',
    completionCondition: 'Assign manager to core',
    reward: 'Starter manager',
    failureHelpState: 'Highlight the starter manager and Tower Core socket.',
    analyticsEvent: 'tutorial_assign_core_manager',
  ),
  LightcoreTutorialStep.autoQueueCheck: LightcoreTutorialQuestDefinition(
    id: 'TUT-007',
    title: 'Auto Queue Check',
    teachGoal:
        'Managers keep queue generation moving while the player is idle.',
    trigger: 'Manager assigned',
    primaryClickTarget: 'Core > Queue display',
    coachCopy:
        'Your manager keeps the queue moving while you are idle. Tapping still helps during active play.',
    completionCondition: 'Let manager generate 5 pulses',
    reward: 'Threat Scan x1',
    failureHelpState:
        'Keep the managed tower in view and show generated pulse count.',
    analyticsEvent: 'tutorial_auto_queue_check',
  ),
  LightcoreTutorialStep.upgradeCoreRange: LightcoreTutorialQuestDefinition(
    id: 'TUT-008',
    title: 'Upgrade a Global Stat',
    teachGoal: 'Account and core growth unlock permanent upgrade paths.',
    trigger: 'Player level 2',
    primaryClickTarget: 'Profile/Level badge > Global Stats > Upgrade',
    coachCopy:
        'Leveling unlocks global stats and modes. Pick a permanent stat upgrade.',
    completionCondition: 'Buy one global stat',
    reward: 'Unlock Level Goals panel',
    failureHelpState: 'Highlight the first affordable core/global upgrade.',
    analyticsEvent: 'tutorial_upgrade_global_stat',
  ),
};

// TODO(full-game): Split local authority here into separate layers:
// 1) a synced player-profile repository for persistence and conflict resolution,
// 2) a content service for downloaded definitions and live balancing, and
// 3) a battle runtime that can replay offline progress from timestamps.
// Convenience aliases keep extension part files readable while preserving
// the public static API on LightcoreController.
const int slotCount = LightcoreController.slotCount;
const int maxShellTier = LightcoreController.maxShellTier;
const int maxTowerLevel = LightcoreController.maxTowerLevel;
const int maxTowerUpgradeRank = LightcoreController.maxTowerUpgradeRank;
const int minTowerUpgradeOptions = LightcoreController.minTowerUpgradeOptions;
const int maxTowerUpgradeOptions = LightcoreController.maxTowerUpgradeOptions;
const int enemyDeckLimit = LightcoreController.enemyDeckLimit;
const int bossSpawnKillRequirement =
    LightcoreController.bossSpawnKillRequirement;
const int bossUnlockLevel = LightcoreController.bossUnlockLevel;
const int tournamentUnlockLevel = LightcoreController.tournamentUnlockLevel;
const int mentorshipUnlockLevel = LightcoreController.mentorshipUnlockLevel;
const int dailyDungeonUnlockLevel = LightcoreController.dailyDungeonUnlockLevel;
const int dailyDungeonStartingTowerLevel =
    LightcoreController.dailyDungeonStartingTowerLevel;
const int dailyDungeonMaxTowerLevel =
    LightcoreController.dailyDungeonMaxTowerLevel;
const int bossUnlockTicketGrant = LightcoreController.bossUnlockTicketGrant;
const int enemyTicketCost = LightcoreController.enemyTicketCost;
const int bossTicketCost = LightcoreController.bossTicketCost;
const int maxSummoningLevel = LightcoreController.maxSummoningLevel;
const int firstSummoningLevelPullGap =
    LightcoreController.firstSummoningLevelPullGap;
const int finalSummoningLevelPullGap =
    LightcoreController.finalSummoningLevelPullGap;
const int minSummoningLevelTicketReward =
    LightcoreController.minSummoningLevelTicketReward;
const int maxSummoningLevelTicketReward =
    LightcoreController.maxSummoningLevelTicketReward;
const int bossPullsPerSummoningLevel =
    LightcoreController.bossPullsPerSummoningLevel;
const int maxBossSummoningLevel = LightcoreController.maxBossSummoningLevel;
const int maxBossCardLevel = LightcoreController.maxBossCardLevel;
const int minScreenNameLength = LightcoreController.minScreenNameLength;
const int maxScreenNameLength = LightcoreController.maxScreenNameLength;
const int towerManagerFluxCost = LightcoreController.towerManagerFluxCost;
const int enemyManagerFluxCost = LightcoreController.enemyManagerFluxCost;
const int maxEquipmentInventorySize =
    LightcoreController.maxEquipmentInventorySize;
const int traitRefreshLumenCost = LightcoreController.traitRefreshLumenCost;
const int maxActiveEnemies = LightcoreController.maxActiveEnemies;
const int evenEntryTournamentLevel =
    LightcoreController.evenEntryTournamentLevel;
const int evenEntryTournamentCoreLevel =
    LightcoreController.evenEntryTournamentCoreLevel;
const int evenEntryTournamentPowerIndex =
    LightcoreController.evenEntryTournamentPowerIndex;
const int minEnemyTarget = LightcoreController.minEnemyTarget;
const int initialEnemyTarget = LightcoreController.initialEnemyTarget;
const int baseEnemyTargetMax = LightcoreController.baseEnemyTargetMax;
const int enemyTargetUpgradeStep = LightcoreController.enemyTargetUpgradeStep;
const int _legacyEnemyTargetUpgradeStep =
    LightcoreController._legacyEnemyTargetUpgradeStep;
const int maxEnemyTargetUpgradeLevel =
    LightcoreController.maxEnemyTargetUpgradeLevel;
const double _maxFlowEfficiency = LightcoreController._maxFlowEfficiency;
const double _maxCoreStability = LightcoreController._maxCoreStability;
const double _minimumOutputEfficiency =
    LightcoreController._minimumOutputEfficiency;
const double _baseCoreStabilityRecoveryPerSecond =
    LightcoreController._baseCoreStabilityRecoveryPerSecond;
const double _apexBaseStabilityDamageMultiplier =
    LightcoreController._apexBaseStabilityDamageMultiplier;
const double _apexRarityStabilityDamageStep =
    LightcoreController._apexRarityStabilityDamageStep;
const double _minimumSpawnRadius = LightcoreController._minimumSpawnRadius;
const double _defaultTowerLaneRangeShare =
    LightcoreController._defaultTowerLaneRangeShare;
const double _spawnRadiusBandSpacing =
    LightcoreController._spawnRadiusBandSpacing;
const int _spawnRadiusBandCount = LightcoreController._spawnRadiusBandCount;
const double _spawnCrowdRadiusPerEnemy =
    LightcoreController._spawnCrowdRadiusPerEnemy;
const int _spawnClusterSize = LightcoreController._spawnClusterSize;
const double _spawnClusterAngleStep =
    LightcoreController._spawnClusterAngleStep;
const double _spawnClusterAngleJitter =
    LightcoreController._spawnClusterAngleJitter;
const double _spawnClusterRadiusJitter =
    LightcoreController._spawnClusterRadiusJitter;
const double _relayImpactRadius = LightcoreController._relayImpactRadius;
const double _pulseSpeed = LightcoreController._pulseSpeed;
const double _shotSpeed = LightcoreController._shotSpeed;
const double _impactSpeed = LightcoreController._impactSpeed;
const double _coreBombSplashRadius = LightcoreController._coreBombSplashRadius;
const double _chainArcImpactLingerSeconds =
    LightcoreController._chainArcImpactLingerSeconds;
const double _blueFocusLaserDamageMultiplier =
    LightcoreController._blueFocusLaserDamageMultiplier;
const double _towerDamageOutputMultiplier =
    LightcoreController._towerDamageOutputMultiplier;
const double _bossBaseHealthScale = LightcoreController._bossBaseHealthScale;
const double _bossTierHealthScaleStep =
    LightcoreController._bossTierHealthScaleStep;
const double _bossWorldPressurePerSpawn =
    LightcoreController._bossWorldPressurePerSpawn;
const double _bossWorldPressurePerBuiltTower =
    LightcoreController._bossWorldPressurePerBuiltTower;
const double _bossWorldPressureCap = LightcoreController._bossWorldPressureCap;
const double _bossBaseDefenseScale = LightcoreController._bossBaseDefenseScale;
const double _bossTierDefenseScaleStep =
    LightcoreController._bossTierDefenseScaleStep;
const double _bossSpeedScale = LightcoreController._bossSpeedScale;
const double _uiNotifyCadence = LightcoreController._uiNotifyCadence;
const double _coreBaseRange = LightcoreController._coreBaseRange;
const double _promotedChildTowerRangeMultiplier =
    LightcoreController._promotedChildTowerRangeMultiplier;
const double _promotedCoreShotPowerMultiplier =
    LightcoreController._promotedCoreShotPowerMultiplier;
const double _promotedCoreShotPowerTierStep =
    LightcoreController._promotedCoreShotPowerTierStep;
const double _promotedSourcePassiveMultiplier =
    LightcoreController._promotedSourcePassiveMultiplier;
const double _coreBaseCooldown = LightcoreController._coreBaseCooldown;
const double _coreBaseCritChance = LightcoreController._coreBaseCritChance;
const double _coreBaseCritMultiplier =
    LightcoreController._coreBaseCritMultiplier;
const int maxCoreUpgradeLevel = LightcoreController.maxCoreUpgradeLevel;
const int maxCoreMultiShotUpgradeLevel =
    LightcoreController.maxCoreMultiShotUpgradeLevel;
const int baseCoreQueueCapacity = LightcoreController.baseCoreQueueCapacity;
const int coreQueueCapacityUpgradeStep =
    LightcoreController.coreQueueCapacityUpgradeStep;
const int maxOfflineProgressSeconds =
    LightcoreController.maxOfflineProgressSeconds;
const int childTowerUpgradeOptionsPerLevel =
    LightcoreController.childTowerUpgradeOptionsPerLevel;
const int childTowerUpgradeMaxRank =
    LightcoreController.childTowerUpgradeMaxRank;
const int payloadUnlockLayer = LightcoreController.payloadUnlockLayer;
const int managerUnlockLevel = LightcoreController.managerUnlockLevel;
const List<PrototypeAffinity> childCoreAffinityChoices =
    LightcoreController.childCoreAffinityChoices;
const double towerConstructionDurationSeconds =
    LightcoreController.towerConstructionDurationSeconds;
const int friendRelayLevelBand = LightcoreController.friendRelayLevelBand;
const int defaultGuildCreationUnlockLevel =
    LightcoreController.defaultGuildCreationUnlockLevel;
const int guildMemberCap = LightcoreController.guildMemberCap;
const int helpSectionTicketReward = LightcoreController.helpSectionTicketReward;
const String timeWarpFluxThirtyMinutesId =
    LightcoreController.timeWarpFluxThirtyMinutesId;
const String timeWarpPrismThirtyMinutesId =
    LightcoreController.timeWarpPrismThirtyMinutesId;
const String timeWarpPrismTwoHoursId =
    LightcoreController.timeWarpPrismTwoHoursId;
const String timeWarpPrismTwelveHoursId =
    LightcoreController.timeWarpPrismTwelveHoursId;
const List<LightcoreTimeWarpOfferDefinition> timeWarpOffers =
    LightcoreController.timeWarpOffers;
const double _normalFluxDropChance = LightcoreController._normalFluxDropChance;
const double _fluxDropChancePerRarity =
    LightcoreController._fluxDropChancePerRarity;
const double _bossFluxDropChance = LightcoreController._bossFluxDropChance;
const double _normalThreatScanDropChance =
    LightcoreController._normalThreatScanDropChance;
const double _threatScanDropChancePerRarity =
    LightcoreController._threatScanDropChancePerRarity;
const double _bossThreatScanDropChance =
    LightcoreController._bossThreatScanDropChance;
const List<String> _mockFriendNames = LightcoreController._mockFriendNames;
const List<String> _mockGuildReplies = LightcoreController._mockGuildReplies;
final Set<PrototypeAffinity> _rainbowTowerAffinities =
    LightcoreController._rainbowTowerAffinities;
const double _manualOverdriveTapBurst =
    LightcoreController._manualOverdriveTapBurst;
const double _manualOverdriveChargePerSecond =
    LightcoreController._manualOverdriveChargePerSecond;
const double _manualOverdriveDecayPerSecond =
    LightcoreController._manualOverdriveDecayPerSecond;
const double _baseBattleSpeedMultiplier =
    LightcoreController._baseBattleSpeedMultiplier;
const double _manualOverdriveMaxMultiplier =
    LightcoreController._manualOverdriveMaxMultiplier;
const double _localhostAutoTapperCoreInterval =
    LightcoreController._localhostAutoTapperCoreInterval;
const double _maxLumenHarvestSlowdown =
    LightcoreController._maxLumenHarvestSlowdown;
const double _relayHitLumenHarvestDamageScale =
    LightcoreController._relayHitLumenHarvestDamageScale;
const double _emptyLaneLumenHarvestDamageScale =
    LightcoreController._emptyLaneLumenHarvestDamageScale;
const int firstOuterSlotKillRequirement =
    LightcoreController.firstOuterSlotKillRequirement;
const List<int> outerSlotUnlockExperienceThresholds =
    LightcoreController.outerSlotUnlockExperienceThresholds;
const double maxOfflineKillsPerHour =
    LightcoreController.maxOfflineKillsPerHour;
String shellNameForTier(int tier) => LightcoreController.shellNameForTier(tier);
String shellBadgeForTier(int tier) =>
    LightcoreController.shellBadgeForTier(tier);
Map<String, dynamic> _coerceMap(dynamic value) =>
    LightcoreController._coerceMap(value);
List<dynamic> _coerceList(dynamic value) =>
    LightcoreController._coerceList(value);
String _stringValue(dynamic value, {String fallback = ''}) =>
    LightcoreController._stringValue(value, fallback: fallback);
String? _stringOrNull(dynamic value) =>
    LightcoreController._stringOrNull(value);
bool _boolValue(dynamic value, {bool fallback = false}) =>
    LightcoreController._boolValue(value, fallback: fallback);
int _intValue(dynamic value, {int fallback = 0}) =>
    LightcoreController._intValue(value, fallback: fallback);
int? _intOrNull(dynamic value) => LightcoreController._intOrNull(value);
double _doubleValue(dynamic value, {double fallback = 0}) =>
    LightcoreController._doubleValue(value, fallback: fallback);
double? _doubleOrNull(dynamic value) =>
    LightcoreController._doubleOrNull(value);
T? _enumByName<T extends Enum>(List<T> values, String? name) =>
    LightcoreController._enumByName(values, name);
double _outputEfficiencyPercentForStability(double stability) =>
    LightcoreController._outputEfficiencyPercentForStability(stability);
double _stabilityForLegacyOutputEfficiency(double flowEfficiency) =>
    LightcoreController._stabilityForLegacyOutputEfficiency(flowEfficiency);
int summoningLevelForPullCount(int pullCount) =>
    LightcoreController.summoningLevelForPullCount(pullCount);
int summoningLevelPullTargetForLevel(int level) =>
    LightcoreController.summoningLevelPullTargetForLevel(level);
int summoningLevelPullGapForLevel(int level) =>
    LightcoreController.summoningLevelPullGapForLevel(level);
int summoningLevelTicketRewardForLevel(int level) =>
    LightcoreController.summoningLevelTicketRewardForLevel(level);
int bossSummoningLevelTicketRewardForLevel(int level) =>
    LightcoreController.bossSummoningLevelTicketRewardForLevel(level);
String _normalizeOptionalScreenName(String? value) =>
    LightcoreController._normalizeOptionalScreenName(value);
int _screenNameLength(String value) =>
    LightcoreController._screenNameLength(value);
int _screenNameVisibleLength(String value) =>
    LightcoreController._screenNameVisibleLength(value);
int unlockExperienceForOuterSlot(int slotIndex) =>
    LightcoreController.unlockExperienceForOuterSlot(slotIndex);
int unlockKillsForOuterSlot(int slotIndex) =>
    LightcoreController.unlockKillsForOuterSlot(slotIndex);
int unlockedOuterSlotCountForExperience(int totalExperience) =>
    LightcoreController.unlockedOuterSlotCountForExperience(totalExperience);
int unlockedOuterSlotCountForKills(int totalKills) =>
    LightcoreController.unlockedOuterSlotCountForKills(totalKills);
int experienceForOverallLevel(int level) =>
    LightcoreController.experienceForOverallLevel(level);
int killsForOverallLevel(int level) =>
    LightcoreController.killsForOverallLevel(level);
int overallLevelForExperience(int totalExperience) =>
    LightcoreController.overallLevelForExperience(totalExperience);
int overallLevelForKills(int totalKills) =>
    LightcoreController.overallLevelForKills(totalKills);

class LightcoreController extends ChangeNotifier {
  LightcoreController({
    Random? packRandom,
    Random? traitRandom,
    Random? managerRandom,
    Random? spawnRandom,
    LightcoreGuideProfile? guideProfile,
    String playerId = 'LUMI-LOCAL',
    String? screenName,
    bool guildsEnabled = true,
    int guildCreationUnlockLevel = defaultGuildCreationUnlockLevel,
    LightcoreBalanceTuning balanceTuning = LightcoreBalanceTuning.defaults,
  }) : _packRandom = packRandom ?? Random(),
       _traitRandom = traitRandom ?? Random(),
       _managerRandom = managerRandom ?? Random(),
       _spawnRandom = spawnRandom ?? Random(),
       _guideProfile = guideProfile ?? LightcoreGuideProfile.lumo,
       _playerId = playerId,
       _screenName = _normalizeOptionalScreenName(screenName),
       _guildsEnabled = guildsEnabled,
       _guildCreationUnlockLevel = max(1, guildCreationUnlockLevel),
       _balanceTuning = balanceTuning {
    _cards = <InventoryCard>[];
    _enemyManagers = <EnemyManagerState>[];
    _equipmentInventory = <PlayerEquipmentItem>[];
    _equippedPlayerItems = <EquipmentLoadoutSlot, String?>{
      for (final slot in EquipmentLoadoutSlot.values) slot: null,
    };
    _equippedProfileMedalId = null;
    _unlockedProfileMedalIds.clear();
    _enemyCards = _createEnemyCardInventory();
    _bossEnemyCards = BossEnemyLibrary.all
        .map((config) => EnemyCardState(config: config))
        .toList();
    _activeBossEnemyCardId = null;
    _seedStarterEnemyCards();
    _seedStarterManagers();
    _layers = <TowerLayerSnapshot>[];
    final rootLayer = _freshLayerSnapshot(label: shellNameForTier(1), tier: 1);
    _layers.add(rootLayer);
    _viewLayerId = rootLayer.id;
    _runtimeLayerId = rootLayer.id;
    _loadLayer(rootLayer);
    _battlePasses = _createBattlePassMap();
    _timeWarpPurchaseWeekKey = _currentWeekKey();
    _storeOfferPurchaseWeekKey = _currentWeekKey();
    _sharedRelayOuterPieceIds = List<String?>.filled(slotCount, null);
    _initializeSharedRelayLoadout();
    _showBanner(
      'Wake the Lightcore. The route ahead is full of black holes. Unfold the first shell and anchor your first prism.',
      duration: 3.2,
    );
    _syncTutorialStep(showBanner: false);
  }

  factory LightcoreController.fromCloudSavePayload(
    Map<String, dynamic> payload, {
    LightcoreGuideProfile? fallbackGuideProfile,
    LightcoreBalanceTuning balanceTuning = LightcoreBalanceTuning.defaults,
  }) {
    final playerData = _coerceMap(payload['player']);
    final savedGuide = LightcoreGuideProfile.maybeFromStorageId(
      _stringOrNull(playerData['guideId']),
    );
    final controller = LightcoreController(
      guideProfile:
          savedGuide ?? fallbackGuideProfile ?? LightcoreGuideProfile.lumo,
      playerId: _stringOrNull(playerData['playerId']) ?? 'LUMI-LOCAL',
      screenName: _stringOrNull(playerData['screenName']),
      balanceTuning: balanceTuning,
    );
    controller._restoreFromCloudSavePayload(payload);
    return controller;
  }

  static const int slotCount = 6;
  static const int maxShellTier = 4;
  static const int maxTowerLevel = 5;
  static const int maxTowerUpgradeRank = maxTowerLevel - 1;
  static const int minTowerUpgradeOptions = 2;
  static const int maxTowerUpgradeOptions = 4;
  static const int enemyDeckLimit = 3;
  static const int bossSpawnKillRequirement = 100;
  static const int bossUnlockLevel = 5;
  static const int tournamentUnlockLevel = 20;
  static const int mentorshipUnlockLevel = 30;
  static const int dailyDungeonUnlockLevel = 15;
  static const int dailyDungeonStartingTowerLevel = 1;
  static const int dailyDungeonMaxTowerLevel = 60;
  static const int bossUnlockTicketGrant = 10;
  static const int enemyTicketCost = 1;
  static const int bossTicketCost = 1;
  static const int maxSummoningLevel = 20;
  static const int firstSummoningLevelPullGap = 250;
  static const int finalSummoningLevelPullGap = 20000;
  static const int minSummoningLevelTicketReward = 100;
  static const int maxSummoningLevelTicketReward = 1000;
  static const int bossPullsPerSummoningLevel = 40;
  static const int maxBossSummoningLevel = 12;
  static const int maxBossCardLevel = 20;
  static const int minScreenNameLength = 3;
  static const int maxScreenNameLength = 20;
  static const int towerManagerFluxCost = 40;
  static const int enemyManagerFluxCost = 52;
  static const int maxEquipmentInventorySize = 200;
  static const int traitRefreshLumenCost = 6;
  static const int maxActiveEnemies = 84;
  static const int evenEntryTournamentLevel = 1;
  static const int evenEntryTournamentCoreLevel = 1;
  static const int evenEntryTournamentPowerIndex = 1000;
  static const int minEnemyTarget = 6;
  static const int initialEnemyTarget = 6;
  static const int baseEnemyTargetMax = 20;
  static const int enemyTargetUpgradeStep = 1;
  static const int _legacyEnemyTargetUpgradeStep = 8;
  static const int maxEnemyTargetUpgradeLevel =
      (maxActiveEnemies - baseEnemyTargetMax) ~/ enemyTargetUpgradeStep;
  static const double _maxFlowEfficiency = 100;
  static const double _maxCoreStability = 100;
  static const double _minimumOutputEfficiency = 0.15;
  static const double _outputEfficiencyGamma = 1.10;
  static const double _baseCoreStabilityRecoveryPerSecond = 0.8;
  static const double _apexBaseStabilityDamageMultiplier = 2.5;
  static const double _apexRarityStabilityDamageStep = 0.82;
  static const double _minimumSpawnRadius = 860;
  static const double _defaultTowerLaneRangeShare = 2 / 3;
  static const double _spawnRadiusBandSpacing = 20;
  static const int _spawnRadiusBandCount = 4;
  static const double _spawnCrowdRadiusPerEnemy = 14;
  static const int _spawnClusterSize = 3;
  static const double _spawnClusterAngleStep = 0.052;
  static const double _spawnClusterAngleJitter = 0.012;
  static const double _spawnClusterRadiusJitter = 10;
  static const double _relayImpactRadius = 102;
  static const double _pulseSpeed = 1.8;
  static const double _shotSpeed = 3.8;
  static const double _impactSpeed = 2.8;
  static const double _coreBombSplashRadius = 64;
  static const double _chainArcImpactLingerSeconds = 0.5;
  static const double _blueFocusLaserDamageMultiplier = 0.38;
  static const double _towerDamageOutputMultiplier = 0.5;
  static const double _bossBaseHealthScale = 0.52;
  static const double _bossTierHealthScaleStep = 0.2;
  static const double _bossWorldPressurePerSpawn = 0.006;
  static const double _bossWorldPressurePerBuiltTower = 0.015;
  static const double _bossWorldPressureCap = 0.45;
  static const double _bossBaseDefenseScale = 0.62;
  static const double _bossTierDefenseScaleStep = 0.04;
  static const double _bossSpeedScale = 0.74;
  static const double _uiNotifyCadence = 0.12;
  static const double _coreBaseRange =
      _relayImpactRadius +
      ((_minimumSpawnRadius - _relayImpactRadius) *
          _defaultTowerLaneRangeShare);
  static const double _promotedChildTowerRangeMultiplier = 1.15;
  static const double _promotedCoreShotPowerMultiplier = 3.25;
  static const double _promotedCoreShotPowerTierStep = 0.55;
  static const double _promotedSourcePassiveMultiplier = 1 / slotCount;
  static const double _coreBaseCooldown = 0.62;
  static const double _coreBaseCritChance = 0.05;
  static const double _coreBaseCritMultiplier = 1.55;
  static const int maxCoreUpgradeLevel = 5;
  static const int maxCoreMultiShotUpgradeLevel = 3;
  static const int baseCoreQueueCapacity = 8;
  static const int coreQueueCapacityUpgradeStep = 2;
  static const int maxOfflineProgressSeconds = 4 * 60 * 60;
  static const int childTowerUpgradeOptionsPerLevel = 4;
  static const int childTowerUpgradeMaxRank = 10;
  static const int payloadUnlockLayer = 2;
  static const int managerUnlockLevel = 10;
  static const List<PrototypeAffinity> childCoreAffinityChoices =
      <PrototypeAffinity>[
        PrototypeAffinity.ember,
        PrototypeAffinity.flare,
        PrototypeAffinity.solar,
        PrototypeAffinity.verdant,
        PrototypeAffinity.aether,
        PrototypeAffinity.violet,
      ];
  static const double towerConstructionDurationSeconds = 5;
  static const int friendRelayLevelBand = 6;
  static const int defaultGuildCreationUnlockLevel = 10;
  static const int guildMemberCap = slotCount + 1;
  static const int helpSectionTicketReward = 5;
  static const String timeWarpFluxThirtyMinutesId = 'time_warp_flux_30m';
  static const String timeWarpPrismThirtyMinutesId = 'time_warp_prism_30m';
  static const String timeWarpPrismTwoHoursId = 'time_warp_prism_2h';
  static const String timeWarpPrismTwelveHoursId = 'time_warp_prism_12h';
  static const List<LightcoreTimeWarpOfferDefinition> timeWarpOffers =
      <LightcoreTimeWarpOfferDefinition>[
        LightcoreTimeWarpOfferDefinition(
          id: timeWarpFluxThirtyMinutesId,
          title: 'Flux Time Warp',
          subtitle: 'Jump the idle economy ahead by half an hour.',
          durationSeconds: 30 * 60,
          cost: 60,
          currency: LightcoreTimeWarpCurrency.flux,
          weeklyLimit: 3,
          badgeLabel: 'Flux Warp',
        ),
        LightcoreTimeWarpOfferDefinition(
          id: timeWarpPrismThirtyMinutesId,
          title: 'Prism Time Warp',
          subtitle: 'A short paid-currency skip with a strict weekly cap.',
          durationSeconds: 30 * 60,
          cost: 25,
          currency: LightcoreTimeWarpCurrency.prismShards,
          weeklyLimit: 4,
          badgeLabel: 'Warp',
        ),
        LightcoreTimeWarpOfferDefinition(
          id: timeWarpPrismTwoHoursId,
          title: 'Relay Time Warp',
          subtitle: 'Bank two hours of passive Lumens and simulated clears.',
          durationSeconds: 2 * 60 * 60,
          cost: 85,
          currency: LightcoreTimeWarpCurrency.prismShards,
          weeklyLimit: 2,
          badgeLabel: 'Warp',
        ),
        LightcoreTimeWarpOfferDefinition(
          id: timeWarpPrismTwelveHoursId,
          title: 'Deep Orbit Time Warp',
          subtitle: 'A large skip with no uncapped fallback.',
          durationSeconds: 12 * 60 * 60,
          cost: 420,
          currency: LightcoreTimeWarpCurrency.prismShards,
          weeklyLimit: 2,
          badgeLabel: 'Weekly',
        ),
      ];
  static const double _normalFluxDropChance = 0.035;
  static const double _fluxDropChancePerRarity = 0.012;
  static const double _bossFluxDropChance = 0.55;
  static const double _normalThreatScanDropChance = 0.012;
  static const double _threatScanDropChancePerRarity = 0.006;
  static const double _bossThreatScanDropChance = 0.42;
  static const List<String> _mockFriendNames = <String>[
    'Iona',
    'Rook',
    'Vale',
    'Mira',
    'Tess',
    'Orin',
    'Sable',
    'Kiro',
  ];
  static const List<String> _mockGuildReplies = <String>[
    'Copy. I can keep my lane synced for the next push.',
    'I can rotate my tower after this wave if we need a different affinity.',
    'Anchor is stable on my side. Keep filling the open hexes.',
    'I am saving burst for the next Apex cycle.',
    'I can cover range if someone else wants to pivot into payloads.',
  ];
  static String shellNameForTier(int tier) => switch (tier) {
    <= 1 => 'Root Shell',
    2 => 'Prism Shell',
    3 => 'Nexus Shell',
    _ => 'Ascendant Shell',
  };

  static String shellBadgeForTier(int tier) => switch (tier) {
    <= 1 => 'Root',
    2 => 'Prism',
    3 => 'Nexus',
    _ => 'Asc',
  };

  static final Set<PrototypeAffinity> _rainbowTowerAffinities = TowerLibrary.all
      .map((config) => config.affinity)
      .where(
        (affinity) =>
            affinity != PrototypeAffinity.neutral &&
            affinity != PrototypeAffinity.black,
      )
      .toSet();
  static const double _manualOverdriveTapBurst = 0.18;
  static const double _manualOverdriveChargePerSecond = 0.7;
  static const double _manualOverdriveDecayPerSecond = 0.45;
  static const double _baseBattleSpeedMultiplier = 0.75;
  static const double _manualOverdriveMaxMultiplier = 1.5;
  static const double _localhostAutoTapperCoreInterval = 0.22;
  static const double _maxLumenHarvestSlowdown = 0.24;
  static const double _relayHitLumenHarvestDamageScale = 12;
  static const double _emptyLaneLumenHarvestDamageScale = 18;
  static const int firstOuterSlotKillRequirement = 100;
  static const List<int> outerSlotUnlockExperienceThresholds = <int>[
    0,
    100,
    250,
    500,
    850,
    1250,
  ];
  static const double maxOfflineKillsPerHour = 600;
  static const double _overallLevelExperienceGrowth = 1.03;

  final LightcoreGuideProfile _guideProfile;
  late List<TowerLayerSnapshot> _layers;
  late List<OuterTowerState> _slots;
  late List<InventoryCard> _cards;
  late List<EnemyManagerState> _enemyManagers;
  late List<EnemyCardState> _enemyCards;
  late List<EnemyCardState> _bossEnemyCards;
  late List<PlayerEquipmentItem> _equipmentInventory;
  late List<EnemyState> _enemies;
  late List<EnergyPulseState> _pulses;
  late List<CoreShotState> _shots;
  late List<ImpactState> _impacts;
  late List<AmmoPacket> _ammoQueue;
  late List<String> _activeEnemyCardIds;
  final Map<int, String> _blueFocusTargetEnemyIdBySlot = <int, String>{};
  String? _activeBossEnemyCardId;
  List<PackPullResult> _lastEnemyPackPulls = <PackPullResult>[];
  List<PackPullResult> _lastBossPackPulls = <PackPullResult>[];
  final Random _packRandom;
  final Random _traitRandom;
  final Random _managerRandom;
  final Random _spawnRandom;
  final bool _guildsEnabled;
  final int _guildCreationUnlockLevel;
  LightcoreBalanceTuning _balanceTuning;
  final Set<String> _newEquipmentItemIds = <String>{};

  late CoreState _core;
  late Layer2TowerState _layer2;
  late String _activeLayerId;
  late String _viewLayerId;
  late String _runtimeLayerId;
  final Map<String, int> _coreDamageSequencesByLayer = <String, int>{};
  final Map<String, double> _coreDamageAmountsByLayer = <String, double>{};
  late Map<BattlePassType, List<BattlePassProgress>> _battlePasses;
  late Map<EquipmentLoadoutSlot, String?> _equippedPlayerItems;
  bool _outerRingRevealed = false;
  bool _swarmActivated = false;

  // TODO(authority): Move persistent player state behind a repository backed by
  // local cache plus backend sync. Client-owned mutable state keeps local play
  // responsive, but long-lived progression still needs authoritative claims.
  int lumens = 44;
  int flux = 96;
  int prismShards = 0;
  int enemyTickets = 18;
  int bossTickets = 0;
  int bossCores = 0;
  int enemyPullCount = 0;
  int bossPullCount = 0;
  int towerManagerPullCount = 0;
  int enemyManagerPullCount = 0;
  int kills = 0;
  int experience = 0;
  int echoSeeds = 0;
  final Map<LightcoreRadianceStat, int> _radianceStatRanks =
      <LightcoreRadianceStat, int>{
        for (final stat in LightcoreRadianceStat.values) stat: 0,
      };
  int totalHelpSectionsRead = 0;
  int? selectedSlotIndex;
  int? _towerRangePreviewSlotIndex;
  String? selectedEnemyCardId;
  double elapsed = 0;
  String bannerMessage = '';
  double _totalBattleSeconds = 0;
  int _totalOfflineSecondsClaimed = 0;
  int _totalUpgradesBought = 0;
  int _totalTowersBuilt = 0;
  int _totalManagersForged = 0;
  int _totalBossesDefeated = 0;
  int _totalLumensSpent = 0;
  int _totalFluxSpent = 0;
  int _totalPrismShardsSpent = 0;
  int _totalTimeWarpSecondsClaimed = 0;
  String? _serverDayKey;
  String? _serverWeekKey;
  String _timeWarpPurchaseWeekKey = '';
  final Map<String, int> _timeWarpWeeklyPurchases = <String, int>{};
  String _storeOfferPurchaseWeekKey = '';
  final Map<String, int> _storeOfferWeeklyPurchases = <String, int>{};
  int _dailyDungeonHighestUnlockedTowerLevel = dailyDungeonStartingTowerLevel;
  int _dailyDungeonHighestClearedTowerLevel = 0;
  String? _equippedProfileMedalId;
  final Set<String> _unlockedProfileMedalIds = <String>{};

  double _spawnTimer = 1.35;
  double _bannerTimer = 0;
  double _levelUpRadianceProgress = 1;
  double _notifyAccumulator = 0;
  double _lumenHarvestSlowdown = 0;
  double _enemyTicketBuffer = 0;
  double _eventOfflineLumenBuffer = 0;
  double _eventOfflineKillBuffer = 0;
  int _enemyTargetCount = initialEnemyTarget;
  int _enemyTargetUpgradeLevel = 0;
  int _spawnSequence = 0;
  int _enemyCounter = 0;
  int? _activeSpawnClusterIndex;
  double _activeSpawnClusterAngle = 0;
  double _activeSpawnClusterRadius = 0;
  int _pulseCounter = 0;
  int _shotCounter = 0;
  int _impactCounter = 0;
  int _levelUpRadianceSequence = 0;
  int _lastLevelUpRadianceLevel = 1;
  int _lastLevelUpRadianceDestroyedEnemies = 0;
  int _equipmentDropCounter = 0;
  bool _manualOverdriveHeld = false;
  double _manualOverdriveCharge = 0;
  bool _suppressRuntimeBanners = false;
  double _localhostAutoTapperCoreCooldown = 0;
  bool _hasPermanentOverdrive = false;
  bool _hasPremiumMembership = false;
  double _tournamentExperienceMultiplier = 1.0;
  DateTime? _tournamentExperienceBoostEndsAt;
  bool _notificationBannersEnabled = true;
  bool _tutorialPromptsEnabled = true;
  bool _localhostAutoTapperEnabled = false;
  bool _needsNotify = false;
  bool _notifyPostFrameScheduled = false;
  bool _disposed = false;
  bool _bossUnlockGrantClaimed = false;
  String _playerId;
  String? _screenName;
  final Set<String> _readHelpSections = <String>{};
  String? _sharedRelayCenterPieceId;
  late List<String?> _sharedRelayOuterPieceIds;
  GuildState? _activeGuild;
  LightcoreSocialOverview? _socialOverview;
  int _guildChatCounter = 0;
  LightcoreTutorialStep _tutorialStep = LightcoreTutorialStep.none;
  bool _tutorialEarlyQuestChainCompleted = false;
  bool _tutorialFirstBossDefeated = false;
  bool _tutorialFirstEquipmentOpened = false;
  bool _tutorialFirstManagersOpened = false;
  bool _tutorialFirstEnemyTargetSet = false;
  bool _tutorialEnemyCountAdjusted = false;
  bool _tutorialStabilityPanelOpened = false;
  bool _tutorialTowerMatrixOpened = false;
  bool _tutorialStoreOpened = false;
  bool _tutorialBattlePassRewardClaimed = false;
  bool _tutorialTowerManagerAssigned = false;
  bool _tutorialEnemyManagerAssigned = false;
  bool _tutorialFriendsOpened = false;
  bool _tutorialMenteesOpened = false;
  bool _tutorialMentorsOpened = false;
  bool _tutorialCoreShotTapLearned = false;
  bool _tutorialSecondShellShotTapLearned = false;
  bool _tutorialOverdriveLearned = false;
  bool _tutorialIntroBossPending = false;
  int _tutorialSafeScanDefeats = 0;
  int _tutorialAutoQueuedPulses = 0;
  String? _tutorialTrackedBossEnemyId;
  LightcoreTutorialPulseTarget? _tutorialPulseTarget;
  int _tutorialPulseSignal = 0;
  final Set<LightcoreTutorialStep> _rewardedTutorialSteps =
      <LightcoreTutorialStep>{};
  final Set<LightcoreTournamentModeId> _reviewedTournamentTutorialModes =
      <LightcoreTournamentModeId>{};

  static Map<String, dynamic> _coerceMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, dynamic item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }

  static List<dynamic> _coerceList(dynamic value) {
    return value is List ? value : const <dynamic>[];
  }

  static String _stringValue(dynamic value, {String fallback = ''}) {
    return _stringOrNull(value) ?? fallback;
  }

  static String? _stringOrNull(dynamic value) {
    if (value is! String) {
      return null;
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static bool _boolValue(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    return fallback;
  }

  static int _intValue(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  static int? _intOrNull(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static double _doubleValue(dynamic value, {double fallback = 0}) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }

  static double? _doubleOrNull(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  static T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null || name.isEmpty) {
      return null;
    }
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }

  static double _outputEfficiencyPercentForStability(double stability) {
    final normalized = (stability.clamp(0.0, _maxCoreStability) / 100).clamp(
      0.0,
      1.0,
    );
    return max(
          _minimumOutputEfficiency,
          pow(normalized, _outputEfficiencyGamma).toDouble(),
        ) *
        100;
  }

  static double _stabilityForLegacyOutputEfficiency(double flowEfficiency) {
    final normalized = (flowEfficiency / 100).clamp(
      _minimumOutputEfficiency,
      1.0,
    );
    return pow(normalized, 1 / _outputEfficiencyGamma).toDouble() * 100;
  }

  static int summoningLevelForPullCount(int pullCount) {
    final normalizedPullCount = max(0, pullCount);
    var level = 1;
    while (level < maxSummoningLevel &&
        normalizedPullCount >= summoningLevelPullTargetForLevel(level + 1)) {
      level += 1;
    }
    return level;
  }

  static int summoningLevelPullTargetForLevel(int level) {
    final normalizedLevel = min(maxSummoningLevel, max(1, level));
    var target = 0;
    for (
      var milestoneLevel = 2;
      milestoneLevel <= normalizedLevel;
      milestoneLevel += 1
    ) {
      target += summoningLevelPullGapForLevel(milestoneLevel);
    }
    return target;
  }

  static int summoningLevelPullGapForLevel(int level) {
    final normalizedLevel = min(maxSummoningLevel, max(2, level));
    final progress = (normalizedLevel - 2) / (maxSummoningLevel - 2);
    final gap =
        firstSummoningLevelPullGap +
        ((finalSummoningLevelPullGap - firstSummoningLevelPullGap) *
            progress *
            progress);
    return gap.round();
  }

  static int summoningLevelTicketRewardForLevel(int level) {
    final normalizedLevel = min(maxSummoningLevel, max(2, level));
    final progress = (normalizedLevel - 2) / (maxSummoningLevel - 2);
    final reward =
        minSummoningLevelTicketReward +
        ((maxSummoningLevelTicketReward - minSummoningLevelTicketReward) *
            progress);
    return reward.round();
  }

  static int bossSummoningLevelTicketRewardForLevel(int level) {
    final normalizedLevel = min(maxBossSummoningLevel, max(2, level));
    return 1 + ((normalizedLevel - 2) ~/ 3);
  }

  static String _normalizeOptionalScreenName(String? value) {
    if (value == null) {
      return '';
    }
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
        .trim();
  }

  static int _screenNameLength(String value) =>
      _normalizeOptionalScreenName(value).runes.length;

  static int _screenNameVisibleLength(String value) =>
      _normalizeOptionalScreenName(
        value,
      ).replaceAll(RegExp(r'\s+'), '').runes.length;

  static int unlockExperienceForOuterSlot(int slotIndex) {
    if (slotIndex < 0) {
      return 0;
    }
    if (slotIndex < outerSlotUnlockExperienceThresholds.length) {
      return outerSlotUnlockExperienceThresholds[slotIndex];
    }

    final lastIndex = outerSlotUnlockExperienceThresholds.length - 1;
    final lastThreshold = outerSlotUnlockExperienceThresholds[lastIndex];
    final lastGap =
        lastThreshold - outerSlotUnlockExperienceThresholds[lastIndex - 1];
    final extraSlots = slotIndex - lastIndex;
    return lastThreshold +
        (lastGap * extraSlots) +
        (firstOuterSlotKillRequirement * extraSlots * (extraSlots + 1) ~/ 2);
  }

  static int unlockKillsForOuterSlot(int slotIndex) =>
      unlockExperienceForOuterSlot(slotIndex);

  static int unlockedOuterSlotCountForExperience(int totalExperience) {
    var unlocked = 0;
    for (var index = 0; index < slotCount; index++) {
      if (totalExperience < unlockExperienceForOuterSlot(index)) {
        break;
      }
      unlocked += 1;
    }
    return unlocked;
  }

  static int unlockedOuterSlotCountForKills(int totalKills) =>
      unlockedOuterSlotCountForExperience(totalKills);

  static int _baseExperienceGapForOverallLevel(int level) {
    if (level <= 1) {
      return 0;
    }
    return 40 + (30 * (level - 2));
  }

  static int _experienceGapForOverallLevel(int level) {
    if (level <= 1) {
      return 0;
    }
    final compoundScale = pow(
      _overallLevelExperienceGrowth,
      max(0, level - 2),
    ).toDouble();
    return max(
      1,
      (_baseExperienceGapForOverallLevel(level) * compoundScale).round(),
    );
  }

  static int experienceForOverallLevel(int level) {
    var totalExperience = 0;
    for (var targetLevel = 2; targetLevel <= level; targetLevel++) {
      totalExperience += _experienceGapForOverallLevel(targetLevel);
    }
    return totalExperience;
  }

  static int killsForOverallLevel(int level) =>
      experienceForOverallLevel(level);

  static int overallLevelForExperience(int totalExperience) {
    var level = 1;
    var nextLevelExperience = _experienceGapForOverallLevel(level + 1);
    while (totalExperience >= nextLevelExperience) {
      level += 1;
      nextLevelExperience += _experienceGapForOverallLevel(level + 1);
    }
    return level;
  }

  static int overallLevelForKills(int totalKills) =>
      overallLevelForExperience(totalKills);

  void _dispatchUiNotification() {
    if (_disposed) {
      return;
    }
    _syncProfileMedalAchievements(showBanner: true);
    _syncTutorialStep(showBanner: false);

    SchedulerBinding scheduler;
    try {
      scheduler = SchedulerBinding.instance;
    } catch (_) {
      notifyListeners();
      return;
    }
    final phase = scheduler.schedulerPhase;
    final canNotifyImmediately =
        phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks;

    if (canNotifyImmediately) {
      notifyListeners();
      return;
    }

    if (_notifyPostFrameScheduled) {
      return;
    }

    _notifyPostFrameScheduled = true;
    scheduler.addPostFrameCallback((_) {
      _notifyPostFrameScheduled = false;
      if (_disposed) {
        return;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _MockGuildSuggestionSeed {
  const _MockGuildSuggestionSeed({
    required this.id,
    required this.name,
    required this.motto,
    required this.activityLabel,
    required this.recruitOffsets,
  });

  final String id;
  final String name;
  final String motto;
  final String activityLabel;
  final List<int> recruitOffsets;
}

const List<_MockGuildSuggestionSeed> _mockGuildSuggestionSeeds =
    <_MockGuildSuggestionSeed>[
      _MockGuildSuggestionSeed(
        id: 'aurora_circuit',
        name: 'Aurora Circuit',
        motto: 'Rotate lanes before the apex and keep the anchor clean.',
        activityLabel: 'Apex planners',
        recruitOffsets: <int>[0, 1, 3, 5],
      ),
      _MockGuildSuggestionSeed(
        id: 'ember_lattice',
        name: 'Ember Lattice',
        motto: 'Push fast clears, then rebuild the outer ring on demand.',
        activityLabel: 'Fast-cycle clears',
        recruitOffsets: <int>[1, 2, 4],
      ),
      _MockGuildSuggestionSeed(
        id: 'verdant_spindle',
        name: 'Verdant Spindle',
        motto: 'Fill every slot, then tune affinities for long idle uptime.',
        activityLabel: 'Long-run growers',
        recruitOffsets: <int>[0, 2, 6, 7, 4],
      ),
    ];
