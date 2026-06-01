# Testing

LumiHex uses a small CI-facing test suite while gameplay design is still moving
quickly. The default tests are guardrails for build health, persistence,
content integrity, and a few screen smoke paths. Detailed gameplay, balance,
tutorial choreography, projectile, and tower math regressions were intentionally
removed from the default suite so tests do not freeze pre-production design.

## Fast local checks

Run the existing unit and widget regression suite:

```sh
flutter test
```

This covers cloud save and restore behavior, currency invariants, basic menu
and screen smoke checks, data/catalog integrity, asset references, rewarded-ad
disclosure, and the lightweight Layer 2 UI promotion smoke. The suite is meant
to answer “does the app still broadly work?” rather than “did gameplay tuning
stay exactly the same?” Deleted gameplay tests can be recovered from git history
if a mechanic becomes stable enough to protect again.

## Screenshot aesthetic regression checks

Golden screenshot tests live outside `test/` so they do not run during the
default `flutter test` loop:

```sh
flutter test golden_test
```

When the UI intentionally changes, refresh the checked-in screenshots:

```sh
flutter test golden_test --update-goldens
```

The current golden coverage captures the main menu, early compact battle HUD,
and compact battle after a deterministic Prism Shell promotion.

## Device/browser UI smoke checks

Integration tests are also opt-in:

```sh
flutter test integration_test/layer2_ui_smoke_test.dart -d macos
```

or use another configured device:

```sh
flutter test integration_test/layer2_ui_smoke_test.dart -d <deviceId>
```

The Prism Shell smoke test starts from a deterministic promotion-ready state,
opens the Advancement UI, forges a Prism Shell through the actual UI, and
verifies the app lands in the promoted shell.

Flutter's `integration_test` runner currently requires a supported device target;
if the local device toolchain is unavailable, run the equivalent fast regression:

```sh
flutter test test/layer2_ui_regression_test.dart
```

## Manual web screenshots

Avoid the interactive screenshot shortcut from `flutter run -d chrome` for now.
On Flutter 3.38.5 it can crash inside `flutter_tools` while handling the
Chrome screenshot request, leaving an empty root-level `flutter_*.png` file.
Use the checked-in golden tests for regression screenshots, or capture the
running web app from Chrome/DevTools instead.

## Dev event preview URLs

Event preview mode is a web debug-build tool only. It is gated behind
`kDebugMode`, should not be exposed in production routes, and should not be
marketed as a release feature.

Use `eventPreview` to open the dev preview shell:

```text
/?eventPreview=dungeons&dungeon=threatDirector&tower=prism
/?eventPreview=dungeons&dungeon=prismRift&tower=nexus
/?eventPreview=tournaments&tournament=enemyBlitz&tower=starter
/?eventPreview=tournaments&tournament=hexGauntlet&tower=prism
/?eventPreview=tournaments&tournament=arenaFlow&tower=nexus
```

`devPreview` is accepted as an alias for `eventPreview`.

Supported tower seeds are `starter`, `prism`, and `nexus`. Dungeon routes are
`hub`, `threatDirector`, and `prismRift`. Tournament routes are `enemyBlitz`,
`hexGauntlet`, and `arenaFlow`.

## Development impact

The default development loop is intentionally lighter than before:
`flutter test` does not include the golden or integration directories, and it no
longer includes brittle gameplay/balance micro-regressions. Use the heavier
suites before releases, before visual polish changes, or when touching
promotion/navigation UI.
