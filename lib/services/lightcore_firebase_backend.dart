import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../app/lightcore_bootstrap.dart';
import '../models/lightcore_cloud_save.dart';
import '../models/lightcore_social_state.dart';
import '../models/lightcore_tournament.dart';
import 'lightcore_firebase_runtime_config.dart';

class LightcoreScreenNameUpdateException implements Exception {
  const LightcoreScreenNameUpdateException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class LightcoreSessionExpiredException implements Exception {
  const LightcoreSessionExpiredException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class LightcoreCloudSaveConflictException
    extends LightcoreSessionExpiredException {
  const LightcoreCloudSaveConflictException(super.message, [super.cause]);
}

enum LightcoreGoogleAccountCollisionResolution {
  switchToExistingSave,
  replaceExistingSave,
}

class LightcoreGoogleAccountCollisionException implements Exception {
  const LightcoreGoogleAccountCollisionException({
    required this.message,
    this.email,
    this.cause,
  });

  final String message;
  final String? email;
  final Object? cause;

  @override
  String toString() => message;
}

class FirebaseLightcoreBackend {
  FirebaseLightcoreBackend({required this.runtimeConfig});

  final LightcoreFirebaseRuntimeConfig runtimeConfig;
  LightcoreCloudSaveEnvelope? _cachedCloudSave;
  String? _activeSessionId;
  _PendingGoogleAccountCollision? _pendingGoogleAccountCollision;

  LightcoreCloudSaveEnvelope? get cachedCloudSave => _cachedCloudSave;

  bool get canUseCloudSave {
    if (Firebase.apps.isEmpty) {
      return false;
    }
    return FirebaseAuth.instance.currentUser != null;
  }

  bool get hasRecoverableAccount {
    if (Firebase.apps.isEmpty) {
      return false;
    }
    final user = FirebaseAuth.instance.currentUser;
    return user != null && !user.isAnonymous;
  }

  bool get isCurrentUserAnonymous {
    if (Firebase.apps.isEmpty) {
      return false;
    }
    return FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
  }

  String? get currentAuthEmail {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    final email = FirebaseAuth.instance.currentUser?.email?.trim();
    return email == null || email.isEmpty ? null : email;
  }

  String get currentAuthProviderLabel {
    if (Firebase.apps.isEmpty) {
      return 'Cloud';
    }
    final providers =
        FirebaseAuth.instance.currentUser?.providerData
            .map((provider) => provider.providerId)
            .toSet() ??
        const <String>{};
    if (providers.contains('apple.com')) {
      return 'Apple ID';
    }
    if (providers.contains('password')) {
      return 'Email';
    }
    if (providers.contains('google.com')) {
      return 'Google';
    }
    return 'Cloud';
  }

  Future<LightcoreBootstrapReport> bootstrap({
    required LightcoreGuestSession guestSession,
    required String clientVersion,
    String? clientBuildNumber,
  }) async {
    var manifest = createDefaultContentManifest(
      firebaseProjectId: runtimeConfig.projectId,
    );
    final warnings = <String>[];
    var firebaseReady = false;
    var serverValidated = false;
    var appCheckActive = false;
    var profile = LightcorePlayerProfileSummary(
      playerId: guestSession.playerId,
    );
    DateTime? serverTime;
    String? serverDayKey;
    String? serverWeekKey;
    LightcoreCloudSaveEnvelope? cloudSave;
    var cloudRestoreRequired = false;
    var cloudRestoreComplete = true;
    var offlineClaim = LightcoreOfflineClaimResult.empty(
      statusMessage: 'No offline rewards available yet.',
    );

    if (!runtimeConfig.canInitializeOnCurrentPlatform) {
      warnings.add(
        'Firebase is not configured for this platform yet. Main menu is running in local fallback mode.',
      );
      return LightcoreBootstrapReport(
        guestSession: guestSession,
        clientVersion: clientVersion,
        clientBuildNumber: clientBuildNumber,
        manifest: manifest.copyWith(
          statusMessage:
              'Online startup requires a Firebase-configured web, Android, or iOS build.',
        ),
        profile: profile,
        offlineClaim: offlineClaim,
        integrityLevel: LightcoreIntegrityLevel.localOnly,
        firebaseReady: false,
        serverValidated: false,
        appCheckActive: false,
        sessionId: null,
        serverTime: null,
        serverDayKey: null,
        serverWeekKey: null,
        cloudSave: null,
        warnings: warnings,
      );
    }

    try {
      await _ensureFirebaseInitialized();
      firebaseReady = true;
    } catch (error) {
      warnings.add('Firebase init failed: $error');
      return LightcoreBootstrapReport(
        guestSession: guestSession,
        clientVersion: clientVersion,
        clientBuildNumber: clientBuildNumber,
        manifest: manifest.copyWith(
          statusMessage:
              'Online startup failed. Connect to the internet and retry.',
        ),
        profile: profile,
        offlineClaim: offlineClaim,
        integrityLevel: LightcoreIntegrityLevel.localOnly,
        firebaseReady: false,
        serverValidated: false,
        appCheckActive: false,
        sessionId: null,
        serverTime: null,
        serverDayKey: null,
        serverWeekKey: null,
        cloudSave: null,
        warnings: warnings,
      );
    }

    try {
      appCheckActive = await _activateAppCheck();
      if (!appCheckActive) {
        warnings.add('App Check is not active on this client.');
      }
    } catch (error) {
      warnings.add('App Check activation failed: $error');
    }

    try {
      final existingUser = FirebaseAuth.instance.currentUser;
      final user =
          existingUser ??
          (await FirebaseAuth.instance.signInAnonymously()).user;
      profile = _buildAuthBackedProfileSummary(
        user: user,
        fallbackPlayerId: guestSession.playerId,
      );
    } catch (error) {
      warnings.add('Anonymous auth failed: $error');
    }

    try {
      manifest = await _fetchRemoteManifest(defaultManifest: manifest);
    } catch (error) {
      warnings.add('Remote Config fetch failed: $error');
    }

    if (FirebaseAuth.instance.currentUser != null) {
      try {
        final result = await _callBootstrapClient(
          guestSession: guestSession,
          clientVersion: clientVersion,
          clientBuildNumber: clientBuildNumber,
          defaultManifest: manifest,
        );
        manifest = result.manifest;
        profile = result.profile;
        _activeSessionId = result.sessionId;
        serverTime = result.serverTime;
        serverDayKey = result.serverDayKey;
        serverWeekKey = result.serverWeekKey;
        serverValidated = true;
      } catch (error) {
        warnings.add('Server bootstrap validation failed: $error');
      }

      if (serverValidated) {
        try {
          profile = await _fetchProfileFromFirestore(fallbackProfile: profile);
        } catch (error) {
          warnings.add('Firestore profile read failed: $error');
        }
      }

      var cloudSaveLoaded = false;
      var offlineClaimLoaded = false;
      cloudRestoreRequired = canUseCloudSave;
      cloudRestoreComplete = !cloudRestoreRequired;
      if (canUseCloudSave) {
        try {
          cloudSave = await loadPlayerSave();
          cloudSaveLoaded = true;
        } catch (error) {
          warnings.add('Cloud save load failed: $error');
        }
      }

      if (cloudSaveLoaded) {
        try {
          offlineClaim = await claimOfflineProgress();
          offlineClaimLoaded = true;
        } catch (error) {
          warnings.add('Offline claim failed: $error');
        }
      }
      cloudRestoreComplete =
          !cloudRestoreRequired || (cloudSaveLoaded && offlineClaimLoaded);
    }

    _cachedCloudSave = cloudSave;
    return LightcoreBootstrapReport(
      guestSession: guestSession,
      clientVersion: clientVersion,
      clientBuildNumber: clientBuildNumber,
      manifest: manifest,
      profile: profile,
      offlineClaim: offlineClaim,
      integrityLevel: _resolveIntegrityLevel(
        firebaseReady: firebaseReady,
        serverValidated: serverValidated,
        appCheckActive: appCheckActive,
      ),
      firebaseReady: firebaseReady,
      serverValidated: serverValidated,
      appCheckActive: appCheckActive,
      sessionId: _activeSessionId,
      serverTime: serverTime,
      serverDayKey: serverDayKey,
      serverWeekKey: serverWeekKey,
      cloudSave: cloudSave,
      cloudRestoreRequired: cloudRestoreRequired,
      cloudRestoreComplete: cloudRestoreComplete,
      warnings: warnings,
    );
  }

  Future<LightcoreServerSyncResult> syncOfflineSnapshot(
    LightcoreOfflineProgressSnapshot snapshot, {
    String? clientVersion,
    String? clientBuildNumber,
  }) async {
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      throw StateError('Server sync requires Firebase authentication.');
    }

    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('syncIdleSnapshot');

    final payload = <String, dynamic>{
      'snapshot': snapshot.toMap(),
      'platform': _platformLabel,
      if (_activeSessionId != null) 'sessionId': _activeSessionId,
    };
    if (clientVersion != null) {
      payload['clientVersion'] = clientVersion;
    }
    if (clientBuildNumber != null) {
      payload['clientBuildNumber'] = clientBuildNumber;
    }

    final HttpsCallableResult<Map<String, dynamic>> result;
    try {
      result = await callable.call<Map<String, dynamic>>(payload);
    } on FirebaseFunctionsException catch (error) {
      throw _mapSessionAwareCallableException(error);
    }
    return _serverSyncResultFromMap(_coerceMap(result.data));
  }

  Future<void> signInWithGoogle({bool requireAnonymousLink = false}) async {
    await _ensureFirebaseInitialized();
    final auth = FirebaseAuth.instance;
    final currentUser =
        auth.currentUser ?? (await auth.signInAnonymously()).user;

    if (kIsWeb) {
      final provider = GoogleAuthProvider()..addScope('email');
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          await currentUser.linkWithPopup(provider);
          await _refreshCurrentAuthToken();
          return;
        } on FirebaseAuthException catch (error) {
          if (!_isGoogleCredentialCollision(error)) {
            rethrow;
          }
          _throwGoogleAccountCollision(error: error, webProvider: provider);
        }
      }
      _clearAuthScopedCache();
      await auth.signInWithPopup(provider);
      await _refreshCurrentAuthToken();
      return;
    }

