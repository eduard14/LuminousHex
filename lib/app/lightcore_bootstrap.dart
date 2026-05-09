import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/lightcore_cloud_save.dart';
import 'lightcore_build_info.dart';

enum LightcoreBackendMode { localFallback, firebaseBacked }

enum LightcoreIntegrityLevel { localOnly, degraded, secure }

enum LightcoreVersionGate { ok, softUpdate, hardBlock }

class LightcoreBalanceTuning {
  const LightcoreBalanceTuning({
    this.balanceEpoch = 1,
    this.active = false,
    this.maxSingleStatDelta = 0.05,
    this.maxCumulativeStatDelta = 0.25,
    this.towerMultipliers = const <String, Map<String, double>>{},
    this.enemyMultipliers = const <String, Map<String, double>>{},
    this.economyMultipliers = const <String, double>{},
  });

  static const defaults = LightcoreBalanceTuning();

  final int balanceEpoch;
  final bool active;
  final double maxSingleStatDelta;
  final double maxCumulativeStatDelta;
  final Map<String, Map<String, double>> towerMultipliers;
  final Map<String, Map<String, double>> enemyMultipliers;
  final Map<String, double> economyMultipliers;

  bool get hasOverrides =>
      active &&
      (towerMultipliers.isNotEmpty ||
          enemyMultipliers.isNotEmpty ||
          economyMultipliers.isNotEmpty);

  double towerMultiplier(String configId, String stat) =>
      _nestedMultiplier(towerMultipliers, configId, stat);

  double enemyMultiplier(String configId, String stat) =>
      _nestedMultiplier(enemyMultipliers, configId, stat);

  double economyMultiplier(String stat) =>
      active ? (economyMultipliers[stat] ?? 1.0) : 1.0;

  Map<String, dynamic> toContentHashMap() {
    return <String, dynamic>{
      'balanceEpoch': balanceEpoch,
      'active': active,
      'maxSingleStatDelta': _fixedContentDecimal(maxSingleStatDelta),
      'maxCumulativeStatDelta': _fixedContentDecimal(maxCumulativeStatDelta),
      'towerMultipliers': _nestedMultiplierContentMap(towerMultipliers),
      'enemyMultipliers': _nestedMultiplierContentMap(enemyMultipliers),
      'economyMultipliers': _multiplierContentMap(economyMultipliers),
    };
  }

  factory LightcoreBalanceTuning.fromMap(Map<String, dynamic> data) {
    final maxSingleStatDelta = _clampDouble(
      (data['maxSingleStatDelta'] as num?)?.toDouble() ?? 0.05,
      0,
      0.05,
    );
    final maxCumulativeStatDelta = _clampDouble(
      (data['maxCumulativeStatDelta'] as num?)?.toDouble() ?? 0.25,
      maxSingleStatDelta,
      0.25,
    );

    return LightcoreBalanceTuning(
      balanceEpoch: max(1, (data['balanceEpoch'] as num?)?.toInt() ?? 1),
      active: (data['active'] as bool?) ?? false,
      maxSingleStatDelta: maxSingleStatDelta,
      maxCumulativeStatDelta: maxCumulativeStatDelta,
      towerMultipliers: _coerceNestedMultiplierMap(
        data['towerMultipliers'],
        maxCumulativeStatDelta,
      ),
      enemyMultipliers: _coerceNestedMultiplierMap(
        data['enemyMultipliers'],
        maxCumulativeStatDelta,
      ),
      economyMultipliers: _coerceMultiplierMap(
        data['economyMultipliers'],
        maxCumulativeStatDelta,
      ),
    );
  }
}

class LightcoreGuestSession {
  const LightcoreGuestSession({
    required this.playerId,
    required this.createdAt,
    required this.authLabel,
  });

  final String playerId;
  final DateTime createdAt;
  final String authLabel;
}

