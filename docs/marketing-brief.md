# LumiHex Marketing Brief

Last updated: 2026-06-04

This is the source-of-truth marketing handoff for LumiHex. Update it whenever
player-facing features, naming, story, monetization, screenshots, or asset needs
change enough that store copy, social posts, landing pages, trailers, or press
materials would become stale.

## Brand Snapshot

| Field | Current Direction |
| --- | --- |
| Public app name | LumiHex |
| Preferred subtitle | Prism Relay |
| Full marketing title | LumiHex: Prism Relay |
| Developer / splash credit | Lemon Goose Games Inc. |
| Genre | Mobile idle tower defense with hex-shell progression |
| Platforms | iOS and Android planned; web is a staging/test surface |
| Monetization model | Free-to-play with rewarded ads, Prism Shard packs, capped bundles, battle-pass style tracks, and premium membership scaffolding |
| Brand rule | LumiHex is the public game name. Lightcore is the in-world core object. Lumicore should be treated as backend/project residue, not a public brand. |

## One-Line Pitch

Rebuild a fractured Lightcore by charging hex relays, shaping anomaly waves,
and promoting each completed shell into a deeper prism lattice.

## Short Description

LumiHex is a mobile-first idle tower-defense game where the battlefield is a
six-relay hex shell around a central Lightcore. Towers auto-charge shots,
focus anomaly encounters, collect managers, and
promote Root Shells into Prism, Nexus, and Ascendant structures.

## Player Fantasy

The Lightcore has fractured into unstable hex shells. Anomalies spiral inward,
draining stability and lowering output. The player rebuilds the lattice one
relay at a time, turns enemy pressure into progression, and forges completed
shells into higher-order prism structures.

Marketing tone should be clear and energetic, not lore-heavy. The story exists
to explain the loop: build relays, defend the core, shape anomalies, merge
Layer 1 towers into Layer 2 components, lock better farm waves, and keep
climbing.

## Core Gameplay Loop

1. Enter a hex shell built around the central Lightcore.
2. Reveal the first perimeter hex immediately and build the opening relay.
3. Let the core and relay towers auto-charge shots while the shell chooses
   anomaly targets automatically.
4. Upgrade the first tower from its controls as the next action.
5. Clear wave milestones to unlock the remaining perimeter relay towers:
   Hex 1 at Wave 1, Hexes 2-3 after Wave 5, and Hexes 4-6 after Wave 10.
6. Spend wave-earned Layer 1 Wave Cores to open/build the shell, then spend
   kill-earned Lumens on combat upgrades like range, fire speed, multi-shot,
   and tower damage tuning.
7. Roll Threat Scans into Knowledge Cards that make enemy families easier
   to understand and farm.
8. Follow the fixed Threat Map route, clear higher waves in each area, then lock
   the best completed farm wave for offline rewards.
9. Defeat normal anomalies to prime Apex Anomaly encounters.
10. Merge completed Layer 1 shells into Layer 2 components with independent
   projectile and payload rolls, wave-based Layer 2 levels, and random subtraits.
11. Equip farmed Layer 2 components to Threat Map areas, upgrade standout rolls
   with Component Scrolls from Layer 2+ boss clears, and dismantle bad rolls
   into more scrolls.
12. Return to older shells as passive support archives while the live shell grows.
13. Expand into managers, daily dungeons, tournaments, and social play.

## Feature Inventory

### Battle And Defense

- Real-time hex battlefield with one central Lightcore and six relay towers.
- Relay towers charge shots into the Lightcore instead of asking the player to
  manually queue or drag ammo.
- Opening combat is low-friction: shots auto-charge after the player presses Play,
  Hex 1 is immediately selectable, and generated shots auto-target anomalies
  without a tap-to-queue requirement.
- The first battle view now opens with focused pre-Play chrome: a centered
  animated Start Route control, a compact play prompt, reduced top/bottom HUD
  noise, and pre-battle route/anomaly energy on the canvas.
- Anomalies enter from randomized points outside the battle radius instead of
  uniform lanes, then move inward faster with a subtler spiral.
- The first tower/auto-target/upgrade loop grants enough starter Lumens to move
  from build to the first upgrade without idle grinding.
- Opening waves now escalate mechanically: Wave 2 strengthens normal anomalies
  and bruises Hex 1 plus Output Efficiency if the first tower is still
  unupgraded, making the first upgrade feel necessary instead of decorative.
- Clearing Wave 1 now grants persistent Layer 1 round currency. That first
  payout opens the remaining five Layer 1 tower slots, so early expansion comes
  from a persistent round reward instead of waiting on later milestone gates.
