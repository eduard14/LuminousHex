# Lightcore Code And V8 Design Alignment Map

Last verified: 2026-04-25

This document maps the current implementation to `lumicore_cosmic_design_bible_v8_efficiency_systems.xlsx`.
Use it before doing a broad codebase scan. It is intentionally code-level:
symbols, files, and review anchors are listed so future alignment checks can
start from a targeted `rg` search.

## Status Key

- `Aligned`: the implemented behavior matches the V8 design direction closely.
- `Partial`: the system exists, but scope or player-facing framing differs.
- `Legacy drift`: useful legacy behavior exists, but it conflicts with or
  predates V8 decisions.
- `Missing`: the workbook describes a system that is not implemented yet.

## Fast Entry Points

| Area | Primary files | Useful symbols / searches |
| --- | --- | --- |
| Game authority | `lib/state/lightcore_controller.dart` | `LightcoreController`, `tick`, `_spawnEnemy`, `_killEnemy`, `unlockLayer2Tower` |
| Runtime state | `lib/models/lightcore_state.dart` | `OuterTowerState`, `CoreState`, `Layer2TowerState`, `TowerLayerSnapshot` |
| Tower content | `lib/data/tower_configs.dart`, `lib/data/lumicore_trait_catalog.dart` | `TowerLibrary`, `layer1ProjectileByAffinity`, `layer2PayloadByAffinity` |
| Anomaly content | `lib/data/enemy_configs.dart`, `lib/data/card_configs.dart` | `EnemyLibrary`, `BossEnemyLibrary`, `EnemyCardState` |
| Threat Directors | `lib/data/enemy_manager_configs.dart` | `EnemyManagerLibrary`, `EnemyManagerState`, `enemyManagerForCard` |
| Equipment | `lib/data/equipment_configs.dart` | `EquipmentLibrary`, `PlayerEquipmentItem`, `_awardEquipmentDropIfRolled` |
| Social / mentor | `lib/models/lightcore_social_state.dart`, `functions/index.js` | `LightcoreSocialOverview`, `MENTOR_LINK_COLLECTION`, `computeSocialBonusProfile` |
| Backend idle and tournaments | `lib/services/lightcore_firebase_backend.dart`, `functions/index.js` | `claimOfflineProgress`, `syncIdleSnapshot`, `submitTournamentRun` |
| Player-facing shell UI | `lib/screens/lightcore_shell.dart`, `lib/screens/tower_management_screen.dart`, `lib/screens/prestige_screen.dart`, `lib/screens/enemy_management_screen.dart` | `FriendManagementScreen`, `TournamentScreen`, `PrestigeScreen` |

## V8 System Map

