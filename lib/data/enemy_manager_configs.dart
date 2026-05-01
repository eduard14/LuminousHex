import '../models/lightcore_config.dart';

// TODO(full-game): Threat Director definitions should be data-driven and signed
// by the backend because they directly influence spawn cadence and rewards.
class EnemyManagerLibrary {
  static final plainJaneQuasar = _titan(
    'emg_001_plain_jane_quasar',
    'Plain Jane Quasar',
    'White enemies gain small HP but no new gimmick.',
    'Keeps simple waves credible.',
    'Plain Jane believes elegance is a straight line of enemies with enough health to matter. She hates overcomplication and loves a clean spreadsheet.',
  );
  static final countHuskula = _greed(
    'emg_002_count_huskula',
    'Count Huskula',
    'Red enemy husks remain targetable slightly longer.',
    'Makes DPS sinks more punishing.',
    'Count Huskula collects the last echoes of defeated stars. He calls them \'after-dinner guests\' and gets offended when towers ignore them.',
  );
  static final splinterStella = _swarm(
    'emg_003_splinter_stella',
    'Splinter Stella',
    'Purple enemies split with cleaner spacing.',
    'Makes split waves harder to AOE lazily.',
    'Stella names every shard before it breaks off. Her family reunions are loud, recursive, and usually a balance problem.',
  );
  static final blinkFloyd = _phase(
    'emg_004_blink_floyd',
    'Blink Floyd',
    'Yellow enemies blink on a more awkward rhythm.',
    'Adds miss pressure without raw stats.',
    'Blink Floyd sells tickets to places he has not arrived at yet. He is already behind you, but only on beat.',
  );
  static final regenadeMoss = _regen(
    'emg_005_regenade_moss',
    'Regenade Moss',
    'Green enemies restore more health after not taking damage.',
    'Punishes unfocused boards.',
    'Moss deserted from a garden planet because the rules were not growing fast enough. Now he teaches enemy waves to heal through discouragement.',
  );
  static final blueScreenBaron = _saboteur(
    'emg_006_blue_screen_baron',
    'Blue Screen Baron',
    'Blue contact disables last slightly longer.',
    'Turns contact into a real threat.',
    'The Baron introduces himself with a handshake and a system crash. His manners are impeccable; his firmware is not.',
  );
  static final fastroNaut = _volatile(
    'emg_007_fastro_naut',
    'Fastro Naut',
    'Orange enemies accelerate sooner.',
    'Stress-tests lanes and early targeting.',
    'Fastro has never finished a sentence at normal speed. He captains by drive-by briefing and assumes everyone kept up.',
  );
  static final grimGravity = _gravity(
    'emg_008_grim_gravity',
    'Grim Gravity',
    'Black enemies redirect attacks from a wider nearby area.',
    'Turns warp tanks into real bodyguards.',
    'Grim Gravity speaks softly because everything else falls toward him. He considers incoming fire a form of applause.',
  );
  static final duchessDeadweight = _apex(
    'emg_009_duchess_deadweight',
    'Duchess Deadweight',
    'Black enemies prioritize protecting red husks.',
    'Makes bad targeting feel deliberately dangerous.',
    'The Duchess arranges battlefields like dinner seating, always placing the dead weight where towers least want it.',
  );

