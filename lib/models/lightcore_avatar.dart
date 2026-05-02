import 'lightcore_guide.dart';
import 'lightcore_types.dart';

enum AvatarCosmeticType { hair, face }

enum LightcoreAvatarPose { idle, move, boost, thrust }

class AvatarCosmeticConfig {
  const AvatarCosmeticConfig({
    required this.id,
    required this.type,
    required this.name,
    required this.summary,
    required this.assetPath,
    required this.pricePrismShards,
    required this.rarity,
  });

  final String id;
  final AvatarCosmeticType type;
  final String name;
  final String summary;
  final String assetPath;
  final int pricePrismShards;
  final ManagerRarity rarity;

  bool get isPremium => pricePrismShards > 0;
}

class AvatarCosmeticLoadout {
  const AvatarCosmeticLoadout({this.hairId, this.faceId});

  static const empty = AvatarCosmeticLoadout();

  final String? hairId;
  final String? faceId;

  bool get isEmpty => hairId == null && faceId == null;

  String? idForType(AvatarCosmeticType type) => switch (type) {
    AvatarCosmeticType.hair => hairId,
    AvatarCosmeticType.face => faceId,
  };
}

class LightcoreAvatarEquipmentPiece {
  const LightcoreAvatarEquipmentPiece({
    required this.slotType,
    required this.setId,
    required this.affinity,
    required this.rarity,
  });

  final EquipmentInventorySlot slotType;
  final String setId;
  final PrototypeAffinity affinity;
  final ManagerRarity rarity;

  String get assetPath =>
      'assets/sprites/equipment/$setId/${slotType.name}.png';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'slotType': slotType.name,
      'setId': setId,
      'affinity': affinity.name,
      'rarity': rarity.name,
    };
  }

  static LightcoreAvatarEquipmentPiece? fromMap(Map<String, dynamic> data) {
    final slotType = _enumByName(
      EquipmentInventorySlot.values,
      _stringOrNull(data['slotType']),
    );
    final affinity = _enumByName(
      PrototypeAffinity.values,
      _stringOrNull(data['affinity']),
    );
    final rarity = _enumByName(
      ManagerRarity.values,
      _stringOrNull(data['rarity']),
    );
    final setId = _stringOrNull(data['setId']);
    if (slotType == null ||
        affinity == null ||
        rarity == null ||
        setId == null) {
      return null;
    }
    return LightcoreAvatarEquipmentPiece(
      slotType: slotType,
      setId: setId,
      affinity: affinity,
      rarity: rarity,
    );
  }
}

class LightcoreAvatarProfile {
  const LightcoreAvatarProfile({
    required this.guideId,
    this.hairCosmeticId,
    this.faceCosmeticId,
    this.equipmentPieces = const <LightcoreAvatarEquipmentPiece>[],
  });

  static const empty = LightcoreAvatarProfile(
    guideId: 'lumo',
    equipmentPieces: <LightcoreAvatarEquipmentPiece>[],
  );

  final String guideId;
  final String? hairCosmeticId;
  final String? faceCosmeticId;
  final List<LightcoreAvatarEquipmentPiece> equipmentPieces;

  LightcoreGuideProfile get guideProfile =>
      LightcoreGuideProfile.maybeFromStorageId(guideId) ??
      LightcoreGuideProfile.lumo;

  AvatarCosmeticLoadout get cosmeticLoadout =>
      AvatarCosmeticLoadout(hairId: hairCosmeticId, faceId: faceCosmeticId);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'guideId': guideId,
      'hairCosmeticId': hairCosmeticId,
      'faceCosmeticId': faceCosmeticId,
      'equipmentPieces': equipmentPieces
          .map((piece) => piece.toMap())
          .toList(growable: false),
    };
  }

  static LightcoreAvatarProfile fromMap(Map<String, dynamic> data) {
    final guideId = _stringOrNull(data['guideId']) ?? empty.guideId;
    final pieces = _listValue(data['equipmentPieces'])
        .map((item) => LightcoreAvatarEquipmentPiece.fromMap(_mapValue(item)))
        .whereType<LightcoreAvatarEquipmentPiece>()
        .take(6)
        .toList(growable: false);
    return LightcoreAvatarProfile(
      guideId: guideId,
      hairCosmeticId: _stringOrNull(data['hairCosmeticId']),
      faceCosmeticId: _stringOrNull(data['faceCosmeticId']),
      equipmentPieces: pieces,
    );
  }
}

T? _enumByName<T extends Enum>(Iterable<T> values, String? name) {
  if (name == null || name.isEmpty) {
    return null;
  }
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return null;
}

String? _stringOrNull(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

Map<String, dynamic> _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, dynamic item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

List<dynamic> _listValue(dynamic value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}
