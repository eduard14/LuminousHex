const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions, logger } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { createHash, randomUUID } = require("crypto");
const { createRuntimeContent } = require("./src/runtime_content");
const { createPlayerSaveHelpers } = require("./src/player_save_helpers");
const { createTournamentHelpers } = require("./src/tournament_helpers");

initializeApp();
setGlobalOptions({ region: "us-central1", maxInstances: 10 });

const db = getFirestore();

const PROFILE_COLLECTION = "playerProfiles";
const PUBLIC_PROFILE_COLLECTION = "publicProfiles";
const SCREEN_NAME_CLAIM_COLLECTION = "screenNameClaims";
const TOURNAMENT_SEASON_COLLECTION = "tournamentSeasons";
const MENTOR_LINK_COLLECTION = "mentorLinks";
const MENTOR_INVITE_COLLECTION = "mentorInvites";
const FRIEND_LINK_COLLECTION = "friendLinks";
const FRIEND_REQUEST_COLLECTION = "friendRequests";
const DAILY_BOSS_GIFT_COLLECTION = "dailyBossGifts";
const PRIVATE_PROFILE_COLLECTION = "private";
const PLAYER_SAVE_DOCUMENT = "saveState";
const BALANCE_MANIFEST_DOCUMENT = "runtime/balanceManifest";
const RUNTIME_CONFIG_CACHE_TTL_MILLIS = 60 * 1000;


const DEFAULT_TOURNAMENT_RATING = 1000;
const EVEN_ENTRY_TOURNAMENT_LEVEL = 1;
const EVEN_ENTRY_TOURNAMENT_CORE_LEVEL = 1;
const EVEN_ENTRY_TOURNAMENT_BUILT_TOWER_COUNT = 6;
const EVEN_ENTRY_TOURNAMENT_POWER_INDEX = 1000;
const OVERALL_LEVEL_EXPERIENCE_GROWTH = 1.03;
const PLAYER_SAVE_SCHEMA_VERSION = 1;
const SCREEN_NAME_LIMITS = Object.freeze({
  min: 3,
  max: 20,
});

const DEFAULT_BALANCE_TUNING = Object.freeze({
  balanceEpoch: 1,
  active: false,
  maxSingleStatDelta: 0.05,
  maxCumulativeStatDelta: 0.25,
  towerMultipliers: Object.freeze({}),
  enemyMultipliers: Object.freeze({}),
  economyMultipliers: Object.freeze({}),
});

const DEFAULT_MANIFEST = Object.freeze({
  contentSchemaVersion: 1,
  seasonKey: "preseason-alpha",
  contentEpoch: 1,
  minimumSupportedVersion: "1.0.18",
  minimumSupportedBuildNumber: "19",
  recommendedVersion: "1.0.18",
  recommendedBuildNumber: "19",
  functionsRegion: "us-central1",
  maintenanceMode: false,
  requiresMandatoryUpdate: false,
  usesRemoteContent: true,
  appCheckRequired: true,
  onlineFeaturesEnabled: true,
  offlineProgressCapSeconds: 4 * 60 * 60,
  balanceTuning: DEFAULT_BALANCE_TUNING,
  statusMessage:
    "Server bootstrap active. Client version and offline claims are being validated.",
});

const TOWER_BALANCE_STATS = new Set([
  "buildCost",
  "basePower",
  "baseChargeRate",
  "baseCooldown",
  "baseGenerationSpeed",
  "baseCritChance",
  "baseCritMultiplier",
  "coreCooldownMultiplier",
  "jamHitMultiplier",
  "jamDecayMultiplier",
  "lumenPressureGuard",
  "affinityBonusMultiplier",
]);

const ENEMY_BALANCE_STATS = new Set([
  "baseHealth",
  "baseDefense",
  "baseSpeed",
  "reward",
  "baseExperience",
  "jamStrength",
  "baseSpiralDrift",
]);

const ECONOMY_BALANCE_STATS = new Set([
  "lumenReward",
  "fluxReward",
  "threatScanReward",
  "experienceReward",
  "passiveLumens",
  "offlineKills",
]);

const SNAPSHOT_LIMITS = Object.freeze({
  passiveLumensPerHour: 250000,
  fluxPerHour: 25000,
  enemyTicketsPerHour: 1500,
  killsPerHour: 600,
  activeLayerTier: 50,
  builtTowerCount: 200,
  prestigeLevel: 1000,
});

const SERVER_BALANCE_LIMITS = Object.freeze({
  maxOfflineKillsPerHour: 600,
  spawnIntervalSeconds: 1.35,
  slotCount: 6,
  promotedSourcePassiveMultiplier: 1 / 6,
});

const TOURNAMENT_LIMITS = Object.freeze({
  overallLevel: 5000,
  coreLevel: 500,
  towerPowerIndex: 500000,
  submittedScore: 5000000,
  globalRating: 5000,
});

const SOCIAL_LIMITS = Object.freeze({
  mentorLevelBand: 6,
  mentorshipUnlockLevel: 30,
  activeMenteeBonusLimit: 6,
  maxFriends: 30,
  maxOverviewMentees: 80,
  maxOverviewGrandMentees: 160,
  globalLeaderboardLimit: 20,
  publicProfilePublishIntervalMillis: 3 * 60 * 1000,
  bossPullGiftAmount: 1,
  maxTargetLength: 64,
  maxInviteIdLength: 180,
});

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
  maxPayloadBytes: 700000,
  maxFutureSkewMillis: 5 * 60 * 1000,
  maxFutureDateKeySkewDays: 0,
  maxSaveDeltaGraceSeconds: 10 * 60,
  maxSaveDeltaWindowSeconds: 7 * 24 * 60 * 60,
  maxSnapshotRateSlackMultiplier: 3,
  maxSaveDeltaRateSlackMultiplier: 12,
  maxLayerTier: 500,
  maxTowerLevel: 5,
  maxCoreLevel: 500,
  maxEquipmentLevel: 300,
  minManagerMultiplier: 0.2,
  maxManagerMultiplier: 4,
  maxAutomationRate: 5,
  maxEquipmentBonus: 5,
  maxCritChanceBonus: 1.5,
  suspiciousLumensDelta: 250000000,
  suspiciousFluxDelta: 25000000,
  suspiciousPrismShardsDelta: 100000,
  suspiciousTicketDelta: 1000000,
  suspiciousCounterDelta: 1000000,
});

const TOURNAMENT_MODE_CONFIGS = Object.freeze({
  enemyBlitz: Object.freeze({
    label: "Anomaly Blitz",
    mechanicSummary:
      "Draft anomalies from your tournament pool, start a weekend-length survival session, and keep upgrading the tower before rewards unlock at reset.",
    capacity: 25,
    defaultBucketLabel: null,
    schedule: "weekend",
    testingAlwaysOpen: true,
    usesTowerSeed: false,
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
    mechanicSummary:
      "Import an event-normalized shell into a separate hex path map and see how far the weekly global climb goes.",
    capacity: 20,
    defaultBucketLabel: null,
    schedule: "weekly",
    usesTowerSeed: false,
    rewardBase: Object.freeze({
      flux: 780,
      tickets: 7,
      experienceMultiplier: 1.18,
      experienceBuffHours: 7,
      bonusEquipmentCaches: 1,
    }),
  }),
  arenaFlow: Object.freeze({
    label: "Arena Flow",
    mechanicSummary:
      "Send your highest-layer Home Tower into a 20-second arena duel, trade enemy waves with a rival tower, and climb by net damage.",
    capacity: 15,
    defaultBucketLabel: null,
    schedule: "weekly",
    usesTowerSeed: false,
    rewardBase: Object.freeze({
      flux: 1100,
      tickets: 10,
      experienceMultiplier: 1.25,
      experienceBuffHours: 10,
      bonusEquipmentCaches: 2,
    }),
  }),
});

const { loadManifest, loadBalanceTuning } = createRuntimeContent({
  db,
  createHash,
  constants: {
    BALANCE_MANIFEST_DOCUMENT,
    RUNTIME_CONFIG_CACHE_TTL_MILLIS,
    DEFAULT_MANIFEST,
    DEFAULT_BALANCE_TUNING,
    TOWER_BALANCE_STATS,
    ENEMY_BALANCE_STATS,
    ECONOMY_BALANCE_STATS,
  },
  helpers: {
    clampInt,
    clampNumber,
    normalizeObject,
    sanitizeString,
    resolveManifestVersionGate,
    roundToFour,
  },
});

const {
  buildOfflineClaimStatusMessage,
  playerSaveRef,
  buildPlayerSaveResponse,
  isRecoverableAuth,
  rejectInvalidRawSavePayload,
  rejectImplausibleSaveDelta,
  buildAuthoritativeIdleSnapshot,
  buildIdleSnapshotFromSavePayload,
  buildSaveIntegritySummary,
  sanitizePlayerSavePayload,
} = createPlayerSaveHelpers({
  db,
  logger,
  HttpsError,
  constants: {
    PROFILE_COLLECTION,
    PRIVATE_PROFILE_COLLECTION,
    PLAYER_SAVE_DOCUMENT,
    PLAYER_SAVE_SCHEMA_VERSION,
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
    timestampToIso,
    toMillis,
    isDateKeyBeyondAllowedFuture,
  },
});

const {
  loadTournamentContext,
  buildTournamentOverview,
  buildTournamentModeState,
  buildTournamentReward,
  computeNextTournamentRating,
  computeTournamentRank,
  buildTournamentGrouping,
  touchTournamentSeason,
  tournamentEntryRef,
  computeTournamentOverviewWindow,
  computePreviousTournamentWindowForMode,
  ensureTournamentModeOpen,
  normalizeTournamentPlayerSnapshot,
  sanitizeTournamentSubmittedScore,
  resolveDisplayName,
  normalizeTournamentBoost,
  sanitizeTournamentMode,
  sanitizeTournamentRating,
  buildTournamentSeasonKey,
  hasPremiumMembership,
} = createTournamentHelpers({
  db,
  HttpsError,
  FieldValue,
  Timestamp,
  constants: {
    PROFILE_COLLECTION,
    TOURNAMENT_SEASON_COLLECTION,
    TOURNAMENT_MODE_CONFIGS,
    TOURNAMENT_LIMITS,
    DEFAULT_TOURNAMENT_RATING,
    EVEN_ENTRY_TOURNAMENT_LEVEL,
    EVEN_ENTRY_TOURNAMENT_CORE_LEVEL,
    EVEN_ENTRY_TOURNAMENT_BUILT_TOWER_COUNT,
    EVEN_ENTRY_TOURNAMENT_POWER_INDEX,
  },
  helpers: {
    requireAuth,
    loadManifest,
    requireAppCheckIfNeeded,
    clampInt,
    clampNumber,
    sanitizeString,
    sanitizeOptionalString,
    normalizeStoredScreenName,
    toMillis,
    roundToTwo,
  },
});

