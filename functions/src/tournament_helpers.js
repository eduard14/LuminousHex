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
        "Hex and Arena Flow run on the weekly rotation. Enemy Blitz opens on weekends.",
      modes: modeStates,
    };
  }

  async function buildTournamentModeState(context, mode) {
    const config = TOURNAMENT_MODE_CONFIGS[mode];
    const modeWindow = computeTournamentWindowForMode(mode);
    const entryRef = tournamentEntryRef(
      context.manifest.seasonKey,
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
    const scoringEntriesRef = tournamentEntriesRef(
      context.manifest.seasonKey,
      mode,
    ).where("bestScore", ">", 0);
    const [leaderboardSnap, scoringEntryCountSnap] = await Promise.all([
      scoringEntriesRef.orderBy("bestScore", "desc").limit(config.capacity).get(),
      scoringEntriesRef.count().get(),
    ]);
    const leaderboardDocs = leaderboardSnap.docs;
    const submittedEntryCount = scoringEntryCountSnap.data().count;
    const playerRank =
      bestScore > 0
        ? (await tournamentEntriesRef(
            context.manifest.seasonKey,
            mode,
          ).where("bestScore", ">", bestScore).count().get()).data().count + 1
        : null;
    const fallbackGrouping = buildTournamentGrouping({
      mode,
      seasonKey: context.manifest.seasonKey,
      snapshot: entryData.lastSnapshot,
      globalRating: sanitizeTournamentRating(
        entryData.globalRating ?? context.profileData.globalTournamentRating,
      ),
    });
    const joined = entryData.joined === true;
    const rewardReady = Boolean(entryData.rewardReady && bestScore > 0);
    const rewardClaimed = Boolean(entryData.rewardClaimed && bestScore > 0);

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
      rewardPreview: buildTournamentReward(mode, playerRank, bestScore),
      startsAt: modeWindow.startsAt.toISOString(),
      endsAt: modeWindow.endsAt.toISOString(),
      groupId: sanitizeString(entryData.groupId, fallbackGrouping.groupId),
      matchBucketLabel:
        sanitizeOptionalString(entryData.matchBucketLabel) ??
        fallbackGrouping.matchBucketLabel,
      groupSize: submittedEntryCount,
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
      leaderboard: leaderboardDocs.map((doc) => {
        const data = doc.data() || {};
        return {
          displayName: sanitizeString(data.displayName, "Pilot"),
          score: clampInt(
            data.bestScore,
            0,
            TOURNAMENT_LIMITS.submittedScore,
            0,
          ),
          globalRating: sanitizeTournamentRating(data.globalRating),
          isPlayer: doc.id === context.auth.uid,
        };
      }),
    };
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
        ? "Enemy Blitz is closed right now. It reopens for the next weekend window."
        : `${label} is between rotations right now.`;
    }
    if (!joined) {
      switch (mode) {
        case "enemyBlitz":
          return "Enemy Blitz is live for the weekend. Join to lock your seed and start a survival sprint.";
        case "hexGauntlet":
          return "Hex is live. Run solo and post your best wave to the global weekly leaderboard.";
        case "arenaFlow":
          return "Arena Flow is live for the week. Join to configure your duel loadout and chase the weekly ladder.";
        default:
          return `${label} queue is open. Join to lock your current seed.`;
      }
    }
    if (bestScore > 0) {
      switch (mode) {
        case "enemyBlitz":
          return "Run submitted. Improve your best wave before the weekend board closes.";
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
        return "Weekend queue joined. Start a survival sprint.";
      case "hexGauntlet":
        return "Weekly queue joined. Start a solo hex run whenever you are ready.";
      case "arenaFlow":
        return "Weekly queue joined. Start an arena duel whenever you are ready.";
      default:
        return "Queue joined. Start a tournament run from the mobile client.";
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
      0,
      Math.min(22, Math.floor(((submittedScore / baseline) - 1) * 18)),
    );

    return sanitizeTournamentRating(
      currentRating + improvementDelta + performanceDelta + 6,
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

  function touchTournamentSeason(transaction, manifest, seasonWindow) {
    const seasonRef = db.collection(TOURNAMENT_SEASON_COLLECTION).doc(manifest.seasonKey);
    transaction.set(
      seasonRef,
      {
        seasonKey: manifest.seasonKey,
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
    switch (TOURNAMENT_MODE_CONFIGS[mode].schedule) {
      case "weekend":
        return computeWeekendTournamentWindow(now);
      case "weekly":
      default:
        return computeWeeklyTournamentWindow(now);
    }
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
      overallLevel: EVEN_ENTRY_TOURNAMENT_LEVEL,
      prestigeLevel: 0,
      activeLayerTier: 1,
      builtTowerCount: EVEN_ENTRY_TOURNAMENT_BUILT_TOWER_COUNT,
      coreLevel: EVEN_ENTRY_TOURNAMENT_CORE_LEVEL,
      towerPowerIndex: EVEN_ENTRY_TOURNAMENT_POWER_INDEX,
    };
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
    buildTournamentGrouping,
    touchTournamentSeason,
    tournamentEntryRef,
    computeTournamentOverviewWindow,
    ensureTournamentModeOpen,
    normalizeTournamentPlayerSnapshot,
    resolveDisplayName,
    normalizeTournamentBoost,
    sanitizeTournamentMode,
    sanitizeTournamentRating,
    hasPremiumMembership,
  };
}

module.exports = { createTournamentHelpers };
