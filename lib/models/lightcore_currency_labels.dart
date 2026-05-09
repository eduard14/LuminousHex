class LightcoreCurrencyLabels {
  const LightcoreCurrencyLabels._();

  static const String lumens = 'Lumens';
  static const String flux = 'Flux';
  static const String prismShards = 'Prism Shards';
  static const String managerShardSingular = 'Manager Shard';
  static const String managerShards = 'Manager Shards';
  static const String shellCores = 'Shell Cores';
  static const String scansShort = 'Scans';
  static const String threatScanSingular = 'Threat Scan';
  static const String threatScanPlural = 'Threat Scans';
  static const String bossScanSingular = 'Threat Scan';
  static const String bossScanPlural = 'Threat Scans';

  static String threatScanName(int count) =>
      count == 1 ? threatScanSingular : threatScanPlural;

  static String bossScanName(int count) =>
      count == 1 ? bossScanSingular : bossScanPlural;

  static String lumenCount(int amount) => '$amount $lumens';

  static String fluxCount(int amount) => '$amount $flux';

  static String prismShardCount(int amount) => '$amount $prismShards';

  static String managerShardName(int amount) =>
      amount == 1 ? managerShardSingular : managerShards;

  static String managerShardCount(int amount) =>
      '$amount ${managerShardName(amount)}';

  static String shellCoreCount(int amount) => '$amount $shellCores';

  static String threatScanCount(int amount) =>
      '$amount ${threatScanName(amount)}';

  static String bossScanCount(int amount) => '$amount ${bossScanName(amount)}';

  static String rewardLumens(int amount) => '+${lumenCount(amount)}';

  static String rewardFlux(int amount) => '+${fluxCount(amount)}';

  static String rewardPrismShards(int amount) => '+${prismShardCount(amount)}';

  static String rewardManagerShards(int amount) =>
      '+${managerShardCount(amount)}';

  static String rewardShellCores(int amount) => '+${shellCoreCount(amount)}';

  static String rewardThreatScans(int amount) => '+${threatScanCount(amount)}';

  static String rewardBossScans(int amount) => '+${bossScanCount(amount)}';
}
