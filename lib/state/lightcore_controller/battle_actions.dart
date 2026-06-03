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
    if (_ammoQueue.length >= coreQueueCapacity) {
      if (showBanner) {
        _showBanner('Core charge is full. Focus an anomaly to fire first.');
      }
      return false;
    }
    if (activeLayer.tier == 1 && _core.packetCooldownRemaining > 0) {
      if (showBanner) {
        _showBanner(
          'Lightcore shot charging for ${_core.packetCooldownRemaining.toStringAsFixed(1)}s.',
        );
      }
      return false;
    }

    final sequence = _core.fireSequence;
    final projectileType = _coreProjectileTypeForSequence(sequence);
    final payloadType = _corePayloadTypeForSequence(sequence);
    _ammoQueue.add(
      AmmoPacket(
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
        critChance: coreCritChance,
        critMultiplier: coreCritMultiplier,
        finalDamageMultiplier: coreFinalDamageMultiplier,
        bossDamageMultiplier: coreBossDamageMultiplier,
        normalDamageMultiplier: coreNormalDamageMultiplier,
        defensePenetration: coreDefensePenetration,
        minDamageMultiplier: coreMinDamageMultiplier,
        maxDamageMultiplier: coreMaxDamageMultiplier,
      ),
    );
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

  bool debugAdvancePulseToCore(String pulseId) {
    final index = _pulses.indexWhere((pulse) => pulse.id == pulseId);
    if (index == -1) {
      return false;
    }
    _pulses[index] = _pulses[index].copyWith(
      progress: max(_pulses[index].progress, 0.985),
      inboundStartedAtElapsed: elapsed,
    );
    if (_tutorialStep == LightcoreTutorialStep.inspectSecondShellTower) {
      _tutorialSecondShellTowerInspected = true;
    }
    _syncTutorialStep(showBanner: false);
    _notifyNow();
    return true;
  }
}
