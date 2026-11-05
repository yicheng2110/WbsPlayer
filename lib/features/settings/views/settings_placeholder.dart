import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_context.dart';

class SettingsPlaceholder extends StatelessWidget {
  const SettingsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.l10n.settingsTitle,
        style: const TextStyle(fontSize: 18, color: Colors.black54),
      ),
    );
  }
}
