# Gameplay Mechanics Audit

This document is a short replacement for re-reading the whole codebase when you
need to remember how the prototype actually works today, what systems matter,
and which mechanics are likely to need redesign.

Primary sources:

- `lib/state/lightcore_controller.dart`
- `lib/models/lightcore_state.dart`
- `lib/data/tower_configs.dart`
- `lib/data/enemy_configs.dart`
- `lib/data/card_configs.dart`
- `lib/data/enemy_manager_configs.dart`
- `lib/screens/lightcore_shell.dart`
- `lib/screens/prestige_screen.dart`
- `test/overall_progression_and_boss_test.dart`
- `test/progression_unlocks_test.dart`
- `test/child_tower_growth_test.dart`
- `test/manual_overdrive_test.dart`

## One-Page Summary

Lightcore is not a standard tower defense where every tower shoots. The center
core is the only unit that fires directly. The six outer towers are relays that
charge, package shot data, and feed ammo packets into the core queue.

The player builds a six-slot shell, upgrades each outer tower to level 5, then
promotes the shell into a higher layer. Root-shell promotion creates a new
higher-tier shell. Child-shell promotion forges one tower into a parent slot.
Promoted lower shells stay inspectable as passive archives; the shell map marks
whether the viewed shell is the live battle focus or a passive support archive.

Anomaly pulls are also non-standard: you summon anomaly cards to define the
anomalies you fight, not the units you own. Cards create the active anomaly
deck for a layer, and the selected region's Threat Director tunes current spawn
cadence, enemy strength, and reward bonuses.

## Current Gameplay Loop

1. Reveal the shell by tapping/selecting the center.
2. Select Hex 1 immediately and build the first relay tower.
3. Tap the highlighted starter anomaly to focus queued fire while the Lightcore
   and ready relays auto-feed packets into the core queue.
4. Upgrade all built towers to level 5.
5. Tune the encounter by changing the active anomaly deck and target count.
6. Promote the finished shell.
7. Re-enter child shells and repeat until higher-tier parent slots are forged.
8. Spend Flux on managers once Core Lv 3 or Account Radiance Lv 10 unlocks the
   foundry.

## Rules That Matter

### Battle topology

- The center core is the only direct attacker. Early play auto-generates
  `AmmoPacket` entries after the Lightcore wakes, then anomaly taps aim/focus
  fire without making the player tap the core to queue shots.
- The active tutorial stays as a compact, tap-to-expand quest notification on
  the battlefield. The collapsed notification names the next action while the
  battlefield highlight and click gesture point at the target.
- Outer towers generate `EnergyPulseState` objects through starter auto-feed or
  manager automation, but waiting packets do not orbit as field objects. Only
  brief tower-to-core handoff effects are shown so players do not chase
  non-interactive packet visuals.
- Tapping an anomaly focuses fire immediately. If the queue is still charging,
  the focused target receives the next available queued packet before manager
  auto-fire is unlocked.
- The Focus Fire tutorial guarantees a visible starter anomaly when the lesson
  begins, so the player has a target instead of waiting for a spawn.
- Auto-fire stays locked until a Core Manager is assigned. Once unlocked, the
  core consumes the best ammo packet available, picks a target, and fires.
- Enemies do not destroy the core in the prototype. Reaching the relay ring
  causes lane disruption instead of a fail state.

### Flow, disruption, and pressure

- Output Efficiency is reduced by anomaly count and average lane disruption.
- Empty lanes do not damage the player; they delete one queued packet.
- Occupied lanes gain disruption, which reduces charge rate and increases tower
  cooldown.
- Green towers recover from jams best.
- Yellow towers reduce Lumen reward loss from crowded battlefields.

### Slot unlock progression

- Outer slots unlock from total progression EXP/kills, not local shell progress.
- Unlock thresholds are:
  - Hex 1: available at start
  - Hex 2: 100 EXP
  - Hex 3: 250 EXP
  - Hex 4: 500 EXP
  - Hex 5: 850 EXP
  - Hex 6: 1250 EXP
- Promotion still requires all six slots to be built and promotion-ready.

### Towers

- Seven Source Tower identities exist: white, red, yellow, green, purple, orange, blue.
- Base towers roll combat traits on build.
- Source Towers are single-affinity and projectile-only.
- Payloads unlock after the first promotion.
- Prism Shell is where blended color signatures first appear on promoted towers
  and cores.
- Core Managers and Threat Directors unlock at Core Lv 3 or Account Radiance
  Lv 10.
