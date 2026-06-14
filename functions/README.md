# Firebase Functions Backend

`functions/` contains the Firebase Functions v2 backend for LumiHex. The app
uses callable Functions for profile bootstrap, cloud saves, offline progress,
social state, tournaments, chat, and live balance metadata.

## Layout

- `index.js`: exported callable and scheduled Functions plus collection names,
  runtime manifest defaults, and validation limits.
- `src/runtime_content.js`: server-side runtime content helpers.
- `src/player_save_helpers.js`: cloud-save sanitation, revision, and integrity
  helpers.
- `src/tournament_helpers.js`: tournament scoring and bracket helpers.
- `scripts/check-top-level-call-references.js`: callable export reference check.

## Commands

```bash
npm run check
npm run serve
npm run deploy
npm run logs
```

Deploy scripts target `lumicore-95c8a` explicitly. Do not remove that project
guard unless the deployment workflow is intentionally changed.
