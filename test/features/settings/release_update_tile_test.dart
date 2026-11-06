import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wbs_player/features/settings/widgets/release_update_tile.dart';
import 'package:wbs_player/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('shows the update setting on Android', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ReleaseUpdateTile(isAndroid: true)),
      ),
    );

    expect(find.byKey(const Key('check-for-updates')), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
  });
}