- Towers auto-feed after the shell wakes. Tapping a built tower opens tower
  controls, stats, upgrades, and targeting tools instead of firing a packet.
- Higher shell classes inherit projectile and payload arsenals from the child shells
  beneath them instead of collapsing to one dominant shot type.
- Source Tower and Root Shell Core max level is 5.
- Sell value is 70 percent of invested Lumens.

### Naming conventions

- Root Shell: tier-1 shell class with one center core and six perimeter slots.
- Root Shell Core: the center Lightcore in the Root Shell.
- Shell Level: the level on the active shell core. Root Shell level uses Lumens;
  Child Shell level comes from completing the child-tower tuning board.
- Shell Class: Root Shell, Prism Shell, Nexus Shell, or Ascendant Shell.
- Perimeter Tower: any tower in one of the six edge slots.
- Source Tower: a buildable Root Shell perimeter tower with one color,
  one projectile family, no payload, its own level, and its own stat board.
- Child Shell: a lower shell built inside a parent perimeter slot.
- Child Tower: the promoted perimeter tower created from a completed Child
  Shell. It inherits projectile and payload traits from that Child Shell.
- Archived Shell: a completed lower shell kept for inspection and passive
  support after promotion.

### Projectile families

- Projectile is the delivery method.
- Payload is the hit effect.
- Projectile and payload are modular once promotions begin.
- Source Tower family tracks are:
  - White / Starbolt Turret: precision bolts.
  - Blue / Rayline: Thread Beam; Pulse Beam, Split Beam; Sweep Beam, Lance Beam,
    Prism Beam, Sentinel Beam. Payloads: Chill, Fracture; Deep Chill, Brittle
    Fracture.
  - Orange / Impact: Heavy Shot; Breaker Shot, Crush Shot; Siege Shot, Drill
    Shot, Ricochet Shot, Hunter Ship. Payloads: Rend, Force; Core Rend,
    Concussive Force.
  - Red / Burst: Core Bomb; Pulse Bomb, Cluster Bomb; Nova Bomb, Cascade Bomb,
    Field Bomb, Bomber Ship. Payloads: Overheat, Detonate; Meltdown, Chain
    Detonate.
  - Yellow / Arc: Chain Arc; Fork Arc, Arc Node; Storm Arc, Web Arc, Sky Arc,
    Interceptor Ship. Payloads: Shock, Disrupt; Overload, EMP Disrupt.
  - Purple / Wave: Pulse Ring; Echo Ring, Collapse Ring; Halo Wave, Spiral
    Wave, Warp Wave, Shade Satellite. Payloads: Expose, Pull; Collapse,
    Singularity Pull.
  - Green / Shield: persistent Shield Halo with no packet generation; Sweep
    Node, Sling Node; Halo Nodes, Anchor Node, Flail Node, Familiar Ship.
    Payloads: Corrupt, Spread; Cascade Corrupt, Viral Spread.
- Projectiles remain color-specific in Root Shell.
- Payloads remain color-specific once they unlock.
- Starting in Prism Shell, promoted towers can show blended signatures such as
  Red projectile / Blue payload while still carrying multiple projectile or
  payload families.

### Anomaly deck and summons

- Threat Scan pulls unlock anomaly cards and add copies.
- New cards auto-fill the active deck until the three-card deck limit is hit.
- Summoning Level uses increasing scan milestones, with the final milestone gap
  at 20,000 total pulls.
- Higher Summoning Level increases access to higher-rarity anomalies.
- Anomaly cards are used to spawn anomalies, not friendly units.

### Apex loop

- Apex Anomalies are layer-local.
- After 100 normal anomaly clears without an Apex Anomaly alive, the next spawn
  becomes the chosen Apex Anomaly card.
- Apex clears grant a large payout, occasional Threat Scans, and Apex Scans.

### Layering and promotion

- Root shell promotion creates a new parent shell and keeps the old shell as a
  source layer.
- Child-shell promotion does not create a new layer. It forges that shell into
  one parent slot as a promoted child tower.
- A parent slot only counts toward ring completion after the child shell has
  actually been promoted.
- Child shells also have a separate four-option upgrade board that levels the
  forged parent tower over time.

### Live, passive, and offline simulation

- Only the currently viewed shell runs combat, anomaly spawning, Apex progress,
  and ticket generation.
- Non-viewed shells only generate passive Lumens from tower slots that have
  assigned managers.
- Offline catch-up only estimates managed towers. Unmanaged towers do not
  generate progress while the player is away.