exports.bootstrapClient = onCall({ enforceAppCheck: false }, async (request) => {
  const auth = requireAuth(request);
  const manifest = await loadManifest();
  requireAppCheckIfNeeded(request, manifest);

  const playerId = sanitizePlayerId(request.data?.playerId);
  const clientVersion = sanitizeVersion(request.data?.clientVersion);
  const clientBuildNumber = sanitizeBuildNumber(request.data?.clientBuildNumber);
  const platform = sanitizePlatform(request.data?.platform);
  const versionGate = computeVersionGate(clientVersion, clientBuildNumber, manifest);
  const sessionId = createSessionId();
  const serverNow = new Date();

  const profileRef = db.collection(PROFILE_COLLECTION).doc(auth.uid);
  const publicRef = db.collection(PUBLIC_PROFILE_COLLECTION).doc(auth.uid);

  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(profileRef);
    const existingData = existing.data() || {};
    const baseUpdate = {
      playerId,
      authUid: auth.uid,
      isAnonymous: !isRecoverableAuth(auth),
      clientVersion,
      clientBuildNumber,
      lastBootstrapAt: FieldValue.serverTimestamp(),
      lastPlatform: platform,
      lastVersionGate: versionGate,
      activeSessionId: sessionId,
      activeSessionStartedAt: FieldValue.serverTimestamp(),
    };

    if (!existing.exists) {
      transaction.set(profileRef, {
        ...baseUpdate,
        createdAt: FieldValue.serverTimestamp(),
        idleSnapshot: null,
        lastActiveAt: null,
        lastIdleClaimAt: null,
        globalTournamentRating: DEFAULT_TOURNAMENT_RATING,
        activeTournamentExpMultiplier: 1,
        activeTournamentBoostEndsAt: null,
        hasPremiumMembership: false,
      });
    } else {
      transaction.set(profileRef, baseUpdate, { merge: true });
    }

    transaction.set(
      publicRef,
      {
        playerId,
        displayName: sanitizeString(existingData.screenName, playerId),
        screenNameLower: normalizeSearchKey(existingData.screenName),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

  const profileSnap = await profileRef.get();
  const profileData = profileSnap.data() || {};

  return {
    manifest,
    profile: buildProfileResponse(profileData, auth, playerId),
    sessionId,
    ...buildServerClockPayload(serverNow),
  };
});

exports.updateScreenName = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const auth = requireAuth(request);
    const manifest = await loadManifest();
    requireAppCheckIfNeeded(request, manifest);

    const screenName = sanitizeScreenName(request.data?.screenName);
    const screenNameLower = normalizeSearchKey(screenName);
    const profileRef = db.collection(PROFILE_COLLECTION).doc(auth.uid);
    const publicRef = db.collection(PUBLIC_PROFILE_COLLECTION).doc(auth.uid);
    const screenNameClaimRef = screenNameReservationRef(screenNameLower);
    const seasonKey = manifest.seasonKey;

    await db.runTransaction(async (transaction) => {
      const profileSnap = await transaction.get(profileRef);
      if (!profileSnap.exists) {
        throw new HttpsError(
          "failed-precondition",
          "Player profile does not exist yet. Bootstrap first.",
        );
      }

      const profileData = profileSnap.data() || {};
      const existingScreenNameLower = normalizeSearchKey(profileData.screenName);
      const existingScreenNameClaimRef =
        existingScreenNameLower && existingScreenNameLower !== screenNameLower
          ? screenNameReservationRef(existingScreenNameLower)
          : null;
      const screenNameClaimSnap = await transaction.get(screenNameClaimRef);
      const existingScreenNameClaimSnap = existingScreenNameClaimRef
        ? await transaction.get(existingScreenNameClaimRef)
        : null;
      const publicNameSnap = await transaction.get(
        db
          .collection(PUBLIC_PROFILE_COLLECTION)
          .where("screenNameLower", "==", screenNameLower)
          .limit(2),
      );
      const claimedByUid = sanitizeString(screenNameClaimSnap.data()?.uid, "");
      if (screenNameClaimSnap.exists && claimedByUid !== auth.uid) {
        throw new HttpsError(
          "already-exists",
          "That screen name is already taken.",
        );
      }
      const publicNameConflict = publicNameSnap.docs.find(
        (doc) => doc.id !== auth.uid,
      );
      if (publicNameConflict) {
        throw new HttpsError(
          "already-exists",
          "That screen name is already taken.",
        );
      }

      transaction.set(
        screenNameClaimRef,
        {
          uid: auth.uid,
          screenName,
          screenNameLower,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      if (
        existingScreenNameClaimRef &&
        existingScreenNameClaimSnap.exists &&
        sanitizeString(existingScreenNameClaimSnap.data()?.uid, "") === auth.uid
      ) {
        transaction.delete(existingScreenNameClaimRef);
      }
      transaction.set(
        profileRef,
        {
          screenName,
          lastScreenNameUpdateAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      transaction.set(
        publicRef,
          {
            playerId: sanitizeString(profileData.playerId, ""),
            screenName,
            screenNameLower,
            displayName: screenName,
            updatedAt: FieldValue.serverTimestamp(),
          },
        { merge: true },
      );

      for (const mode of Object.keys(TOURNAMENT_MODE_CONFIGS)) {
        transaction.set(
          tournamentEntryRef(seasonKey, mode, auth.uid),
          {
            displayName: screenName,
            screenName,
          },
          { merge: true },
        );
      }
    });

    const profileSnap = await profileRef.get();
    const profileData = profileSnap.data() || {};

    return {
      profile: buildProfileResponse(profileData, auth),
    };
  },
);

exports.purchasePremiumMembership = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const auth = requireAuth(request);
    const manifest = await loadManifest();
    requireAppCheckIfNeeded(request, manifest);

    const profileRef = db.collection(PROFILE_COLLECTION).doc(auth.uid);

    await db.runTransaction(async (transaction) => {
      const profileSnap = await transaction.get(profileRef);
      if (!profileSnap.exists) {
        throw new HttpsError(
          "failed-precondition",
          "Player profile does not exist yet. Bootstrap first.",
        );
      }

      transaction.set(
        profileRef,
        {
          hasPremiumMembership: true,
          premiumMembershipPurchasedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });

    const profileSnap = await profileRef.get();
    const profileData = profileSnap.data() || {};

    return {
      profile: buildProfileResponse(profileData, auth),
    };
  },
);

exports.getSocialOverview = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const context = await loadSocialContext(request);
    return buildSocialOverview(context);
  },
);

exports.sendMentorInvite = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const context = await loadSocialContext(request);
    assertMentorshipUnlocked(await loadPublicProfileData(context.auth.uid));
    const targetUid = await resolveTargetUid(
      request.data?.target,
      context.auth.uid,
    );
    assertMentorshipUnlocked(await loadPublicProfileData(targetUid));
    const inviteRef = db
      .collection(MENTOR_INVITE_COLLECTION)
      .doc(`${context.auth.uid}_${targetUid}`);
    const linkRef = db.collection(MENTOR_LINK_COLLECTION).doc(targetUid);

    await db.runTransaction(async (transaction) => {
      const targetLinkSnap = await transaction.get(linkRef);
      if (targetLinkSnap.exists) {
        throw new HttpsError(
          "failed-precondition",
          "That player already has a mentor.",
        );
      }
      const existingInvite = await transaction.get(inviteRef);
      if (existingInvite.exists && existingInvite.data()?.status === "pending") {
        throw new HttpsError(
          "already-exists",
          "A mentor invite is already pending for that player.",
        );
      }

      transaction.set(inviteRef, {
        mentorUid: context.auth.uid,
        menteeUid: targetUid,
        status: "pending",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });

    return { overview: await buildSocialOverview(context) };
  },
);

exports.respondMentorInvite = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const context = await loadSocialContext(request);
    const inviteId = sanitizeString(
      request.data?.inviteId,
      "",
      SOCIAL_LIMITS.maxInviteIdLength,
    );
    const accept = request.data?.accept === true;
    if (!inviteId) {
      throw new HttpsError("invalid-argument", "Mentor invite id is required.");
    }
    if (accept) {
      assertMentorshipUnlocked(await loadPublicProfileData(context.auth.uid));
    }

    const inviteRef = db.collection(MENTOR_INVITE_COLLECTION).doc(inviteId);
    const linkRef = db.collection(MENTOR_LINK_COLLECTION).doc(context.auth.uid);

    await db.runTransaction(async (transaction) => {
      const inviteSnap = await transaction.get(inviteRef);
      if (!inviteSnap.exists || inviteSnap.data()?.status !== "pending") {
        throw new HttpsError("not-found", "Mentor invite is no longer pending.");
      }
      const invite = inviteSnap.data() || {};
      if (invite.menteeUid !== context.auth.uid) {
        throw new HttpsError(
          "permission-denied",
          "Only the invited player can answer this mentor invite.",
        );
      }

      if (accept) {
        const existingLink = await transaction.get(linkRef);
        if (existingLink.exists) {
          throw new HttpsError(
            "failed-precondition",
            "You already have a mentor.",
          );
        }
        const mentorProfileSnap = await transaction.get(
          db.collection(PUBLIC_PROFILE_COLLECTION).doc(invite.mentorUid),
        );
        assertMentorshipUnlocked(mentorProfileSnap.data() || null);
        await assertNoMentorCycle(
          transaction,
          invite.mentorUid,
          context.auth.uid,
        );
        transaction.set(linkRef, {
          mentorUid: invite.mentorUid,
          menteeUid: context.auth.uid,
          createdAt: FieldValue.serverTimestamp(),
          sourceInviteId: inviteId,
        });
      }

      transaction.set(
        inviteRef,
        {
          status: accept ? "accepted" : "declined",
          respondedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });

    return { overview: await buildSocialOverview(context) };
  },
);

exports.acceptMentorLink = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const context = await loadSocialContext(request);
    assertMentorshipUnlocked(await loadPublicProfileData(context.auth.uid));
    const mentorUid = await resolveTargetUid(
      request.data?.mentor || request.data?.target,
      context.auth.uid,
    );
    assertMentorshipUnlocked(await loadPublicProfileData(mentorUid));
    const linkRef = db.collection(MENTOR_LINK_COLLECTION).doc(context.auth.uid);
    const inviteRef = db
      .collection(MENTOR_INVITE_COLLECTION)
      .doc(`${mentorUid}_${context.auth.uid}`);

    await db.runTransaction(async (transaction) => {
      const existingLink = await transaction.get(linkRef);
      const inviteSnap = await transaction.get(inviteRef);
      if (existingLink.exists) {
        throw new HttpsError(
          "failed-precondition",
          "You already have a mentor.",
        );
      }

      await assertNoMentorCycle(transaction, mentorUid, context.auth.uid);
      transaction.set(linkRef, {
        mentorUid,
        menteeUid: context.auth.uid,
        createdAt: FieldValue.serverTimestamp(),
        sourceInviteId:
          inviteSnap.exists && inviteSnap.data()?.status === "pending"
            ? inviteRef.id
            : null,
        source: "mentor-link",
      });

      if (inviteSnap.exists && inviteSnap.data()?.status === "pending") {
        transaction.set(
          inviteRef,
          {
            status: "accepted",
            respondedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
    });

    return { overview: await buildSocialOverview(context) };
  },
);

exports.sendFriendRequest = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const context = await loadSocialContext(request);
    const targetUid = await resolveTargetUid(request.data?.target, context.auth.uid);
    const pairKey = socialPairKey(context.auth.uid, targetUid);
    const requestId = `${context.auth.uid}_${targetUid}`;
    const reverseRequestId = `${targetUid}_${context.auth.uid}`;
    const linkRef = db.collection(FRIEND_LINK_COLLECTION).doc(pairKey);
    const requestRef = db.collection(FRIEND_REQUEST_COLLECTION).doc(requestId);
    const reverseRequestRef = db
      .collection(FRIEND_REQUEST_COLLECTION)
      .doc(reverseRequestId);

    await db.runTransaction(async (transaction) => {
      const linkSnap = await transaction.get(linkRef);
      if (linkSnap.exists) {
        throw new HttpsError("already-exists", "You are already friends.");
      }
      const existingSnap = await transaction.get(requestRef);
      const reverseSnap = await transaction.get(reverseRequestRef);
      if (
        (existingSnap.exists && existingSnap.data()?.status === "pending") ||
        (reverseSnap.exists && reverseSnap.data()?.status === "pending")
      ) {
        throw new HttpsError(
          "already-exists",
          "A friend request is already pending between these players.",
        );
      }

      transaction.set(requestRef, {
        fromUid: context.auth.uid,
        targetUid,
        pairKey,
        status: "pending",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });

    return { overview: await buildSocialOverview(context) };
  },
);

exports.respondFriendRequest = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const context = await loadSocialContext(request);
    const requestId = sanitizeString(
      request.data?.requestId,
      "",
      SOCIAL_LIMITS.maxInviteIdLength,
    );
    const accept = request.data?.accept === true;
    if (!requestId) {
      throw new HttpsError("invalid-argument", "Friend request id is required.");
    }

    const requestRef = db.collection(FRIEND_REQUEST_COLLECTION).doc(requestId);

    await db.runTransaction(async (transaction) => {
      const requestSnap = await transaction.get(requestRef);
      if (!requestSnap.exists || requestSnap.data()?.status !== "pending") {
        throw new HttpsError("not-found", "Friend request is no longer pending.");
      }
      const requestData = requestSnap.data() || {};
      if (requestData.targetUid !== context.auth.uid) {
        throw new HttpsError(
          "permission-denied",
          "Only the requested player can answer this friend request.",
        );
      }

      if (accept) {
        const fromUid = requestData.fromUid;
        const pairKey = socialPairKey(fromUid, context.auth.uid);
        const [selfCount, otherCount] = await Promise.all([
          countFriendsForUidTransaction(transaction, context.auth.uid),
          countFriendsForUidTransaction(transaction, fromUid),
        ]);
        if (
          selfCount >= SOCIAL_LIMITS.maxFriends ||
          otherCount >= SOCIAL_LIMITS.maxFriends
        ) {
          throw new HttpsError(
            "failed-precondition",
            `Friend lists are capped at ${SOCIAL_LIMITS.maxFriends}.`,
          );
        }
        transaction.set(db.collection(FRIEND_LINK_COLLECTION).doc(pairKey), {
          uids: [fromUid, context.auth.uid].sort(),
          createdAt: FieldValue.serverTimestamp(),
          sourceRequestId: requestId,
        });
      }

      transaction.set(
        requestRef,
        {
          status: accept ? "accepted" : "declined",
          respondedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });

    return { overview: await buildSocialOverview(context) };
  },
);

exports.sendBossPullGift = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const context = await loadSocialContext(request);
    const friendUid = sanitizeString(
      request.data?.friendUid,
      "",
      SOCIAL_LIMITS.maxTargetLength,
    );
    if (!friendUid || friendUid === context.auth.uid) {
      throw new HttpsError("invalid-argument", "Friend uid is required.");
    }
    const pairKey = socialPairKey(context.auth.uid, friendUid);
    const resetKey = easternDailyResetKey();
    const giftRef = dailyBossGiftRef(resetKey, context.auth.uid, friendUid);

    await db.runTransaction(async (transaction) => {
      const friendLink = await transaction.get(
        db.collection(FRIEND_LINK_COLLECTION).doc(pairKey),
      );
      if (!friendLink.exists) {
        throw new HttpsError(
          "failed-precondition",
          "Apex Scan gifts can only be sent to friends.",
        );
      }
      const giftSnap = await transaction.get(giftRef);
      if (giftSnap.exists) {
        throw new HttpsError(
          "already-exists",
          "You already sent this friend an Apex Scan gift for today's reset.",
        );
      }
      transaction.set(giftRef, {
        resetKey,
        fromUid: context.auth.uid,
        toUid: friendUid,
        pairKey,
        amount: SOCIAL_LIMITS.bossPullGiftAmount,
        sentAt: FieldValue.serverTimestamp(),
        claimedAt: null,
      });
    });

    return { overview: await buildSocialOverview(context) };
  },
);

exports.sendAllBossPullGifts = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const context = await loadSocialContext(request);
    const uid = context.auth.uid;
    const resetKey = easternDailyResetKey();
    const friendUids = await loadFriendUids(uid);

    const sentCount = await db.runTransaction(async (transaction) => {
      const giftRefs = friendUids.map((friendUid) =>
        dailyBossGiftRef(resetKey, uid, friendUid),
      );
      const pairRefs = friendUids.map((friendUid) =>
        db.collection(FRIEND_LINK_COLLECTION).doc(socialPairKey(uid, friendUid)),
      );
      const [giftSnaps, pairSnaps] = await Promise.all([
        Promise.all(giftRefs.map((ref) => transaction.get(ref))),
        Promise.all(pairRefs.map((ref) => transaction.get(ref))),
      ]);

      let count = 0;
      giftSnaps.forEach((giftSnap, index) => {
        const friendUid = friendUids[index];
        if (giftSnap.exists || !pairSnaps[index].exists) {
          return;
        }
        transaction.set(giftRefs[index], {
          resetKey,
          fromUid: uid,
          toUid: friendUid,
          pairKey: socialPairKey(uid, friendUid),
          amount: SOCIAL_LIMITS.bossPullGiftAmount,
          sentAt: FieldValue.serverTimestamp(),
          claimedAt: null,
        });
        count += 1;
      });
      return count;
    });

    return {
      sentCount,
      skippedCount: Math.max(0, friendUids.length - sentCount),
      message:
        sentCount > 0
          ? `Sent ${sentCount} Apex Scan gift${sentCount === 1 ? "" : "s"}.`
          : "No Apex Scan gifts were ready to send.",
      overview: await buildSocialOverview(context),
    };
  },
);

