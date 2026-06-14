# LumiHex Documentation Map

Use this directory as the project memory. Code should stay readable on its own,
but these files explain the product intent, release posture, and validation
steps that are too broad to keep in source comments.

## Product And Design

- [marketing-brief.md](marketing-brief.md) is the store-facing promise, brand
  framing, audience, monetization notes, and asset needs. Update it whenever a
  player-facing feature, claim, premise, monetization surface, or marketing need
  changes.
- [gameplay-mechanics-audit.md](gameplay-mechanics-audit.md) summarizes the
  implemented loop, economies, shell promotion, and redesign risks.
- [code-design-alignment-map.md](code-design-alignment-map.md) maps design-bible
  systems to Dart and Cloud Functions symbols.
- [ui-design-rules.md](ui-design-rules.md) records UI rules that should guide
  screen work and QA.
- [live-balance.md](live-balance.md) tracks balance assumptions for live tuning.

## Assets And Release

- [assets-needed.md](assets-needed.md) lists missing or provisional art/audio.
- [enemy-png-guidelines.md](enemy-png-guidelines.md) defines enemy art export
  expectations.
- [release-readiness.md](release-readiness.md) tracks production-hardening work.
- [versioning.md](versioning.md) explains version bumps across Flutter metadata,
  backend gates, menu display fixtures, and deploy checks.

## Development And QA

- [testing.md](testing.md) lists validation commands for Flutter and Firebase.
- [design-qa.md](design-qa.md) records the latest Product Design QA outcome.

When a code change contradicts one of these notes, update the note in the same
commit so future agents do not work from stale assumptions.
