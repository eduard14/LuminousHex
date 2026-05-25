part of '../friend_management_screen.dart';

class _GlobalChatPanel extends StatelessWidget {
  const _GlobalChatPanel({
    required this.controller,
    required this.overview,
    required this.error,
    required this.loading,
    required this.sending,
    required this.onRefresh,
    required this.onSend,
  });

  final TextEditingController controller;
  final LightcoreGlobalChatOverview? overview;
  final String? error;
  final bool loading;
  final bool sending;
  final VoidCallback onRefresh;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final messages = overview?.messages ?? const <LightcoreGlobalChatMessage>[];
    final banned =
        overview?.accountBanned == true || overview?.chatBanned == true;
    return AuroraPanel(
      tint: LightcorePalette.aether,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Global Chat',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              LightcoreInfoButton(
                title: 'Global Chat Rules',
                message:
                    'Global chat keeps 24 hours of messages. Repeating messages or posting too quickly triggers a 24-hour chat ban and warning. A second spam offense bans the account. Tracked bot messages are blocked and can ban immediately.',
                tint: LightcorePalette.aether,
              ),
              const SizedBox(width: 4),
              OutlinedButton.icon(
                onPressed: loading ? null : onRefresh,
                icon: loading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
                label: const Text('Sync'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Messages older than 24 hours are purged. Use /w playerUid message to whisper; whispers are only visible to sender and recipient.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LightcorePalette.mist.withValues(alpha: 0.72),
            ),
          ),
          if (error != null && error!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LightcorePalette.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: LightcorePalette.night.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: LightcorePalette.stroke.withValues(alpha: 0.36),
                ),
              ),
              child: messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          loading
                              ? 'Loading global chat...'
                              : 'No global messages in the last 24 hours.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _GlobalChatMessageBubble(
                          message: messages[index],
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !banned && !sending,
                  minLines: 1,
                  maxLines: 3,
                  maxLength: 180,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!banned && !sending) {
                      onSend();
                    }
                  },
                  decoration: InputDecoration(
                    counterText: '',
                    prefixIcon: const Icon(Icons.chat_bubble_rounded),
                    labelText: banned ? 'Chat locked' : 'Message global chat',
                    helperText:
                        'Use chat responsibly. Repeats and spam are blocked.',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'Send global message',
                onPressed: banned || sending ? null : onSend,
                icon: sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlobalChatMessageBubble extends StatelessWidget {
  const _GlobalChatMessageBubble({required this.message});

  final LightcoreGlobalChatMessage message;

  @override
  Widget build(BuildContext context) {
    final tint = message.isSystem
        ? LightcorePalette.solar
        : message.isWhisper
        ? LightcorePalette.violet
        : message.isLocalPlayer
        ? LightcorePalette.aether
        : LightcorePalette.verdant;
    final title = message.isSystem
        ? 'System'
        : message.isWhisper
        ? '${message.authorLabel} whisper'
        : message.authorLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tint.withValues(alpha: 0.24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    message.isWhisper
                        ? Icons.lock_rounded
                        : Icons.public_rounded,
                    size: 16,
                    color: tint,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: tint,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (message.isLocalPlayer)
                    Text(
                      'You',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: LightcorePalette.mist.withValues(alpha: 0.72),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                message.message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
