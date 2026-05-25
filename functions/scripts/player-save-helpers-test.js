const assert = require("node:assert/strict");

const { createPlayerSaveHelpers } = require("../src/player_save_helpers");

class HttpsError extends Error {
  constructor(code, message, details) {
    super(message);
    this.code = code;
    this.details = details;
  }
}

const PLAYER_SAVE_LIMITS = Object.freeze({
  maxRevision: 1000000000,
  maxCurrency: 1000000000000,
  maxCounter: 1000000000,
  maxTowerStrength: 9000000000000000,
  maxMetricSeconds: 1000000000,
  maxLayers: 64,
  maxSlotsPerLayer: 6,
  maxInventoryCards: 400,
  maxEnemyManagers: 300,
  maxEnemyCards: 160,
  maxEquipmentItems: 250,
  maxBattlePasses: 16,
  maxHelpSections: 256,
  maxGuildMembers: 7,
  maxGuildMessages: 60,
  maxStringLength: 160,
});
const SAVE_INTEGRITY_LIMITS = Object.freeze({
  maxSnapshotRateSlackMultiplier: 3,
  maxLayerTier: 500,
  maxCoreLevel: 500,
});
const SERVER_BALANCE_LIMITS = Object.freeze({
  maxOfflineKillsPerHour: 600,
  spawnIntervalSeconds: 1.35,
  promotedSourcePassiveMultiplier: 1 / 6,
});
const SNAPSHOT_LIMITS = Object.freeze({
  passiveLumensPerHour: 250000,
  fluxPerHour: 25000,
  enemyTicketsPerHour: 1500,
  killsPerHour: 600,
  activeLayerTier: 50,
  builtTowerCount: 200,
  prestigeLevel: 1000,
});

const { buildAuthoritativeIdleSnapshot, sanitizePlayerSavePayload } =
  createPlayerSaveHelpers({
    db: {},
    logger: { warn() {} },
    HttpsError,
    constants: {
      PROFILE_COLLECTION: "profiles",
      PRIVATE_PROFILE_COLLECTION: "private",
      PLAYER_SAVE_DOCUMENT: "save",
      PLAYER_SAVE_SCHEMA_VERSION: 1,
      PLAYER_SAVE_LIMITS,
      SAVE_INTEGRITY_LIMITS,
      SERVER_BALANCE_LIMITS,
      SNAPSHOT_LIMITS,
    },
    helpers: {
      clampInt,
      clampNumber,
      sanitizeString,
      sanitizeOptionalString,
      sanitizePlayerId,
      normalizeStoredScreenName,
      normalizeObject,
      normalizeArray,
      timestampToIso() {
        return null;
      },
      toMillis() {
        return 0;
      },
      isDateKeyBeyondAllowedFuture() {
        return false;
      },
    },
  });

const payload = sanitizePlayerSavePayload(
  basePayload({
    player: {
      playerId: "LUMI-TEST-0001",
      radianceStats: {
        might: 2,
        focus: "3",
        tempo: -5,
        insight: 4.8,
        unused: 99,
      },
    },
  }),
);

assert.deepEqual(payload.player.radianceStats, {
  might: 2,
  focus: 3,
  tempo: 0,
  insight: 4,
});
assert.equal(payload.player.radianceStats.unused, undefined);

const missingStatsPayload = sanitizePlayerSavePayload(
  basePayload({ player: { playerId: "LUMI-TEST-0002" } }),
);
assert.deepEqual(missingStatsPayload.player.radianceStats, {
  might: 0,
  focus: 0,
  tempo: 0,
  insight: 0,
});

const authoritativeSnapshot = buildAuthoritativeIdleSnapshot({
  clientSnapshot: {
    generatedAtMillis: Date.now(),
    passiveLumensPerHour: 1,
    fluxPerHour: 999999,
    enemyTicketsPerHour: 999999,
    killsPerHour: 1,
    activeLayerTier: 1,
    builtTowerCount: 1,
    prestigeLevel: 0,
  },
  savePayload: basePayload({
    inventory: {
      cards: [{ equippedLayerId: "root" }],
    },
    layers: {
      activeLayerId: "root",
      items: [
        {
          id: "root",
          tier: 1,
          core: { level: 1 },
          swarmActivated: true,
          enemyTargetCount: 6,
          slots: [{ configId: "red-prism" }],
        },
      ],
    },
  }),
});

