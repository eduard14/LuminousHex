import '../models/lightcore_config.dart';

// TODO(full-game): Threat Director definitions should be data-driven and signed
// by the backend because they directly influence spawn cadence and rewards.
class EnemyManagerLibrary {
  static final swarmBroker = _swarm(
    'swarm_broker',
    'Splinter Stella',
    'Purple enemies split with cleaner spacing.',
    'Makes split waves harder to AOE lazily.',
  );

  static final extractor = _titan(
    'extractor',
    'Plain Jane Quasar',
    'White enemies gain small HP but no new gimmick.',
    'Keeps simple waves credible.',
  );

  static final phaseScript = _phase(
    'phase_script',
    'Blink Floyd',
    'Yellow enemies blink on a more awkward rhythm.',
    'Adds miss pressure without raw stats.',
  );

  static final regenDirector = _regen(
    'regen_director',
    'Regenade Moss',
    'Green enemies restore more health after not taking damage.',
    'Punishes unfocused boards.',
  );

  static final gravityDirector = _gravity(
    'gravity_director',
    'Grim Gravity',
    'Black enemies redirect attacks from a wider nearby area.',
    'Turns warp tanks into real bodyguards.',
  );

  static final greedDirector = _greed(
    'greed_director',
    'Count Huskula',
    'Red enemy husks remain targetable slightly longer.',
    'Makes DPS sinks more punishing.',
  );

  static final saboteurDirector = _saboteur(
    'saboteur_director',
    'Blue Screen Baron',
    'Blue contact disables last slightly longer.',
    'Turns contact into a real threat.',
  );

  static final volatileDirector = _volatile(
    'volatile_director',
    'Fastro Naut',
    'Orange enemies accelerate sooner.',
    'Stress-tests lanes and early targeting.',
  );

  static final apexHerald = _apex(
    'apex_herald',
    'Duchess Deadweight',
    'Black enemies prioritize protecting red husks.',
    'Makes bad targeting feel deliberately dangerous.',
  );

  static final all = <EnemyManagerConfig>[
    extractor,
    greedDirector,
    swarmBroker,
    phaseScript,
    regenDirector,
    saboteurDirector,
    volatileDirector,
    gravityDirector,
    apexHerald,
    _regen(
      'emg_010_fractal_fern',
      'Fractal Fern',
      'Purple fragments inherit a tiny regen seed.',
      'Forces immediate cleanup.',
    ),
    _phase(
      'emg_011_dash_mirage',
      'Dash Mirage',
      'Yellow enemies exit blinks with a short speed burst.',
      'Creates slippery fast lanes.',
    ),
    _saboteur(
      'emg_012_ion_umbrella',
      'Ion Umbrella',
      'Black warp tanks prefer shielding blue jammers.',
      'Protects tower-disabling threats.',
    ),
    _regen(
      'emg_013_cauter_moss',
      'Cauter Moss',
      'Red husks linger while nearby green enemies heal.',
      'Creates target-waste under healing pressure.',
    ),
    _phase(
      'emg_014_parallax_splint',
      'Parallax Splint',
      'Fresh purple fragments get a tiny phase window.',
      'Challenges delayed AOE timing.',
    ),
    _volatile(
      'emg_015_vanilla_velocity',
      'Vanilla Velocity',
      'White enemies can appear as low-trick fast fillers.',
      'Makes simple waves still urgent.',
    ),
    _saboteur(
      'emg_016_patch_cable_ivy',
      'Patch Cable Ivy',
      'Blue jammers slowly repair unless under fire.',
      'Rewards focused priority targeting.',
    ),
    _swarm(
      'emg_017_husk_fractalist',
      'Husk Fractalist',
      'Some red husks break into harmless but targetable fragments.',
      'Premium shot-waste pressure.',
    ),
    _phase(
      'emg_018_lag_lightning',
      'Lag Lightning',
      "A yellow blink can briefly delay a nearby tower's next shot.",
      'Soft control without contact.',
    ),
    _gravity(
      'emg_019_ouroboros_well',
      'Ouroboros Well',
      'Black protection prioritizes high-regen enemies.',
      'Makes healers feel guarded.',
    ),
    _volatile(
      'emg_020_cinder_sprinter',
      'Cinder Sprinter',
      'Fast red enemies leave momentum husks that steal a few shots.',
      'Fast DPS-sink hybrid pressure.',
    ),
    _gravity(
      'emg_021_umbra_mitosis',
      'Umbra Mitosis',
      'Black redirect fields can briefly shield new purple fragments.',
      'Protects the dangerous second wave.',
    ),
    _saboteur(
      'emg_022_blank_outage',
      'Blank Outage',
      'White filler waves hide one blue jammer pattern.',
      'Teaches players to read the wave, not just color.',
    ),
    _regen(
      'emg_023_static_bloom',
      'Static Bloom',
      'Green enemies receive regen bursts after nearby yellow blinks.',
      'Punishes uncontrolled phasing packs.',
    ),
    _volatile(
      'emg_024_prism_pusher',
      'Prism Pusher',
      'Waves can include one extra off-color elite.',
      'Introduces rainbow anomaly compositions.',
    ),
    _gravity(
      'emg_025_deadlight_broker',
      'Deadlight Broker',
      'Red husks may be protected by black tanks while yellow enemies blink.',
      'Late-game target chaos.',
    ),
    _saboteur(
      'emg_026_deepcare_kernel',
      'Deepcare Kernel',
      'Jammers and healers receive warp protection in alternating pulses.',
      'Creates priority puzzles.',
    ),
    _phase(
      'emg_027_shatterdash_maestro',
      'Shatterdash Maestro',
      'Split fragments can dash or blink once, depending on wave script.',
      'Forces broad coverage.',
    ),
    _regen(
      'emg_028_compost_choir',
      'Compost Choir',
      'Defeated split fragments can feed tiny regen to nearby bodies.',
      'Swarm sustain pressure.',
    ),
    _volatile(
      'emg_029_traffic_control',
      'Traffic Control',
      'Fast waves hide blue jammers behind simple white bodies.',
      'Lane discipline check.',
    ),
    _gravity(
      'emg_030_nullshard_admin',
      'Nullshard Admin',
      'Black fields prefer to absorb shots aimed at purple or blue threats.',
      'Protects disruptive units.',
    ),
    _greed(
      'emg_031_chromatic_huskler',
      'Chromatic Huskler',
      'Off-color elites may leave red-style targetable remnants.',
      'Surprise shot-waste hooks.',
    ),
    _volatile(
      'emg_032_event_planner_nyx',
      'Event Planner Nyx',
      'Mixed waves get scheduled around black warp tanks.',
      'Turns compositions into set pieces.',
    ),
    _volatile(
      'emg_033_the_spectrum_syndic',
      'The Spectrum Syndic',
      'All colors can appear with one chosen dominant mechanic.',
      'Endgame mixed-wave architect.',
    ),
    _gravity(
      'emg_034_the_dead_star_regent',
      'The Dead Star Regent',
      'Black tanks can crown red husks as priority decoys.',
      'Turns death into battlefield authority.',
    ),
    _phase(
      'emg_035_the_blink_horizon',
      'The Blink Horizon',
      'Teleporting enemies may blink toward a black protection field.',
      'Combines evasion with shielding.',
    ),
    _regen(
      'emg_036_the_garden_standard',
      'The Garden Standard',
      'White waves can carry invisible regen benchmarks for green elites.',
      'Makes basic enemies part of sustain puzzles.',
    ),
    _gravity(
      'emg_037_the_mitosis_maw',
      'The Mitosis Maw',
      'Fragments briefly orbit the nearest black tank before choosing lanes.',
      'Endgame split protection.',
    ),
    _saboteur(
      'emg_038_the_crash_comet',
      'The Crash Comet',
      'Fast blue enemies threaten contact disables at terrifying timing windows.',
      'High-pressure contact boss wave manager.',
    ),
    _apex(
      'emg_039_the_triage_tyrant',
      'The Triage Tyrant',
      'Enemies preserve, heal, and jam in a rotating order.',
      'Sustained priority-management test.',
    ),
    _apex(
      'emg_040_the_dark_spectrum',
      'The Dark Spectrum',
      'Rainbow waves gain attack-redirection choreography around singularity tanks.',
      'Final-form enemy manager.',
    ),
  ];