class LightcoreContentManifest {
  const LightcoreContentManifest({
    required this.firebaseProjectId,
    required this.seasonKey,
    required this.contentEpoch,
    required this.minimumSupportedVersion,
    required this.recommendedVersion,
    required this.backendMode,
    this.minimumSupportedBuildNumber,
    this.recommendedBuildNumber,
    this.functionsRegion = 'us-central1',
    this.requiresMandatoryUpdate = false,
    this.usesRemoteContent = true,
    this.maintenanceMode = false,
    this.appCheckRequired = true,
    this.onlineFeaturesEnabled = true,
    this.offlineProgressCapSeconds = 4 * 60 * 60,
    this.balanceTuning = LightcoreBalanceTuning.defaults,
    this.contentSchemaVersion = 1,
    this.contentHash,
    this.contentHashVerified = true,
    this.statusMessage,
  });

  final String firebaseProjectId;
  final String seasonKey;
  final int contentEpoch;
  final String minimumSupportedVersion;
  final String recommendedVersion;
  final String? minimumSupportedBuildNumber;
  final String? recommendedBuildNumber;
  final LightcoreBackendMode backendMode;
  final String functionsRegion;
  final bool requiresMandatoryUpdate;
  final bool usesRemoteContent;
  final bool maintenanceMode;
  final bool appCheckRequired;
  final bool onlineFeaturesEnabled;
  final int offlineProgressCapSeconds;
  final LightcoreBalanceTuning balanceTuning;
  final int contentSchemaVersion;
  final String? contentHash;
  final bool contentHashVerified;
  final String? statusMessage;

  String get backendLabel => switch (backendMode) {
    LightcoreBackendMode.localFallback => 'Local fallback',
    LightcoreBackendMode.firebaseBacked => 'Firebase-backed',
  };

  String get minimumSupportedDisplayVersion => _joinVersionAndBuild(
    minimumSupportedVersion,
    minimumSupportedBuildNumber,
  );

  String get recommendedDisplayVersion =>
      _joinVersionAndBuild(recommendedVersion, recommendedBuildNumber);

  String get updateModeLabel {
    if (maintenanceMode) {
      return 'Server maintenance in progress';
    }
    return requiresMandatoryUpdate
        ? 'Hard update required'
        : 'Soft content refresh enabled';
  }

  bool get requiresVerifiedContent =>
      backendMode == LightcoreBackendMode.firebaseBacked && usesRemoteContent;

  bool get contentTrusted => !requiresVerifiedContent || contentHashVerified;

  String get computedContentHash => computeLightcoreContentHash(
    contentSchemaVersion: contentSchemaVersion,
    seasonKey: seasonKey,
    contentEpoch: contentEpoch,
    minimumSupportedVersion: minimumSupportedVersion,
    minimumSupportedBuildNumber: minimumSupportedBuildNumber,
    recommendedVersion: recommendedVersion,
    recommendedBuildNumber: recommendedBuildNumber,
    functionsRegion: functionsRegion,
    maintenanceMode: maintenanceMode,
    requiresMandatoryUpdate: requiresMandatoryUpdate,
    usesRemoteContent: usesRemoteContent,
    appCheckRequired: appCheckRequired,
    onlineFeaturesEnabled: onlineFeaturesEnabled,
    offlineProgressCapSeconds: offlineProgressCapSeconds,
    balanceTuning: balanceTuning,
  );

  LightcoreVersionGate versionGateFor(
    String clientVersion, {
    String? clientBuildNumber,
  }) {
    final minimumVersionCompare = compareVersionStrings(
      clientVersion,
      minimumSupportedVersion,
    );
    if (minimumVersionCompare < 0 ||
        (minimumVersionCompare == 0 &&
            _isBuildBelow(clientBuildNumber, minimumSupportedBuildNumber))) {
      return LightcoreVersionGate.hardBlock;
    }
    final recommendedVersionCompare = compareVersionStrings(
      clientVersion,
      recommendedVersion,
    );
    if (recommendedVersionCompare < 0 ||
        (recommendedVersionCompare == 0 &&
            _isBuildBelow(clientBuildNumber, recommendedBuildNumber))) {
      return LightcoreVersionGate.softUpdate;
    }
    return LightcoreVersionGate.ok;
  }