assert.equal(authoritativeSnapshot.fluxPerHour, 0);
assert.equal(authoritativeSnapshot.enemyTicketsPerHour, 0);
assert.equal(authoritativeSnapshot.activeLayerTier, 1);
assert.equal(authoritativeSnapshot.builtTowerCount, 1);
assert.equal(authoritativeSnapshot.passiveLumensPerHour, 0);
assert.equal(authoritativeSnapshot.killsPerHour, 0);

const validatedFarmSnapshot = buildAuthoritativeIdleSnapshot({
  clientSnapshot: {
    generatedAtMillis: Date.now(),
    passiveLumensPerHour: 120,
    fluxPerHour: 0,
    enemyTicketsPerHour: 0,
    killsPerHour: 12,
    activeLayerTier: 1,
    builtTowerCount: 1,
    prestigeLevel: 0,
  },
  savePayload: basePayload({
    inventory: {
      enemyManagers: [
        {
          instanceId: "director-1",
          spawnRateMultiplier: 1.2,
          rewardMultiplier: 1.3,
          healthMultiplier: 1.1,
          speedMultiplier: 1.05,
        },
      ],
    },
    threatMap: {
      validatedFarmRegionId: "region_r1_0_0",
      validatedFarmStabilizedLevel: 3,
      validatedFarmThreatDirectorId: "director-1",
      validatedFarmSwarmSize: 12,
      validatedFarmEfficiency: 0.95,
      validatedFarmLumensPerHour: 240,
    },
    layers: {
      activeLayerId: "root",
      items: [
        {
          id: "root",
          tier: 1,
          core: { level: 1 },
          slots: [{ configId: "red-prism" }],
        },
      ],
    },
  }),
});

assert.ok(validatedFarmSnapshot.killsPerHour > 0);
assert.equal(validatedFarmSnapshot.passiveLumensPerHour, 240);
assert.equal(validatedFarmSnapshot.offlineRegionId, "region_r1_0_0");
assert.equal(
  validatedFarmSnapshot.offlineRegionValidatedThreatDirectorId,
  "director-1",
);

assert.throws(
  () =>
    buildAuthoritativeIdleSnapshot({
      clientSnapshot: {
        generatedAtMillis: Date.now(),
        passiveLumensPerHour: 999999,
        fluxPerHour: 0,
        enemyTicketsPerHour: 0,
        killsPerHour: 0,
        activeLayerTier: 1,
        builtTowerCount: 0,
        prestigeLevel: 0,
      },
      savePayload: basePayload(),
    }),
  /Idle snapshot rejected by server progression checks/,
);

function basePayload(overrides = {}) {
  return {
    savedAtMillis: 1234,
    player: {
      playerId: "LUMI-TEST-0000",
      ...(overrides.player || {}),
    },
    resources: {},
    metrics: {},
    dailyDungeons: {},
    readHelpSections: [],
    battlePasses: [],
    store: {},
    inventory: {},
    layers: {},
    completedTowerShells: [],
    tutorial: {},
    ...withoutPlayer(overrides),
  };
}

function withoutPlayer(value) {
  const next = { ...value };
  delete next.player;
  return next;
}

function normalizeObject(value) {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value
    : {};
}

function normalizeArray(value) {
  return Array.isArray(value) ? value : [];
}

function sanitizeString(value, fallback) {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : fallback;
}

function sanitizeOptionalString(value) {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : null;
}

function normalizeStoredScreenName(value) {
  return sanitizeOptionalString(value);
}

function sanitizePlayerId(value) {
  const next = sanitizeString(value, "").trim().toUpperCase();
  if (!/^LUMI-[A-Z0-9]{4}-[A-Z0-9]{4}$/.test(next)) {
    throw new HttpsError("invalid-argument", "Invalid player ID format.");
  }
  return next;
}

function clampNumber(value, min, max, fallback = 0) {
  const numeric = Number(value);
  if (!Number.isFinite(numeric)) {
    return fallback;
  }
  return Math.min(max, Math.max(min, numeric));
}

function clampInt(value, min, max, fallback = 0) {
  const numeric = Number.parseInt(value, 10);
  if (!Number.isFinite(numeric)) {
    return fallback;
  }
  return Math.min(max, Math.max(min, numeric));
}
