import '../models/lightcore_config.dart';

// TODO(full-game): Replace this local library with downloaded manager
// archetypes so balance patches and live additions can ship independently of
// app code.
class CardLibrary {
  static final whitneyStardust = _flow(
    'mgr_001_whitney_stardust',
    'Whitney Stardust',
    'accuracy, mark strength',
    'Adjacent white/basic towers gain cleaner priority picks.',
    'Keeps the board honest by making simple towers feel intentional.',
    'Whitney audits every shot like a starship launch checklist. She believes basic does not mean boring, and her crews love her for turning clean fundamentals into wins.',
  );
  static final reddieMercury = _power(
    'mgr_002_reddie_mercury',
    'Reddie Mercury',
    'damage, red adjacency',
    'Gains bonus damage for each adjacent red tower; extra bonus at a full red hex.',
    'Your requested red adjacency specialist.',
    'Reddie performs every battle like an arena concert, cueing red towers to hit the same chorus at the same time. The louder the red cluster gets, the harder the finale lands.',
  );
  static final yellaNova = _tempo(
    'mgr_003_yella_nova',
    'Yella Nova',
    'chain range, shock uptime',
    'Adjacent yellow towers get longer chain reach after the first jump.',
    'Makes lightning feel like smart routing, not random zaps.',
    'Yella grew up racing lightning across satellite farms. She talks fast, thinks faster, and treats every chain as a route through rush-hour space traffic.',
  );
  static final gretaGreenlight = _spectrum(
    'mgr_004_greta_greenlight',
    'Greta Greenlight',
    'orbit duration, anti-regen',
    'Green towers orbit longer and tag regenerating enemies more aggressively.',
    'Turns green from passive orbit into anti-regen identity.',
    'Greta keeps a greenhouse inside her command pod and names every moonlet. She is sweet until a regen enemy shows up; then the vines come out.',
  );
  static final violetVortex = _stability(
    'mgr_005_violet_vortex',
    'Violet Vortex',
    'ring radius, split control',
    'Purple rings gain radius when they hit newly split enemies.',
    'Helps purple own fragment waves.',
    'Violet conducts gravity like music, expanding ring waves with perfect timing. She never raises her voice; the universe simply echoes for her.',
  );
  static final orionOrange = _pulse(
    'mgr_006_orion_orange',
    'Orion Orange',
    'impact force, reload timing',
    'Orange heavy shots gain stagger after waiting a full reload cycle.',
    'Makes orange feel weighty and deliberate.',
    'Orion measures courage in recoil marks. He teaches crews to wait, breathe, and fire one shot so heavy the lane remembers it.',
  );
  static final blueshiftAldrin = _burst(
    'mgr_007_blueshift_aldrin',
    'Blueshift Aldrin',
    'laser tracking, jam resistance',
    'Blue towers reacquire faster after disabled or interrupted.',
    'Protects laser identity against blue jammer enemies.',
    'Blueshift is a calm spacewalker who repairs beams mid-combat. He has seen enough ion storms to know panic is just another thing to route around.',
  );

