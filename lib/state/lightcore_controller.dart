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
import '../data/threat_region_configs.dart';
import '../data/tower_configs.dart';
import '../models/lightcore_config.dart';
import '../models/lightcore_avatar.dart';
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
part 'lightcore_controller/threat_regions.dart';
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
  inspectFirstTowerStats,
  tapBattleCore,
  tapFirstTower,
  tapSecondShellTower,
  upgradeFirstTowerToLevel3,
  raiseThreat,
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

enum LightcoreGraphicsQuality {
  high,
  balanced,
  lowPower;

  String get storageValue => switch (this) {
    LightcoreGraphicsQuality.high => 'high',
    LightcoreGraphicsQuality.balanced => 'balanced',
    LightcoreGraphicsQuality.lowPower => 'low_power',
  };

  String get label => switch (this) {
    LightcoreGraphicsQuality.high => 'High',
    LightcoreGraphicsQuality.balanced => 'Balanced',
    LightcoreGraphicsQuality.lowPower => 'Low Power',
  };

  String get summary => switch (this) {
    LightcoreGraphicsQuality.high =>
      'Full battle glow, particles, shakes, and transitions.',
    LightcoreGraphicsQuality.balanced =>
      'Keeps the battle readable while trimming extra particles and bloom.',
    LightcoreGraphicsQuality.lowPower =>
      'Reduces particles, glow, shake, and burst density for weaker devices.',
  };

  static LightcoreGraphicsQuality? maybeFromStorageValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    for (final quality in LightcoreGraphicsQuality.values) {
      if (quality.storageValue == normalized || quality.name == normalized) {
        return quality;
      }
    }
    return null;
  }
}

enum LightcoreNotificationCategory { action, battle }

enum LightcoreBattleSpawnPolicy { automatic, manual }

class LightcoreDailyDungeonReward {
  const LightcoreDailyDungeonReward({
    required this.towerLevel,
    required this.lumens,
    required this.flux,
    required this.managerShards,
    required this.shellCores,
    required this.threatScans,
    required this.experience,
  });

  final int towerLevel;
  final int lumens;
  final int flux;
  final int managerShards;
  final int shellCores;
  final int threatScans;
  final int experience;

  bool get hasRewards =>
      lumens > 0 ||
      flux > 0 ||
      managerShards > 0 ||
      shellCores > 0 ||
      threatScans > 0 ||
      experience > 0;

  String get label {
    final parts = <String>[
      if (lumens > 0) LightcoreCurrencyLabels.rewardLumens(lumens),
      if (flux > 0) LightcoreCurrencyLabels.rewardFlux(flux),
      if (managerShards > 0)
        LightcoreCurrencyLabels.rewardManagerShards(managerShards),
      if (shellCores > 0) LightcoreCurrencyLabels.rewardShellCores(shellCores),
      if (threatScans > 0)
        LightcoreCurrencyLabels.rewardThreatScans(threatScans),
      if (experience > 0) '+$experience EXP',
    ];
    return parts.join(', ');
  }

