# LumiHex Codex Instructions

- Treat the local `main` branch as the active development state and GitHub `origin/main` as the backup snapshot.
- Keep `docs/marketing-brief.md` current when a change adds, removes, renames, or materially alters a player-facing feature, monetization surface, story premise, store claim, branding element, or marketing asset need.
- At the end of each completed task, unless the user explicitly says not to, stage current changes, commit them with a concise backup-oriented message, and push `main` to `origin`.
- Keep the backup workflow simple: `git status`, `git add -A`, `git commit -m "<message>"`, then `git push origin main`.

## Fast Repository Map

- `README.md` explains the product scope and common run commands.
- `docs/README.md` indexes design, QA, release, testing, and asset references.
- `lib/README.md` maps the Flutter source tree and the main runtime flow.
- `assets/README.md` explains where images, audio, guide art, and sprites live.
- `functions/README.md` maps the Firebase Functions backend and backend tests.
- `tool/README.md` covers one-off asset import and generation scripts.

## Runtime Entry Points

- `lib/main.dart` chooses between event previews, web previews, and the full app.
- `lib/app/lightcore_app.dart` owns bootstrap, session recovery, cloud sync, audio, and app-level navigation.
- `lib/state/lightcore_controller.dart` is the local gameplay authority; its `part` files split saves, battle, rewards, progression, and inventory logic.
- `lib/battle/lightcore_battle_game.dart` and `lib/battle/lightcore_battle_game/` render the Flame battlefield.
- `functions/index.js` is the callable/scheduled backend entry point.

## Change Placement Rules

- Keep runtime assets under `assets/`, not `lib/`.
- Keep player-facing design and store-claim changes reflected in `docs/marketing-brief.md`.
- Put reusable Flutter UI in `lib/widgets/`; keep screen-specific widgets beside their screen under `lib/screens/<feature>/`.
- Put gameplay authority in `lib/state/lightcore_controller/` parts; do not mutate controller-owned models directly from widgets.
- Avoid broad platform-folder edits (`android/`, `ios/`, `macos/`, `linux/`, `windows/`) unless the task is platform-specific.

## Verification

- Flutter client: run `flutter analyze` and the most focused `flutter test` command practical for the change.
- Backend: run `cd functions` then `npm test` after editing `functions/`.
- Asset path changes require a Flutter analysis or build check because missing assets fail late.