- The opening shell starts with Hex 1, then uses the Wave 1 round-currency
  payout to open Hexes 2-6 for the rest of Layer 1.
- Wave 10 creates the Layer 2 level 1 seed target, but the player still needs a
  full shell before merge: all six outer towers built and stat boards tuned.
- Challenge prompts and active challenge HUD now show the harder enemy level,
  active swarm count, and Lumen reward preview; starter challenge waves raise
  both enemy level and active enemy pressure so the "new area is harder" beat is
  mechanical, not tutorial copy.
- Layer 1 now exposes a Component Forecast in battle, tower management, and the
  Layer 2 Components screen so players can see current projectile odds, payload
  odds, best wave, Layer 2 level, and expected subtraits before merging.
- The Component Forecast now shows the key wave milestones directly: Wave 5
  farm lock, Wave 10 Layer 2 Lv 1, Wave 15 stronger seed, and Wave 25
  3-subtrait rolls.
- The battlefield now keeps a compact wave HUD visible, including the early
  `Wave 10 -> Layer 2 Lv 1` seed goal, so the Layer 1 push has a clear target.
- The wave HUD also shows unlocked hex coverage and the full-shell merge
  requirement so Wave 10 cannot be mistaken for an instant merge.
- Selecting a built tower now opens its level and rolled stat upgrade board on
  the battlefield, making fire-rate, damage, range, multishot-adjacent, and
  other wave-by-wave upgrades visible without hunting through a detail modal.
- Battlefield upgrade controls now use compact command docks with stat chips
  and grid actions, keeping tower/core tuning readable while leaving more of
  the active battle visible.
- Layer 1 battle docks now expose Wave Cores beside Kill Lumens, remove the
  ambiguous Buffer control from the first shell, and hide side controls while
  the selected upgrade dock is open.
- Core upgrade docks now hold a stable compact height and move dense combat
  values into a Full Stats popup so live wave progress does not make the menu
  bounce.
- Layer 1 battle upgrade docks now prioritize spendable currencies and upgrade
  actions; secondary values like current wave, core level, output, stat-board
  count, and Layer 2 seed level live behind Full Stats instead of crowding the
  live combat dock.
- Selecting the Lightcore opens persistent core upgrades directly and separates
  shell-wide core growth from Layer 1 tower stat rolls.
- The Lightcore control panel can expose charged-shot queue order controls when
  shots are waiting, letting active players move generated shots earlier or
  later before firing.
- Layer 1 merges now hand the created Layer 2 component into the promotion
  result surface, showing the rolled projectile, payload, Layer 2 level,
  source wave, farm-output value, subtraits, favorite action, and area
  assignment control.
- Layer 2 Components now have a production inventory: players can sort farmed
  rolls, favorite keepers, assign one component per revealed Threat Map area,
  upgrade them with Component Scrolls, and dismantle unwanted rolls.
- Layer 2+ Apex clears award Component Scrolls alongside boss rewards, tying
  active boss farming to long-term region output without adding prestige.
- The post-upgrade threat prompt explains the payoff and highlights the push
  action directly, including harder-enemy framing and the Lumen reward preview,
  so the next step reads as an earned push instead of a menu hunt.
- Tutorial systems are intentionally disabled while the first two layers are
  being rebuilt; production teaching will be redesigned after the core loop is
  stable.
- Unspent Radiance points stay available in Profile without blocking the first
  tower-upgrade-to-wave-push expansion loop.
- The opening resource rail keeps Lumens and Output Efficiency legible while
  battle state stays focused on wave, selected tower, challenge, and upgrades.
- Tower badges use projectile color and hex-edge level progress only; payload
  tinting is kept out of the first-session visual language until payload traits
  are explicitly taught later.
- Battle canvas input prioritizes visible anomaly focus before tower control hit
  tests, so aiming at enemies does not compete with opening tower panels.
- Tower hit zones now stay tighter around the visible relay bodies and avoid the
  central Lightcore edge, so core clicks near the center do not accidentally
  open tower controls.
- Red tower badges use a comet-shaped projectile glyph, not a circular marker
  that can read as a numeric level.
- First-session battle HUD panels hide empty payload rows and payload sub-pips,
  keeping the early combat read focused on projectile choice, wave progress,
  tower upgrades, and auto-targeted anomaly pressure.
- Manager-less shells now call the opening state Auto Targeting instead of
  Focus Fire or Manual Command, and core stats separate charge-buffer capacity
  from shell completion.