  LightcoreContentManifest copyWith({
    String? firebaseProjectId,
    String? seasonKey,
    int? contentEpoch,
    String? minimumSupportedVersion,
    String? recommendedVersion,
    String? minimumSupportedBuildNumber,
    String? recommendedBuildNumber,
    LightcoreBackendMode? backendMode,
    String? functionsRegion,
    bool? requiresMandatoryUpdate,
    bool? usesRemoteContent,
    bool? maintenanceMode,
    bool? appCheckRequired,
    bool? onlineFeaturesEnabled,
    int? offlineProgressCapSeconds,
    LightcoreBalanceTuning? balanceTuning,
    int? contentSchemaVersion,
    String? contentHash,
    bool? contentHashVerified,
    String? statusMessage,
  }) {
    return LightcoreContentManifest(
      firebaseProjectId: firebaseProjectId ?? this.firebaseProjectId,
      seasonKey: seasonKey ?? this.seasonKey,
      contentEpoch: contentEpoch ?? this.contentEpoch,
      minimumSupportedVersion:
          minimumSupportedVersion ?? this.minimumSupportedVersion,
      recommendedVersion: recommendedVersion ?? this.recommendedVersion,
      minimumSupportedBuildNumber:
          minimumSupportedBuildNumber ?? this.minimumSupportedBuildNumber,
      recommendedBuildNumber:
          recommendedBuildNumber ?? this.recommendedBuildNumber,
      backendMode: backendMode ?? this.backendMode,
      functionsRegion: functionsRegion ?? this.functionsRegion,
      requiresMandatoryUpdate:
          requiresMandatoryUpdate ?? this.requiresMandatoryUpdate,
      usesRemoteContent: usesRemoteContent ?? this.usesRemoteContent,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      appCheckRequired: appCheckRequired ?? this.appCheckRequired,
      onlineFeaturesEnabled:
          onlineFeaturesEnabled ?? this.onlineFeaturesEnabled,
      offlineProgressCapSeconds:
          offlineProgressCapSeconds ?? this.offlineProgressCapSeconds,
      balanceTuning: balanceTuning ?? this.balanceTuning,
      contentSchemaVersion: contentSchemaVersion ?? this.contentSchemaVersion,
      contentHash: contentHash ?? this.contentHash,
      contentHashVerified: contentHashVerified ?? this.contentHashVerified,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  factory LightcoreContentManifest.fromMap(
    Map<String, dynamic> data, {
    required String firebaseProjectId,
    required LightcoreBackendMode backendMode,
  }) {
    final balanceTuning = LightcoreBalanceTuning.fromMap(
      _coerceStringDynamicMap(data['balanceTuning']),
    );
    final contentSchemaVersion = max(
      1,
      (data['contentSchemaVersion'] as num?)?.toInt() ?? 1,
    );
    final contentHash = _optionalString(data['contentHash']);
    final manifest = LightcoreContentManifest(
      firebaseProjectId: firebaseProjectId,
      seasonKey: (data['seasonKey'] as String?) ?? 'season-01',
      contentEpoch: (data['contentEpoch'] as num?)?.toInt() ?? 1,
      minimumSupportedVersion:
          (data['minimumSupportedVersion'] as String?) ?? '1.0.0',
      recommendedVersion: (data['recommendedVersion'] as String?) ?? '1.0.0',
      minimumSupportedBuildNumber: _optionalString(
        data['minimumSupportedBuildNumber'],
      ),
      recommendedBuildNumber: _optionalString(data['recommendedBuildNumber']),
      backendMode: backendMode,
      functionsRegion: (data['functionsRegion'] as String?) ?? 'us-central1',
      requiresMandatoryUpdate:
          (data['requiresMandatoryUpdate'] as bool?) ?? false,
      usesRemoteContent: (data['usesRemoteContent'] as bool?) ?? true,
      maintenanceMode: (data['maintenanceMode'] as bool?) ?? false,
      appCheckRequired: (data['appCheckRequired'] as bool?) ?? true,
      onlineFeaturesEnabled: (data['onlineFeaturesEnabled'] as bool?) ?? true,
      offlineProgressCapSeconds:
          (data['offlineProgressCapSeconds'] as num?)?.toInt() ?? (4 * 60 * 60),
      balanceTuning: balanceTuning,
      contentSchemaVersion: contentSchemaVersion,
      contentHash: contentHash,
      contentHashVerified: false,
      statusMessage: data['statusMessage'] as String?,
    );
    return manifest.copyWith(
      contentHashVerified:
          contentHash != null && contentHash == manifest.computedContentHash,
    );
  }
}

class LightcorePlayerProfileSummary {
  const LightcorePlayerProfileSummary({
    required this.playerId,
    this.screenName,
    this.authUid,
    this.isAnonymous = true,
    this.lastActiveAt,
    this.lastIdleClaimAt,
    this.globalTournamentRating = 1000,
    this.activeTournamentExpMultiplier = 1.0,
    this.activeTournamentBoostEndsAt,
    this.hasPremiumMembership = false,
  });

  final String playerId;
  final String? screenName;
  final String? authUid;
  final bool isAnonymous;
  final DateTime? lastActiveAt;
  final DateTime? lastIdleClaimAt;
  final int globalTournamentRating;
  final double activeTournamentExpMultiplier;
  final DateTime? activeTournamentBoostEndsAt;
  final bool hasPremiumMembership;

  String get displayName {
    final normalized = screenName?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
    return playerId;
  }

  String get authStatusLabel {
    if (authUid == null || authUid!.isEmpty) {
      return 'Guest session';
    }
    return isAnonymous ? 'Firebase anonymous auth' : 'Authenticated account';
  }

  bool get hasActiveTournamentBoost =>
      activeTournamentExpMultiplier > 1.0 &&
      activeTournamentBoostEndsAt != null &&
      activeTournamentBoostEndsAt!.isAfter(DateTime.now());

  factory LightcorePlayerProfileSummary.fromMap(Map<String, dynamic> data) {
    return LightcorePlayerProfileSummary(
      playerId: (data['playerId'] as String?) ?? 'UNKNOWN',
      screenName: (data['screenName'] as String?)?.trim(),
      authUid: data['authUid'] as String?,
      isAnonymous: (data['isAnonymous'] as bool?) ?? true,
      lastActiveAt: _dateFromValue(data['lastActiveAt']),
      lastIdleClaimAt: _dateFromValue(data['lastIdleClaimAt']),
      globalTournamentRating:
          (data['globalTournamentRating'] as num?)?.toInt() ?? 1000,
      activeTournamentExpMultiplier:
          (data['activeTournamentExpMultiplier'] as num?)?.toDouble() ?? 1.0,
      activeTournamentBoostEndsAt: _dateFromValue(
        data['activeTournamentBoostEndsAt'],
      ),
      hasPremiumMembership: (data['hasPremiumMembership'] as bool?) ?? false,
    );
  }
}

class LightcoreOfflineProgressSnapshot {
  const LightcoreOfflineProgressSnapshot({
    required this.generatedAtMillis,
    required this.passiveLumensPerHour,
    required this.fluxPerHour,
    required this.enemyTicketsPerHour,
    required this.killsPerHour,
    required this.activeLayerTier,
    required this.builtTowerCount,
    required this.prestigeLevel,
    this.offlineRegionId,
    this.offlineRegionStabilizedLevel = 0,
    this.offlineRegionValidatedThreatDirectorId,
  });

  final int generatedAtMillis;
  final double passiveLumensPerHour;
  final double fluxPerHour;
  final double enemyTicketsPerHour;
  final double killsPerHour;
  final int activeLayerTier;
  final int builtTowerCount;
  final int prestigeLevel;
  final String? offlineRegionId;
  final int offlineRegionStabilizedLevel;
  final String? offlineRegionValidatedThreatDirectorId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'generatedAtMillis': generatedAtMillis,
      'passiveLumensPerHour': passiveLumensPerHour,
      'fluxPerHour': fluxPerHour,
      'enemyTicketsPerHour': enemyTicketsPerHour,
      'killsPerHour': killsPerHour,
      'activeLayerTier': activeLayerTier,
      'builtTowerCount': builtTowerCount,
      'prestigeLevel': prestigeLevel,
      'offlineRegionId': offlineRegionId,
      'offlineRegionStabilizedLevel': offlineRegionStabilizedLevel,
      'offlineRegionValidatedThreatDirectorId':
          offlineRegionValidatedThreatDirectorId,
    };
  }

