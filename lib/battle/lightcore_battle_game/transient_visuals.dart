part of '../lightcore_battle_game.dart';

extension LightcoreBattleGameTransientVisuals on LightcoreBattleGame {
  void _syncSlotVisuals() {
    final activeLayerId = controller.activeLayer.id;
    if (_previousSlotCharge.length == controller.slots.length &&
        _slotVisualLayerId == activeLayerId) {
      return;
    }
    _slotVisualLayerId = activeLayerId;
    _previousSlotCharge = controller.slots
        .map((slot) => slot.charge.clamp(0, 1).toDouble())
        .toList(growable: false);
    _previousSlotBuilt = controller.slots
        .map((slot) => slot.isBuilt)
        .toList(growable: false);
    _previousSlotFabricating = controller.slots
        .map((slot) => slot.isFabricating)
        .toList(growable: false);
    _previousSlotChildBuiltCount = controller.slots
        .map((slot) => slot.childBuiltCount)
        .toList(growable: false);
    _slotHexChargePopRemaining = List<double>.filled(
      controller.slots.length,
      0,
      growable: false,
    );
    _slotBuildBurstRemaining = List<double>.filled(
      controller.slots.length,
      0,
      growable: false,
    );
    _slotFuseBurstRemaining = List<double>.filled(
      controller.slots.length,
      0,
      growable: false,
    );
  }

  void _syncCoreVisuals() {
    final activeLayerId = controller.activeLayer.id;
    if (_coreVisualLayerId == activeLayerId) {
      return;
    }
    _coreVisualLayerId = activeLayerId;
    _previousCoreFireSequence = controller.coreState.fireSequence;
    _previousCoreDamageSequence = controller.coreDamageSequence;
    _knownCoreShotIds = controller.shots
        .where((shot) => !shot.layer2)
        .map((shot) => shot.id)
        .toSet();
    _knownShotIds = controller.shots.map((shot) => shot.id).toSet();
    _knownImpactIds = controller.impacts.map((impact) => impact.id).toSet();
    _knownEnemyIds = controller.enemies.map((enemy) => enemy.id).toSet();
    _shotFireBursts = <_ShotFireBurst>[];
    _coreHexFirePopRemaining = 0;
    _screenShakeRemaining = 0;
    _screenShakeAmplitude = 0;
    _screenShakeOffset = Vector2.zero();
  }

  void _syncLevelUpRadianceVisuals() {
    final sequence = controller.levelUpRadianceSequence;
    if (sequence == _knownLevelUpRadianceSequence) {
      return;
    }
    _knownLevelUpRadianceSequence = sequence;
    if (sequence <= 0) {
      return;
    }
    _screenShakeRemaining = math.max(_screenShakeRemaining, 0.36);
    _screenShakeAmplitude = math.max(_screenShakeAmplitude, _coreRadius * 0.07);
    _coreHexFirePopRemaining = math.max(
      _coreHexFirePopRemaining,
      LightcoreBattleGame._hexChargePopDuration,
    );
    LightcoreAudio.instance.playSfx(LightcoreSfx.rewardClaim);
  }

  void _syncCombatAudio() {
    final currentEnemyIds = controller.enemies.map((enemy) => enemy.id).toSet();
    for (final enemy in controller.enemies) {
      if (_knownEnemyIds.contains(enemy.id)) {
        continue;
      }
      LightcoreAudio.instance.playSfx(
        enemy.config.isBoss ? LightcoreSfx.bossSpawn : LightcoreSfx.enemySpawn,
      );
    }

    final currentImpactIds = controller.impacts
        .map((impact) => impact.id)
        .toSet();
    for (final impact in controller.impacts) {
      if (_knownImpactIds.contains(impact.id)) {
        continue;
      }
      if (impact.lethal) {
        final isBossSized = impact.defeatedEnemySizeScale >= 1.35;
        LightcoreAudio.instance.playSfx(
          isBossSized ? LightcoreSfx.bossDeath : LightcoreSfx.enemyDeath,
        );
      } else if (impact.critical) {
        LightcoreAudio.instance.playSfx(LightcoreSfx.critHit);
      } else {
        LightcoreAudio.instance.playSfx(LightcoreSfx.hit);
      }
    }

    _knownEnemyIds = currentEnemyIds;
    _knownImpactIds = currentImpactIds;
  }

