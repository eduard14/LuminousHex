// Temporary local Layer 1 iteration switches. Flip both off when the menu and
// Firebase-backed startup flow should be exercised again.
const bool bypassServerValidationForLayer1Testing = true;
const bool skipMainMenuForLayer1Testing = true;

bool shouldEnableLocalhostAutoTapper({required bool isWeb, required Uri uri}) {
  if (!isWeb) {
    return false;
  }
  final host = uri.host.toLowerCase();
  final isLocalHost =
      host == 'localhost' || host == '127.0.0.1' || host == '::1';
  if (!isLocalHost) {
    return false;
  }
  return _truthyQueryFlag(uri, 'autoTap') ||
      _truthyQueryFlag(uri, 'localhostAutoTapper');
}

bool _truthyQueryFlag(Uri uri, String key) {
  final value = uri.queryParameters[key]?.toLowerCase();
  return value == '1' || value == 'true';
}
