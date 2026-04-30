import '../models/lightcore_config.dart';

// TODO(full-game): Replace this local library with downloaded manager
// archetypes so balance patches and live additions can ship independently of
// app code.
class CardLibrary {
  static final fluxCoil = _flow(
    'flux_coil',
    'Whitney Stardust',
    'accuracy, mark strength',
    'Keeps simple towers feeling intentional.',
  );

  static final impactPrism = _power(
    'impact_prism',
    'Reddie Mercury',
    'damage, red adjacency',
    'Your requested red adjacency specialist.',
  );

  static final quickRelay = _tempo(
    'quick_relay',
    'Yella Nova',
    'chain range, shock uptime',
    'Makes lightning feel like smart routing, not random zaps.',
  );

  static final spectrumSeal = _spectrum(
    'spectrum_seal',
    'Greta Greenlight',
    'shield pulse, anti-regen',
    'Turns green into a damaging shield and anti-regen identity.',
  );

  static final anchorArray = _stability(
    'anchor_array',
    'Violet Vortex',
    'ring radius, split control',
    'Helps purple own fragment waves.',
  );

  static final pulseBroker = _pulse(
    'pulse_broker',
    'Orion Orange',
    'impact force, reload timing',
    'Makes orange feel weighty and deliberate.',
  );

  static final overloadLens = _burst(
    'overload_lens',
    'Blueshift Aldrin',
    'laser tracking, jam resistance',
    'Protects laser identity against blue jammer enemies.',
  );

