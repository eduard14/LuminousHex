# Lightcore Configuration Checklist

This is the working list of content and product configuration needed before the
prototype can become a shippable mobile build. It covers art, audio, ads,
premium currency, subscriptions, in-game store items, backend fields, and launch
setup.

The current prototype already uses custom paint, gradients, Material icons, and
mock store flows. Use this file as the replacement list for everything that
needs real assets, product IDs, prices, reward values, and live-service config.

## Monetization Decision

- Subscriptions are purchased directly through the platform stores.
- Every non-subscription purchase should use one premium currency.
- Working premium currency name: `Prism Shards`.
- Do not use direct real-money SKUs for passes, consumables, cosmetics, boosts,
  or bundles unless this decision changes.
- Keep `Flux` as a gameplay resource unless it is intentionally renamed into the
  premium currency. The current prototype spends Flux on manager forging, store
  conversions, and premium pass unlocks, so it needs a cleanup pass before
  launch.

## Suggested Asset Layout

These folders are not fully wired in `pubspec.yaml` yet. This is the intended
layout when real assets are added.

```text
assets/
  audio/
    music/
    sfx/
  images/
    ads/
    backgrounds/
    branding/
    cards/
    gear/
    store/
    ui/
  sprites/
    bosses/
    core/
    enemies/
    towers/
  vfx/
    impacts/
    payloads/
    projectiles/
```

## Asset Standards

| Type | Preferred Format | Source Target | Runtime Target | Notes |
| --- | --- | ---: | ---: | --- |
| Static UI art | PNG or WebP | 2x or 4x display size | Downscaled by Flutter | Use PNG for transparency-heavy UI. Use WebP for large backgrounds. |
| Sprite state | PNG or WebP | 512 x 512 | 64 to 220 px display | One centered subject with transparent padding. |
| Sprite sheet | PNG or WebP | 2048 x 512 or 2048 x 1024 | Frame-sliced | Use only where animation loops are needed. |
| Large backdrop | WebP | 2160 x 3840 portrait or 2048 x 2048 square | Cropped responsively | Keep important details inside center 70 percent. |
| Icons | PNG or SVG | 256 x 256 | 20 to 96 px display | Prefer simple silhouettes that read at tiny size. |
| Store art | PNG or WebP | 1024 x 1024 or 1600 x 900 | Product cards and promos | Include space for localized text overlays if needed. |
| Audio SFX | OGG, WAV source | 44.1 or 48 kHz | OGG in app | Short, compressed, no clipped peaks. |
| Music | OGG, WAV source | Loopable stereo | OGG in app | Export seamless loops plus stingers. |

## P0 Image Assets

These replace the most visible placeholders in the main menu, battle, header,
store, passes, and reward flows.