| V8 design area | Implementation status | Code anchors | Notes / follow-up |
| --- | --- | --- | --- |
| Terminology: Anomalies, Threat Scans, Threat Directors, Apex Anomalies, Output Efficiency | Partial | `LightcoreCurrencyLabels`, `EnemyManagerLibrary`, `enemy_management_screen.dart`, `lightcore_shell.dart`, `functions/index.js` | Player-facing labels are V8-aligned. Some backend callable names still use `Boss` for API compatibility, but returned social gift messages now say Apex Scan gifts. |
| Source Tower identities | Aligned | `TowerLibrary`, `PrototypeAffinityX`, `layer1ProjectileByAffinity` | The seven playable Source Tower families exist: White, Red, Orange, Yellow, Green, Blue/Aether, Purple. Black is reserved for anomalies and special systems. Legacy internal ids such as `cyan_prism` remain for Blue/Rayline. |
| Tower fabrication | Partial | `startTowerFabricationAt`, `_advanceTowerFabrication`, `OuterTowerState.isFabricating`, `tutorialStartTowerFabricationAt`, `buildTowerAt` | The player-facing tower screen now starts a timed fabrication job that reserves the slot, persists remaining time, and only counts the tower as active when complete. `buildTowerAt` remains an instant test/debug compatibility path, and there is no manual completion claim or trusted server timestamp yet. |
| Random trainable stats, Overcharge, Radiant | Aligned | `TowerUpgradeOptionState`, `_rollTowerUpgradeBoard`, `towerUpgradeEffectLabel` | Towers roll 2-4 trainable stats. Radiant applies the V8 1.30 multiplier in upgrade labeling and effect math. Overcharge is represented as a flagged upgrade option. |
| Layer 2 Alignment / shell promotion | Partial | `unlockLayer2Tower`, `_resolvePromotedTraitLoadoutForLayer`, `_syncParentSlotFromLayer`, `activeChildTowerProjection` | The game uses shell-class promotion and child-shell forging, not the workbook's simpler "seven Layer 1 towers create one Layer 2 Aligned Tower" wording. Component history is preserved through child-layer links and inherited stats, but there is no separate alignment timer for promotions. |
| Old `Layer2TowerState` weapon | Legacy internals | `Layer2TowerState`, `_fireLayer2IfPossible`, `_layer2.unlocked` | `Layer2TowerState` still exists as a second-weapon runtime object, but no normal gameplay path sets it unlocked and current UI does not present it as a weapon. Treat it as legacy unless a future design explicitly revives it. |
| Component history retention | Partial | `OuterTowerState.childLayerId`, `childProjectileLoadout`, `childPayloadLoadout`, `childBuiltCount`, `_syncParentSlotFromLayer` | Child shells remain playable and parent slots retain projected inherited values. This supports "history remains inspectable", but the UI is currently shell/tree oriented rather than a dedicated component-history view. |
| Core clusters and firing queue | Aligned | `CoreState`, `AmmoPacket`, `_ammoQueue`, `_advancePulses`, `_fireCoreIfPossible`, `coreQueueCapacity` | The center core consumes relay packets as intended. Built towers create floating payload pieces at a starter feed rate; one Core Manager can be assigned per shell to improve payload feed, and managers no longer generate free core-basic packets. |
| Multiple active cores | Partial | `_viewLayerId`, `_runtimeLayerId`, `tick`, `_advanceRuntimeLayer`, `_storeActiveLayer` | `tick` now iterates every stored shell and advances combat, fabrication timers, pressure, shots, and automated output. Foreground-only helpers still gate tutorial prompts and localhost auto-tapping. Offline claims remain snapshot-based rather than full replay. |
| Core Stability and Output Efficiency formula | Aligned | `_outputEfficiencyPercentForStability`, `_setCoreStability`, `outputEfficiencyMultiplier`, `activeEffectiveGainMultiplier` | Formula matches V8: `E = max(E_min, (S / 100)^gamma)` with `E_min = 0.15`, `gamma = 1.10`. Effective gain is exposed as Threat Reward x Output Efficiency. |
| Stability damage and recovery | Aligned | `_applyLumenHarvestDamage`, `_stabilityDamageMultiplierForEnemy`, `_recoverLumenHarvest`, `coreStabilityRecoveryPerSecond` | Leaks and Apex pressure reduce Core Stability rather than player health. Recovery uses base recovery plus green tower, manager, and core-level contributions. |
| Threat Scans as risk/reward bundles | Partial | `ThreatScanBundleSnapshot`, `activeThreatScanBundle`, `openEnemyTickets`, `activeEnemyDeck`, `activeThreatRewardMultiplier`, `activeThreatStabilityMultiplier`, `enemyTargetCount` | Threat Scans unlock or copy anomaly cards, and the armed deck is now projected into a formal bundle snapshot with risk, reward, stability pressure, director names, and counterplay. This is still derived from deck composition rather than authored selectable bundle content. |
| Threat Directors | Aligned | `EnemyManagerLibrary`, `_generateEnemyManager`, `assignEnemyManagerToCore`, `activeRegionThreatDirector`, `_enemyManagerEffectMultiplier` | Threat Directors use the old bible display-name roster while preserving V8-style mechanical archetypes in config summaries. They attach to Threat Map regions and tune the current spawn cadence, enemy strength, rewards, EXP, stability risk, farm wave cadence, queue disruption, and Apex stability. |
| Apex Anomaly cadence | Aligned | `bossSpawnKillRequirement`, `normalKillsSinceBoss`, `bossReady`, `_spawnEnemy`, `_killEnemy` | Every 100 normal anomaly clears primes the next Apex spawn if an Apex card is armed. Apex clears grant Lumens, Apex Scans, Heartcores, and sometimes other rewards. |
| Apex pressure | Aligned | `_apexBaseStabilityDamageMultiplier`, `_apexRarityStabilityDamageStep`, `_directorApexStabilityMultiplier` | Apex enemies multiply stability damage and can inherit director pressure. There is no separate health bar fail state, consistent with V8's efficiency-defense direction. |
| Equipment acquisition | Aligned | `equipmentDropChanceForEnemy`, `_awardEquipmentDropIfRolled`, `_grantEquipmentEventCache`, `TournamentRewardPackage` | Normal and Apex anomaly clears no longer roll equipment. Event caches and tournament reward packages are the acquisition path; debug helpers remain for tests and tools. |
| Tournament tower snapshots | Partial | `TournamentScreen`, `LightcoreTournamentPlayerSnapshot`, `buildTournamentSnapshot`, `functions/index.js` tournament handlers | Arena Flow now uses the player's highest-layer Home Tower for tier, core, and power index. Weekly tournament entries are keyed by server window, Arena Flow pads its leaderboard with server-seeded rivals, and rewards are claimed from the last closed server board. Other tournament formats still use event-specific shells and anomaly pools. |
| Mentor network | Partial | `LightcoreSocialOverview`, `sendMentorInvite`, `acceptMentorLink`, `computeSocialBonusProfile`, `homeTowerMentorExperienceMultiplier`, `homeTowerLabel` | Real player mentor links, level-band checks, capped first-ring bonuses, and second-ring recognition exist. Client runtime now shapes those bonuses through the highest-layer Home Tower affinity. |
| Friends and Apex Scan gifts | Aligned | `sendBossPullGift`, `claimBossPullGift`, `applySocialBossGiftClaim` | UI and backend returned messages call these Apex Scan gifts. Callable names remain stable for compatibility. |
| Offline simulation | Partial | `buildOfflineProgressSnapshot`, `syncIdleSnapshot`, `claimOfflineProgress`, `offlineKillsPerHour` | Offline rewards are based on a current snapshot and server claim. They use managed automation and recent effective gain, but do not simulate full per-core Threat Scans, Apex outcomes, or multiple running cores. |
| Account Radiance / Player Level | Partial | `accountRadianceLevel`, `accountRadianceLabel`, `overallLevel`, `experience`, `_boostedExperienceReward`, `LightcoreSocialPlayer.levelLabel` | Player-facing copy now uses Account Radiance. Internal save/API fields still use `overallLevel` for compatibility. |
| Deconstruct / recalibrate | Partial | `scrapActiveLayer`, `rerollActiveChildTowerTraits`, `buyLumensWithFlux`, `buyEnemyPullsWithFlux` | Child shell scrap and Echo Seed reroll exist. V8's broader Source Tower deconstruction and special-currency recalibration economy is not implemented as a first-class loop. |
| Store / premium / battle pass | Legacy drift | `meta_progression_sheet.dart`, battle pass methods in `LightcoreController`, `purchasePremiumMembership` | Monetization and pass scaffolding is mixed into the gameplay shell. This is useful for testing but should be separated when tuning core V8 progression. |