exports.claimBossPullGift = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const context = await loadSocialContext(request);
    const fromUid = sanitizeString(
      request.data?.fromUid,
      "",
      SOCIAL_LIMITS.maxTargetLength,
    );
    if (!fromUid || fromUid === context.auth.uid) {
      throw new HttpsError("invalid-argument", "Gift sender uid is required.");
    }
    const resetKey = easternDailyResetKey();
    const giftRef = dailyBossGiftRef(resetKey, fromUid, context.auth.uid);
    let granted = 0;

    await db.runTransaction(async (transaction) => {
      const giftSnap = await transaction.get(giftRef);
      if (!giftSnap.exists) {
        throw new HttpsError("not-found", "No Apex Scan gift is waiting.");
      }
      const giftData = giftSnap.data() || {};
      if (giftData.toUid !== context.auth.uid) {
        throw new HttpsError(
          "permission-denied",
          "Only the recipient can claim this Apex Scan gift.",
        );
      }
      if (giftData.claimedAt) {
        throw new HttpsError(
          "failed-precondition",
          "This Apex Scan gift has already been claimed.",
        );
      }
      granted = clampInt(
        giftData.amount,
        1,
        SOCIAL_LIMITS.bossPullGiftAmount,
        SOCIAL_LIMITS.bossPullGiftAmount,
      );
      transaction.set(
        giftRef,
        {
          claimedAt: FieldValue.serverTimestamp(),
          claimedAmount: granted,
        },
        { merge: true },
      );
    });

    return {
      bossTicketsGranted: granted,
      message: `Apex Scan gift claimed: +${granted} Apex Scan${
        granted === 1 ? "" : "s"
      }.`,
      overview: await buildSocialOverview(context),
    };
  },
);

exports.claimAllBossPullGifts = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const context = await loadSocialContext(request);
    const uid = context.auth.uid;
    const resetKey = easternDailyResetKey();
    const friendUids = await loadFriendUids(uid);

    const claim = await db.runTransaction(async (transaction) => {
      const giftRefs = friendUids.map((friendUid) =>
        dailyBossGiftRef(resetKey, friendUid, uid),
      );
      const pairRefs = friendUids.map((friendUid) =>
        db.collection(FRIEND_LINK_COLLECTION).doc(socialPairKey(uid, friendUid)),
      );
      const [giftSnaps, pairSnaps] = await Promise.all([
        Promise.all(giftRefs.map((ref) => transaction.get(ref))),
        Promise.all(pairRefs.map((ref) => transaction.get(ref))),
      ]);

      let granted = 0;
      let claimedCount = 0;
      giftSnaps.forEach((giftSnap, index) => {
        if (!giftSnap.exists || !pairSnaps[index].exists) {
          return;
        }
        const giftData = giftSnap.data() || {};
        if (giftData.toUid !== uid || giftData.claimedAt) {
          return;
        }
        const amount = clampInt(
          giftData.amount,
          1,
          SOCIAL_LIMITS.bossPullGiftAmount,
          SOCIAL_LIMITS.bossPullGiftAmount,
        );
        transaction.set(
          giftRefs[index],
          {
            claimedAt: FieldValue.serverTimestamp(),
            claimedAmount: amount,
          },
          { merge: true },
        );
        granted += amount;
        claimedCount += 1;
      });
      return { granted, claimedCount };
    });

    return {
      bossTicketsGranted: claim.granted,
      claimedCount: claim.claimedCount,
      message:
        claim.granted > 0
          ? `Apex Scan gifts claimed: +${claim.granted} Apex Scan${
              claim.granted === 1 ? "" : "s"
            }.`
          : "No Apex Scan gifts were ready to claim.",
      overview: await buildSocialOverview(context),
    };
  },
);

exports.syncIdleSnapshot = onCall({ enforceAppCheck: false }, async (request) => {
  const auth = requireAuth(request);
  const manifest = await loadManifest();
  requireAppCheckIfNeeded(request, manifest);

  const clientSnapshot = normalizeSnapshot(request.data?.snapshot);
  const clientVersion = sanitizeVersion(request.data?.clientVersion);
  const clientBuildNumber = sanitizeBuildNumber(request.data?.clientBuildNumber);
  const platform = sanitizePlatform(request.data?.platform);
  const versionGate = computeVersionGate(clientVersion, clientBuildNumber, manifest);
  const profileRef = db.collection(PROFILE_COLLECTION).doc(auth.uid);
  const serverNow = new Date();
  const existingProfileSnap = await profileRef.get();
  if (!existingProfileSnap.exists) {
    throw new HttpsError(
      "failed-precondition",
      "Player profile does not exist yet. Bootstrap first.",
    );
  }
  requireActiveSession(existingProfileSnap.data() || {}, request);
  const saveRef = playerSaveRef(auth.uid);
  const saveSnap = await saveRef.get();
  const savePayload = normalizeObject(saveSnap.data()?.payload);
  const authoritativeSnapshot = buildAuthoritativeIdleSnapshot({
    clientSnapshot,
    savePayload,
  });

  await profileRef.set(
    {
      idleSnapshot: authoritativeSnapshot,
      lastActiveAt: FieldValue.serverTimestamp(),
      lastSnapshotSyncAt: FieldValue.serverTimestamp(),
      lastHeartbeatAt: FieldValue.serverTimestamp(),
      clientVersion,
      clientBuildNumber,
      lastPlatform: platform,
      lastVersionGate: versionGate,
    },
    { merge: true },
  );

  const profileSnap = await profileRef.get();
  const profileData = profileSnap.data() || {};
  const saveData = saveSnap.data() || {};

  return {
    accepted: true,
    manifest,
    profile: buildProfileResponse(
      profileData,
      auth,
      profileData.playerId || "LUMI-0000-0000",
    ),
    ...buildServerClockPayload(serverNow),
    sessionId: profileData.activeSessionId || null,
    versionGate,
    cloudSaveRevision: saveSnap.exists
      ? clampInt(saveData.revision, 0, PLAYER_SAVE_LIMITS.maxRevision, 0)
      : 0,
    offlineProgressCapSeconds: manifest.offlineProgressCapSeconds,
  };
});

