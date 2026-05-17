# LumiHex Codex Instructions

- Treat the local `main` branch as the active development state and GitHub `origin/main` as the backup snapshot.
- Keep `docs/marketing-brief.md` current when a change adds, removes, renames, or materially alters a player-facing feature, monetization surface, story premise, store claim, branding element, or marketing asset need.
- At the end of each completed task, unless the user explicitly says not to, stage current changes, commit them with a concise backup-oriented message, and push `main` to `origin`.
- Keep the backup workflow simple: `git status`, `git add -A`, `git commit -m "<message>"`, then `git push origin main`.
