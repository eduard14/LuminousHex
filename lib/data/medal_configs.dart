import '../models/lightcore_config.dart';
import '../models/lightcore_types.dart';

class MedalLibrary {
  static const ProfileMedalConfig firstPrism = ProfileMedalConfig(
    id: 'first_prism',
    name: 'First Prism',
    summary: 'A profile medal for fabricating your first source tower.',
    requirementLabel: 'Fabricate 1 source tower',
    requiredValue: 1,
    bonusLabel: '+3.0% Power',
    bonuses: EquipmentBonusProfile(towerPower: 0.03),
    affinity: PrototypeAffinity.ember,
  );

  static const ProfileMedalConfig ringwright = ProfileMedalConfig(
    id: 'ringwright',
    name: 'Ringwright',
    summary: 'A profile medal for completing the first six-prism ring.',
    requirementLabel: 'Fabricate 6 source towers',
    requiredValue: 6,
    bonusLabel: '+4.0% Charge',
    bonuses: EquipmentBonusProfile(chargeRate: 0.04),
    affinity: PrototypeAffinity.flare,
  );

  static const ProfileMedalConfig apexBreaker = ProfileMedalConfig(
    id: 'apex_breaker',
    name: 'Apex Breaker',
    summary: 'A profile medal for defeating an Apex Anomaly.',
    requirementLabel: 'Defeat 1 Apex Anomaly',
    requiredValue: 1,
    bonusLabel: '+7.0% Apex Dmg',
    bonuses: EquipmentBonusProfile(bossDamage: 0.07),
    affinity: PrototypeAffinity.solar,
  );

  static const ProfileMedalConfig radianceCrest = ProfileMedalConfig(
    id: 'radiance_crest',
    name: 'Radiance Crest',
    summary: 'A profile medal for reaching Account Radiance Lv 10.',
    requirementLabel: 'Reach Radiance Lv 10',
    requiredValue: 10,
    bonusLabel: '+5.0% Lumens',
    bonuses: EquipmentBonusProfile(lumenGain: 0.05),
    affinity: PrototypeAffinity.verdant,
  );

  static const ProfileMedalConfig signalHunter = ProfileMedalConfig(
    id: 'signal_hunter',
    name: 'Signal Hunter',
    summary: 'A profile medal for building an anomaly card collection.',
    requirementLabel: 'Own 8 anomaly cards',
    requiredValue: 8,
    bonusLabel: '+1.2% Crit',
    bonuses: EquipmentBonusProfile(critChance: 0.012),
    affinity: PrototypeAffinity.aether,
  );

  static const ProfileMedalConfig foundryPatron = ProfileMedalConfig(
    id: 'foundry_patron',
    name: 'Foundry Patron',
    summary: 'A profile medal for forging managers in the foundry.',
    requirementLabel: 'Forge 5 managers',
    requiredValue: 5,
    bonusLabel: '+4.0% Flux',
    bonuses: EquipmentBonusProfile(fluxGain: 0.04),
    affinity: PrototypeAffinity.violet,
  );

  static const ProfileMedalConfig dungeonClimber = ProfileMedalConfig(
    id: 'dungeon_climber',
    name: 'Dungeon Climber',
    summary: 'A profile medal for clearing a daily dungeon tower.',
    requirementLabel: 'Clear Daily Tower Lv 1',
    requiredValue: 1,
    bonusLabel: '+4.0% Scans',
    bonuses: EquipmentBonusProfile(ticketGain: 0.04),
    affinity: PrototypeAffinity.neutral,
  );

  static const ProfileMedalConfig ascendant = ProfileMedalConfig(
    id: 'ascendant',
    name: 'Ascendant',
    summary: 'A profile medal for pushing beyond the root shell.',
    requirementLabel: 'Reach Prestige 1',
    requiredValue: 1,
    bonusLabel: '+5.0% Range',
    bonuses: EquipmentBonusProfile(range: 0.05),
    affinity: PrototypeAffinity.black,
  );

  static const List<ProfileMedalConfig> all = <ProfileMedalConfig>[
    firstPrism,
    ringwright,
    apexBreaker,
    radianceCrest,
    signalHunter,
    foundryPatron,
    dungeonClimber,
    ascendant,
  ];

  static final Map<String, ProfileMedalConfig> byId =
      <String, ProfileMedalConfig>{for (final medal in all) medal.id: medal};
}
