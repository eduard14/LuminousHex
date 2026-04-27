import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class LightcoreFirebaseRuntimeConfig {
  const LightcoreFirebaseRuntimeConfig({
    required this.projectId,
    required this.messagingSenderId,
    this.functionsRegion = 'us-central1',
    this.storageBucket = '',
    this.webApiKey = '',
    this.webAppId = '',
    this.webAuthDomain = '',
    this.androidApiKey = '',
    this.androidAppId = '',
    this.iosApiKey = '',
    this.iosAppId = '',
    this.iosBundleId = '',
    this.appCheckWebSiteKey = '',
    this.googleIosClientId = '',
    this.googleServerClientId = '',
  });

  final String projectId;
  final String messagingSenderId;
  final String functionsRegion;
  final String storageBucket;
  final String webApiKey;
  final String webAppId;
  final String webAuthDomain;
  final String androidApiKey;
  final String androidAppId;
  final String iosApiKey;
  final String iosAppId;
  final String iosBundleId;
  final String appCheckWebSiteKey;
  final String googleIosClientId;
  final String googleServerClientId;

  bool get hasWebOptions =>
      webApiKey.isNotEmpty &&
      webAppId.isNotEmpty &&
      messagingSenderId.isNotEmpty;

  bool get hasAndroidOptions =>
      androidApiKey.isNotEmpty &&
      androidAppId.isNotEmpty &&
      messagingSenderId.isNotEmpty;

  bool get hasIosOptions =>
      iosApiKey.isNotEmpty &&
      iosAppId.isNotEmpty &&
      messagingSenderId.isNotEmpty;

  bool get hasWebAppCheckSiteKey => appCheckWebSiteKey.isNotEmpty;

  bool get canInitializeOnCurrentPlatform {
    if (kIsWeb) {
      return hasWebOptions;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return hasAndroidOptions;
      case TargetPlatform.iOS:
        return hasIosOptions;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  FirebaseOptions? get currentPlatformOptions {
    if (kIsWeb) {
      if (!hasWebOptions) {
        return null;
      }

      return FirebaseOptions(
        apiKey: webApiKey,
        appId: webAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: webAuthDomain.isEmpty ? null : webAuthDomain,
        storageBucket: storageBucket.isEmpty ? null : storageBucket,
      );
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android when hasAndroidOptions => FirebaseOptions(
        apiKey: androidApiKey,
        appId: androidAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket.isEmpty ? null : storageBucket,
      ),
      TargetPlatform.iOS when hasIosOptions => FirebaseOptions(
        apiKey: iosApiKey,
        appId: iosAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket.isEmpty ? null : storageBucket,
        iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
      ),
      _ => null,
    };
  }
}

const lightcoreFirebaseRuntimeConfig = LightcoreFirebaseRuntimeConfig(
  projectId: 'lumicore-95c8a',
  messagingSenderId: '215700700025',
  storageBucket: 'lumicore-95c8a.firebasestorage.app',
  webApiKey: 'AIzaSyCTkDHho5MQX_gVbqJZOh6yeSsKbQLqezY',
  webAppId: '1:215700700025:web:fc173ca0a1f6960fc94da8',
  webAuthDomain: 'lumicore-95c8a.firebaseapp.com',
  androidApiKey: 'AIzaSyBKQ5PJLPXtdO8EL2GiNVXgkcSVs0c_vIg',
  androidAppId: '1:215700700025:android:12bef50951968e28c94da8',
  iosApiKey: 'AIzaSyDYOgk5YV9izPxI6caYKYZOO7KXyVioesU',
  iosAppId: '1:215700700025:ios:11d7d2bc63c624ecc94da8',
  iosBundleId: 'com.example.lightcore',
);