  factory LightcoreOfflineProgressSnapshot.fromMap(Map<String, dynamic> data) {
    return LightcoreOfflineProgressSnapshot(
      generatedAtMillis: (data['generatedAtMillis'] as num?)?.toInt() ?? 0,
      passiveLumensPerHour:
          (data['passiveLumensPerHour'] as num?)?.toDouble() ?? 0,
      fluxPerHour: (data['fluxPerHour'] as num?)?.toDouble() ?? 0,
      enemyTicketsPerHour:
          (data['enemyTicketsPerHour'] as num?)?.toDouble() ?? 0,
      killsPerHour: (data['killsPerHour'] as num?)?.toDouble() ?? 0,
      activeLayerTier: (data['activeLayerTier'] as num?)?.toInt() ?? 1,
      builtTowerCount: (data['builtTowerCount'] as num?)?.toInt() ?? 0,
      prestigeLevel: (data['prestigeLevel'] as num?)?.toInt() ?? 0,
      offlineRegionId: data['offlineRegionId'] as String?,
      offlineRegionStabilizedLevel:
          (data['offlineRegionStabilizedLevel'] as num?)?.toInt() ?? 0,
      offlineRegionValidatedThreatDirectorId:
          data['offlineRegionValidatedThreatDirectorId'] as String?,
    );
  }
}