    final signIn = GoogleSignIn.instance;
    await signIn.initialize(
      clientId: _googleClientIdForCurrentPlatform,
      serverClientId: runtimeConfig.googleServerClientId.isEmpty
          ? null
          : runtimeConfig.googleServerClientId,
    );
    final googleUser = await signIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google Sign-In completed without an ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    if (currentUser != null && currentUser.isAnonymous) {
      try {
        await currentUser.linkWithCredential(credential);
        await _refreshCurrentAuthToken();
        return;
      } on FirebaseAuthException catch (error) {
        if (!_isGoogleCredentialCollision(error)) {
          rethrow;
        }
        _throwGoogleAccountCollision(
          error: error,
          credential: credential,
          email: googleUser.email,
        );
      }
    }

    _clearAuthScopedCache();
    await auth.signInWithCredential(credential);
    await _refreshCurrentAuthToken();
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
    bool requireAnonymousLink = false,
  }) async {
    await _ensureFirebaseInitialized();
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw StateError('Email and password are required.');
    }

    final auth = FirebaseAuth.instance;
    final currentUser =
        auth.currentUser ?? (await auth.signInAnonymously()).user;
    final credential = EmailAuthProvider.credential(
      email: normalizedEmail,
      password: password,
    );

    if (currentUser != null && currentUser.isAnonymous) {
      if (requireAnonymousLink) {
        try {
          await currentUser.linkWithCredential(credential);
          await _refreshCurrentAuthToken();
          return;
        } on FirebaseAuthException catch (error) {
          if (_isEmailAlreadyLinked(error)) {
            throw StateError(
              'That email already has a LumiHex cloud save. Sign out first if you want to switch saves.',
            );
          }
          rethrow;
        }
      }

      try {
        _clearAuthScopedCache();
        await auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
        await _refreshCurrentAuthToken();
        return;
      } on FirebaseAuthException catch (error) {
        if (!_isMissingEmailAccount(error)) {
          rethrow;
        }
      }

      await currentUser.linkWithCredential(credential);
      await _refreshCurrentAuthToken();
      return;
    }

    _clearAuthScopedCache();
    await auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    await _refreshCurrentAuthToken();
  }

  Future<void> signInWithApplePlaceholder() async {
    throw UnsupportedError(
      'Apple ID cloud saves are reserved for the release auth pass.',
    );
  }

  Future<void> resolvePendingGoogleAccountCollision(
    LightcoreGoogleAccountCollisionResolution resolution,
  ) async {
    await _ensureFirebaseInitialized();
    final pending = _pendingGoogleAccountCollision;
    if (pending == null) {
      throw StateError(
        'No Google account collision is waiting for a decision.',
      );
    }

    switch (resolution) {
      case LightcoreGoogleAccountCollisionResolution.switchToExistingSave:
        await _signInWithPendingGoogleCollision(pending);
        break;
      case LightcoreGoogleAccountCollisionResolution.replaceExistingSave:
        final replacementCredential = await _signInWithPendingGoogleCollision(
          pending,
        );
        await _deleteSignedInPlayerAccount();
        await FirebaseAuth.instance.signOut();
        _clearAuthScopedCache();
        await _linkPendingGoogleToFreshAnonymousUser(
          pending,
          credential: replacementCredential,
        );
        break;
    }

    _pendingGoogleAccountCollision = null;
  }

  void cancelPendingGoogleAccountCollision() {
    _pendingGoogleAccountCollision = null;
  }

  Future<void> deleteCurrentPlayerAccount() async {
    await _ensureFirebaseInitialized();
    await _deleteSignedInPlayerAccount();
    await FirebaseAuth.instance.signOut();
    _clearAuthScopedCache();
  }

  Future<void> signOutToGuest() async {
    _cachedCloudSave = null;
    _activeSessionId = null;
    _pendingGoogleAccountCollision = null;
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {
      // Google Sign-In state is best-effort and should not block logout.
    }

    if (Firebase.apps.isNotEmpty) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<LightcoreCloudSaveEnvelope?> loadPlayerSave() async {
    if (!canUseCloudSave) {
      _cachedCloudSave = null;
      return null;
    }

    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('getPlayerSave');

    final result = await callable.call<Map<String, dynamic>>(
      <String, dynamic>{},
    );
    final data = _coerceMap(result.data);
    final saveData = _coerceMap(data['save']);
    if (saveData.isEmpty) {
      _cachedCloudSave = null;
      return null;
    }

    final save = LightcoreCloudSaveEnvelope.fromMap(saveData);
    _cachedCloudSave = save;
    return save;
  }

  Future<LightcoreCloudSaveEnvelope> savePlayerSave(
    Map<String, dynamic> payload, {
    String? clientVersion,
    String? clientBuildNumber,
  }) async {
    if (!canUseCloudSave) {
      throw StateError('Cloud save requires Firebase authentication.');
    }

    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('savePlayerSave');

    final request = <String, dynamic>{
      'schemaVersion': lightcoreCloudSaveSchemaVersion,
      'baseRevision': _cachedCloudSave?.revision,
      'payload': payload,
      if (_activeSessionId != null) 'sessionId': _activeSessionId,
    };
    if (clientVersion != null) {
      request['clientVersion'] = clientVersion;
    }
    if (clientBuildNumber != null) {
      request['clientBuildNumber'] = clientBuildNumber;
    }

    final HttpsCallableResult<Map<String, dynamic>> result;
    try {
      result = await callable.call<Map<String, dynamic>>(request);
    } on FirebaseFunctionsException catch (error) {
      throw _mapSessionAwareCallableException(error);
    }
    final data = _coerceMap(result.data);
    final saveData = _coerceMap(data['save']);
    if (saveData.isEmpty) {
      throw StateError('No cloud save payload returned from savePlayerSave.');
    }

    final save = LightcoreCloudSaveEnvelope.fromMap(saveData);
    _cachedCloudSave = save;
    return save;
  }

  Future<void> resetPlayerSave() async {
    if (!canUseCloudSave) {
      _cachedCloudSave = null;
      return;
    }

    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('resetPlayerSave');
    try {
      await callable.call<Map<String, dynamic>>(<String, dynamic>{
        if (_activeSessionId != null) 'sessionId': _activeSessionId,
      });
    } on FirebaseFunctionsException catch (error) {
      throw _mapSessionAwareCallableException(error);
    }
    _cachedCloudSave = null;
  }

  Future<LightcoreTournamentOverview> fetchTournamentOverview() async {
    await _ensureTournamentBackendReady();
    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('getTournamentOverview');

    final result = await callable.call<Map<String, dynamic>>(
      <String, dynamic>{},
    );
    return LightcoreTournamentOverview.fromMap(_coerceMap(result.data));
  }

  Future<LightcoreTournamentOverview> joinTournamentQueue({
    required LightcoreTournamentModeId mode,
    required LightcoreTournamentPlayerSnapshot snapshot,
  }) async {
    await _ensureTournamentBackendReady();
    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('joinTournamentQueue');

    final result = await callable.call<Map<String, dynamic>>(<String, dynamic>{
      'mode': mode.wireKey,
      'snapshot': snapshot.toMap(),
    });
    return LightcoreTournamentOverview.fromMap(_coerceMap(result.data));
  }

  Future<LightcoreTournamentOverview> submitTournamentRun({
    required LightcoreTournamentModeId mode,
    required int score,
    required LightcoreTournamentPlayerSnapshot snapshot,
  }) async {
    await _ensureTournamentBackendReady();
    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('submitTournamentRun');

    final result = await callable.call<Map<String, dynamic>>(<String, dynamic>{
      'mode': mode.wireKey,
      'score': score,
      'snapshot': snapshot.toMap(),
    });
    return LightcoreTournamentOverview.fromMap(_coerceMap(result.data));
  }

  Future<LightcoreTournamentClaimResult> claimTournamentReward({
    required LightcoreTournamentModeId mode,
  }) async {
    await _ensureTournamentBackendReady();
    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('claimTournamentReward');

    final result = await callable.call<Map<String, dynamic>>(<String, dynamic>{
      'mode': mode.wireKey,
    });
    return LightcoreTournamentClaimResult.fromMap(_coerceMap(result.data));
  }

  Future<LightcorePlayerProfileSummary> updateScreenName({
    required String screenName,
  }) async {
    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('updateScreenName');

    final HttpsCallableResult<Map<String, dynamic>> result;
    try {
      result = await callable.call<Map<String, dynamic>>(<String, dynamic>{
        'screenName': screenName,
      });
    } on FirebaseFunctionsException catch (error) {
      throw LightcoreScreenNameUpdateException(
        _screenNameUpdateErrorMessage(error),
        error,
      );
    }
    final data = _coerceMap(result.data);
    final profileData = _coerceMap(data['profile']);
    if (profileData.isEmpty) {
      throw StateError('No profile payload returned after screen-name update.');
    }
    return LightcorePlayerProfileSummary.fromMap(profileData);
  }

  String _screenNameUpdateErrorMessage(FirebaseFunctionsException error) {
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return switch (error.code) {
      'already-exists' => 'That screen name is already taken.',
      'invalid-argument' => 'Enter a valid screen name.',
      'failed-precondition' =>
        'Create or sync your player profile before changing your screen name.',
      _ => 'Unable to verify that screen name right now.',
    };
  }

  Future<LightcoreSocialOverview> fetchSocialOverview() async {
    await _ensureSocialBackendReady();
    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('getSocialOverview');

    final result = await callable.call<Map<String, dynamic>>(
      <String, dynamic>{},
    );
    return LightcoreSocialOverview.fromMap(_coerceMap(result.data));
  }

  Future<LightcoreSocialOverview> sendMentorInvite({
    required String target,
  }) async {
    return _callSocialOverviewMutation(
      functionName: 'sendMentorInvite',
      payload: <String, dynamic>{'target': target},
    );
  }

  Future<LightcoreSocialOverview> respondMentorInvite({
    required String inviteId,
    required bool accept,
  }) async {
    return _callSocialOverviewMutation(
      functionName: 'respondMentorInvite',
      payload: <String, dynamic>{'inviteId': inviteId, 'accept': accept},
    );
  }

  Future<LightcoreSocialOverview> acceptMentorLink({
    required String mentor,
  }) async {
    return _callSocialOverviewMutation(
      functionName: 'acceptMentorLink',
      payload: <String, dynamic>{'mentor': mentor},
    );
  }

  Future<LightcoreSocialOverview> sendFriendRequest({
    required String target,
  }) async {
    return _callSocialOverviewMutation(
      functionName: 'sendFriendRequest',
      payload: <String, dynamic>{'target': target},
    );
  }

  Future<LightcoreSocialOverview> respondFriendRequest({
    required String requestId,
    required bool accept,
  }) async {
    return _callSocialOverviewMutation(
      functionName: 'respondFriendRequest',
      payload: <String, dynamic>{'requestId': requestId, 'accept': accept},
    );
  }

  Future<LightcoreSocialOverview> sendBossPullGift({
    required String friendUid,
  }) async {
    return _callSocialOverviewMutation(
      functionName: 'sendBossPullGift',
      payload: <String, dynamic>{'friendUid': friendUid},
    );
  }

  Future<LightcoreBossGiftSendResult> sendAllBossPullGifts() async {
    await _ensureSocialBackendReady();
    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('sendAllBossPullGifts');

    final result = await callable.call<Map<String, dynamic>>(
      const <String, dynamic>{},
    );
    return LightcoreBossGiftSendResult.fromMap(_coerceMap(result.data));
  }

  Future<LightcoreBossGiftClaimResult> claimBossPullGift({
    required String fromUid,
  }) async {
    await _ensureSocialBackendReady();
    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('claimBossPullGift');

    final result = await callable.call<Map<String, dynamic>>(<String, dynamic>{
      'fromUid': fromUid,
    });
    return LightcoreBossGiftClaimResult.fromMap(_coerceMap(result.data));
  }

  Future<LightcoreBossGiftClaimResult> claimAllBossPullGifts() async {
    await _ensureSocialBackendReady();
    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('claimAllBossPullGifts');

    final result = await callable.call<Map<String, dynamic>>(
      const <String, dynamic>{},
    );
    return LightcoreBossGiftClaimResult.fromMap(_coerceMap(result.data));
  }

  Future<LightcoreSocialOverview> _callSocialOverviewMutation({
    required String functionName,
    required Map<String, dynamic> payload,
  }) async {
    await _ensureSocialBackendReady();
    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable(functionName);

    final result = await callable.call<Map<String, dynamic>>(payload);
    final data = _coerceMap(result.data);
    final overviewData = _coerceMap(data['overview']);
    return LightcoreSocialOverview.fromMap(
      overviewData.isEmpty ? data : overviewData,
    );
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    final options = runtimeConfig.currentPlatformOptions;
    if (options != null) {
      await Firebase.initializeApp(options: options);
      return;
    }

    await Firebase.initializeApp();
  }

  Future<bool> _activateAppCheck() async {
    final appCheck = FirebaseAppCheck.instance;

    if (kIsWeb) {
      if (!runtimeConfig.hasWebAppCheckSiteKey) {
        return false;
      }

      await appCheck.activate(
        providerWeb: ReCaptchaV3Provider(runtimeConfig.appCheckWebSiteKey),
      );
      return true;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await appCheck.activate(
          providerAndroid: const AndroidPlayIntegrityProvider(),
        );
        return true;
      case TargetPlatform.iOS:
        await appCheck.activate(
          providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
        return true;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  Future<void> _ensureTournamentBackendReady() async {
    if (!runtimeConfig.canInitializeOnCurrentPlatform) {
      throw StateError(
        'Tournaments require Firebase-backed web, Android, or iOS configuration. This platform is running in local fallback mode.',
      );
    }
    await _ensureFirebaseInitialized();
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  Future<void> _ensureSocialBackendReady() async {
    if (!runtimeConfig.canInitializeOnCurrentPlatform) {
      throw StateError(
        'Friends require Firebase-backed web, Android, or iOS configuration. This platform is running in local fallback mode.',
      );
    }
    await _ensureFirebaseInitialized();
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  Future<LightcoreContentManifest> _fetchRemoteManifest({
    required LightcoreContentManifest defaultManifest,
  }) async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setDefaults(<String, dynamic>{
      'season_key': defaultManifest.seasonKey,
      'content_epoch': defaultManifest.contentEpoch,
      'minimum_supported_version': defaultManifest.minimumSupportedVersion,
      'minimum_supported_build_number':
          defaultManifest.minimumSupportedBuildNumber ?? '',
      'recommended_version': defaultManifest.recommendedVersion,
      'recommended_build_number': defaultManifest.recommendedBuildNumber ?? '',
      'maintenance_mode': defaultManifest.maintenanceMode,
      'requires_mandatory_update': defaultManifest.requiresMandatoryUpdate,
      'uses_remote_content': defaultManifest.usesRemoteContent,
      'app_check_required': defaultManifest.appCheckRequired,
      'online_features_enabled': defaultManifest.onlineFeaturesEnabled,
      'offline_progress_cap_seconds': defaultManifest.offlineProgressCapSeconds,
      'status_message': defaultManifest.statusMessage ?? '',
      'functions_region': defaultManifest.functionsRegion,
    });
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 12),
        // Startup uses the manifest as a launch gate, so always fetch fresh.
        minimumFetchInterval: Duration.zero,
      ),
    );
    await remoteConfig.fetchAndActivate();

    return LightcoreContentManifest(
      firebaseProjectId: runtimeConfig.projectId,
      seasonKey: remoteConfig.getString('season_key'),
      contentEpoch: remoteConfig.getInt('content_epoch'),
      minimumSupportedVersion: remoteConfig.getString(
        'minimum_supported_version',
      ),
      minimumSupportedBuildNumber: _emptyToNull(
        remoteConfig.getString('minimum_supported_build_number'),
      ),
      recommendedVersion: remoteConfig.getString('recommended_version'),
      recommendedBuildNumber: _emptyToNull(
        remoteConfig.getString('recommended_build_number'),
      ),
      backendMode: LightcoreBackendMode.firebaseBacked,
      functionsRegion: remoteConfig.getString('functions_region').isEmpty
          ? defaultManifest.functionsRegion
          : remoteConfig.getString('functions_region'),
      maintenanceMode: remoteConfig.getBool('maintenance_mode'),
      requiresMandatoryUpdate: remoteConfig.getBool(
        'requires_mandatory_update',
      ),
      usesRemoteContent: remoteConfig.getBool('uses_remote_content'),
      appCheckRequired: remoteConfig.getBool('app_check_required'),
      onlineFeaturesEnabled: remoteConfig.getBool('online_features_enabled'),
      offlineProgressCapSeconds: remoteConfig.getInt(
        'offline_progress_cap_seconds',
      ),
      statusMessage: remoteConfig.getString('status_message').isEmpty
          ? null
          : remoteConfig.getString('status_message'),
    );
  }

  Future<_BootstrapCallableResult> _callBootstrapClient({
    required LightcoreGuestSession guestSession,
    required String clientVersion,
    String? clientBuildNumber,
    required LightcoreContentManifest defaultManifest,
  }) async {
    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('bootstrapClient');

    final result = await callable.call<Map<String, dynamic>>(<String, dynamic>{
      'playerId': guestSession.playerId,
      'clientVersion': clientVersion,
      'clientBuildNumber': clientBuildNumber,
      'platform': _platformLabel,
      'appCheckActive': false,
    });

    final data = _coerceMap(result.data);
    final manifestData = _coerceMap(data['manifest']);
    final profileData = _coerceMap(data['profile']);

    final manifest = manifestData.isEmpty
        ? defaultManifest
        : LightcoreContentManifest.fromMap(
            manifestData,
            firebaseProjectId: runtimeConfig.projectId,
            backendMode: LightcoreBackendMode.firebaseBacked,
          );

    final profile = profileData.isEmpty
        ? _buildAuthBackedProfileSummary(
            user: FirebaseAuth.instance.currentUser,
            fallbackPlayerId: guestSession.playerId,
          )
        : LightcorePlayerProfileSummary.fromMap(profileData);

    return _BootstrapCallableResult(
      manifest: manifest,
      profile: profile,
      sessionId: data['sessionId'] as String?,
      serverTime: _dateFromValue(data['serverTime']),
      serverDayKey: data['serverDayKey'] as String?,
      serverWeekKey: data['serverWeekKey'] as String?,
    );
  }

  Future<LightcoreOfflineClaimResult> claimOfflineProgress() async {
    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('claimOfflineProgress');

    final HttpsCallableResult<Map<String, dynamic>> result;
    try {
      result = await callable.call<Map<String, dynamic>>(<String, dynamic>{
        if (_activeSessionId != null) 'sessionId': _activeSessionId,
      });
    } on FirebaseFunctionsException catch (error) {
      throw _mapSessionAwareCallableException(error);
    }
    final data = _coerceMap(result.data);
    if (data.isEmpty) {
      return LightcoreOfflineClaimResult.empty(
        statusMessage: 'No server offline claim payload returned.',
      );
    }
    return LightcoreOfflineClaimResult.fromMap(data);
  }

  LightcoreServerSyncResult _serverSyncResultFromMap(
    Map<String, dynamic> data,
  ) {
    final manifestData = _coerceMap(data['manifest']);
    final profileData = _coerceMap(data['profile']);
    final manifest = manifestData.isEmpty
        ? createDefaultContentManifest(
            firebaseProjectId: runtimeConfig.projectId,
          )
        : LightcoreContentManifest.fromMap(
            manifestData,
            firebaseProjectId: runtimeConfig.projectId,
            backendMode: LightcoreBackendMode.firebaseBacked,
          );
    return LightcoreServerSyncResult(
      manifest: manifest,
      profile: profileData.isEmpty
          ? const LightcorePlayerProfileSummary(playerId: 'LUMI-0000-0000')
          : LightcorePlayerProfileSummary.fromMap(profileData),
      serverTime: _dateFromValue(data['serverTime']),
      accepted: data['accepted'] == true,
      sessionId: data['sessionId'] as String? ?? _activeSessionId,
      serverDayKey: data['serverDayKey'] as String?,
      serverWeekKey: data['serverWeekKey'] as String?,
      cloudSaveRevision: (data['cloudSaveRevision'] as num?)?.toInt() ?? 0,
      versionGate: data['versionGate'] as String?,
    );
  }

  Future<LightcorePlayerProfileSummary> _fetchProfileFromFirestore({
    required LightcorePlayerProfileSummary fallbackProfile,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return fallbackProfile;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('playerProfiles')
        .doc(user.uid)
        .get();
    final data = snapshot.data();
    if (data == null || data.isEmpty) {
      return fallbackProfile;
    }

    return LightcorePlayerProfileSummary.fromMap(
      _withCurrentAuthDetails(
        user: user,
        data: <String, dynamic>{
          ...data,
          'playerId': data['playerId'] ?? fallbackProfile.playerId,
        },
      ),
    );
  }

  Future<LightcorePlayerProfileSummary> purchasePremiumMembership() async {
    if (!runtimeConfig.canInitializeOnCurrentPlatform) {
      throw StateError(
        'Premium membership sync is unavailable on this platform while Firebase is in local fallback mode.',
      );
    }

    await _ensureFirebaseInitialized();
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('purchasePremiumMembership');

    final result = await callable.call<Map<String, dynamic>>(
      <String, dynamic>{},
    );
    final data = _coerceMap(result.data);
    final profileData = _coerceMap(data['profile']);
    if (profileData.isEmpty) {
      throw StateError(
        'No profile payload returned after premium membership purchase.',
      );
    }
    return LightcorePlayerProfileSummary.fromMap(profileData);
  }

  LightcoreIntegrityLevel _resolveIntegrityLevel({
    required bool firebaseReady,
    required bool serverValidated,
    required bool appCheckActive,
  }) {
    if (!firebaseReady) {
      return LightcoreIntegrityLevel.localOnly;
    }
    if (serverValidated && appCheckActive) {
      return LightcoreIntegrityLevel.secure;
    }
    return LightcoreIntegrityLevel.degraded;
  }

  Map<String, dynamic> _coerceMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, dynamic item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }

  DateTime? _dateFromValue(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is Map<String, dynamic>) {
      final seconds = (value['_seconds'] as num?)?.toInt();
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }
    return null;
  }

  Exception _mapSessionAwareCallableException(
    FirebaseFunctionsException error,
  ) {
    final message = error.message?.trim();
    if (error.code == 'aborted') {
      return LightcoreCloudSaveConflictException(
        message == null || message.isEmpty
            ? 'Cloud save changed on another device. Reload latest save.'
            : message,
        error,
      );
    }
    if (error.code == 'failed-precondition' &&
        message != null &&
        message.toLowerCase().contains('session expired')) {
      return LightcoreSessionExpiredException(message, error);
    }
    return error;
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String get _platformLabel {
    if (kIsWeb) {
      return 'web';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  LightcorePlayerProfileSummary _buildAuthBackedProfileSummary({
    required User? user,
    required String fallbackPlayerId,
  }) {
    return LightcorePlayerProfileSummary.fromMap(
      _withCurrentAuthDetails(
        user: user,
        data: <String, dynamic>{'playerId': fallbackPlayerId},
      ),
    );
  }

  Map<String, dynamic> _withCurrentAuthDetails({
    required User? user,
    required Map<String, dynamic> data,
  }) {
    if (user == null) {
      return data;
    }
    return <String, dynamic>{
      ...data,
      'authUid': user.uid,
      'isAnonymous': user.isAnonymous,
      if (user.email != null && user.email!.isNotEmpty) 'authEmail': user.email,
      if (user.providerData.isNotEmpty)
        'authProviderIds': user.providerData
            .map((provider) => provider.providerId)
            .where((providerId) => providerId.isNotEmpty)
            .toList(growable: false),
    };
  }

  String? get _googleClientIdForCurrentPlatform {
    if (kIsWeb) {
      return null;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS
          when runtimeConfig.googleIosClientId.isNotEmpty =>
        runtimeConfig.googleIosClientId,
      _ => null,
    };
  }

  bool _isGoogleCredentialCollision(FirebaseAuthException error) {
    return error.code == 'credential-already-in-use' ||
        error.code == 'account-exists-with-different-credential' ||
        error.code == 'provider-already-linked';
  }

  bool _isEmailAlreadyLinked(FirebaseAuthException error) {
    return error.code == 'email-already-in-use' ||
        error.code == 'credential-already-in-use' ||
        error.code == 'provider-already-linked';
  }

  bool _isMissingEmailAccount(FirebaseAuthException error) {
    return error.code == 'user-not-found';
  }

  Never _throwGoogleAccountCollision({
    required FirebaseAuthException error,
    AuthCredential? credential,
    GoogleAuthProvider? webProvider,
    String? email,
  }) {
    final normalizedEmail = _emptyToNull(email ?? error.email ?? '');
    _pendingGoogleAccountCollision = _PendingGoogleAccountCollision(
      credential: error.credential ?? credential,
      webProvider: webProvider,
      email: normalizedEmail,
    );
    throw LightcoreGoogleAccountCollisionException(
      message: normalizedEmail == null
          ? 'That Google account is already linked to another LumiHex save.'
          : 'That Google account ($normalizedEmail) is already linked to another LumiHex save.',
      email: normalizedEmail,
      cause: error,
    );
  }

  Future<AuthCredential?> _signInWithPendingGoogleCollision(
    _PendingGoogleAccountCollision pending,
  ) async {
    final auth = FirebaseAuth.instance;
    final UserCredential userCredential;
    if (kIsWeb) {
      userCredential = await auth.signInWithPopup(
        pending.webProvider ?? _googleAuthProvider(),
      );
    } else {
      final credential = pending.credential;
      if (credential == null) {
        throw StateError('Google Sign-In must be restarted to continue.');
      }
      userCredential = await auth.signInWithCredential(credential);
    }
    _clearAuthScopedCache();
    await _refreshCurrentAuthToken();
    return userCredential.credential ?? pending.credential;
  }

  Future<void> _linkPendingGoogleToFreshAnonymousUser(
    _PendingGoogleAccountCollision pending, {
    AuthCredential? credential,
  }) async {
    final auth = FirebaseAuth.instance;
    final user = (await auth.signInAnonymously()).user;
    if (user == null) {
      throw StateError('Could not create a replacement guest account.');
    }

    final resolvedCredential = credential ?? pending.credential;
    if (resolvedCredential != null) {
      await user.linkWithCredential(resolvedCredential);
    } else if (kIsWeb) {
      await user.linkWithPopup(pending.webProvider ?? _googleAuthProvider());
    } else {
      throw StateError('Google Sign-In must be restarted to continue.');
    }
    await _refreshCurrentAuthToken();
  }

  Future<void> _deleteSignedInPlayerAccount() async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('No signed-in LumiHex account is available to delete.');
    }

    final callable = FirebaseFunctions.instanceFor(
      region: runtimeConfig.functionsRegion,
    ).httpsCallable('deleteCurrentPlayerAccount');
    await callable.call<Map<String, dynamic>>(<String, dynamic>{});
    _clearAuthScopedCache();
  }

  GoogleAuthProvider _googleAuthProvider() {
    return GoogleAuthProvider()..addScope('email');
  }

  void _clearAuthScopedCache() {
    _cachedCloudSave = null;
    _activeSessionId = null;
  }

  Future<void> _refreshCurrentAuthToken() async {
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
  }
}

class _PendingGoogleAccountCollision {
  const _PendingGoogleAccountCollision({
    required this.credential,
    required this.webProvider,
    required this.email,
  });

  final AuthCredential? credential;
  final GoogleAuthProvider? webProvider;
  final String? email;
}

class _BootstrapCallableResult {
  const _BootstrapCallableResult({
    required this.manifest,
    required this.profile,
    required this.sessionId,
    required this.serverTime,
    required this.serverDayKey,
    required this.serverWeekKey,
  });

  final LightcoreContentManifest manifest;
  final LightcorePlayerProfileSummary profile;
  final String? sessionId;
  final DateTime? serverTime;
  final String? serverDayKey;
  final String? serverWeekKey;
}