  static final all = <EnemyManagerConfig>[
    plainJaneQuasar,
    countHuskula,
    splinterStella,
    blinkFloyd,
    regenadeMoss,
    blueScreenBaron,
    fastroNaut,
    grimGravity,
    duchessDeadweight,
    _regen(
      'emg_010_fractal_fern',
      'Fractal Fern',
      'Purple fragments inherit a tiny regen seed.',
      'Forces immediate cleanup.',
      'Fern is a botanist who looked at shards and asked why they could not also sprout. Nobody liked the answer.',
    ),
    _phase(
      'emg_011_dash_mirage',
      'Dash Mirage',
      'Yellow enemies exit blinks with a short speed burst.',
      'Creates slippery fast lanes.',
      'Dash Mirage signs autographs before he appears, then leaves scorch marks where the ink should dry.',
    ),
    _saboteur(
      'emg_012_ion_umbrella',
      'Ion Umbrella',
      'Black warp tanks prefer shielding blue jammers.',
      'Protects tower-disabling threats.',
      'Ion Umbrella runs security for storms. He believes every outage deserves a bodyguard.',
    ),
    _regen(
      'emg_013_cauter_moss',
      'Cauter Moss',
      'Red husks linger while nearby green enemies heal.',
      'Creates target-waste under healing pressure.',
      'Cauter Moss does field medicine by preserving exactly the wrong things. His motto: keep the problem alive.',
    ),
    _phase(
      'emg_014_parallax_splint',
      'Parallax Splint',
      'Fresh purple fragments get a tiny phase window.',
      'Challenges delayed AOE timing.',
      'Parallax Splint fractures light first and asks questions later. Every split arrives from a slightly rude angle.',
    ),
    _volatile(
      'emg_015_vanilla_velocity',
      'Vanilla Velocity',
      'White enemies can appear as low-trick fast fillers.',
      'Makes simple waves still urgent.',
      'Vanilla Velocity refuses to be called plain at her current speed. She is basic only in the sense that oxygen is basic.',
    ),
    _saboteur(
      'emg_016_patch_cable_ivy',
      'Patch Cable Ivy',
      'Blue jammers slowly repair unless under fire.',
      'Rewards focused priority targeting.',
      'Patch Cable Ivy grows vines through server racks and calls it infrastructure. The system is down, but it is blooming.',
    ),
    _swarm(
      'emg_017_husk_fractalist',
      'Husk Fractalist',
      'Some red husks break into harmless but targetable fragments.',
      'Premium shot-waste pressure.',
      'The Fractalist sculpts leftovers into new problems. He considers wasted DPS a gallery opening.',
    ),
    _phase(
      'emg_018_lag_lightning',
      'Lag Lightning',
      'A yellow blink can briefly delay a nearby tower\'s next shot.',
      'Soft control without contact.',
      'Lag Lightning has never been late; time simply buffers around her. Towers hate the loading icon she leaves behind.',
    ),
    _gravity(
      'emg_019_ouroboros_well',
      'Ouroboros Well',
      'Black protection prioritizes high-regen enemies.',
      'Makes healers feel guarded.',
      'The Well feeds on patience and gives it back to enemies with interest. It is less a manager than a very persuasive gravity problem.',
    ),
    _volatile(
      'emg_020_cinder_sprinter',
      'Cinder Sprinter',
      'Fast red enemies leave momentum husks that steal a few shots.',
      'Fast DPS-sink hybrid pressure.',
      'Cinder Sprinter collects finish lines and leaves decoys at all of them. The decoys are somehow smug.',
    ),
    _gravity(
      'emg_021_umbra_mitosis',
      'Umbra Mitosis',
      'Black redirect fields can briefly shield new purple fragments.',
      'Protects the dangerous second wave.',
      'Umbra Mitosis wrote a self-help book called \'Become Many, Hide Behind One.\' It sold badly but split into sequels.',
    ),
    _saboteur(
      'emg_022_blank_outage',
      'Blank Outage',
      'White filler waves hide one blue jammer pattern.',
      'Teaches players to read the wave, not just color.',
      'Blank Outage weaponizes boredom. By the time towers notice the pattern, someone is unplugged.',
    ),
    _regen(
      'emg_023_static_bloom',
      'Static Bloom',
      'Green enemies receive regen bursts after nearby yellow blinks.',
      'Punishes uncontrolled phasing packs.',
      'Static Bloom pollinates thunderclouds. Her flowers bloom exactly when targeting systems lose confidence.',
    ),
    _volatile(
      'emg_024_prism_pusher',
      'Prism Pusher',
      'Waves can include one extra off-color elite.',
      'Introduces rainbow enemy compositions.',
      'Prism Pusher treats color lanes like a market stall and always has something you were not ready to buy.',
    ),
    _gravity(
      'emg_025_deadlight_broker',
      'Deadlight Broker',
      'Red husks may be protected by black tanks while yellow enemies blink around them.',
      'Late-game target chaos.',
      'The Broker sells darkness by the lumen. Every contract includes a clause about missed shots and emotional damage.',
    ),
    _saboteur(
      'emg_026_deepcare_kernel',
      'Deepcare Kernel',
      'Jammers and healers receive warp protection in alternating pulses.',
      'Creates priority puzzles.',
      'Deepcare Kernel smiles like customer support and patches enemies while your towers reboot. Nobody finds the survey link.',
    ),
    _phase(
      'emg_027_shatterdash_maestro',
      'Shatterdash Maestro',
      'Split fragments can dash or blink once, depending on wave script.',
      'Forces broad coverage.',
      'The Maestro conducts waves with a baton made from a broken speedometer. The orchestra arrives in pieces and never on time.',
    ),
    _regen(
      'emg_028_compost_choir',
      'Compost Choir',
      'Defeated split fragments can feed tiny regen to nearby bodies.',
      'Swarm sustain pressure.',
      'The Choir sings in biodegradable harmony. Every note becomes mulch; every mulch becomes trouble.',
    ),
    _volatile(
      'emg_029_traffic_control',
      'Traffic Control',
      'Fast waves hide blue jammers behind simple white bodies.',
      'Lane discipline check.',
      'Traffic Control owns every permit in the sector and weaponizes all of them. Even comets wait at his lights.',
    ),
    _gravity(
      'emg_030_nullshard_admin',
      'Nullshard Admin',
      'Black fields prefer to absorb shots aimed at purple or blue threats.',
      'Protects disruptive units.',
      'The Admin says no in five dimensions. Requests to target anything useful are automatically redirected.',
    ),
    _greed(
      'emg_031_chromatic_huskler',
      'Chromatic Huskler',
      'Off-color elites may leave red-style targetable remnants.',
      'Surprise shot-waste hooks.',
      'The Huskler bets against tower attention spans and keeps winning. His sleeves are full of little dead stars.',
    ),
    _volatile(
      'emg_032_event_planner_nyx',
      'Event Planner Nyx',
      'Mixed waves get scheduled around black warp tanks.',
      'Turns compositions into set pieces.',
      'Nyx plans parties where the favors are wormholes and the guest list is incoming fire. She is booked through heat death.',
    ),
    _volatile(
      'emg_033_the_spectrum_syndic',
      'The Spectrum Syndic',
      'All colors can appear with one chosen dominant mechanic.',
      'Endgame mixed-wave architect.',
      'The Syndic does not command enemies; it curates them. Every wave is a thesis on why the player\'s favorite tower is overconfident.',
    ),
    _gravity(
      'emg_034_the_dead_star_regent',
      'The Dead Star Regent',
      'Black tanks can crown red husks as priority decoys.',
      'Turns death into battlefield authority.',
      'The Regent rules over things that should have stopped mattering. His crown is an orbiting graveyard of missed shots.',
    ),
    _phase(
      'emg_035_the_blink_horizon',
      'The Blink Horizon',
      'Teleporting enemies may blink toward a black protection field.',
      'Combines evasion with shielding.',
      'The Horizon opens doors only gravity can close. Enemies step through; projectiles politely do not.',
    ),
    _regen(
      'emg_036_the_garden_standard',
      'The Garden Standard',
      'White waves can carry invisible regen benchmarks for green elites.',
      'Makes basic enemies part of sustain puzzles.',
      'The Garden Standard believes the simplest organism is still a miracle. It also believes miracles should have hit points.',
    ),
    _gravity(
      'emg_037_the_mitosis_maw',
      'The Mitosis Maw',
      'Fragments briefly orbit the nearest black tank before choosing lanes.',
      'Endgame split protection.',
      'The Maw smiles in multiples. Each tooth is a smaller mouth with a better plan.',
    ),
    _saboteur(
      'emg_038_the_crash_comet',
      'The Crash Comet',
      'Fast blue enemies threaten contact disables at terrifying timing windows.',
      'High-pressure contact boss wave manager.',
      'The Crash Comet\'s personal motto is \'arrive loud, leave everything offline.\' It is embroidered on her boots.',
    ),
    _apex(
      'emg_039_the_triage_tyrant',
      'The Triage Tyrant',
      'Enemies preserve, heal, and jam in a rotating order.',
      'Sustained priority-management test.',
      'The Tyrant runs a hospital where every patient is a problem for the player. Discharge is not offered.',
    ),
    _apex(
      'emg_040_the_dark_spectrum',
      'The Dark Spectrum',
      'Rainbow waves gain attack-redirection choreography around singularity tanks.',
      'Final-form enemy manager.',
      'The Dark Spectrum is what color looks like from the other side of a black hole: beautiful, expensive, and very bad for targeting.',
    ),
  ];

