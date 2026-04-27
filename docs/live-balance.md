# Live Balance Tuning

LumiHex uses server-published balance tuning as a thin multiplier layer over
the checked-in tower, enemy, and economy defaults. The client always keeps the
bundled defaults as a fallback.

## Storage

- `runtime/clientManifest` remains the launch/version gate.
- `runtime/balanceManifest` stores live balance overrides.
- Clients do not read either document directly. The `bootstrapClient` callable
  loads both documents, sanitizes them, and returns one trusted manifest.
- Firestore rules keep `runtime/*` unreadable and unwritable from clients.

## Balance Manifest Shape

```json
{
  "balanceEpoch": 12,
  "active": true,
  "maxSingleStatDelta": 0.05,
  "maxCumulativeStatDelta": 0.25,
  "towerMultipliers": {
    "cyan_prism": {
      "basePower": 0.98,
      "baseCooldown": 1.02
    }
  },
  "enemyMultipliers": {
    "green_basic": {
      "baseSpeed": 0.97,
      "reward": 1.03
    }
  },
  "economyMultipliers": {
    "lumenReward": 1.02,
    "threatScanReward": 1.04
  },
  "previousTowerMultipliers": {},
  "previousEnemyMultipliers": {},
  "previousEconomyMultipliers": {}
}
```

`previous*Multipliers` are optional, but should be copied from the last live
manifest before a weekly update. The callable clamps each new stat against the
previous value by `maxSingleStatDelta`, then clamps the total value against
`maxCumulativeStatDelta` from the bundled baseline.

## Caps

- `maxSingleStatDelta` is server-clamped to `0.05`, so a weekly step cannot move
  a single multiplier by more than 5 percent from its previous value.
- `maxCumulativeStatDelta` is server-clamped to `0.25`, so remote tuning cannot
  move a single multiplier more than 25 percent from the bundled baseline.
- The Dart client repeats cumulative clamping as a second safety net.
- Unknown stat names are ignored by the callable.

## Supported Stats

Tower stats:
`buildCost`, `basePower`, `baseChargeRate`, `baseCooldown`,
`baseGenerationSpeed`, `baseCritChance`, `baseCritMultiplier`,
`coreCooldownMultiplier`, `jamHitMultiplier`, `jamDecayMultiplier`,
`lumenPressureGuard`, `affinityBonusMultiplier`.

Enemy stats:
`baseHealth`, `baseDefense`, `baseSpeed`, `reward`, `baseExperience`,
`jamStrength`, `baseSpiralDrift`.

Economy stats:
`lumenReward`, `fluxReward`, `threatScanReward`, `experienceReward`,
`passiveLumens`, `offlineKills`.

## Weekly Workflow

1. Export weekly balance telemetry grouped by `balanceEpoch`.
2. Run deterministic local balance simulations against the proposed manifest.
3. Copy current live multipliers into the matching `previous*Multipliers`.
4. Publish small changes to `runtime/balanceManifest` and increment
   `balanceEpoch`.
5. Verify startup logs show the expected sanitized epoch and rollback by setting
   `active: false` or restoring the previous document.
