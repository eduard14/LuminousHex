# Testing

LumiHex uses a tiered test setup so day-to-day development stays fast while
still protecting important UI and progression flows.

## Fast local checks

Run the existing unit and widget regression suite:

```sh
flutter test
```

This covers gameplay math, progression, menu rendering, overlays, and compact
layout overflow checks. These tests are intended to be cheap enough to run often.

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

## Development impact

The default development loop is unchanged: `flutter test` does not include the
golden or integration directories. Use those heavier suites before releases,
before visual polish changes, or when touching promotion/navigation UI.
