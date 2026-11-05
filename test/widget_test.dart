import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wbs_player/app/locale_preference_store.dart';
import 'package:wbs_player/app/wbs_player_app.dart';
import 'package:wbs_player/features/servers/data/server_database.dart';
import 'package:wbs_player/features/servers/repositories/drift_server_repository.dart';

void main() {
  testWidgets('renders the server home page', (WidgetTester tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale(
      'zh',
      'CN',
    );
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    final database = ServerDatabase(NativeDatabase.memory());
    final repository = DriftServerRepository(database: database);
    addTearDown(database.close);

    await tester.pumpWidget(
      WbsPlayerApp(
        serverRepository: repository,
        localePreferenceStore: _TestLocalePreferenceStore(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('服务器'), findsNWidgets(2));
    expect(find.byKey(const Key('add-server-button')), findsOneWidget);
  });
}

class _TestLocalePreferenceStore implements LocalePreferenceStore {
  @override
  Future<String?> read() async => 'zh';

  @override
  Future<void> write(String value) async {}
}