exports.claimOfflineProgress = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const auth = requireAuth(request);
    const manifest = await loadManifest();
    requireAppCheckIfNeeded(request, manifest);

    const profileRef = db.collection(PROFILE_COLLECTION).doc(auth.uid);
    const saveRef = playerSaveRef(auth.uid);

    const claimResult = await db.runTransaction(async (transaction) => {
      const snap = await transaction.get(profileRef);
      const saveSnap = await transaction.get(saveRef);
      if (!snap.exists) {
        throw new HttpsError(
          "failed-precondition",
          "Player profile does not exist yet. Bootstrap first.",
        );
      }

      const data = snap.data() || {};
      requireActiveSession(data, request);
      const savePayload = saveSnap.exists
        ? normalizeObject(saveSnap.data()?.payload)
        : null;
      const idleSnapshot = savePayload
        ? buildIdleSnapshotFromSavePayload(savePayload)
        : null;
      if (!idleSnapshot) {
        return {
          secondsClaimed: 0,
          lumensGranted: 0,
          fluxGranted: 0,
          enemyTicketsGranted: 0,
          killsGranted: 0,
          serverValidated: true,
          claimIssuedAt: new Date().toISOString(),
          statusMessage: "No idle snapshot is stored yet.",
        };
      }

      const lastActiveAt = toMillis(data.lastActiveAt);
      if (!lastActiveAt) {
        transaction.set(
          profileRef,
          {
            idleSnapshot,
            lastActiveAt: FieldValue.serverTimestamp(),
            lastSnapshotSyncAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        return {
          secondsClaimed: 0,
          lumensGranted: 0,
          fluxGranted: 0,
          enemyTicketsGranted: 0,
          killsGranted: 0,
          serverValidated: true,
          claimIssuedAt: new Date().toISOString(),
          statusMessage: "Idle timer initialized. Come back later for rewards.",
        };
      }

      const nowMillis = Date.now();
      const elapsedSeconds = Math.max(
        0,
        Math.floor((nowMillis - lastActiveAt) / 1000),
      );
      const premiumMembershipActive = hasPremiumMembership(data);
      const freeCapSeconds = clampInt(
        manifest.offlineProgressCapSeconds,
        0,
        365 * 24 * 60 * 60,
        DEFAULT_MANIFEST.offlineProgressCapSeconds,
      );
      const secondsClaimed = premiumMembershipActive
        ? elapsedSeconds
        : Math.min(elapsedSeconds, freeCapSeconds);

      const lumensGranted = Math.floor(
        clampNumber(
          idleSnapshot.passiveLumensPerHour,
          0,
          SNAPSHOT_LIMITS.passiveLumensPerHour,
        ) * (secondsClaimed / 3600),
      );
      const fluxGranted = Math.floor(
        clampNumber(idleSnapshot.fluxPerHour, 0, SNAPSHOT_LIMITS.fluxPerHour) *
          (secondsClaimed / 3600),
      );
      const enemyTicketsGranted = Math.floor(
        clampNumber(
          idleSnapshot.enemyTicketsPerHour,
          0,
          SNAPSHOT_LIMITS.enemyTicketsPerHour,
        ) * (secondsClaimed / 3600),
      );
      const killsGranted = Math.floor(
        clampNumber(idleSnapshot.killsPerHour, 0, SNAPSHOT_LIMITS.killsPerHour) *
          (secondsClaimed / 3600),
      );

      transaction.set(
        profileRef,
        {
          lastActiveAt: FieldValue.serverTimestamp(),
          lastIdleClaimAt: FieldValue.serverTimestamp(),
          idleSnapshot,
          lastSnapshotSyncAt: FieldValue.serverTimestamp(),
          lastIdleClaimResult: {
            secondsClaimed,
            lumensGranted,
            fluxGranted,
            enemyTicketsGranted,
            killsGranted,
            claimedAt: Timestamp.now(),
          },
        },
        { merge: true },
      );

      return {
        secondsClaimed,
        lumensGranted,
        fluxGranted,
        enemyTicketsGranted,
        killsGranted,
        serverValidated: true,
        claimIssuedAt: new Date(nowMillis).toISOString(),
        statusMessage: buildOfflineClaimStatusMessage({
          elapsedSeconds,
          secondsClaimed,
          freeCapSeconds,
          premiumMembershipActive,
        }),
      };
    });

    return claimResult;
  },
);

exports.getPlayerSave = onCall({ enforceAppCheck: false }, async (request) => {
  const auth = requireAuth(request);
  const manifest = await loadManifest();
  requireAppCheckIfNeeded(request, manifest);

  const saveSnap = await playerSaveRef(auth.uid).get();
  if (!saveSnap.exists) {
    return { save: null, recoverable: isRecoverableAuth(auth) };
  }

  return {
    save: buildPlayerSaveResponse(saveSnap.data() || {}),
    recoverable: isRecoverableAuth(auth),
  };
});

exports.savePlayerSave = onCall({ enforceAppCheck: false }, async (request) => {
  const auth = requireAuth(request);
  const manifest = await loadManifest();
  requireAppCheckIfNeeded(request, manifest);

  const schemaVersion = Number.parseInt(request.data?.schemaVersion, 10);
  if (schemaVersion !== PLAYER_SAVE_SCHEMA_VERSION) {
    throw new HttpsError("invalid-argument", "Unsupported save schema version.");
  }
  const clientVersion = request.data?.clientVersion === undefined
    ? null
    : sanitizeVersion(request.data?.clientVersion);
  const clientBuildNumber = request.data?.clientBuildNumber === undefined
    ? null
    : sanitizeBuildNumber(request.data?.clientBuildNumber);
  const versionGate = clientVersion
    ? computeVersionGate(clientVersion, clientBuildNumber, manifest)
    : null;

  const rawPayload = request.data?.payload;
  rejectInvalidRawSavePayload(rawPayload, auth);
  const payload = sanitizePlayerSavePayload(rawPayload);
  const hasBaseRevision = request.data?.baseRevision !== undefined &&
    request.data?.baseRevision !== null;
  const baseRevision = hasBaseRevision
    ? clampInt(request.data.baseRevision, 0, PLAYER_SAVE_LIMITS.maxRevision, 0)
    : null;
  const profileRef = db.collection(PROFILE_COLLECTION).doc(auth.uid);
  const publicRef = db.collection(PUBLIC_PROFILE_COLLECTION).doc(auth.uid);
  const saveRef = playerSaveRef(auth.uid);

  await db.runTransaction(async (transaction) => {
    const profileSnap = await transaction.get(profileRef);
    if (!profileSnap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "Player profile does not exist yet. Bootstrap first.",
      );
    }
    const profileData = profileSnap.data() || {};

    const saveSnap = await transaction.get(saveRef);
    requireActiveSession(profileData, request);
    const previousPayload = saveSnap.exists
      ? normalizeObject(saveSnap.data()?.payload)
      : null;
    const existingRevision = saveSnap.exists
      ? clampInt(
          saveSnap.data()?.revision,
          0,
          PLAYER_SAVE_LIMITS.maxRevision,
          0,
        )
      : 0;
    if (baseRevision !== null && existingRevision !== baseRevision) {
      throw new HttpsError(
        "aborted",
        "Cloud save has changed on another device. Reload before saving.",
      );
    }
    rejectImplausibleSaveDelta({
      previousPayload,
      nextPayload: payload,
      previousSaveData: saveSnap.exists ? saveSnap.data() || {} : null,
    });

    const nextRevision = Math.min(
      existingRevision + 1,
      PLAYER_SAVE_LIMITS.maxRevision,
    );
    const integrity = buildSaveIntegritySummary({
      auth,
      rawPayload,
      payload,
      previousPayload,
    });
    const publishSocialPublicProfile =
      shouldPublishSocialPublicProfile(profileData);
    transaction.set(saveRef, {
      schemaVersion: PLAYER_SAVE_SCHEMA_VERSION,
      revision: nextRevision,
      payload,
      updatedAt: FieldValue.serverTimestamp(),
      authProvider: auth.token?.firebase?.sign_in_provider || "unknown",
      recoverable: isRecoverableAuth(auth),
      integrity,
    });
    transaction.set(profileRef, {
      lastSaveAt: FieldValue.serverTimestamp(),
      lastSaveRevision: nextRevision,
      lastSaveSchemaVersion: PLAYER_SAVE_SCHEMA_VERSION,
      lastSaveAuthProvider:
        auth.token?.firebase?.sign_in_provider || "unknown",
      lastSaveRecoverable: isRecoverableAuth(auth),
      lastSaveIntegrityRiskScore: integrity.riskScore,
      lastSaveIntegrityFlags: integrity.flags,
      idleSnapshot: buildIdleSnapshotFromSavePayload(payload),
      lastActiveAt: FieldValue.serverTimestamp(),
      lastSnapshotSyncAt: FieldValue.serverTimestamp(),
      lastHeartbeatAt: FieldValue.serverTimestamp(),
      ...(publishSocialPublicProfile
        ? { lastPublicProfilePublishedAt: FieldValue.serverTimestamp() }
        : {}),
      ...(clientVersion
        ? {
            clientVersion,
            clientBuildNumber,
            lastVersionGate: versionGate,
          }
        : {}),
    }, { merge: true });
    if (publishSocialPublicProfile) {
      transaction.set(
        publicRef,
        buildSocialPublicProfileUpdate({
          auth,
          rawPayload,
          payload,
          profileData,
        }),
        { merge: true },
      );
    }
    if (integrity.flags.length > 0) {
      transaction.set(profileRef.collection("securityEvents").doc(), {
        type: "cloudSaveIntegrity",
        riskScore: integrity.riskScore,
        flags: integrity.flags,
        revision: nextRevision,
        authProvider: auth.token?.firebase?.sign_in_provider || "unknown",
        createdAt: FieldValue.serverTimestamp(),
      });
    }
  });

  const updatedSnap = await saveRef.get();
  return {
    save: buildPlayerSaveResponse(updatedSnap.data() || {}),
    recoverable: isRecoverableAuth(auth),
  };
});

exports.resetPlayerSave = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const auth = requireAuth(request);
    const manifest = await loadManifest();
    requireAppCheckIfNeeded(request, manifest);

    const profileRef = db.collection(PROFILE_COLLECTION).doc(auth.uid);
    const saveRef = playerSaveRef(auth.uid);
    await db.runTransaction(async (transaction) => {
      const profileSnap = await transaction.get(profileRef);
      if (!profileSnap.exists) {
        throw new HttpsError(
          "failed-precondition",
          "Player profile does not exist yet. Bootstrap first.",
        );
      }
      requireActiveSession(profileSnap.data() || {}, request);
      transaction.delete(saveRef);
      transaction.set(
        profileRef,
        {
          idleSnapshot: null,
          lastActiveAt: FieldValue.serverTimestamp(),
          lastIdleClaimAt: null,
          lastIdleClaimResult: FieldValue.delete(),
          lastSaveAt: FieldValue.serverTimestamp(),
          lastSaveRevision: FieldValue.delete(),
          lastSaveSchemaVersion: FieldValue.delete(),
          lastSaveAuthProvider: FieldValue.delete(),
          lastSaveRecoverable: FieldValue.delete(),
          lastSaveIntegrityRiskScore: FieldValue.delete(),
          lastSaveIntegrityFlags: FieldValue.delete(),
        },
        { merge: true },
      );
    });

    return { reset: true, recoverable: isRecoverableAuth(auth) };
  },
);

