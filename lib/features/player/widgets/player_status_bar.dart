import 'package:flutter/material.dart';

/// Persistent player status showing local time and estimated stream speed.
class PlayerStatusBar extends StatelessWidget {
  const PlayerStatusBar({
    super.key,
    required this.time,
    required this.streamLoadBytesPerSecond,
  });

  final DateTime time;
  final double? streamLoadBytesPerSecond;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        child: Row(
          children: [
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              key: const Key('player-status-time'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            Icon(
              Icons.network_check_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Text(
              formatStreamLoadSpeed(streamLoadBytesPerSecond),
              key: const Key('player-status-network-speed'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  static String formatStreamLoadSpeed(double? bytesPerSecond) =>
      bytesPerSecond == null
      ? '\u2014'
      : '${(bytesPerSecond * 8 / 1000000).toStringAsFixed(1)} Mbps';
}
