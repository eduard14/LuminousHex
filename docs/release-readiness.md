# Release Readiness

This checklist covers pre-release readiness that does not depend on App Store or
Google Play IAP approval. IAP, production sign-in provider launch, and platform
receipt validation stay out of scope until the app is closer to submission.

## Backend Maintenance

- `refreshGlobalLeaderboard` runs every 10 minutes and writes the global Total
  Strength board to `globalLeaderboardSnapshots/towerStrength`.
- `buildSocialOverview` reads the cached global board while still calculating
  the current player's rank from the latest public profile available to the
  server.
- The client may locally preview the current player's rank immediately after a
  tower change; other players refresh from the 10-minute server snapshot.
- `purgeGlobalChat` runs hourly and deletes global chat messages older than the
  24-hour retention window.
- `getGlobalChat` and `sendGlobalChatMessage` also purge expired messages before
  returning chat state, so low-traffic periods do not leave stale messages in the
  client.

## Balance QA

- Threat Directors must visibly change live spawn pressure, enemy strength,
  rewards, EXP, stability risk, and farm output.
- Farm Validation must require surviving 3 waves at the selected level with the
  current Threat Director before offline rewards are produced.
- Offline reward claims must use elapsed server sign-in time, the validated
  region level, the validated Threat Director, and the saved enemy output
  snapshot.
- Equipment, guilds, avatar cosmetics, and Space Room must stay hidden from the
  launch surface.
- Dev event preview URLs are allowed in web debug builds only and must not be
  linked from production UI.

## Chat Moderation And Support

- Global chat messages are retained for 24 hours.
- Whisper messages are visible only to the sender and recipient.
- Posting the same message repeatedly or posting too quickly triggers a warning
  and a 24-hour chat lock.
- A second spam offense after a warning bans the account.
- Tracked bot-message repeats are blocked before posting and may ban the account
  immediately.
- Support copy should tell players that Lemon Goose Games will never ask for a
  password, recovery code, private key, payment password, or device passcode.
- Chat ban appeals and account-ban support should route through the same public
  support channel used for account recovery before release.

## Manual Smoke Pass

1. Start from a fresh guest profile and reach the map.
2. Confirm equipment, guilds, avatar cosmetics, and Space Room are not active
   release surfaces.
3. Build and upgrade towers until manager assignment unlocks.
4. Assign a Threat Director to a revealed region and confirm live enemy pressure
   and reward labels change.
5. Complete Farm Validation and verify the next offline claim references the
   validated region/director output.
6. Open the leaderboard, change tower strength locally, and verify the player's
   projected rank moves immediately while the global board remains the cached
   server board.
7. Send a normal global chat message, a whisper, a repeated message, and a
   tracked bot-message phrase in a non-production test project.
8. Confirm chat moderation records warning, chat-ban, and account-ban state as
   expected.