- Passive shells do not simulate kills, Flux, Threat Scans, or Apex Anomalies.
- Manual Overdrive only speeds the live shell battle. It does not speed passive
  income.

### Global economies

- Lumens are global and used for tower building, tower upgrades, child-shell
  tuning, core upgrades, and encounter-cap upgrades.
- Flux is global and mainly spent on manager forging.
- Threat Scans are global and used for anomaly pulls.
- Apex Scans are global, visible in the UI, and currently feed Apex Anomaly pulls.

## How Promotion Actually Inherits Stats

Promotion is one of the least obvious systems in the project.

- Root-shell promotion creates a higher-tier shell whose core inherits a
  weighted primary affinity, an optional secondary affinity, and recursive
  projectile and payload arsenals from the shell below it.
- Child-shell promotion updates the parent-slot tower from the child shell.
- Parent-slot towers inherit:
  - A primary affinity plus an optional secondary affinity when the direct
    child-shell mix warrants a blend
  - Recursive projectile and payload arsenals assembled from descendant towers
  - Weighted averages of range, generation speed, crit chance, crit multiplier,
    final damage, boss damage, normal damage, defense penetration, min damage,
    and max damage
  - Extra bonuses from the child-shell upgrade board
- Weighting is based on effective tower level, so higher-level contributors
  matter more.
- Higher shell classes fire by cycling those inherited arsenals, so one mixed child can
  contaminate an otherwise pure parent build.

Practical consequence: if you want a Nexus tower or core to stay pure Wave,
every promoted child shell under it must also stay Wave-only. One off-pattern
child adds its projectile and payload families to the parent arsenal. The
resulting parent tower is still hard to predict by feel alone unless the UI
exposes these inherited values before promotion.

## Mechanics That Need Improvement

### 1. The `Layer2TowerState` system is legacy internals

Why it does not make sense:

- The controller contains a full second-weapon system:
  `_fireLayer2IfPossible`, layer2 cooldown, layer2 range checks, and flow
  relief.
- The prestige UI used to display a separate second-weapon counter, but current
  UI treats promotion as shell creation/forging instead.
- Promotion uses `unlockLayer2Tower()` as the main entry point.
- But no gameplay path appears to set `layer2.unlocked = true`, raise its
  `count`, or configure its traits.

Why this matters:

- It reads like a live feature but behaves like dead or abandoned design.
- It creates false expectations that promotion unlocks a separate Prism gun,
  when promotion currently creates or forges shells instead.

Recommended direction:

- Keep it out of player-facing copy unless a future design deliberately revives
  it as a separate weapon.

### 2. Apex Scans need clearer framing

Why it does not make sense:

- Apex Scans are granted on Apex clear and shown in the header and management
  screens.
- The previous name made them feel like a separate Apex trophy instead of the
  Apex-card pull currency.

Why this matters:

- Players need to understand that regular Threat Scans pull normal anomalies,
  while Apex Scans pull Apex Anomaly cards.

Recommended direction:

- Keep the scan naming consistent anywhere Apex Scan pulls are surfaced.

### 3. Live and passive shell state must be explicit

Why it does not make sense:

- The shell-class fantasy can imply many equal battlefronts.
- Current play is easier to understand as one live battle focus plus passive
  archives after promotion.
- A passive archive can still be opened for inspection, which makes any generic
  "viewed shell runs live" copy misleading.

Why this matters:

- Players need to know when they are looking at an archive versus the live
  runtime shell.
- Promotion should feel like archiving a completed shell into support, not
  spawning a hidden second battlefield.

Recommended direction:

- Keep persistent LIVE/PASSIVE labels on battle, shell map, and advancement
  surfaces.
- Never show "viewed shell runs live" while `activeLayerPassiveOnly` is true.

### 4. Enemy cards are conceptually backwards for first-time players

Why it does not make sense:

- Pulling cards usually means acquiring allies or usable abilities.
- Here, enemy pulls mostly unlock the enemies you will fight.

Why this matters:

- The mechanic is original, but the UI needs stronger framing to avoid players
  assuming they are summoning combat units.
- It also means spending tickets can make the battlefield harder before the
  player feels the reward upside.

Recommended direction:

- Rename or reframe the system as encounter blueprints, enemy contracts, swarm
  templates, or another term that communicates "you are shaping the encounter."

### 5. Promotion output is too opaque

Why it does not make sense:

- The parent-slot result depends on dominant traits, weighted averages, and the
  child upgrade board.