  static final templates = <CardConfig>[
    fluxCoil,
    impactPrism,
    quickRelay,
    spectrumSeal,
    anchorArray,
    pulseBroker,
    overloadLens,
    _stability(
      'mgr_008_barryon_blackwell',
      'Barryon Blackwell',
      'pierce, anti-warp',
      'Lets the player fight warp tanks without making them trivial.',
    ),
    _spectrum(
      'mgr_009_ampere_del_sol',
      'Ampere Del Sol',
      'damage + shock spread',
      'Makes bomb and chain builds talk to each other.',
    ),
    _flow(
      'mgr_010_frostleaf_faye',
      'Frostleaf Faye',
      'slow + shield control',
      'Turns shield and laser builds into a control pair.',
    ),
    _pulse(
      'mgr_011_velvet_impact',
      'Velvet Impact',
      'ring shove + heavy stagger',
      'A combo manager for zoning into heavy shots.',
    ),
    _power(
      'mgr_012_cinder_sprout',
      'Cinder Sprout',
      'DoT + anti-regen',
      'Hard counter to green anomaly waves without being free.',
    ),
    _tempo(
      'mgr_013_speed_of_lightyear',
      'Speed of Lightyear',
      'chain timing + impact force',
      'Gives fast-wave builds a premium timing mini-game.',
    ),
    _spectrum(
      'mgr_014_luna_lens',
      'Luna Lens',
      'beam focus + ring center',
      'Rewards clean placement overlap.',
    ),
    _power(
      'mgr_015_pearl_ignition',
      'Pearl Ignition',
      'marking + burn focus',
      'Simple towers become premium primers.',
    ),
    _stability(
      'mgr_016_nullwave_navigator',
      'Nullwave Navigator',
      'anti-warp + laser lock',
      'A soft answer to attack redirection.',
    ),
    _power(
      'mgr_017_rift_mercury',
      'Rift Mercury',
      'damage + split punisher',
      'Reddie-style aggression with anti-split utility.',
    ),
    _tempo(
      'mgr_018_circuit_aldrin',
      'Circuit Aldrin',
      'chain recalculation + beam uptime',
      'Premium anti-yellow phasing support.',
    ),
    _pulse(
      'mgr_019_grove_driver_gigi',
      'Grove Driver Gigi',
      'siphon + knockback',
      'Makes control feel choreographed.',
    ),
    _spectrum(
      'mgr_020_halo_quinn',
      'Halo Quinn',
      'marking + ring precision',
      'Helps rings feel precise, not fuzzy.',
    ),
    _stability(
      'mgr_021_gravitas_julius',
      'Gravitas Julius',
      'gravity + impact control',
      'Makes orange a boss-control option.',
    ),
    _power(
      'mgr_022_thermal_doctor_ray',
      'Thermal Doctor Ray',
      'burn + beam tracking',
      'Focus-fire boss manager.',
    ),
    _flow(
      'mgr_023_static_fern',
      'Static Fern',
      'shock + anti-regen',
      'Strong answer to regen packs.',
    ),
    _spectrum(
      'mgr_024_prisma_patel',
      'Prisma Patel',
      'rainbow adjacency',
      'Encourages premium mixed hexes.',
    ),
    _stability(
      'mgr_025_dame_eventide',
      'Dame Eventide',
      'husk deletion + anti-warp',
      'Turns two annoying mechanics into a tactical exchange.',
    ),
    _tempo(
      'mgr_026_blink_floyd',
      'Blink Floyd',
      'phase punish + split control',
      'High-skill answer to teleport waves.',
    ),
    _flow(
      'mgr_027_moss_event_horizon',
      'Moss Event Horizon',
      'regen denial + gravity',
      'Counters protected healers.',
    ),
    _burst(
      'mgr_028_sir_isaac_neon',
      'Sir Isaac Neon',
      'laser lock + knockback',
      'A premium focus-then-stagger manager.',
    ),
    _tempo(
      'mgr_029_captain_clearbolt',
      'Captain Clearbolt',
      'marking + chain reliability',
      'Reliability manager for lightning builds.',
    ),
    _pulse(
      'mgr_030_myco_vortex',
      'Myco Vortex',
      'ring control + siphon',
      'Controls fractal regen hybrids.',
    ),
    _burst(
      'mgr_031_major_cinderkick',
      'Major Cinderkick',
      'impact + burn',
      'Weighty control with damage payoff.',
    ),
    _spectrum(
      'mgr_032_professor_paradox',
      'Professor Paradox',
      'rainbow + anti-warp',
      'Rainbow board answer to warp tanks.',
    ),
    _spectrum(
      'mgr_033_vega_v_spectrum',
      'Vega V. Spectrum',
      'all-color harmony',
      'The premium manager for rainbow hex building.',
    ),
    _spectrum(
      'mgr_034_the_primary_directive',
      'The Primary Directive',
      'tri-color command',
      'Makes primary-color cores feel like a planned engine.',
    ),
    _pulse(
      'mgr_035_the_secondary_orbit',
      'The Secondary Orbit',
      'tri-color command',
      'A centerpiece for premium crowd-control boards.',
    ),
    _stability(
      'mgr_036_noir_starling',
      'Noir Starling',
      'contrast command',
      'Simple clarity versus dark-matter chaos.',
    ),
    _power(
      'mgr_037_doctor_deadstar',
      'Doctor Deadstar',
      'burn + anti-regen + singularity',
      'Specialist into brutal late-game blends.',
    ),
    _tempo(
      'mgr_038_the_phase_prosecutor',
      'The Phase Prosecutor',
      'phase + split + warp law',
      'Makes slippery enemies feel legally doomed.',
    ),
    _flow(
      'mgr_039_admiral_permafrost',
      'Admiral Permafrost',
      'slow + impact + clarity',
      'A clean legendary support for tempo boards.',
    ),
    _spectrum(
      'mgr_040_the_singularity_stylist',
      'The Singularity Stylist',
      'prism + gravity',
      'Endgame fashion-and-function manager.',
    ),
  ];

  static CardConfig _flow(String id, String name, String focus, String rule) =>
      _manager(
        id: id,
        name: name,
        roleLabel: 'Flow Manager',
        mechanic: '+30% charge rate. Turns a relay into a packet printer.',
        focus: focus,
        rule: rule,
        powerMultiplier: 1,
        chargeMultiplier: 1.3,
        cooldownMultiplier: 1,
        advantageMultiplier: 1,
        automationRate: 0.62,
      );

  static CardConfig _power(String id, String name, String focus, String rule) =>
      _manager(
        id: id,
        name: name,
        roleLabel: 'Power Manager',
        mechanic:
            '+32% power. Best for slower relays that need clean knockout hits.',
        focus: focus,
        rule: rule,
        powerMultiplier: 1.32,
        chargeMultiplier: 1,
        cooldownMultiplier: 1,
        advantageMultiplier: 1,
        automationRate: 0.46,
      );

