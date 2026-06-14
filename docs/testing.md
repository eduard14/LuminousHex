# Testing And Validation

Run the smallest useful check while iterating, then broaden before handoff when
the change touches shared systems.

## Flutter Client

```bash
flutter analyze
flutter test
```

Use a targeted test command when a focused test exists:

```bash
flutter test test/<file>_test.dart
```

See [../test/README.md](../test/README.md) for where new Flutter tests should
live.

For web-only or asset-path changes, add a build check:

```bash
flutter build web
```

## Firebase Functions

```bash
cd functions
npm test
```

`npm test` syntax-checks `index.js`, checks top-level callable references, and
runs helper tests for player saves and tournaments.

## Local Runs

```bash
flutter run -d ios
flutter run -d android
flutter run -d chrome
```

The web run is a developer staging surface. iOS and Android remain the primary
product targets.

## Handoff Rule

If a validation command cannot be run, note the exact command and reason in the
handoff. Do not imply coverage from commands that were not executed.
