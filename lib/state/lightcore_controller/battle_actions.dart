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
            _coreBasicShotPower() *
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
        critChance: (_coreBaseCritChance + _gearCritChanceBonus).clamp(
          0.02,
          0.55,
        ),
        critMultiplier: _coreBaseCritMultiplier * _gearCritDamageMultiplier,
        finalDamageMultiplier: 1,
        bossDamageMultiplier: _gearBossDamageMultiplier,
        normalDamageMultiplier: 1,
        defensePenetration: 0,
        minDamageMultiplier: 1,
        maxDamageMultiplier: 1,
        progress: 0,
      ),
    );
    _tutorialCoreShotTapLearned = true;
    _core = _core.copyWith(fireSequence: sequence + 1);
    return true;
  }
}