| Asset | Count | Source Size | Suggested Path | Description |
| --- | ---: | ---: | --- | --- |
| Lightcore wordmark | 1 | 2048 x 512 | `assets/images/branding/lightcore_wordmark.png` | Transparent logo for menu, loading, store, and marketing. |
| Lightcore crest | 1 | 1024 x 1024 | `assets/images/branding/lightcore_crest.png` | Main symbol used in menu, pass headers, and app identity. |
| Monochrome crest | 1 | 1024 x 1024 | `assets/images/branding/lightcore_crest_mono.png` | One-color version for overlays, loading, and small badges. |
| App icon master | 1 | 1024 x 1024 | `assets/images/branding/lightcore_app_icon_master.png` | Source for iOS and Android launcher icons. |
| Android adaptive icon foreground | 1 | 432 x 432 | `assets/images/branding/android_icon_foreground.png` | Keep core subject inside the 288 x 288 safe zone. |
| Android adaptive icon background | 1 | 432 x 432 | `assets/images/branding/android_icon_background.png` | Flat or gradient background layer. |
| Main menu hero backdrop | 1 | 2160 x 3840 | `assets/images/backgrounds/main_menu_hero.webp` | Portrait-first atmosphere behind the landing/menu CTA stack. |
| Main menu emblem overlay | 1 | 1024 x 1024 | `assets/images/backgrounds/main_menu_emblem.png` | Optional center motif behind the main buttons. |
| Battle arena backdrop | 1 | 2048 x 2048 | `assets/images/backgrounds/battle_arena.webp` | Square field under the Flame battle canvas. |
| Loading backdrop | 1 | 2160 x 3840 | `assets/images/backgrounds/loading_backdrop.webp` | Used while Firebase/bootstrap/game state initializes. |
| Core sprite set | 4 | 512 x 512 each | `assets/sprites/core/` | `idle`, `charged`, `overdrive`, `hit`. |
| Relay tower prism states | 7 families x 3 | 512 x 512 each | `assets/sprites/towers/` | White, Red, Yellow, Green, Purple, Orange, Blue. States: `idle`, `charging`, `ready`. |
| Projectile sprites | 10 | 512 x 512 each | `assets/vfx/projectiles/` | Starbolt, basic, fast, burst, chain, split, lance, explosion, ring, nova. |
| Payload status FX | 5 | 512 x 512 each | `assets/vfx/payloads/` | Burn, freeze, shock, knockback, bounty markers. |
| Hit and impact FX | 6 | 1024 x 1024 sheets | `assets/vfx/impacts/` | Normal hit, crit, bomb, laser, kill burst, apex burst. |
| Normal anomaly body families | 5 | 512 x 512 each | `assets/sprites/enemies/rarity_*.png` | One silhouette each for Basic, Uncommon, Rare, Epic, Legendary. |
| Anomaly affinity palettes | 8 | 256 x 256 swatches or overlays | `assets/sprites/enemies/palettes/` | White, Red, Yellow, Green, Purple, Orange, Blue, Black. |
| Apex Anomaly sprites | 14 | 1024 x 1024 each | `assets/sprites/bosses/` | Current mapped old-bible Apex seed names, starting with The Pale Equation, Huskstar Rex, Comet Khan, Parallax Jack, Mother Moss Nova, The Ion Warden, and The Gemini Maw. |
| Currency icons | 5 | 256 x 256 each | `assets/images/ui/currency/` | Lumens, Flux, Threat Scans, Apex Scans, Prism Shards. |
| Affinity glyphs | 8 | 256 x 256 each | `assets/images/ui/affinity/` | Clean faction/color symbol for every affinity, including Black anomaly glyphs. |
| Store tab icons | 5 | 256 x 256 each | `assets/images/store/tabs/` | Featured, Prism Shards, Passes, Boosts, Subscriptions. |
| Prism Shard product art | 6 | 1024 x 1024 each | `assets/images/store/currency/` | One pile/chest/beam visual per premium currency pack. |
| Subscription product art | 3 | 1600 x 900 each | `assets/images/store/subscriptions/` | Premium membership, ad-free, and offline/progression subscription cards. |
| Pass product art | 4 | 1600 x 900 each | `assets/images/store/passes/` | Daily Kill, Core Manager, Threat Director, Threat Scan premium pass cards. |
| Reward chest art | 4 | 1024 x 1024 each | `assets/images/ui/rewards/` | Common, rare, epic, legendary reward containers. |

## P1 Image Assets

These are the next layer once the app identity and core battle pass are in
place.

| Asset | Count | Source Size | Suggested Path | Description |
| --- | ---: | ---: | --- | --- |
| Anomaly card frame set | 5 | 1024 x 1280 each | `assets/images/cards/frames/` | One frame for each anomaly rarity. |
| Anomaly card portraits | 40 or modular | 1024 x 1280 each | `assets/images/cards/enemies/` | Old bible anomaly name roots with rarity treatments, starting with Dustling, Huskflare, Rushling, Blinkling, Mossmender, Jammer Cub, Splitling, and Wormguard. |
| Apex Anomaly card portraits | 14 | 1024 x 1280 each | `assets/images/cards/bosses/` | Current mapped old-bible Apex seed names, with higher-rarity Apex cards keeping rarity prefixes for preview clarity. |
| Core Manager crests | 40 | 512 x 512 each | `assets/images/cards/managers/tower/` | Bible manager roster, starting with Whitney Stardust, Reddie Mercury, Yella Nova, Greta Greenlight, Violet Vortex, Orion Orange, and Blueshift Aldrin. |
| Threat Director crests | 40 | 512 x 512 each | `assets/images/cards/managers/enemy/` | Bible threat roster, starting with Plain Jane Quasar, Count Huskula, Splinter Stella, Blink Floyd, Regenade Moss, Blue Screen Baron, Fastro Naut, and Grim Gravity. |
| Equipment set crests | 7 | 512 x 512 each | `assets/images/gear/sets/` | Surveyor, Ashspike, Embertrail, Sunplate, Thornpath, Tideglass, Voidloom. |
| Equipment slot base icons | 5 | 512 x 512 each | `assets/images/gear/slots/` | Hat, Top, Pants, Shoes, Accessory. |
| Equipment item icons | 35 or layered | 512 x 512 each | `assets/images/gear/items/` | Use 5 slot bases plus 7 set overlays for the first pass. |
| Navigation icon set | 8 | 256 x 256 each | `assets/images/ui/nav/` | Battle, Towers, Managers, Mentees, Mentors, Anomalies, Tournament, Advance. |
| Battle pass reward badges | 8 | 256 x 256 each | `assets/images/ui/rewards/` | Lumens, Flux, Prism Shards, Threat Scans, Core Manager, Threat Director, Anomaly Card, cosmetic. |
| Tournament banners | 3 | 1600 x 900 each | `assets/images/ui/tournaments/` | Anomaly Blitz, Hex Gauntlet, Arena Flow. |
| Friend relay emblem | 1 | 512 x 512 | `assets/images/ui/social/friend_relay.png` | Used on Friend Relay and alliance surfaces. |
| Guild crest | 1 | 512 x 512 | `assets/images/ui/social/guild_crest.png` | Used for guild creation, roster, and chat framing. |
| Shared tower blueprint | 1 | 1600 x 900 | `assets/images/ui/social/shared_tower_blueprint.webp` | Optional polish for Friend Relay. |
| Promotion burst art | 2 | 1600 x 900 each | `assets/images/ui/progression/` | Shell promotion and parent-slot forge reward moments. |
| Ad reward badge | 1 | 512 x 512 | `assets/images/ui/progression/reward_boost.png` | Visual for rewarded ad bonus prompts. |
| No-ads badge | 1 | 512 x 512 | `assets/images/store/no_ads_badge.png` | Used in subscription and upsell cards. |

