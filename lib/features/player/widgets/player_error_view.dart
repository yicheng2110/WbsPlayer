import 'package:flutter/material.dart';

/// Error state shown when playback resolution or the player engine fails.
class PlayerErrorView extends StatelessWidget {
  const PlayerErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onBack,
    this.retryLabel = 'Retry',
    this.backLabel = 'Back',
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final String retryLabel;
  final String backLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 54),
            const SizedBox(height: 16),
            Text(
              message,
              key: const Key('player-error-message'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [
                OutlinedButton(onPressed: onBack, child: Text(backLabel)),
                FilledButton(onPressed: onRetry, child: Text(retryLabel)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