  static final templates = <CardConfig>[
    whitneyStardust,
    reddieMercury,
    yellaNova,
    gretaGreenlight,
    violetVortex,
    orionOrange,
    blueshiftAldrin,
    _stability(
      'mgr_008_barryon_blackwell',
      'Barryon Blackwell',
      'pierce, anti-warp',
      'Adjacent towers gain small resistance to attack redirection from black enemies.',
      'Lets the player fight warp tanks without making them trivial.',
      'Barryon studies black holes like other people read comics. He is polite, heavy, and somehow always standing exactly where projectiles stop bending.',
    ),
    _spectrum(
      'mgr_009_ampere_del_sol',
      'Ampere Del Sol',
      'damage + shock spread',
      'Red towers next to yellow towers add tiny shock sparks to blast survivors.',
      'Makes bomb and chain builds talk to each other.',
      'Ampere is a solar electrician who can wire a sunspot into a doorbell. His favorite phrase is \'just enough voltage to be funny.\'',
    ),
    _flow(
      'mgr_010_frostleaf_faye',
      'Frostleaf Faye',
      'slow + orbit control',
      'Green and blue towers share a small slow bonus when covering the same lane.',
      'Turns orbit and laser builds into a control pair.',
      'Faye cultivates ice flowers that bloom only under laser light. Her lab smells like mint and ozone, and her timing is terrifyingly exact.',
    ),
    _pulse(
      'mgr_011_velvet_impact',
      'Velvet Impact',
      'ring shove + heavy stagger',
      'Purple rings slightly empower the next orange impact on enemies they touched.',
      'A combo manager for zoning into heavy shots.',
      'Velvet was a zero-g percussionist before she became a tactician. She still calls every knockback a drum fill.',
    ),
    _power(
      'mgr_012_cinder_sprout',
      'Cinder Sprout',
      'DoT + anti-regen',
      'Burning enemies receive weaker regen while inside green orbit paths.',
      'Hard counter to green enemy waves without being free.',
      'Cinder Sprout keeps a campfire in a terrarium. They are gentle, practical, and weirdly good at making hostile biology give up.',
    ),
    _tempo(
      'mgr_013_speed_of_lightyear',
      'Speed of Lightyear',
      'chain timing + impact force',
      'Yellow chains mark enemies for the next orange heavy shot.',
      'Gives fast-wave builds a premium timing mini-game.',
      'Lightyear sells impossible engines and somehow delivers every one on time. He never walks anywhere when a dramatic slide will do.',
    ),
    _spectrum(
      'mgr_014_luna_lens',
      'Luna Lens',
      'beam focus + ring center',
      'Blue lasers gain bonus focus against enemies inside purple ring centers.',
      'Rewards clean placement overlap.',
      'Luna designs lenses for eclipses that have not happened yet. She speaks softly because her glass is always listening.',
    ),
    _power(
      'mgr_015_pearl_ignition',
      'Pearl Ignition',
      'marking + burn focus',
      'White marks make the first red burn tick stronger.',
      'Simple towers become premium primers.',
      'Pearl treats every battle like lighting a ceremonial star. Nothing goes boom until the ribbon is straight.',
    ),
    _stability(
      'mgr_016_nullwave_navigator',
      'Nullwave Navigator',
      'anti-warp + laser lock',
      'Blue beams keep target lock slightly longer when black enemies warp attacks.',
      'A soft answer to attack redirection.',
      'Nullwave charts safe routes through places maps refuse to draw. He laughs at impossible angles because they usually owe him money.',
    ),
    _power(
      'mgr_017_rift_mercury',
      'Rift Mercury',
      'damage + split punisher',
      'Red damage ramps on enemies recently hit by purple ring pulses.',
      'Reddie-style aggression with anti-split utility.',
      'Rift Mercury headlines in shattered theaters at the edge of a nebula. Every encore leaves fewer fragments than it found.',
    ),
    _tempo(
      'mgr_018_circuit_aldrin',
      'Circuit Aldrin',
      'chain recalculation + beam uptime',
      'Yellow shock improves blue beam retarget speed after a miss or blink.',
      'Premium anti-yellow/phasing support.',
      'Circuit Aldrin was the first to walk a maintenance beam across a thundercloud. He still signs autographs on insulated gloves.',
    ),
    _pulse(
      'mgr_019_grove_driver_gigi',
      'Grove Driver Gigi',
      'siphon + knockback',
      'Orange impacts push enemies back into green orbit paths.',
      'Makes control feel choreographed.',
      'Gigi grows trees in railgun barrels, which everyone agrees is unsafe until it works. Her orchards have recoil permits.',
    ),
    _spectrum(
      'mgr_020_halo_quinn',
      'Halo Quinn',
      'marking + ring precision',
      'White-marked enemies take cleaner hits from purple ring edges.',
      'Helps rings feel precise, not fuzzy.',
      'Halo Quinn is a stage magician who uses orbit maps instead of cards. The trick is always geometry, but nobody catches the second circle.',
    ),
    _stability(
      'mgr_021_gravitas_julius',
      'Gravitas Julius',
      'gravity + impact control',
      'Black-affinity towers add mass to orange shots, improving stagger against elites.',
      'Makes orange a boss-control option.',
      'Gravitas conquered exactly zero planets and still insists on wearing a cape. His speeches are long; his projectiles are longer.',
    ),
    _power(
      'mgr_022_thermal_doctor_ray',
      'Thermal Doctor Ray',
      'burn + beam tracking',
      'Blue lasers increase burn tick speed while continuously held.',
      'Focus-fire boss manager.',
      'Doctor Ray prescribes heat with clinical confidence. His bedside manner is terrible, but even red dwarfs respect his follow-through.',
    ),
    _flow(
      'mgr_023_static_fern',
      'Static Fern',
      'shock + anti-regen',
      'Shock charges briefly pause regen bursts when green towers are nearby.',
      'Strong answer to regen packs.',
      'Static Fern is a gardening prodigy who insists lightning is just weather with opinions. Her plants agree and spark politely.',
    ),
    _spectrum(
      'mgr_024_prisma_patel',
      'Prisma Patel',
      'rainbow adjacency',
      'Different adjacent tower colors grant stacking micro-bonuses up to six colors.',
      'Encourages premium mixed hexes.',
      'Prisma balances crews like a constellation chart, giving every color a reason to sit at the table. She never picks favorites; the prism does that for her.',
    ),
    _stability(
      'mgr_025_dame_eventide',
      'Dame Eventide',
      'husk deletion + anti-warp',
      'Red towers under her command consume one husk faster when a black enemy is present.',
      'Turns two annoying mechanics into a tactical exchange.',
      'Eventide hosts tea parties inside disaster zones. Her manners are flawless, and so is the moment she asks a dead star to leave.',
    ),
    _tempo(
      'mgr_026_blink_floyd',
      'Blink Floyd',
      'phase punish + split control',
      'Phasing enemies that blink through purple rings return with shock instability.',
      'High-skill answer to teleport waves.',
      'Blink Floyd plays tactical light shows for enemies that think they can dodge. The finale is always exactly where they blinked.',
    ),
    _flow(
      'mgr_027_moss_event_horizon',
      'Moss Event Horizon',
      'regen denial + gravity',
      'Green anti-regen effects gain strength against enemies protected by black warp tanks.',
      'Counters protected healers.',
      'Moss speaks in slow riddles and grows vines around singularities. Nobody knows if they are patient or simply operating on tree time.',
    ),
    _burst(
      'mgr_028_sir_isaac_neon',
      'Sir Isaac Neon',
      'laser lock + knockback',
      'Blue beams charge orange impacts on the same target.',
      'A premium focus-then-stagger manager.',
      'Sir Isaac Neon discovered that motion laws are more fun when they glow. He drops apples from orbit for calibration.',
    ),
    _tempo(
      'mgr_029_captain_clearbolt',
      'Captain Clearbolt',
      'marking + chain reliability',
      'Marked enemies become preferred chain anchors for yellow towers.',
      'Reliability manager for lightning builds.',
      'Clearbolt writes every order twice and still makes it sound exciting. Her chains never ask where to go; they already have coordinates.',
    ),
    _pulse(
      'mgr_030_myco_vortex',
      'Myco Vortex',
      'ring control + siphon',
      'Purple rings plant green siphon spores on enemies that split inside the radius.',
      'Controls fractal regen hybrids.',
      'Myco Vortex is half DJ, half xenobiologist, and fully convinced spores have rhythm. The lab banned fog machines because of him.',
    ),
    _burst(
      'mgr_031_major_cinderkick',
      'Major Cinderkick',
      'impact + burn',
      'Orange knockbacks refresh a small red burn on heavy targets.',
      'Weighty control with damage payoff.',
      'Major Cinderkick trains artillery crews by dancing on recoil platforms. He calls it morale; the engineers call it terrifying.',
    ),
    _spectrum(
      'mgr_032_professor_paradox',
      'Professor Paradox',
      'rainbow + anti-warp',
      'Each different adjacent color weakens black attack redirection by a small amount.',
      'Rainbow board answer to warp tanks.',
      'Paradox wrote three dissertations that disagree with each other and are all correct. He treats black holes as committee meetings with gravity.',
    ),
    _spectrum(
      'mgr_033_vega_v_spectrum',
      'Vega V. Spectrum',
      'all-color harmony',
      'A full six-color adjacency grants a unique bonus based on the tower at the center.',
      'The premium manager for rainbow hex building.',
      'Vega speaks fluent color and refuses to translate it badly. When she takes command, every tower feels chosen rather than slotted.',
    ),
    _spectrum(
      'mgr_034_the_primary_directive',
      'The Primary Directive',
      'tri-color command',
      'Red, yellow, and blue towers in the same hex cluster gain rotating fire, shock, or slow windows.',
      'Makes primary-color cores feel like a planned engine.',
      'The Directive is not one person but a rotating captaincy of three prodigies. They argue constantly and somehow issue perfect orders.',
    ),
    _pulse(
      'mgr_035_the_secondary_orbit',
      'The Secondary Orbit',
      'tri-color command',
      'Green, purple, and orange towers form a control loop: orbit, ring, impact.',
      'A centerpiece for premium crowd-control boards.',
      'The Orbit dances around its own command table, moving models with gloves, rings, and small moons. It wins battles like choreography.',
    ),
    _stability(
      'mgr_036_noir_starling',
      'Noir Starling',
      'contrast command',
      'White marks reveal priority targets; black tech reduces redirect waste against them.',
      'Simple clarity versus dark-matter chaos.',
      'Noir solves cosmic crimes by asking where the light refused to go. Her reports are short, elegant, and usually alarming.',
    ),
    _power(
      'mgr_037_doctor_deadstar',
      'Doctor Deadstar',
      'burn + anti-regen + singularity',
      'Burned regen enemies near black warp fields lose both husk and heal efficiency.',
      'Specialist into brutal late-game blends.',
      'Deadstar used to study life cycles. Now she studies why some things keep fighting after the cycle ends, and how to make them stop politely.',
    ),
    _tempo(
      'mgr_038_the_phase_prosecutor',
      'The Phase Prosecutor',
      'phase + split + warp law',
      'Blinking, splitting, or redirecting enemies receive escalating evidence stacks.',
      'Makes slippery enemies feel legally doomed.',
      'The Prosecutor treats physics violations as court filings. Every teleport leaves paperwork; every split gets cross-examined.',
    ),
    _flow(
      'mgr_039_admiral_permafrost',
      'Admiral Permafrost',
      'slow + impact + clarity',
      'Blue slows and orange impacts are more reliable against white-marked targets.',
      'A clean legendary support for tempo boards.',
      'Permafrost commands with the serene menace of an iceberg in uniform. She believes panic is wasted motion and motion should be weaponized.',
    ),
    _spectrum(
      'mgr_040_the_singularity_stylist',
      'The Singularity Stylist',
      'prism + gravity',
      'Rainbow adjacency bonuses remain active even when black enemies are warping attacks.',
      'Endgame fashion-and-function manager.',
      'The Stylist dresses crews for the heat death of the universe and makes them look early. Under the shimmer is ruthless tactical math.',
    ),
  ];