## P2 Image Assets

These are polish or marketing assets. They should not block the first real asset
pass.

| Asset | Count | Source Size | Suggested Path | Description |
| --- | ---: | ---: | --- | --- |
| Loading sequence illustrations | 3 | 1600 x 900 each | `assets/images/ui/loading/` | Linking the relay, raising the tower, opening the gate. |
| Offline rewards panel art | 1 | 1600 x 900 | `assets/images/ui/progression/offline_rewards.png` | Startup claim modal polish. |
| Chat avatar frames | 3 | 512 x 512 each | `assets/images/ui/social/chat_frames/` | Guild leader, member, system framing. |
| Tutorial plate illustrations | 6 | 1600 x 900 each | `assets/images/ui/help/` | Economy, targeting, managers, promotion, passes, store. |
| Marketing key art | 3 | 2732 x 2048 each | `assets/images/branding/marketing/` | Store page, website, splash, trailer thumbnails. |
| Store screenshots | 6 to 10 | Platform sizes | external/store | App Store and Play Store screenshots. |
| Feature graphic | 1 | 1024 x 500 | external/store | Google Play feature graphic. |
| App preview poster frames | 3 | 1920 x 1080 | external/store | Thumbnail frames for optional preview videos. |

## P0 Sound Effects

Use short, distinct sounds with enough variation that repeated combat does not
become abrasive. Export app-ready files as OGG unless the platform pipeline
requires a different container.