- That is a lot of hidden math for a key long-term decision.

Why this matters:

- Players cannot confidently build toward a desired parent tower.
- Designers also have to keep re-reading inheritance code to know what carries
  up.

Recommended direction:

- Add a pre-promotion preview panel that shows exactly what the promoted core or
  forged parent tower will become.

### 6. Flux shows up long before it has meaningful gameplay

Why it does not make sense:

- Flux drops from combat immediately.
- The actual manager systems that consume Flux are locked until Core Lv 3 or
  Account Radiance Lv 10.
- Before then, Flux only interacts with mock store conversions.

Why this matters:

- Early Flux feels dead and dilutes the readability of the early game.
- The player is asked to track a currency that does not yet drive decisions.

Recommended direction:

- Either delay Flux visibility until managers unlock, or add a real early-game
  Flux sink.

### 7. The combat loop has pressure but no real fail state

Why it does not make sense:

- Enemies jam lanes and lower reward efficiency, but they never threaten loss,
  shell breakage, or reset.
- Even leaking an empty lane only deletes one queued packet.

Why this matters:

- The game has tempo pressure but limited tension.
- Battle can feel like a reward-optimization sim instead of defense.

Recommended direction:

- Decide whether the game wants a true fail state, a shield/health system, or a
  stronger leak penalty. If not, communicate clearly that this is an efficiency
  defense game rather than a survival defense game.

### 8. Mock store and battle-pass systems are mixed into the core loop

Why it does not make sense:

- The prototype includes Flux purchases, premium pass unlocks, and reward
  grants that are explicitly fake.
- These systems sit next to the real balance loop.

Why this matters:

- It becomes harder to tune early progression because test resources and mock
  monetization paths are part of the same player-facing flow.

Recommended direction:

- Keep the scaffolding for future live-ops, but separate it from gameplay
  tuning and onboarding when evaluating the core loop.

### 9. Boss targeting overrides player target preferences completely

Why it does not make sense:

- `Close`, `Strong`, and `Weak` all yield to boss priority while a boss exists.
- That may be intended, but the UI does not state it.

Why this matters:

- Players may think their target configuration is broken during boss waves.

Recommended direction:

- Surface this rule in the targeting UI or allow explicit boss-priority control.

### 10. Simply revealing/selecting a shell activates the swarm

Why it does not make sense:

- The first reveal is also the moment the shell becomes "live" for swarms and
  Manual Overdrive.
- That is a surprising side effect for what looks like a camera/UI action.

Why this matters:

- Players may expect to inspect first and opt into battle second.

Recommended direction:

- Split "view shell" from "start shell" unless instant activation is a core
  onboarding choice.

## Secondary Notes

- Help sections reward Threat Scans once each. This is useful for onboarding,
  but it also incentivizes opening help for currency rather than understanding.
- Kill-gated slot unlocks are global, so high-tier or high-rarity farming can
  accelerate low-tier board access quickly.
- Child shells are expensive and mechanically rich enough that they probably
  deserve their own dedicated tutorial or preview flow.

## Fast File Map

Use this instead of re-scanning the repo:

- Core rules and almost all real gameplay logic:
  `lib/state/lightcore_controller.dart`
- Runtime entity/state definitions:
  `lib/models/lightcore_state.dart`
- Static balance data:
  `lib/data/tower_configs.dart`, `lib/data/enemy_configs.dart`,
  `lib/data/card_configs.dart`, `lib/data/enemy_manager_configs.dart`
- Player-facing help and terminology:
  `lib/screens/lightcore_shell.dart`
- Promotion UI and advancement messaging:
  `lib/screens/prestige_screen.dart`
- Behavior that already has tests:
  `test/overall_progression_and_boss_test.dart`,
  `test/progression_unlocks_test.dart`,
  `test/child_tower_growth_test.dart`,
  `test/manual_overdrive_test.dart`,
  `test/battle_pass_rewards_test.dart`

For a V8 design-bible-to-code map, including implementation status and `rg`
anchors, use `docs/code-design-alignment-map.md`.

## Recommended Next Steps

1. Keep old `Layer2TowerState` internals out of player-facing copy unless
   revived by a future weapon design.
2. Keep Apex Scans framed as the Apex Anomaly pull currency.
3. Keep live/passive archive labels visible anywhere shell state can be changed.
4. Keep promotion-result previews visible before promotion actions.
5. Tighten terminology around anomaly cards so the encounter-building fantasy is
   obvious without reading code.