- The first tower timer is presented as Building and Online instead of
  fabrication jargon, keeping the opening loop action-oriented.
- Player-facing guidance uses auto-targeting language for battlefield, tower,
  and detail interactions so the opening does not read like an old tap-to-queue
  mobile chore loop.
- Manual Overdrive appears from the underlying combat unlocks instead of being
  hidden behind tutorial state.
- Clearing starter Wave 5 pays enough Lumens for the next anchor-tower stat
  tune, so the first combat loop chains directly into a stronger lane
  instead of asking for a grind pause.
- Hexes 2 and 3 wait until Wave 5 is cleared; Hexes 4-6 wait until Wave 10 is
  cleared, keeping tower expansion connected to the pressure-upgrade-repeat
  loop instead of allowing a full shell immediately.
- Tower body clicks are reserved for tower controls, upgrades, and stats,
  keeping build/stat actions distinct from automated combat targeting.
- Battlefield hex slots now render as subdued HUD frames underneath anomalies,
  so enemy bodies remain the top combat read when they cross the tower grid.
- Tower slot collision plus core and selected-tower range previews now use the
  same hex geometry as the HUD frames instead of circular tower footprints.
- Active waves default to the expanded relay shell so tower collision
  footprints, lanes, and hex slots stay visible.
- Active battle also supports a manual folded-shell long-run view from the
  shell visibility HUD, without the old pre-battle route-energy arcs or extra
  decorative field marks.
- Battle tower center glyphs now show projectile shape while using payload
  color; no-payload Layer 1 towers fall back to the tower color, and the basic
  projectile reads as a simple circle instead of an abstract slash.
- Core shots do not orbit as collectible-looking field objects; only brief
  handoff effects appear when a relay charges the core.
- Payload-colored orbit dots are kept out of shot, relay, and fire-burst
  visuals so early combat does not imply there are floating payloads to manage.
- Child-shell presence is shown through hex bodies, range language, and
  promotion moments, not orbiting marker dots around the active core.
- The battlefield no longer shows a ready-shot counter during normal Layer 1
  play; the visible combat read is wave, focus, and tower upgrades.
- Opening core controls suppress meta/buildcraft rows such as Ring, Slots, TS,
  EXP, crit, final damage, and penetration so the first panel stays readable.
- Opening area-push challenges keep a compact live battle HUD on screen that
  names the harder enemy wave, shows progress, and points the player back to
  upgrading Hex 1 after the wave clears.
- The first two area-push challenges are shortened into brisk pressure spikes
  so the opening loop reaches the Wave 5 and Wave 10 milestones quickly instead
  of asking the player to wait through full-length region timers.
- Shell visibility is an explicit HUD toggle, keeping battlefield taps from
  folding the active battlefield or opening tower placement.
- Manager automation upgrades core fire into hands-off target routing without
  adding manual target overrides.
- Combat rewards charge cadence, tower placement, and keeping lanes stable.
- Output Efficiency pressure system replaces a simple health-loss fail state.
- Lane disruption reduces rewards and Tower Health when anomalies reach the ring.
- Manual Overdrive accelerates the live shell battle.
- Automatic targeting briefly prioritizes dangerous anomalies during active
  challenges and live farming.
- Lumo/Luma loading interstitials can show short non-blocking flavor tips such
  as balancing growth, Tower Health, and Output Efficiency.
- Screen transitions, event-run loading, and major shell area transitions use the
  same fullscreen branded Lightcore loading interstitial with generic loading
  status, Lumo/Luma background art, and short tip text. App startup shows
  only the Lemon Goose Games Inc. splash before revealing the LumiHex main menu.

### Towers And Builds

- Seven Source Tower families: White, Red, Orange, Yellow, Green, Blue, Purple.
- Tower families support distinct projectile identities such as Starbolt,
  Burst, Impact, Arc, Shield, Rayline, and Wave.
- Towers roll trainable stat boards and special upgrade traits.
- Core stats can be upgraded separately from perimeter towers.
- Core Managers assign to a shell, upgrade auto-fire, and raise passive output.
  Common Core Manager cards use identity tiles instead of
  generated-style portrait art.
- Pattern bonuses reward certain tower arrangements and shell build choices.

### Shell Progression

- Root Shell, Prism Shell, Nexus Shell, and Ascendant Shell progression.
- Completed shells promote into higher shell classes.
- Child shells can be forged into parent-slot child towers.
- Higher-tier cores and towers inherit projectile and payload history from
  promoted child shells.
- Live/passive shell state makes older shells inspectable while they support the
  active build.