| SFX | Count | Length | Suggested Path | Description |
| --- | ---: | ---: | --- | --- |
| UI tap | 2 | 0.05 to 0.12s | `assets/audio/sfx/ui_tap_*.ogg` | Light selectable tap variations. |
| UI confirm | 1 | 0.15s | `assets/audio/sfx/ui_confirm.ogg` | Positive commit action. |
| UI cancel/back | 1 | 0.12s | `assets/audio/sfx/ui_cancel.ogg` | Soft negative navigation. |
| Panel open | 1 | 0.2s | `assets/audio/sfx/ui_panel_open.ogg` | Sheet/modal opening shimmer. |
| Panel close | 1 | 0.15s | `assets/audio/sfx/ui_panel_close.ogg` | Sheet/modal closing motion. |
| Error/blocked | 1 | 0.2s | `assets/audio/sfx/ui_error.ogg` | Invalid spend, locked feature, unavailable ad. |
| Unlock | 1 | 0.45s | `assets/audio/sfx/ui_unlock.ogg` | Feature or slot unlock. |
| Reward claim | 2 | 0.35 to 0.7s | `assets/audio/sfx/reward_claim_*.ogg` | Small and big reward claims. |
| Relay charge | 2 | 0.25 to 0.45s | `assets/audio/sfx/relay_charge_*.ogg` | Tower reaches ready state. |
| Relay packet send | 2 | 0.15 to 0.3s | `assets/audio/sfx/relay_packet_*.ogg` | Packet handoff to the core queue. |
| Core fire | 9 | 0.15 to 0.5s | `assets/audio/sfx/core_fire_*.ogg` | One per projectile profile: basic, fast, burst, chain, split, lance, explosion, ring, nova. |
| Hit | 2 | 0.08 to 0.15s | `assets/audio/sfx/hit_*.ogg` | Normal impact variations. |
| Crit hit | 1 | 0.18s | `assets/audio/sfx/hit_crit.ogg` | Brighter impact for criticals. |
| Enemy death | 2 | 0.25 to 0.45s | `assets/audio/sfx/enemy_death_*.ogg` | Normal enemy defeat variations. |
| Boss hit | 1 | 0.18s | `assets/audio/sfx/boss_hit.ogg` | Heavy impact layer for bosses. |
| Boss spawn | 1 | 1.0s | `assets/audio/sfx/boss_spawn.ogg` | Warning arrival sound. |
| Boss death | 1 | 1.5s | `assets/audio/sfx/boss_death.ogg` | Large payout and victory moment. |
| Enemy spawn | 2 | 0.2 to 0.35s | `assets/audio/sfx/enemy_spawn_*.ogg` | Small portal/singularity arrivals. |
| Enemy split | 1 | 0.25s | `assets/audio/sfx/enemy_split.ogg` | Split-on-death enemy behavior. |
| Lane jam warning | 1 | 0.35s | `assets/audio/sfx/pressure_lane_jam.ogg` | Enemy reaches the relay ring. |
| High pressure warning | 1 | 0.55s | `assets/audio/sfx/pressure_high.ogg` | Swarm pressure is high. |
| Tower build | 1 | 0.35s | `assets/audio/sfx/build_tower.ogg` | New relay prism anchors. |
| Tower upgrade | 1 | 0.3s | `assets/audio/sfx/build_upgrade.ogg` | Tower level increases. |
| Sell/dismantle | 1 | 0.25s | `assets/audio/sfx/build_dismantle.ogg` | Tower or manager dismantled. |
| Ticket pull | 1 | 0.45s | `assets/audio/sfx/reward_ticket_pull.ogg` | Threat Scan starts. |
| Rarity reveal | 5 | 0.35 to 0.8s | `assets/audio/sfx/reveal_*.ogg` | Basic, Uncommon, Rare, Epic, Legendary reveal sounds. |
| Flux reward | 1 | 0.35s | `assets/audio/sfx/reward_flux.ogg` | Gameplay Flux earned. |
| Prism Shard reward | 1 | 0.45s | `assets/audio/sfx/reward_prism_shard.ogg` | Premium currency added or purchase credited. |
| Equipment drop | 1 | 0.5s | `assets/audio/sfx/reward_equipment.ogg` | Gear reward lands. |
| Battle pass claim | 1 | 0.65s | `assets/audio/sfx/reward_pass_claim.ogg` | Free or premium pass reward claimed. |
| Store purchase success | 1 | 0.8s | `assets/audio/sfx/store_purchase_success.ogg` | IAP or Prism Shard spend succeeds. |
| Store purchase failed | 1 | 0.25s | `assets/audio/sfx/store_purchase_failed.ogg` | Cancelled, failed, or already-owned purchase. |
| Rewarded ad earned | 1 | 0.7s | `assets/audio/sfx/ad_reward_earned.ogg` | Ad completes and reward is granted. |
| Overdrive start | 1 | 0.6s | `assets/audio/sfx/overdrive_start.ogg` | Manual overdrive begins. |
| Overdrive end | 1 | 0.45s | `assets/audio/sfx/overdrive_end.ogg` | Manual overdrive ends. |
| Promotion complete | 1 | 1.6s | `assets/audio/sfx/promotion_complete.ogg` | Shell promotion or parent slot forge. |

## Music

| Track | Count | Length | Suggested Path | Description |
| --- | ---: | ---: | --- | --- |
| Main menu loop | 1 | 60 to 120s | `assets/audio/music/main_menu_loop.ogg` | Slow, atmospheric, high-tech identity. |
| Battle loop | 1 | 90 to 180s | `assets/audio/music/battle_loop.ogg` | Neutral combat groove for long sessions. |
| Boss escalation loop | 1 | 45 to 90s | `assets/audio/music/boss_loop.ogg` | Layered when boss cycle starts or peaks. |
| Tournament loop | 1 | 90 to 180s | `assets/audio/music/tournament_loop.ogg` | More competitive and urgent. |
| Store loop | 1 | 60 to 120s | `assets/audio/music/store_loop.ogg` | Optional calmer loop for shop/pass screens. |
| Reward stinger | 1 | 2 to 4s | `assets/audio/music/reward_stinger.ogg` | Big reward, promotion, rank payout. |

