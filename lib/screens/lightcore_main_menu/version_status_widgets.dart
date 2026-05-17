part of '../lightcore_main_menu_screen.dart';

class _RailFooter extends StatelessWidget {
  const _RailFooter({
    required this.compact,
    required this.statusLine,
    required this.statusNote,
    required this.accent,
  });

  final bool compact;
  final String statusLine;
  final String statusNote;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: LightcorePalette.stroke.withValues(alpha: 0.18),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: compact ? 7 : 9,
        runSpacing: 2,
        children: [
          Text(
            statusLine.toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: accent.withValues(alpha: 0.9),
              fontSize: compact ? 9.5 : 10.5,
              letterSpacing: compact ? 0.8 : 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: LightcorePalette.layer2.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
          ),
          Text(
            statusNote.toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: LightcorePalette.layer2.withValues(alpha: 0.7),
              fontSize: compact ? 9 : 10,
              letterSpacing: compact ? 0.65 : 0.9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionAnchor extends StatelessWidget {
  const _VersionAnchor({required this.compact, required this.clientVersion});

  final bool compact;
  final String clientVersion;

  @override
  Widget build(BuildContext context) {
    final version = clientVersion.trim();
    if (version.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(compact ? 11 : 13),
        border: Border.all(
          color: LightcorePalette.stroke.withValues(alpha: 0.14),
        ),
      ),
      child: Text(
        'v$version'.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: LightcorePalette.layer2.withValues(alpha: 0.66),
          fontSize: compact ? 9 : 10,
          letterSpacing: compact ? 0.75 : 0.95,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          height: 1.05,
        ),
      ),
    );
  }
}

class _VersionNoticeCard extends StatelessWidget {
  const _VersionNoticeCard({
    required this.report,
    required this.showRefreshAction,
    required this.showAppStoreAction,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onOpenAppStore,
    required this.compact,
  });

  final LightcoreBootstrapReport report;
  final bool showRefreshAction;
  final bool showAppStoreAction;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onOpenAppStore;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final waitingForServer =
        report.requiresServerValidation && !report.serverValidated;
    final waitingForRestore = !report.restoreResolved;
    final maintenance = report.manifest.maintenanceMode;
    final accent = waitingForServer || waitingForRestore
        ? LightcorePalette.aether
        : LightcorePalette.warning;
    final icon = maintenance
        ? Icons.pause_circle_filled_rounded
        : waitingForRestore
        ? Icons.cloud_sync_rounded
        : waitingForServer
        ? Icons.sync_problem_rounded
        : Icons.system_update_alt_rounded;
    final olderThanRequired =
        report.versionResolved && !report.latestVersionSatisfied;
    final requiredServerVersion = report.requiredServerVersion;
    final label = maintenance
        ? 'Live paused'
        : waitingForRestore
        ? 'Restoring save'
        : waitingForServer
        ? 'Internet required'
        : 'Version blocked';
    final headline = maintenance
        ? 'Live startup is paused.'
        : waitingForRestore
        ? 'Cloud save restore did not finish.'
        : waitingForServer
        ? 'Internet connection required.'
        : olderThanRequired
        ? 'Your version is older than the required server version.'
        : 'Live build is $requiredServerVersion+.';
    final detail = maintenance
        ? 'The server is in maintenance mode right now.'
        : waitingForRestore
        ? 'Reconnect and retry. Launch stays locked until the cloud save and offline progress are restored.'
        : waitingForServer
        ? 'Reconnect and retry. Launch stays locked until the server confirms the current build.'
        : showAppStoreAction
        ? 'Current build is v${report.clientDisplayVersion}. Open the App Store to install v$requiredServerVersion+ before launch.'
        : showRefreshAction
        ? 'Current build is v${report.clientDisplayVersion}. Reloading the browser to fetch v$requiredServerVersion+ before launch.'
        : 'Current build is v${report.clientDisplayVersion}. Server requires v$requiredServerVersion+ before launch.';
    final targetLabel = waitingForServer || waitingForRestore
        ? 'Server'
        : 'Required server';
    final targetVersion = requiredServerVersion;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 430 : 560),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 20,
          vertical: compact ? 14 : 16,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 24 : 28),
          border: Border.all(color: accent.withValues(alpha: 0.48)),
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: waitingForServer ? 0.18 : 0.16),
              LightcorePalette.panelRaised.withValues(alpha: 0.96),
              LightcorePalette.panel.withValues(alpha: 0.98),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: waitingForServer ? 0.2 : 0.16),
              blurRadius: 26,
              spreadRadius: -10,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 38 : 42,
                  height: compact ? 38 : 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.32)),
                  ),
                  child: Icon(icon, size: compact ? 20 : 22, color: accent),
                ),
                SizedBox(width: compact ? 12 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: accent,
                          fontSize: compact ? 12 : 13,
                          letterSpacing: compact ? 1.5 : 1.9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: compact ? 4 : 6),
                      Text(
                        headline,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: LightcorePalette.layer2,
                              fontSize: compact ? 16 : 17,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 12 : 14),
            Text(
              detail,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.82),
                fontSize: compact ? 13.5 : 14.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: compact ? 12 : 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _VersionPill(
                  label: 'Current',
                  value: report.clientDisplayVersion,
                  accent: LightcorePalette.layer2.withValues(alpha: 0.82),
                ),
                _VersionPill(
                  label: targetLabel,
                  value: targetVersion,
                  accent: accent,
                ),
              ],
            ),
            if (showRefreshAction || showAppStoreAction) ...[
              SizedBox(height: compact ? 12 : 14),
              FilledButton.icon(
                onPressed: isRefreshing
                    ? null
                    : showAppStoreAction
                    ? onOpenAppStore
                    : onRefresh,
                icon: Icon(
                  isRefreshing
                      ? Icons.hourglass_top_rounded
                      : showAppStoreAction
                      ? Icons.storefront_rounded
                      : Icons.refresh_rounded,
                  size: compact ? 16 : 18,
                ),
                label: Text(
                  isRefreshing
                      ? 'Refreshing Web App'
                      : showAppStoreAction
                      ? 'Open App Store'
                      : 'Refresh Web App',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: accent.withValues(alpha: 0.2),
                  foregroundColor: accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionNoticeCard extends StatelessWidget {
  const _SessionNoticeCard({
    required this.message,
    required this.compact,
    required this.onReconnect,
  });

  final String message;
  final bool compact;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final accent = LightcorePalette.warning;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 430 : 560),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 20,
          vertical: compact ? 13 : 15,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 18 : 22),
          border: Border.all(color: accent.withValues(alpha: 0.42)),
          color: LightcorePalette.panelRaised.withValues(alpha: 0.92),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.14),
              blurRadius: 24,
              spreadRadius: -12,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_clock_rounded,
              color: accent,
              size: compact ? 20 : 22,
            ),
            SizedBox(width: compact ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SESSION EXPIRED',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: accent,
                      fontSize: compact ? 12 : 13,
                      letterSpacing: compact ? 1.3 : 1.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LightcorePalette.mist.withValues(alpha: 0.84),
                      fontSize: compact ? 13.5 : 14.5,
                      height: 1.34,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 12),
                  FilledButton.icon(
                    key: const ValueKey<String>('main-menu-reconnect-button'),
                    onPressed: onReconnect,
                    icon: Icon(Icons.refresh_rounded, size: compact ? 16 : 18),
                    label: const Text('Reconnect'),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent.withValues(alpha: 0.18),
                      foregroundColor: accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionPill extends StatelessWidget {
  const _VersionPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: accent.withValues(alpha: 0.8),
                letterSpacing: 0.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: LightcorePalette.layer2,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
