bool get isWebCacheRefreshSupported => false;

bool hasAttemptedWebCacheRefresh(String version) => false;

void clearWebCacheRefreshAttempt() {}

Future<bool> clearCachesAndReloadWebApp({required String targetVersion}) async {
  return false;
}