## Ad Configuration

The app currently initializes Google Mobile Ads and has rewarded ads wired for
Android and iOS. Production ad unit IDs should come from remote config or a
build-time config file, not hardcoded test IDs.

| Placement | Type | P0? | Reward or Behavior | Cooldown / Cap | Required Config |
| --- | --- | --- | --- | --- | --- |
| Offline claim doubler | Rewarded | Yes | Grants the same offline bundle a second time. | 1 per offline claim. | Android ad unit, iOS ad unit, enabled flag, reward multiplier. |
| Threat Scan top-off | Rewarded | Yes | Grants `+5 Threat Scans`. | Daily cap 5, cooldown 5 min. | Ad unit IDs, grant amount, daily cap, cooldown. |
| Foundry Flux top-off | Rewarded | Yes | Grants enough Flux or a fixed Flux amount when short on manager forging. | Daily cap 5, cooldown 5 min. | Ad unit IDs, grant amount, max grant, eligibility rule. |
| Prism Shard daily drip | Rewarded | Optional | Grants a small premium currency amount. | Daily cap 1 to 3. | Use carefully. Configure server validation and fraud limits. |
| Post-tournament break | Interstitial | No | Shows after a completed run, never during battle. | Frequency cap 1 per 10 min. | Interstitial unit IDs, subscription/ad-free suppression. |
| Session return break | Interstitial | No | Shows after returning from background if enough time passed. | Frequency cap 1 per session. | Interstitial unit IDs, session timing rule. |
| Store promo banner | Native/banner | No | Optional cross-promo card in store only. | No battle banners. | Native/banner unit IDs, placement enable flag. |

Ad suppression rules:

- Disable all forced/interstitial ads for any active no-ads subscription.
- Rewarded ads can remain available to subscribers if they voluntarily opt in.
- Never show interstitials during battle, a purchase flow, tutorial steps, or
  immediately after a failed purchase.
- Every rewarded ad prompt must disclose the reward before launch.
- Server should validate ad reward claims or rate-limit them by player ID.

Production IDs to configure:

| Platform | Rewarded Unit ID | Interstitial Unit ID | Native/Banner Unit ID | Notes |
| --- | --- | --- | --- | --- |
| Android | TBD | TBD | TBD | Replace current Google sample rewarded ID before release. |
| iOS | TBD | TBD | TBD | Replace current Google sample rewarded ID before release. |

## Premium Currency

Working name: `Prism Shards`.

| Field | Value To Configure | Notes |
| --- | --- | --- |
| Display name | Prism Shards | Rename later if needed. |
| Short name | Shards | Used in compact header/UI. |
| Icon | `assets/images/ui/currency/prism_shard.png` | Needs to read at 20 px. |
| Spend model | Hard currency | Bought through IAP packs, earned sparingly from events/rewarded ads. |
| Server authority | Required | Balance and ledger should be server-authoritative for real-money value. |
| Refund handling | Required | Revoke unspent currency or flag account on refunded purchases. |
| Analytics name | `prism_shards` | Use one stable event/property name. |

Suggested use:

- Unlock premium battle pass tracks.
- Buy limited bundles.
- Buy cosmetics.
- Buy boosters.
- Buy extra Threat Scans.
- Buy manager forge tokens or manager packs.
- Buy tournament reruns or bonus entries only if the design remains fair.

Avoid:

- Selling direct power with no cap.
- Making pass rewards pay back more premium currency than the pass costs unless
  that is an intentional retention design.
- Letting client-only save data own premium balances.

## Platform Store Products

Only subscriptions and premium currency packs should be real-money products
under the current monetization decision.

### Subscriptions

Each subscription should be configured as its own platform product. These are
not bought with Prism Shards.

| Product ID | Name | Billing | Benefits To Configure | Notes |
| --- | --- | --- | --- | --- |
| `lightcore_premium_monthly` | Lightcore Premium Monthly | Monthly | No forced ads, longer offline cap, daily Prism Shards, premium profile badge. | Current mocked `Premium Membership` can map here. |
| `lightcore_premium_yearly` | Lightcore Premium Yearly | Yearly | Same as monthly with yearly pricing. | Optional but common. |
| `lightcore_no_ads_monthly` | No-Ads Monthly | Monthly | Suppress forced/interstitial ads only. | Optional separate lower-price subscription. |
| `lightcore_offline_plus_monthly` | Offline Plus Monthly | Monthly | Increased offline claim cap and passive income cap. | Optional. Keep separate only if you want individual subscriptions. |

