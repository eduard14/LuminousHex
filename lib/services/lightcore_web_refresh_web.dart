// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

const _refreshAttemptStorageKey = 'lightcore.web_refresh_attempt';
const _refreshVersionQueryKey = '_lcver';
const _refreshTimeQueryKey = '_lcts';

bool get isWebCacheRefreshSupported => true;

bool hasAttemptedWebCacheRefresh(String version) {
  return html.window.sessionStorage[_refreshAttemptStorageKey] == version;
}

void clearWebCacheRefreshAttempt() {
  html.window.sessionStorage.remove(_refreshAttemptStorageKey);
}

Future<bool> clearCachesAndReloadWebApp({required String targetVersion}) async {
  html.window.sessionStorage[_refreshAttemptStorageKey] = targetVersion;

  try {
    final serviceWorker = html.window.navigator.serviceWorker;
    if (serviceWorker != null) {
      final registrations = await serviceWorker.getRegistrations();
      for (final registration in registrations) {
        if (registration is html.ServiceWorkerRegistration) {
          await registration.unregister();
        }
      }
    }

    final caches = html.window.caches;
    if (caches != null) {
      final keys = await caches.keys();
      for (final key in keys) {
        if (key is String) {
          await caches.delete(key);
        }
      }
    }

    final query = Map<String, String>.from(Uri.base.queryParameters);
    query[_refreshVersionQueryKey] = targetVersion;
    query[_refreshTimeQueryKey] = DateTime.now().millisecondsSinceEpoch
        .toString();
    final refreshedUri = Uri.base.replace(queryParameters: query);
    html.window.location.replace(refreshedUri.toString());
    return true;
  } catch (_) {
    return false;
  }
}