  static const _legacyConfigIds = <String, String>{
    'flux_coil': 'mgr_001_whitney_stardust',
    'impact_prism': 'mgr_002_reddie_mercury',
    'quick_relay': 'mgr_003_yella_nova',
    'spectrum_seal': 'mgr_004_greta_greenlight',
    'anchor_array': 'mgr_005_violet_vortex',
    'pulse_broker': 'mgr_006_orion_orange',
    'overload_lens': 'mgr_007_blueshift_aldrin',
  };

  static CardConfig? byId(String? configId) {
    if (configId == null) {
      return null;
    }
    final resolvedId = _legacyConfigIds[configId] ?? configId;
    for (final config in templates) {
      if (config.id == resolvedId) {
        return config;
      }
    }
    return null;
  }

  static CardConfig _flow(
    String id,
    String name,
    String focus,
    String boardBonus,
    String signatureRule,
    String bio,
  ) => _manager(
    id: id,
    name: name,
    roleLabel: 'Cadence Manager',
    mechanic: '+30% charge rate. Turns a relay into a packet printer.',
    focus: focus,
    boardBonus: boardBonus,
    signatureRule: signatureRule,
    bio: bio,
    powerMultiplier: 1,
    chargeMultiplier: 1.3,
    cooldownMultiplier: 1,
    advantageMultiplier: 1,
    automationRate: 0.62,
  );

