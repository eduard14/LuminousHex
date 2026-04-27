enum LightcoreSocialInviteLinkKind {
  friend,
  mentor;

  String get wireKey => switch (this) {
    LightcoreSocialInviteLinkKind.friend => 'friend',
    LightcoreSocialInviteLinkKind.mentor => 'mentor',
  };

  String get label => switch (this) {
    LightcoreSocialInviteLinkKind.friend => 'friend',
    LightcoreSocialInviteLinkKind.mentor => 'mentor',
  };

  static LightcoreSocialInviteLinkKind? fromWireKey(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'friend' => LightcoreSocialInviteLinkKind.friend,
      'mentor' => LightcoreSocialInviteLinkKind.mentor,
      _ => null,
    };
  }
}

class LightcoreSocialInviteLink {
  const LightcoreSocialInviteLink({required this.kind, required this.target});

  static const inviteQueryKey = 'socialInvite';
  static const targetQueryKey = 'target';

  final LightcoreSocialInviteLinkKind kind;
  final String target;

  bool get isValid => target.trim().isNotEmpty;

  factory LightcoreSocialInviteLink.fromUri(Uri uri) {
    final kind = LightcoreSocialInviteLinkKind.fromWireKey(
      uri.queryParameters[inviteQueryKey] ??
          uri.queryParameters['invite'] ??
          uri.queryParameters['social'],
    );
    final target =
        uri.queryParameters[targetQueryKey] ??
        uri.queryParameters['player'] ??
        uri.queryParameters['mentor'] ??
        '';
    return LightcoreSocialInviteLink(
      kind: kind ?? LightcoreSocialInviteLinkKind.friend,
      target: target.trim(),
    );
  }

  static LightcoreSocialInviteLink? maybeFromUri(Uri uri) {
    if (!uri.queryParameters.containsKey(inviteQueryKey) &&
        !uri.queryParameters.containsKey('invite') &&
        !uri.queryParameters.containsKey('social')) {
      return null;
    }
    final link = LightcoreSocialInviteLink.fromUri(uri);
    return link.isValid ? link : null;
  }
}

String buildLightcoreSocialInviteUrl({
  required Uri currentUri,
  required String fallbackHost,
  required LightcoreSocialInviteLinkKind kind,
  required String target,
}) {
  final normalizedTarget = target.trim();
  final baseUri = _usableCurrentUri(currentUri)
      ? currentUri
      : Uri.parse('https://$fallbackHost/');

  return baseUri
      .replace(
        queryParameters: <String, String>{
          LightcoreSocialInviteLink.inviteQueryKey: kind.wireKey,
          LightcoreSocialInviteLink.targetQueryKey: normalizedTarget,
        },
        fragment: null,
      )
      .toString();
}

bool _usableCurrentUri(Uri uri) {
  return uri.hasScheme &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}
