import '../models/lightcore_state.dart';

class ShellPromotionPresentation {
  const ShellPromotionPresentation({
    required this.sequence,
    required this.sourceLayerLabel,
    required this.targetLayerLabel,
    required this.sourceTier,
    required this.targetTier,
    required this.sourceCore,
    required this.targetCore,
    required this.sourceSlots,
    this.layer2Component,
  });

  final int sequence;
  final String sourceLayerLabel;
  final String targetLayerLabel;
  final int sourceTier;
  final int targetTier;
  final CoreState sourceCore;
  final CoreState targetCore;
  final List<OuterTowerState> sourceSlots;
  final Layer2ComponentState? layer2Component;
}
