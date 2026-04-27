part of '../meta_progression_sheet.dart';

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tint.withValues(alpha: 0.14),
        border: Border.all(color: tint.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: tint),
      ),
    );
  }
}

Color _passTint(BattlePassType type) => switch (type) {
  BattlePassType.dailyKills => LightcorePalette.flare,
  BattlePassType.towerManagerPulls => LightcorePalette.aether,
  BattlePassType.enemyManagerPulls => LightcorePalette.violet,
  BattlePassType.enemyPulls => LightcorePalette.solar,
};

IconData _battlePassTypeIcon(BattlePassType type) => switch (type) {
  BattlePassType.dailyKills => Icons.ads_click_rounded,
  BattlePassType.towerManagerPulls => Icons.precision_manufacturing_rounded,
  BattlePassType.enemyManagerPulls => Icons.bug_report_rounded,
  BattlePassType.enemyPulls => LightcoreIcons.threatScan,
};

IconData _battlePassRewardIcon(BattlePassReward reward) =>
    switch (reward.kind) {
      BattlePassRewardKind.lumens => Icons.hexagon_rounded,
      BattlePassRewardKind.flux => Icons.workspace_premium_rounded,
      BattlePassRewardKind.enemyPulls => LightcoreIcons.threatScan,
      BattlePassRewardKind.towerManager =>
        Icons.precision_manufacturing_rounded,
      BattlePassRewardKind.enemyManager => Icons.bug_report_rounded,
      BattlePassRewardKind.enemyCard => Icons.memory_rounded,
    };

String? _battlePassRewardQualifier(BattlePassReward reward) =>
    switch (reward.kind) {
      BattlePassRewardKind.towerManager ||
      BattlePassRewardKind.enemyManager => reward.managerRarity?.label,
      BattlePassRewardKind.enemyCard => reward.enemyCardRarity?.label,
      _ => null,
    };

int _premiumPrismShardCost(BattlePassType type) => switch (type) {
  BattlePassType.dailyKills => 120,
  BattlePassType.towerManagerPulls => 90,
  BattlePassType.enemyManagerPulls => 90,
  BattlePassType.enemyPulls => 90,
};

String _passSummary(BattlePassProgress pass) => switch (pass.type) {
  BattlePassType.dailyKills =>
    'Daily kills fill this track. Tap a reward card when you want the full claim state.',
  BattlePassType.towerManagerPulls =>
    'Tower manager pulls advance the current pass; completed passes stay available.',
  BattlePassType.enemyManagerPulls =>
    'Threat Director pulls advance the current pass; completed passes stay available.',
  BattlePassType.enemyPulls =>
    'Threat scans advance the current pass; completed passes stay available.',
};

Future<void> _showBattlePassHelpDialog(
  BuildContext context,
  BattlePassProgress pass,
) {
  return showDialog<void>(
    context: context,
    barrierColor: LightcorePalette.night.withValues(alpha: 0.76),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(context).height * 0.84,
          ),
          child: AuroraPanel(
            tint: _passTint(pass.type),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pass.type.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(switch (pass.type) {
                    BattlePassType.dailyKills =>
                      'Free rewards stay on the left, premium rewards stay on the right, and the center line tracks kill progress until the daily reset.',
                    BattlePassType.towerManagerPulls =>
                      'Free rewards stay on the left, premium rewards stay on the right, and Core Manager pulls advance the current pass. Completed passes remain available.',
                    BattlePassType.enemyManagerPulls =>
                      'Free rewards stay on the left, premium rewards stay on the right, and Threat Director pulls advance the current pass. Completed passes remain available.',
                    BattlePassType.enemyPulls =>
                      'Free rewards stay on the left, premium rewards stay on the right, and threat scans advance the current pass. Completed passes remain available.',
                  }, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