- Layer 1 merges create a long-term buildcraft layer around purity, blended
  projectile/payload colors, wave-tiered component stats, and random subtraits.

### Anomalies And Encounter Tuning

- Threat Scans unlock Knowledge Cards and add research copies.
- Knowledge Cards are enemy-family knowledge and combat progression, not
  friendly units.
- Threat Map regions define the main enemy progression path as a fixed linear
  route with visible connections between each step.
- The next Threat Map region opens as players clear the current route's required
  waves and boss checks.
- Region challenges are short wave pushes with isolated combat pressure and a
  per-wave timer: no EXP, upgrade spending, or notification clutter during the
  run.
- Region intel dialogs now act as the Layer 2 area command surface, showing the
  next wave, best farm wave, locked offline output, assigned component,
  Threat Director, and boss-only equipment source before the player chooses
  Start Wave or Lock Farm Wave.
- Farm-wave locking records the best completed wave for that region/director
  setup and determines offline output until the player pushes and locks higher.
- Swarm Magnet controls the account-wide farming swarm size and can be rerolled
  with dedicated currency.
- Threat Directors tune the selected region's current spawn cadence, enemy
  strength, reward bonuses, EXP, stability risk, farm wave cadence, and Apex
  behavior.
- Apex Anomalies spawn after normal anomaly progress and grant larger rewards.
- Threat Map and regional challenge surfaces frame anomaly pressure by region.
- Starter-region Wave 5 now starts automatically after early overmatch, turning
  the first tower tune into immediate added pressure without covering the first
  tower hex or bottom browser chrome.
- The compact battle Component Forecast appears once the shell has useful
  Layer 1 context, and the full forecast is available on Tower Management and
  Layer 2 Components for deliberate build planning.

### Progression And Rewards

- Lumens fuel tower construction, upgrades, and core growth.
- Flux supports manager forging and related systems.
- Threat Scans feed Knowledge Card pulls.
- Apex Scans feed Apex Anomaly pulls and social gifts.
- Locked region farm waves determine offline rewards from elapsed sign-in time,
  Threat Director multipliers, and that wave's enemy output.
- Account Radiance tracks broader player growth.
- Global Total Strength leaderboard previews the player's rank immediately from
  local tower changes while the public board refreshes periodically.
- Battle-pass style tracks reward daily kills, manager pulls, and scans.
- Offline rewards are server-reconciled and can be doubled with rewarded ads.
- Daily Dungeons and Prism Rift content create repeatable challenge surfaces.
- Weekly tournaments include Anomaly Blitz, Hex Gauntlet, and Arena Flow modes.
- Dev-only event preview URLs exist for dungeon and tournament QA in web debug
  builds. They are not a production route or marketing claim.
- Release readiness for backend maintenance, balance QA, and chat moderation is
  tracked in `docs/release-readiness.md`.

### Social And Live-Ops

- Anonymous guest startup with Firebase-backed cloud-save support.
- Google-linked and email/password recovery with Apple ID placeholders reserved
  for the release auth pass.
- Friends, requests, and daily Apex Scan/Threat Scan gift flows.
- Global chat lives in the social screen with 24-hour message retention,
  whispers, spam warnings, 24-hour chat bans, repeat-offense account bans, and
  instant blocking for tracked bot-message repeats.
- Space Room is hidden from the current release surface.
- Mentorship with mentor, mentee, and branch-context surfaces.
- Guilds are hidden from the current release surface and should appear only as
  coming-soon social copy until the live guild loop is complete.
- Store, Prism Shard packs, bundles, boosts, and Premium Membership
  scaffolding exist, but production purchase wiring still needs release hardening.
- Rewarded ad placements exist for mobile builds, but current checked-in ad IDs
  are test IDs.

## Audience

Primary players:

- Mobile tower-defense players who like progression and upgrades.
- Idle/incremental players who want active moments without constant precision.
- Buildcraft players who enjoy color affinities, inherited traits, managers,
  and long-term optimization.

Secondary players:

- Casual strategy players who like clear loops and daily rewards.
- Collection-driven players interested in Knowledge Cards, managers, passes, and
  event rewards.

## Store And Landing Page Angles

Use these as starting points for App Store copy, landing sections, or short
video hooks.

- Auto-charge the core. Focus the anomaly. Hold the hex.
- Your towers do not just shoot; they power the Lightcore.
- Build a Root Shell, promote it, and forge a deeper prism lattice.
- Research anomaly families with Threat Scans, then push forward on the fixed
  Threat Map route.