  static EnemyManagerConfig _swarm(
    String id,
    String name,
    String modifier,
    String intent,
  ) => _director(
    id: id,
    name: name,
    archetype: 'Swarm Director',
    modifier: modifier,
    intent: intent,
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
  ) => _director(
    id: id,
    name: name,
    archetype: 'Titan Director',
    modifier: modifier,
    intent: intent,
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
  ) => _director(
    id: id,
    name: name,
    archetype: 'Phase Director',
    modifier: modifier,
    intent: intent,
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
  ) => _director(
    id: id,
    name: name,
    archetype: 'Regen Director',
    modifier: modifier,
    intent: intent,
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
  ) => _director(
    id: id,
    name: name,
    archetype: 'Gravity Director',
    modifier: modifier,
    intent: intent,
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
  ) => _director(
    id: id,
    name: name,
    archetype: 'Greed Director',
    modifier: modifier,
    intent: intent,
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
  ) => _director(
    id: id,
    name: name,
    archetype: 'Saboteur Director',
    modifier: modifier,
    intent: intent,
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
  ) => _director(
    id: id,
    name: name,
    archetype: 'Volatile Director',
    modifier: modifier,
    intent: intent,
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
  ) => _director(
    id: id,
    name: name,
    archetype: 'Apex Herald',
    modifier: modifier,
    intent: intent,
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
      summary: '$archetype archetype. $modifier $intent',
      flavorBio: _threatDirectorBio(
        name: name,
        archetype: archetype,
        modifier: modifier,
        intent: intent,
      ),
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

  static String _threatDirectorBio({
    required String name,
    required String archetype,
    required String modifier,
    required String intent,
  }) {
    final officeHabit = switch (archetype) {
      'Swarm Director' => 'a seating chart that keeps multiplying',
      'Titan Director' => 'one very heavy spreadsheet',
      'Phase Director' => 'a calendar invite that keeps disappearing',
      'Regen Director' => 'a wellness program with suspicious math',
      'Gravity Director' => 'a policy binder dense enough to bend light',
      'Greed Director' => 'a bonus plan nobody admits they approved',
      'Saboteur Director' => 'an outage report marked "working as designed"',
      'Volatile Director' => 'a launch schedule written entirely in red ink',
      'Apex Herald' => 'a crown, a stamp, and no visible approval process',
      _ => 'an alarming pile of meeting notes',
    };
    final intentLine = _lowercaseSentenceStart(intent);

    return '$name runs $archetype operations with $officeHabit. '
        'Today\'s agenda: $modifier Also, $intentLine, because apparently that counts as leadership.';
  }

  static String _lowercaseSentenceStart(String value) {
    final trimmed = value.trim();
    final withoutPeriod = trimmed.endsWith('.')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    if (withoutPeriod.isEmpty) {
      return withoutPeriod;
    }
    return withoutPeriod[0].toLowerCase() + withoutPeriod.substring(1);
  }
}
