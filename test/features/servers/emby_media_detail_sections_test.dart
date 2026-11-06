import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:wbs_player/features/servers/models/emby_media_detail.dart';
import 'package:wbs_player/features/servers/models/emby_server.dart';
import 'package:wbs_player/features/servers/services/emby_library_service.dart';
import 'package:wbs_player/features/servers/widgets/emby_media_detail_sections.dart';

void main() {
  testWidgets('series details render their seasons and episode counts', (
    tester,
  ) async {
    final libraryService = EmbyLibraryService(
      client: MockClient((_) async => throw StateError('unexpected request')),
    );
    addTearDown(libraryService.close);
    const server = EmbyServer(
      name: 'Test server',
      address: 'http://emby.test:8096',
      username: 'user',
      password: 'password',
      accessToken: 'token',
      serverId: 'server-id',
      userId: 'user-id',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EmbyMediaDetailSections(
              detail: EmbyMediaDetail(
                id: 'series-1',
                name: 'Show',
                type: 'Series',
              ),
              similar: const [],
              seasons: const [
                EmbyMediaSeason(
                  id: 'season-1',
                  name: 'Season 1',
                  indexNumber: 1,
                  episodeCount: 8,
                ),
              ],
              mediaSources: const [],
              images: const [],
              server: server,
              libraryService: libraryService,
              text: (key) => switch (key) {
                'mediaDetailSeasons' => 'Seasons',
                'mediaDetailSeasonNumber' => 'Season {number}',
                'mediaDetailEpisodeCount' => '{count} episodes',
                _ => key,
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Seasons'), findsOneWidget);
    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('8 episodes'), findsOneWidget);
  });
}