## Highest-Risk Alignment Gaps

1. Fabrication is only locally time-gated.
   `startTowerFabricationAt` and `_advanceTowerFabrication` reserve a slot and
   count down in runtime state, while `buildTowerAt` remains an instant
   compatibility path for tests/debug flows. There is no trusted timestamp,
   offline fabrication catch-up, or "claim fabricated tower" step yet.

2. `Layer2TowerState` is legacy relative to shell promotion.
   The model and `_fireLayer2IfPossible` still support a separate Layer 2 gun,
   but normal advancement no longer unlocks it and the UI should not surface it.
   Treat this as legacy unless a new design explicitly revives it.

3. Threat Scan bundles are derived, not authored content.
   `ThreatScanBundleSnapshot` formalizes the active deck into bundle readouts,
   but the source of truth is still anomaly cards plus target count. There is no
   separate bundle library, bundle rarity table, or per-core authored bundle
   selection.

4. Offline simulation remains snapshot-based.
   Foreground and background shells now run during live ticks, but server idle
   claims still use aggregate snapshots instead of replaying every shell's full
   Threat Scan, Apex, and stability outcomes.

## Code-Level Alignment Details

### Source Towers And Stats

- Base tower definitions live in `TowerLibrary`.
- Source Tower display names stay weapon-first:
  `Starbolt Turret`, `Comet Mortar`, `Meteor Driver`, `Stormhook Coil`,
  `Thorn Aegis`, `Rayline Spire`, and `Quasar Ring`.