  static CardConfig _tempo(String id, String name, String focus, String rule) =>
      _manager(
        id: id,
        name: name,
        roleLabel: 'Tempo Manager',
        mechanic: '-22% cooldown. Smooths packet timing into the core queue.',
        focus: focus,
        rule: rule,
        powerMultiplier: 1,
        chargeMultiplier: 1,
        cooldownMultiplier: 0.78,
        advantageMultiplier: 1,
        automationRate: 0.84,
      );

  static CardConfig _spectrum(
    String id,
    String name,
    String focus,
    String rule,
  ) => _manager(
    id: id,
    name: name,
    roleLabel: 'Spectrum Manager',
    mechanic: '+8% power, +8% charge, +18% bonus on favorable color matchups.',
    focus: focus,
    rule: rule,
    powerMultiplier: 1.08,
    chargeMultiplier: 1.08,
    cooldownMultiplier: 1,
    advantageMultiplier: 1.18,
    automationRate: 0.58,
  );

  static CardConfig _stability(
    String id,
    String name,
    String focus,
    String rule,
  ) => _manager(
    id: id,
    name: name,
    roleLabel: 'Stability Manager',
    mechanic: '+18% power, -12% cooldown for a steady center-fed profile.',
    focus: focus,
    rule: rule,
    powerMultiplier: 1.18,
    chargeMultiplier: 1,
    cooldownMultiplier: 0.88,
    advantageMultiplier: 1,
    automationRate: 0.66,
  );

  static CardConfig _pulse(String id, String name, String focus, String rule) =>
      _manager(
        id: id,
        name: name,
        roleLabel: 'Flow Manager',
        mechanic:
            'Stacks efficient charge routing with weaker direct damage gains.',
        focus: focus,
        rule: rule,
        powerMultiplier: 0.98,
        chargeMultiplier: 1.18,
        cooldownMultiplier: 0.94,
        advantageMultiplier: 1.02,
        automationRate: 0.72,
      );

  static CardConfig _burst(String id, String name, String focus, String rule) =>
      _manager(
        id: id,
        name: name,
        roleLabel: 'Burst Manager',
        mechanic:
            'Leans into bigger packet payloads with slower charge timing.',
        focus: focus,
        rule: rule,
        powerMultiplier: 1.22,
        chargeMultiplier: 0.92,
        cooldownMultiplier: 1.04,
        advantageMultiplier: 1.08,
        automationRate: 0.4,
      );

  static CardConfig _manager({
    required String id,
    required String name,
    required String roleLabel,
    required String mechanic,
    required String focus,
    required String rule,
    required double powerMultiplier,
    required double chargeMultiplier,
    required double cooldownMultiplier,
    required double advantageMultiplier,
    required double automationRate,
  }) {
    return CardConfig(
      id: id,
      name: name,
      summary: '$mechanic Build focus: $focus. $rule',
      flavorBio: _coreManagerBio(
        name: name,
        roleLabel: roleLabel,
        focus: focus,
        rule: rule,
      ),
      roleLabel: roleLabel,
      powerMultiplier: powerMultiplier,
      chargeMultiplier: chargeMultiplier,
      cooldownMultiplier: cooldownMultiplier,
      advantageMultiplier: advantageMultiplier,
      automationRate: automationRate,
    );
  }

  static String _coreManagerBio({
    required String name,
    required String roleLabel,
    required String focus,
    required String rule,
  }) {
    final deskRelic = switch (roleLabel) {
      'Flow Manager' => 'a mug labeled "World\'s Okayest Packet Printer"',
      'Power Manager' => 'a motivational poster that just says "hit it harder"',
      'Tempo Manager' => 'a stopwatch that judges everyone silently',
      'Spectrum Manager' => 'a color wheel with several legal notes attached',
      'Stability Manager' => 'a clipboard full of emergency calm-down forms',
      'Burst Manager' => 'a button marked "probably fine"',
      _ => 'an alarming number of laminated procedures',
    };

    return '$name specializes in $focus and keeps $deskRelic within arm\'s reach. '
        '$rule Their official weakness is being asked to make the core queue less dramatic.';
  }
}