exports.getTournamentOverview = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const context = await loadTournamentContext(request);
    return buildTournamentOverview(context);
  },
);

exports.joinTournamentQueue = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const context = await loadTournamentContext(request);
    const mode = sanitizeTournamentMode(request.data?.mode);
    const modeWindow = ensureTournamentModeOpen(mode);
    const snapshot = normalizeTournamentPlayerSnapshot(request.data?.snapshot);
    const seasonKey = buildTournamentSeasonKey(
      context.manifest.seasonKey,
      mode,
      modeWindow,
    );
    const entryRef = tournamentEntryRef(
      seasonKey,
      mode,
      context.auth.uid,
    );
    const grouping = buildTournamentGrouping({
      mode,
      seasonKey,
      snapshot,
      globalRating: sanitizeTournamentRating(
        context.profileData.globalTournamentRating,
      ),
    });

    await db.runTransaction(async (transaction) => {
      const existingSnap = await transaction.get(entryRef);
      const existingData = existingSnap.data() || {};
      const bestScore = clampInt(
        existingData.bestScore,
        0,
        TOURNAMENT_LIMITS.submittedScore,
        0,
      );

      touchTournamentSeason(
        transaction,
        seasonKey,
        modeWindow,
      );

      transaction.set(
        entryRef,
        {
          mode,
          playerId: sanitizeString(
            context.profileData.playerId,
            "Pilot",
          ),
          displayName: resolveDisplayName(context.profileData, context.auth),
          joined: true,
          joinedAt: existingData.joinedAt || FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          bestScore,
          rewardReady: false,
          globalRating: sanitizeTournamentRating(
            context.profileData.globalTournamentRating,
          ),
          groupId: grouping.groupId,
          matchBucketLabel: grouping.matchBucketLabel,
          seedPowerIndex: snapshot.towerPowerIndex,
          lastSnapshot: snapshot,
        },
        { merge: true },
      );

      transaction.set(
        context.profileRef,
        {
          lastTournamentSeenAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });

    return buildTournamentOverview(context);
  },
);

exports.submitTournamentRun = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const context = await loadTournamentContext(request);
    const mode = sanitizeTournamentMode(request.data?.mode);
    const modeWindow = ensureTournamentModeOpen(mode);
    const snapshot = normalizeTournamentPlayerSnapshot(request.data?.snapshot);
    const submittedScore = sanitizeTournamentSubmittedScore(
      mode,
      request.data?.score,
      snapshot,
    );
    if (submittedScore <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "A positive tournament score is required.",
      );
    }
    const seasonKey = buildTournamentSeasonKey(
      context.manifest.seasonKey,
      mode,
      modeWindow,
    );

    const entryRef = tournamentEntryRef(
      seasonKey,
      mode,
      context.auth.uid,
    );
    const currentRating = sanitizeTournamentRating(
      context.profileData.globalTournamentRating,
    );

    let nextRating = currentRating;

    await db.runTransaction(async (transaction) => {
      const existingSnap = await transaction.get(entryRef);
      if (!existingSnap.exists || existingSnap.data()?.joined !== true) {
        throw new HttpsError(
          "failed-precondition",
          "Join the tournament queue before submitting a run.",
        );
      }

      const existingData = existingSnap.data() || {};
      const previousBestScore = clampInt(
        existingData.bestScore,
        0,
        TOURNAMENT_LIMITS.submittedScore,
        0,
      );
      const nextBestScore = Math.max(previousBestScore, submittedScore);

      nextRating =
        mode === "arenaFlow"
          ? computeNextTournamentRating({
              currentRating,
              submittedScore,
              previousBestScore,
              snapshot,
            })
          : currentRating;

      const grouping = buildTournamentGrouping({
        mode,
        seasonKey,
        snapshot,
        globalRating: nextRating,
      });

      touchTournamentSeason(
        transaction,
        seasonKey,
        modeWindow,
      );

      transaction.set(
        entryRef,
        {
          mode,
          playerId: sanitizeString(
            context.profileData.playerId,
            "Pilot",
          ),
          displayName: resolveDisplayName(context.profileData, context.auth),
          joined: true,
          updatedAt: FieldValue.serverTimestamp(),
          lastSubmittedAt: FieldValue.serverTimestamp(),
          lastSubmittedScore: submittedScore,
          bestScore: nextBestScore,
          rewardReady: false,
          rewardClaimed: false,
          globalRating: nextRating,
          groupId: grouping.groupId,
          matchBucketLabel: grouping.matchBucketLabel,
          seedPowerIndex: snapshot.towerPowerIndex,
          lastSnapshot: snapshot,
        },
        { merge: true },
      );

      transaction.set(
        context.profileRef,
        {
          globalTournamentRating: nextRating,
          lastTournamentPlayedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });

    context.profileData = {
      ...context.profileData,
      globalTournamentRating: nextRating,
    };

    return buildTournamentOverview(context);
  },
);

exports.claimTournamentReward = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const context = await loadTournamentContext(request);
    const mode = sanitizeTournamentMode(request.data?.mode);
    const previousWindow = computePreviousTournamentWindowForMode(mode);
    const rewardSeasonKey = buildTournamentSeasonKey(
      context.manifest.seasonKey,
      mode,
      previousWindow,
    );
    const entryRef = tournamentEntryRef(
      rewardSeasonKey,
      mode,
      context.auth.uid,
    );
    const entrySnap = await entryRef.get();
    const entryData = entrySnap.data() || {};
    const bestScore = clampInt(
      entryData.bestScore,
      0,
      TOURNAMENT_LIMITS.submittedScore,
      0,
    );
    if (!entrySnap.exists || bestScore <= 0 || entryData.rewardClaimed) {
      throw new HttpsError(
        "failed-precondition",
        "No closed-window tournament reward is ready for this mode.",
      );
    }
    const grouping = buildTournamentGrouping({
      mode,
      seasonKey: rewardSeasonKey,
      snapshot: entryData.lastSnapshot,
      globalRating: sanitizeTournamentRating(
        entryData.globalRating ?? context.profileData.globalTournamentRating,
      ),
    });
    const rewardRank = await computeTournamentRank({
      mode,
      seasonKey: rewardSeasonKey,
      score: bestScore,
      groupId: grouping.groupId,
      globalRating: sanitizeTournamentRating(
        entryData.globalRating ?? context.profileData.globalTournamentRating,
      ),
    });
    const reward = buildTournamentReward(
      mode,
      rewardRank,
      bestScore,
    );
    const boostEndsAt = Timestamp.fromMillis(
      Date.now() + reward.experienceBuffHours * 60 * 60 * 1000,
    );

    await db.runTransaction(async (transaction) => {
      const entrySnap = await transaction.get(entryRef);
      if (!entrySnap.exists) {
        throw new HttpsError(
          "failed-precondition",
          "Join and submit a run before claiming a reward.",
        );
      }

      const entryData = entrySnap.data() || {};
      const transactionBestScore = clampInt(
        entryData.bestScore,
        0,
        TOURNAMENT_LIMITS.submittedScore,
        0,
      );
      if (transactionBestScore <= 0 || entryData.rewardClaimed) {
        throw new HttpsError(
          "failed-precondition",
          "This reward has already been claimed.",
        );
      }

      transaction.set(
        entryRef,
        {
          rewardReady: false,
          rewardClaimed: true,
          rewardClaimedAt: FieldValue.serverTimestamp(),
          lastClaimedReward: {
            seasonKey: rewardSeasonKey,
            rank: rewardRank || TOURNAMENT_MODE_CONFIGS[mode].capacity,
            bestScore,
            reward,
          },
        },
        { merge: true },
      );

      transaction.set(
        context.profileRef,
        {
          activeTournamentExpMultiplier: reward.experienceMultiplier,
          activeTournamentBoostEndsAt: boostEndsAt,
          lastTournamentRewardClaimAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });

    context.profileData = {
      ...context.profileData,
      activeTournamentExpMultiplier: reward.experienceMultiplier,
      activeTournamentBoostEndsAt: boostEndsAt,
    };

    return {
      reward,
      overview: await buildTournamentOverview(context),
    };
  },
);

async function loadSocialContext(request) {
  const auth = requireAuth(request);
  const manifest = await loadManifest();
  requireAppCheckIfNeeded(request, manifest);

  const profileRef = db.collection(PROFILE_COLLECTION).doc(auth.uid);
  const profileSnap = await profileRef.get();
  if (!profileSnap.exists) {
    throw new HttpsError(
      "failed-precondition",
      "Player profile does not exist yet. Bootstrap first.",
    );
  }

  return {
    auth,
    manifest,
    profileRef,
    profileData: profileSnap.data() || {},
  };
}

async function loadFriendUids(uid) {
  const friendLinkSnap = await db
    .collection(FRIEND_LINK_COLLECTION)
    .where("uids", "array-contains", uid)
    .get();
  return Array.from(
    new Set(
      friendLinkSnap.docs
        .flatMap((doc) => sanitizeStringList(doc.data()?.uids, 2))
        .filter((friendUid) => friendUid && friendUid !== uid),
    ),
  ).slice(0, SOCIAL_LIMITS.maxFriends);
}

