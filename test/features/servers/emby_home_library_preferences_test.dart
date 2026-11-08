import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wbs_player/features/servers/models/emby_library_preferences.dart';
import 'package:wbs_player/features/servers/models/emby_media.dart';
import 'package:wbs_player/features/servers/models/emby_server.dart';
import 'package:wbs_player/features/servers/services/emby_library_preferences_store.dart';
import 'package:wbs_player/features/servers/services/emby_library_service.dart';
import 'package:wbs_player/features/servers/services/emby_server_service.dart';
import 'package:wbs_player/features/servers/views/emby_home_page.dart';
import 'package:wbs_player/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('home shows libraries in saved order and hides disabled ones', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final preferencesStore = SharedPreferencesEmbyLibraryPreferencesStore();
    await preferencesStore.write(
      'server-id',
      const EmbyLibraryPreferences(
        order: ['a', 'b', 'c'],
        hiddenLibraryIds: {'b'},
      ),
    );
    final libraryService = EmbyLibraryService(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/Users/user-id/Views')) {
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'c', 'Name': 'C', 'CollectionType': 'movies'},
                {'Id': 'b', 'Name': 'B', 'CollectionType': 'movies'},
                {'Id': 'a', 'Name': 'A', 'CollectionType': 'movies'},
              ],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/Users/user-id/Items/Resume')) {
          return http.Response(
            jsonEncode({'Items': <Object>[], 'TotalRecordCount': 0}),
            200,
          );
        }
        if (request.url.path.endsWith('/Users/user-id/Items/Latest')) {
          return http.Response('[]', 200);
        }
        return http.Response('', 404);
      }),
    );
    final serverService = EmbyServerService(
      client: MockClient((_) async => http.Response('', 200)),
    );
    addTearDown(libraryService.close);
    addTearDown(serverService.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: EmbyHomePage(
          server: const EmbyServer(
            name: 'Test server',
            address: 'http://emby.test:8096',
            username: 'user',
            password: 'password',
            accessToken: 'token',
            serverId: 'server-id',
            userId: 'user-id',
          ),
          serverService: serverService,
          libraryService: libraryService,
          libraryPreferencesStore: preferencesStore,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('A')).dy,
      lessThan(tester.getTopLeft(find.text('C')).dy),
    );
  });
}
