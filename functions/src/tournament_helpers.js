function createTournamentHelpers({ db, HttpsError, FieldValue, Timestamp, constants, helpers }) {
  const {
    PROFILE_COLLECTION,
    TOURNAMENT_SEASON_COLLECTION,
    TOURNAMENT_MODE_CONFIGS,
    TOURNAMENT_LIMITS,
    DEFAULT_TOURNAMENT_RATING,
    EVEN_ENTRY_TOURNAMENT_LEVEL,
    EVEN_ENTRY_TOURNAMENT_CORE_LEVEL,
    EVEN_ENTRY_TOURNAMENT_BUILT_TOWER_COUNT,
    EVEN_ENTRY_TOURNAMENT_POWER_INDEX,
  } = constants;
  const {
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
  } = helpers;
  const ARENA_FLOW_SYNTHETIC_PLAYER_COUNT = 14;
  const ARENA_FLOW_AFFINITIES = Object.freeze([
    "neutral",
    "ember",
    "flare",
    "solar",
    "verdant",
    "aether",
    "violet",
    "black",
  ]);
  const ARENA_FLOW_SYNTHETIC_NAMES = Object.freeze([
    "Nova Relay",
    "Iris Vector",
    "Pulse Vale",
    "Cinder Lane",
    "Halo Quill",
    "Vega Prism",
    "Sol Anchor",
    "Mira Flux",
    "Kite Aurora",
    "Rook Ember",
    "Luna Circuit",
    "Echo Finch",
    "Aster Beam",
    "Orion Drift",
    "Pearl Static",
    "Nyx Signal",
  ]);

  async function loadTournamentContext(request) {
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

  async function buildTournamentOverview(context) {
    const seasonWindow = computeTournamentOverviewWindow();
    const modeStates = await Promise.all(
      Object.keys(TOURNAMENT_MODE_CONFIGS).map((mode) =>
        buildTournamentModeState(context, mode),
      ),
    );
    const activeBoost = normalizeTournamentBoost(context.profileData);

    return {
      seasonKey: context.manifest.seasonKey,
      seasonLabel: `${context.manifest.seasonKey} weekly bracket`,
      startsAt: seasonWindow.startsAt.toISOString(),
      endsAt: seasonWindow.endsAt.toISOString(),
      globalTournamentRating: sanitizeTournamentRating(
        context.profileData.globalTournamentRating,
      ),
      activeExperienceMultiplier: activeBoost.multiplier,
      activeExperienceBoostEndsAt: activeBoost.endsAt,
      online: true,
      statusMessage:
        "Anomaly Blitz is open for testing with weekend-length sessions. Hex and Arena Flow run on the weekly rotation.",
      modes: modeStates,
    };
  }

  async function buildTournamentModeState(context, mode) {
    const config = TOURNAMENT_MODE_CONFIGS[mode];
    const modeWindow = computeTournamentWindowForMode(mode);
    const seasonKey = buildTournamentSeasonKey(
      context.manifest.seasonKey,
      mode,
      modeWindow,
    );
    const previousWindow = computePreviousTournamentWindowForMode(mode);
    const previousSeasonKey = buildTournamentSeasonKey(
      context.manifest.seasonKey,
      mode,
      previousWindow,
    );
    const entryRef = tournamentEntryRef(
      seasonKey,
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
    const fallbackGrouping = buildTournamentGrouping({
      mode,
      seasonKey,
      snapshot: entryData.lastSnapshot,
      globalRating: sanitizeTournamentRating(
        entryData.globalRating ?? context.profileData.globalTournamentRating,
      ),
    });
    const [leaderboardState, playerRank, rewardState] = await Promise.all([
      buildTournamentLeaderboard({
        mode,
        seasonKey,
        capacity: config.capacity,
        groupId: fallbackGrouping.groupId,
        globalRating: sanitizeTournamentRating(
          entryData.globalRating ?? context.profileData.globalTournamentRating,
        ),
        playerUid: context.auth.uid,
      }),
      bestScore > 0
        ? computeTournamentRank({
            mode,
            seasonKey,
            score: bestScore,
            groupId: fallbackGrouping.groupId,
            globalRating: sanitizeTournamentRating(
              entryData.globalRating ?? context.profileData.globalTournamentRating,
            ),
          })
        : null,
      buildClosedTournamentRewardState({
        context,
        mode,
        seasonKey: previousSeasonKey,
        window: previousWindow,
      }),
    ]);
    const joined = entryData.joined === true;
    const rewardReady = rewardState.ready;
    const rewardClaimed = rewardState.claimed;

    return {
      mode,
      statusMessage: buildTournamentStatusMessage({
        mode,
        label: config.label,
        isOpen: modeWindow.isOpen,
        joined,
        bestScore,
        rewardReady,
        rewardClaimed,
      }),
      mechanicSummary: config.mechanicSummary,
      rewardPreview:
        rewardState.reward ?? buildTournamentReward(mode, playerRank, bestScore),
      startsAt: modeWindow.startsAt.toISOString(),
      endsAt: modeWindow.endsAt.toISOString(),
      groupId: sanitizeString(entryData.groupId, fallbackGrouping.groupId),
      matchBucketLabel:
        sanitizeOptionalString(entryData.matchBucketLabel) ??
        fallbackGrouping.matchBucketLabel,
      groupSize: leaderboardState.groupSize,
      capacity: config.capacity,
      playerBestScore: bestScore,
      playerRank,
      joined,
      isOpen: modeWindow.isOpen,
      rewardReady,
      rewardClaimed,
      seedPowerIndex: clampInt(
        entryData.seedPowerIndex,
        0,
        TOURNAMENT_LIMITS.towerPowerIndex,
        0,
      ),
      leaderboard: leaderboardState.entries,
    };
  }

  async function buildTournamentLeaderboard({
    mode,
    seasonKey,
    capacity,
    groupId,
    globalRating,
    playerUid,
  }) {
    const scoringEntriesRef = tournamentEntriesRef(seasonKey, mode)
      .where("groupId", "==", groupId)
      .where("bestScore", ">", 0);
    const [leaderboardSnap, scoringEntryCountSnap] = await Promise.all([
      scoringEntriesRef.orderBy("bestScore", "desc").limit(capacity).get(),
      scoringEntriesRef.count().get(),
    ]);
    const realEntries = leaderboardSnap.docs.map((doc) => {
      const data = doc.data() || {};
      const snapshot = normalizeOptionalTournamentPlayerSnapshot(data.lastSnapshot);
      return {
        displayName: sanitizeString(data.displayName, "Pilot"),
        score: clampInt(
          data.bestScore,
          0,
          TOURNAMENT_LIMITS.submittedScore,
          0,
        ),
        globalRating: sanitizeTournamentRating(data.globalRating),
        isPlayer: doc.id === playerUid,
        ...(snapshot ? { snapshot } : {}),
      };
    });
    const syntheticEntries = buildSyntheticTournamentEntries({
      mode,
      seasonKey,
      groupId,
      globalRating,
      capacity,
    });
    const entries = [...realEntries, ...syntheticEntries]
      .sort(compareTournamentLeaderboardEntries)
      .slice(0, capacity);

    return {
      entries,
      groupSize: scoringEntryCountSnap.data().count + syntheticEntries.length,
    };
  }

  async function computeTournamentRank({
    mode,
    seasonKey,
    score,
    groupId,
    globalRating,
  }) {
    const realAhead = (
      await tournamentEntriesRef(seasonKey, mode)
        .where("groupId", "==", groupId)
        .where("bestScore", ">", score)
        .count()
        .get()
    ).data().count;
    const syntheticAhead = buildSyntheticTournamentEntries({
      mode,
      seasonKey,
      groupId,
      globalRating,
      capacity: TOURNAMENT_MODE_CONFIGS[mode].capacity,
    }).filter((entry) => entry.score > score).length;
    return realAhead + syntheticAhead + 1;
  }

  async function buildClosedTournamentRewardState({
    context,
    mode,
    seasonKey,
    window,
  }) {
    const entryRef = tournamentEntryRef(seasonKey, mode, context.auth.uid);
    const entrySnap = await entryRef.get();
    const entryData = entrySnap.data() || {};
    const bestScore = clampInt(
      entryData.bestScore,
      0,
      TOURNAMENT_LIMITS.submittedScore,
      0,
    );
    const claimed = Boolean(entryData.rewardClaimed && bestScore > 0);
    if (!entrySnap.exists || bestScore <= 0 || Date.now() < window.endsAt.getTime()) {
      return {
        ready: false,
        claimed,
        rank: null,
        bestScore,
        reward: null,
      };
    }

    const grouping = buildTournamentGrouping({
      mode,
      seasonKey,
      snapshot: entryData.lastSnapshot,
      globalRating: sanitizeTournamentRating(
        entryData.globalRating ?? context.profileData.globalTournamentRating,
      ),
    });
    const rank = await computeTournamentRank({
      mode,
      seasonKey,
      score: bestScore,
      groupId: grouping.groupId,
      globalRating: sanitizeTournamentRating(
        entryData.globalRating ?? context.profileData.globalTournamentRating,
      ),
    });
    return {
      ready: !claimed,
      claimed,
      rank,
      bestScore,
      reward: buildTournamentReward(mode, rank, bestScore),
    };
  }

  function compareTournamentLeaderboardEntries(left, right) {
    if (right.score !== left.score) {
      return right.score - left.score;
    }
    if (left.isPlayer !== right.isPlayer) {
      return left.isPlayer ? -1 : 1;
    }
    return left.displayName.localeCompare(right.displayName);
  }

  function buildSyntheticTournamentEntries({
    mode,
    seasonKey,
    groupId,
    globalRating,
    capacity,
  }) {
    if (mode !== "arenaFlow") {
      return [];
    }
    const count = Math.min(ARENA_FLOW_SYNTHETIC_PLAYER_COUNT, capacity);
    const rating = sanitizeTournamentRating(globalRating);
    const bucketSeed = sanitizeString(groupId, `${seasonKey}:arena`);
    return Array.from({ length: count }, (_, index) => {
      const roll = seededUnitFloat(`${seasonKey}:${bucketSeed}:bot:${index}`);
      const nameIndex =
        positiveHash(`${bucketSeed}:name:${index}`) %
        ARENA_FLOW_SYNTHETIC_NAMES.length;
      const ratingOffset = Math.round((roll - 0.5) * 420);
      const botRating = sanitizeTournamentRating(
        rating + ratingOffset + ((index % 5) - 2) * 18,
      );
      const scoreRoll = seededUnitFloat(`${bucketSeed}:score:${index}:${seasonKey}`);
      const score = Math.max(
        18,
        Math.round(55 + (botRating - 750) / 6 + scoreRoll * 190),
      );
      const towerAffinity =
        ARENA_FLOW_AFFINITIES[
          positiveHash(`${bucketSeed}:tower-affinity:${index}`) %
            ARENA_FLOW_AFFINITIES.length
        ];
      const enemyAffinity =
        ARENA_FLOW_AFFINITIES[
          positiveHash(`${bucketSeed}:enemy-affinity:${index}`) %
            ARENA_FLOW_AFFINITIES.length
        ];
      const towerPowerIndex = clampInt(
        EVEN_ENTRY_TOURNAMENT_POWER_INDEX +
          Math.round((botRating - 800) * 18 + scoreRoll * 2400),
        EVEN_ENTRY_TOURNAMENT_POWER_INDEX,
        TOURNAMENT_LIMITS.towerPowerIndex,
        EVEN_ENTRY_TOURNAMENT_POWER_INDEX,
      );
      return {
        displayName: ARENA_FLOW_SYNTHETIC_NAMES[nameIndex],
        score,
        globalRating: botRating,
        isPlayer: false,
        synthetic: true,
        snapshot: {
          overallLevel: EVEN_ENTRY_TOURNAMENT_LEVEL,
          prestigeLevel: 0,
          activeLayerTier: Math.max(1, 1 + Math.floor((botRating - 700) / 450)),
          builtTowerCount: EVEN_ENTRY_TOURNAMENT_BUILT_TOWER_COUNT,
          coreLevel: Math.max(
            EVEN_ENTRY_TOURNAMENT_CORE_LEVEL,
            1 + Math.floor((botRating - 800) / 300),
          ),
          towerPowerIndex,
          towerAffinity,
          enemyAffinity,
          enemyCardIds: [],
          enemyCardLevels: {},
          bossEnemyLevel: 1,
        },
      };
    });
  }

  function positiveHash(value) {
    const text = String(value);
    let hash = 2166136261;
    for (let index = 0; index < text.length; index += 1) {
      hash ^= text.charCodeAt(index);
      hash = Math.imul(hash, 16777619);
    }
    return hash >>> 0;
  }

  function seededUnitFloat(value) {
    return positiveHash(value) / 0xffffffff;
  }

  function buildTournamentStatusMessage({
    mode,
    label,
    isOpen,
    joined,
    bestScore,
    rewardReady,
    rewardClaimed,
  }) {
    if (rewardReady && !rewardClaimed) {
      return "Reward ready. Claim your tournament package.";
    }
    if (rewardClaimed) {
      return "Reward claimed. Submit another run to improve your standing.";
    }
    if (!isOpen) {
      return mode === "enemyBlitz"
        ? "Anomaly Blitz is closed right now. It reopens when testing access is enabled."
        : `${label} is between rotations right now.`;
    }
    if (!joined) {
      switch (mode) {
        case "enemyBlitz":
          return "Anomaly Blitz is open for testing. Start a run to lock your seed and enter the survival board.";
        case "hexGauntlet":
          return "Hex is live. Run solo and post your best wave to the global weekly leaderboard.";
        case "arenaFlow":
          return "Arena Flow is live for the week. Start a run to send your highest-layer Home Tower into the net-damage ladder.";
        default:
          return `${label} queue is open. Start a run to lock your current seed.`;
      }
    }
    if (bestScore > 0) {
      switch (mode) {
        case "enemyBlitz":
          return "Run submitted. Improve your best wave before the testing board resets.";
        case "hexGauntlet":
          return "Run submitted. Improve your best wave on the global weekly leaderboard.";
        case "arenaFlow":
          return "Run submitted. Improve your duel score before the weekly ladder resets.";
        default:
          return "Run submitted. Improve your best score before the bracket resets.";
      }
    }
    switch (mode) {
      case "enemyBlitz":
        return "Testing queue is ready. Start a weekend-length survival session whenever you are ready.";
      case "hexGauntlet":
        return "Weekly queue is ready. Start a solo hex run whenever you are ready.";
      case "arenaFlow":
        return "Weekly queue is ready. Start a Home Tower arena duel whenever you are ready.";
      default:
        return "Queue is ready. Start a tournament run from the mobile client.";
    }
  }

  function buildTournamentReward(mode, rank, bestScore) {
    const base = TOURNAMENT_MODE_CONFIGS[mode].rewardBase;
    const placementMultiplier =
      rank === 1
        ? 1.6
        : rank !== null && rank <= 3
          ? 1.35
          : rank !== null && rank <= 10
            ? 1.15
            : 1;
    const scoreMultiplier =
      bestScore > 0 ? Math.min(1.4, 1 + bestScore / 100000) : 1;
    const totalMultiplier = placementMultiplier * scoreMultiplier;

    return {
      flux: Math.floor(base.flux * totalMultiplier),
      tickets: Math.max(
        base.tickets,
        Math.round(base.tickets * placementMultiplier),
      ),
      experienceMultiplier: roundToTwo(
        Math.min(base.experienceMultiplier + (placementMultiplier - 1) * 0.3, 2.5),
      ),
      experienceBuffHours:
        base.experienceBuffHours + (rank !== null && rank <= 3 ? 4 : 0),
      bonusTowerManagers: rank === 1 ? 2 : rank !== null && rank <= 3 ? 1 : 0,
      bonusTowerManagerRarity:
        rank === 1 ? "legendary" : rank !== null && rank <= 3 ? "epic" : null,
      bonusEquipmentCaches:
        base.bonusEquipmentCaches +
        (rank === 1 ? 2 : rank !== null && rank <= 3 ? 1 : 0),
      bonusEquipmentRarity:
        rank === 1 ? "legendary" : rank !== null && rank <= 3 ? "epic" : "rare",
    };
  }

  function computeNextTournamentRating({
    currentRating,
    submittedScore,
    previousBestScore,
  }) {
    const baseline = EVEN_ENTRY_TOURNAMENT_POWER_INDEX;
    const improvement = Math.max(0, submittedScore - previousBestScore);
    const improvementDelta = Math.min(28, Math.floor(improvement / 400));
    const performanceDelta = Math.max(
      -18,
      Math.min(22, Math.floor(((submittedScore / baseline) - 1) * 18)),
    );
    const participationDelta = submittedScore >= previousBestScore ? 4 : -6;

    return sanitizeTournamentRating(
      currentRating + improvementDelta + performanceDelta + participationDelta,
    );
  }

  function buildTournamentGrouping({ mode, seasonKey, snapshot, globalRating }) {
    switch (mode) {
      case "enemyBlitz":
        return {
          groupId: `${seasonKey}:enemy-blitz`,
          matchBucketLabel: TOURNAMENT_MODE_CONFIGS[mode].defaultBucketLabel,
        };
      case "hexGauntlet": {
        return {
          groupId: `${seasonKey}:hex-global`,
          matchBucketLabel: TOURNAMENT_MODE_CONFIGS[mode].defaultBucketLabel,
        };
      }
      case "arenaFlow": {
        const bucketFloor = Math.floor(globalRating / 100) * 100;
        return {
          groupId: `${seasonKey}:arena-flow:${bucketFloor}`,
          matchBucketLabel: TOURNAMENT_MODE_CONFIGS[mode].defaultBucketLabel,
        };
      }
      default:
        throw new HttpsError("invalid-argument", "Unknown tournament mode.");
    }
  }

  function buildTournamentSeasonKey(manifestSeasonKey, mode, window) {
    const startsAtKey = window.startsAt.toISOString().slice(0, 10);
    return `${manifestSeasonKey}:${mode}:${startsAtKey}`;
  }

  function touchTournamentSeason(transaction, seasonKey, seasonWindow) {
    const seasonRef = db.collection(TOURNAMENT_SEASON_COLLECTION).doc(seasonKey);
    transaction.set(
      seasonRef,
      {
        seasonKey,
        startsAt: Timestamp.fromDate(seasonWindow.startsAt),
        endsAt: Timestamp.fromDate(seasonWindow.endsAt),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  function tournamentEntriesRef(seasonKey, mode) {
    return db
      .collection(TOURNAMENT_SEASON_COLLECTION)
      .doc(seasonKey)
      .collection("modes")
      .doc(mode)
      .collection("entries");
  }

  function tournamentEntryRef(seasonKey, mode, uid) {
    return tournamentEntriesRef(seasonKey, mode).doc(uid);
  }

  function computeTournamentOverviewWindow(now = new Date()) {
    const windows = Object.keys(TOURNAMENT_MODE_CONFIGS).map((mode) =>
      computeTournamentWindowForMode(mode, now),
    );
    const startsAt = windows.reduce(
      (earliest, current) =>
        current.startsAt.getTime() < earliest.getTime() ? current.startsAt : earliest,
      windows[0].startsAt,
    );
    const endsAt = windows.reduce(
      (latest, current) =>
        current.endsAt.getTime() > latest.getTime() ? current.endsAt : latest,
      windows[0].endsAt,
    );
    return { startsAt, endsAt };
  }

  function computeTournamentWindowForMode(mode, now = new Date()) {
    const config = TOURNAMENT_MODE_CONFIGS[mode];
    if (config.testingAlwaysOpen === true) {
      return computeWeeklyTournamentWindow(now);
    }
    switch (config.schedule) {
      case "weekend":
        return computeWeekendTournamentWindow(now);
      case "weekly":
      default:
        return computeWeeklyTournamentWindow(now);
    }
  }

  function computePreviousTournamentWindowForMode(mode, now = new Date()) {
    const config = TOURNAMENT_MODE_CONFIGS[mode];
    const current = computeTournamentWindowForMode(mode, now);
    const startsAt = new Date(current.startsAt.getTime());
    const endsAt = new Date(current.startsAt.getTime());
    startsAt.setUTCDate(startsAt.getUTCDate() - 7);
    if (config.schedule === "weekend" && config.testingAlwaysOpen !== true) {
      endsAt.setUTCDate(endsAt.getUTCDate() - 4);
    }
    return { startsAt, endsAt, isOpen: false };
  }

  function computeWeeklyTournamentWindow(now = new Date()) {
    const start = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
    );
    const weekdayOffset = (start.getUTCDay() + 6) % 7;
    start.setUTCDate(start.getUTCDate() - weekdayOffset);
    start.setUTCHours(0, 0, 0, 0);

    const end = new Date(start.getTime());
    end.setUTCDate(end.getUTCDate() + 7);

    return { startsAt: start, endsAt: end, isOpen: true };
  }

  function computeWeekendTournamentWindow(now = new Date()) {
    const today = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
    );
    const daysSinceFriday = (today.getUTCDay() + 2) % 7;
    const lastFriday = new Date(today.getTime());
    lastFriday.setUTCDate(lastFriday.getUTCDate() - daysSinceFriday);

    const end = new Date(lastFriday.getTime());
    end.setUTCDate(end.getUTCDate() + 3);

    if (now >= lastFriday && now < end) {
      return { startsAt: lastFriday, endsAt: end, isOpen: true };
    }

    const nextFriday = new Date(lastFriday.getTime());
    if (now >= end) {
      nextFriday.setUTCDate(nextFriday.getUTCDate() + 7);
    }
    const nextEnd = new Date(nextFriday.getTime());
    nextEnd.setUTCDate(nextEnd.getUTCDate() + 3);
    return { startsAt: nextFriday, endsAt: nextEnd, isOpen: false };
  }

  function ensureTournamentModeOpen(mode) {
    const window = computeTournamentWindowForMode(mode);
    if (!window.isOpen) {
      throw new HttpsError(
        "failed-precondition",
        `${TOURNAMENT_MODE_CONFIGS[mode].label} is closed right now.`,
      );
    }
    return window;
  }

  function normalizeTournamentPlayerSnapshot(value) {
    if (!value || typeof value !== "object") {
      throw new HttpsError(
        "invalid-argument",
        "Tournament snapshot payload is required.",
      );
    }

    return {
      overallLevel: clampInt(
        value.overallLevel,
        EVEN_ENTRY_TOURNAMENT_LEVEL,
        TOURNAMENT_LIMITS.overallLevel,
        EVEN_ENTRY_TOURNAMENT_LEVEL,
      ),
      prestigeLevel: clampInt(value.prestigeLevel, 0, 1000, 0),
      activeLayerTier: clampInt(value.activeLayerTier, 1, 50, 1),
      builtTowerCount: clampInt(
        value.builtTowerCount,
        0,
        EVEN_ENTRY_TOURNAMENT_BUILT_TOWER_COUNT,
        EVEN_ENTRY_TOURNAMENT_BUILT_TOWER_COUNT,
      ),
      coreLevel: clampInt(
        value.coreLevel,
        EVEN_ENTRY_TOURNAMENT_CORE_LEVEL,
        TOURNAMENT_LIMITS.coreLevel,
        EVEN_ENTRY_TOURNAMENT_CORE_LEVEL,
      ),
      towerPowerIndex: clampInt(
        value.towerPowerIndex,
        EVEN_ENTRY_TOURNAMENT_POWER_INDEX,
        TOURNAMENT_LIMITS.towerPowerIndex,
        EVEN_ENTRY_TOURNAMENT_POWER_INDEX,
      ),
      towerAffinity: sanitizeTournamentAffinity(value.towerAffinity, "neutral"),
      enemyAffinity: sanitizeTournamentAffinity(value.enemyAffinity, "neutral"),
      enemyCardIds: sanitizeTournamentStringList(value.enemyCardIds, 6),
      enemyCardLevels: sanitizeTournamentLevelMap(
        value.enemyCardLevels,
        value.enemyCardIds,
      ),
      bossEnemyCardId: sanitizeOptionalString(value.bossEnemyCardId),
      bossEnemyLevel: clampInt(value.bossEnemyLevel, 1, 1000, 1),
    };
  }

  function normalizeOptionalTournamentPlayerSnapshot(value) {
    if (!value || typeof value !== "object") {
      return null;
    }
    return normalizeTournamentPlayerSnapshot(value);
  }

  function sanitizeTournamentAffinity(value, fallback) {
    const key = sanitizeString(value, "");
    return ARENA_FLOW_AFFINITIES.includes(key) ? key : fallback;
  }

  function sanitizeTournamentStringList(value, limit) {
    if (!Array.isArray(value)) {
      return [];
    }
    const unique = [];
    for (const item of value) {
      const key = sanitizeString(item, "").slice(0, 96);
      if (key && !unique.includes(key)) {
        unique.push(key);
      }
      if (unique.length >= limit) {
        break;
      }
    }
    return unique;
  }

  function sanitizeTournamentLevelMap(value, ids) {
    if (!value || typeof value !== "object") {
      return {};
    }
    const normalizedIds = sanitizeTournamentStringList(ids, 6);
    return normalizedIds.reduce((levels, id) => {
      levels[id] = clampInt(value[id], 1, 1000, 1);
      return levels;
    }, {});
  }

  function sanitizeTournamentSubmittedScore(mode, value, snapshot) {
    const submittedScore = clampInt(
      value,
      0,
      TOURNAMENT_LIMITS.submittedScore,
      0,
    );
    if (mode !== "arenaFlow" || submittedScore <= 0) {
      return submittedScore;
    }
    const maxArenaScore = maxArenaFlowSubmittedScore(snapshot);
    return Math.min(submittedScore, maxArenaScore);
  }

  function maxArenaFlowSubmittedScore(snapshot) {
    const power = clampInt(
      snapshot?.towerPowerIndex,
      EVEN_ENTRY_TOURNAMENT_POWER_INDEX,
      TOURNAMENT_LIMITS.towerPowerIndex,
      EVEN_ENTRY_TOURNAMENT_POWER_INDEX,
    );
    const tier = clampInt(snapshot?.activeLayerTier, 1, 50, 1);
    const coreLevel = clampInt(
      snapshot?.coreLevel,
      EVEN_ENTRY_TOURNAMENT_CORE_LEVEL,
      TOURNAMENT_LIMITS.coreLevel,
      EVEN_ENTRY_TOURNAMENT_CORE_LEVEL,
    );
    const builtTowerCount = clampInt(
      snapshot?.builtTowerCount,
      0,
      EVEN_ENTRY_TOURNAMENT_BUILT_TOWER_COUNT,
      EVEN_ENTRY_TOURNAMENT_BUILT_TOWER_COUNT,
    );
    return Math.round(
      500 +
        Math.sqrt(power) * 12 +
        tier * 180 +
        coreLevel * 8 +
        builtTowerCount * 40,
    );
  }

  function resolveDisplayName(profileData, auth) {
    const screenName = normalizeStoredScreenName(profileData.screenName);
    if (screenName) {
      return screenName;
    }
    const namedPlayer = sanitizeString(profileData.playerId, "");
    if (namedPlayer) {
      return namedPlayer;
    }
    const authName = sanitizeString(auth.token?.name, "");
    if (authName) {
      return authName.slice(0, 24);
    }
    return `Pilot ${auth.uid.slice(0, 6).toUpperCase()}`;
  }

  function normalizeTournamentBoost(profileData) {
    const endsAtMillis = toMillis(profileData.activeTournamentBoostEndsAt);
    const multiplier = clampNumber(
      profileData.activeTournamentExpMultiplier,
      1,
      3,
      1,
    );

    if (!endsAtMillis || endsAtMillis <= Date.now() || multiplier <= 1) {
      return {
        multiplier: 1,
        endsAt: null,
      };
    }

    return {
      multiplier,
      endsAt: new Date(endsAtMillis).toISOString(),
    };
  }

  function sanitizeTournamentMode(value) {
    const next = sanitizeString(value, "");
    if (!Object.prototype.hasOwnProperty.call(TOURNAMENT_MODE_CONFIGS, next)) {
      throw new HttpsError("invalid-argument", "Unknown tournament mode.");
    }
    return next;
  }

  function sanitizeTournamentRating(value) {
    return clampInt(
      value,
      500,
      TOURNAMENT_LIMITS.globalRating,
      DEFAULT_TOURNAMENT_RATING,
    );
  }

  function hasPremiumMembership(profileData) {
    return profileData?.hasPremiumMembership === true;
  }

  return {
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
    computeTournamentWindowForMode,
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
  };
}

module.exports = { createTournamentHelpers };