Subscription config checklist:

- App Store product IDs.
- Google Play product IDs.
- Price tier per region.
- Intro offer and free trial policy.
- Grace period and billing retry behavior.
- Server receipt validation.
- Entitlement mapping in player profile.
- Restore purchases flow.
- Expiration handling.
- UI copy for active, expired, billing retry, and cancelled states.

### Premium Currency Packs

These are real-money IAP products that grant Prism Shards.

| Product ID | Name | Prism Shards | Bonus | Art | Notes |
| --- | --- | ---: | ---: | --- | --- |
| `prism_shards_080` | Spark Pack | 80 | 0 | `store/currency/spark_pack.png` | Entry pack. |
| `prism_shards_240` | Prism Pack | 240 | 10 | `store/currency/prism_pack.png` | Small popular pack. |
| `prism_shards_550` | Core Pack | 550 | 50 | `store/currency/core_pack.png` | Mid pack. |
| `prism_shards_1200` | Relay Cache | 1200 | 180 | `store/currency/relay_cache.png` | Large pack. |
| `prism_shards_2500` | Nexus Cache | 2500 | 500 | `store/currency/nexus_cache.png` | Whale-safe upper pack. |
| `prism_shards_6500` | Ascendant Vault | 6500 | 1800 | `store/currency/ascendant_vault.png` | Highest pack. |

Currency pack config checklist:

- App Store consumable product IDs.
- Google Play consumable product IDs.
- Localized title and description.
- Regional price tier.
- First-purchase bonus flag if used.
- Receipt validation.
- Grant ledger entry.
- Duplicate transaction protection.
- Refund/revocation behavior.

## In-Game Store Items Bought With Prism Shards

These are not direct platform SKUs. They are live-service catalog entries bought
with Prism Shards after the player has a balance.

### Passes

| Store ID | Name | Cost | Unlocks | Current Prototype Reference |
| --- | --- | ---: | --- | --- |
| `pass_daily_kills_premium` | Daily Kill Premium Track | 120 | Premium rewards on the daily kill pass for the active day. | Prototype now spends Prism Shards. |
| `pass_tower_manager_premium` | Core Manager Premium Track | 90 | Premium rewards on the static Core Manager pass. | Prototype now spends Prism Shards. |
| `pass_enemy_manager_premium` | Threat Director Premium Track | 90 | Premium rewards on the static Threat Director pass. | Prototype now spends Prism Shards. |
| `pass_threat_scan_premium` | Threat Scan Premium Track | 90 | Premium rewards on the static Threat Scan pass. | Prototype now spends Prism Shards. |
| `pass_season_premium` | Seasonal Premium Track | TBD | Future longer season track. | Add only when seasonal pass exists. |

Pass config checklist:

- Cost in Prism Shards.
- Season key or reset cadence.
- Free reward track.
- Premium reward track.
- Claim rules.
- Expiration rules.
- Purchase confirmation copy.
- Refund behavior.
- Any remaining Flux-priced store references to migrate.

### Consumables

| Store ID | Name | Cost | Grants | Notes |
| --- | --- | ---: | --- | --- |
| `bundle_lumens_small` | Small Lumen Cache | 35 | 500 Lumens | Prototype weekly cap: 3. Keep scaling based on player progression. |
| `bundle_lumens_medium` | Medium Lumen Cache | 90 | 1,500 Lumens | Prototype weekly cap: 2. Avoid static values becoming useless. |
| `bundle_lumens_large` | Large Lumen Cache | TBD | Lumens | Use server-calculated grants. |
| `bundle_threat_scans_05` | 5 Threat Scans | 45 | 5 Threat Scans | Prototype weekly cap: 5. Replaces direct Flux conversion. |
| `bundle_threat_scans_15` | 15 Threat Scans | 120 | 15 Threat Scans | Prototype weekly cap: 3. Match current prototype bundle shape. |
| `bundle_threat_scans_30` | 30 Threat Scans | TBD | 30 Threat Scans | Match current prototype bundle shape. |
| `bundle_tower_manager_pull` | Core Manager Forge Token | TBD | 1 core manager forge | Alternative to spending gameplay Flux. |
| `bundle_enemy_manager_pull` | Threat Director Forge Token | TBD | 1 threat director forge | Alternative to spending gameplay Flux. |
| `bundle_echo_seed` | Echo Seed | TBD | 1 Echo Seed | Use only after Echo Seeds are fully surfaced. |
| `bundle_boss_scans` | Apex Scan Cache | TBD | Apex Scans | Only if Apex Scans get a real sink. |

### Boosts

