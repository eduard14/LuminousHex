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
    if (_floatingPulseCountForSource(null) >= _maxFloatingPayloadsPerSource) {
      if (showBanner) {
        _showBanner(
          'Lightcore payloads are already floating. Catch one or let one enter the queue.',
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
        progress: _payloadOrbitStartProgress,
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

  bool boostPulseToCore(String pulseId) {
    final index = _pulses.indexWhere((pulse) => pulse.id == pulseId);
    if (index == -1) {
      return false;
    }
    _pulses[index] = _pulses[index].copyWith(progress: 0.92);
    if (_tutorialStep == LightcoreTutorialStep.tapSecondShellTower) {
      _tutorialSecondShellShotTapLearned = true;
    }
    _syncTutorialStep(showBanner: false);
    _notifyNow();
    return true;
  }

  bool markPulseCriticalBoosted(String pulseId) {
    final index = _pulses.indexWhere((pulse) => pulse.id == pulseId);
    if (index == -1) {
      return false;
    }
    _pulses[index] = _pulses[index].copyWith(criticalBoosted: true);
    _notifyNow();
    return true;
  }

  bool releaseDraggedPulse(String pulseId, {required bool crossedSourceTower}) {
    if (crossedSourceTower) {
      markPulseCriticalBoosted(pulseId);
    }
    return boostPulseToCore(pulseId);
  }
}
