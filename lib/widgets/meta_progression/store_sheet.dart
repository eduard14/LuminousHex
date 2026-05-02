part of '../meta_progression_sheet.dart';

class LightcoreStoreSheet extends StatefulWidget {
  const LightcoreStoreSheet({
    super.key,
    required this.controller,
    this.backend,
  });

  final LightcoreController controller;
  final FirebaseLightcoreBackend? backend;

  @override
  State<LightcoreStoreSheet> createState() => _LightcoreStoreSheetState();
}

class _LightcoreStoreSheetState extends State<LightcoreStoreSheet> {
  bool _premiumMembershipPurchaseInFlight = false;
  _StoreCategory _selectedCategory = _StoreCategory.featured;

  Future<void> _handlePremiumMembershipPurchase() async {
    if (_premiumMembershipPurchaseInFlight ||
        widget.controller.hasPremiumMembership) {
      return;
    }

    final backend = widget.backend;
    if (backend == null ||
        !backend.runtimeConfig.canInitializeOnCurrentPlatform) {
      widget.controller.unlockPremiumMembership();
      return;
    }

    setState(() => _premiumMembershipPurchaseInFlight = true);
    try {
      final profile = await backend.purchasePremiumMembership();
      if (!mounted) {
        return;
      }
      widget.controller.syncPlayerProfile(profile, showBanner: false);
      widget.controller.unlockPremiumMembership();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Premium Membership unlock failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _premiumMembershipPurchaseInFlight = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MetaSheetFrame(
      title: 'Store',
      subtitle: 'Shard packs, capped bundles, boosts, and account upgrades.',
      tint: LightcorePalette.aether,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StoreBalanceBar(
                  prismShards: widget.controller.prismShards,
                  flux: widget.controller.flux,
                ),
                const SizedBox(height: 12),
                const _StoreTickerStrip(
                  text:
                      'PLATFORM PRODUCTS GRANT PRISM SHARDS  •  BUNDLES AND PASSES SPEND PRISM SHARDS  •  FLUX STAYS GAMEPLAY-EARNED  •  WEEKLY BOOSTS HAVE HARD CAPS',
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compactRail = constraints.maxWidth < 560;
                    final railWidth = compactRail ? 104.0 : 162.0;
                    final offers = _offersFor(_selectedCategory);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: railWidth,
                          child: _StoreCategoryRail(
                            selectedCategory: _selectedCategory,
                            compact: compactRail,
                            onSelected: (category) {
                              setState(() => _selectedCategory = category);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StoreCategoryHeader(
                                category: _selectedCategory,
                                offerCount: offers.length,
                              ),
                              const SizedBox(height: 12),
                              _StoreProductGrid(offers: offers),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_StoreOffer> _offersFor(_StoreCategory category) {
    final controller = widget.controller;

    final premiumMembershipOffer = _StoreOffer(
      title: 'Premium Membership',
      subtitle: 'Monthly subscription for the longer offline cap.',
      quantityLabel: '30d',
      priceLabel: r'$4.99',
      currency: _StoreCurrency.cash,
      limitLabel: controller.hasPremiumMembership ? 'Active' : 'Monthly',
      noteLabel: 'No direct power pack',
      badgeLabel: 'Membership',
      buttonLabel: controller.hasPremiumMembership
          ? 'Owned'
          : _premiumMembershipPurchaseInFlight
          ? 'Working...'
          : 'Activate',
      icon: Icons.workspace_premium_rounded,
      tint: LightcorePalette.solar,
      enabled:
          !controller.hasPremiumMembership &&
          !_premiumMembershipPurchaseInFlight,
      onPressed: _handlePremiumMembershipPurchase,
    );
    final overdriveOffer = _StoreOffer(
      title: 'Permanent Overdrive',
      subtitle: 'One-time account upgrade bought with shards.',
      quantityLabel: 'x1.50',
      priceLabel: _permanentOverdrivePrismCost.toString(),
      currency: _StoreCurrency.prismShards,
      limitLabel: controller.hasPermanentOverdrive ? 'Unlocked' : 'Account',
      noteLabel: 'Not a platform cash SKU',
      badgeLabel: 'Speed',
      buttonLabel: controller.hasPermanentOverdrive ? 'Owned' : 'Unlock',
      icon: Icons.bolt_rounded,
      tint: LightcorePalette.flare,
      enabled:
          !controller.hasPermanentOverdrive &&
          controller.prismShards >= _permanentOverdrivePrismCost,
      onPressed: _buyPermanentOverdrive,
    );
    final spentRadiancePoints = controller.totalRadianceStatPointsSpent;
    final radianceResetOffer = _StoreOffer(
      title: 'Global Stat Reset',
      subtitle: 'Refunds all allocated Global Attribute points.',
      quantityLabel: spentRadiancePoints > 0
          ? '$spentRadiancePoints spent'
          : 'No points spent',
      priceLabel: _radianceStatResetPrismCost.toString(),
      currency: _StoreCurrency.prismShards,
      limitLabel: spentRadiancePoints > 0 ? 'Account' : 'Unavailable',
      noteLabel: spentRadiancePoints > 0
          ? 'Reallocate earned Radiance points'
          : 'Spend Radiance points first',
      badgeLabel: 'Reset',
      buttonLabel: spentRadiancePoints > 0 ? 'Reset' : 'Locked',
      icon: Icons.restart_alt_rounded,
      tint: LightcorePalette.quest,
      enabled: controller.canPurchaseRadianceStatReset,
      onPressed: () => controller.purchaseRadianceStatReset(),
    );
    final shardPacks = _prismShardPacks
        .map(_prismShardPackOffer)
        .toList(growable: false);
    final starterRelayCache = _limitedPrismBundleOffer(
      id: _starterRelayCacheId,
      title: 'Starter Relay Cache',
      subtitle: 'Early Lumens, Flux, and scans without cash pricing.',
      quantityLabel: '2,000 Lumens',
      cost: 90,
      weeklyLimit: 1,
      noteLabel: '+25 Flux, +6 Threat Scans',
      badgeLabel: 'Starter',
      icon: Icons.auto_awesome_rounded,
      tint: LightcorePalette.aether,
      onPurchased: _grantStarterRelayCache,
    );
    final smallLumenCache = _limitedPrismBundleOffer(
      id: _smallLumenCacheId,
      title: 'Small Lumen Cache',
      subtitle: 'A capped stabilization bump for fresh shell anchors.',
      quantityLabel: '500 Lumens',
      cost: 35,
      weeklyLimit: 3,
      noteLabel: 'Scales conservatively',
      badgeLabel: 'Lumen',
      icon: Icons.hexagon_rounded,
      tint: LightcorePalette.aether,
      onPurchased: () =>
          _grantLumenCache(lumenAmount: 500, sourceLabel: 'Small Lumen Cache'),
    );
    final mediumLumenCache = _limitedPrismBundleOffer(
      id: _mediumLumenCacheId,
      title: 'Medium Lumen Cache',
      subtitle: 'A larger capped cache for active upgrade pushes.',
      quantityLabel: '1,500 Lumens',
      cost: 90,
      weeklyLimit: 2,
      noteLabel: 'Weekly capped',
      badgeLabel: 'Lumen',
      icon: Icons.hexagon_rounded,
      tint: LightcorePalette.aether,
      onPurchased: () => _grantLumenCache(
        lumenAmount: 1500,
        sourceLabel: 'Medium Lumen Cache',
      ),
    );
    final threatScanFive = _limitedPrismBundleOffer(
      id: _threatScanFiveId,
      title: 'Threat Scan Cache',
      subtitle: 'Extra anomaly pulls with a strict weekly cap.',
      quantityLabel: '5 Scans',
      cost: 45,
      weeklyLimit: 5,
      noteLabel: 'No Flux conversion',
      badgeLabel: 'Scans',
      icon: LightcoreIcons.threatScan,
      tint: LightcorePalette.scanGlow,
      onPurchased: () =>
          _grantThreatScans(scanAmount: 5, sourceLabel: 'Threat Scan Cache'),
    );
    final threatScanFifteen = _limitedPrismBundleOffer(
      id: _threatScanFifteenId,
      title: 'Large Threat Scan Cache',
      subtitle: 'Better scan value with a lower weekly cap.',
      quantityLabel: '15 Scans',
      cost: 120,
      weeklyLimit: 3,
      noteLabel: 'Best scan value',
      badgeLabel: 'Scans',
      icon: LightcoreIcons.threatScan,
      tint: LightcorePalette.scanGlow,
      onPurchased: () => _grantThreatScans(
        scanAmount: 15,
        sourceLabel: 'Large Threat Scan Cache',
      ),
    );
    final fluxTimeWarp = _timeWarpStoreOffer(
      controller.timeWarpOfferById(
        LightcoreController.timeWarpFluxThirtyMinutesId,
      )!,
    );
    final prismQuickWarp = _timeWarpStoreOffer(
      controller.timeWarpOfferById(
        LightcoreController.timeWarpPrismThirtyMinutesId,
      )!,
    );
    final prismRelayWarp = _timeWarpStoreOffer(
      controller.timeWarpOfferById(
        LightcoreController.timeWarpPrismTwoHoursId,
      )!,
    );
    final prismDeepWarp = _timeWarpStoreOffer(
      controller.timeWarpOfferById(
        LightcoreController.timeWarpPrismTwelveHoursId,
      )!,
    );
    final cosmeticOffers = AvatarCosmeticCatalog.all
        .map(_avatarCosmeticOffer)
        .toList(growable: false);

    return switch (category) {
      _StoreCategory.featured => [
        premiumMembershipOffer,
        shardPacks[1],
        ...cosmeticOffers.take(2),
        starterRelayCache,
        threatScanFive,
        prismRelayWarp,
        overdriveOffer,
        radianceResetOffer,
      ],
      _StoreCategory.shardPacks => shardPacks,
      _StoreCategory.bundles => [
        starterRelayCache,
        smallLumenCache,
        mediumLumenCache,
        threatScanFive,
        threatScanFifteen,
      ],
      _StoreCategory.boosts => [
        fluxTimeWarp,
        prismQuickWarp,
        prismRelayWarp,
        prismDeepWarp,
      ],
      _StoreCategory.cosmetics => cosmeticOffers,
      _StoreCategory.premium => [
        premiumMembershipOffer,
        overdriveOffer,
        radianceResetOffer,
      ],
    };
  }

  _StoreOffer _avatarCosmeticOffer(AvatarCosmeticConfig config) {
    final owned = widget.controller.isAvatarCosmeticUnlocked(config.id);
    final equipped = widget.controller.isAvatarCosmeticEquipped(config.id);
    final currentLoadout = widget.controller.avatarCosmeticLoadout;
    final previewLoadout = switch (config.type) {
      AvatarCosmeticType.hair => AvatarCosmeticLoadout(
        hairId: config.id,
        faceId: currentLoadout.faceId,
      ),
      AvatarCosmeticType.face => AvatarCosmeticLoadout(
        hairId: currentLoadout.hairId,
        faceId: config.id,
      ),
    };
    return _StoreOffer(
      title: config.name,
      subtitle: config.summary,
      quantityLabel: _cosmeticStoreTypeLabel(config.type),
      priceLabel: owned ? 'Owned' : config.pricePrismShards.toString(),
      currency: _StoreCurrency.prismShards,
      limitLabel: owned ? 'Unlocked' : 'Account',
      noteLabel: config.rarity.label,
      badgeLabel: 'Cosmetic',
      buttonLabel: equipped
          ? 'Equipped'
          : owned
          ? 'Equip'
          : 'Buy',
      icon: _cosmeticStoreIcon(config.type),
      tint: _cosmeticStoreTint(config),
      enabled: equipped
          ? false
          : owned
          ? true
          : widget.controller.canPurchaseAvatarCosmetic(config.id),
      onPressed: () {
        if (owned) {
          widget.controller.equipAvatarCosmetic(config.id);
        } else {
          widget.controller.purchaseAvatarCosmetic(config.id);
        }
      },
      cosmeticPreview: _StoreCosmeticPreviewData(
        guide: widget.controller.guideProfile,
        loadout: previewLoadout,
        config: config,
      ),
    );
  }

  _StoreOffer _prismShardPackOffer(_PrismShardPackDefinition pack) {
    return _StoreOffer(
      title: pack.title,
      subtitle: pack.subtitle,
      quantityLabel: LightcoreCurrencyLabels.prismShardCount(pack.totalAmount),
      priceLabel: pack.priceLabel,
      currency: _StoreCurrency.cash,
      limitLabel: 'Consumable',
      noteLabel: pack.bonusAmount > 0
          ? '+${pack.bonusAmount} bonus shards'
          : 'No bonus tier',
      badgeLabel: pack.badgeLabel,
      buttonLabel: 'Buy',
      icon: Icons.diamond_rounded,
      tint: LightcorePalette.aether,
      enabled: true,
      onPressed: () => _mockPrismShardPackPurchase(
        amount: pack.totalAmount,
        sourceLabel: pack.title,
      ),
    );
  }

  _StoreOffer _limitedPrismBundleOffer({
    required String id,
    required String title,
    required String subtitle,
    required String quantityLabel,
    required int cost,
    required int weeklyLimit,
    required String noteLabel,
    required String badgeLabel,
    required IconData icon,
    required Color tint,
    required VoidCallback onPurchased,
  }) {
    final remaining = widget.controller.storeOfferPurchasesRemaining(
      id,
      weeklyLimit: weeklyLimit,
    );
    return _StoreOffer(
      title: title,
      subtitle: subtitle,
      quantityLabel: quantityLabel,
      priceLabel: cost.toString(),
      currency: _StoreCurrency.prismShards,
      limitLabel: 'Weekly $remaining / $weeklyLimit',
      noteLabel: remaining == 0 ? 'Hard weekly cap reached' : noteLabel,
      badgeLabel: badgeLabel,
      buttonLabel: remaining == 0 ? 'Sold Out' : 'Buy',
      icon: icon,
      tint: tint,
      enabled: widget.controller.canSpendPrismShardsForStoreOffer(
        id,
        amount: cost,
        weeklyLimit: weeklyLimit,
      ),
      onPressed: () {
        if (!widget.controller.spendPrismShardsForStoreOffer(
          offerId: id,
          amount: cost,
          weeklyLimit: weeklyLimit,
          reasonLabel: title,
          showBanner: false,
        )) {
          return;
        }
        onPurchased();
      },
    );
  }

  _StoreOffer _timeWarpStoreOffer(LightcoreTimeWarpOfferDefinition offer) {
    final remaining = widget.controller.timeWarpPurchasesRemaining(offer.id);
    final storeCurrency = switch (offer.currency) {
      LightcoreTimeWarpCurrency.flux => _StoreCurrency.flux,
      LightcoreTimeWarpCurrency.prismShards => _StoreCurrency.prismShards,
    };
    final tint = switch (offer.currency) {
      LightcoreTimeWarpCurrency.flux => LightcorePalette.ember,
      LightcoreTimeWarpCurrency.prismShards => LightcorePalette.aether,
    };

    return _StoreOffer(
      title: offer.title,
      subtitle: offer.subtitle,
      quantityLabel: offer.durationLabel,
      priceLabel: offer.cost.toString(),
      currency: storeCurrency,
      limitLabel: 'Weekly $remaining / ${offer.weeklyLimit}',
      noteLabel: remaining == 0
          ? 'Hard weekly cap reached'
          : 'Instant idle progress, no uncapped fallback',
      badgeLabel: offer.badgeLabel,
      buttonLabel: remaining == 0 ? 'Sold Out' : 'Warp',
      icon: Icons.more_time_rounded,
      tint: tint,
      enabled: widget.controller.canPurchaseTimeWarp(offer.id),
      onPressed: () => widget.controller.purchaseTimeWarp(offer.id),
    );
  }

  void _mockPrismShardPackPurchase({
    required int amount,
    required String sourceLabel,
  }) {
    widget.controller.grantPrismShards(
      amount: amount,
      sourceLabel: sourceLabel,
    );
  }

  void _buyPermanentOverdrive() {
    if (widget.controller.hasPermanentOverdrive) {
      return;
    }
    if (!widget.controller.spendPrismShards(
      amount: _permanentOverdrivePrismCost,
      reasonLabel: 'Permanent Overdrive',
      showBanner: false,
    )) {
      return;
    }
    widget.controller.unlockPermanentOverdrive();
  }

  void _grantStarterRelayCache() {
    widget.controller.grantRewardedResources(
      lumensGranted: 2000,
      fluxGranted: 25,
      enemyTicketsGranted: 6,
      sourceLabel: 'Starter Relay Cache',
    );
  }

  void _grantLumenCache({
    required int lumenAmount,
    required String sourceLabel,
  }) {
    widget.controller.grantRewardedResources(
      lumensGranted: lumenAmount,
      sourceLabel: sourceLabel,
    );
  }

  void _grantThreatScans({
    required int scanAmount,
    required String sourceLabel,
  }) {
    widget.controller.grantRewardedResources(
      enemyTicketsGranted: scanAmount,
      sourceLabel: sourceLabel,
    );
  }
}

enum _StoreCategory {
  featured,
  shardPacks,
  cosmetics,
  bundles,
  boosts,
  premium,
}

enum _StoreCurrency { cash, flux, prismShards }

extension _StoreCategoryX on _StoreCategory {
  String get label => switch (this) {
    _StoreCategory.featured => 'Featured',
    _StoreCategory.shardPacks => 'Shard Packs',
    _StoreCategory.cosmetics => 'Cosmetics',
    _StoreCategory.bundles => 'Bundles',
    _StoreCategory.boosts => 'Boosts',
    _StoreCategory.premium => 'Premium',
  };

  String get summary => switch (this) {
    _StoreCategory.featured => 'Subscriptions, packs, and capped offers.',
    _StoreCategory.shardPacks => 'Platform purchases that grant shards.',
    _StoreCategory.cosmetics => 'Hair and face profile unlocks.',
    _StoreCategory.bundles => 'Weekly-capped bundles bought with shards.',
    _StoreCategory.boosts => 'Time skips with hard weekly caps.',
    _StoreCategory.premium => 'Membership and account unlocks.',
  };

  IconData get icon => switch (this) {
    _StoreCategory.featured => Icons.star_rounded,
    _StoreCategory.shardPacks => Icons.diamond_rounded,
    _StoreCategory.cosmetics => Icons.face_retouching_natural_rounded,
    _StoreCategory.bundles => Icons.inventory_2_rounded,
    _StoreCategory.boosts => Icons.speed_rounded,
    _StoreCategory.premium => Icons.workspace_premium_rounded,
  };

  Color get tint => switch (this) {
    _StoreCategory.featured => LightcorePalette.aether,
    _StoreCategory.shardPacks => LightcorePalette.aether,
    _StoreCategory.cosmetics => LightcorePalette.violet,
    _StoreCategory.bundles => LightcorePalette.verdant,
    _StoreCategory.boosts => LightcorePalette.flare,
    _StoreCategory.premium => LightcorePalette.gilded,
  };
}

extension _StoreCurrencyX on _StoreCurrency {
  String get label => switch (this) {
    _StoreCurrency.cash => 'Platform',
    _StoreCurrency.flux => LightcoreCurrencyLabels.flux,
    _StoreCurrency.prismShards => LightcoreCurrencyLabels.prismShards,
  };

  IconData get icon => switch (this) {
    _StoreCurrency.cash => Icons.payments_rounded,
    _StoreCurrency.flux => Icons.diamond_rounded,
    _StoreCurrency.prismShards => Icons.diamond_rounded,
  };

  Color get tint => switch (this) {
    _StoreCurrency.cash => LightcorePalette.success,
    _StoreCurrency.flux => LightcorePalette.ember,
    _StoreCurrency.prismShards => LightcorePalette.aether,
  };
}

String _cosmeticStoreTypeLabel(AvatarCosmeticType type) => switch (type) {
  AvatarCosmeticType.hair => 'Hair',
  AvatarCosmeticType.face => 'Face',
};

IconData _cosmeticStoreIcon(AvatarCosmeticType type) => switch (type) {
  AvatarCosmeticType.hair => Icons.content_cut_rounded,
  AvatarCosmeticType.face => Icons.face_retouching_natural_rounded,
};

Color _cosmeticStoreTint(AvatarCosmeticConfig config) =>
    switch (config.rarity) {
      ManagerRarity.common => LightcorePalette.mist,
      ManagerRarity.uncommon => LightcorePalette.verdant,
      ManagerRarity.rare => LightcorePalette.aether,
      ManagerRarity.epic => LightcorePalette.violet,
      ManagerRarity.legendary => LightcorePalette.gilded,
    };

class _PrismShardPackDefinition {
  const _PrismShardPackDefinition({
    required this.productId,
    required this.title,
    required this.subtitle,
    required this.baseAmount,
    required this.bonusAmount,
    required this.priceLabel,
    required this.badgeLabel,
  });

  final String productId;
  final String title;
  final String subtitle;
  final int baseAmount;
  final int bonusAmount;
  final String priceLabel;
  final String badgeLabel;

  int get totalAmount => baseAmount + bonusAmount;
}

class _StoreOffer {
  const _StoreOffer({
    required this.title,
    required this.subtitle,
    required this.quantityLabel,
    required this.priceLabel,
    required this.currency,
    required this.limitLabel,
    required this.noteLabel,
    required this.badgeLabel,
    required this.buttonLabel,
    required this.icon,
    required this.tint,
    required this.enabled,
    required this.onPressed,
    this.cosmeticPreview,
  });

  final String title;
  final String subtitle;
  final String quantityLabel;
  final String priceLabel;
  final _StoreCurrency currency;
  final String limitLabel;
  final String noteLabel;
  final String badgeLabel;
  final String buttonLabel;
  final IconData icon;
  final Color tint;
  final bool enabled;
  final VoidCallback onPressed;
  final _StoreCosmeticPreviewData? cosmeticPreview;
}

class _StoreCosmeticPreviewData {
  const _StoreCosmeticPreviewData({
    required this.guide,
    required this.loadout,
    required this.config,
  });

  final LightcoreGuideProfile guide;
  final AvatarCosmeticLoadout loadout;
  final AvatarCosmeticConfig config;
}

class _StoreBalanceBar extends StatelessWidget {
  const _StoreBalanceBar({required this.prismShards, required this.flux});

  final int prismShards;
  final int flux;

  @override
  Widget build(BuildContext context) {
    return AuroraPanel(
      tint: LightcorePalette.aether,
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          StatusPill(
            label: LightcoreCurrencyLabels.prismShards,
            value: prismShards.toString(),
            tint: LightcorePalette.aether,
            icon: Icons.diamond_rounded,
          ),
          StatusPill(
            label: LightcoreCurrencyLabels.flux,
            value: flux.toString(),
            tint: LightcorePalette.ember,
            icon: Icons.diamond_rounded,
          ),
        ],
      ),
    );
  }
}

class _StoreTickerStrip extends StatelessWidget {
  const _StoreTickerStrip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: LightcorePalette.panelRaised.withValues(alpha: 0.72),
        border: Border.all(
          color: LightcorePalette.aether.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.sensors_rounded, size: 16, color: LightcorePalette.aether),
          const SizedBox(width: 8),
          Expanded(
            child: _SideScrollText(
              text: text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.82),
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideScrollText extends StatelessWidget {
  const _SideScrollText({required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          return Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: effectiveStyle,
          );
        }

        final painter = TextPainter(
          text: TextSpan(text: text, style: effectiveStyle),
          textDirection: Directionality.of(context),
          maxLines: 1,
        )..layout();
        if (painter.width <= constraints.maxWidth) {
          return Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: effectiveStyle,
          );
        }

        final travel = painter.width - constraints.maxWidth + 20;
        final durationMs = math.max(4200, travel * 42).round();
        return ClipRect(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: -travel),
            duration: Duration(milliseconds: durationMs),
            curve: Curves.easeInOutCubic,
            child: Text(text, softWrap: false, style: effectiveStyle),
            builder: (context, offset, child) {
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}

class _StoreCategoryRail extends StatelessWidget {
  const _StoreCategoryRail({
    required this.selectedCategory,
    required this.compact,
    required this.onSelected,
  });

  final _StoreCategory selectedCategory;
  final bool compact;
  final ValueChanged<_StoreCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final category in _StoreCategory.values) ...[
          _StoreCategoryButton(
            category: category,
            selected: selectedCategory == category,
            compact: compact,
            onTap: () => onSelected(category),
          ),
          if (category != _StoreCategory.values.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _StoreCategoryButton extends StatelessWidget {
  const _StoreCategoryButton({
    required this.category,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final _StoreCategory category;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = category.tint;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected
                ? tint.withValues(alpha: 0.18)
                : LightcorePalette.panelRaised.withValues(alpha: 0.58),
            border: Border.all(
              color: (selected ? tint : LightcorePalette.stroke).withValues(
                alpha: selected ? 0.5 : 0.36,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(category.icon, size: 16, color: tint),
              if (!compact) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: LightcorePalette.mist,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreCategoryHeader extends StatelessWidget {
  const _StoreCategoryHeader({
    required this.category,
    required this.offerCount,
  });

  final _StoreCategory category;
  final int offerCount;

  @override
  Widget build(BuildContext context) {
    return AuroraPanel(
      tint: category.tint,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(category.icon, color: category.tint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  category.summary,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _HeaderChip(label: '$offerCount', tint: category.tint),
        ],
      ),
    );
  }
}

class _StoreProductGrid extends StatelessWidget {
  const _StoreProductGrid({required this.offers});

  final List<_StoreOffer> offers;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 760
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth >= 460
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final offer in offers)
              SizedBox(
                width: width,
                child: _StoreOfferCard(offer: offer),
              ),
          ],
        );
      },
    );
  }
}

class _StoreOfferCard extends StatelessWidget {
  const _StoreOfferCard({required this.offer});

  final _StoreOffer offer;

  @override
  Widget build(BuildContext context) {
    final priceTint = offer.currency.tint;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: offer.tint.withValues(alpha: 0.38)),
        gradient: LinearGradient(
          colors: [
            offer.tint.withValues(alpha: 0.12),
            LightcorePalette.panelRaised.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: offer.tint.withValues(alpha: 0.16),
                  ),
                  child: Icon(offer.icon, color: offer.tint, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeaderChip(label: offer.badgeLabel, tint: offer.tint),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SideScrollText(
              text: offer.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: LightcorePalette.mist,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              offer.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (offer.cosmeticPreview case final preview?) ...[
              const SizedBox(height: 12),
              _StoreCosmeticPreview(preview: preview, tint: offer.tint),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeaderChip(label: offer.quantityLabel, tint: offer.tint),
                _HeaderChip(
                  label: offer.limitLabel,
                  tint: LightcorePalette.mist,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(offer.currency.icon, size: 16, color: priceTint),
                const SizedBox(width: 6),
                Text(
                  offer.priceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: priceTint,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    offer.currency.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: LightcorePalette.mist.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              offer.noteLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: offer.enabled ? offer.onPressed : null,
                child: Text(offer.buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreCosmeticPreview extends StatelessWidget {
  const _StoreCosmeticPreview({required this.preview, required this.tint});

  final _StoreCosmeticPreviewData preview;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withValues(alpha: 0.14),
            ),
            child: Image.asset(
              preview.config.assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => Icon(
                _cosmeticStoreIcon(preview.config.type),
                color: tint,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: tint.withValues(alpha: 0.74),
            ),
          ),
          CosmicGuideAvatar(
            guide: preview.guide,
            size: 72,
            avatarCosmetics: preview.loadout,
            semanticLabel: '${preview.config.name} cosmetic preview',
          ),
        ],
      ),
    );
  }
}