  static CardConfig _power(
    String id,
    String name,
    String focus,
    String boardBonus,
    String signatureRule,
    String bio,
  ) => _manager(
    id: id,
    name: name,
    roleLabel: 'Power Manager',
    mechanic:
        '+32% power. Best for slower relays that need clean knockout hits.',
    focus: focus,
    boardBonus: boardBonus,
    signatureRule: signatureRule,
    bio: bio,
    powerMultiplier: 1.32,
    chargeMultiplier: 1,
    cooldownMultiplier: 1,
    advantageMultiplier: 1,
    automationRate: 0.46,
  );

  static CardConfig _tempo(
    String id,
    String name,
    String focus,
    String boardBonus,
    String signatureRule,
    String bio,
  ) => _manager(
    id: id,
    name: name,
    roleLabel: 'Tempo Manager',
    mechanic: '-22% cooldown. Smooths packet timing into the core queue.',
    focus: focus,
    boardBonus: boardBonus,
    signatureRule: signatureRule,
    bio: bio,
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
    String boardBonus,
    String signatureRule,
    String bio,
  ) => _manager(
    id: id,
    name: name,
    roleLabel: 'Spectrum Manager',
    mechanic: '+8% power, +8% charge, +18% bonus on favorable color matchups.',
    focus: focus,
    boardBonus: boardBonus,
    signatureRule: signatureRule,
    bio: bio,
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
    String boardBonus,
    String signatureRule,
    String bio,
  ) => _manager(
    id: id,
    name: name,
    roleLabel: 'Stability Manager',
    mechanic: '+18% power, -12% cooldown for a steady center-fed profile.',
    focus: focus,
    boardBonus: boardBonus,
    signatureRule: signatureRule,
    bio: bio,
    powerMultiplier: 1.18,
    chargeMultiplier: 1,
    cooldownMultiplier: 0.88,
    advantageMultiplier: 1,
    automationRate: 0.66,
  );