  static const _legacyConfigIds = <String, String>{
    'extractor': 'emg_001_plain_jane_quasar',
    'greed_director': 'emg_002_count_huskula',
    'swarm_broker': 'emg_003_splinter_stella',
    'phase_script': 'emg_004_blink_floyd',
    'regen_director': 'emg_005_regenade_moss',
    'saboteur_director': 'emg_006_blue_screen_baron',
    'volatile_director': 'emg_007_fastro_naut',
    'gravity_director': 'emg_008_grim_gravity',
    'apex_herald': 'emg_009_duchess_deadweight',
  };

  static EnemyManagerConfig? byId(String? configId) {
    if (configId == null) {
      return null;
    }
    final resolvedId = _legacyConfigIds[configId] ?? configId;
    for (final config in all) {
      if (config.id == resolvedId) {
        return config;
      }
    }
    return null;
  }

  static EnemyManagerConfig _swarm(
    String id,
    String name,
    String modifier,
    String intent,
    String bio,
  ) => _director(
    id: id,
    name: name,
    archetype: 'Swarm Director',
    modifier: modifier,
    intent: intent,
    bio: bio,
    spawnRateMultiplier: 1.14,
    rewardMultiplier: 1.2,
    experienceMultiplier: 1.16,
    healthMultiplier: 0.86,
    speedMultiplier: 1.0,
    stabilityDamageMultiplier: 1.1,
    apexStabilityMultiplier: 1.0,
    queueDisruptionMultiplier: 1.0,
  );