class LightcoreOfflineClaimResult {
  const LightcoreOfflineClaimResult({
    required this.secondsClaimed,
    required this.lumensGranted,
    required this.fluxGranted,
    required this.enemyTicketsGranted,
    required this.killsGranted,
    required this.serverValidated,
    this.claimIssuedAt,
    this.statusMessage,
  });

  final int secondsClaimed;
  final int lumensGranted;
  final int fluxGranted;
  final int enemyTicketsGranted;
  final int killsGranted;
  final bool serverValidated;
  final DateTime? claimIssuedAt;
  final String? statusMessage;

  bool get hasRewards =>
      lumensGranted > 0 ||
      fluxGranted > 0 ||
      enemyTicketsGranted > 0 ||
      killsGranted > 0;

  bool get hasProgress => serverValidated && secondsClaimed > 0;

  factory LightcoreOfflineClaimResult.empty({String? statusMessage}) {
    return LightcoreOfflineClaimResult(
      secondsClaimed: 0,
      lumensGranted: 0,
      fluxGranted: 0,
      enemyTicketsGranted: 0,
      killsGranted: 0,
      serverValidated: false,
      statusMessage: statusMessage,
    );
  }

  factory LightcoreOfflineClaimResult.fromMap(Map<String, dynamic> data) {
    return LightcoreOfflineClaimResult(
      secondsClaimed: (data['secondsClaimed'] as num?)?.toInt() ?? 0,
      lumensGranted: (data['lumensGranted'] as num?)?.toInt() ?? 0,
      fluxGranted: (data['fluxGranted'] as num?)?.toInt() ?? 0,
      enemyTicketsGranted: (data['enemyTicketsGranted'] as num?)?.toInt() ?? 0,
      killsGranted: (data['killsGranted'] as num?)?.toInt() ?? 0,
      serverValidated: (data['serverValidated'] as bool?) ?? false,
      claimIssuedAt: _dateFromValue(data['claimIssuedAt']),
      statusMessage: data['statusMessage'] as String?,
    );
  }
}

class LightcoreServerSyncResult {
  const LightcoreServerSyncResult({
    required this.manifest,
    required this.profile,
    required this.serverTime,
    required this.accepted,
    this.sessionId,
    this.serverDayKey,
    this.serverWeekKey,
    this.cloudSaveRevision = 0,
    this.versionGate,
  });