async function buildSocialOverview(context) {
  const uid = context.auth.uid;
  const [
    mentorLinkSnap,
    directLinkSnap,
    incomingMentorInviteSnap,
    outgoingMentorInviteSnap,
    incomingFriendRequestSnap,
    outgoingFriendRequestSnap,
    friendLinkSnap,
  ] = await Promise.all([
    db.collection(MENTOR_LINK_COLLECTION).doc(uid).get(),
    db
      .collection(MENTOR_LINK_COLLECTION)
      .where("mentorUid", "==", uid)
      .limit(SOCIAL_LIMITS.maxOverviewMentees)
      .get(),
    db.collection(MENTOR_INVITE_COLLECTION).where("menteeUid", "==", uid).get(),
    db.collection(MENTOR_INVITE_COLLECTION).where("mentorUid", "==", uid).get(),
    db.collection(FRIEND_REQUEST_COLLECTION).where("targetUid", "==", uid).get(),
    db.collection(FRIEND_REQUEST_COLLECTION).where("fromUid", "==", uid).get(),
    db.collection(FRIEND_LINK_COLLECTION).where("uids", "array-contains", uid).get(),
  ]);

  const mentorUid = mentorLinkSnap.exists
    ? sanitizeString(mentorLinkSnap.data()?.mentorUid, "")
    : null;
  const directLinks = directLinkSnap.docs.map((doc) => ({
    id: doc.id,
    ...(doc.data() || {}),
  }));
  const directUids = directLinks.map((link) => link.menteeUid).filter(Boolean);
  const grandLinks = await loadGrandMenteeLinks(directUids);
  const grandUids = grandLinks.map((link) => link.menteeUid).filter(Boolean);
  const friendUids = friendLinkSnap.docs
    .flatMap((doc) => sanitizeStringList(doc.data()?.uids, 2))
    .filter((friendUid) => friendUid && friendUid !== uid);

  const pendingInvites = [
    ...incomingMentorInviteSnap.docs
      .map((doc) => ({ id: doc.id, kind: "mentor", direction: "incoming", data: doc.data() || {} }))
      .filter((invite) => invite.data.status === "pending"),
    ...outgoingMentorInviteSnap.docs
      .map((doc) => ({ id: doc.id, kind: "mentor", direction: "outgoing", data: doc.data() || {} }))
      .filter((invite) => invite.data.status === "pending"),
    ...incomingFriendRequestSnap.docs
      .map((doc) => ({ id: doc.id, kind: "friend", direction: "incoming", data: doc.data() || {} }))
      .filter((invite) => invite.data.status === "pending"),
    ...outgoingFriendRequestSnap.docs
      .map((doc) => ({ id: doc.id, kind: "friend", direction: "outgoing", data: doc.data() || {} }))
      .filter((invite) => invite.data.status === "pending"),
  ];
  const inviteUids = pendingInvites.flatMap((invite) => [
    invite.data.mentorUid || invite.data.fromUid,
    invite.data.menteeUid || invite.data.targetUid,
  ]);

  const publicProfiles = await fetchPublicProfileMap([
    uid,
    mentorUid,
    ...directUids,
    ...grandUids,
    ...friendUids,
    ...inviteUids,
  ]);
  const selfProfile = publicProfiles.get(uid);
  const selfTowerStrength = clampInt(
    selfProfile?.towerStrength,
    0,
    PLAYER_SAVE_LIMITS.maxTowerStrength,
    0,
  );
  const [
    strongerTowerStrengthSnap,
    rankedTowerStrengthSnap,
    globalTowerStrengthLeaderboardSnap,
  ] = await Promise.all([
    selfTowerStrength > 0
      ? db
          .collection(PUBLIC_PROFILE_COLLECTION)
          .where("towerStrength", ">", selfTowerStrength)
          .count()
          .get()
      : Promise.resolve(null),
    db
      .collection(PUBLIC_PROFILE_COLLECTION)
      .where("towerStrength", ">", 0)
      .count()
      .get(),
    db
      .collection(PUBLIC_PROFILE_COLLECTION)
      .where("towerStrength", ">", 0)
      .orderBy("towerStrength", "desc")
      .limit(SOCIAL_LIMITS.globalLeaderboardLimit)
      .get(),
  ]);
  const towerStrengthRank =
    selfTowerStrength > 0
      ? strongerTowerStrengthSnap.data().count + 1
      : null;
  const towerStrengthRankedPlayers =
    rankedTowerStrengthSnap?.data().count || 0;
  const globalTowerStrengthLeaderboard =
    globalTowerStrengthLeaderboardSnap.docs.map((doc, index) =>
      buildSocialPlayerResponse(doc.id, doc.data() || {}, {
        towerStrengthRank: index + 1,
        towerStrengthRankedPlayers,
      }),
    );

  const self = buildSocialPlayerResponse(uid, selfProfile, {
    mentorUid,
    withinLevelBand: true,
    bonusActive: true,
    towerStrengthRank,
    towerStrengthRankedPlayers,
  });
  const selfMentorshipUnlocked =
    self.level >= SOCIAL_LIMITS.mentorshipUnlockLevel;
  const mentorProfile = publicProfiles.get(mentorUid);
  const mentorLevel = profileLevel(mentorProfile);
  const mentor = mentorUid
    ? buildSocialPlayerResponse(mentorUid, mentorProfile, {
        withinLevelBand:
          selfMentorshipUnlocked &&
          mentorLevel >= SOCIAL_LIMITS.mentorshipUnlockLevel &&
          isWithinMentorBand(self.level, mentorLevel),
      })
    : null;
  const directPlayers = directLinks.map((link) => {
    const menteeLevel = profileLevel(publicProfiles.get(link.menteeUid));
    const player = buildSocialPlayerResponse(
      link.menteeUid,
      publicProfiles.get(link.menteeUid),
      {
        mentorUid: uid,
        withinLevelBand:
          selfMentorshipUnlocked &&
          menteeLevel >= SOCIAL_LIMITS.mentorshipUnlockLevel &&
          isWithinMentorBand(self.level, menteeLevel),
      },
    );
    return player;
  });
  const activeDirectIds = selfMentorshipUnlocked
    ? selectActiveDirectMenteeIds(directPlayers)
    : new Set();
  const directMentees = directPlayers.map((player) => ({
    ...player,
    bonusActive: activeDirectIds.has(player.uid),
  }));
  const directLevelByUid = new Map(
    directMentees.map((player) => [player.uid, player.level]),
  );
  const grandMentees = grandLinks
    .slice(0, SOCIAL_LIMITS.maxOverviewGrandMentees)
    .map((link) => {
      const parentLevel = directLevelByUid.get(link.mentorUid) || 1;
      const grandLevel = profileLevel(publicProfiles.get(link.menteeUid));
      return buildSocialPlayerResponse(
        link.menteeUid,
        publicProfiles.get(link.menteeUid),
        {
          mentorUid: link.mentorUid,
          withinLevelBand:
            selfMentorshipUnlocked &&
            activeDirectIds.has(link.mentorUid) &&
            grandLevel >= SOCIAL_LIMITS.mentorshipUnlockLevel &&
            isWithinMentorBand(parentLevel, grandLevel),
          bonusActive: activeDirectIds.has(link.mentorUid),
        },
      );
    });
  const bonusProfile = computeSocialBonusProfile(directMentees, grandMentees);
  const dailyResetKey = easternDailyResetKey();
  const friendStates = await buildSocialFriendStates({
    uid,
    friendUids: Array.from(new Set(friendUids)).slice(0, SOCIAL_LIMITS.maxFriends),
    publicProfiles,
    dailyResetKey,
  });
  const invites = pendingInvites.map((invite) =>
    buildSocialInviteResponse(invite, publicProfiles),
  );

  return {
    self,
    mentor,
    directMentees,
    grandMentees,
    friends: friendStates,
    invites,
    globalTowerStrengthLeaderboard,
    bonusProfile,
    dailyResetKey,
    nextDailyResetAt: nextEasternMidnight().toISOString(),
    levelBand: SOCIAL_LIMITS.mentorLevelBand,
    activeMenteeBonusLimit: SOCIAL_LIMITS.activeMenteeBonusLimit,
    maxFriends: SOCIAL_LIMITS.maxFriends,
  };
}

async function loadGrandMenteeLinks(directUids) {
  if (directUids.length === 0) {
    return [];
  }
  const chunks = chunkArray(Array.from(new Set(directUids)), 30);
  const snapshots = await Promise.all(
    chunks.map((chunk) =>
      db
        .collection(MENTOR_LINK_COLLECTION)
        .where("mentorUid", "in", chunk)
        .limit(SOCIAL_LIMITS.maxOverviewGrandMentees)
        .get(),
    ),
  );
  return snapshots.flatMap((snapshot) =>
    snapshot.docs.map((doc) => ({ id: doc.id, ...(doc.data() || {}) })),
  );
}

async function fetchPublicProfileMap(uids) {
  const normalized = Array.from(new Set(uids.filter(Boolean)));
  const entries = await Promise.all(
    normalized.map(async (uid) => {
      const snap = await db.collection(PUBLIC_PROFILE_COLLECTION).doc(uid).get();
      return [uid, snap.exists ? snap.data() || {} : {}];
    }),
  );
  return new Map(entries);
}

function buildSocialPlayerResponse(uid, data, options = {}) {
  const safeUid = sanitizeString(uid, "unknown");
  const level = profileLevel(data);
  return {
    uid: safeUid,
    playerId: sanitizeString(data?.playerId, safeUid),
    screenName: sanitizeString(data?.screenName, ""),
    displayName: sanitizeString(
      data?.displayName || data?.screenName || data?.playerId,
      safeUid,
    ),
    level,
    progressToNextLevel: clampNumber(data?.progressToNextLevel, 0, 1, 0),
    performanceScore: clampNumber(data?.performanceScore, 0, 1, 0.12),
    towerStrength: clampInt(
      data?.towerStrength,
      0,
      PLAYER_SAVE_LIMITS.maxTowerStrength,
      0,
    ),
    towerStrengthRank: clampInt(
      options.towerStrengthRank,
      1,
      PLAYER_SAVE_LIMITS.maxCounter,
      null,
    ),
    towerStrengthRankedPlayers: clampInt(
      options.towerStrengthRankedPlayers,
      0,
      PLAYER_SAVE_LIMITS.maxCounter,
      0,
    ),
    sharedRelayFilledPieceCount: clampInt(
      data?.sharedRelayFilledPieceCount,
      0,
      7,
      0,
    ),
    sharedRelayAveragePower: clampNumber(
      data?.sharedRelayAveragePower,
      0,
      1000000,
      0,
    ),
    mentorUid: options.mentorUid || null,
    withinLevelBand: Boolean(options.withinLevelBand),
    bonusActive: Boolean(options.bonusActive),
    lastActiveAt: timestampToIso(data?.lastActiveAt || data?.updatedAt),
  };
}

function buildSocialInviteResponse(invite, publicProfiles) {
  const data = invite.data || {};
  const fromUid = data.mentorUid || data.fromUid;
  const toUid = data.menteeUid || data.targetUid;
  return {
    id: invite.id,
    kind: invite.kind,
    direction: invite.direction,
    fromPlayer: buildSocialPlayerResponse(fromUid, publicProfiles.get(fromUid)),
    toPlayer: buildSocialPlayerResponse(toUid, publicProfiles.get(toUid)),
    createdAt: timestampToIso(data.createdAt),
  };
}

async function buildSocialFriendStates({
  uid,
  friendUids,
  publicProfiles,
  dailyResetKey,
}) {
  return Promise.all(
    friendUids.map(async (friendUid) => {
      const [sentSnap, incomingSnap] = await Promise.all([
        dailyBossGiftRef(dailyResetKey, uid, friendUid).get(),
        dailyBossGiftRef(dailyResetKey, friendUid, uid).get(),
      ]);
      const incomingData = incomingSnap.data() || {};
      return {
        player: buildSocialPlayerResponse(friendUid, publicProfiles.get(friendUid)),
        giftSentToday: sentSnap.exists,
        giftAvailable: incomingSnap.exists && !incomingData.claimedAt,
        giftClaimedToday: incomingSnap.exists && Boolean(incomingData.claimedAt),
        incomingGiftId: incomingSnap.exists ? incomingSnap.id : null,
      };
    }),
  );
}

function selectActiveDirectMenteeIds(directMentees) {
  return new Set(
    directMentees
      .filter(
        (player) =>
          player.level >= SOCIAL_LIMITS.mentorshipUnlockLevel &&
          player.withinLevelBand,
      )
      .sort((left, right) => right.performanceScore - left.performanceScore)
      .slice(0, SOCIAL_LIMITS.activeMenteeBonusLimit)
      .map((player) => player.uid),
  );
}

function computeSocialBonusProfile(directMentees, grandMentees) {
  const activeDirect = directMentees.filter((player) => player.bonusActive);
  const activeGrand = grandMentees.filter(
    (player) => player.bonusActive && player.withinLevelBand,
  );
  const directScore = activeDirect.reduce(
    (sum, player) => sum + player.performanceScore,
    0,
  );
  const grandScore = activeGrand.reduce(
    (sum, player) => sum + player.performanceScore,
    0,
  );
  const directBase = activeDirect.length;
  const grandBase = activeGrand.length;
  const experienceMultiplier = clampNumber(
    1 + directBase * 0.032 + directScore * 0.038 + grandBase * 0.004 + grandScore * 0.007,
    1,
    1.65,
    1,
  );
  const combatMultiplier = clampNumber(
    1 + directBase * 0.011 + directScore * 0.021 + grandBase * 0.0015 + grandScore * 0.0035,
    1,
    1.25,
    1,
  );
  const rewardMultiplier = clampNumber(
    1 + directBase * 0.009 + directScore * 0.018 + grandBase * 0.0012 + grandScore * 0.003,
    1,
    1.2,
    1,
  );

  return {
    experienceMultiplier,
    combatMultiplier,
    rewardMultiplier,
    activeDirectMentees: activeDirect.length,
    activeGrandMentees: activeGrand.length,
    capped:
      experienceMultiplier >= 1.65 ||
      combatMultiplier >= 1.25 ||
      rewardMultiplier >= 1.2,
  };
}