  static CardConfig _pulse(
    String id,
    String name,
    String focus,
    String boardBonus,
    String signatureRule,
    String bio,
  ) => _manager(
    id: id,
    name: name,
    roleLabel: 'Cadence Manager',
    mechanic:
        'Stacks efficient charge routing with weaker direct damage gains.',
    focus: focus,
    boardBonus: boardBonus,
    signatureRule: signatureRule,
    bio: bio,
    powerMultiplier: 0.98,
    chargeMultiplier: 1.18,
    cooldownMultiplier: 0.94,
    advantageMultiplier: 1.02,
    automationRate: 0.72,
  );

  static CardConfig _burst(
    String id,
    String name,
    String focus,
    String boardBonus,
    String signatureRule,
    String bio,
  ) => _manager(
    id: id,
    name: name,
    roleLabel: 'Burst Manager',
    mechanic: 'Leans into bigger packet payloads with slower charge timing.',
    focus: focus,
    boardBonus: boardBonus,
    signatureRule: signatureRule,
    bio: bio,
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
    required String boardBonus,
    required String signatureRule,
    required String bio,
    required double powerMultiplier,
    required double chargeMultiplier,
    required double cooldownMultiplier,
    required double advantageMultiplier,
    required double automationRate,
  }) {
    return CardConfig(
      id: id,
      name: name,
      summary:
          '$mechanic Build focus: $focus. Board bonus: $boardBonus Signature rule: $signatureRule',
      flavorBio: bio,
      roleLabel: roleLabel,
      powerMultiplier: powerMultiplier,
      chargeMultiplier: chargeMultiplier,
      cooldownMultiplier: cooldownMultiplier,
      advantageMultiplier: advantageMultiplier,
      automationRate: automationRate,
    );
  }
}