  final LightcoreContentManifest manifest;
  final LightcorePlayerProfileSummary profile;
  final DateTime? serverTime;
  final bool accepted;
  final String? sessionId;
  final String? serverDayKey;
  final String? serverWeekKey;
  final int cloudSaveRevision;
  final String? versionGate;
}

class LightcoreBootstrapReport {
  const LightcoreBootstrapReport({
    required this.guestSession,
    required this.clientVersion,
    required this.manifest,
    required this.profile,
    required this.offlineClaim,
    required this.integrityLevel,
    required this.firebaseReady,
    required this.serverValidated,
    required this.appCheckActive,
    this.sessionId,
    this.serverTime,
    this.serverDayKey,
    this.serverWeekKey,
    this.clientBuildNumber,
    this.cloudSave,
    this.cloudRestoreRequired = false,
    this.cloudRestoreComplete = true,
    this.warnings = const <String>[],
  });

  final LightcoreGuestSession guestSession;
  final String clientVersion;
  final String? clientBuildNumber;
  final LightcoreContentManifest manifest;
  final LightcorePlayerProfileSummary profile;
  final LightcoreOfflineClaimResult offlineClaim;
  final LightcoreIntegrityLevel integrityLevel;
  final bool firebaseReady;
  final bool serverValidated;
  final bool appCheckActive;
  final String? sessionId;
  final DateTime? serverTime;
  final String? serverDayKey;
  final String? serverWeekKey;
  final LightcoreCloudSaveEnvelope? cloudSave;
  final bool cloudRestoreRequired;
  final bool cloudRestoreComplete;
  final List<String> warnings;

  LightcoreVersionGate get versionGate => manifest.versionGateFor(
    clientVersion,
    clientBuildNumber: clientBuildNumber,
  );

  bool get requiresServerValidation =>
      manifest.backendMode == LightcoreBackendMode.firebaseBacked &&
      manifest.usesRemoteContent;

  bool get latestVersionSatisfied => versionGate == LightcoreVersionGate.ok;

  bool get versionResolved => !requiresServerValidation || serverValidated;

  bool get contentResolved =>
      !manifest.requiresVerifiedContent || manifest.contentHashVerified;

  bool get restoreResolved => !cloudRestoreRequired || cloudRestoreComplete;

  bool get hardBlocked =>
      manifest.maintenanceMode ||
      !versionResolved ||
      !latestVersionSatisfied ||
      !contentResolved ||
      !restoreResolved;

  bool get canEnterGame => !hardBlocked;

  String get requiredServerVersion => manifest.recommendedDisplayVersion;

  String get clientDisplayVersion {
    final version = clientVersion.trim();
    final build = clientBuildNumber?.trim();
    if (build == null || build.isEmpty) {
      return version;
    }
    return '$version+$build';
  }

  String get integrityLabel => switch (integrityLevel) {
    LightcoreIntegrityLevel.localOnly => 'Local-only fallback',
    LightcoreIntegrityLevel.degraded => 'Online with reduced trust',
    LightcoreIntegrityLevel.secure => 'Server validated',
  };

  String get versionLabel => switch (versionGate) {
    _ when !contentResolved => 'Content manifest verification failed',
    _ when !restoreResolved => 'Cloud save restore incomplete',
    LightcoreVersionGate.ok when !versionResolved =>
      'Awaiting server version check',
    LightcoreVersionGate.ok => 'Live version validated',
    LightcoreVersionGate.softUpdate => 'Latest live version required',
    LightcoreVersionGate.hardBlock => 'Client update required',
  };
}

LightcoreGuestSession createGuestSession({Random? random}) {
  final generator = random ?? Random.secure();
  return LightcoreGuestSession(
    playerId: _generatePlayerId(generator),
    createdAt: DateTime.now(),
    authLabel: 'Guest session',
  );
}

