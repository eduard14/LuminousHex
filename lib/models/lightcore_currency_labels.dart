class LightcoreCurrencyLabels {
  const LightcoreCurrencyLabels._();

  static const String lumens = 'Lumens';
  static const String flux = 'Flux';
  static const String prismShards = 'Prism Shards';
  static const String scansShort = 'Scans';
  static const String threatScanSingular = 'Threat Scan';
  static const String threatScanPlural = 'Threat Scans';
  static const String bossScanSingular = 'Apex Scan';
  static const String bossScanPlural = 'Apex Scans';

  static String threatScanName(int count) =>
      count == 1 ? threatScanSingular : threatScanPlural;

  static String bossScanName(int count) =>
      count == 1 ? bossScanSingular : bossScanPlural;

  static String lumenCount(int amount) => '$amount $lumens';

  static String fluxCount(int amount) => '$amount $flux';

  static String prismShardCount(int amount) => '$amount $prismShards';

  static String threatScanCount(int amount) =>
      '$amount ${threatScanName(amount)}';

  static String bossScanCount(int amount) => '$amount ${bossScanName(amount)}';

  static String rewardLumens(int amount) => '+${lumenCount(amount)}';

  static String rewardFlux(int amount) => '+${fluxCount(amount)}';

  static String rewardPrismShards(int amount) => '+${prismShardCount(amount)}';

  static String rewardThreatScans(int amount) => '+${threatScanCount(amount)}';

  static String rewardBossScans(int amount) => '+${bossScanCount(amount)}';
}