- Core Manager display names, bios, board bonuses, signature rules, and portrait
  asset ids follow `04 Tower Managers`, starting with
  `mgr_001_whitney_stardust` through `mgr_040_the_singularity_stylist`; each
  bible row is mapped onto an existing mechanical archetype such as Flow, Power,
  Tempo, Spectrum, Stability, or Burst.
- Core Managers assign to one shell at a time, apply their stat board to every
  built tower in that shell, and improve payload feed at their automation
  rate.
- Blue/Rayline is represented internally as `PrototypeAffinity.aether`; some
  legacy ids still use `cyan_prism`, but `PrototypeAffinityX.label` returns
  `Blue`.
- Trainable tower stats are stored in `OuterTowerState.towerUpgradeOptions`.
- Root shell core stats are stored in `CoreState.coreUpgradeOptions`, with a
  separate `CoreState.level` upgrade path capped like Source Tower levels.
- `TowerUpgradeOptionState.isRadiant` and `isOvercharge` carry V8 special-roll
  concepts.
- Upgrade labels and effects apply Radiant as a 1.30 multiplier.
- Player-facing tower creation uses `tutorialStartTowerFabricationAt` and
  `startTowerFabricationAt`; fabricating towers store
  `fabricationTotalSeconds` and `fabricationRemainingSeconds` on
  `OuterTowerState`.
- Combat activation, promotion readiness, pattern bonuses, and tower upgrades
  use `_slotCountsTowardRing`, which excludes `OuterTowerState.isFabricating`
  until `_advanceTowerFabrication` completes the timer.

### Canonical Shell And Tower Terms

- `Root Shell`: tier-1 shell class. It contains the Root Shell Core and six
  perimeter slots.
- `Root Shell Core`: the center Lightcore in the Root Shell. It owns Shell Level
  and Root Shell Core Stat Upgrades.
- `Shell Level`: the level on `CoreState.level` for the active shell core. Root
  Shell level is purchased with Lumens; child shell level advances through the
  child-tower tuning board.
- `Shell Class`: the shell tier label: Root, Prism, Nexus, Ascendant.
- `Perimeter Tower`: broad player-facing term for any tower in one of the six
  edge slots. A perimeter tower can be a Source Tower or a Child Tower.
- `Source Tower`: a buildable Root Shell perimeter tower with one Spectrum Band,
  one projectile family, no payload, a level, and trainable stat board.
- `Child Shell`: a lower shell built inside a parent perimeter slot. It has its
  own core, perimeter slots, enemies, and tuning board.
- `Child Tower`: the promoted result of a completed Child Shell. It occupies the
  parent perimeter slot, inherits projectile/payload traits from the Child Shell,
  and upgrades like a perimeter tower.
- `Archived Shell`: a completed lower shell retained for inspection and passive
  support after promotion.

### Promotion And Inheritance

- Root promotion and child-shell promotion share `unlockLayer2Tower`.
- New parent shell creation happens through `_freshLayerSnapshot`.
- Parent-slot projection happens through `_syncParentSlotFromLayer`.
- Recursive projectile and payload history is carried in:
  `childProjectileLoadout`, `childPayloadLoadout`, `childProjectileType`, and
  `childPayloadType`.
- Weighted stat inheritance is resolved through `_averageRangeForLayer`,
  `_averageGenerationForLayer`, `_averageCritChanceForLayer`,
  `_averageFinalDamageForLayer`, `_averageBossDamageForLayer`,
  `_averageNormalDamageForLayer`, `_averageDefensePenetrationForLayer`,
  `_averageMinDamageForLayer`, and `_averageMaxDamageForLayer`.
- The parent slot can be previewed while still unpromoted through
  `activeChildTowerProjection`, but the Advancement screen does not yet show a
  complete pre-promotion preview for root-shell promotion.

### Combat, Queue, And Efficiency

- Outer towers do not fire directly. They charge and create relay pulses that
  become `AmmoPacket` entries in `_ammoQueue`.
- The core fires through `_fireCoreIfPossible`; fallback core shots are
  controlled through the `allowDefaultShot` path.
