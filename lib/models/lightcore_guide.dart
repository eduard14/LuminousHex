enum LightcoreGuideId { lumo, luma }

class LightcoreGuideProfile {
  const LightcoreGuideProfile({
    required this.id,
    required this.displayName,
    required this.playerProfileLabel,
    required this.summary,
    required this.assetPath,
  });

  final LightcoreGuideId id;
  final String displayName;
  final String playerProfileLabel;
  final String summary;
  final String assetPath;

  String get storageId => id.name;
  String get placeholderLabel => displayName.length < 2
      ? displayName.toUpperCase()
      : displayName.substring(0, 2).toUpperCase();

  static const lumo = LightcoreGuideProfile(
    id: LightcoreGuideId.lumo,
    displayName: 'Lumo',
    playerProfileLabel: 'Boy profile',
    summary: 'Relay guide for the default pilot profile.',
    assetPath: 'assets/guides/lumo.png',
  );

  static const luma = LightcoreGuideProfile(
    id: LightcoreGuideId.luma,
    displayName: 'Luma',
    playerProfileLabel: 'Girl profile',
    summary: 'Relay guide for the alternate pilot profile.',
    assetPath: 'assets/guides/luna.png',
  );

  static const all = <LightcoreGuideProfile>[lumo, luma];

  static LightcoreGuideProfile? maybeFromStorageId(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final guide in all) {
      if (guide.storageId == value) {
        return guide;
      }
    }
    return null;
  }
}
