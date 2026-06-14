# Design QA

## Final Result

Blocked for strict Product Design comparison QA.

## Why

- Source target: no revised target mockup was supplied for the orbit-queue UI. The provided image is the current problem state, not the desired final target.
- Render capture: local `flutter build web` completed, but headless Chrome captures of `http://127.0.0.1:4192/?rebuild=1` produced blank dark frames, so there is no reliable rendered screenshot to compare against a target.

## Implemented Checks

- Replaced the grouped rectangular Shot Queue HUD with an in-battlefield orbit/charge visualization around the Lightcore.
- Reduced the visual weight of the top Layer 1 HUD so the tower field remains the primary focus.
- Retitled active run upgrades as Global Tower Upgrades and kept persistent upgrades separate after runs.
- Updated widget coverage to assert the orbit queue exists and exposes queue readiness semantics.

## Verification

- `flutter analyze`
- `flutter build web`