- Empty lane leaks can remove queued packets and call `_applyLumenHarvestDamage`.
- `CoreState.coreStability` is the hidden pressure value. `CoreState.flowEfficiency`
  stores visible Output Efficiency as a percent.
- Output Efficiency status labels live in `outputEfficiencyStatusLabel` and
  tips live in `outputEfficiencyTip`.

### Threat Scans, Directors, And Apex

- `enemyTickets` are Threat Scans. `bossTickets` are Apex Scans.
- `openEnemyTickets` resolves Threat Scans into anomaly card copies.
- New anomaly cards auto-fill `_activeEnemyCardIds` until `enemyDeckLimit`.
- Active scan pressure is inferred from `activeEnemyDeck` and exposed through
  `activeThreatScanBundle`.
- `ThreatScanBundleSnapshot` carries the dominant affinity, active card names,
  attached director names, risk label, counterplay label, threat reward,
  stability pressure, Output Efficiency, and effective gain.
- Current anomaly display names map the active config slots onto old bible
  roots: `Dustling`, `Huskflare`, `Rushling`, `Blinkling`, `Mossmender`,
  `Jammer Cub`, `Splitling`, and `Wormguard`, with rarity prefixes for higher
  tiers.
- Current Apex display names map the active seed slots onto old bible boss
  names such as `The Pale Equation`, `Huskstar Rex`, `Comet Khan`,
  `Parallax Jack`, `Mother Moss Nova`, `The Ion Warden`, and
  `The Gemini Maw`. Higher-rarity Apex cards keep the existing rarity prefixes
  so preview filtering can distinguish duplicated archetype seeds.
- `EnemyManagerState` represents a Threat Director instance.
- Threat Director display names, bios, wave modifiers, design intents, and
  portrait asset ids follow `05 Enemy Managers`, starting with
  `emg_001_plain_jane_quasar` through `emg_040_the_dark_spectrum`; archetype
  math remains Swarm, Titan, Phase, Regen, Gravity, Greed, Saboteur, Volatile,
  or Apex Herald.
- Threat Directors attach to Threat Map regions. The selected or validating
  region exposes its director through `activeRegionThreatDirector`, and effects
  are applied through `_managerValue` and `_enemyManagerEffectMultiplier`.
- Apex cadence is controlled by `bossSpawnKillRequirement`, currently 100.
- `activeLayer.normalKillsSinceBoss` and `activeLayer.bossReady` are layer-local,
  matching the current shell architecture.

### Offline, Social, And Backend

- The client builds an offline snapshot with `buildOfflineProgressSnapshot`.
- The backend accepts it through `syncIdleSnapshot` and grants rewards through
  `claimOfflineProgress`.
- Mentor links are stored in `mentorLinks`; pending invites are stored in
  `mentorInvites`.
- Level-band validity is checked by `isWithinMentorBand`.
- Active mentees are capped by `activeMenteeBonusLimit`, then converted into
  `LightcoreSocialBonusProfile`.
- Friend gifts are implemented as boss-pull/Apex-Scan gifts. User-facing copy
  should prefer Apex Scan.

## Quick Audit Commands

```bash
rg -n "startTowerFabricationAt|_advanceTowerFabrication|isFabricating|_buildRolledTowerState|_rollTowerUpgradeBoard" lib
rg -n "Layer2TowerState|_fireLayer2IfPossible|_layer2\\.unlocked" lib
rg -n "_runtimeLayerId|_viewLayerId|passiveLumenPerSecond|offlineKillsPerHour" lib/state/lightcore_controller.dart
rg -n "Output Efficiency|coreStability|flowEfficiency|activeEffectiveGain" lib
rg -n "ThreatScanBundleSnapshot|activeThreatScanBundle|openEnemyTickets|activeThreatRewardMultiplier|EnemyManagerLibrary|bossSpawnKillRequirement" lib
rg -n "TournamentPlayerSnapshot|towerPowerIndex|bonusEquipmentCaches" lib functions/index.js
rg -n "Mentor|mentee|LightcoreSocialBonusProfile|computeSocialBonusProfile" lib functions/index.js
```

## Maintenance Notes

- Update this document whenever a design-bible pass changes player-facing terms
  or system ownership.
- If a code change removes a legacy drift item, move it into `Aligned` or
  `Partial` and list the new anchors.
- Prefer adding symbols over line numbers. Function names survive edits better
  and make `rg` searches faster.
