# Versioning

LumiHex uses the Flutter version string format:

```text
<release version>+<build number>
```

For example, `1.0.15+16` means release version `1.0.15` and build number `16`.
The release version is compared semantically. The build number is compared only
when the release versions are equal.

## Files To Bump

When incrementing the app version, update these source files together:

- `pubspec.yaml`
  - `version: 1.0.15+16`
- `lib/app/lightcore_build_info.dart`
  - `LightcoreBuildInfo.versionName`
  - `LightcoreBuildInfo.buildNumber`
- `functions/index.js`
  - `DEFAULT_MANIFEST.minimumSupportedVersion`
  - `DEFAULT_MANIFEST.minimumSupportedBuildNumber`
  - `DEFAULT_MANIFEST.recommendedVersion`
  - `DEFAULT_MANIFEST.recommendedBuildNumber`
- Preview and focused test fixtures when they assert a literal version:
  - `lib/app/lightcore_preview_app.dart`
  - `test/lightcore_main_menu_smoke_test.dart`

Do not hand-edit generated `build/` output. Rebuild it from source.

## Launch Gate Behavior

The app resolves its client version from `package_info_plus`. If platform
metadata is unavailable, it falls back to `LightcoreBuildInfo`.

On startup, the client sends both `clientVersion` and `clientBuildNumber` to
the `bootstrapClient` callable. Cloud Functions compares those values against
the sanitized manifest and stores both values on the player profile.

The checked-in `DEFAULT_MANIFEST` is the lower bound for the deployed backend:
if `runtime/clientManifest` still contains an older version, `loadManifest()`
clamps the returned gate up to the checked-in default. A live manifest may still
raise the required version above the checked-in default.

Set minimum and recommended to the same version/build when the latest build is
mandatory:

```js
minimumSupportedVersion: "1.0.15",
minimumSupportedBuildNumber: "16",
recommendedVersion: "1.0.15",
recommendedBuildNumber: "16",
```

## Menu Display

The main menu footer renders `LightcoreBootstrapReport.clientDisplayVersion`,
so it should show the full client build, such as `V1.0.15+16`.

Version-blocked notices render `LightcoreBootstrapReport.requiredServerVersion`,
which includes the recommended build number when one is configured.

## Verification

After bumping a version, run:

```bash
dart format lib/app/lightcore_build_info.dart lib/app/lightcore_bootstrap.dart lib/app/lightcore_preview_app.dart lib/services/lightcore_firebase_backend.dart lib/screens/lightcore_main_menu_screen.dart test/helpers/lightcore_test_fixtures.dart test/lightcore_bootstrap_test.dart test/lightcore_main_menu_smoke_test.dart
flutter test test/lightcore_bootstrap_test.dart test/lightcore_main_menu_smoke_test.dart
```

Before release, deploy both app and backend surfaces that depend on the gate.
For Firebase Hosting, `firebase deploy --only hosting` runs the configured
`flutter build web --release` predeploy. For Cloud Functions, deploy from
`functions/` with `npm run deploy`.
