function createRuntimeContent({ db, createHash, constants, helpers }) {
  let manifestCache = null;
  let balanceTuningCache = null;
  const {
    BALANCE_MANIFEST_DOCUMENT,
    RUNTIME_CONFIG_CACHE_TTL_MILLIS,
    DEFAULT_MANIFEST,
    DEFAULT_BALANCE_TUNING,
    TOWER_BALANCE_STATS,
    ENEMY_BALANCE_STATS,
    ECONOMY_BALANCE_STATS,
  } = constants;
  const {
    clampInt,
    clampNumber,
    normalizeObject,
    sanitizeString,
    resolveManifestVersionGate,
    roundToFour,
  } = helpers;

  async function loadManifest() {
    const nowMillis = Date.now();
    if (manifestCache && manifestCache.expiresAt > nowMillis) {
      return manifestCache.value;
    }

    const balanceTuning = await loadBalanceTuning();
    const doc = await db.doc("runtime/clientManifest").get();
    if (!doc.exists) {
      const manifest = finalizeManifest({
        ...DEFAULT_MANIFEST,
        balanceTuning,
      });
      manifestCache = {
        value: manifest,
        expiresAt: Date.now() + RUNTIME_CONFIG_CACHE_TTL_MILLIS,
      };
      return manifest;
    }

    const data = doc.data() || {};
    const minimumGate = resolveManifestVersionGate(
      data.minimumSupportedVersion,
      data.minimumSupportedBuildNumber,
      DEFAULT_MANIFEST.minimumSupportedVersion,
      DEFAULT_MANIFEST.minimumSupportedBuildNumber,
    );
    const recommendedGate = resolveManifestVersionGate(
      data.recommendedVersion,
      data.recommendedBuildNumber,
      DEFAULT_MANIFEST.recommendedVersion,
      DEFAULT_MANIFEST.recommendedBuildNumber,
    );
    const manifest = finalizeManifest({
      contentSchemaVersion: clampInt(
        data.contentSchemaVersion,
        1,
        99,
        DEFAULT_MANIFEST.contentSchemaVersion,
      ),
      seasonKey: sanitizeString(data.seasonKey, DEFAULT_MANIFEST.seasonKey),
      contentEpoch: clampInt(
        data.contentEpoch,
        1,
        999999,
        DEFAULT_MANIFEST.contentEpoch,
      ),
      minimumSupportedVersion: minimumGate.version,
      minimumSupportedBuildNumber: minimumGate.buildNumber,
      recommendedVersion: recommendedGate.version,
      recommendedBuildNumber: recommendedGate.buildNumber,
      functionsRegion: sanitizeString(
        data.functionsRegion,
        DEFAULT_MANIFEST.functionsRegion,
      ),
      maintenanceMode: Boolean(
        data.maintenanceMode ?? DEFAULT_MANIFEST.maintenanceMode,
      ),
      requiresMandatoryUpdate: Boolean(
        data.requiresMandatoryUpdate ?? DEFAULT_MANIFEST.requiresMandatoryUpdate,
      ),
      usesRemoteContent: Boolean(
        data.usesRemoteContent ?? DEFAULT_MANIFEST.usesRemoteContent,
      ),
      appCheckRequired: Boolean(
        data.appCheckRequired ?? DEFAULT_MANIFEST.appCheckRequired,
      ),
      onlineFeaturesEnabled: Boolean(
        data.onlineFeaturesEnabled ?? DEFAULT_MANIFEST.onlineFeaturesEnabled,
      ),
      offlineProgressCapSeconds: clampInt(
        data.offlineProgressCapSeconds,
        60,
        4 * 60 * 60,
        DEFAULT_MANIFEST.offlineProgressCapSeconds,
      ),
      statusMessage: sanitizeString(
        data.statusMessage,
        DEFAULT_MANIFEST.statusMessage,
      ),
      balanceTuning,
    });
    manifestCache = {
      value: manifest,
      expiresAt: Date.now() + RUNTIME_CONFIG_CACHE_TTL_MILLIS,
    };
    return manifest;
  }

  function finalizeManifest(manifest) {
    const contentSchemaVersion = clampInt(
      manifest.contentSchemaVersion,
      1,
      99,
      DEFAULT_MANIFEST.contentSchemaVersion,
    );
    const normalized = {
      ...manifest,
      contentSchemaVersion,
    };
    return {
      ...normalized,
      contentHash: computeManifestContentHash(normalized),
    };
  }

  function computeManifestContentHash(manifest) {
    const payload = {
      contentSchemaVersion: manifest.contentSchemaVersion,
      seasonKey: manifest.seasonKey,
      contentEpoch: manifest.contentEpoch,
      minimumSupportedVersion: manifest.minimumSupportedVersion,
      minimumSupportedBuildNumber: manifest.minimumSupportedBuildNumber || "",
      recommendedVersion: manifest.recommendedVersion,
      recommendedBuildNumber: manifest.recommendedBuildNumber || "",
      functionsRegion: manifest.functionsRegion,
      maintenanceMode: Boolean(manifest.maintenanceMode),
      requiresMandatoryUpdate: Boolean(manifest.requiresMandatoryUpdate),
      usesRemoteContent: Boolean(manifest.usesRemoteContent),
      appCheckRequired: Boolean(manifest.appCheckRequired),
      onlineFeaturesEnabled: Boolean(manifest.onlineFeaturesEnabled),
      offlineProgressCapSeconds: manifest.offlineProgressCapSeconds,
      balanceTuning: balanceTuningContentHashMap(manifest.balanceTuning),
    };
    return createHash("sha256").update(JSON.stringify(payload)).digest("hex");
  }

  function balanceTuningContentHashMap(tuning) {
    const source = normalizeObject(tuning);
    return {
      balanceEpoch: clampInt(source.balanceEpoch, 1, 999999, 1),
      active: source.active === true,
      maxSingleStatDelta: fixedContentDecimal(source.maxSingleStatDelta),
      maxCumulativeStatDelta: fixedContentDecimal(source.maxCumulativeStatDelta),
      towerMultipliers: nestedMultiplierContentHashMap(source.towerMultipliers),
      enemyMultipliers: nestedMultiplierContentHashMap(source.enemyMultipliers),
      economyMultipliers: multiplierContentHashMap(source.economyMultipliers),
    };
  }

  function nestedMultiplierContentHashMap(groups) {
    const source = normalizeObject(groups);
    const result = {};
    for (const id of Object.keys(source).sort()) {
      result[id] = multiplierContentHashMap(source[id]);
    }
    return result;
  }

  function multiplierContentHashMap(multipliers) {
    const source = normalizeObject(multipliers);
    const result = {};
    for (const stat of Object.keys(source).sort()) {
      result[stat] = fixedContentDecimal(source[stat]);
    }
    return result;
  }

  function fixedContentDecimal(value) {
    const numeric = typeof value === "number" && Number.isFinite(value) ? value : 1;
    return numeric.toFixed(4);
  }

  async function loadBalanceTuning() {
    const nowMillis = Date.now();
    if (balanceTuningCache && balanceTuningCache.expiresAt > nowMillis) {
      return balanceTuningCache.value;
    }

    const doc = await db.doc(BALANCE_MANIFEST_DOCUMENT).get();
    if (!doc.exists) {
      balanceTuningCache = {
        value: DEFAULT_BALANCE_TUNING,
        expiresAt: Date.now() + RUNTIME_CONFIG_CACHE_TTL_MILLIS,
      };
      return DEFAULT_BALANCE_TUNING;
    }
    const tuning = sanitizeBalanceTuning(doc.data() || {});
    balanceTuningCache = {
      value: tuning,
      expiresAt: Date.now() + RUNTIME_CONFIG_CACHE_TTL_MILLIS,
    };
    return tuning;
  }

  function sanitizeBalanceTuning(data) {
    const maxSingleStatDelta = clampNumber(
      data.maxSingleStatDelta,
      0,
      0.05,
      DEFAULT_BALANCE_TUNING.maxSingleStatDelta,
    );
    const maxCumulativeStatDelta = clampNumber(
      data.maxCumulativeStatDelta,
      maxSingleStatDelta,
      0.25,
      DEFAULT_BALANCE_TUNING.maxCumulativeStatDelta,
    );
    const previousTowerMultipliers = normalizeObject(data.previousTowerMultipliers);
    const previousEnemyMultipliers = normalizeObject(data.previousEnemyMultipliers);
    const previousEconomyMultipliers = normalizeObject(data.previousEconomyMultipliers);

    return {
      balanceEpoch: clampInt(data.balanceEpoch, 1, 999999, 1),
      active: data.active === true,
      maxSingleStatDelta,
      maxCumulativeStatDelta,
      towerMultipliers: sanitizeNestedBalanceMultipliers(
        data.towerMultipliers,
        previousTowerMultipliers,
        TOWER_BALANCE_STATS,
        maxSingleStatDelta,
        maxCumulativeStatDelta,
      ),
      enemyMultipliers: sanitizeNestedBalanceMultipliers(
        data.enemyMultipliers,
        previousEnemyMultipliers,
        ENEMY_BALANCE_STATS,
        maxSingleStatDelta,
        maxCumulativeStatDelta,
      ),
      economyMultipliers: sanitizeBalanceMultipliers(
        data.economyMultipliers,
        previousEconomyMultipliers,
        ECONOMY_BALANCE_STATS,
        maxSingleStatDelta,
        maxCumulativeStatDelta,
      ),
    };
  }

  function sanitizeNestedBalanceMultipliers(
    value,
    previousValue,
    allowedStats,
    maxSingleStatDelta,
    maxCumulativeStatDelta,
  ) {
    const groups = normalizeObject(value);
    const previousGroups = normalizeObject(previousValue);
    const result = {};
    let groupCount = 0;

    for (const [rawId, rawStats] of Object.entries(groups)) {
      if (groupCount >= 120) {
        break;
      }
      const id = sanitizeBalanceKey(rawId, 96);
      if (!id) {
        continue;
      }
      const stats = sanitizeBalanceMultipliers(
        rawStats,
        previousGroups[id],
        allowedStats,
        maxSingleStatDelta,
        maxCumulativeStatDelta,
      );
      if (Object.keys(stats).length > 0) {
        result[id] = stats;
        groupCount += 1;
      }
    }

    return result;
  }

  function sanitizeBalanceMultipliers(
    value,
    previousValue,
    allowedStats,
    maxSingleStatDelta,
    maxCumulativeStatDelta,
  ) {
    const stats = normalizeObject(value);
    const previousStats = normalizeObject(previousValue);
    const result = {};
    let statCount = 0;

    for (const [rawStat, rawValue] of Object.entries(stats)) {
      if (statCount >= 32) {
        break;
      }
      const stat = sanitizeBalanceKey(rawStat, 64);
      if (!stat || !allowedStats.has(stat)) {
        continue;
      }

      const previousMultiplier = clampBalanceMultiplier(
        previousStats[stat],
        1,
        maxCumulativeStatDelta,
      );
      const stepFloor = previousMultiplier * (1 - maxSingleStatDelta);
      const stepCeiling = previousMultiplier * (1 + maxSingleStatDelta);
      const cumulativeFloor = 1 - maxCumulativeStatDelta;
      const cumulativeCeiling = 1 + maxCumulativeStatDelta;
      const minAllowed = Math.max(cumulativeFloor, stepFloor);
      const maxAllowed = Math.min(cumulativeCeiling, stepCeiling);
      const multiplier = clampNumber(rawValue, minAllowed, maxAllowed, 1);

      if (Math.abs(multiplier - 1) > 0.0001) {
        result[stat] = roundToFour(multiplier);
        statCount += 1;
      }
    }

    return result;
  }

  function clampBalanceMultiplier(value, fallback, maxCumulativeStatDelta) {
    return clampNumber(
      value,
      1 - maxCumulativeStatDelta,
      1 + maxCumulativeStatDelta,
      fallback,
    );
  }

  function sanitizeBalanceKey(value, limit) {
    const next = sanitizeString(value, "").slice(0, limit);
    return /^[A-Za-z0-9_:-]+$/.test(next) ? next : "";
  }

  return {
    loadManifest,
    loadBalanceTuning,
  };
}

module.exports = { createRuntimeContent };
