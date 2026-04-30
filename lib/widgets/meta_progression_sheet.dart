import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lightcore_currency_labels.dart';
import '../models/lightcore_progression.dart';
import '../models/lightcore_types.dart';
import '../services/lightcore_firebase_backend.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_icons.dart';
import '../theme/lightcore_palette.dart';
import 'aurora_panel.dart';
import 'status_pill.dart';

part 'meta_progression/store_sheet.dart';
part 'meta_progression/battle_pass_sheet.dart';
part 'meta_progression/battle_pass_picker_widgets.dart';
part 'meta_progression/battle_pass_track_widgets.dart';
part 'meta_progression/battle_pass_helpers.dart';

const int _permanentOverdrivePrismCost = 240;
const int _radianceStatResetPrismCost =
    LightcoreController.radianceStatResetPrismShardCost;
const String _starterRelayCacheId = 'bundle_starter_relay_cache';
const String _smallLumenCacheId = 'bundle_lumens_small';
const String _mediumLumenCacheId = 'bundle_lumens_medium';
const String _threatScanFiveId = 'bundle_threat_scans_05';
const String _threatScanFifteenId = 'bundle_threat_scans_15';

const List<_PrismShardPackDefinition> _prismShardPacks =
    <_PrismShardPackDefinition>[
      _PrismShardPackDefinition(
        productId: 'prism_shards_080',
        title: 'Spark Pack',
        subtitle: 'Entry Prism Shard pack for a small unlock.',
        baseAmount: 80,
        bonusAmount: 0,
        priceLabel: r'$0.99',
        badgeLabel: 'Entry',
      ),
      _PrismShardPackDefinition(
        productId: 'prism_shards_240',
        title: 'Prism Pack',
        subtitle: 'Small shard pack with a light bonus.',
        baseAmount: 240,
        bonusAmount: 10,
        priceLabel: r'$2.99',
        badgeLabel: 'Popular',
      ),
      _PrismShardPackDefinition(
        productId: 'prism_shards_550',
        title: 'Core Pack',
        subtitle: 'Mid-size pack for pass tracks and capped bundles.',
        baseAmount: 550,
        bonusAmount: 50,
        priceLabel: r'$6.99',
        badgeLabel: 'Core',
      ),
      _PrismShardPackDefinition(
        productId: 'prism_shards_1200',
        title: 'Relay Cache',
        subtitle: 'Large shard cache with a stronger bonus.',
        baseAmount: 1200,
        bonusAmount: 180,
        priceLabel: r'$14.99',
        badgeLabel: 'Large',
      ),
      _PrismShardPackDefinition(
        productId: 'prism_shards_2500',
        title: 'Nexus Cache',
        subtitle: 'High-capacity shard cache for planned purchases.',
        baseAmount: 2500,
        bonusAmount: 500,
        priceLabel: r'$29.99',
        badgeLabel: 'Value',
      ),
      _PrismShardPackDefinition(
        productId: 'prism_shards_6500',
        title: 'Ascendant Vault',
        subtitle: 'Highest Prism Shard pack in the launch catalog.',
        baseAmount: 6500,
        bonusAmount: 1800,
        priceLabel: r'$49.99',
        badgeLabel: 'Vault',
      ),
    ];