  LightcoreDailyDungeonReward withoutExperience() {
    if (experience == 0) {
      return this;
    }
    return LightcoreDailyDungeonReward(
      towerLevel: towerLevel,
      lumens: lumens,
      flux: flux,
      managerShards: managerShards,
      shellCores: shellCores,
      threatScans: threatScans,
      experience: 0,
    );
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
    this.battleTitle,
    this.battleAffinity,
    this.battleProjectileType,
    this.battlePayloadType,
    this.battleDisplayLevel,
  });

  final int towerLevel;
  final TowerConfig config;
  final int displayLevel;
  final double maxHealth;
  final double shotDamage;
  final double chargeRate;
  final double cooldownSeconds;
  final String? battleTitle;
  final PrototypeAffinity? battleAffinity;
  final ProjectileType? battleProjectileType;
  final PayloadType? battlePayloadType;
  final int? battleDisplayLevel;

  PrototypeAffinity get affinity => battleAffinity ?? config.affinity;
  ProjectileType get projectileType =>
      battleProjectileType ?? config.defaultProjectileType;
  PayloadType get payloadType => battlePayloadType ?? config.defaultPayloadType;
  int get effectiveDisplayLevel => battleDisplayLevel ?? displayLevel;
  String get title => battleTitle ?? '${affinity.label} ${config.name}';
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
        'Grow the shell by keeping the core active. The core auto-charges shots that earn Lumens.',
    trigger: 'New account',
    primaryClickTarget: 'Core Map > tap central core',
    coachCopy:
        'Tap the center Lightcore to wake the first shell and reveal where towers will go.',
    completionCondition: 'Tap central core',
    reward: 'Safe White Threat Scan x1',
    failureHelpState:
        'Pulse the central core again and keep nonessential UI dimmed.',
    analyticsEvent: 'tutorial_wake_core',
  ),
  LightcoreTutorialStep.waitForFirstHex: LightcoreTutorialQuestDefinition(
    id: 'TUT-002',
    title: 'Hex 1 Ready',
    teachGoal:
        'The first lane opens as soon as the shell wakes, so the player can move directly into building.',
    trigger: 'Legacy save is still parked on the old first-lane wait step',
    primaryClickTarget: 'Battlefield > Hex 1',
    coachCopy: 'Hex 1 is ready. Tap the highlighted lane to build.',
    completionCondition: 'Hex 1 selected',
    reward: 'Small Lumen grant',
    failureHelpState: 'Tap the highlighted first hex.',
    analyticsEvent: 'tutorial_wait_first_hex',
  ),
  LightcoreTutorialStep.selectFirstHex: LightcoreTutorialQuestDefinition(
    id: 'TUT-003',
    title: 'Select Hex 1',
    teachGoal:
        'A hex is a lane. Selecting one opens the controls for building or tuning that lane.',
    trigger: 'First build lane is available',
    primaryClickTarget: 'Battlefield > first outer hex',
    coachCopy:
        'Tap the highlighted first hex. The lower-left prism control opens the build and stats pop-out.',
    completionCondition: 'Hex 1 selected',
    reward: 'Build controls revealed',
    failureHelpState:
        'If the shell is folded, tap the center core or the battlefield to open it.',
    analyticsEvent: 'tutorial_select_first_hex',
  ),
  LightcoreTutorialStep.buildFirstRedTower: LightcoreTutorialQuestDefinition(
    id: 'TUT-004',
    title: 'Choose First Light',
    teachGoal:
        'The first tower sets your opening projectile style. Comet Mortar gives slow area hits; Rayline Spire gives steady beam pressure.',
    trigger: 'First hex selected',
    primaryClickTarget:
        'Hex 1 controls > Comet Mortar or Rayline Spire > Fabricate',
    coachCopy:
        'Choose Comet Mortar or Rayline Spire in Hex 1 so the shell has its first reliable attack style.',
    completionCondition: 'Start or finish first Fabrication',
    reward: 'Instant first tower',
    failureHelpState:
        'Open the first hex controls, then choose one of the highlighted starter build buttons.',
    analyticsEvent: 'tutorial_fabricate_first_light',
  ),
  LightcoreTutorialStep
      .inspectFirstTowerStats: LightcoreTutorialQuestDefinition(
    id: 'TUT-005',
    title: 'Open Tower Controls',
    teachGoal:
        'Tower controls keep upgrades, stats, and targeting separate from enemy focus clicks.',
    trigger: 'First focus-fire action complete',
    primaryClickTarget: 'Lower-left prism control > Tower Stats pop-out',
    coachCopy:
        'Open the first tower controls. This is where upgrades live; enemy taps stay for focus fire.',
    completionCondition: 'Open the first tower controls',
    reward: 'Upgrade controls unlocked',
    failureHelpState:
        'Tap the lower-left prism control if the stats panel is hidden.',
    analyticsEvent: 'tutorial_read_tower_stats',
  ),
  LightcoreTutorialStep.tapBattleCore: LightcoreTutorialQuestDefinition(
    id: 'TUT-006',
    title: 'Auto-Charge Ready',
    teachGoal:
        'Shots charge automatically after the core wakes. The player learns this through the focus-fire action instead of waiting.',
    trigger: 'Legacy save is still parked on the old auto-charge watch step',
    primaryClickTarget: 'Battlefield > anomaly target',
    coachCopy: 'Shots are charging. Tap an anomaly to focus the next shot.',
    completionCondition: 'Focus one anomaly',
    reward: 'Small Lumen grant',
    failureHelpState:
        'Tap a visible anomaly. The next shot will fire when ready.',
    analyticsEvent: 'tutorial_core_auto_generate',
  ),
  LightcoreTutorialStep.tapFirstTower: LightcoreTutorialQuestDefinition(
    id: 'TUT-007',
    title: 'Focus Fire',
    teachGoal:
        'Enemy clicks set the tactical target. Tower clicks stay reserved for tower controls, upgrades, stats, and targeting tools.',
    trigger: 'First tower exists',
    primaryClickTarget: 'Battlefield > anomaly target',
    coachCopy:
        'Tap the highlighted anomaly to focus fire. If the core is still charging, the shot fires as soon as it is ready.',
    completionCondition: 'Focus and fire one shot at an anomaly',
    reward: 'Lumens and White Drift practice scan',
    failureHelpState:
        'Tap the highlighted anomaly, not a tower. Towers open tower controls; enemies set focus fire.',
    analyticsEvent: 'tutorial_manual_aim_fire',
  ),
  LightcoreTutorialStep.tapSecondShellTower: LightcoreTutorialQuestDefinition(
    id: 'TUT-008',
    title: 'Fire Child Tower',
    teachGoal:
        'Child-shell towers keep the same tap-to-control rule: tower taps are for tower controls while firing stays automatic.',
    trigger: 'First child shell has a charged tower',
    primaryClickTarget: 'Battlefield > charged child-shell tower',
    coachCopy:
        'Tap the highlighted child-shell tower to inspect its controls. Firing stays automatic.',
    completionCondition: 'Inspect one charged child-shell tower',
    reward: 'Small Lumen grant',
    failureHelpState:
        'Wait for the highlighted child-shell tower to charge, then tap the tower body to open controls.',
    analyticsEvent: 'tutorial_second_shell_tower_fire',
  ),
  LightcoreTutorialStep
      .upgradeFirstTowerToLevel3: LightcoreTutorialQuestDefinition(
    id: 'TUT-009',
    title: 'Tune the Main Tower',
    teachGoal:
        'One strong anchor lane keeps Output Efficiency stable before the shell spreads into more pressure.',
    trigger: 'First tower can be upgraded',
    primaryClickTarget: 'Tower Stats pop-out > Upgrade',
    coachCopy:
        'Upgrade the first tower once before expanding. A stronger anchor makes every auto-shot matter more.',
    completionCondition: 'First tower reaches level 2',
    reward: 'Small Lumen grant',
    failureHelpState:
        'Open Hex 1 controls and use the highlighted Upgrade button when Lumens are available.',
    analyticsEvent: 'tutorial_upgrade_first_tower_l3',
  ),
  LightcoreTutorialStep.raiseThreat: LightcoreTutorialQuestDefinition(
    id: 'TUT-010A',
    title: 'Raise Threat',
    teachGoal:
        'When the first tower is overmatching the starter field, push the next stabilization level instead of idling on weak anomalies.',
    trigger: 'First upgraded tower is clearing safely',
    primaryClickTarget: 'Battlefield > Threat too low prompt > Challenge Lv 1',
    coachCopy:
        'The current anomaly field is too weak for the upgraded tower. Start Challenge Lv 1 to raise pressure and rewards.',
    completionCondition: 'Starter-region challenge started',
    reward: 'Threat Scan x1',
    failureHelpState:
        'Use the compact Challenge Lv 1 prompt on the battle screen.',
    analyticsEvent: 'tutorial_raise_threat',
  ),
  LightcoreTutorialStep.pullFirstWhiteEnemy: LightcoreTutorialQuestDefinition(
    id: 'TUT-010',
    title: 'Open Knowledge Cards',
    teachGoal:
        'Threat Scans resolve Knowledge Cards that make enemy families easier to fight.',
    trigger: 'Opening combat lesson done',
    primaryClickTarget: 'Anomalies > Research',
    coachCopy:
        'Resolve one Threat Scan into a Knowledge Card. Map regions open through the linear stabilization route.',
    completionCondition: 'Resolve 1 Knowledge Card scan',
    reward: 'Knowledge Card primer',
    failureHelpState: 'Open Anomalies and resolve one Knowledge Card scan.',
    analyticsEvent: 'tutorial_safe_threat_scan',
  ),
  LightcoreTutorialStep.readEffectiveGain: LightcoreTutorialQuestDefinition(
    id: 'TUT-011',
    title: 'Read Flow and Gain',
    teachGoal:
        'Output Efficiency is the real farming limiter. Bigger threats only help when your shell stays stable enough to cash them in.',
    trigger: 'After first research scan',
    primaryClickTarget: 'Left stat stack > Output Efficiency %',
    coachCopy:
        'Open Output Efficiency to see the income formula: Base Gain x Threat Reward x Output Efficiency.',
    completionCondition: 'Open stability panel',
    reward: 'Small Lumen boost',
    failureHelpState:
        'Pulse the Output Efficiency stat and show the formula again.',
    analyticsEvent: 'tutorial_read_effective_gain',
  ),
  LightcoreTutorialStep.autoQueueCheck: LightcoreTutorialQuestDefinition(
    id: 'TUT-012',
    title: 'Manager Auto-Aim',
    teachGoal:
        'Core Managers convert auto-charged shots into hands-off firing when the player wants automation.',
    trigger: 'Manager assigned',
    primaryClickTarget: 'Battlefield > manager firing lane',
    coachCopy:
        'Watch the assigned manager fire charged shots automatically. You can still tap enemies to override focus.',
    completionCondition: 'Let the manager fire 5 charged shots',
    reward: 'Lumens and Threat Scan x1',
    failureHelpState:
        'Keep the managed shell in view and watch automation fire for you.',
    analyticsEvent: 'tutorial_auto_queue_check',
  ),
  LightcoreTutorialStep
      .upgradeFirstTowerToLevel4: LightcoreTutorialQuestDefinition(
    id: 'TUT-013',
    title: 'Reinforce the Anchor',
    teachGoal:
        'A stronger anchor lane gives you room to test harder regions without crushing Output Efficiency.',
    trigger: 'Early red research lesson',
    primaryClickTarget: 'Tower Stats pop-out > Upgrade',
    coachCopy:
        'Upgrade the first tower again before spreading Lumens across more towers.',
    completionCondition: 'First tower reaches level 3',
    reward: 'Small Lumen grant',
    failureHelpState:
        'Open Hex 1 stats and use Upgrade when the Lumen cost is affordable.',
    analyticsEvent: 'tutorial_upgrade_first_tower_l4',
  ),
  LightcoreTutorialStep.pullFirstRedEnemy: LightcoreTutorialQuestDefinition(
    id: 'TUT-014',
    title: 'Challenge Region Pressure',
    teachGoal:
        'Regions define the anomaly combination. Harder rings bring rarer mixes and boss pressure.',
    trigger: 'After safe research lesson',
    primaryClickTarget: 'Bottom nav > Map > Challenge',
    coachCopy:
        'Challenge the next starter-region stabilization layer. Failing returns you to the previous stabilized level.',
    completionCondition: 'Start the next stabilization challenge',
    reward: 'Threat Scan x1',
    failureHelpState: 'Open Map and start the highlighted Challenge.',
    analyticsEvent: 'tutorial_red_counter_scan',
  ),
  LightcoreTutorialStep.setFirstEnemyTarget: LightcoreTutorialQuestDefinition(
    id: 'TUT-015',
    title: 'Review Red Pressure',
    teachGoal:
        'Basic Red confirms that same-color resistance is live before you tune swarm pressure.',
    trigger: 'Red signature is available',
    primaryClickTarget: 'Anomalies > Basic Red card',
    coachCopy:
        'Open Anomalies and review Basic Red in the active deck. No separate action is needed; the red signature is already live.',
    completionCondition: 'Basic Red available',
    reward: 'Small Lumen grant',
    failureHelpState: 'Use the highlighted Basic Red card in Anomalies.',
    analyticsEvent: 'tutorial_review_first_red_enemy',
  ),
  LightcoreTutorialStep.adjustEnemyCount: LightcoreTutorialQuestDefinition(
    id: 'TUT-016',
    title: 'Read the Route',
    teachGoal:
        'The Threat Map is a fixed route. Fully stabilizing a region opens the next step on the path.',
    trigger: 'Red signature is available',
    primaryClickTarget: 'Bottom nav > Map',
    coachCopy:
        'Review the Threat Map and find the next locked step on the route.',
    completionCondition: 'Route reviewed',
    reward: 'Small Lumen grant',
    failureHelpState: 'Open Map and inspect a region.',
    analyticsEvent: 'tutorial_adjust_enemy_count',
  ),
  LightcoreTutorialStep.openTowerMatrix: LightcoreTutorialQuestDefinition(
    id: 'TUT-017',
    title: 'Open the Tower Archive',
    teachGoal:
        'The Towers page unlocks at Layer 2 for completed-shell archives and shell planning.',
    trigger: 'Prism Shell online',
    primaryClickTarget: 'Bottom nav > Towers',
    coachCopy:
        'Open Towers to inspect saved completed Layer 1 sets and Layer 2 shell tools.',
    completionCondition: 'Tower Archive opened',
    reward: 'Threat Scan x1',
    failureHelpState: 'Use the highlighted Towers button in the bottom nav.',
    analyticsEvent: 'tutorial_open_tower_matrix',
  ),
  LightcoreTutorialStep.upgradeCoreRange: LightcoreTutorialQuestDefinition(
    id: 'TUT-018',
    title: 'Upgrade a Global Stat',
    teachGoal: 'Account levels unlock permanent Global Attribute upgrades.',
    trigger: 'Player level 2',
    primaryClickTarget:
        'Profile/Level badge > Profile > Global Attributes > Add Point',
    coachCopy:
        'Leveling unlocks global stats and modes. Pick a permanent stat upgrade.',
    completionCondition: 'Add one Global Attribute point',
    reward: 'Unlock Level Goals panel',
    failureHelpState:
        'Open Profile and use Add Point on any highlighted Global Attribute.',
    analyticsEvent: 'tutorial_upgrade_global_stat',
  ),
  LightcoreTutorialStep.openStore: LightcoreTutorialQuestDefinition(
    id: 'TUT-019',
    title: 'Inspect the Store',
    teachGoal: 'The Store groups conversions, premium unlocks, and offers.',
    trigger: 'Early tutorial complete',
    primaryClickTarget: 'Top HUD > Storefront',
    coachCopy:
        'Open the Store and inspect the resource offers. Opening it never spends anything.',
    completionCondition: 'Store opened',
    reward: 'Flux and Threat Scan',
    failureHelpState: 'Tap the highlighted Storefront icon in the top HUD.',
    analyticsEvent: 'tutorial_open_store',
  ),
  LightcoreTutorialStep.claimBattlePassReward: LightcoreTutorialQuestDefinition(
    id: 'TUT-020',
    title: 'Claim a Pass Reward',
    teachGoal: 'Passes convert normal play into side rewards.',
    trigger: 'A pass reward is claimable',
    primaryClickTarget: 'Top HUD > Passes > claim',
    coachCopy:
        'Open Passes and claim the waiting reward. Pass rewards are bonus progress from normal play.',
    completionCondition: 'Claim one pass reward',
    reward: 'Flux',
    failureHelpState:
        'Tap the highlighted Passes icon, then claim any lit reward.',
    analyticsEvent: 'tutorial_claim_battle_pass',
  ),
  LightcoreTutorialStep.openBossPulls: LightcoreTutorialQuestDefinition(
    id: 'TUT-021',
    title: 'Stabilize the First Region',
    teachGoal:
        'The full hex map unlocks after the starter region is fully stabilized and its boss is defeated.',
    trigger: 'Prism Shell created',
    primaryClickTarget: 'Bottom nav > Map > Challenge',
    coachCopy:
        'Open Map and challenge the starter region until the final boss layer is cleared.',
    completionCondition: 'Starter region fully stabilized',
    reward: 'Full Threat Map',
    failureHelpState: 'Open Map and start the next stabilization challenge.',
    analyticsEvent: 'tutorial_open_boss_pulls',
  ),
  LightcoreTutorialStep.armFirstBoss: LightcoreTutorialQuestDefinition(
    id: 'TUT-022',
    title: 'Build an Apex Suite',
    teachGoal:
        'Knowledge Books use 1 Apex Core, 2 boss traits, and 3 Knowledge Cards.',
    trigger: 'First Apex card owned',
    primaryClickTarget: 'Bottom nav > Anomalies > Knowledge Build',
    coachCopy:
        'Use boss drops from stabilized regions to assemble your first enemy suite.',
    completionCondition:
        'Enemy suite has 1 Apex Core, 2 traits, and 3 anomalies',
    reward: 'Suite primer',
    failureHelpState:
        'Open Anomalies and review boss-core, trait, and anomaly-card slots.',
    analyticsEvent: 'tutorial_arm_first_boss',
  ),
  LightcoreTutorialStep.defeatFirstBoss: LightcoreTutorialQuestDefinition(
    id: 'TUT-023',
    title: 'Defeat White Warden',
    teachGoal:
        'Apex fights are milestone pressure checks for the active shell.',
    trigger: 'First Apex is armed and spawned',
    primaryClickTarget: 'Battlefield > White Warden',
    coachCopy:
        'Return to battle and defeat White Warden. This first Apex is weakened so you can learn the loop.',
    completionCondition: 'White Warden defeated',
    reward: 'Apex progression unlock',
    failureHelpState:
        'Use the highlighted back button, then keep focusing visible threats.',
    analyticsEvent: 'tutorial_defeat_first_boss',
  ),
  LightcoreTutorialStep.openEquipment: LightcoreTutorialQuestDefinition(
    id: 'TUT-024',
    title: 'Check Profile',
    teachGoal: 'The profile panel holds account attributes and guide identity.',
    trigger: 'First Apex defeated',
    primaryClickTarget: 'Top-left profile HUD > Profile',
    coachCopy:
        'Open the profile panel and check account attributes before continuing.',
    completionCondition: 'Profile panel opened after first Apex',
    reward: 'Flux',
    failureHelpState: 'Tap the highlighted profile HUD in the upper left.',
    analyticsEvent: 'tutorial_open_equipment',
  ),
  LightcoreTutorialStep.openManagers: LightcoreTutorialQuestDefinition(
    id: 'TUT-025',
    title: 'Inspect the Foundry',
    teachGoal: 'Managers are Flux-forged automation and threat modifiers.',
    trigger: 'Managers unlocked',
    primaryClickTarget: 'Bottom nav > Managers',
    coachCopy:
        'Open Managers. Core Managers add auto-fire, while Threat Directors tune live spawns, enemy strength, and rewards.',
    completionCondition: 'Managers screen opened',
    reward: 'Flux',
    failureHelpState: 'Use the highlighted Managers button in the bottom nav.',
    analyticsEvent: 'tutorial_open_managers',
  ),
  LightcoreTutorialStep.forgeTowerManager: LightcoreTutorialQuestDefinition(
    id: 'TUT-026',
    title: 'Forge a Core Manager',
    teachGoal: 'Core Managers automate charged shots across the active shell.',
    trigger: 'Manager foundry opened with enough Flux',
    primaryClickTarget: 'Managers > Core Manager foundry > Forge',
    coachCopy:
        'Forge one Core Manager. A manager keeps charged shots firing through automation.',
    completionCondition: 'Own one Core Manager',
    reward: 'Flux',
    failureHelpState: 'Use the highlighted Core Manager forge control.',
    analyticsEvent: 'tutorial_forge_tower_manager',
  ),
  LightcoreTutorialStep.assignTowerManager: LightcoreTutorialQuestDefinition(
    id: 'TUT-027',
    title: 'Assign a Core Manager',
    teachGoal:
        'A Core Manager assigns to the shell and turns charged shots into steady auto-fire.',
    trigger: 'After Output Efficiency shown',
    primaryClickTarget: 'Managers > Core Manager > Assign to Shell',
    coachCopy:
        'Assign the Core Manager to the shell. Managers fire charged shots automatically and add tower-wide bonuses.',
    completionCondition: 'Assign manager to core',
    reward: 'Starter manager',
    failureHelpState:
        'Highlight the starter manager and shell assignment control.',
    analyticsEvent: 'tutorial_assign_core_manager',
  ),
  LightcoreTutorialStep.forgeEnemyManager: LightcoreTutorialQuestDefinition(
    id: 'TUT-028',
    title: 'Forge a Threat Director',
    teachGoal:
        'Threat Directors change current spawn pressure, enemy strength, and reward bonuses.',
    trigger: 'Core Manager assigned with enough Flux',
    primaryClickTarget: 'Managers > Threat Director foundry > Forge',
    coachCopy:
        'Forge one Threat Director. Directors are how you tune enemy pressure and rewards instead of only reacting to them.',
    completionCondition: 'Own one Threat Director',
    reward: 'Flux',
    failureHelpState: 'Use the highlighted Threat Director forge control.',
    analyticsEvent: 'tutorial_forge_enemy_manager',
  ),
  LightcoreTutorialStep.assignEnemyManager: LightcoreTutorialQuestDefinition(
    id: 'TUT-029',
    title: 'Assign a Threat Director',
    teachGoal:
        'An assigned Threat Director tunes the selected region immediately, then stabilization validates its offline output.',
    trigger: 'Threat Director owned',
    primaryClickTarget:
        'Managers > Threat Director > Assign to Selected Region',
    coachCopy:
        'Assign the Threat Director to the selected Threat Map region, then restabilize that region for offline output.',
    completionCondition: 'Assign director to region',
    reward: 'Threat Scans',
    failureHelpState:
        'Highlight the director tile and selected-region assignment control.',
    analyticsEvent: 'tutorial_assign_enemy_manager',
  ),
  LightcoreTutorialStep.holdOverdrive: LightcoreTutorialQuestDefinition(
    id: 'TUT-030',
    title: 'Hold Overdrive',
    teachGoal:
        'Manual Overdrive speeds up live battle time while you are active.',
    trigger: 'First child-shell shot lesson complete',
    primaryClickTarget: 'Battle HUD > Overdrive button',
    coachCopy:
        'Hold Overdrive until the battle speeds up. Use it when you are actively pushing lanes.',
    completionCondition: 'Overdrive multiplier rises',
    reward: 'Flux',
    failureHelpState:
        'Hold the highlighted Overdrive button instead of tapping it once.',
    analyticsEvent: 'tutorial_hold_overdrive',
  ),
  LightcoreTutorialStep.setScreenName: LightcoreTutorialQuestDefinition(
    id: 'TUT-031',
    title: 'Claim Your Screen Name',
    teachGoal: 'Public modes need a visible pilot name for leaderboards.',
    trigger: 'Tournaments unlocked',
    primaryClickTarget: 'Menu > Settings > Change Name',
    coachCopy:
        'Open Menu, choose Settings, then Change Name, and set your screen name.',
    completionCondition: 'Screen name saved',
    reward: 'Flux',
    failureHelpState:
        'Use the highlighted Menu button, then the highlighted Change Name control.',
    analyticsEvent: 'tutorial_set_screen_name',
  ),
  LightcoreTutorialStep.openFriends: LightcoreTutorialQuestDefinition(
    id: 'TUT-032',
    title: 'Inspect Friends',
    teachGoal:
        'Friends are where requests and daily Threat Scan gifts are managed.',
    trigger: 'Screen name set',
    primaryClickTarget: 'Menu > Friends',
    coachCopy:
        'Open Menu, select Friends, and inspect requests plus daily Threat Scan gifts.',
    completionCondition: 'Friends opened',
    reward: 'Threat Scan',
    failureHelpState: 'Use the highlighted Menu button, then Friends.',
    analyticsEvent: 'tutorial_open_friends',
  ),
  LightcoreTutorialStep.openMentees: LightcoreTutorialQuestDefinition(
    id: 'TUT-033',
    title: 'Inspect Mentorship',
    teachGoal: 'Mentorship shows your mentor and every mentee connection.',
    trigger: 'Mentorship unlocked',
    primaryClickTarget: 'Menu > Mentorship',
    coachCopy:
        'Open Menu, select Mentorship, and inspect your mentor plus mentee network.',
    completionCondition: 'Mentorship opened',
    reward: 'Threat Scan',
    failureHelpState: 'Use the highlighted Menu button, then Mentorship.',
    analyticsEvent: 'tutorial_open_mentees',
  ),
  LightcoreTutorialStep.openMentors: LightcoreTutorialQuestDefinition(
    id: 'TUT-034',
    title: 'Inspect Mentors',
    teachGoal:
        'Mentor links share progression support through the social board.',
    trigger: 'Mentorship network is available',
    primaryClickTarget: 'Menu > Mentorship',
    coachCopy: 'Open Menu, select Mentorship, and inspect mentor connections.',
    completionCondition: 'Mentorship mentor panel opened',
    reward: 'Threat Scan',
    failureHelpState: 'Use the highlighted Menu button, then Mentorship.',
    analyticsEvent: 'tutorial_open_mentors',
  ),
  LightcoreTutorialStep.inspectEnemyBlitz: LightcoreTutorialQuestDefinition(
    id: 'TUT-035',
    title: 'Inspect Anomaly Blitz',
    teachGoal:
        'Anomaly Blitz is a testing survival economy tournament with weekend-length sessions.',
    trigger: 'Tournaments unlocked and social primer complete',
    primaryClickTarget: 'Menu > Tournaments > Anomaly Blitz',
    coachCopy: 'Open Menu, select Tournaments, and inspect Anomaly Blitz.',
    completionCondition: 'Anomaly Blitz reviewed',
    reward: 'Flux',
    failureHelpState: 'Use the highlighted tournament card.',
    analyticsEvent: 'tutorial_inspect_enemy_blitz',
  ),
  LightcoreTutorialStep.inspectHexGauntlet: LightcoreTutorialQuestDefinition(
    id: 'TUT-036',
    title: 'Inspect Hex Gauntlet',
    teachGoal: 'Hex Gauntlet tests how far your real shell layout can climb.',
    trigger: 'Anomaly Blitz reviewed',
    primaryClickTarget: 'Menu > Tournaments > Hex Gauntlet',
    coachCopy:
        'Inspect Hex Gauntlet. It mirrors your live tower build and pushes that exact layout.',
    completionCondition: 'Hex Gauntlet reviewed',
    reward: 'Flux',
    failureHelpState: 'Use the highlighted Hex Gauntlet card.',
    analyticsEvent: 'tutorial_inspect_hex_gauntlet',
  ),
  LightcoreTutorialStep.inspectArenaFlow: LightcoreTutorialQuestDefinition(
    id: 'TUT-037',
    title: 'Inspect Arena Flow',
    teachGoal:
        'Arena Flow is a short duel where Home Towers trade enemy waves and net damage decides score.',
    trigger: 'Hex Gauntlet reviewed',
    primaryClickTarget: 'Menu > Tournaments > Arena Flow',
    coachCopy:
        'Inspect Arena Flow. It is the quick duel format built around Home Tower net damage.',
    completionCondition: 'Arena Flow reviewed',
    reward: 'Flux',
    failureHelpState: 'Use the highlighted Arena Flow card.',
    analyticsEvent: 'tutorial_inspect_arena_flow',
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
const int maxCoreLevel = LightcoreController.maxCoreLevel;
const int minTowerUpgradeOptions = LightcoreController.minTowerUpgradeOptions;
const int maxTowerUpgradeOptions = LightcoreController.maxTowerUpgradeOptions;
const int enemyDeckLimit = LightcoreController.enemyDeckLimit;
const int bossSpawnKillRequirement =
    LightcoreController.bossSpawnKillRequirement;
const int bossUnlockLayer = LightcoreController.bossUnlockLayer;
const int bossUnlockLevel = LightcoreController.bossUnlockLevel;
const int tournamentUnlockLevel = LightcoreController.tournamentUnlockLevel;
const int mentorshipUnlockLevel = LightcoreController.mentorshipUnlockLevel;
const int dailyDungeonUnlockLevel = LightcoreController.dailyDungeonUnlockLevel;
const int dailyDungeonStartingTowerLevel =
    LightcoreController.dailyDungeonStartingTowerLevel;
const int dailyDungeonMaxTowerLevel =
    LightcoreController.dailyDungeonMaxTowerLevel;
const int dailyDungeonQuickClearsPerDay =
    LightcoreController.dailyDungeonQuickClearsPerDay;
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
const int maxPromotedChildTowerRerolls =
    LightcoreController.maxPromotedChildTowerRerolls;
const int minScreenNameLength = LightcoreController.minScreenNameLength;
const int maxScreenNameLength = LightcoreController.maxScreenNameLength;
const int towerManagerFluxCost = LightcoreController.towerManagerFluxCost;
const int enemyManagerFluxCost = LightcoreController.enemyManagerFluxCost;
const int maxManagerPowerLevel = LightcoreController.maxManagerPowerLevel;
const int managerPowerBaseUpgradeCost =
    LightcoreController.managerPowerBaseUpgradeCost;
const int managerBulkForgeFiveBonusShards =
    LightcoreController.managerBulkForgeFiveBonusShards;
const int managerBulkForgeTenBonusShards =
    LightcoreController.managerBulkForgeTenBonusShards;
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
const int tournamentPowerIndexCap = LightcoreController.tournamentPowerIndexCap;
const int minEnemyTarget = LightcoreController.minEnemyTarget;
const int initialEnemyTarget = LightcoreController.initialEnemyTarget;
const int farmValidationWaveCount = LightcoreController.farmValidationWaveCount;
const int swarmMagnetRerollCost = LightcoreController.swarmMagnetRerollCost;
const double focusTargetDurationSeconds =
    LightcoreController.focusTargetDurationSeconds;
const double focusTargetCooldownSeconds =
    LightcoreController.focusTargetCooldownSeconds;
const double _farmValidationBaseWaveSeconds =
    LightcoreController._farmValidationBaseWaveSeconds;
const int _layer3TrialEnemyCap = 18;
const double _layer3TrialSpawnCadence = 0.22;
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
const int _coreEnergyUnlockLayer = LightcoreController._coreEnergyUnlockLayer;
const int _maxCoreEnergyUpgradeLevel =
    LightcoreController._maxCoreEnergyUpgradeLevel;
const double _baseCoreEnergyCapacity =
    LightcoreController._baseCoreEnergyCapacity;
const double _coreEnergyCapacityUpgradeStep =
    LightcoreController._coreEnergyCapacityUpgradeStep;
const double _baseCoreEnergyRecoveryPerSecond =
    LightcoreController._baseCoreEnergyRecoveryPerSecond;
const double _coreEnergyRecoveryUpgradeStep =
    LightcoreController._coreEnergyRecoveryUpgradeStep;
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
const int _openingRangeProximitySpawnCount =
    LightcoreController._openingRangeProximitySpawnCount;
const double _openingRangeProximityBuffer =
    LightcoreController._openingRangeProximityBuffer;
const int _spawnClusterSize = LightcoreController._spawnClusterSize;
const double _spawnClusterAngleStep =
    LightcoreController._spawnClusterAngleStep;
const double _spawnClusterAngleJitter =
    LightcoreController._spawnClusterAngleJitter;
const double _spawnClusterRadiusJitter =
    LightcoreController._spawnClusterRadiusJitter;
const double _relayImpactRadius = LightcoreController._relayImpactRadius;
const double _pulseSpeed = LightcoreController._pulseSpeed;
const int _maxFloatingPayloadsPerSource =
    LightcoreController._maxFloatingPayloadsPerSource;
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
const double rainbowPromotionChance =
    LightcoreController.rainbowPromotionChance;
const int managerUnlockLevel = LightcoreController.managerUnlockLevel;
const List<PrototypeAffinity> childCoreAffinityChoices =
    LightcoreController.childCoreAffinityChoices;
const double towerConstructionDurationSeconds =
    LightcoreController.towerConstructionDurationSeconds;
const double layer1ChildTowerMaxConstructionDurationSeconds =
    LightcoreController.layer1ChildTowerMaxConstructionDurationSeconds;
const List<double> layer1TowerConstructionDurationsSeconds =
    LightcoreController.layer1TowerConstructionDurationsSeconds;
const List<double> layer1TowerBuildCostMultipliers =
    LightcoreController.layer1TowerBuildCostMultipliers;
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
    this.relayHitListener,
    LightcoreGuideProfile? guideProfile,
    String playerId = 'LUMI-LOCAL',
    String? screenName,
    bool guildsEnabled = false,
    int guildCreationUnlockLevel = defaultGuildCreationUnlockLevel,
    LightcoreBalanceTuning balanceTuning = LightcoreBalanceTuning.defaults,
    LightcoreGraphicsQuality graphicsQuality = LightcoreGraphicsQuality.high,
  }) : _packRandom = packRandom ?? Random(),
       _traitRandom = traitRandom ?? Random(),
       _managerRandom = managerRandom ?? Random(),
       _spawnRandom = spawnRandom ?? Random(),
       _guideProfile = guideProfile ?? LightcoreGuideProfile.lumo,
       _playerId = playerId,
       _screenName = _normalizeOptionalScreenName(screenName),
       _guildsEnabled = guildsEnabled,
       _guildCreationUnlockLevel = max(1, guildCreationUnlockLevel),
       _balanceTuning = balanceTuning,
       _graphicsQuality = graphicsQuality {
    _cards = <InventoryCard>[];
    _enemyManagers = <EnemyManagerState>[];
    _completedTowerShells = <CompletedTowerShellState>[];
    _equipmentInventory = <PlayerEquipmentItem>[];
    _equippedPlayerItems = <EquipmentLoadoutSlot, String?>{
      for (final slot in EquipmentLoadoutSlot.values) slot: null,
    };
    _equippedProfileMedalId = null;
    _unlockedProfileMedalIds.clear();
    _enemyCards = _createEnemyCardInventory();
    _bossEnemyCards = _createBossEnemyCardInventory();
    _threatRegions = _createThreatRegionStates();
    _bossTraits = _createBossTraitInventory();
    _apexCores = _createApexCoreInventory();
    _activeEnemySuite = const EnemySuiteState();
    _selectedThreatRegionId = ThreatRegionLibrary.all.first.id;
    _offlineRegionId = null;
    _offlineRegionStabilizedLevel = 0;
    _offlineRegionValidatedThreatDirectorId = null;
    _farmSwarmSize = initialEnemyTarget;
    _validatedFarmRegionId = null;
    _validatedFarmSwarmSize = initialEnemyTarget;
    _validatedFarmThreatDirectorId = null;
    _validatedFarmStabilizedLevel = 0;
    _validatedFarmEfficiency = 0;
    _validatedFarmKillsPerHour = 0;
    _validatedFarmLumensPerHour = 0;
    _threatRegionChallenge = null;
    _threatChallengeAutoFocusedWaveIndex = -1;
    _threatRegionFarmValidation = null;
    _activeBossEnemyCardId = BossEnemyLibrary.starterWhiteWarden.id;
    _seedStarterEnemyCards();
    _seedStarterManagers();
    _layers = <TowerLayerSnapshot>[];
    final rootLayer = _freshLayerSnapshot(label: shellNameForTier(1), tier: 1);
    _layers.add(rootLayer);
    _viewLayerId = rootLayer.id;
    _runtimeLayerId = rootLayer.id;
    _loadLayer(rootLayer);
    _armStarterBossForOpening();
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

  static List<LightcoreTutorialQuestDefinition> get tutorialQuestLibrary =>
      _tutorialQuestDefinitions.values.toList(growable: false);

  static String get tutorialQuestHelpBody {
    final sections = <String>[];
    for (final quest in tutorialQuestLibrary) {
      sections.add(
        '${quest.id} ${quest.title}\n'
        'Why: ${quest.teachGoal}\n'
        'Do this: ${quest.coachCopy}\n'
        'Target: ${quest.primaryClickTarget}\n'
        'Complete: ${quest.completionCondition}\n'
        'Result: ${quest.reward}\n'
        'Hint: ${quest.failureHelpState}',
      );
    }
    return sections.join('\n\n');
  }

  static const int slotCount = 6;
  static const bool equipmentReleaseEnabled = false;
  static const int maxShellTier = 4;
  static const int maxTowerLevel = 5;
  static const int maxTowerUpgradeRank = maxTowerLevel - 1;
  static const int minTowerUpgradeOptions = 2;
  static const int maxTowerUpgradeOptions = 4;
  static const int enemyDeckLimit = 3;
  static const int bossSpawnKillRequirement = 100;
  static const int bossUnlockLayer = 2;
  static const int bossUnlockLevel = 5;
  static const int tournamentUnlockLevel = 20;
  static const int mentorshipUnlockLevel = 30;
  static const int dailyDungeonUnlockLevel = 15;
  static const int dailyDungeonStartingTowerLevel = 1;
  static const int dailyDungeonMaxTowerLevel = 60;
  static const int dailyDungeonQuickClearsPerDay = 3;
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
  static const int maxPromotedChildTowerRerolls = 3;
  static const int towerManagerFluxCost = 40;
  static const int enemyManagerFluxCost = 52;
  static const int maxManagerPowerLevel = 30;
  static const int managerPowerBaseUpgradeCost = 18;
  static const int managerBulkForgeFiveBonusShards = 6;
  static const int managerBulkForgeTenBonusShards = 16;
  static const int maxEquipmentInventorySize = 200;
  static const int traitRefreshLumenCost = 6;
  static const int maxActiveEnemies = 84;
  static const int evenEntryTournamentLevel = 1;
  static const int evenEntryTournamentCoreLevel = 1;
  static const int evenEntryTournamentPowerIndex = 1000;
  static const int tournamentPowerIndexCap = 500000;
  static const int minEnemyTarget = 6;
  static const int initialEnemyTarget = 6;
  static const int baseEnemyTargetMax = 20;
  static const int enemyTargetUpgradeStep = 1;
  static const int _legacyEnemyTargetUpgradeStep = 8;
  static const int maxEnemyTargetUpgradeLevel =
      (maxActiveEnemies - baseEnemyTargetMax) ~/ enemyTargetUpgradeStep;
  static const int threatRegionChallengeWaveCount = 3;
  static const int farmValidationWaveCount = 3;
  static const int swarmMagnetRerollCost = 1;
  static const double focusTargetDurationSeconds = 5;
  static const double focusTargetCooldownSeconds = 4;
  static const double _farmValidationBaseWaveSeconds = 30;
  static const double _maxFlowEfficiency = 100;
  static const double _maxCoreStability = 100;
  static const double _minimumOutputEfficiency = 0.15;
  static const double _outputEfficiencyGamma = 1.10;
  static const double _baseCoreStabilityRecoveryPerSecond = 0.8;
  static const int _coreEnergyUnlockLayer = 3;
  static const int _maxCoreEnergyUpgradeLevel = 5;
  static const double _baseCoreEnergyCapacity = 100;
  static const double _coreEnergyCapacityUpgradeStep = 20;
  static const double _baseCoreEnergyRecoveryPerSecond = 7;
  static const double _coreEnergyRecoveryUpgradeStep = 1.4;
  static const double _apexBaseStabilityDamageMultiplier = 2.5;
  static const double _apexRarityStabilityDamageStep = 0.82;
  static const double _minimumSpawnRadius = 860;
  static const double _defaultTowerLaneRangeShare = 2 / 3;
  static const double _spawnRadiusBandSpacing = 20;
  static const int _spawnRadiusBandCount = 4;
  static const double _spawnCrowdRadiusPerEnemy = 14;
  static const int _openingRangeProximitySpawnCount = initialEnemyTarget;
  static const double _openingRangeProximityBuffer = 58;
  static const int _spawnClusterSize = 3;
  static const double _spawnClusterAngleStep = 0.052;
  static const double _spawnClusterAngleJitter = 0.012;
  static const double _spawnClusterRadiusJitter = 10;
  static const double _relayImpactRadius = 102;
  static const double _pulseSpeed = 2.1;
  static const int _maxFloatingPayloadsPerSource = 3;
  static const int maxFloatingPayloadsPerSource = _maxFloatingPayloadsPerSource;
  static const double _shotSpeed = 3.8;
  static const double _impactSpeed = 2.8;
  static const double _coreBombSplashRadius = 180;
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
  static const double _defaultEnemyMovementSpeedMultiplier = 1.32;
  static const double _enemyAngularDriftCapPerSecond = 0.42;
  static const double _yellowBlinkFirstSeconds = 1.6;
  static const double _yellowBlinkIntervalSeconds = 3.1;
  static const double _yellowBlinkAngleShift = 0.34;
  static const double _yellowBlinkBaseRadiusSkip =
      _spawnRadiusBandSpacing * 3.5;
  static const double _uiNotifyCadence = 0.12;
  static const double _coreBaseRange =
      _relayImpactRadius +
      ((_minimumSpawnRadius - _relayImpactRadius) *
          _defaultTowerLaneRangeShare);
  static const double _promotedChildTowerRangeMultiplier = 1.15;
  static const double _promotedChildTowerPowerMultiplier = 1.35;
  static const double _promotedChildTowerPowerTierStep = 0.12;
  static const double _promotedCoreShotPowerMultiplier = 3.25;
  static const double _promotedCoreShotPowerTierStep = 0.55;
  static const double _promotedSourcePassiveMultiplier = 1 / slotCount;
  static const double _coreBaseCooldown = 0.62;
  static const double _coreBaseCritChance = 0.05;
  static const double _coreBaseCritMultiplier = 1.55;
  static const int maxCoreLevel = maxTowerLevel;
  static const int maxCoreUpgradeLevel = 5;
  static const int maxCoreMultiShotUpgradeLevel = 3;
  static const int baseCoreQueueCapacity = 8;
  static const int coreQueueCapacityUpgradeStep = 2;
  static const int maxOfflineProgressSeconds = 4 * 60 * 60;
  static const int childTowerUpgradeOptionsPerLevel = 4;
  static const int childTowerUpgradeMaxRank = 10;
  static const int payloadUnlockLayer = 2;
  static const double rainbowPromotionChance = 0.10;
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
  static const double layer1ChildTowerMaxConstructionDurationSeconds = 10 * 60;
  static const List<double> layer1TowerConstructionDurationsSeconds = <double>[
    towerConstructionDurationSeconds,
    45,
    2 * 60,
    4 * 60,
    7 * 60,
    layer1ChildTowerMaxConstructionDurationSeconds,
  ];
  static const List<double> layer1TowerBuildCostMultipliers = <double>[
    1.10,
    2.80,
    5.50,
    13.75,
    27.50,
    40.00,
  ];
  static const int friendRelayLevelBand = 6;
  static const int defaultGuildCreationUnlockLevel = 10;
  static const int guildMemberCap = slotCount + 1;
  static const int helpSectionTicketReward = 5;
  static const int radianceStatResetPrismShardCost = 2000;
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
  static const double _maxLumenHarvestSlowdown = 0.24;
  static const double _relayHitLumenHarvestDamageScale = 12;
  static const double _emptyLaneLumenHarvestDamageScale = 18;
  static const int tutorialFirstHexUnlockExperience = 8;
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
  late List<CompletedTowerShellState> _completedTowerShells;
  late List<EnemyCardState> _enemyCards;
  late List<EnemyCardState> _bossEnemyCards;
  late List<ThreatRegionState> _threatRegions;
  late List<BossTraitState> _bossTraits;
  late List<ApexCoreState> _apexCores;
  late EnemySuiteState _activeEnemySuite;
  String? _selectedThreatRegionId;
  String? _offlineRegionId;
  int _offlineRegionStabilizedLevel = 0;
  String? _offlineRegionValidatedThreatDirectorId;
  int _farmSwarmSize = initialEnemyTarget;
  String? _validatedFarmRegionId;
  int _validatedFarmSwarmSize = initialEnemyTarget;
  String? _validatedFarmThreatDirectorId;
  int _validatedFarmStabilizedLevel = 0;
  double _validatedFarmEfficiency = 0;
  double _validatedFarmKillsPerHour = 0;
  double _validatedFarmLumensPerHour = 0;
  ThreatRegionChallengeState? _threatRegionChallenge;
  ThreatRegionFarmValidationState? _threatRegionFarmValidation;
  final Set<String> _threatRegionDefeatedBossIds = <String>{};
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
  final void Function(EnemyState enemy)? relayHitListener;
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
  LightcoreBattleSpawnPolicy _battleSpawnPolicy =
      LightcoreBattleSpawnPolicy.automatic;
  bool _enemySpiralMovementEnabled = true;
  double _enemyMovementSpeedMultiplier = _defaultEnemyMovementSpeedMultiplier;
  bool _battleKillRewardsEnabled = true;

  // TODO(authority): Move persistent player state behind a repository backed by
  // local cache plus backend sync. Client-owned mutable state keeps local play
  // responsive, but long-lived progression still needs authoritative claims.
  int lumens = 44;
  int flux = 96;
  int prismShards = 0;
  int managerShards = 0;
  int managerPowerLevel = 0;
  int shellCores = 0;
  int enemyTickets = 18;
  int bossTickets = 0;
  int bossCores = 0;
  int threatShards = 0;
  int swarmMagnets = 0;
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
  int? _serverClockAnchorMillis;
  final Stopwatch _serverClockElapsed = Stopwatch();
  String? _serverDayKey;
  String? _serverWeekKey;
  String _timeWarpPurchaseWeekKey = '';
  final Map<String, int> _timeWarpWeeklyPurchases = <String, int>{};
  String _storeOfferPurchaseWeekKey = '';
  final Map<String, int> _storeOfferWeeklyPurchases = <String, int>{};
  int _dailyDungeonHighestUnlockedTowerLevel = dailyDungeonStartingTowerLevel;
  int _dailyDungeonHighestClearedTowerLevel = 0;
  String _dailyDungeonQuickClearDayKey = '';
  int _dailyDungeonQuickClearsUsed = 0;
  String? _equippedProfileMedalId;
  final Set<String> _unlockedProfileMedalIds = <String>{};
  String? _focusedEnemyId;
  double _focusTargetRemainingSeconds = 0;
  double _focusTargetCooldownRemaining = 0;
  int _threatChallengeAutoFocusedWaveIndex = -1;

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
  bool _hasPermanentOverdrive = false;
  bool _hasPremiumMembership = false;
  double _tournamentExperienceMultiplier = 1.0;
  DateTime? _tournamentExperienceBoostEndsAt;
  LightcoreGraphicsQuality _graphicsQuality;
  bool _notificationBannersEnabled = true;
  bool _battleNotificationBannersEnabled = false;
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
  bool _tutorialFirstTowerStatsOpened = false;
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
  bool _tutorialManualAimFireLearned = false;
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