LightcoreContentManifest createDefaultContentManifest({
  required String firebaseProjectId,
}) {
  return LightcoreContentManifest(
    firebaseProjectId: firebaseProjectId,
    seasonKey: 'season-01',
    contentEpoch: 1,
    minimumSupportedVersion: LightcoreBuildInfo.versionName,
    recommendedVersion: LightcoreBuildInfo.versionName,
    minimumSupportedBuildNumber: LightcoreBuildInfo.buildNumber,
    recommendedBuildNumber: LightcoreBuildInfo.buildNumber,
    backendMode: LightcoreBackendMode.firebaseBacked,
  );
}

String computeLightcoreContentHash({
  required int contentSchemaVersion,
  required String seasonKey,
  required int contentEpoch,
  required String minimumSupportedVersion,
  required String? minimumSupportedBuildNumber,
  required String recommendedVersion,
  required String? recommendedBuildNumber,
  required String functionsRegion,
  required bool maintenanceMode,
  required bool requiresMandatoryUpdate,
  required bool usesRemoteContent,
  required bool appCheckRequired,
  required bool onlineFeaturesEnabled,
  required int offlineProgressCapSeconds,
  required LightcoreBalanceTuning balanceTuning,
}) {
  final payload = <String, dynamic>{
    'contentSchemaVersion': contentSchemaVersion,
    'seasonKey': seasonKey,
    'contentEpoch': contentEpoch,
    'minimumSupportedVersion': minimumSupportedVersion,
    'minimumSupportedBuildNumber': minimumSupportedBuildNumber ?? '',
    'recommendedVersion': recommendedVersion,
    'recommendedBuildNumber': recommendedBuildNumber ?? '',
    'functionsRegion': functionsRegion,
    'maintenanceMode': maintenanceMode,
    'requiresMandatoryUpdate': requiresMandatoryUpdate,
    'usesRemoteContent': usesRemoteContent,
    'appCheckRequired': appCheckRequired,
    'onlineFeaturesEnabled': onlineFeaturesEnabled,
    'offlineProgressCapSeconds': offlineProgressCapSeconds,
    'balanceTuning': balanceTuning.toContentHashMap(),
  };
  return sha256.convert(utf8.encode(jsonEncode(payload))).toString();
}

int compareVersionStrings(String left, String right) {
  final leftParts = _tokenizeVersion(left);
  final rightParts = _tokenizeVersion(right);
  final count = max(leftParts.length, rightParts.length);

  for (var index = 0; index < count; index++) {
    final leftValue = index < leftParts.length ? leftParts[index] : 0;
    final rightValue = index < rightParts.length ? rightParts[index] : 0;
    if (leftValue != rightValue) {
      return leftValue.compareTo(rightValue);
    }
  }
  return 0;
}

String _joinVersionAndBuild(String version, String? buildNumber) {
  final normalizedVersion = version.trim();
  final normalizedBuild = buildNumber?.trim();
  if (normalizedBuild == null || normalizedBuild.isEmpty) {
    return normalizedVersion;
  }
  return '$normalizedVersion+$normalizedBuild';
}

bool _isBuildBelow(String? clientBuildNumber, String? requiredBuildNumber) {
  final requiredBuild = requiredBuildNumber?.trim();
  if (requiredBuild == null || requiredBuild.isEmpty) {
    return false;
  }
  return _compareBuildNumbers(clientBuildNumber ?? '', requiredBuild) < 0;
}

int _compareBuildNumbers(String left, String right) {
  return _buildNumberValue(left).compareTo(_buildNumberValue(right));
}

int _buildNumberValue(String value) {
  final digits = RegExp(r'\d+').firstMatch(value.trim())?.group(0);
  return int.tryParse(digits ?? '0') ?? 0;
}

String? _optionalString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

List<int> _tokenizeVersion(String input) {
  final sanitized = input.trim().split(RegExp(r'[+-]')).first;
  if (sanitized.isEmpty) {
    return const <int>[0];
  }

  return sanitized
      .split('.')
      .map((part) {
        final digits = RegExp(r'\d+').firstMatch(part)?.group(0) ?? '';
        return int.tryParse(digits.isEmpty ? '0' : digits) ?? 0;
      })
      .toList(growable: false);
}

