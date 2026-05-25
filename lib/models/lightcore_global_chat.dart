class LightcoreGlobalChatMessage {
  const LightcoreGlobalChatMessage({
    required this.id,
    required this.authorUid,
    required this.authorLabel,
    required this.message,
    required this.sentAtMillis,
    this.whisperTargetUid,
    this.whisperTargetLabel,
    this.isLocalPlayer = false,
    this.isSystem = false,
  });

  final String id;
  final String authorUid;
  final String authorLabel;
  final String message;
  final int sentAtMillis;
  final String? whisperTargetUid;
  final String? whisperTargetLabel;
  final bool isLocalPlayer;
  final bool isSystem;

  bool get isWhisper => whisperTargetUid != null;

  factory LightcoreGlobalChatMessage.fromMap(Map<String, dynamic> data) {
    final whisperTargetUid = _stringValue(data['whisperTargetUid']);
    return LightcoreGlobalChatMessage(
      id: _stringValue(data['id']),
      authorUid: _stringValue(data['authorUid']),
      authorLabel: _stringValue(data['authorLabel'], fallback: 'Player'),
      message: _stringValue(data['message']),
      sentAtMillis: (data['sentAtMillis'] as num?)?.toInt() ?? 0,
      whisperTargetUid: whisperTargetUid.isEmpty ? null : whisperTargetUid,
      whisperTargetLabel: _stringValue(data['whisperTargetLabel']).isEmpty
          ? null
          : _stringValue(data['whisperTargetLabel']),
      isLocalPlayer: data['isLocalPlayer'] == true,
      isSystem: data['isSystem'] == true,
    );
  }
}

class LightcoreGlobalChatOverview {
  const LightcoreGlobalChatOverview({
    required this.messages,
    this.chatBanUntilMillis,
    this.accountBanned = false,
    this.warningMessage,
  });

  final List<LightcoreGlobalChatMessage> messages;
  final int? chatBanUntilMillis;
  final bool accountBanned;
  final String? warningMessage;

  bool get chatBanned {
    final until = chatBanUntilMillis;
    return until != null && until > DateTime.now().millisecondsSinceEpoch;
  }

  factory LightcoreGlobalChatOverview.fromMap(Map<String, dynamic> data) {
    final messages = _listValue(data['messages'])
        .map((item) => _mapValue(item))
        .map(LightcoreGlobalChatMessage.fromMap)
        .toList(growable: false);
    final warning = _stringValue(data['warningMessage']);
    return LightcoreGlobalChatOverview(
      messages: messages,
      chatBanUntilMillis: (data['chatBanUntilMillis'] as num?)?.toInt(),
      accountBanned: data['accountBanned'] == true,
      warningMessage: warning.isEmpty ? null : warning,
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

List<dynamic> _listValue(Object? value) {
  return value is List ? value : const <dynamic>[];
}

Map<String, dynamic> _mapValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}
