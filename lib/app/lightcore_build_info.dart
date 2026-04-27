class LightcoreBuildInfo {
  const LightcoreBuildInfo._();

  static const String versionName = String.fromEnvironment(
    'LIGHTCORE_VERSION_NAME',
    defaultValue: '1.0.14',
  );

  static const String buildNumber = String.fromEnvironment(
    'LIGHTCORE_BUILD_NUMBER',
    defaultValue: '15',
  );

  static const String iosAppStoreUrl = String.fromEnvironment(
    'LIGHTCORE_IOS_APP_STORE_URL',
    defaultValue: 'https://apps.apple.com/search?term=Lumi%20Core',
  );
}
