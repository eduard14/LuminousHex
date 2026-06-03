part of '../lightcore_shell.dart';

class _EventOfflineBackdrop extends StatelessWidget {
  const _EventOfflineBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            Color(0xFF12283A),
            LightcorePalette.abyss,
            LightcorePalette.night,
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

class _HelpSectionData {
  const _HelpSectionData({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
  });

  final String id;
  final String title;
  final String summary;
  final String body;
}

const List<_HelpSectionData> _baseHelpSections = <_HelpSectionData>[
  _HelpSectionData(
    id: 'mission-briefing',
    title: 'Mission Briefing',
    summary:
        'Why the shell is moving through space and what the swarm really is.',
    body:
        'The Lightcore is navigating fractured sectors and sealing black holes before they grow into stronger singularities. Every shell is a temporary defense ring built to clear the route ahead.\n\n'
        'Anomalies keep mutating as you move deeper into space. That is why new systems come online over time, why Knowledge Cards matter, and why promoted shells must keep pushing forward instead of holding one lane forever.',
  ),
  _HelpSectionData(
    id: 'header-icons',
    title: 'Command HUD',
    summary:
        'What the compact header buttons and resource icons mean in the shell.',
    body:
        'Top action icons:\n'
        '- Storefront opens the Store.\n'
        '- Friends opens friend requests and daily Threat Scan gifts.\n'
        '- Map opens the linear area route and farm-wave controls.\n'
        '- Premium badge opens Passes. A number badge means claimable rewards are waiting.\n'
        '- Settings opens stats, help, and reset controls.\n\n'
        'Status icons:\n'
        '- Leaderboard shows global ranking based on TS.\n'
        '- Trophy shows current TS.\n'
        '- Coin shows current Lumen.\n'
        '- Premium seal shows current Flux.\n'
        '- Circular blur shows current Output Efficiency.\n'
        '- Eye shows which layer you are viewing right now.',
  ),
  _HelpSectionData(
    id: 'battle-basics',
    title: 'Shell Defense Basics',
    summary: 'How the core, relay prisms, and anomalies interact.',
    body:
        'The center tower is the Lightcore. After the shell wakes, shots charge automatically and choose anomaly targets on their own. Core Managers later add auto-fire. The six surrounding towers are relay prisms. They build charge automatically, while tower clicks stay reserved for controls, stats, and upgrades.\n\n'
        'Anomalies spiral inward from beyond the shell. They do not destroy the core directly. Instead they jam the edge hex they hit, slow relay output, and reduce how efficiently the shell harvests Lumens.',
  ),
  _HelpSectionData(
    id: 'focus-fire-lanes',
    title: 'Auto Targeting and Lanes',
    summary:
        'How core charge, automatic targets, and lane pressure fit together.',
    body:
        'Core Stability is the hidden pressure value from 0 to 100. Output Efficiency is the visible multiplier derived from that stability, and Effective Gain is Base Gain x Threat Reward x Output Efficiency.\n\n'
        'Core fire charges automatically. Shots pick live targets from the current wave, while Core Managers automate the firing cadence later. The battle HUD stays focused on wave progress, tower upgrades, and lane pressure instead of ammo queue management.\n\n'
        'A lane is the approach corridor tied to each outer hex. When anomalies break through a corridor, they jam that lane and slow the prism assigned to it. Repeated lane hits shake Core Stability, and Output Efficiency recovers over time through recovery stats and stable builds.',
  ),
  _HelpSectionData(
    id: 'currencies',
    title: 'Resources',
    summary: 'What Lumens, Flux, and Threat Scans are for.',
    body:
        'Lumens are your main tower-building currency. Use them to anchor new prisms and upgrade existing ones. Lumen income scales hardest with active-shell progress, so it is your main growth curve.\n\n'
        'Flux feeds the foundries. The foundry unlocks when a Layer 1 shell has all ${LightcoreController.slotCount} outer towers online, so early Flux is intentionally banked until managers enter the run.\n\n'
        'Threat Scans let you resolve anomaly signatures. Scan income starts slower than Lumen income, so each scan matters more.',
  ),
  _HelpSectionData(
    id: 'enemy-tickets',
    title: 'Threat Scans and Signatures',
    summary: 'How scan level, rarity, and card counts work.',
    body:
        'Anomaly cards represent threat signatures. Spectrum Band defines behavior, like speed or splitting. Rarity defines threat tier, reward potential, and long-term value.\n\n'
        'You spend Threat Scans one at a time or in batches to resolve anomaly signatures. As total scans rise, your scan level increases and higher rarities become possible more often.\n\n'
        'Extra copies strengthen a signature. Once a card hits its rarity cap, extra copies can eventually merge upward into a random card of the next rarity.',
  ),
  _HelpSectionData(
    id: 'tower-shell-terms',
    title: 'Tower and Shell Terms',
    summary: 'Canonical names for shell levels, child towers, and edge slots.',
    body:
        'Root Shell: the first shell class. It contains the center Lightcore plus six perimeter slots.\n\n'
        'Root Shell Core: the center Lightcore while you are in the Root Shell. Its Shell Level and Core Stat Upgrades are separate from the six perimeter towers.\n\n'
        'Shell Level: the level of the active shell core. Root Shell level uses Lumens. Child shell level grows when its child-tower tuning board is completed.\n\n'
        'Shell Class: the tier name of a shell. The current class order is Root Shell, Prism Shell, Nexus Shell, then Ascendant Shell.\n\n'
        'Perimeter Tower: any tower occupying one of the six edge slots around the core. Source Towers and Child Towers are both perimeter towers.\n\n'
        'Source Tower: a buildable Root Shell perimeter tower. Each Source Tower has one Spectrum Band, one projectile family, no payload, a tower level, and a stat board.\n\n'
        'Child Shell: a lower shell built inside a parent perimeter slot. It has its own core, perimeter slots, enemies, and tuning progress.\n\n'
        'Child Tower: the promoted result of a completed Child Shell. It occupies the parent perimeter slot, inherits projectile and payload traits from its Child Shell, and upgrades like a perimeter tower.\n\n'
        'Archived Shell: a completed lower shell that remains inspectable after promotion and can contribute passive support.',
  ),
  _HelpSectionData(
    id: 'projectile-families',
    title: 'Projectile Families',
    summary: 'How Source Towers become aligned projectile and payload traits.',
    body:
        'Every buildable Source Tower is a pure Spectrum Band seed with one projectile family and no payload. Projectile is the delivery method, payload is the hit effect, and Layer 2 components roll those two traits independently from the Layer 1 tower mix. That means a component can resolve into signatures such as Red projectile / Blue payload.\n\n'
        'Default family tracks:\n'
        '- White Starbolt: Starbolt. Payloads: Precision, priority correction, and consistency through managers or alignment history.\n'
        '- Blue Rayline: Thread Beam -> Pulse Beam, Split Beam -> Sweep Beam, Lance Beam, Prism Beam, Sentinel Beam. Payloads: Chill, Fracture -> Deep Chill, Brittle Fracture.\n'
        '- Orange Impact: Heavy Shot -> Breaker Shot, Crush Shot -> Siege Shot, Drill Shot, Ricochet Shot, Hunter Ship. Payloads: Rend, Force -> Core Rend, Concussive Force.\n'
        '- Red Burst: Core Bomb -> Pulse Bomb, Cluster Bomb -> Nova Bomb, Cascade Bomb, Field Bomb, Bomber Ship. Payloads: Overheat, Detonate -> Meltdown, Chain Detonate.\n'
        '- Yellow Arc: Chain Arc -> Fork Arc, Arc Node -> Storm Arc, Web Arc, Sky Arc, Interceptor Ship. Payloads: Shock, Disrupt -> Overload, EMP Disrupt.\n'
        '- Purple Wave: Pulse Ring -> Echo Ring, Collapse Ring -> Halo Wave, Spiral Wave, Warp Wave, Shade Satellite. Payloads: Expose, Pull -> Collapse, Singularity Pull.\n'
        '- Green Shield: persistent Shield Halo, no packet generation -> Sweep Node, Sling Node -> Halo Nodes, Anchor Node, Flail Node, Familiar Ship. Payloads: Corrupt, Spread -> Cascade Corrupt, Viral Spread.\n\n'
        'Projectile and payload colors stay tied to the Layer 1 towers actually used. Pure tower mixes create pure odds; off-color towers add their projectile and payload families to the result pool.',
  ),
  _HelpSectionData(
    id: 'layers-promotion',
    title: 'Shell Classes and Alignment',
    summary: 'How seven lower shells align into one higher shell class.',
    body:
        'A shell is not ready to merge just because all six outer slots are filled. Edge slots unlock from total EXP, beginning at 25, and Root Shell merging also requires every Source Tower to reach level 5. Merging is manual from the Layer 2 Components screen.\n\n'
        'A higher shell is a seven-shell cluster: the source shell plus six edge anchors. Seven Root Shells make a Prism Shell, seven Prism Shells make a Nexus Shell, and seven Nexus Shells make the final Ascendant Shell.\n\n'
        'The first Layer 2 component merge unlocks payload results. Later shell classes deepen projectile and payload pools, but the farmable reward remains the component roll.\n\n'
        'Every active shell can run its own battle simulation. The viewed shell gets direct input, while background shells continue resolving their timers, pressure, and automated output.',
  ),
  _HelpSectionData(
    id: 'targeting-managers',
    title: 'Targeting and Foundries',
    summary: 'How automatic targeting and managers modify behavior.',
    body:
        'Relays no longer carry player-selected target priorities. When a tower contributes charge, the shell automatically weighs range, lane danger, boss pressure, affinity, and expected damage before choosing an anomaly.\n\n'
        'Core Managers assign to a shell and add auto-fire. Each one has an automation rate: if towers charge faster than the manager can fire, the shell loses efficiency while shots wait. Threat Directors attach to Threat Map regions and immediately tune spawn cadence, enemy strength, reward bonuses, EXP, stability risk, and locked farm-wave output. Both manager families unlock after Layer 1 shell coverage.',
  ),
];

List<_HelpSectionData> get _helpSections => <_HelpSectionData>[
  ..._baseHelpSections,
  _HelpSectionData(
    id: 'guide-quest-walkthrough',
    title: 'Guide Quest Walkthrough',
    summary: 'Every tutorial quest, what it teaches, and what to click.',
    body: LightcoreController.tutorialQuestHelpBody,
  ),
];
