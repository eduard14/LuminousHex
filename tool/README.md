# Local Tooling

This folder contains one-off scripts for generating, cropping, and importing
LumiHex visual assets.

- `crop_openai_manager_portraits.py`: crops generated manager portrait sheets.
- `generate_avatar_cosmetic_pngs.py`: creates avatar cosmetic PNG layers.
- `import_openai_avatar_assets.py`: imports generated avatar assets into the
  runtime asset tree.

These scripts are not part of the game runtime. Keep script outputs under
`assets/` and update [docs/assets-needed.md](../docs/assets-needed.md) when an
asset need is completed or materially changed.
