part of '../meta_progression_sheet.dart';

class LightcoreBattlePassSheet extends StatefulWidget {
  const LightcoreBattlePassSheet({super.key, required this.controller});

  final LightcoreController controller;

  @override
  State<LightcoreBattlePassSheet> createState() =>
      _LightcoreBattlePassSheetState();
}

class _LightcoreBattlePassSheetState extends State<LightcoreBattlePassSheet> {
  late BattlePassType _selectedType;
  String? _selectedPassKey;

  List<BattlePassType> get _battlePassTypes =>
      widget.controller.battlePassTypes.toList(growable: false);

  @override
  void initState() {
    super.initState();
    _selectedType = _initialBattlePassType();
    _selectedPassKey = _initialBattlePassKey(_selectedType);
  }

  BattlePassType _initialBattlePassType() {
    for (final type in _battlePassTypes) {
      if (widget.controller.claimableBattlePassRewards(type) > 0) {
        return type;
      }
    }
    return _battlePassTypes.isNotEmpty
        ? _battlePassTypes.first
        : BattlePassType.dailyKills;
  }

  String? _initialBattlePassKey(BattlePassType type) {
    final passes = widget.controller.battlePassesFor(type);
    for (final pass in passes) {
      if (widget.controller.claimableBattlePassRewardsForPass(pass) > 0) {
        return pass.seasonKey;
      }
    }
    return passes.isNotEmpty ? passes.last.seasonKey : null;
  }

  BattlePassProgress _resolveSelectedPass(List<BattlePassProgress> passes) {
    for (final pass in passes) {
      if (pass.seasonKey == _selectedPassKey) {
        return pass;
      }
    }
    for (final pass in passes) {
      if (widget.controller.claimableBattlePassRewardsForPass(pass) > 0) {
        return pass;
      }
    }
    return passes.isNotEmpty
        ? passes.last
        : widget.controller.battlePassFor(_selectedType);
  }

