# Flutter Tests

Put Flutter unit, widget, and gameplay regression tests here.

## Naming

- Use `*_test.dart` so `flutter test` discovers the file.
- Prefer focused names such as `battle_screen_controller_swap_test.dart` or
  `lightcore_controller_save_restore_test.dart`.

## Scope

- Keep pure model/controller tests small and deterministic.
- Use widget tests for screen behavior, layout state, semantics, and callbacks.
- Add regression tests beside bug fixes when the behavior can be reproduced
  without a full device run.