async function resolveTargetUid(rawTarget, selfUid) {
  const target = sanitizeString(rawTarget, "", SOCIAL_LIMITS.maxTargetLength);
  if (!target) {
    throw new HttpsError("invalid-argument", "Target player id is required.");
  }
  if (target === selfUid) {
    throw new HttpsError("invalid-argument", "You cannot target yourself.");
  }

  const directSnap = await db.collection(PUBLIC_PROFILE_COLLECTION).doc(target).get();
  if (directSnap.exists) {
    return target;
  }

  const playerIdSnap = await db
    .collection(PUBLIC_PROFILE_COLLECTION)
    .where("playerId", "==", target)
    .limit(1)
    .get();
  if (!playerIdSnap.empty) {
    const uid = playerIdSnap.docs[0].id;
    if (uid === selfUid) {
      throw new HttpsError("invalid-argument", "You cannot target yourself.");
    }
    return uid;
  }

  const screenNameSnap = await db
    .collection(PUBLIC_PROFILE_COLLECTION)
    .where("screenNameLower", "==", normalizeSearchKey(target))
    .limit(1)
    .get();
  if (!screenNameSnap.empty) {
    const uid = screenNameSnap.docs[0].id;
    if (uid === selfUid) {
      throw new HttpsError("invalid-argument", "You cannot target yourself.");
    }
    return uid;
  }

  throw new HttpsError("not-found", "No player found for that id or screen name.");
}

async function loadPublicProfileData(uid) {
  const snap = await db.collection(PUBLIC_PROFILE_COLLECTION).doc(uid).get();
  return snap.exists ? snap.data() || {} : null;
}

function assertMentorshipUnlocked(profileData) {
  if (profileLevel(profileData) >= SOCIAL_LIMITS.mentorshipUnlockLevel) {
    return;
  }
  throw new HttpsError(
    "failed-precondition",
    `Mentors and mentees unlock at Account Radiance Lv ${SOCIAL_LIMITS.mentorshipUnlockLevel}.`,
  );
}

function shouldPublishSocialPublicProfile(profileData) {
  const lastPublishedAt = toMillis(profileData?.lastPublicProfilePublishedAt);
  if (!lastPublishedAt) {
    return true;
  }
  return Date.now() - lastPublishedAt >=
    SOCIAL_LIMITS.publicProfilePublishIntervalMillis;
}

function buildSocialPublicProfileUpdate({ auth, rawPayload, payload, profileData }) {
  const snapshot = normalizeObject(rawPayload.socialSnapshot);
  const resources = normalizeObject(payload.resources);
  const metrics = normalizeObject(payload.metrics);
  const progressionExperience = Math.max(
    clampInt(resources.experience, 0, PLAYER_SAVE_LIMITS.maxCounter, 0),
    clampInt(resources.kills, 0, PLAYER_SAVE_LIMITS.maxCounter, 0),
  );
  const level = clampInt(
    snapshot.overallLevel,
    1,
    1000000,
    overallLevelForExperience(progressionExperience),
  );
  const totalBattleSeconds = clampNumber(
    snapshot.totalBattleSeconds ?? metrics.totalBattleSeconds,
    0,
    PLAYER_SAVE_LIMITS.maxMetricSeconds,
    0,
  );
  const bossesDefeated = clampInt(
    snapshot.bossesDefeated ?? metrics.totalBossesDefeated,
    0,
    PLAYER_SAVE_LIMITS.maxCounter,
    0,
  );
  const sharedRelayFilledPieceCount = clampInt(
    snapshot.sharedRelayFilledPieceCount,
    0,
    7,
    0,
  );
  const towerStrength = clampInt(
    snapshot.towerStrength,
    0,
    PLAYER_SAVE_LIMITS.maxTowerStrength,
    0,
  );
  const performanceScore = computePublicPerformanceScore({
    level,
    progressToNextLevel: clampNumber(snapshot.progressToNextLevel, 0, 1, 0),
    totalBattleSeconds,
    bossesDefeated,
    totalPullsOpened: clampInt(
      snapshot.totalPullsOpened,
      0,
      PLAYER_SAVE_LIMITS.maxCounter,
      0,
    ),
    sharedRelayFilledPieceCount,
  });
  const screenName = normalizeStoredScreenName(profileData.screenName);
  const playerId = sanitizePlayerId(payload.player.playerId || profileData.playerId);
  return {
    playerId,
    authUid: auth.uid,
    screenName,
    screenNameLower: normalizeSearchKey(screenName),
    displayName: screenName || playerId,
    overallLevel: level,
    progressionExperience,
    progressToNextLevel: clampNumber(snapshot.progressToNextLevel, 0, 1, 0),
    performanceScore,
    towerStrength,
    sharedRelayFilledPieceCount,
    sharedRelayAveragePower: clampNumber(snapshot.sharedRelayAveragePower, 0, 1000000, 0),
    bossesDefeated,
    totalBattleSeconds,
    totalPullsOpened: clampInt(snapshot.totalPullsOpened, 0, PLAYER_SAVE_LIMITS.maxCounter, 0),
    updatedAt: FieldValue.serverTimestamp(),
    lastActiveAt: FieldValue.serverTimestamp(),
    isAnonymous: !isRecoverableAuth(auth),
  };
}

function computePublicPerformanceScore({
  level,
  progressToNextLevel,
  totalBattleSeconds,
  bossesDefeated,
  totalPullsOpened,
  sharedRelayFilledPieceCount,
}) {
  const levelScore = clampNumber((level - 1) / 42, 0, 1, 0);
  const activityScore = clampNumber(totalBattleSeconds / (18 * 60 * 60), 0, 1, 0);
  const bossScore = clampNumber(bossesDefeated / 60, 0, 1, 0);
  const pullScore = clampNumber(totalPullsOpened / 800, 0, 1, 0);
  const relayScore = clampNumber(sharedRelayFilledPieceCount / 7, 0, 1, 0);
  return clampNumber(
    levelScore * 0.32 +
      progressToNextLevel * 0.1 +
      activityScore * 0.18 +
      bossScore * 0.18 +
      pullScore * 0.1 +
      relayScore * 0.12,
    0,
    1,
    0,
  );
}

function profileLevel(data) {
  return clampInt(data?.overallLevel, 1, 1000000, 1);
}

function isWithinMentorBand(leftLevel, rightLevel) {
  return Math.abs(leftLevel - rightLevel) <= SOCIAL_LIMITS.mentorLevelBand;
}

function experienceForOverallLevel(level) {
  let totalExperience = 0;
  for (let targetLevel = 2; targetLevel <= level; targetLevel += 1) {
    totalExperience += experienceGapForOverallLevel(targetLevel);
  }
  return totalExperience;
}

function baseExperienceGapForOverallLevel(level) {
  if (level <= 1) {
    return 0;
  }
  return 40 + 30 * (level - 2);
}

function experienceGapForOverallLevel(level) {
  if (level <= 1) {
    return 0;
  }
  const compoundScale = Math.pow(
    OVERALL_LEVEL_EXPERIENCE_GROWTH,
    Math.max(0, level - 2),
  );
  return Math.max(
    1,
    Math.round(baseExperienceGapForOverallLevel(level) * compoundScale),
  );
}

function overallLevelForExperience(totalExperience) {
  let level = 1;
  let nextLevelExperience = experienceGapForOverallLevel(level + 1);
  while (totalExperience >= nextLevelExperience) {
    level += 1;
    nextLevelExperience += experienceGapForOverallLevel(level + 1);
  }
  return level;
}

async function countFriendsForUidTransaction(transaction, uid) {
  const snap = await transaction.get(
    db.collection(FRIEND_LINK_COLLECTION).where("uids", "array-contains", uid),
  );
  return snap.size;
}

async function assertNoMentorCycle(transaction, mentorUid, menteeUid) {
  let cursor = mentorUid;
  const seen = new Set([menteeUid]);
  for (let depth = 0; depth < 24; depth += 1) {
    if (!cursor) {
      return;
    }
    if (cursor === menteeUid || seen.has(cursor)) {
      throw new HttpsError(
        "failed-precondition",
        "That mentor link would create a cycle.",
      );
    }
    seen.add(cursor);
    const snap = await transaction.get(
      db.collection(MENTOR_LINK_COLLECTION).doc(cursor),
    );
    if (!snap.exists) {
      return;
    }
    cursor = sanitizeString(snap.data()?.mentorUid, "");
  }
  throw new HttpsError(
    "failed-precondition",
    "Mentor chains are capped to prevent runaway loops.",
  );
}

function dailyBossGiftRef(resetKey, fromUid, toUid) {
  return db
    .collection(DAILY_BOSS_GIFT_COLLECTION)
    .doc(`${resetKey}_${fromUid}_${toUid}`);
}

function socialPairKey(leftUid, rightUid) {
  return [leftUid, rightUid].sort().join("_");
}

function easternDailyResetKey(date = new Date()) {
  const parts = timeZoneParts(date, "America/New_York");
  return `${parts.year}-${String(parts.month).padStart(2, "0")}-${String(
    parts.day,
  ).padStart(2, "0")}`;
}

function nextEasternMidnight(now = new Date()) {
  const parts = timeZoneParts(now, "America/New_York");
  const nextDay = new Date(Date.UTC(parts.year, parts.month - 1, parts.day + 1));
  return zonedTimeToUtc({
    year: nextDay.getUTCFullYear(),
    month: nextDay.getUTCMonth() + 1,
    day: nextDay.getUTCDate(),
    hour: 0,
    minute: 0,
    second: 0,
    timeZone: "America/New_York",
  });
}

function zonedTimeToUtc({ year, month, day, hour, minute, second, timeZone }) {
  const target = Date.UTC(year, month - 1, day, hour, minute, second);
  let guess = target;
  for (let index = 0; index < 4; index += 1) {
    const parts = timeZoneParts(new Date(guess), timeZone);
    const rendered = Date.UTC(
      parts.year,
      parts.month - 1,
      parts.day,
      parts.hour,
      parts.minute,
      parts.second,
    );
    guess += target - rendered;
  }
  return new Date(guess);
}

function timeZoneParts(date, timeZone) {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  const lookup = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return {
    year: Number.parseInt(lookup.year, 10),
    month: Number.parseInt(lookup.month, 10),
    day: Number.parseInt(lookup.day, 10),
    hour: Number.parseInt(lookup.hour, 10),
    minute: Number.parseInt(lookup.minute, 10),
    second: Number.parseInt(lookup.second, 10),
  };
}

function createSessionId() {
  return randomUUID();
}

function requireActiveSession(profileData, request) {
  const activeSessionId = sanitizeOptionalString(profileData.activeSessionId);
  const providedSessionId = sanitizeOptionalString(request.data?.sessionId);
  if (!activeSessionId || !providedSessionId || activeSessionId !== providedSessionId) {
    throw new HttpsError(
      "failed-precondition",
      "Session expired. Reconnect to claim server-calculated offline progress.",
    );
  }
}

function buildServerClockPayload(date = new Date()) {
  return {
    serverTime: date.toISOString(),
    serverDayKey: utcDayKey(date),
    serverWeekKey: utcWeekKey(date),
  };
}