  @override
  Widget build(BuildContext context) {
    return _MetaSheetFrame(
      title: 'Battle Pass',
      subtitle:
          'Daily kill pass plus rolling scan tracks. Premium unlocks with Prism Shards.',
      tint: _passTint(_selectedType),
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final passes = widget.controller.battlePassesFor(_selectedType);
          final pass = _resolveSelectedPass(passes);
          final tiers = widget.controller.battlePassTiersForPass(pass);
          final progressCap = tiers.last.goal;
          final progress = pass.progress.clamp(0, progressCap);
          final claimable = widget.controller.claimableBattlePassRewardsForPass(
            pass,
          );
          var lockedPaidRewards = 0;
          if (!pass.premiumUnlocked) {
            for (var tierIndex = 0; tierIndex < tiers.length; tierIndex++) {
              if (pass.progress < tiers[tierIndex].goal) {
                continue;
              }
              if (!widget.controller.isBattlePassRewardClaimedForPass(
                pass,
                tierIndex,
                BattlePassTrack.premium,
              )) {
                lockedPaidRewards += 1;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuroraPanel(
                  tint: _passTint(_selectedType),
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final useSplitOverview = constraints.maxWidth >= 720;
                      final accent = _passTint(_selectedType);
                      final identityBlock = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(
                                _battlePassTypeIcon(pass.type),
                                color: accent,
                                size: 22,
                              ),
                              Text(
                                pass.type.label,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              _HeaderChip(
                                label: pass.type.cadenceLabel,
                                tint: pass.type.resetsDaily
                                    ? LightcorePalette.flare
                                    : LightcorePalette.success,
                              ),
                              IconButton(
                                onPressed: () =>
                                    _showBattlePassHelpDialog(context, pass),
                                tooltip: 'Pass details',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.help_outline_rounded,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _passSummary(pass),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      );
                      final statusBlock = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              StatusPill(
                                label: 'Progress',
                                value: '$progress / $progressCap',
                                tint: accent,
                                icon: Icons.timeline_rounded,
                                tooltip:
                                    '${pass.type.progressUnitLabel}: $progress of $progressCap',
                              ),
                              StatusPill(
                                label: 'Claimable',
                                value: claimable > 0 ? '$claimable' : '0',
                                tint: claimable > 0
                                    ? LightcorePalette.success
                                    : LightcorePalette.mist,
                                icon: Icons.redeem_rounded,
                                tooltip: claimable > 0
                                    ? '$claimable pass reward${claimable == 1 ? '' : 's'} can be claimed'
                                    : 'No pass rewards can be claimed',
                              ),
                              StatusPill(
                                label: 'Premium',
                                value: pass.premiumUnlocked
                                    ? lockedPaidRewards > 0
                                          ? '$lockedPaidRewards available'
                                          : 'Active'
                                    : '${_premiumPrismShardCost(_selectedType)} Shards',
                                tint: pass.premiumUnlocked
                                    ? LightcorePalette.success
                                    : LightcorePalette.solar,
                                icon: pass.premiumUnlocked
                                    ? Icons.lock_open_rounded
                                    : Icons.lock_rounded,
                                tooltip: pass.premiumUnlocked
                                    ? lockedPaidRewards > 0
                                          ? '$lockedPaidRewards premium reward${lockedPaidRewards == 1 ? '' : 's'} waiting'
                                          : 'Premium track is unlocked'
                                    : 'Unlock premium for ${_premiumPrismShardCost(_selectedType)} Prism Shards',
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: useSplitOverview ? double.infinity : null,
                            child: FilledButton.icon(
                              onPressed: claimable > 0
                                  ? () => widget.controller
                                        .claimUnlockedBattlePassRewardsForPass(
                                          pass,
                                        )
                                  : null,
                              icon: const Icon(Icons.redeem_rounded),
                              label: Text(
                                claimable > 0
                                    ? 'Claim All • $claimable'
                                    : 'Claim All',
                              ),
                            ),
                          ),
                          if (!pass.premiumUnlocked) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Unlock premium rewards on this pass with Prism Shards.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonalIcon(
                                onPressed:
                                    widget.controller.prismShards >=
                                        _premiumPrismShardCost(_selectedType)
                                    ? () => widget.controller
                                          .unlockPremiumBattlePassForPass(
                                            pass,
                                            prismShardCost:
                                                _premiumPrismShardCost(
                                                  _selectedType,
                                                ),
                                          )
                                    : null,
                                icon: const Icon(Icons.lock_open_rounded),
                                label: Text(
                                  'Unlock Premium • ${_premiumPrismShardCost(_selectedType)} Shards',
                                ),
                              ),
                            ),
                          ],
                        ],
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BattlePassTypePicker(
                            controller: widget.controller,
                            types: _battlePassTypes,
                            selectedType: _selectedType,
                            onSelected: (type) {
                              setState(() {
                                _selectedType = type;
                                _selectedPassKey = _initialBattlePassKey(type);
                              });
                            },
                          ),
                          if (passes.length > 1) ...[
                            const SizedBox(height: 12),
                            _BattlePassCopyPicker(
                              controller: widget.controller,
                              passes: passes,
                              selectedPass: pass,
                              onSelected: (selectedPass) {
                                setState(
                                  () =>
                                      _selectedPassKey = selectedPass.seasonKey,
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (useSplitOverview)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: identityBlock),
                                const SizedBox(width: 18),
                                Expanded(flex: 4, child: statusBlock),
                              ],
                            )
                          else ...[
                            identityBlock,
                            const SizedBox(height: 14),
                            statusBlock,
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                AuroraPanel(
                  tint: _passTint(_selectedType),
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final useCompactLane = constraints.maxWidth < 620;
                      return Stack(
                        children: [
                          Positioned(
                            top: useCompactLane ? 72 : 86,
                            bottom: 28,
                            left: (constraints.maxWidth / 2) - 3,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: LinearGradient(
                                  colors: [
                                    _passTint(
                                      _selectedType,
                                    ).withValues(alpha: 0.04),
                                    _passTint(
                                      _selectedType,
                                    ).withValues(alpha: 0.3),
                                    _passTint(
                                      _selectedType,
                                    ).withValues(alpha: 0.06),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _passTint(
                                      _selectedType,
                                    ).withValues(alpha: 0.18),
                                    blurRadius: 18,
                                    spreadRadius: -5,
                                  ),
                                ],
                              ),
                              child: const SizedBox(width: 6),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _BattlePassLaneHeader(
                                type: _selectedType,
                                pass: pass,
                                progress: progress,
                                progressCap: progressCap,
                              ),
                              const SizedBox(height: 14),
                              for (
                                var tierIndex = 0;
                                tierIndex < tiers.length;
                                tierIndex++
                              ) ...[
                                _BattlePassTierCard(
                                  controller: widget.controller,
                                  type: _selectedType,
                                  pass: pass,
                                  tier: tiers[tierIndex],
                                  tierIndex: tierIndex,
                                  previousGoal: tierIndex == 0
                                      ? 0
                                      : tiers[tierIndex - 1].goal,
                                  compact: useCompactLane,
                                ),
                                if (tierIndex < tiers.length - 1)
                                  SizedBox(height: useCompactLane ? 12 : 10),
                              ],
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