  static EnemyManagerConfig _titan(
    String id,
    String name,
    String modifier,
    String intent,
    String bio,
  ) => _director(
    id: id,
    name: name,
    archetype: 'Titan Director',
    modifier: modifier,
    intent: intent,
    bio: bio,
    spawnRateMultiplier: 0.82,
    rewardMultiplier: 1.28,
    experienceMultiplier: 1.12,
    healthMultiplier: 1.42,
    speedMultiplier: 0.9,
    stabilityDamageMultiplier: 1.16,
    apexStabilityMultiplier: 1.04,
    queueDisruptionMultiplier: 1.0,
  );

  static EnemyManagerConfig _phase(
    String id,
    String name,
    String modifier,
    String intent,
    String bio,
  ) => _director(
    id: id,
    name: name,
    archetype: 'Phase Director',
    modifier: modifier,
    intent: intent,
    bio: bio,
    spawnRateMultiplier: 1.08,
    rewardMultiplier: 1.12,
    experienceMultiplier: 1.08,
    healthMultiplier: 1.0,
    speedMultiplier: 1.16,
    stabilityDamageMultiplier: 1.14,
    apexStabilityMultiplier: 1.06,
    queueDisruptionMultiplier: 1.04,
  );

  static EnemyManagerConfig _regen(
    String id,
    String name,
    String modifier,
    String intent,
    String bio,
  ) => _director(
    id: id,
    name: name,
    archetype: 'Regen Director',
    modifier: modifier,
    intent: intent,
    bio: bio,
    spawnRateMultiplier: 0.96,
    rewardMultiplier: 1.18,
    experienceMultiplier: 1.12,
    healthMultiplier: 1.18,
    speedMultiplier: 0.96,
    stabilityDamageMultiplier: 1.12,
    apexStabilityMultiplier: 1.08,
    queueDisruptionMultiplier: 1.0,
  );