function utcDayKey(date = new Date()) {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, "0");
  const day = String(date.getUTCDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function utcWeekKey(date = new Date()) {
  const start = new Date(Date.UTC(
    date.getUTCFullYear(),
    date.getUTCMonth(),
    date.getUTCDate(),
  ));
  const dayOfWeek = start.getUTCDay() === 0 ? 7 : start.getUTCDay();
  start.setUTCDate(start.getUTCDate() - (dayOfWeek - 1));
  return utcDayKey(start);
}

function isDateKeyBeyondAllowedFuture(value) {
  const millis = parseDateKeyMillis(value);
  if (millis === null) {
    return false;
  }
  const now = new Date();
  const todayMillis = Date.UTC(
    now.getUTCFullYear(),
    now.getUTCMonth(),
    now.getUTCDate(),
  );
  const allowedFutureMillis =
    todayMillis +
    SAVE_INTEGRITY_LIMITS.maxFutureDateKeySkewDays * 24 * 60 * 60 * 1000;
  return millis > allowedFutureMillis;
}

function parseDateKeyMillis(value) {
  const match = String(value).match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (!match) {
    return null;
  }
  const year = Number.parseInt(match[1], 10);
  const month = Number.parseInt(match[2], 10);
  const day = Number.parseInt(match[3], 10);
  if (
    !Number.isFinite(year) ||
    !Number.isFinite(month) ||
    !Number.isFinite(day) ||
    month < 1 ||
    month > 12 ||
    day < 1 ||
    day > 31
  ) {
    return null;
  }
  const millis = Date.UTC(year, month - 1, day);
  const parsed = new Date(millis);
  if (
    parsed.getUTCFullYear() !== year ||
    parsed.getUTCMonth() !== month - 1 ||
    parsed.getUTCDate() !== day
  ) {
    return null;
  }
  return millis;
}

function normalizeSearchKey(value) {
  return normalizeScreenNameText(value).toLowerCase();
}

function screenNameReservationRef(screenNameLower) {
  return db
    .collection(SCREEN_NAME_CLAIM_COLLECTION)
    .doc(screenNameReservationId(screenNameLower));
}

function screenNameReservationId(screenNameLower) {
  return Buffer.from(screenNameLower, "utf8").toString("base64url");
}

function sanitizeStringList(value, maxLength) {
  if (!Array.isArray(value)) {
    return [];
  }
  return value
    .slice(0, maxLength)
    .map((item) => sanitizeString(item, "", SOCIAL_LIMITS.maxTargetLength))
    .filter(Boolean);
}

function chunkArray(items, size) {
  const chunks = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}


function sanitizeScreenName(value) {
  const normalized = normalizeScreenNameText(value);
  if (screenNameVisibleLength(normalized) < SCREEN_NAME_LIMITS.min) {
    throw new HttpsError(
      "invalid-argument",
      `Screen names need at least ${SCREEN_NAME_LIMITS.min} visible characters.`,
    );
  }
  if (screenNameLength(normalized) > SCREEN_NAME_LIMITS.max) {
    throw new HttpsError(
      "invalid-argument",
      `Screen names cannot exceed ${SCREEN_NAME_LIMITS.max} characters.`,
    );
  }
  return normalized;
}

function normalizeStoredScreenName(value) {
  const normalized = normalizeScreenNameText(value);
  if (screenNameVisibleLength(normalized) < SCREEN_NAME_LIMITS.min) {
    return "";
  }
  if (screenNameLength(normalized) > SCREEN_NAME_LIMITS.max) {
    return Array.from(normalized).slice(0, SCREEN_NAME_LIMITS.max).join("").trim();
  }
  return normalized;
}

function normalizeScreenNameText(value) {
  return sanitizeString(value, "")
    .replace(/\s+/g, " ")
    .replace(/[^A-Za-z0-9 _-]/g, "")
    .trim();
}

function screenNameLength(value) {
  return Array.from(value).length;
}

function screenNameVisibleLength(value) {
  return Array.from(value.replace(/\s/g, "")).length;
}

function buildProfileResponse(profileData, auth, fallbackPlayerId = "") {
  const activeBoost = normalizeTournamentBoost(profileData);
  return {
    playerId: profileData.playerId || fallbackPlayerId,
    screenName: normalizeStoredScreenName(profileData.screenName) || null,
    authUid: auth.uid,
    isAnonymous: profileData.isAnonymous !== false,
    lastActiveAt: timestampToIso(profileData.lastActiveAt),
    lastIdleClaimAt: timestampToIso(profileData.lastIdleClaimAt),
    globalTournamentRating: sanitizeTournamentRating(
      profileData.globalTournamentRating,
    ),
    activeTournamentExpMultiplier: activeBoost.multiplier,
    activeTournamentBoostEndsAt: activeBoost.endsAt,
    hasPremiumMembership: hasPremiumMembership(profileData),
  };
}

function normalizeObject(value) {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value
    : {};
}

function normalizeArray(value) {
  return Array.isArray(value) ? value : [];
}

function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Anonymous auth is required.");
  }
  return request.auth;
}

function requireAppCheckIfNeeded(request, manifest) {
  if (manifest.appCheckRequired && !request.app) {
    throw new HttpsError(
      "failed-precondition",
      "App Check token is required for this operation.",
    );
  }
}

function sanitizePlayerId(value) {
  const next = sanitizeString(value, "").trim().toUpperCase();
  if (!/^LUMI-[A-Z0-9]{4}-[A-Z0-9]{4}$/.test(next)) {
    throw new HttpsError("invalid-argument", "Invalid player ID format.");
  }
  return next;
}

function sanitizeVersion(value, fallback = "1.0.0") {
  const next = sanitizeString(value, fallback);
  const release = next.split(/[+-]/)[0];
  const cleaned = release
    .split(".")
    .map((part) => {
      const digits = String(part).match(/\d+/)?.[0] || "";
      return digits.length === 0 ? "0" : digits;
    })
    .join(".");
  return cleaned || fallback;
}

function sanitizeBuildNumber(value, fallback = null) {
  const text =
    typeof value === "number" && Number.isFinite(value)
      ? String(Math.trunc(value))
      : sanitizeOptionalString(value);
  if (!text) {
    return fallback;
  }
  const digits = String(text).match(/\d+/)?.[0] || "";
  return digits.length > 0 ? digits : fallback;
}

function resolveManifestVersionGate(
  rawVersion,
  rawBuildNumber,
  defaultVersion,
  defaultBuildNumber,
) {
  const version = sanitizeVersion(rawVersion, defaultVersion);
  const buildNumber = sanitizeBuildNumber(rawBuildNumber);
  const versionCompare = compareVersions(version, defaultVersion);
  if (versionCompare < 0) {
    return { version: defaultVersion, buildNumber: defaultBuildNumber };
  }
  if (versionCompare > 0) {
    return { version, buildNumber };
  }
  if (compareBuildNumbers(buildNumber, defaultBuildNumber) < 0) {
    return { version: defaultVersion, buildNumber: defaultBuildNumber };
  }
  return { version, buildNumber: buildNumber || defaultBuildNumber };
}

function sanitizePlatform(value) {
  const next = sanitizeString(value, "unknown").toLowerCase();
  return ["android", "ios", "web", "macos", "windows", "linux", "fuchsia"].includes(next)
    ? next
    : "unknown";
}

function sanitizeString(value, fallback) {
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : fallback;
}

function sanitizeOptionalString(value) {
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : null;
}

function normalizeSnapshot(value) {
  if (!value || typeof value !== "object") {
    throw new HttpsError("invalid-argument", "Snapshot payload is required.");
  }

  const snapshot = {
    generatedAtMillis: clampInt(value.generatedAtMillis, 0, Date.now(), Date.now()),
    passiveLumensPerHour: clampNumber(
      value.passiveLumensPerHour,
      0,
      SNAPSHOT_LIMITS.passiveLumensPerHour,
    ),
    fluxPerHour: clampNumber(value.fluxPerHour, 0, SNAPSHOT_LIMITS.fluxPerHour),
    enemyTicketsPerHour: clampNumber(
      value.enemyTicketsPerHour,
      0,
      SNAPSHOT_LIMITS.enemyTicketsPerHour,
    ),
    killsPerHour: clampNumber(value.killsPerHour, 0, SNAPSHOT_LIMITS.killsPerHour),
    activeLayerTier: clampInt(value.activeLayerTier, 1, SNAPSHOT_LIMITS.activeLayerTier, 1),
    builtTowerCount: clampInt(
      value.builtTowerCount,
      0,
      SNAPSHOT_LIMITS.builtTowerCount,
      0,
    ),
    prestigeLevel: clampInt(
      value.prestigeLevel,
      0,
      SNAPSHOT_LIMITS.prestigeLevel,
      0,
    ),
  };

  logger.info("Accepted idle snapshot", {
    activeLayerTier: snapshot.activeLayerTier,
    builtTowerCount: snapshot.builtTowerCount,
    killsPerHour: snapshot.killsPerHour,
    prestigeLevel: snapshot.prestigeLevel,
  });

  return snapshot;
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

function roundToTwo(value) {
  return Math.round(value * 100) / 100;
}

function roundToFour(value) {
  return Math.round(value * 10000) / 10000;
}

function computeVersionGate(clientVersion, clientBuildNumber, manifest) {
  if (compareVersions(clientVersion, manifest.minimumSupportedVersion) < 0) {
    return "hardBlock";
  }
  if (
    compareVersions(clientVersion, manifest.minimumSupportedVersion) === 0 &&
    compareBuildNumbers(clientBuildNumber, manifest.minimumSupportedBuildNumber) < 0
  ) {
    return "hardBlock";
  }
  if (compareVersions(clientVersion, manifest.recommendedVersion) < 0) {
    return "softUpdate";
  }
  if (
    compareVersions(clientVersion, manifest.recommendedVersion) === 0 &&
    compareBuildNumbers(clientBuildNumber, manifest.recommendedBuildNumber) < 0
  ) {
    return "softUpdate";
  }
  return "ok";
}

function compareVersions(left, right) {
  const leftParts = tokenizeVersion(left);
  const rightParts = tokenizeVersion(right);
  const count = Math.max(leftParts.length, rightParts.length);

  for (let index = 0; index < count; index += 1) {
    const leftValue = leftParts[index] || 0;
    const rightValue = rightParts[index] || 0;
    if (leftValue !== rightValue) {
      return leftValue < rightValue ? -1 : 1;
    }
  }
  return 0;
}

function compareBuildNumbers(left, right) {
  return buildNumberValue(left) - buildNumberValue(right);
}

function buildNumberValue(value) {
  const digits = String(value || "").match(/\d+/)?.[0] || "0";
  const numeric = Number.parseInt(digits, 10);
  return Number.isFinite(numeric) ? numeric : 0;
}

function tokenizeVersion(value) {
  return String(value).split(/[+-]/)[0]
    .split(".")
    .map((part) => Number.parseInt(String(part).match(/\d+/)?.[0] || "0", 10));
}

function toMillis(value) {
  if (!value) {
    return null;
  }
  if (value instanceof Timestamp) {
    return value.toMillis();
  }
  if (typeof value.toMillis === "function") {
    return value.toMillis();
  }
  if (typeof value === "number") {
    return value;
  }
  if (typeof value === "string") {
    const millis = Date.parse(value);
    return Number.isFinite(millis) ? millis : null;
  }
  return null;
}

function timestampToIso(value) {
  const millis = toMillis(value);
  return millis ? new Date(millis).toISOString() : null;
}
