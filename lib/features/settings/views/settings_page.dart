import 'package:flutter/material.dart';

import '../../../app/locale_preference.dart';
import '../../../l10n/app_localizations_context.dart';
import '../../../ui/core/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.localePreference,
    required this.isLocaleLoaded,
    required this.onLocalePreferenceSelected,
  });

  final LocalePreference localePreference;
  final bool isLocaleLoaded;
  final Future<void> Function(LocalePreference) onLocalePreferenceSelected;

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
      ],
    );
  }

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
