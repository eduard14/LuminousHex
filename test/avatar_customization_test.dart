import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/avatar_cosmetic_configs.dart';
import 'package:lightcore/models/lightcore_avatar.dart';
import 'package:lightcore/models/lightcore_guide.dart';
import 'package:lightcore/models/lightcore_social_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void main() {
  test(
    'premium avatar cosmetic purchase equips and survives cloud restore',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      final hair = AvatarCosmeticCatalog.byType(AvatarCosmeticType.hair).first;
      controller.grantPrismShards(
        amount: hair.pricePrismShards,
        sourceLabel: 'Test',
        showBanner: false,
      );

      expect(controller.purchaseAvatarCosmetic(hair.id), isTrue);
      expect(controller.isAvatarCosmeticUnlocked(hair.id), isTrue);
      expect(controller.avatarCosmeticLoadout.hairId, hair.id);
      expect(controller.prismShards, 0);

      final restored = LightcoreController.fromCloudSavePayload(
        controller.buildCloudSavePayload(),
      );
      addTearDown(restored.dispose);

      expect(restored.isAvatarCosmeticUnlocked(hair.id), isTrue);
      expect(restored.avatarCosmeticLoadout.hairId, hair.id);
      expect(restored.publicAvatarProfile.hairCosmeticId, hair.id);
    },
  );

  test('social player carries public avatar icon data', () {
    final face = AvatarCosmeticCatalog.byType(AvatarCosmeticType.face).last;
    final player = LightcoreSocialPlayer.fromMap(<String, dynamic>{
      'uid': 'remote-player',
      'playerId': 'LUMI-TEST-0001',
      'displayName': 'Remote Pilot',
      'avatar': <String, dynamic>{
        'guideId': LightcoreGuideProfile.luma.storageId,
        'faceCosmeticId': face.id,
        'equipmentPieces': <Map<String, dynamic>>[
          <String, dynamic>{
            'slotType': EquipmentInventorySlot.hat.name,
            'setId': 'surveyor',
            'affinity': PrototypeAffinity.neutral.name,
            'rarity': ManagerRarity.rare.name,
          },
        ],
      },
    });

    expect(player.avatar.guideProfile, LightcoreGuideProfile.luma);
    expect(player.avatar.faceCosmeticId, face.id);
    expect(player.avatar.equipmentPieces.single.setId, 'surveyor');
  });
}
