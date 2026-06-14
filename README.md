# LumiHex

LumiHex is a Flutter + Flame game built around shell-class idle tower-defense.
The current build combines a tap-driven battle shell, tower and manager
progression, enemy-card summoning, and an advancement loop where completed shells
forge higher shell classes.

This project is mobile-first. iOS and Android are the intended product targets.
The web build exists only as a developer test surface and staging harness.

## Current Scope

- Live battle simulation with a central core and six relay towers
- Lumens, Flux, Threat Scan, and Apex Scan economies
- Enemy-card pulls with summoning-level progression
- Tower-manager and enemy-manager inventories
- Root, Prism, Nexus, and Ascendant shell progression
- Guest-session startup with Firebase-backed bootstrap support
- Anonymous cloud sync with Google-linked recovery and callable-only save writes
- Daily and static battle-pass tracks

## Gameplay Loop

The active shell runs the real-time battle. Enemies spiral inward, charged relay
towers feed packets to the core when tapped or when assigned managers automate
their ready taps, and the player spends Lumens to build and upgrade the ring
until all six edge towers are strong enough to promote.

Once a shell is completed, it can be promoted into the next shell class or into
an adjacent parent slot. Seven lower shells form each higher shell cluster: the
source shell plus six edge anchors. Seven Roots make a Prism, seven Prisms make
a Nexus, and seven Nexuses make the final Ascendant Shell. Lower shells remain
available as source shells. Active shells continue their own battle timers and
automated output while the player views another shell.

## Projectile and Promotion Rules

Root prisms are single-color, projectile-only towers. Projectile is the
delivery method. Payload is the hit effect. Projectile and payload are modular,
but each color has a default family track:

- Cyan / Beam: Thread Beam; Pulse Beam, Split Beam; Sweep Beam, Lance Beam,
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
- Purple / Wave: Pulse Ring; Echo Ring, Collapse Ring; Halo Wave, Spiral Wave,
  Warp Wave, Shade Satellite. Payloads: Expose, Pull; Collapse, Singularity
  Pull.
- Green / Orbit: Orbit Node; Sweep Node, Sling Node; Halo Nodes, Anchor Node,
  Flail Node, Familiar Ship. Payloads: Corrupt, Spread; Cascade Corrupt, Viral
  Spread.

Prism promotion unlocks payloads and starts allowing blended signatures such as
Red projectile / Cyan payload on promoted towers and cores. Nexus and Ascendant
shells do not collapse into one dominant projectile anymore. They cycle
recursive projectile and payload arsenals inherited from the promoted child
shells feeding them.

Purity is recursive. If you want a Nexus or Ascendant tower/core to fire only
Pulse Rings and Wave payloads, every promoted child shell beneath it must also
stay Wave-only. One off-pattern child adds its projectile and payload families
to the parent arsenal.

## Tech Stack

- Flutter
- Flame
- Firebase packages for live session/bootstrap integration
- Shared preferences for local session persistence

## Project Layout

```text
AGENTS.md   Standing workflow rules for Codex and other agents
docs/       Product, design, QA, release, and architecture references
assets/     Runtime images, audio, guides, and sprites
functions/  Firebase Functions backend
lib/
  app/        App bootstrap, manifest, and session setup
  battle/     Flame battlefield runtime
  data/       Tower, enemy, manager, and card definitions
  models/     Core gameplay and progression state
  screens/    Landing, battle, tower, enemy, manager, and advancement UI
  state/      Local game authority and progression logic
  theme/      Visual system
  widgets/    Shared UI components
tool/       Local asset-generation and import scripts
web/          Web shell assets
```

Start with [docs/README.md](docs/README.md) for the documentation map and
[lib/README.md](lib/README.md) for the Dart source map.

## Gameplay Reference

Use [docs/gameplay-mechanics-audit.md](docs/gameplay-mechanics-audit.md) for a
current summary of the implemented gameplay loop, economy, promotion rules, and
the mechanics that are most likely to need redesign.

Use [docs/code-design-alignment-map.md](docs/code-design-alignment-map.md) when
checking the code against the V8 design bible. It maps workbook systems to
concrete Dart and Cloud Functions symbols and calls out known alignment risks.

Use [docs/versioning.md](docs/versioning.md) when bumping app versions across
Flutter metadata, backend gates, menu display fixtures, and deployment checks.

## Running Locally

```bash
flutter pub get
flutter run -d ios
```

Other useful commands:

```bash
flutter analyze
```

For Android development:

```bash
flutter run -d android
```

For browser-only testing:

```bash
flutter run -d chrome
```

To jump into a higher shell while testing a debug web run, add `?devLayer=3`
or pass `--dart-define=LIGHTCORE_DEV_LAYER=3`. The jump is debug-only and
cloud save is disabled for that run.

## Backend Deploys

Cloud Functions and Firestore deploys should explicitly target
`lumicore-95c8a` so they cannot accidentally publish to another Firebase
project selected in the local CLI session.

```bash
cd functions
npm run deploy
```

The checked-in backend uses Firebase Functions v2 on Node.js 22 and stores
runtime profile, cloud-save, idle-progress, and tournament state in Firestore.

## Web Test Surface

Firebase Hosting can continue to serve the web build as a staging surface, but
it is not the primary release target for this project.

## Product Limitations

A few systems are live but still need hardening before a fully authoritative
production release:

- Persistent profile storage, anonymous cloud sync, and Google-linked recovery
  are wired, but active battle simulation still runs locally between autosaves
- Offline catch-up is estimated from managed towers and claimed server-side
- Cloud saves are sanitized, revision-checked, and integrity-logged by callable
  Functions; full server-authoritative live-battle replay is still planned
- Premium purchases and some live-ops flows still need store/provider wiring

## Status

The app is positioned as a mobile-first LumiHex build with Firebase-backed
profile, cloud-save, idle-progress, social, and tournament services. Remaining
work is production hardening, balance tuning, and asset/audio completion.
