const int lightcoreCloudSaveSchemaVersion = 1;

class LightcoreCloudSaveEnvelope {
  const LightcoreCloudSaveEnvelope({
    required this.schemaVersion,
    required this.revision,
    required this.payload,
    this.updatedAt,
  });

  final int schemaVersion;
  final int revision;
  final DateTime? updatedAt;
  final Map<String, dynamic> payload;

  bool get hasPayload => payload.isNotEmpty;

  String? get guideStorageId {
    final playerData = payload['player'];
    if (playerData is! Map) {
      return null;
    }
    final guideId = playerData['guideId'];
    if (guideId is! String) {
      return null;
    }
    final normalized = guideId.trim();
    return normalized.isEmpty ? null : normalized;
  }

  factory LightcoreCloudSaveEnvelope.fromMap(Map<String, dynamic> data) {
    return LightcoreCloudSaveEnvelope(
      schemaVersion:
          (data['schemaVersion'] as num?)?.toInt() ??
          lightcoreCloudSaveSchemaVersion,
      revision: (data['revision'] as num?)?.toInt() ?? 0,
      updatedAt: _dateFromValue(data['updatedAt']),
      payload: _coerceMap(data['payload']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'revision': revision,
      'updatedAt': updatedAt?.toIso8601String(),
      'payload': payload,
    };
  }
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
