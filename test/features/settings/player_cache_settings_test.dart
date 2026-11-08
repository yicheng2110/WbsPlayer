import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wbs_player/app/locale_preference.dart';
import 'package:wbs_player/features/player/models/player_preferences.dart';
import 'package:wbs_player/features/settings/views/player_settings_page.dart';
import 'package:wbs_player/features/settings/views/settings_page.dart';
import 'package:wbs_player/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('configures the swipe seek range', (tester) async {
    final preferences = ValueNotifier(const PlayerPreferences());
    addTearDown(preferences.dispose);
    await tester.pumpWidget(_SettingsHarness(preferences: preferences));
    await tester.tap(find.byKey(const Key('player-settings-entry')));
    await tester.pumpAndSettle();

    final setting = find.byKey(const Key('player-drag-seek-duration-setting'));
    await tester.ensureVisible(setting);
    await tester.pump();
    final dropdown = tester.widget<DropdownButton<int>>(
      find.descendant(of: setting, matching: find.byType(DropdownButton<int>)),
    );
    expect(dropdown.value, 600);
    expect(dropdown.items!.map((item) => item.value), [
      120,
      300,
      600,
      900,
      1800,
    ]);

    dropdown.onChanged!(900);
    await tester.pump();
    expect(preferences.value.dragSeekDurationSeconds, 900);
  });

  testWidgets('configures the playback cache switch and size slider', (
    tester,
  ) async {
    final preferences = ValueNotifier(const PlayerPreferences());
    addTearDown(preferences.dispose);
    await tester.pumpWidget(_SettingsHarness(preferences: preferences));

    expect(find.text('Player settings'), findsOneWidget);
    await tester.tap(find.byKey(const Key('player-settings-entry')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('player-cache-size-slider')),
    );
    await tester.pump();
    expect(find.text('64 MB'), findsOneWidget);
    final initialSlider = tester.widget<Slider>(
      find.byKey(const Key('player-cache-size-slider')),
    );
    expect(initialSlider.onChanged, isNotNull);
    expect(initialSlider.min, 2);
    expect(initialSlider.max, 1024);
    expect(initialSlider.divisions, 511);

    await tester.ensureVisible(
      find.byKey(const Key('player-cache-enabled-setting')),
    );
    await tester.tap(find.byKey(const Key('player-cache-enabled-setting')));
    await tester.pump();

    expect(preferences.value.cacheEnabled, isFalse);
    expect(
      tester
          .widget<Slider>(find.byKey(const Key('player-cache-size-slider')))
          .onChanged,
      isNull,
    );

    await tester.tap(find.byKey(const Key('player-cache-enabled-setting')));
    await tester.pump();
    expect(preferences.value.cacheEnabled, isTrue);

    final slider = tester.widget<Slider>(
      find.byKey(const Key('player-cache-size-slider')),
    );
    slider.onChanged!(128);
    await tester.pump();
    expect(preferences.value.cacheSizeMb, 128);
  });
}

class _SettingsHarness extends StatelessWidget {
  const _SettingsHarness({required this.preferences});

  final ValueNotifier<PlayerPreferences> preferences;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ValueListenableBuilder<PlayerPreferences>(
          valueListenable: preferences,
          builder: (context, _, _) => SettingsPage(
            localePreference: LocalePreference.system,
            isLocaleLoaded: true,
            onLocalePreferenceSelected: (_) async {},
            onPlayerSettingsTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => ValueListenableBuilder<PlayerPreferences>(
                    valueListenable: preferences,
                    builder: (context, playerPreferences, _) => Scaffold(
                      appBar: AppBar(title: const Text('Player settings')),
                      body: PlayerSettingsPage(
                        playerPreferences: playerPreferences,
                        arePlayerPreferencesLoaded: true,
                        onPlayerPreferencesChanged: (updated) async {
                          preferences.value = updated;
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
