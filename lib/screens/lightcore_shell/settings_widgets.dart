part of '../lightcore_shell.dart';

class _SettingsStatEntry {
  const _SettingsStatEntry({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.tint,
    required this.icon,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color tint;
  final IconData icon;
}

class _SettingsStatsGrid extends StatelessWidget {
  const _SettingsStatsGrid({required this.entries});

  final List<_SettingsStatEntry> entries;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 430
            ? 1
            : width < 760
            ? 2
            : 3;
        final aspectRatio = switch (columns) {
          1 => 3.6,
          2 => 1.7,
          _ => 1.32,
        };

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            return _SettingsStatCard(entry: entries[index]);
          },
        );
      },
    );
  }
}

class _SettingsStatCard extends StatelessWidget {
  const _SettingsStatCard({required this.entry});

  final _SettingsStatEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: entry.tint.withValues(alpha: 0.45)),
        gradient: LinearGradient(
          colors: [
            entry.tint.withValues(alpha: 0.12),
            LightcorePalette.panelRaised.withValues(alpha: 0.98),
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.tint.withValues(alpha: 0.16),
                  ),
                  child: Icon(entry.icon, size: 16, color: entry.tint),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.label,
                    style: textTheme.labelLarge?.copyWith(
                      color: LightcorePalette.mist,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              entry.value,
              style: textTheme.headlineSmall?.copyWith(
                color: entry.tint,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entry.subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.72),
                height: 1.28,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsVersionFooter extends StatelessWidget {
  const _SettingsVersionFooter({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final displayVersion = version.trim();
    if (displayVersion.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Semantics(
        label: 'App version $displayVersion',
        child: Text(
          'v$displayVersion'.toUpperCase(),
          key: const ValueKey<String>('settings-version-number'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: LightcorePalette.mist.withValues(alpha: 0.56),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
            letterSpacing: 0,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.switchKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.tint,
    required this.onChanged,
  });

  final Key switchKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color tint;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.26)),
        color: LightcorePalette.panelRaised.withValues(alpha: 0.54),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0.14),
              ),
              child: Icon(icon, color: tint, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      color: LightcorePalette.mist.withValues(alpha: 0.74),
                      height: 1.28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Switch.adaptive(
              key: switchKey,
              value: value,
              activeThumbColor: tint,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
