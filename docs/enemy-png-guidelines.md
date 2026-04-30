# Enemy PNG Guidelines

LumiHex expects many enemy images over time, so enemy art should be prepared as
runtime assets rather than untouched source exports. Keep layered/source files
outside the Flutter asset bundle and ship only optimized runtime images.

## Recommended Runtime Sizes

| Use | Runtime Size | Notes |
| --- | ---: | --- |
| Normal enemy sprite | 768 x 768 PNG | Best default for transparent enemy bodies. |
| Small/simple enemy sprite | 512 x 512 PNG | Use when the silhouette reads clearly at card size. |
| Apex/boss sprite | 1024 x 1024 PNG | Use for larger enemies and reveal moments. |
| Card portrait crop | 1024 x 1280 PNG or WebP | Separate from battle sprites if card art needs framing. |
| Large background | WebP | Use WebP for non-transparent full-screen art. |

Avoid shipping 1500 px or larger transparent PNGs for normal enemies unless the
asset is a boss or is reused in a full-screen reveal. A 1254 x 1254 RGBA image
decodes to about 6 MB in memory before Flutter draws it, even if it displays at
80-200 px.

## File Format

- Use PNG for enemies that need transparency.
- Use WebP for opaque backgrounds, banners, and large card art.
- Export 8-bit/channel sRGB.
- Trim empty transparent padding, but keep a consistent subject safe zone.
- Prefer indexed/optimized PNG only if edges still look clean.
- Do not ship source PSD, Procreate, Krita, or huge generation exports in
  `assets/`.

## Sprite Composition

For battle sprites:

- Canvas should usually be square.
- Subject should fit inside the middle 80-88 percent of the canvas.
- Leave enough transparent padding for glow, bobbing, and health rings.
- Face/front direction should be consistent across a family.
- Keep silhouettes readable at 48 px, 96 px, and 160 px.
- Avoid baked text, UI frames, rarity labels, and heavy background effects.

Recommended naming once the asset tree is reorganized:

```text
assets/sprites/enemies/red/basic.png
assets/sprites/enemies/red/uncommon.png
assets/sprites/enemies/red/rare.png
assets/sprites/enemies/red/epic.png
assets/sprites/enemies/red/legendary.png
assets/sprites/bosses/red/apex_name.png
```

The current prototype maps runtime enemy art from `assets/sprites/`.

## Animation Direction

Prefer in-engine animation for most enemies:

- idle bob
- subtle scale pulse
- rotation or drift
- hit flash
- spawn/reveal glow
- low-health shake or tint

This keeps download size low because one PNG can produce many motion states.
Avoid animated PNG/APNG or GIF-style frame exports for normal enemies.

Use sprite sheets only for high-value moments:

- Apex/boss intro
- death burst
- rare summon/reveal
- store/premium cosmetic preview

If using a sprite sheet, keep it short:

- 6-12 frames for normal loops
- 12-24 frames for boss/reveal moments
- power-of-two sheet dimensions when practical, such as `2048 x 512` or
  `2048 x 1024`
- no more than one or two active animated sheets on screen at once

## Delivery Checklist

For each new enemy family, provide:

- optimized runtime PNGs at the target size
- source/master file kept outside `assets/`
- affinity and rarity in the filename or folder path
- transparent background for battle sprites
- one still image first before any animation sheet
- optional notes for intended motion, such as "slow hover" or "jittery blink"

The safest production path is static enemy PNGs first, then add in-engine
motion presets. Add sprite sheets later only where the game clearly benefits
from authored animation.
