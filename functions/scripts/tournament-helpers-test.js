const assert = require("node:assert/strict");

const { createTournamentHelpers } = require("../src/tournament_helpers");

class HttpsError extends Error {
  constructor(code, message, details) {
    super(message);
    this.code = code;
    this.details = details;
  }
}

const TOURNAMENT_MODE_CONFIGS = Object.freeze({
  enemyBlitz: Object.freeze({
    label: "Anomaly Blitz",
    capacity: 25,
    defaultBucketLabel: null,
    schedule: "weekend",
    testingAlwaysOpen: true,
    rewardBase: Object.freeze({
      flux: 900,
      tickets: 8,
      experienceMultiplier: 1.2,
      experienceBuffHours: 8,
      bonusEquipmentCaches: 1,
    }),
  }),
  hexGauntlet: Object.freeze({
    label: "Hex",
    capacity: 20,
    defaultBucketLabel: null,
    schedule: "weekly",
    rewardBase: Object.freeze({
      flux: 780,
      tickets: 7,
      experienceMultiplier: 1.18,
      experienceBuffHours: 7,
      bonusEquipmentCaches: 1,
    }),
  }),
});

const {
  computeTournamentWindowForMode,
  computePreviousTournamentWindowForMode,
  buildTournamentSeasonKey,
  computeNextTournamentRating,
  sanitizeTournamentSubmittedScore,
} = createTournamentHelpers({
  db: {},
  HttpsError,
  FieldValue: {},
  Timestamp: {
    fromDate(value) {
      return value;
    },
  },
  constants: {
    PROFILE_COLLECTION: "profiles",
    TOURNAMENT_SEASON_COLLECTION: "tournamentSeasons",
    TOURNAMENT_MODE_CONFIGS,
    TOURNAMENT_LIMITS: {
      submittedScore: 10000000,
      overallLevel: 1000,
      coreLevel: 500,
      towerPowerIndex: 500000,
      globalRating: 5000,
    },
    DEFAULT_TOURNAMENT_RATING: 1000,
    EVEN_ENTRY_TOURNAMENT_LEVEL: 1,
    EVEN_ENTRY_TOURNAMENT_CORE_LEVEL: 1,
    EVEN_ENTRY_TOURNAMENT_BUILT_TOWER_COUNT: 6,
    EVEN_ENTRY_TOURNAMENT_POWER_INDEX: 1000,
  },
  helpers: {
    requireAuth() {
      throw new Error("not used");
    },
    loadManifest() {
      throw new Error("not used");
    },
    requireAppCheckIfNeeded() {},
    clampInt,
    clampNumber,
    sanitizeString,
    sanitizeOptionalString,
    normalizeStoredScreenName: sanitizeOptionalString,
    toMillis() {
      return 0;
    },
    roundToTwo(value) {
      return Math.round(value * 100) / 100;
    },
  },
});

const testingWindow = computeTournamentWindowForMode(
  "enemyBlitz",
  new Date("2026-04-30T12:00:00.000Z"),
);
assert.equal(testingWindow.isOpen, true);
assert.equal(testingWindow.startsAt.toISOString(), "2026-04-27T00:00:00.000Z");
assert.equal(testingWindow.endsAt.toISOString(), "2026-05-04T00:00:00.000Z");
assert.equal(
  buildTournamentSeasonKey("preseason-alpha", "enemyBlitz", testingWindow),
  "preseason-alpha:enemyBlitz:2026-04-27",
);

const stillOpenDuringWeekend = computeTournamentWindowForMode(
  "enemyBlitz",
  new Date("2026-05-02T12:00:00.000Z"),
);
assert.equal(stillOpenDuringWeekend.isOpen, true);
assert.equal(
  stillOpenDuringWeekend.startsAt.toISOString(),
  "2026-04-27T00:00:00.000Z",
);
assert.equal(
  stillOpenDuringWeekend.endsAt.toISOString(),
  "2026-05-04T00:00:00.000Z",
);

const nextTestingWindow = computeTournamentWindowForMode(
  "enemyBlitz",
  new Date("2026-05-04T00:00:00.000Z"),
);
assert.equal(nextTestingWindow.isOpen, true);
assert.equal(
  nextTestingWindow.startsAt.toISOString(),
  "2026-05-04T00:00:00.000Z",
);
assert.equal(
  nextTestingWindow.endsAt.toISOString(),
  "2026-05-11T00:00:00.000Z",
);

const previousTestingWindow = computePreviousTournamentWindowForMode(
  "enemyBlitz",
  new Date("2026-05-04T00:00:00.000Z"),
);
assert.equal(previousTestingWindow.isOpen, false);
assert.equal(
  previousTestingWindow.startsAt.toISOString(),
  "2026-04-27T00:00:00.000Z",
);
assert.equal(
  previousTestingWindow.endsAt.toISOString(),
  "2026-05-04T00:00:00.000Z",
);

const weeklyWindow = computeTournamentWindowForMode(
  "hexGauntlet",
  new Date("2026-05-02T12:00:00.000Z"),
);
assert.equal(weeklyWindow.isOpen, true);
assert.equal(weeklyWindow.startsAt.toISOString(), "2026-04-27T00:00:00.000Z");
assert.equal(weeklyWindow.endsAt.toISOString(), "2026-05-04T00:00:00.000Z");

assert.equal(
  computeNextTournamentRating({
    currentRating: 1000,
    submittedScore: 250,
    previousBestScore: 800,
  }),
  980,
);
assert.equal(
  computeNextTournamentRating({
    currentRating: 1000,
    submittedScore: 2600,
    previousBestScore: 1000,
  }),
  1030,
);
assert.equal(sanitizeTournamentSubmittedScore("hexGauntlet", 0, {}), 0);

function clampInt(value, min, max, fallback) {
  const number = Number(value);
  if (!Number.isFinite(number)) {
    return fallback;
  }
  return Math.min(max, Math.max(min, Math.trunc(number)));
}

function clampNumber(value, min, max, fallback) {
  const number = Number(value);
  if (!Number.isFinite(number)) {
    return fallback;
  }
  return Math.min(max, Math.max(min, number));
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
