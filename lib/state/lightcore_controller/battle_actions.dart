part of '../lightcore_controller.dart';

extension LightcoreControllerBattleActions on LightcoreController {
  bool _queueCoreBasicAttack({bool showBanner = false}) {
    if (activeLayerPassiveOnly) {
      if (showBanner) {
        _showBanner(
          '$activeLayerLabel is a static archive. Return to a live shell to fire.',
        );
      }
      return false;
    }
    if ((_ammoQueue.length + _pulses.length) >= coreQueueCapacity) {
      if (showBanner) {
        _showBanner(
          'Core queue full. Wait for the Lightcore to fire or upgrade queue capacity.',
        );
      }
      return false;
    }
    if (activeLayer.tier == 1 && _core.packetCooldownRemaining > 0) {
      if (showBanner) {
        _showBanner(
          'Lightcore packet charging for ${_core.packetCooldownRemaining.toStringAsFixed(1)}s.',
        );
      }
      return false;
    }

    final sequence = _core.fireSequence;
    final projectileType = _coreProjectileTypeForSequence(sequence);
    final payloadType = _corePayloadTypeForSequence(sequence);
    _pulses.add(
      EnergyPulseState(
        id: 'core_packet_${_pulseCounter++}',
        sourceSlotIndex: null,
        affinity: _coreAffinityForProjectile(projectileType),
        secondaryAffinity: _coreSecondaryAffinityForPayload(payloadType),
        power:
            coreBasicShotPower *
            friendAllianceCombatMultiplier *
            _gearPowerMultiplier,
        advantageMultiplier: 1,
        projectileType: projectileType,
        payloadType: payloadType,
        targetPriority: TargetPriority.close,
        range: coreEffectiveRangeForUpgradeLevel(
          _core.rangeUpgradeLevel,
          projectileType: projectileType,
        ),
        generationSpeed: coreShotsPerSecondForUpgradeLevel(
          _core.fireSpeedUpgradeLevel,
          projectileType: projectileType,
        ),
        critChance: coreCritChance,
        critMultiplier: coreCritMultiplier,
        finalDamageMultiplier: coreFinalDamageMultiplier,
        bossDamageMultiplier: coreBossDamageMultiplier,
        normalDamageMultiplier: coreNormalDamageMultiplier,
        defensePenetration: coreDefensePenetration,
        minDamageMultiplier: coreMinDamageMultiplier,
        maxDamageMultiplier: coreMaxDamageMultiplier,
        progress: 0,
      ),
    );
    _tutorialCoreShotTapLearned = true;
    _core = _core.copyWith(
      fireSequence: sequence + 1,
      packetCooldownRemaining: activeLayer.tier == 1
          ? coreShotCooldownForUpgradeLevel(
              _core.fireSpeedUpgradeLevel,
              projectileType: projectileType,
            )
          : 0,
    );
    return true;
  }
}