  void _updateSlotVisuals(double dt) {
    for (var index = 0; index < controller.slots.length; index++) {
      final slot = controller.slots[index];
      final currentCharge = slot.charge.clamp(0, 1).toDouble();
      final previousCharge = _previousSlotCharge[index];
      final currentlyBuilt = slot.isBuilt;
      final wasBuilt = _previousSlotBuilt[index];
      final filledThisFrame = currentCharge >= 0.995 && previousCharge < 0.995;
      final firedAfterFill = previousCharge >= 0.9 && currentCharge <= 0.12;
      final currentFabricating = slot.isFabricating;
      final wasFabricating = _previousSlotFabricating[index];
      final currentChildBuiltCount = slot.childBuiltCount;
      final previousChildBuiltCount = _previousSlotChildBuiltCount[index];

      if (controller.isSlotActiveTower(slot) &&
          (filledThisFrame || firedAfterFill)) {
        _slotHexChargePopRemaining[index] =
            LightcoreBattleGame._hexChargePopDuration;
        if (filledThisFrame) {
          LightcoreAudio.instance.playSfx(LightcoreSfx.relayCharge);
        }
      } else if (_slotHexChargePopRemaining[index] > 0) {
        _slotHexChargePopRemaining[index] = math.max(
          0,
          _slotHexChargePopRemaining[index] - dt,
        );
      }

      if (!wasBuilt && currentlyBuilt) {
        _slotBuildBurstRemaining[index] =
            LightcoreBattleGame._slotBuildBurstDuration;
        LightcoreAudio.instance.playSfx(LightcoreSfx.buildTower);
      } else if (wasFabricating && !currentFabricating) {
        _slotBuildBurstRemaining[index] =
            LightcoreBattleGame._slotBuildBurstDuration;
        LightcoreAudio.instance.playSfx(LightcoreSfx.buildTower);
      } else if (_slotBuildBurstRemaining[index] > 0) {
        _slotBuildBurstRemaining[index] = math.max(
          0,
          _slotBuildBurstRemaining[index] - dt,
        );
      }

      if (controller.isSlotLayerProject(slot) &&
          currentChildBuiltCount > previousChildBuiltCount) {
        _slotFuseBurstRemaining[index] =
            LightcoreBattleGame._slotFuseBurstDuration;
        LightcoreAudio.instance.playSfx(LightcoreSfx.promotionComplete);
      } else if (_slotFuseBurstRemaining[index] > 0) {
        _slotFuseBurstRemaining[index] = math.max(
          0,
          _slotFuseBurstRemaining[index] - dt,
        );
      }

      _previousSlotCharge[index] = currentCharge;
      _previousSlotBuilt[index] = currentlyBuilt;
      _previousSlotFabricating[index] = currentFabricating;
      _previousSlotChildBuiltCount[index] = currentChildBuiltCount;
    }
  }

  void _updateCoreVisuals(double dt) {
    final coreShotIds = controller.shots
        .where((shot) => !shot.layer2)
        .map((shot) => shot.id)
        .toSet();
    final hasNewCoreShot = coreShotIds.any(
      (id) => !_knownCoreShotIds.contains(id),
    );
    final coreSequenceChanged =
        controller.coreState.fireSequence != _previousCoreFireSequence;

    if (hasNewCoreShot || coreSequenceChanged) {
      _coreHexFirePopRemaining = LightcoreBattleGame._hexChargePopDuration;
      LightcoreAudio.instance.playSfx(LightcoreSfx.coreFire);
    } else if (_coreHexFirePopRemaining > 0) {
      _coreHexFirePopRemaining = math.max(0, _coreHexFirePopRemaining - dt);
    }

    final coreDamageSequence = controller.coreDamageSequence;
    if (coreDamageSequence != _previousCoreDamageSequence) {
      _startCoreDamageShake(controller.coreDamageAmount);
      LightcoreAudio.instance.playSfx(LightcoreSfx.coreDamage);
    }

    _knownCoreShotIds = coreShotIds;
    _previousCoreFireSequence = controller.coreState.fireSequence;
    _previousCoreDamageSequence = coreDamageSequence;
  }

  void _updateShotFireBursts(double dt) {
    final currentShotIds = controller.shots.map((shot) => shot.id).toSet();
    for (final shot in controller.shots) {
      if (_knownShotIds.contains(shot.id)) {
        continue;
      }
      _shotFireBursts = <_ShotFireBurst>[
        ..._shotFireBursts,
        _ShotFireBurst.fromShot(shot),
      ];
    }

    _shotFireBursts = _shotFireBursts
        .map((burst) => burst.copyWith(elapsed: burst.elapsed + dt))
        .where(
          (burst) => burst.elapsed < LightcoreBattleGame._shotFireBurstDuration,
        )
        .toList(growable: false);
    _knownShotIds = currentShotIds;
  }

  void _startCoreDamageShake(double stabilityDamage) {
    final shortest = math.min(size.x, size.y);
    final baseAmplitude = shortest * 0.006;
    final damageAmplitude =
        math.sqrt(stabilityDamage.clamp(0.0, 100.0)) * shortest * 0.0014;
    _screenShakeAmplitude = math.max(
      _screenShakeAmplitude,
      (baseAmplitude + damageAmplitude).clamp(3.0, shortest * 0.018),
    );
    _screenShakeRemaining = LightcoreBattleGame._coreDamageShakeDuration;
  }
}