| Store ID | Name | Cost | Duration | Effect |
| --- | --- | ---: | ---: | --- |
| `boost_lumen_2x_30m` | Lumen Surge | TBD | 30 min | 2x active Lumen gains. |
| `boost_flux_2x_30m` | Flux Surge | TBD | 30 min | 2x gameplay Flux gains. |
| `boost_scan_drop_30m` | Scanner Surge | TBD | 30 min | Increased Threat Scan drops. |
| `boost_offline_24h` | Offline Amplifier | TBD | 24 h | Increased offline claim cap or rate. |
| `boost_overdrive_refill` | Overdrive Refill | TBD | Instant | Refills or extends manual overdrive. |

Boost config checklist:

- Stacking rule.
- Pause/offline behavior.
- Server timestamp source.
- Battle-only or global effect.
- Subscription interaction.
- UI timer copy.

### Account Upgrades

| Store ID | Name | Cost | Unlocks | Notes |
| --- | --- | ---: | --- | --- |
| `account_permanent_overdrive` | Permanent Overdrive | 240 | Always-on X1.50 live battle speed. | One-time Prism Shard unlock. Not a direct platform SKU. |

### Cosmetics

| Store ID | Name | Cost | Type | Art Needed |
| --- | --- | ---: | --- | --- |
| `cosmetic_core_skin_nebula` | Nebula Core | TBD | Core skin | Core sprite set. |
| `cosmetic_tower_skin_obsidian` | Obsidian Relay Set | TBD | Tower skin set | 7 tower family states. |
| `cosmetic_projectile_pack_starlace` | Starlace Projectiles | TBD | Projectile skin set | 9 projectile sprites. |
| `cosmetic_profile_frame_founder` | Founder Frame | TBD | Profile frame | UI frame art. |
| `cosmetic_guild_banner_solar` | Solar Guild Banner | TBD | Guild banner | Guild/social art. |

Cosmetic config checklist:

- Ownership flag.
- Equip slot.
- Preview art.
- Refund behavior.
- Whether cosmetics are account-wide.

### Bundles

| Store ID | Name | Cost | Contents | Notes |
| --- | --- | ---: | --- | --- |
| `bundle_starter_relay_cache` | Starter Relay Cache | 90 | 2,000 Lumens, 25 Flux, 6 Threat Scans | Prototype weekly cap: 1. Purchased with Prism Shards, not direct money. |
| `bundle_manager_foundry` | Manager Foundry Bundle | TBD | Core manager forge, threat director forge, Flux | Unlock only after managers unlock. |
| `bundle_battle_ready` | Battle Ready Bundle | TBD | Boosts, Threat Scans, Lumens | Rotate weekly if used. |
| `bundle_tournament_weekly` | Weekly Tournament Bundle | TBD | Entry boosts or reruns, cosmetics | Avoid pay-to-win leaderboard pressure. |

Bundle config checklist:

- Visibility conditions.
- Purchase limit.
- Reset cadence.
- Discount display rule.
- Contents ledger.
- Art and localized copy.

## Battle Pass Configuration

Current implemented pass types:

| Type | Cadence | Progress | Existing Premium Cost | Current Rewards |
| --- | --- | --- | ---: | --- |
| Daily Kill Pass | Daily reset | Kills | 120 Flux | Flux and Threat Scans. |
| Core Manager Pass | Static | Core Manager pulls | 90 Flux | Flux and Threat Scans. |
| Threat Director Pass | Static | Threat Director pulls | 90 Flux | Flux and Threat Scans. |
| Threat Scan Pass | Static | Threat Scans | 90 Flux | Flux and Threat Scans. |

Migration target:

- Premium costs become Prism Shard costs.
- Pass rewards should be reviewed so premium tracks do not primarily return the
  same currency used to buy them unless that is intentional.
- Daily pass reset should be server-keyed, not based only on local device date.
- Static passes need version keys so reward tables can change without breaking
  existing claims.

Fields to configure for each pass:

- Pass ID.
- Display name.
- Start and end time.
- Reset cadence.
- Premium unlock cost in Prism Shards.
- Progress source.
- Tier goals.
- Free reward table.
- Premium reward table.
- Claim availability.
- Backfill rules after purchase.
- Art banner.
- Store card art.
- Analytics event names.

## Backend And Remote Config