- Reroll Swarm Magnet pressure and validate farms for stronger offline gains.
- Turn completed shells into inherited power for Prism, Nexus, and Ascendant
  builds.
- Automate your relays with managers and keep earning while offline.
- Enter daily dungeons, tournaments, and Apex anomaly challenges.
- Optimize purity or blend projectile and payload histories across generations.

## Social Content Pillars

| Pillar | Post Ideas |
| --- | --- |
| Gameplay hook | Short clips of tower charge feeding the Lightcore, tower controls opening cleanly, and shots auto-targeting anomalies. |
| Progression | Before/after shell promotion, Root to Prism, Prism to Nexus, inheritance previews. |
| Buildcraft | Color-family comparisons, pure builds versus blended projectile/payload builds. |
| Anomaly pressure | Knowledge Card pulls, Apex Anomaly reveals, auto-target saves, lane disruption moments. |
| Rewards | Offline gains, pass claims, tournament rewards, and event progress. |
| Studio identity | Lemon Goose Games Inc. splash, dev updates, patch notes, asset reveals. |

## App Store Screenshot Set

Suggested first release order:

1. Main battle screen: six relays around the Lightcore with anomalies incoming.
2. Tower upgrade screen: trainable stats and tower family identity.
3. Knowledge Cards/Threat Map screen: show research progression and region push.
4. Promotion screen: Root Shell to Prism Shell or child tower forge.
5. Managers/profile screen: automation and account progression.
6. Daily Dungeons or Tournament screen: repeatable events and competitive modes.
7. Store/pass screen only after real purchase wiring and final economy review.

## Trailer Beats

1. Lemon Goose Games Inc. splash.
2. Fractured Lightcore premise in one short text card.
3. First relay comes online, player clicks an anomaly, and the next auto-charged
   shot fires there.
4. Anomalies spiral inward and disrupt lanes.
5. Threat Scan pull reveals a new Knowledge Card.
6. Region challenge and farm-wave lock pressure.
7. Apex Anomaly arrival.
8. Shell promotion into a higher prism structure.
9. Managers automate relays and validated offline rewards land.
10. Daily dungeon/tournament tease.
11. Logo/title card: LumiHex: Prism Relay.

## Visual Direction

- Use luminous sci-fi, hex geometry, prism refraction, and clean dark UI.
- Show actual gameplay, not abstract gradients, whenever explaining the product.
- Keep the central Lightcore and six-relay structure recognizable in key art.
- Use color families as marketing shorthand: Red Burst, Blue Rayline, Purple
  Wave, Green Shield, Yellow Arc, Orange Impact, White Starbolt.
- Avoid implying a traditional base-health survival game unless a true fail
  state is added.

## Claims To Avoid Until Implemented Or Finalized

- Do not claim production IAPs are live until platform purchase wiring is done.
- Do not claim ad monetization is live until test ad IDs are replaced.
- Do not claim web is a release platform; web is currently staging/test only.
- Do not call enemy cards friendly units, heroes, summons, or allies.
- Do not describe Knowledge Cards as friendly units, heroes, or allies.
- Do not describe Threat Scans as a Threat Map reveal or area-clear mechanic.
- Do not imply every shell runs a full battle simulation while offline.
- Do not describe offline rewards as passive tower income; they come from
  validated region/director farm calculations.
- Market equipment narrowly as boss-only Layer 2+ drops; do not imply normal
  farm waves drop full equipment.
- Do not market guilds as a launch feature until the live guild loop is complete.
- Do not use Lumicore as a public title or franchise name.
- Do not imply IAP, production sign-in, or platform purchases are ready before
  app-store submission wiring exists.

## Current Marketing Asset Needs

- Lemon Goose Games Inc. splash treatment for all platforms.
- LumiHex logo or final renamed title lockup.
- App icon master that reads clearly at small mobile sizes.
- Key art showing the central Lightcore, six relays, and incoming anomalies.
- Short portrait gameplay clips for TikTok/Reels/Shorts.
- App Store and Play Store screenshots after final naming pass.
- Feature graphic for Google Play.
- Social templates for update notes, feature reveals, and event reminders.

## Maintenance Checklist

Update this document when any of these change:

- Public game name, subtitle, studio credit, or store positioning.
- Any new player-facing feature or removed/renamed feature.
- Gameplay loop, story premise, currencies, progression classes, or enemy terms.
- Monetization claims, real-money products, ad placements, or subscription rules.
- Social/live-ops state, tournaments, events, dungeons, guilds, or account systems.
- Screenshot order, trailer beats, asset needs, or claims to avoid.
