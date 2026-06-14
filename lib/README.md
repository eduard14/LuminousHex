# Flutter Source Map

`lib/` contains Dart source only. Runtime images, audio, and generated visual
assets belong under `assets/` so source searches stay focused on code.

## Runtime Flow

1. `main.dart` selects the app surface: event preview, web preview, or the full
   game.
2. `app/lightcore_app.dart` bootstraps Firebase/local fallback, restores session
   preferences, creates `LightcoreController`, and owns cloud-sync timers.
3. `state/lightcore_controller.dart` is the local gameplay authority. Its part
   files split battle, rewards, save/restore, progression, and inventory logic.
4. `screens/` present controller state and call controller command methods.
5. `battle/` renders the active battlefield through Flame.

## Directory Roles

- `app/`: app bootstrap, build info, dev flags, preview wrappers, and session
  orchestration.
- `battle/`: Flame game objects, battlefield drawing, projectile visuals, and
  promotion presentation.
- `data/`: static gameplay configuration for towers, cards, enemies, equipment,
  medals, traits, and threat regions.
- `models/`: immutable or serializable gameplay, social, cloud-save, tournament,
  avatar, and progression types.
- `screens/`: full-screen Flutter surfaces. Feature subfolders hold private
  widgets for larger screens.
- `services/`: platform and external-service boundaries such as Firebase, audio,
  ads, session storage, and web foreground/refresh hooks.
- `state/`: mutable gameplay authority and controller part files.
- `theme/`: palette, icon, and theme definitions.
- `widgets/`: reusable UI components shared across screens.

## Placement Rules

- Put gameplay mutations in `LightcoreController` or a focused controller part.
- Put shared UI in `widgets/`; keep screen-only helpers under the screen folder.
- Put Firebase/package integrations behind `services/`.
- Add comments at ownership boundaries and non-obvious algorithms, not beside
  every assignment.
