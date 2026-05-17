function createPlayerSaveHelpers({ db, logger, HttpsError, constants, helpers }) {
  const {
    PROFILE_COLLECTION,
    PRIVATE_PROFILE_COLLECTION,
    PLAYER_SAVE_DOCUMENT,
    PLAYER_SAVE_SCHEMA_VERSION,
    PLAYER_SAVE_LIMITS,
    SAVE_INTEGRITY_LIMITS,
    SERVER_BALANCE_LIMITS,
    SNAPSHOT_LIMITS,
  } = constants;
  const {
    clampInt,
    clampNumber,
    sanitizeString,
    sanitizeOptionalString,
    sanitizePlayerId,
    normalizeStoredScreenName,
    normalizeObject,
    normalizeArray,
    timestampToIso,
    toMillis,
    isDateKeyBeyondAllowedFuture,
  } = helpers;
  const RADIANCE_STAT_KEYS = Object.freeze([
    "might",
    "focus",
    "tempo",
    "insight",
  ]);

  function buildOfflineClaimStatusMessage({
    elapsedSeconds,
    secondsClaimed,
    freeCapSeconds,
    premiumMembershipActive,
  }) {
    if (secondsClaimed <= 0) {
      return "No idle time was available to claim.";
    }
    if (premiumMembershipActive) {
      return "Server-side idle rewards validated with Premium Membership active.";
    }
    if (elapsedSeconds > freeCapSeconds) {
      return `Free idle rewards hit the ${formatOfflineCapLabel(freeCapSeconds)} cap. Premium Membership removes that limit.`;
    }
    return "Server-side idle rewards validated.";
  }

  function formatOfflineCapLabel(seconds) {
    const normalizedSeconds = Math.max(0, seconds);
    const hours = normalizedSeconds / 3600;
    return Number.isInteger(hours) ? `${hours}h` : `${hours.toFixed(1)}h`;
  }

  function playerSaveRef(uid) {
    return db
      .collection(PROFILE_COLLECTION)
      .doc(uid)
      .collection(PRIVATE_PROFILE_COLLECTION)
      .doc(PLAYER_SAVE_DOCUMENT);
  }

  function buildPlayerSaveResponse(data) {
    if (!data || typeof data !== "object" || !data.payload) {
      return null;
    }
    return {
      schemaVersion: clampInt(
        data.schemaVersion,
        PLAYER_SAVE_SCHEMA_VERSION,
        PLAYER_SAVE_SCHEMA_VERSION,
        PLAYER_SAVE_SCHEMA_VERSION,
      ),
      revision: clampInt(data.revision, 0, PLAYER_SAVE_LIMITS.maxRevision, 0),
      updatedAt: timestampToIso(data.updatedAt),
      authProvider: sanitizeString(data.authProvider, "unknown"),
      recoverable: data.recoverable === true,
      integrity: normalizeStoredIntegrity(data.integrity),
      payload: data.payload,
    };
  }

  function normalizeStoredIntegrity(value) {
    const data = normalizeObject(value);
    return {
      version: clampInt(data.version, 1, 1, 1),
      riskScore: clampInt(data.riskScore, 0, 100, 0),
      flags: sanitizeSavedStringList(data.flags, 16, 96),
      checkedAtMillis: clampInt(data.checkedAtMillis, 0, Date.now(), 0),
    };
  }

  function isRecoverableAuth(auth) {
    const signInProvider = auth.token?.firebase?.sign_in_provider || "anonymous";
    const identities = auth.token?.firebase?.identities || {};
    const linkedProviderIds = Object.keys(identities).filter(
      (providerId) => providerId !== "anonymous",
    );
    return signInProvider !== "anonymous" || linkedProviderIds.length > 0;
  }

  function rejectInvalidRawSavePayload(rawPayload, auth) {
    if (!rawPayload || typeof rawPayload !== "object" || Array.isArray(rawPayload)) {
      throw new HttpsError("invalid-argument", "Cloud save payload is required.");
    }

    const reasons = [];
    const payloadBytes = safeJsonByteLength(rawPayload);
    if (payloadBytes > SAVE_INTEGRITY_LIMITS.maxPayloadBytes) {
      reasons.push("payload_too_large");
    }

    const savedAtMillis = Number(rawPayload.savedAtMillis);
    if (
      Number.isFinite(savedAtMillis) &&
      savedAtMillis > Date.now() + SAVE_INTEGRITY_LIMITS.maxFutureSkewMillis
    ) {
      reasons.push("saved_at_in_future");
    }

    rejectInvalidResourceEnvelope(rawPayload.resources, reasons);
    rejectInvalidMetricsEnvelope(rawPayload.metrics, reasons);
    rejectInvalidInventoryEnvelope(rawPayload.inventory, reasons);
    rejectInvalidLayersEnvelope(rawPayload.layers, reasons);
    rejectInvalidStoreEnvelope(rawPayload.store, reasons);
    rejectInvalidDailyDungeonsEnvelope(rawPayload.dailyDungeons, reasons);
    rejectInvalidBattlePassEnvelope(rawPayload.battlePasses, reasons);
    rejectInvalidBattlePassTimeEnvelope(rawPayload.battlePasses, reasons);

    if (reasons.length === 0) {
      return;
    }

    logger.warn("Rejected cloud save by integrity gate", {
      uid: auth.uid,
      reasons,
      payloadBytes,
      authProvider: auth.token?.firebase?.sign_in_provider || "unknown",
    });
    throw new HttpsError(
      "failed-precondition",
      "Cloud save rejected by integrity checks.",
      { reasons: reasons.slice(0, 16) },
    );
  }

  function rejectInvalidResourceEnvelope(value, reasons) {
    const resources = normalizeObject(value);
    for (const field of [
      "lumens",
      "flux",
      "prismShards",
      "managerShards",
      "shellCores",
      "enemyTickets",
      "bossTickets",
      "threatShards",
      "swarmMagnets",
    ]) {
      rejectInvalidNumericRange(
        resources[field],
        `resources.${field}`,
        0,
        PLAYER_SAVE_LIMITS.maxCurrency,
        reasons,
      );
    }
    for (const field of [
      "bossCores",
      "enemyPullCount",
      "bossPullCount",
      "towerManagerPullCount",
      "enemyManagerPullCount",
      "managerPowerLevel",
      "kills",
      "experience",
      "echoSeeds",
      "equipmentDropCounter",
    ]) {
      rejectInvalidNumericRange(
        resources[field],
        `resources.${field}`,
        0,
        PLAYER_SAVE_LIMITS.maxCounter,
        reasons,
      );
    }
  }

  function rejectInvalidMetricsEnvelope(value, reasons) {
    const metrics = normalizeObject(value);
    for (const field of [
      "totalBattleSeconds",
      "totalOfflineSecondsClaimed",
    ]) {
      rejectInvalidNumericRange(
        metrics[field],
        `metrics.${field}`,
        0,
        PLAYER_SAVE_LIMITS.maxMetricSeconds,
        reasons,
      );
    }
    for (const field of [
      "totalUpgradesBought",
      "totalTowersBuilt",
      "totalManagersForged",
      "totalBossesDefeated",
      "balanceEpoch",
    ]) {
      rejectInvalidNumericRange(
        metrics[field],
        `metrics.${field}`,
        0,
        PLAYER_SAVE_LIMITS.maxCounter,
        reasons,
      );
    }
    for (const field of [
      "totalLumensSpent",
      "totalFluxSpent",
      "totalPrismShardsSpent",
    ]) {
      rejectInvalidNumericRange(
        metrics[field],
        `metrics.${field}`,
        0,
        PLAYER_SAVE_LIMITS.maxCurrency,
        reasons,
      );
    }
  }

  function rejectInvalidInventoryEnvelope(value, reasons) {
    const inventory = normalizeObject(value);
    checkArrayLength(
      inventory.cards,
      "inventory.cards",
      PLAYER_SAVE_LIMITS.maxInventoryCards,
      reasons,
    );
    checkArrayLength(
      inventory.enemyManagers,
      "inventory.enemyManagers",
      PLAYER_SAVE_LIMITS.maxEnemyManagers,
      reasons,
    );
    checkArrayLength(
      inventory.enemyCards,
      "inventory.enemyCards",
      PLAYER_SAVE_LIMITS.maxEnemyCards,
      reasons,
    );
    checkArrayLength(
      inventory.bossEnemyCards,
      "inventory.bossEnemyCards",
      PLAYER_SAVE_LIMITS.maxEnemyCards,
      reasons,
    );
    checkArrayLength(
      inventory.equipmentInventory,
      "inventory.equipmentInventory",
      PLAYER_SAVE_LIMITS.maxEquipmentItems,
      reasons,
    );

    validateTowerManagerCards(inventory.cards, reasons);
    validateEnemyManagers(inventory.enemyManagers, reasons);
    validateEnemyCards(inventory.enemyCards, "inventory.enemyCards", 100, reasons);
    validateEnemyCards(
      inventory.bossEnemyCards,
      "inventory.bossEnemyCards",
      20,
      reasons,
    );
    validateEquipmentInventory(inventory.equipmentInventory, reasons);
  }

  function rejectInvalidLayersEnvelope(value, reasons) {
    const layers = normalizeObject(value);
    checkArrayLength(
      layers.items,
      "layers.items",
      PLAYER_SAVE_LIMITS.maxLayers,
      reasons,
    );

    for (const [layerIndex, rawLayer] of normalizeArray(layers.items).entries()) {
      const layer = normalizeObject(rawLayer);
      rejectInvalidNumericRange(
        layer.tier,
        `layers.items.${layerIndex}.tier`,
        1,
        SAVE_INTEGRITY_LIMITS.maxLayerTier,
        reasons,
      );
      checkArrayLength(
        layer.slots,
        `layers.items.${layerIndex}.slots`,
        PLAYER_SAVE_LIMITS.maxSlotsPerLayer,
        reasons,
      );
      validateLayerCore(layer.core, layerIndex, reasons);
      validateLayerSlots(layer.slots, layerIndex, reasons);
    }
  }

  function rejectInvalidBattlePassEnvelope(value, reasons) {
    checkArrayLength(
      value,
      "battlePasses",
      PLAYER_SAVE_LIMITS.maxBattlePasses,
      reasons,
    );
  }

  function rejectInvalidStoreEnvelope(value, reasons) {
    const store = normalizeObject(value);
    const timeWarpWeekKey = sanitizeSavedString(store.timeWarpWeekKey, "", 32);
    if (
      timeWarpWeekKey &&
      isDateKeyBeyondAllowedFuture(timeWarpWeekKey)
    ) {
      reasons.push("store.timeWarpWeekKey_in_future");
    }
  }

  function rejectInvalidBattlePassTimeEnvelope(value, reasons) {
    for (const [index, rawPass] of normalizeArray(value).entries()) {
      const pass = normalizeObject(rawPass);
      const seasonKey = sanitizeSavedString(pass.seasonKey, "", 32);
      if (seasonKey && isDateKeyBeyondAllowedFuture(seasonKey)) {
        reasons.push(`battlePasses.${index}.seasonKey_in_future`);
      }
    }
  }

  function rejectInvalidDailyDungeonsEnvelope(value, reasons) {
    const dailyDungeons = normalizeObject(value);
    rejectInvalidNumericRange(
      dailyDungeons.highestUnlockedTowerLevel,
      "dailyDungeons.highestUnlockedTowerLevel",
      1,
      60,
      reasons,
    );
    rejectInvalidNumericRange(
      dailyDungeons.highestClearedTowerLevel,
      "dailyDungeons.highestClearedTowerLevel",
      0,
      60,
      reasons,
    );
    rejectInvalidNumericRange(
      dailyDungeons.quickClearsUsed,
      "dailyDungeons.quickClearsUsed",
      0,
      3,
      reasons,
    );
  }

  function validateTowerManagerCards(value, reasons) {
    for (const [index, rawCard] of normalizeArray(value).entries()) {
      const card = normalizeObject(rawCard);
      rejectInvalidNumericRange(
        card.forgeCost,
        `inventory.cards.${index}.forgeCost`,
        0,
        PLAYER_SAVE_LIMITS.maxCurrency,
        reasons,
      );
      for (const field of [
        "powerMultiplier",
        "chargeMultiplier",
        "cooldownMultiplier",
        "advantageMultiplier",
      ]) {
        rejectInvalidNumericRange(
          card[field],
          `inventory.cards.${index}.${field}`,
          SAVE_INTEGRITY_LIMITS.minManagerMultiplier,
          SAVE_INTEGRITY_LIMITS.maxManagerMultiplier,
          reasons,
        );
      }
      rejectInvalidNumericRange(
        card.automationRate,
        `inventory.cards.${index}.automationRate`,
        0,
        SAVE_INTEGRITY_LIMITS.maxAutomationRate,
        reasons,
      );
    }
  }

  function validateEnemyManagers(value, reasons) {
    for (const [index, rawManager] of normalizeArray(value).entries()) {
      const manager = normalizeObject(rawManager);
      rejectInvalidNumericRange(
        manager.forgeCost,
        `inventory.enemyManagers.${index}.forgeCost`,
        0,
        PLAYER_SAVE_LIMITS.maxCurrency,
        reasons,
      );
      for (const field of [
        "spawnRateMultiplier",
        "rewardMultiplier",
        "experienceMultiplier",
        "healthMultiplier",
        "speedMultiplier",
      ]) {
        rejectInvalidNumericRange(
          manager[field],
          `inventory.enemyManagers.${index}.${field}`,
          SAVE_INTEGRITY_LIMITS.minManagerMultiplier,
          SAVE_INTEGRITY_LIMITS.maxManagerMultiplier,
          reasons,
        );
      }
    }
  }

  function validateEnemyCards(value, path, maxLevel, reasons) {
    for (const [index, rawCard] of normalizeArray(value).entries()) {
      const card = normalizeObject(rawCard);
      rejectInvalidNumericRange(
        card.level,
        `${path}.${index}.level`,
        1,
        maxLevel,
        reasons,
      );
      rejectInvalidNumericRange(
        card.copies,
        `${path}.${index}.copies`,
        0,
        PLAYER_SAVE_LIMITS.maxCounter,
        reasons,
      );
    }
  }

  function validateEquipmentInventory(value, reasons) {
    for (const [index, rawItem] of normalizeArray(value).entries()) {
      const item = normalizeObject(rawItem);
      rejectInvalidNumericRange(
        item.level,
        `inventory.equipmentInventory.${index}.level`,
        1,
        SAVE_INTEGRITY_LIMITS.maxEquipmentLevel,
        reasons,
      );
      rejectInvalidNumericRange(
        item.dropOrder,
        `inventory.equipmentInventory.${index}.dropOrder`,
        0,
        PLAYER_SAVE_LIMITS.maxCounter,
        reasons,
      );
      const bonuses = normalizeObject(item.bonuses);
      for (const field of [
        "towerPower",
        "chargeRate",
        "critDamage",
        "range",
        "bossDamage",
        "lumenGain",
        "fluxGain",
        "ticketGain",
        "dropRate",
      ]) {
        rejectInvalidNumericRange(
          bonuses[field],
          `inventory.equipmentInventory.${index}.bonuses.${field}`,
          0,
          SAVE_INTEGRITY_LIMITS.maxEquipmentBonus,
          reasons,
        );
      }
      rejectInvalidNumericRange(
        bonuses.critChance,
        `inventory.equipmentInventory.${index}.bonuses.critChance`,
        0,
        SAVE_INTEGRITY_LIMITS.maxCritChanceBonus,
        reasons,
      );
    }
  }

  function validateLayerCore(value, layerIndex, reasons) {
    const core = normalizeObject(value);
    rejectInvalidNumericRange(
      core.level,
      `layers.items.${layerIndex}.core.level`,
      1,
      SAVE_INTEGRITY_LIMITS.maxCoreLevel,
      reasons,
    );
    for (const field of [
      "rangeUpgradeLevel",
      "fireSpeedUpgradeLevel",
      "queueLimitUpgradeLevel",
    ]) {
      rejectInvalidNumericRange(
        core[field],
        `layers.items.${layerIndex}.core.${field}`,
        0,
        5,
        reasons,
      );
    }
    rejectInvalidNumericRange(
      core.multiShotUpgradeLevel,
      `layers.items.${layerIndex}.core.multiShotUpgradeLevel`,
      0,
      3,
      reasons,
    );
  }

  function validateLayerSlots(value, layerIndex, reasons) {
    for (const [slotIndex, rawSlot] of normalizeArray(value).entries()) {
      const slot = normalizeObject(rawSlot);
      rejectInvalidNumericRange(
        slot.slotIndex,
        `layers.items.${layerIndex}.slots.${slotIndex}.slotIndex`,
        0,
        PLAYER_SAVE_LIMITS.maxSlotsPerLayer - 1,
        reasons,
      );
      const isActiveTower = typeof slot.configId === "string" &&
        slot.configId.trim().length > 0 &&
        !slot.childLayerId;
      if (isActiveTower) {
        rejectInvalidNumericRange(
          slot.level,
          `layers.items.${layerIndex}.slots.${slotIndex}.level`,
          1,
          SAVE_INTEGRITY_LIMITS.maxTowerLevel,
          reasons,
        );
      }
      rejectInvalidNumericRange(
        slot.childCoreLevel,
        `layers.items.${layerIndex}.slots.${slotIndex}.childCoreLevel`,
        1,
        SAVE_INTEGRITY_LIMITS.maxCoreLevel,
        reasons,
      );
    }
  }

  function rejectImplausibleSnapshotRates(snapshot, savePayload) {
    const envelope = buildProductionEnvelope(savePayload);
    const slack = SAVE_INTEGRITY_LIMITS.maxSnapshotRateSlackMultiplier;
    const maxPassiveLumensPerHour = Math.max(120, envelope.passiveLumensPerHour * slack);
    const maxKillsPerHour = Math.max(20, envelope.killsPerHour * slack);
    const reasons = [];
    if (snapshot.passiveLumensPerHour > maxPassiveLumensPerHour) {
      reasons.push("snapshot.passiveLumensPerHour_implausible");
    }
    if (snapshot.killsPerHour > maxKillsPerHour) {
      reasons.push("snapshot.killsPerHour_implausible");
    }
    if (reasons.length > 0) {
      throw new HttpsError(
        "failed-precondition",
        "Idle snapshot rejected by server progression checks.",
        { reasons, envelope },
      );
    }
  }

  function buildAuthoritativeIdleSnapshot({ clientSnapshot, savePayload }) {
    const normalizedSavePayload = normalizeObject(savePayload);
    rejectImplausibleSnapshotRates(clientSnapshot, normalizedSavePayload);
    return buildIdleSnapshotFromSavePayload(normalizedSavePayload);
  }

  function rejectImplausibleSaveDelta({
    previousPayload,
    nextPayload,
    previousSaveData,
  }) {
    if (!previousPayload || !previousSaveData) {
      return;
    }

    const elapsedSeconds = elapsedSecondsSince(previousSaveData.updatedAt);
    const offlineSecondsDelta = positiveDelta(
      previousPayload,
      nextPayload,
      "metrics.totalOfflineSecondsClaimed",
    );
    const timeWarpSecondsDelta = positiveDelta(
      previousPayload,
      nextPayload,
      "metrics.totalTimeWarpSecondsClaimed",
    );
    const productionSeconds = Math.min(
      SAVE_INTEGRITY_LIMITS.maxSaveDeltaWindowSeconds,
      elapsedSeconds +
        offlineSecondsDelta +
        timeWarpSecondsDelta +
        SAVE_INTEGRITY_LIMITS.maxSaveDeltaGraceSeconds,
    );
    const envelope = maxProductionEnvelope(
      buildProductionEnvelope(previousPayload),
      buildProductionEnvelope(nextPayload),
    );
    const slack = SAVE_INTEGRITY_LIMITS.maxSaveDeltaRateSlackMultiplier;
    const allowedKills = Math.max(
      10000,
      envelope.killsPerHour * (productionSeconds / 3600) * slack,
    );
    const allowedLumens = Math.max(
      10000000,
      envelope.passiveLumensPerHour * (productionSeconds / 3600) * slack +
        allowedKills * 1000,
    );
    const allowedExperience = Math.max(10000000, allowedKills * 2500);
    const checks = [
      {
        path: "resources.kills",
        limit: allowedKills,
      },
      {
        path: "resources.experience",
        limit: allowedExperience,
      },
      {
        path: "resources.lumens",
        limit: allowedLumens,
      },
    ];
    const reasons = checks
      .filter((check) => positiveDelta(previousPayload, nextPayload, check.path) > check.limit)
      .map((check) => `${check.path}_implausible_delta`);
    if (reasons.length > 0) {
      throw new HttpsError(
        "failed-precondition",
        "Cloud save rejected by server progression checks.",
        {
          reasons,
          elapsedSeconds,
          productionSeconds,
          envelope,
        },
      );
    }
  }

  function buildProductionEnvelope(payload) {
    const layersData = normalizeObject(payload?.layers);
    const inventoryData = normalizeObject(payload?.inventory);
    const layers = normalizeArray(layersData.items).map(normalizeObject);
    if (layers.length === 0) {
      return {
        passiveLumensPerHour: 0,
        killsPerHour: 0,
        activeLayerTier: 1,
        builtTowerCount: 0,
      };
    }

    const managerLayerIds = new Set(
      normalizeArray(inventoryData.cards)
        .map((card) => normalizeObject(card).equippedLayerId)
        .filter((layerId) => typeof layerId === "string" && layerId.length > 0),
    );
    const layersById = new Map(
      layers
        .map((layer) => [sanitizeOptionalString(layer.id), layer])
        .filter(([layerId]) => Boolean(layerId)),
    );
    function hasTowerManagerForLayer(layer) {
      const visitedLayerIds = new Set();
      let currentLayer = layer;
      while (currentLayer) {
        const layerId = sanitizeOptionalString(currentLayer.id);
        if (!layerId || visitedLayerIds.has(layerId)) {
          return false;
        }
        if (managerLayerIds.has(layerId)) {
          return true;
        }
        visitedLayerIds.add(layerId);
        const parentLayerId = sanitizeOptionalString(currentLayer.parentLayerId);
        currentLayer = parentLayerId ? layersById.get(parentLayerId) : null;
      }
      return false;
    }
    let passiveLumensPerSecond = 0;
    let totalBuiltTowerCount = 0;
    const activeLayerId =
      sanitizeOptionalString(layersData.activeLayerId) ||
      sanitizeOptionalString(layersData.runtimeLayerId) ||
      sanitizeOptionalString(layers[0]?.id);
    let activeLayer = layers.find((layer) => layer.id === activeLayerId) || layers[0];

    for (const layer of layers) {
      const tier = clampInt(layer.tier, 1, SAVE_INTEGRITY_LIMITS.maxLayerTier, 1);
      const core = normalizeObject(layer.core);
      const coreLevel = clampInt(core.level, 1, SAVE_INTEGRITY_LIMITS.maxCoreLevel, 1);
      const builtTowerCount = countBuiltTowers(layer);
      totalBuiltTowerCount += builtTowerCount;
      const hasLayerManager = hasTowerManagerForLayer(layer);
      const managedTowerCount = hasLayerManager ? builtTowerCount : 0;
      if (managedTowerCount <= 0) {
        continue;
      }
      const tierScale = Math.pow(2, Math.min(40, tier - 1));
      const passiveOnlyScale = layer.id === activeLayer.id
        ? 1
        : SERVER_BALANCE_LIMITS.promotedSourcePassiveMultiplier;
      passiveLumensPerSecond +=
        ((managedTowerCount * 0.18) + (coreLevel * 0.04)) *
        tierScale *
        passiveOnlyScale;
    }

    const activeTier = clampInt(
      activeLayer.tier,
      1,
      SAVE_INTEGRITY_LIMITS.maxLayerTier,
      1,
    );
    const threatMap = normalizeObject(payload.threatMap);
    const offlineRegionId =
      sanitizeOptionalString(threatMap.validatedFarmRegionId) ||
      sanitizeOptionalString(threatMap.offlineRegionId);
    const offlineRegionStabilizedLevel = clampInt(
      threatMap.validatedFarmStabilizedLevel ??
        threatMap.offlineRegionStabilizedLevel,
      0,
      100,
      0,
    );
    const offlineRegionValidatedThreatDirectorId =
      sanitizeOptionalString(threatMap.validatedFarmThreatDirectorId) ||
      sanitizeOptionalString(threatMap.offlineRegionValidatedThreatDirectorId);
    const validatedFarmSwarmSize = clampInt(
      threatMap.validatedFarmSwarmSize,
      6,
      84,
      6,
    );
    const validatedFarmEfficiency = clampNumber(
      threatMap.validatedFarmEfficiency,
      0,
      1,
      0,
    );
    const validatedFarmKillsPerHour = clampNumber(
      threatMap.validatedFarmKillsPerHour,
      0,
      SERVER_BALANCE_LIMITS.maxOfflineKillsPerHour,
      0,
    );
    const killsPerHour = estimateOfflineKillsPerHour({
      offlineRegionId,
      offlineRegionStabilizedLevel,
      validatedFarmSwarmSize,
      validatedFarmEfficiency,
      validatedFarmKillsPerHour,
    });

    return {
      passiveLumensPerHour: passiveLumensPerSecond * 3600,
      killsPerHour,
      activeLayerTier: activeTier,
      builtTowerCount: totalBuiltTowerCount,
      offlineRegionId,
      offlineRegionStabilizedLevel,
      offlineRegionValidatedThreatDirectorId,
      validatedFarmSwarmSize,
      validatedFarmEfficiency,
    };
  }

  function buildIdleSnapshotFromSavePayload(payload) {
    const envelope = buildProductionEnvelope(payload);
    return {
      generatedAtMillis: Date.now(),
      passiveLumensPerHour: clampNumber(
        envelope.passiveLumensPerHour,
        0,
        SNAPSHOT_LIMITS.passiveLumensPerHour,
        0,
      ),
      fluxPerHour: 0,
      enemyTicketsPerHour: 0,
      killsPerHour: clampNumber(
        envelope.killsPerHour,
        0,
        SNAPSHOT_LIMITS.killsPerHour,
        0,
      ),
      activeLayerTier: clampInt(
        envelope.activeLayerTier,
        1,
        SNAPSHOT_LIMITS.activeLayerTier,
        1,
      ),
      builtTowerCount: clampInt(
        envelope.builtTowerCount,
        0,
        SNAPSHOT_LIMITS.builtTowerCount,
        0,
      ),
      prestigeLevel: 0,
      offlineRegionId: envelope.offlineRegionId || null,
      offlineRegionStabilizedLevel: clampInt(
        envelope.offlineRegionStabilizedLevel,
        0,
        100,
        0,
      ),
      offlineRegionValidatedThreatDirectorId:
        envelope.offlineRegionValidatedThreatDirectorId || null,
      validatedFarmSwarmSize: clampInt(
        envelope.validatedFarmSwarmSize,
        0,
        84,
        0,
      ),
      validatedFarmEfficiency: clampNumber(
        envelope.validatedFarmEfficiency,
        0,
        1,
        0,
      ),
    };
  }

  function estimateOfflineKillsPerHour({
    offlineRegionId,
    offlineRegionStabilizedLevel,
    validatedFarmSwarmSize,
    validatedFarmEfficiency,
    validatedFarmKillsPerHour,
  }) {
    if (!offlineRegionId || offlineRegionStabilizedLevel <= 0) {
      return 0;
    }
    if (validatedFarmKillsPerHour > 0) {
      return Math.min(
        SERVER_BALANCE_LIMITS.maxOfflineKillsPerHour,
        validatedFarmKillsPerHour,
      );
    }
    const ringMatch = offlineRegionId.match(/^region_r(\d+)_/);
    const ring = ringMatch ? clampInt(ringMatch[1], 0, 3, 0) : 0;
    const layerCap = ring === 0 ? 3 : ring === 1 ? 5 : ring === 2 ? 8 : 13;
    const layerRatio = clampNumber(
      offlineRegionStabilizedLevel / layerCap,
      0,
      1,
      0,
    );
    const base = 18 + (ring * 18);
    const swarmScale = clampNumber(validatedFarmSwarmSize / 6, 1, 8, 1);
    const efficiencyScale = clampNumber(validatedFarmEfficiency, 0.7, 1, 1);
    return Math.min(
      SERVER_BALANCE_LIMITS.maxOfflineKillsPerHour,
      base * (0.4 + (layerRatio * 0.6)) * swarmScale * efficiencyScale,
    );
  }

  function countBuiltTowers(layer) {
    return normalizeArray(layer.slots).filter((rawSlot) => {
      const slot = normalizeObject(rawSlot);
      const configId = sanitizeOptionalString(slot.configId);
      const childLayerId = sanitizeOptionalString(slot.childLayerId);
      const childPromoted = slot.childPromoted === true;
      const fabricationRemainingSeconds = Number(slot.fabricationRemainingSeconds);
      const isFabricating = Number.isFinite(fabricationRemainingSeconds) &&
        fabricationRemainingSeconds > 0;
      return !isFabricating &&
        ((Boolean(configId) && !childLayerId) || childPromoted);
    }).length;
  }

  function maxProductionEnvelope(left, right) {
    return {
      passiveLumensPerHour: Math.max(
        left.passiveLumensPerHour,
        right.passiveLumensPerHour,
      ),
      killsPerHour: Math.max(left.killsPerHour, right.killsPerHour),
      activeLayerTier: Math.max(left.activeLayerTier, right.activeLayerTier),
      builtTowerCount: Math.max(left.builtTowerCount, right.builtTowerCount),
    };
  }

  function positiveDelta(previousPayload, nextPayload, path) {
    const previous = numberAtPath(previousPayload, path);
    const next = numberAtPath(nextPayload, path);
    if (previous === null || next === null || next <= previous) {
      return 0;
    }
    return next - previous;
  }

  function elapsedSecondsSince(timestampValue) {
    const updatedAtMillis = toMillis(timestampValue);
    if (!updatedAtMillis) {
      return SAVE_INTEGRITY_LIMITS.maxSaveDeltaGraceSeconds;
    }
    return clampNumber(
      (Date.now() - updatedAtMillis) / 1000,
      0,
      SAVE_INTEGRITY_LIMITS.maxSaveDeltaWindowSeconds,
      SAVE_INTEGRITY_LIMITS.maxSaveDeltaGraceSeconds,
    );
  }

  function rejectInvalidNumericRange(value, path, min, max, reasons) {
    if (value === null || value === undefined) {
      return;
    }
    const numeric = Number(value);
    if (!Number.isFinite(numeric) || numeric < min || numeric > max) {
      reasons.push(`${path}_out_of_range`);
    }
  }

  function checkArrayLength(value, path, limit, reasons) {
    if (Array.isArray(value) && value.length > limit) {
      reasons.push(`${path}_too_large`);
    }
  }

  function buildSaveIntegritySummary({ auth, rawPayload, payload, previousPayload }) {
    const flags = [];
    let riskScore = 0;
    const addFlag = (flag, score) => {
      if (!flags.includes(flag)) {
        flags.push(flag);
      }
      riskScore += score;
    };

    const payloadBytes = safeJsonByteLength(rawPayload);
    if (payloadBytes > SAVE_INTEGRITY_LIMITS.maxPayloadBytes * 0.85) {
      addFlag("large_save_payload", 5);
    }

    if (previousPayload) {
      flagCounterDecrease(previousPayload, payload, "resources.kills", addFlag);
      flagCounterDecrease(
        previousPayload,
        payload,
        "resources.experience",
        addFlag,
      );
      flagCounterDecrease(
        previousPayload,
        payload,
        "resources.enemyPullCount",
        addFlag,
      );
      flagCounterDecrease(
        previousPayload,
        payload,
        "resources.bossPullCount",
        addFlag,
      );
      flagCounterDecrease(
        previousPayload,
        payload,
        "resources.towerManagerPullCount",
        addFlag,
      );
      flagCounterDecrease(
        previousPayload,
        payload,
        "resources.enemyManagerPullCount",
        addFlag,
      );
      flagCounterDecrease(
        previousPayload,
        payload,
        "resources.managerPowerLevel",
        addFlag,
      );
      flagCounterDecrease(
        previousPayload,
        payload,
        "metrics.totalBattleSeconds",
        addFlag,
      );
      flagCounterDecrease(
        previousPayload,
        payload,
        "metrics.totalOfflineSecondsClaimed",
        addFlag,
      );
      flagCounterDecrease(
        previousPayload,
        payload,
        "metrics.totalUpgradesBought",
        addFlag,
      );
      flagCounterDecrease(
        previousPayload,
        payload,
        "metrics.totalTowersBuilt",
        addFlag,
      );
      flagCounterDecrease(
        previousPayload,
        payload,
        "metrics.totalManagersForged",
        addFlag,
      );
      flagCounterDecrease(
        previousPayload,
        payload,
        "metrics.totalBossesDefeated",
        addFlag,
      );
      flagCounterDecrease(
        previousPayload,
        payload,
        "metrics.totalPrismShardsSpent",
        addFlag,
      );
      flagCounterDecrease(
        previousPayload,
        payload,
        "metrics.totalTimeWarpSecondsClaimed",
        addFlag,
      );
      flagCounterDecrease(
        previousPayload,
        payload,
        "metrics.balanceEpoch",
        addFlag,
      );

      flagSuspiciousIncrease(
        previousPayload,
        payload,
        "resources.lumens",
        SAVE_INTEGRITY_LIMITS.suspiciousLumensDelta,
        addFlag,
      );
      flagSuspiciousIncrease(
        previousPayload,
        payload,
        "resources.flux",
        SAVE_INTEGRITY_LIMITS.suspiciousFluxDelta,
        addFlag,
      );
      flagSuspiciousIncrease(
        previousPayload,
        payload,
        "resources.prismShards",
        SAVE_INTEGRITY_LIMITS.suspiciousPrismShardsDelta,
        addFlag,
      );
      flagSuspiciousIncrease(
        previousPayload,
        payload,
        "resources.managerShards",
        SAVE_INTEGRITY_LIMITS.suspiciousPrismShardsDelta,
        addFlag,
      );
      flagSuspiciousIncrease(
        previousPayload,
        payload,
        "resources.shellCores",
        SAVE_INTEGRITY_LIMITS.suspiciousFluxDelta,
        addFlag,
      );
      flagSuspiciousIncrease(
        previousPayload,
        payload,
        "resources.enemyTickets",
        SAVE_INTEGRITY_LIMITS.suspiciousTicketDelta,
        addFlag,
      );
      flagSuspiciousIncrease(
        previousPayload,
        payload,
        "resources.bossTickets",
        SAVE_INTEGRITY_LIMITS.suspiciousTicketDelta,
        addFlag,
      );
      flagSuspiciousIncrease(
        previousPayload,
        payload,
        "resources.kills",
        SAVE_INTEGRITY_LIMITS.suspiciousCounterDelta,
        addFlag,
      );
    }

    logger.info("Accepted cloud save", {
      uid: auth.uid,
      riskScore,
      flags,
      layerCount: payload.layers.items.length,
      cardCount: payload.inventory.cards.length,
      equipmentCount: payload.inventory.equipmentInventory.length,
      battlePassCount: payload.battlePasses.length,
      balanceEpoch: payload.metrics.balanceEpoch,
    });

    return {
      version: 1,
      riskScore: Math.min(100, riskScore),
      flags: flags.slice(0, 16),
      checkedAtMillis: Date.now(),
    };
  }

  function flagCounterDecrease(previousPayload, payload, path, addFlag) {
    const previous = numberAtPath(previousPayload, path);
    const next = numberAtPath(payload, path);
    if (previous !== null && next !== null && next + 0.001 < previous) {
      addFlag(`counter_decreased:${path}`, 15);
    }
  }

  function flagSuspiciousIncrease(previousPayload, payload, path, limit, addFlag) {
    const previous = numberAtPath(previousPayload, path);
    const next = numberAtPath(payload, path);
    if (previous !== null && next !== null && next - previous > limit) {
      addFlag(`large_delta:${path}`, 20);
    }
  }

  function numberAtPath(value, path) {
    let current = value;
    for (const part of path.split(".")) {
      if (!current || typeof current !== "object") {
        return null;
      }
      current = current[part];
    }
    const numeric = Number(current);
    return Number.isFinite(numeric) ? numeric : null;
  }

  function safeJsonByteLength(value) {
    try {
      return Buffer.byteLength(JSON.stringify(value), "utf8");
    } catch (error) {
      return SAVE_INTEGRITY_LIMITS.maxPayloadBytes + 1;
    }
  }

  function sanitizePlayerSavePayload(value) {
    if (!value || typeof value !== "object" || Array.isArray(value)) {
      throw new HttpsError("invalid-argument", "Cloud save payload is required.");
    }

    const payload = {
      schemaVersion: PLAYER_SAVE_SCHEMA_VERSION,
      savedAtMillis: clampInt(value.savedAtMillis, 0, Date.now(), Date.now()),
      player: sanitizeSavedPlayer(value.player),
      resources: sanitizeSavedResources(value.resources),
      metrics: sanitizeSavedMetrics(value.metrics),
      dailyDungeons: sanitizeSavedDailyDungeons(value.dailyDungeons),
      readHelpSections: sanitizeSavedStringList(
        value.readHelpSections,
        PLAYER_SAVE_LIMITS.maxHelpSections,
      ),
      battlePasses: sanitizeSavedArray(
        value.battlePasses,
        PLAYER_SAVE_LIMITS.maxBattlePasses,
      ),
      store: sanitizeSavedStore(value.store),
      inventory: sanitizeSavedInventory(value.inventory),
      layers: sanitizeSavedLayers(value.layers),
      threatMap: sanitizeSavedThreatMap(value.threatMap),
      completedTowerShells: sanitizeSavedArray(value.completedTowerShells, 96),
      guild: value.guild ? sanitizeSavedGuild(value.guild) : null,
      tutorial: sanitizeSavedTutorial(value.tutorial),
    };

    return payload;
  }

  function sanitizeSavedPlayer(value) {
    const data = normalizeObject(value);
    return {
      playerId: sanitizePlayerId(data.playerId),
      screenName: normalizeStoredScreenName(data.screenName) || null,
      guideId: sanitizeSavedString(data.guideId, "lumo", 32),
      hasPermanentOverdrive: data.hasPermanentOverdrive === true,
      hasPremiumMembership: data.hasPremiumMembership === true,
      bossUnlockGrantClaimed: data.bossUnlockGrantClaimed === true,
      avatarCosmetics: sanitizeSavedAvatarCosmetics(data.avatarCosmetics),
      publicAvatar: sanitizeSavedPublicAvatar(data.publicAvatar),
      equippedProfileMedalId: sanitizeSavedNullableString(
        data.equippedProfileMedalId,
        64,
      ),
      unlockedProfileMedalIds: sanitizeSavedStringList(
        data.unlockedProfileMedalIds,
        32,
        64,
      ),
      radianceStats: sanitizeSavedRadianceStats(data.radianceStats),
      sharedRelayCenterPieceId: sanitizeSavedNullableString(
        data.sharedRelayCenterPieceId,
        96,
      ),
      sharedRelayOuterPieceIds: sanitizeSavedStringList(
        data.sharedRelayOuterPieceIds,
        6,
        96,
        true,
      ),
    };
  }

  function sanitizeSavedAvatarCosmetics(value) {
    const data = normalizeObject(value);
    return {
      unlockedIds: sanitizeSavedStringList(data.unlockedIds, 32, 80),
      equippedHairId: sanitizeSavedNullableString(data.equippedHairId, 80),
      equippedFaceId: sanitizeSavedNullableString(data.equippedFaceId, 80),
    };
  }

  function sanitizeSavedPublicAvatar(value) {
    const data = normalizeObject(value);
    return {
      guideId: sanitizeSavedString(data.guideId, "lumo", 32),
      hairCosmeticId: sanitizeSavedNullableString(data.hairCosmeticId, 80),
      faceCosmeticId: sanitizeSavedNullableString(data.faceCosmeticId, 80),
      equipmentPieces: normalizeArray(data.equipmentPieces)
        .slice(0, 6)
        .map((item) => {
          const piece = normalizeObject(item);
          return {
            slotType: sanitizeSavedString(piece.slotType, "", 32),
            setId: sanitizeSavedString(piece.setId, "", 80),
            affinity: sanitizeSavedString(piece.affinity, "", 32),
            rarity: sanitizeSavedString(piece.rarity, "", 32),
          };
        })
        .filter((piece) => piece.slotType && piece.setId),
    };
  }

  function sanitizeSavedRadianceStats(value) {
    const data = normalizeObject(value);
    return Object.fromEntries(
      RADIANCE_STAT_KEYS.map((stat) => [
        stat,
        clampInt(data[stat], 0, PLAYER_SAVE_LIMITS.maxCounter, 0),
      ]),
    );
  }

  function sanitizeSavedResources(value) {
    const data = normalizeObject(value);
    return {
      lumens: clampInt(data.lumens, 0, PLAYER_SAVE_LIMITS.maxCurrency, 0),
      flux: clampInt(data.flux, 0, PLAYER_SAVE_LIMITS.maxCurrency, 0),
      prismShards: clampInt(
        data.prismShards,
        0,
        PLAYER_SAVE_LIMITS.maxCurrency,
        0,
      ),
      managerShards: clampInt(
        data.managerShards,
        0,
        PLAYER_SAVE_LIMITS.maxCurrency,
        0,
      ),
      managerPowerLevel: clampInt(
        data.managerPowerLevel,
        0,
        PLAYER_SAVE_LIMITS.maxCounter,
        0,
      ),
      shellCores: clampInt(
        data.shellCores,
        0,
        PLAYER_SAVE_LIMITS.maxCurrency,
        0,
      ),
      enemyTickets: clampInt(
        clampInt(data.enemyTickets, 0, PLAYER_SAVE_LIMITS.maxCurrency, 0) +
          clampInt(data.bossTickets, 0, PLAYER_SAVE_LIMITS.maxCurrency, 0),
        0,
        PLAYER_SAVE_LIMITS.maxCurrency,
        0,
      ),
      bossTickets: 0,
      threatShards: clampInt(
        clampInt(data.threatShards, 0, PLAYER_SAVE_LIMITS.maxCurrency, 0) +
          clampInt(data.bossCores, 0, PLAYER_SAVE_LIMITS.maxCounter, 0),
        0,
        PLAYER_SAVE_LIMITS.maxCurrency,
        0,
      ),
      swarmMagnets: clampInt(
        data.swarmMagnets,
        0,
        PLAYER_SAVE_LIMITS.maxCurrency,
        0,
      ),
      bossCores: 0,
      enemyPullCount: clampInt(
        data.enemyPullCount,
        0,
        PLAYER_SAVE_LIMITS.maxCounter,
        0,
      ),
      bossPullCount: clampInt(
        data.bossPullCount,
        0,
        PLAYER_SAVE_LIMITS.maxCounter,
        0,
      ),
      towerManagerPullCount: clampInt(
        data.towerManagerPullCount,
        0,
        PLAYER_SAVE_LIMITS.maxCounter,
        0,
      ),
      enemyManagerPullCount: clampInt(
        data.enemyManagerPullCount,
        0,
        PLAYER_SAVE_LIMITS.maxCounter,
        0,
      ),
      kills: clampInt(data.kills, 0, PLAYER_SAVE_LIMITS.maxCounter, 0),
      experience: clampInt(data.experience, 0, PLAYER_SAVE_LIMITS.maxCounter, 0),
      echoSeeds: clampInt(data.echoSeeds, 0, PLAYER_SAVE_LIMITS.maxCounter, 0),
      totalHelpSectionsRead: clampInt(
        data.totalHelpSectionsRead,
        0,
        PLAYER_SAVE_LIMITS.maxHelpSections,
        0,
      ),
      lumenHarvestSlowdown: clampNumber(data.lumenHarvestSlowdown, 0, 1, 0),
      enemyTicketBuffer: clampNumber(data.enemyTicketBuffer, 0, 1000000, 0),
      equipmentDropCounter: clampInt(
        data.equipmentDropCounter,
        0,
        PLAYER_SAVE_LIMITS.maxCounter,
        0,
      ),
    };
  }

  function sanitizeSavedDailyDungeons(value) {
    const data = normalizeObject(value);
    return {
      highestUnlockedTowerLevel: clampInt(data.highestUnlockedTowerLevel, 1, 60, 1),
      highestClearedTowerLevel: clampInt(data.highestClearedTowerLevel, 0, 60, 0),
      quickClearDayKey: sanitizeSavedString(data.quickClearDayKey, "", 32),
      quickClearsUsed: clampInt(data.quickClearsUsed, 0, 3, 0),
    };
  }

  function sanitizeSavedMetrics(value) {
    const data = normalizeObject(value);
    return {
      totalBattleSeconds: clampNumber(
        data.totalBattleSeconds,
        0,
        PLAYER_SAVE_LIMITS.maxMetricSeconds,
        0,
      ),
      totalOfflineSecondsClaimed: clampInt(
        data.totalOfflineSecondsClaimed,
        0,
        PLAYER_SAVE_LIMITS.maxMetricSeconds,
        0,
      ),
      totalUpgradesBought: clampInt(
        data.totalUpgradesBought,
        0,
        PLAYER_SAVE_LIMITS.maxCounter,
        0,
      ),
      totalTowersBuilt: clampInt(
        data.totalTowersBuilt,
        0,
        PLAYER_SAVE_LIMITS.maxCounter,
        0,
      ),
      totalManagersForged: clampInt(
        data.totalManagersForged,
        0,
        PLAYER_SAVE_LIMITS.maxCounter,
        0,
      ),
      totalBossesDefeated: clampInt(
        data.totalBossesDefeated,
        0,
        PLAYER_SAVE_LIMITS.maxCounter,
        0,
      ),
      totalLumensSpent: clampInt(
        data.totalLumensSpent,
        0,
        PLAYER_SAVE_LIMITS.maxCurrency,
        0,
      ),
      totalFluxSpent: clampInt(
        data.totalFluxSpent,
        0,
        PLAYER_SAVE_LIMITS.maxCurrency,
        0,
      ),
      totalPrismShardsSpent: clampInt(
        data.totalPrismShardsSpent,
        0,
        PLAYER_SAVE_LIMITS.maxCurrency,
        0,
      ),
      totalTimeWarpSecondsClaimed: clampInt(
        data.totalTimeWarpSecondsClaimed,
        0,
        PLAYER_SAVE_LIMITS.maxMetricSeconds,
        0,
      ),
      balanceEpoch: clampInt(data.balanceEpoch, 1, 999999, 1),
    };
  }

  function sanitizeSavedStore(value) {
    const data = normalizeObject(value);
    const rawTimeWarpPurchases = normalizeObject(data.timeWarpWeeklyPurchases);
    const timeWarpWeeklyPurchases = {};
    for (const [rawKey, rawCount] of Object.entries(rawTimeWarpPurchases).slice(
      0,
      16,
    )) {
      const key = sanitizeSavedString(rawKey, "", 64);
      if (!key) {
        continue;
      }
      timeWarpWeeklyPurchases[key] = clampInt(rawCount, 0, 999, 0);
    }
    return {
      timeWarpWeekKey: sanitizeSavedString(data.timeWarpWeekKey, "", 32),
      timeWarpWeeklyPurchases,
    };
  }

  function sanitizeSavedInventory(value) {
    const data = normalizeObject(value);
    return {
      cards: sanitizeSavedArray(
        data.cards,
        PLAYER_SAVE_LIMITS.maxInventoryCards,
      ),
      enemyManagers: sanitizeSavedArray(
        data.enemyManagers,
        PLAYER_SAVE_LIMITS.maxEnemyManagers,
      ),
      enemyCards: sanitizeSavedArray(
        data.enemyCards,
        PLAYER_SAVE_LIMITS.maxEnemyCards,
      ),
      bossEnemyCards: sanitizeSavedArray(
        data.bossEnemyCards,
        PLAYER_SAVE_LIMITS.maxEnemyCards,
      ),
      bossTraits: sanitizeSavedArray(
        data.bossTraits,
        PLAYER_SAVE_LIMITS.maxEnemyCards,
      ),
      apexCores: sanitizeSavedArray(
        data.apexCores,
        PLAYER_SAVE_LIMITS.maxEnemyCards,
      ),
      equipmentInventory: sanitizeSavedArray(
        data.equipmentInventory,
        PLAYER_SAVE_LIMITS.maxEquipmentItems,
      ),
      equippedPlayerItems: sanitizeSavedObject(data.equippedPlayerItems, 0, 16),
    };
  }

  function sanitizeSavedThreatMap(value) {
    const data = normalizeObject(value);
    return {
      selectedRegionId: sanitizeSavedNullableString(data.selectedRegionId, 96),
      farmSwarmSize: clampInt(data.farmSwarmSize, 6, 84, 6),
      validatedFarmRegionId: sanitizeSavedNullableString(
        data.validatedFarmRegionId,
        96,
      ),
      validatedFarmSwarmSize: clampInt(data.validatedFarmSwarmSize, 6, 84, 6),
      validatedFarmThreatDirectorId: sanitizeSavedNullableString(
        data.validatedFarmThreatDirectorId,
        96,
      ),
      validatedFarmStabilizedLevel: clampInt(
        data.validatedFarmStabilizedLevel,
        0,
        100,
        0,
      ),
      validatedFarmEfficiency: clampNumber(
        data.validatedFarmEfficiency,
        0,
        1,
        0,
      ),
      validatedFarmKillsPerHour: clampNumber(
        data.validatedFarmKillsPerHour,
        0,
        SERVER_BALANCE_LIMITS.maxOfflineKillsPerHour,
        0,
      ),
      offlineRegionId: sanitizeSavedNullableString(data.offlineRegionId, 96),
      offlineRegionStabilizedLevel: clampInt(
        data.offlineRegionStabilizedLevel,
        0,
        100,
        0,
      ),
      offlineRegionValidatedThreatDirectorId: sanitizeSavedNullableString(
        data.offlineRegionValidatedThreatDirectorId,
        96,
      ),
      regions: sanitizeSavedArray(data.regions, 64),
      regionEchoes: sanitizeSavedObject(data.regionEchoes, 0, 64),
      activeEnemySuite: sanitizeSavedObject(data.activeEnemySuite, 0, 8),
    };
  }

  function sanitizeSavedLayers(value) {
    const data = normalizeObject(value);
    return {
      activeLayerId: sanitizeSavedNullableString(data.activeLayerId, 96),
      viewLayerId: sanitizeSavedNullableString(data.viewLayerId, 96),
      runtimeLayerId: sanitizeSavedNullableString(data.runtimeLayerId, 96),
      items: normalizeArray(data.items)
        .slice(0, PLAYER_SAVE_LIMITS.maxLayers)
        .map(sanitizeSavedLayer)
        .filter(Boolean),
    };
  }

  function sanitizeSavedLayer(value) {
    const data = sanitizeSavedObject(normalizeObject(value), 0, 80);
    data.slots = normalizeArray(data.slots)
      .slice(0, PLAYER_SAVE_LIMITS.maxSlotsPerLayer)
      .map((slot) => sanitizeSavedObject(slot, 0, 80));
    data.childTowerUpgrades = sanitizeSavedArray(data.childTowerUpgrades, 24);
    data.activeEnemyCardIds = sanitizeSavedStringList(data.activeEnemyCardIds, 12, 96);
    data.enemies = [];
    data.pulses = [];
    data.shots = [];
    data.impacts = [];
    data.ammoQueue = [];
    return data;
  }

  function sanitizeSavedGuild(value) {
    const data = sanitizeSavedObject(normalizeObject(value), 0, 40);
    data.members = normalizeArray(data.members)
      .slice(0, PLAYER_SAVE_LIMITS.maxGuildMembers)
      .map((member) => sanitizeSavedObject(member, 0, 48));
    data.chatMessages = normalizeArray(data.chatMessages)
      .slice(-PLAYER_SAVE_LIMITS.maxGuildMessages)
      .map((message) => sanitizeSavedObject(message, 0, 16));
    return data;
  }

  function sanitizeSavedTutorial(value) {
    const data = normalizeObject(value);
    return {
      earlyQuestChainCompleted: data.earlyQuestChainCompleted === true,
      firstBossDefeated: data.firstBossDefeated === true,
      firstEquipmentOpened: data.firstEquipmentOpened === true,
      firstManagersOpened: data.firstManagersOpened === true,
      firstEnemyTargetSet: data.firstEnemyTargetSet === true,
      enemyCountAdjusted: data.enemyCountAdjusted === true,
      firstTowerStatsOpened: data.firstTowerStatsOpened === true,
      stabilityPanelOpened: data.stabilityPanelOpened === true,
      towerMatrixOpened: data.towerMatrixOpened === true,
      storeOpened: data.storeOpened === true,
      battlePassRewardClaimed: data.battlePassRewardClaimed === true,
      towerManagerAssigned: data.towerManagerAssigned === true,
      enemyManagerAssigned: data.enemyManagerAssigned === true,
      friendsOpened: data.friendsOpened === true,
      menteesOpened: data.menteesOpened === true,
      mentorsOpened: data.mentorsOpened === true,
      coreShotTapLearned: data.coreShotTapLearned === true,
      secondShellShotTapLearned: data.secondShellShotTapLearned === true,
      overdriveLearned: data.overdriveLearned === true,
      introBossPending: data.introBossPending === true,
      safeScanDefeats: clampInt(data.safeScanDefeats, 0, 1000000, 0),
      autoQueuedPulses: clampInt(data.autoQueuedPulses, 0, 1000000, 0),
      trackedBossEnemyId: sanitizeSavedNullableString(data.trackedBossEnemyId, 96),
      reviewedTournamentModes: sanitizeSavedStringList(
        data.reviewedTournamentModes,
        12,
        64,
      ),
      rewardedSteps: sanitizeSavedStringList(data.rewardedSteps, 64, 64),
    };
  }

  function sanitizeSavedArray(value, limit) {
    return normalizeArray(value)
      .slice(0, limit)
      .map((item) => sanitizeSavedObject(item, 0, 80));
  }

  function sanitizeSavedObject(value, depth = 0, maxKeys = 80) {
    if (depth > 8) {
      return null;
    }
    if (value === null || value === undefined) {
      return null;
    }
    if (Array.isArray(value)) {
      return value
        .slice(0, 64)
        .map((item) => sanitizeSavedObject(item, depth + 1, maxKeys));
    }
    if (typeof value === "boolean") {
      return value;
    }
    if (typeof value === "string") {
      return sanitizeSavedString(value, "", PLAYER_SAVE_LIMITS.maxStringLength);
    }
    if (typeof value === "number") {
      return clampNumber(
        value,
        -PLAYER_SAVE_LIMITS.maxCurrency,
        PLAYER_SAVE_LIMITS.maxCurrency,
        0,
      );
    }
    if (typeof value !== "object") {
      return null;
    }

    const next = {};
    for (const [key, rawItem] of Object.entries(value).slice(0, maxKeys)) {
      const safeKey = sanitizeSavedString(key, "", 80);
      if (!safeKey) {
        continue;
      }
      const item = sanitizeSavedObject(rawItem, depth + 1, maxKeys);
      if (item !== undefined) {
        next[safeKey] = item;
      }
    }
    return next;
  }

  function sanitizeSavedStringList(value, limit, stringLimit = 96, allowNull = false) {
    return normalizeArray(value)
      .slice(0, limit)
      .map((item) => allowNull && item === null
        ? null
        : sanitizeSavedNullableString(item, stringLimit))
      .filter((item) => allowNull ? item === null || item : Boolean(item));
  }

  function sanitizeSavedString(value, fallback = "", limit = 160) {
    const next = sanitizeString(value, fallback);
    return next.slice(0, limit);
  }

  function sanitizeSavedNullableString(value, limit = 160) {
    const next = sanitizeOptionalString(value);
    return next ? next.slice(0, limit) : null;
  }

  return {
    buildOfflineClaimStatusMessage,
    playerSaveRef,
    buildPlayerSaveResponse,
    isRecoverableAuth,
    rejectInvalidRawSavePayload,
    rejectImplausibleSnapshotRates,
    rejectImplausibleSaveDelta,
    buildAuthoritativeIdleSnapshot,
    buildIdleSnapshotFromSavePayload,
    buildSaveIntegritySummary,
    sanitizePlayerSavePayload,
  };
}

module.exports = { createPlayerSaveHelpers };
