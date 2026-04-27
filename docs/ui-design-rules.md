# Lightcore UI Design Rules

This document is the default reference for future UI changes. The goal is clarity, consistency, and fewer moving parts.

## Core Rules

- Navigation lives in one place. Do not duplicate the same destinations in multiple UI regions.
- The bottom menu stays at the bottom of the base game and uses icons only. No visible text labels.
- If a screen is opened from the bottom menu, do not recreate that menu at the top as buttons, chips, or segmented controls.
- If something is not a true tab set, do not fake tabs with buttons.
- Tournaments are a separate screen. Open it, do the tournament work there, and use one return action to go back to the base game.
- Do not move existing actions to a second location unless the original location is removed in the same change.

## Layout Rules

- Prefer one primary surface per screen region.
- Avoid panel-inside-panel styling unless the inner panel adds real functional grouping.
- Use decoration sparingly. Do not add extra gradients, borders, or glow treatments just to make a screen feel "designed."
- Reuse spacing and structure before introducing new wrappers or containers.
- Keep top bars simple: title, essential actions, return action.

## Copy Rules

- Keep labels short.
- Do not restate navigation structure in body copy.
- Avoid explanatory filler when the screen content already makes the function obvious.
- Use words only where they add meaning; icons and structure should carry the rest.

## Navigation Model

- Base game: battle view plus the persistent bottom menu.
- Management screens: focused views opened from the bottom menu, with no mirrored navigation inside the screen.
- Tournament screen: focused view opened from the bottom menu, with no mirrored navigation inside the screen.
- Header actions: utilities and top-level social actions only. They should not duplicate bottom-menu destinations.

## Change Checklist

Before shipping a UI change, verify all of the following:

- No destination appears in multiple places.
- No menu changes position between related screens.
- The bottom menu remains icon-only.
- The screen can be understood without extra descriptive containers.
- New UI chrome was added only when it solved a functional problem.
