import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wbs_player/features/servers/models/emby_media.dart';
import 'package:wbs_player/features/servers/models/emby_server.dart';
import 'package:wbs_player/features/servers/services/emby_library_service.dart';
import 'package:wbs_player/features/servers/services/emby_server_service.dart';
import 'package:wbs_player/features/servers/views/emby_library_page.dart';
import 'package:wbs_player/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('searching a library sends the search term to Emby', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final libraryService = EmbyLibraryService(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({'Items': <Object>[], 'TotalRecordCount': 0}),
          200,
        );
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
        home: EmbyLibraryPage(
          library: const EmbyLibrary(
            id: 'movies',
            name: 'Movies',
            collectionType: 'movies',
          ),
          server: const EmbyServer(
            name: 'Test server',
            address: 'http://emby.test:8096',
            username: 'user',
            password: 'password',
            accessToken: 'token',
            serverId: 'server',
            userId: 'user-1',
          ),
          serverService: serverService,
          serverRepository: null,
          libraryService: libraryService,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const Key('emby-library-search-button')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('emby-library-search-field')),
      'Arrival',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    final searchRequest = requests.lastWhere(
      (request) => request.url.queryParameters.containsKey('SearchTerm'),
    );
    expect(searchRequest.url.queryParameters['SearchTerm'], 'Arrival');
    expect(searchRequest.url.queryParameters['IncludeItemTypes'], 'Movie');
    expect(find.text('No matching movies or series'), findsOneWidget);

    await tester.tap(find.byKey(const Key('emby-library-search-clear-button')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('No items yet'), findsOneWidget);
  });
}
