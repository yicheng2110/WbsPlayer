import 'package:flutter/material.dart';

import '../../player/models/player_preferences.dart';
import '../../../l10n/app_localizations_context.dart';

class PlayerSettingsPage extends StatelessWidget {
  const PlayerSettingsPage({
    super.key,
    required this.playerPreferences,
    required this.arePlayerPreferencesLoaded,
    required this.onPlayerPreferencesChanged,
  });

  final PlayerPreferences playerPreferences;
  final bool arePlayerPreferencesLoaded;
  final Future<void> Function(PlayerPreferences) onPlayerPreferencesChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        ListTile(
          key: const Key('player-quality-setting'),
          leading: const Icon(Icons.high_quality_outlined),
          title: Text(l10n.playerQuality),
          subtitle: Text(
            playerPreferences.maxStreamingBitrate == null
                ? l10n.playerQualityOriginal
                : '${l10n.playerQualityLimit}: ${_formatBitrate(playerPreferences.maxStreamingBitrate!)}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: arePlayerPreferencesLoaded
              ? () => _showQualityDialog(context)
              : null,
        ),
        ListTile(
          key: const Key('player-seek-backward-setting'),
          leading: const Icon(Icons.replay_rounded),
          title: Text(l10n.playerSeekBackward),
          trailing: DropdownButton<int>(
            value: playerPreferences.seekBackwardSeconds,
            items: [
              for (final seconds
                  in PlayerPreferences.seekDurationOptionsSeconds)
                DropdownMenuItem(
                  value: seconds,
                  child: Text(l10n.playerSeekSecondsValue(seconds)),
                ),
            ],
            onChanged: arePlayerPreferencesLoaded
                ? (value) {
                    if (value != null) {
                      onPlayerPreferencesChanged(
                        playerPreferences.copyWith(seekBackwardSeconds: value),
                      );
                    }
                  }
                : null,
          ),
        ),
        ListTile(
          key: const Key('player-seek-forward-setting'),
          leading: const Icon(Icons.forward_rounded),
          title: Text(l10n.playerSeekForward),
          trailing: DropdownButton<int>(
            value: playerPreferences.seekForwardSeconds,
            items: [
              for (final seconds
                  in PlayerPreferences.seekDurationOptionsSeconds)
                DropdownMenuItem(
                  value: seconds,
                  child: Text(l10n.playerSeekSecondsValue(seconds)),
                ),
            ],
            onChanged: arePlayerPreferencesLoaded
                ? (value) {
                    if (value != null) {
                      onPlayerPreferencesChanged(
                        playerPreferences.copyWith(seekForwardSeconds: value),
                      );
                    }
                  }
                : null,
          ),
        ),
        ListTile(
          key: const Key('player-drag-seek-duration-setting'),
          leading: const Icon(Icons.swipe_right_alt_rounded),
          title: Text(l10n.playerDragSeekDuration),
          trailing: DropdownButton<int>(
            value: playerPreferences.dragSeekDurationSeconds,
            items: [
              for (final seconds
                  in PlayerPreferences.dragSeekDurationOptionsSeconds)
                DropdownMenuItem(
                  value: seconds,
                  child: Text(l10n.playerDragSeekDurationValue(seconds ~/ 60)),
                ),
            ],
            onChanged: arePlayerPreferencesLoaded
                ? (value) {
                    if (value != null) {
                      onPlayerPreferencesChanged(
                        playerPreferences.copyWith(
                          dragSeekDurationSeconds: value,
                        ),
                      );
                    }
                  }
                : null,
          ),
        ),
        ListTile(
          key: const Key('player-subtitle-language-setting'),
          title: Text(l10n.playerSubtitleLanguage),
          leading: const Icon(Icons.subtitles_outlined),
          trailing: DropdownButton<String>(
            value:
                const {
                  '',
                  'zh',
                  'en',
                  'ja',
                }.contains(playerPreferences.subtitleLanguage)
                ? playerPreferences.subtitleLanguage
                : '',
            items: [
              DropdownMenuItem(value: '', child: Text(l10n.languageAuto)),
              DropdownMenuItem(value: 'zh', child: Text(l10n.languageChinese)),
              DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
              DropdownMenuItem(
                value: 'ja',
                child: Text(context.l10n.playerSubtitleJapanese),
              ),
            ],
            onChanged: arePlayerPreferencesLoaded
                ? (value) {
                    if (value != null) {
                      onPlayerPreferencesChanged(
                        playerPreferences.copyWith(subtitleLanguage: value),
                      );
                    }
                  }
                : null,
          ),
        ),
        ListTile(
          title: Text(l10n.playerSubtitleSize),
          leading: const Icon(Icons.format_size),
          subtitle: Slider(
            min: 18,
            max: 48,
            divisions: 10,
            value: playerPreferences.subtitleFontSize.clamp(18, 48),
            label: playerPreferences.subtitleFontSize.round().toString(),
            onChanged: arePlayerPreferencesLoaded
                ? (value) => onPlayerPreferencesChanged(
                    playerPreferences.copyWith(subtitleFontSize: value),
                  )
                : null,
          ),
        ),
        SwitchListTile(
          title: Text(l10n.playerAudioPassthrough),
          value: playerPreferences.audioPassthrough,
          onChanged: arePlayerPreferencesLoaded
              ? (value) => onPlayerPreferencesChanged(
                  playerPreferences.copyWith(audioPassthrough: value),
                )
              : null,
        ),
        SwitchListTile(
          title: Text(l10n.playerHardwareAcceleration),
          value: playerPreferences.hardwareAcceleration,
          onChanged: arePlayerPreferencesLoaded
              ? (value) => onPlayerPreferencesChanged(
                  playerPreferences.copyWith(hardwareAcceleration: value),
                )
              : null,
        ),
        SwitchListTile(
          key: const Key('player-cache-enabled-setting'),
          title: Text(l10n.playerCache),
          subtitle: Text(l10n.playerCacheDescription),
          value: playerPreferences.cacheEnabled,
          onChanged: arePlayerPreferencesLoaded
              ? (value) => onPlayerPreferencesChanged(
                  playerPreferences.copyWith(cacheEnabled: value),
                )
              : null,
        ),
        Column(
          key: const Key('player-cache-size-setting'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(l10n.playerCacheSize),
              subtitle: Text(
                l10n.playerCacheSizeValue(playerPreferences.cacheSizeMb),
              ),
              leading: const Icon(Icons.storage_outlined),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Slider(
                key: const Key('player-cache-size-slider'),
                min: PlayerPreferences.minCacheSizeMb.toDouble(),
                max: PlayerPreferences.maxCacheSizeMb.toDouble(),
                divisions:
                    (PlayerPreferences.maxCacheSizeMb -
                        PlayerPreferences.minCacheSizeMb) ~/
                    2,
                value: playerPreferences.cacheSizeMb.toDouble(),
                label: l10n.playerCacheSizeValue(playerPreferences.cacheSizeMb),
                onChanged:
                    arePlayerPreferencesLoaded && playerPreferences.cacheEnabled
                    ? (value) => onPlayerPreferencesChanged(
                        playerPreferences.copyWith(cacheSizeMb: value.round()),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showQualityDialog(BuildContext context) async {
    final bitrate = await showDialog<int?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.playerQuality),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, -1),
            child: Text(context.l10n.playerQualityOriginal),
          ),
          for (final value in [8, 20, 40, 80])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, value * 1000000),
              child: Text('${context.l10n.playerQualityLimit}: $value Mbps'),
            ),
        ],
      ),
    );
    if (bitrate != null) {
      await onPlayerPreferencesChanged(
        playerPreferences.copyWith(
          maxStreamingBitrate: bitrate < 0 ? null : bitrate,
          clearMaxStreamingBitrate: bitrate < 0,
        ),
      );
    }
  }

  String _formatBitrate(int bitsPerSecond) =>
      '${(bitsPerSecond / 1000000).round()} Mbps';
}
