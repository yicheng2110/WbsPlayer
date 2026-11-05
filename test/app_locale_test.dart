import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wbs_player/features/servers/models/emby_server.dart';
import 'package:wbs_player/app/locale_preference.dart';
import 'package:wbs_player/app/locale_preference_store.dart';
import 'package:wbs_player/app/wbs_player_app.dart';
import 'package:wbs_player/features/servers/repositories/server_repository.dart';
import 'package:wbs_player/features/servers/views/server_home_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('follows system locale by default on first launch', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale(
      'en',
      'US',
    );
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(
      WbsPlayerApp(
        localePreferenceStore: _MemoryLocalePreferenceStore(),
        serverRepository: _EmptyServerRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Servers'), findsNWidgets(2));
  });

  testWidgets('switches language immediately and restores it after restart', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale(
      'en',
      'US',
    );
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    final store = _MemoryLocalePreferenceStore();

    await tester.pumpWidget(
      WbsPlayerApp(
        localePreferenceStore: store,
        serverRepository: _EmptyServerRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Servers'), findsNWidgets(2));
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Auto'), findsOneWidget);
    await tester.tap(find.byKey(const Key('language-setting')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('language-dialog')), findsOneWidget);
    await tester.tap(find.text('Simplified Chinese'));
    await tester.pumpAndSettle();

    expect(store.value, 'zh');
    expect(find.text('服务器'), findsOneWidget);
    expect(find.text('语言'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      WbsPlayerApp(
        localePreferenceStore: store,
        serverRepository: _EmptyServerRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('服务器'), findsNWidgets(2));
  });

  test('unknown stored language falls back to following system', () {
    expect(
      LocalePreference.fromStoredValue('unsupported'),
      LocalePreference.system,
    );
  });

  testWidgets(
    'falls back to Simplified Chinese for unsupported system locale',
    (tester) async {
      tester.binding.platformDispatcher.localesTestValue = const [
        Locale('ja', 'JP'),
      ];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(
        WbsPlayerApp(
          localePreferenceStore: _MemoryLocalePreferenceStore(),
          serverRepository: _EmptyServerRepository(),
        ),
      );
      await tester.pumpAndSettle();

      final appContext = tester.element(find.byType(ServerHomePage));
      expect(Localizations.localeOf(appContext).languageCode, 'zh');
      expect(find.text('服务器'), findsNWidgets(2));
    },
  );
}

class _MemoryLocalePreferenceStore implements LocalePreferenceStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}

class _EmptyServerRepository implements ServerRepository {
  @override
  Future<List<EmbyServer>> getAllServers() async => const [];

  @override
  Future<EmbyServer> saveServer(EmbyServer server) async => server;

  @override
  Future<void> close() async {}
}
