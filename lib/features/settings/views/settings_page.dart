import 'package:flutter/material.dart';

import '../../../app/locale_preference.dart';
import '../../../l10n/app_localizations_context.dart';
import '../../../ui/core/app_colors.dart';
import '../../player/models/player_preferences.dart';
import '../widgets/release_update_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.localePreference,
    required this.isLocaleLoaded,
    required this.onLocalePreferenceSelected,
    required this.playerPreferences,
    required this.arePlayerPreferencesLoaded,
    required this.onPlayerPreferencesChanged,
  });

  final LocalePreference localePreference;
  final bool isLocaleLoaded;
  final Future<void> Function(LocalePreference) onLocalePreferenceSelected;
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
          key: const Key('language-setting'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: const Icon(Icons.language, size: 28),
          title: Text(l10n.languageSetting),
          subtitle: Text(_preferenceLabel(context, localePreference)),
          trailing: const Icon(Icons.chevron_right),
          onTap: isLocaleLoaded ? () => _showLanguageDialog(context) : null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            l10n.playerSettings,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
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
        const ReleaseUpdateTile(),
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
              child: Text('${context.l10n.playerQualityLimit}: ${value} Mbps'),
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

  Future<void> _showLanguageDialog(BuildContext context) async {
    final selection = await showDialog<LocalePreference>(
      context: context,
      builder: (context) => _LanguageDialog(selected: localePreference),
    );
    if (selection != null && selection != localePreference) {
      await onLocalePreferenceSelected(selection);
    }
  }

  String _preferenceLabel(BuildContext context, LocalePreference preference) =>
      switch (preference) {
        LocalePreference.system => context.l10n.languageAuto,
        LocalePreference.simplifiedChinese => context.l10n.languageChinese,
        LocalePreference.english => context.l10n.languageEnglish,
      };
}

class _LanguageDialog extends StatefulWidget {
  const _LanguageDialog({required this.selected});

  final LocalePreference selected;

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  late LocalePreference _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      key: const Key('language-dialog'),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: RadioGroup<LocalePreference>(
        groupValue: _selected,
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selected = value);
          Navigator.pop(context, value);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              value: LocalePreference.system,
              title: l10n.languageAuto,
              key: const Key('language-option-system'),
            ),
            _LanguageOption(
              value: LocalePreference.simplifiedChinese,
              title: l10n.languageChinese,
              key: const Key('language-option-zh'),
            ),
            _LanguageOption(
              value: LocalePreference.english,
              title: l10n.languageEnglish,
              key: const Key('language-option-en'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({super.key, required this.value, required this.title});

  final LocalePreference value;
  final String title;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<LocalePreference>(
      value: value,
      activeColor: AppColors.navy,
      title: Text(title),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      dense: true,
    );
  }
}
