# LumiHex Codex Instructions

- Treat the local `main` branch as the active development state and GitHub `origin/main` as the backup snapshot.
- At the end of each completed task, unless the user explicitly says not to, stage current changes, commit them with a concise backup-oriented message, and push `main` to `origin`.
- Keep the backup workflow simple: `git status`, `git add -A`, `git commit -m "<message>"`, then `git push origin main`.
