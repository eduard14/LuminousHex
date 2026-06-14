# Runtime Assets

Flutter loads runtime assets from this directory. Keep generated and production
assets here instead of `lib/` so source search and code reviews stay clean.

## Folders

- `Images/`: menu backgrounds, logos, loading art, and other non-sprite images.
- `audio/music/`: looping music beds.
- `audio/sfx/`: short interface and battle sound effects.
- `guides/`: guide character portraits.
- `sprites/avatar/`: player avatar base, hair, and face layers.
- `sprites/bosses/`: boss art grouped by rarity.
- `sprites/enemies/`: enemy art grouped by color family.
- `sprites/equipment/`: equipment layer art grouped by set.
- `sprites/managers/`: core and threat manager portraits.

## Naming

Use lower_snake_case for new assets. Avoid timestamps, spaces, and temporary
tool names in final paths. When an asset path changes, update `pubspec.yaml`,
all Dart string references, and the relevant docs under `docs/`.