DateTime? _dateFromValue(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value is Map<String, dynamic>) {
    final millis = (value['_seconds'] as num?)?.toInt();
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis * 1000);
    }
  }
  return null;
}

double _nestedMultiplier(
  Map<String, Map<String, double>> groups,
  String configId,
  String stat,
) {
  final group = groups[configId];
  if (group == null) {
    return 1.0;
  }
  return group[stat] ?? 1.0;
}

Map<String, dynamic> _nestedMultiplierContentMap(
  Map<String, Map<String, double>> groups,
) {
  final result = <String, dynamic>{};
  final ids = groups.keys.toList()..sort();
  for (final id in ids) {
    result[id] = _multiplierContentMap(groups[id] ?? const <String, double>{});
  }
  return result;
}

Map<String, String> _multiplierContentMap(Map<String, double> multipliers) {
  final result = <String, String>{};
  final stats = multipliers.keys.toList()..sort();
  for (final stat in stats) {
    result[stat] = _fixedContentDecimal(multipliers[stat] ?? 1.0);
  }
  return result;
}

String _fixedContentDecimal(double value) => value.toStringAsFixed(4);

Map<String, dynamic> _coerceStringDynamicMap(dynamic value) {
  if (value is! Map) {
    return const <String, dynamic>{};
  }
  return <String, dynamic>{
    for (final entry in value.entries)
      if (entry.key != null) entry.key.toString(): entry.value,
  };
}

Map<String, Map<String, double>> _coerceNestedMultiplierMap(
  dynamic value,
  double maxCumulativeStatDelta,
) {
  final source = value is Map ? value : const <Object?, Object?>{};
  final result = <String, Map<String, double>>{};
  final lower = 1 - maxCumulativeStatDelta;
  final upper = 1 + maxCumulativeStatDelta;

  for (final entry in source.entries) {
    final id = entry.key?.toString().trim();
    final statSource = entry.value is Map
        ? entry.value as Map
        : const <Object?, Object?>{};
    if (id == null || id.isEmpty || statSource.isEmpty) {
      continue;
    }

    final stats = <String, double>{};
    for (final statEntry in statSource.entries) {
      final stat = statEntry.key?.toString().trim();
      final raw = statEntry.value;
      final numeric = raw is num ? raw.toDouble() : double.tryParse('$raw');
      if (stat == null || stat.isEmpty || numeric == null) {
        continue;
      }
      final clamped = _clampDouble(numeric, lower, upper);
      if ((clamped - 1).abs() > 0.0001) {
        stats[stat] = clamped;
      }
    }

    if (stats.isNotEmpty) {
      result[id] = Map<String, double>.unmodifiable(stats);
    }
  }

  return Map<String, Map<String, double>>.unmodifiable(result);
}

Map<String, double> _coerceMultiplierMap(
  dynamic value,
  double maxCumulativeStatDelta,
) {
  final source = value is Map ? value : const <Object?, Object?>{};
  final result = <String, double>{};
  final lower = 1 - maxCumulativeStatDelta;
  final upper = 1 + maxCumulativeStatDelta;

  for (final entry in source.entries) {
    final stat = entry.key?.toString().trim();
    final raw = entry.value;
    final numeric = raw is num ? raw.toDouble() : double.tryParse('$raw');
    if (stat == null || stat.isEmpty || numeric == null) {
      continue;
    }
    final clamped = _clampDouble(numeric, lower, upper);
    if ((clamped - 1).abs() > 0.0001) {
      result[stat] = clamped;
    }
  }

  return Map<String, double>.unmodifiable(result);
}

double _clampDouble(double value, double lower, double upper) {
  if (!value.isFinite) {
    return lower;
  }
  return min(upper, max(lower, value));
}

String _generatePlayerId(Random random) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String generateBlock(int length) {
    final buffer = StringBuffer();
    for (var index = 0; index < length; index++) {
      buffer.write(alphabet[random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }

  return 'LUMI-${generateBlock(4)}-${generateBlock(4)}';
}
