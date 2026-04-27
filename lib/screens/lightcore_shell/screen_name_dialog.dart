part of '../lightcore_shell.dart';

class _ScreenNameDialog extends StatefulWidget {
  const _ScreenNameDialog({
    required this.controller,
    required this.onSaveScreenName,
  });

  final LightcoreController controller;
  final Future<void> Function(String screenName) onSaveScreenName;

  @override
  State<_ScreenNameDialog> createState() => _ScreenNameDialogState();
}

class _ScreenNameDialogState extends State<_ScreenNameDialog> {
  late final TextEditingController _screenNameController;
  late final FocusNode _screenNameFocusNode;
  late String _lastSyncedScreenName;
  bool _saving = false;
  String? _errorText;

  LightcoreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _lastSyncedScreenName = controller.screenName ?? '';
    _screenNameController = TextEditingController.fromValue(
      TextEditingValue(
        text: _lastSyncedScreenName,
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: _lastSyncedScreenName.length,
        ),
      ),
    );
    _screenNameFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _ScreenNameDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = widget.controller.screenName ?? '';
    if (nextValue == _lastSyncedScreenName) {
      return;
    }
    _lastSyncedScreenName = nextValue;
    if (!_screenNameFocusNode.hasFocus &&
        _screenNameController.text != nextValue) {
      _screenNameController.value = TextEditingValue(
        text: nextValue,
        selection: TextSelection.collapsed(offset: nextValue.length),
      );
    }
  }

  @override
  void dispose() {
    _screenNameController.dispose();
    _screenNameFocusNode.dispose();
    super.dispose();
  }

  void _handleScreenNameChanged(String value) {
    if (_errorText == null) {
      return;
    }
    final validationError = controller.validateScreenName(value);
    if (validationError == _errorText) {
      return;
    }
    setState(() => _errorText = validationError);
  }

  Future<void> _submit() async {
    final validationError = controller.validateScreenName(
      _screenNameController.text,
    );
    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    final normalized = controller.normalizeScreenName(
      _screenNameController.text,
    );
    try {
      await widget.onSaveScreenName(normalized);
      if (!mounted) {
        return;
      }
      _lastSyncedScreenName = widget.controller.screenName ?? normalized;
      _screenNameController.value = TextEditingValue(
        text: _lastSyncedScreenName,
        selection: TextSelection.collapsed(
          offset: _lastSyncedScreenName.length,
        ),
      );
      Navigator.of(context).pop();
    } on LightcoreScreenNameUpdateException catch (error) {
      if (mounted) {
        setState(() => _errorText = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorText = 'Unable to verify that screen name right now.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = controller.canEditScreenName;
    final tutorialActive =
        controller.tutorialStep == LightcoreTutorialStep.setScreenName;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: AuroraPanel(
          tint: tutorialActive
              ? LightcorePalette.warning
              : controller.activeLayer.core.affinity.color,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Change Name',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unlocked
                            ? controller.hasCustomScreenName
                                  ? 'Current tournament name: ${controller.playerDisplayName}.'
                                  : 'Set the public name shown on tournament boards.'
                            : 'Screen names unlock with tournaments at Account Radiance Lv ${LightcoreController.tournamentUnlockLevel}. You are currently ${controller.accountRadianceLabel}.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (tutorialActive) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Tutorial: save a public screen name before entering tournament rooms.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: LightcorePalette.warning,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextField(
                        key: const ValueKey<String>('player-screen-name-field'),
                        controller: _screenNameController,
                        focusNode: _screenNameFocusNode,
                        enabled: unlocked && !_saving,
                        autofocus: unlocked,
                        textInputAction: TextInputAction.done,
                        onChanged: _handleScreenNameChanged,
                        onSubmitted: unlocked && !_saving
                            ? (_) => _submit()
                            : null,
                        decoration: InputDecoration(
                          labelText: 'Screen Name',
                          hintText: unlocked
                              ? 'Enter your tournament callsign'
                              : 'Unlocks at Account Radiance Lv 20',
                          errorText: _errorText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: GuidedFocusFrame(
                  active: tutorialActive,
                  tint: LightcorePalette.quest,
                  radius: 18,
                  label: 'SAVE',
                  child: FilledButton.icon(
                    key: const ValueKey<String>('save-screen-name-button'),
                    onPressed: unlocked && !_saving ? _submit : null,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.badge_rounded),
                    label: Text(
                      controller.hasCustomScreenName ? 'Update' : 'Save',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorDialog extends StatelessWidget {
  const _SelectorDialog({
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color tint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.76,
        ),
        child: AuroraPanel(
          tint: tint,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorChoiceCard extends StatelessWidget {
  const _SelectorChoiceCard({
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.selected,
    required this.leading,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color tint;
  final bool selected;
  final Widget leading;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? tint.withValues(alpha: 0.92)
                  : LightcorePalette.stroke.withValues(alpha: 0.72),
            ),
            gradient: LinearGradient(
              colors: [
                tint.withValues(alpha: selected ? 0.22 : 0.1),
                LightcorePalette.panel.withValues(alpha: 0.98),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        color: LightcorePalette.mist,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: LightcorePalette.mist.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _LayerPickerSectionHeader extends StatelessWidget {
  const _LayerPickerSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: LightcorePalette.mist,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: LightcorePalette.mist.withValues(alpha: 0.72),
            height: 1.28,
          ),
        ),
      ],
    );
  }
}

class _LayerChoiceLeading extends StatelessWidget {
  const _LayerChoiceLeading({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: tint.withValues(alpha: 0.14),
        border: Border.all(color: tint.withValues(alpha: 0.38)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: tint,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LayerChoiceTrailing extends StatelessWidget {
  const _LayerChoiceTrailing({
    required this.tint,
    required this.markerLabel,
    required this.progressLabel,
  });

  final Color tint;
  final String? markerLabel;
  final String progressLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (markerLabel != null) ...[
          _RailMarker(label: markerLabel!, tint: tint),
          const SizedBox(height: 6),
        ],
        Text(
          progressLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: LightcorePalette.mist.withValues(alpha: 0.76),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RailMarker extends StatelessWidget {
  const _RailMarker({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tint,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