  static EnemyManagerConfig _gravity(
    String id,
    String name,
    String modifier,
    String intent,
    String bio,
  ) => _director(
    id: id,
    name: name,
    archetype: 'Gravity Director',
    modifier: modifier,
    intent: intent,
    bio: bio,
    spawnRateMultiplier: 0.9,
    rewardMultiplier: 1.3,
    experienceMultiplier: 1.14,
    healthMultiplier: 1.28,
    speedMultiplier: 0.88,
    stabilityDamageMultiplier: 1.28,
    apexStabilityMultiplier: 1.18,
    queueDisruptionMultiplier: 1.06,
  );

  static EnemyManagerConfig _greed(
    String id,
    String name,
    String modifier,
    String intent,
    String bio,
  ) => _director(
    id: id,
    name: name,
    archetype: 'Greed Director',
    modifier: modifier,
    intent: intent,
    bio: bio,
    spawnRateMultiplier: 1.0,
    rewardMultiplier: 1.26,
    experienceMultiplier: 1.12,
    healthMultiplier: 1.14,
    speedMultiplier: 0.98,
    stabilityDamageMultiplier: 1.24,
    apexStabilityMultiplier: 1.08,
    queueDisruptionMultiplier: 1.0,
  );

  static EnemyManagerConfig _saboteur(
    String id,
    String name,
    String modifier,
    String intent,
    String bio,
  ) => _director(
    id: id,
    name: name,
    archetype: 'Saboteur Director',
    modifier: modifier,
    intent: intent,
    bio: bio,
    spawnRateMultiplier: 1.08,
    rewardMultiplier: 1.2,
    experienceMultiplier: 1.08,
    healthMultiplier: 1.04,
    speedMultiplier: 1.06,
    stabilityDamageMultiplier: 1.18,
    apexStabilityMultiplier: 1.1,
    queueDisruptionMultiplier: 1.22,
  );

  static EnemyManagerConfig _volatile(
    String id,
    String name,
    String modifier,
    String intent,
    String bio,
  ) => _director(
    id: id,
    name: name,
    archetype: 'Volatile Director',
    modifier: modifier,
    intent: intent,
    bio: bio,
    spawnRateMultiplier: 1.12,
    rewardMultiplier: 1.22,
    experienceMultiplier: 1.22,
    healthMultiplier: 1.08,
    speedMultiplier: 1.08,
    stabilityDamageMultiplier: 1.18,
    apexStabilityMultiplier: 1.08,
    queueDisruptionMultiplier: 1.06,
  );

  static EnemyManagerConfig _apex(
    String id,
    String name,
    String modifier,
    String intent,
    String bio,
  ) => _director(
    id: id,
    name: name,
    archetype: 'Apex Herald',
    modifier: modifier,
    intent: intent,
    bio: bio,
    spawnRateMultiplier: 0.98,
    rewardMultiplier: 1.18,
    experienceMultiplier: 1.12,
    healthMultiplier: 1.04,
    speedMultiplier: 0.98,
    stabilityDamageMultiplier: 1.06,
    apexStabilityMultiplier: 1.38,
    queueDisruptionMultiplier: 1.0,
  );

  static EnemyManagerConfig _director({
    required String id,
    required String name,
    required String archetype,
    required String modifier,
    required String intent,
    required String bio,
    required double spawnRateMultiplier,
    required double rewardMultiplier,
    required double experienceMultiplier,
    required double healthMultiplier,
    required double speedMultiplier,
    required double stabilityDamageMultiplier,
    required double apexStabilityMultiplier,
    required double queueDisruptionMultiplier,
  }) {
    return EnemyManagerConfig(
      id: id,
      name: name,
      summary:
          '$archetype archetype. Wave modifier: $modifier Design intent: $intent',
      flavorBio: bio,
      roleLabel: 'Threat Director',
      spawnRateMultiplier: spawnRateMultiplier,
      rewardMultiplier: rewardMultiplier,
      experienceMultiplier: experienceMultiplier,
      healthMultiplier: healthMultiplier,
      speedMultiplier: speedMultiplier,
      stabilityDamageMultiplier: stabilityDamageMultiplier,
      apexStabilityMultiplier: apexStabilityMultiplier,
      queueDisruptionMultiplier: queueDisruptionMultiplier,
    );
  }
}