| Area | Required Config |
| --- | --- |
| IAP validation | App Store shared secret or StoreKit 2 validation setup, Google Play service account, server receipt validation endpoint. |
| Entitlements | Subscription state, no-ads state, offline-plus state, premium membership state. |
| Premium currency | Server-owned balance, transaction ledger, duplicate transaction guard, refund/reversal handling. |
| Store catalog | Product IDs, prices, visible dates, purchase limits, grants, art paths, localization keys. |
| Pass catalog | Season keys, tier tables, unlock costs, reset times, reward tables. |
| Ad rewards | Placement IDs, grant amounts, caps, cooldowns, server-side claim ledger. |
| Remote config | Feature flags for store, ads, subscriptions, passes, premium currency, cosmetics, boosts. |
| Save integrity | Add premium currency and entitlement fields to sanitizer and anomaly logs. |
| Time authority | Server reset time for daily pass, daily ad caps, daily subscription grants. |
| Privacy | Consent flow, ad personalization flags, account deletion path, purchase support copy. |

## Analytics Events

| Event | When |
| --- | --- |
| `store_opened` | Store sheet/screen opens. |
| `store_product_viewed` | Player views a product detail/card. |
| `iap_started` | Platform purchase starts. |
| `iap_completed` | Platform purchase succeeds and server grant completes. |
| `iap_failed` | Platform purchase fails or is cancelled. |
| `prism_shards_granted` | Premium currency balance increases. |
| `prism_shards_spent` | Premium currency is spent on an in-game item. |
| `subscription_started` | Subscription entitlement becomes active. |
| `subscription_restored` | Restore purchases succeeds. |
| `subscription_expired` | Entitlement expires or lapses. |
| `pass_premium_unlocked` | Premium pass track is purchased. |
| `pass_reward_claimed` | Any pass reward is claimed. |
| `ad_prompt_shown` | Rewarded ad prompt is shown. |
| `ad_started` | Ad starts. |
| `ad_reward_granted` | Rewarded ad finishes and reward is granted. |
| `ad_unavailable` | Ad placement is unavailable. |
| `bundle_purchased` | In-game bundle bought with Prism Shards. |
| `boost_started` | Boost is activated. |
| `cosmetic_equipped` | Cosmetic is equipped. |

## Product Copy To Write

| Surface | Copy Needed |
| --- | --- |
| Store landing | Short explanation of Prism Shards, subscriptions, passes, and ad rewards. |
| Premium currency packs | Title, short description, bonus copy, legal disclaimer. |
| Subscription cards | Benefits, renewal note, cancellation note, restore copy. |
| Pass cards | Reset cadence, premium unlock copy, reward claim copy. |
| Ad prompts | Reward amount, completion requirement, unsupported-platform message. |
| Purchase confirmations | Spend amount, item granted, irreversible/limited copy if needed. |
| Purchase failures | Cancelled, network error, validation failed, already owned. |
| Refund/support | Where to get purchase support and what happens after refund. |
| Privacy/consent | Ad personalization, analytics, account deletion. |

## Implementation Cleanup Checklist

- Add `Prism Shards` to currency labels, save payloads, backend sanitizer, and
  UI headers.
- Decide whether `Flux` stays gameplay-only. If yes, remove Flux from premium
  pass unlocks and non-gameplay store purchases.
- Replace `unlockPremiumBattlePass(... fluxCost)` with a premium-currency spend
  path.
- Replace `buyLumensWithFlux` and `buyEnemyPullsWithFlux` store buttons with
  Prism Shard catalog entries or keep them as gameplay exchange only.
- Add server-authoritative premium currency ledger before enabling real money.
- Move ad unit IDs to remote config or build config.
- Add restore purchases UI and backend entitlement refresh.
- Add subscription expiration handling.
- Add store catalog loading with safe local fallback.
- Add localized strings for every product and ad prompt.
- Add tests for pass purchase, currency spend, subscription entitlement, ad caps,
  refund/reversal, and restore purchases.

## Concrete First Pass

If you want the smallest batch that changes the product feel and unblocks
store/pass setup, start with this:

- 1 wordmark.
- 1 crest.
- 1 app icon master.
- 1 menu background.
- 1 battle background.
- 1 core sprite set.
- 6 tower prism sprite sets.
- 9 projectile sprites.
- 5 payload FX sprites.
- 6 impact FX sprites.
- 5 enemy rarity body sprites.
- 7 enemy color palettes.
- 7 boss sprites.
- 5 currency icons, including Prism Shards.
- 7 affinity glyphs.
- 12 to 16 essential SFX.
- 2 music loops.
- Rewarded ad production unit IDs.
- Premium currency product IDs.
- One monthly premium subscription SKU.
- Four premium pass catalog entries using Prism Shards.
- Backend ledger fields for premium currency and subscriptions.
