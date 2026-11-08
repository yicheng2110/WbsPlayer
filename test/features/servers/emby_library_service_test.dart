import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wbs_player/features/servers/services/emby_api_response_cache.dart';
import 'package:wbs_player/features/servers/services/emby_library_service.dart';

void main() {
  test('loads TV libraries as series instead of individual episodes', () async {
    final requests = <http.Request>[];
    final service = EmbyLibraryService(
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/Users/user-1/Views')) {
          return http.Response(
            jsonEncode({
              'Items': [
                {
                  'Id': 'tv-library',
                  'Name': 'TV Shows',
                  'CollectionType': 'tvshows',
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/Users/user-1/Items/Latest')) {
          return http.Response('[]', 200);
        }
        if (request.url.path.endsWith('/Users/user-1/Items/Resume')) {
          return http.Response(
            jsonEncode({'Items': <Object>[], 'TotalRecordCount': 0}),
            200,
          );
        }
        if (request.url.path.endsWith('/Users/user-1/Items')) {
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'series-1', 'Name': 'Example series', 'Type': 'Series'},
              ],
              'TotalRecordCount': 1,
            }),
            200,
          );
        }
        return http.Response('', 404);
      }),
    );
    addTearDown(service.close);

    final home = await service.loadHome(
      serverAddress: 'http://emby.example:8096',
      accessToken: 'token',
      userId: 'user-1',
    );
    final library = home.libraries.single.library;
    expect(library.collectionType, 'tvshows');

    final page = await service.loadLibraryItems(
      serverAddress: 'http://emby.example:8096',
      accessToken: 'token',
      userId: 'user-1',
      parentId: library.id,
      collectionType: library.collectionType,
      sortBy: EmbyLibrarySort.title,
      ascending: true,
      startIndex: 0,
    );

    expect(page.items.single.type, 'Series');
    final itemsRequest = requests.singleWhere(
      (request) =>
          request.url.path.endsWith('/Users/user-1/Items') &&
          !request.url.path.endsWith('/Latest') &&
          !request.url.path.endsWith('/Resume'),
    );
    expect(itemsRequest.url.queryParameters['Recursive'], 'true');
    expect(itemsRequest.url.queryParameters['IncludeItemTypes'], 'Series');
  });

  test('caches library item pages and refresh bypasses the cache', () async {
    var requests = 0;
    final service = EmbyLibraryService(
      responseCache: EmbyApiResponseCache(),
      client: MockClient((request) async {
        requests++;
        return http.Response(
          jsonEncode({
            'Items': [
              {
                'Id': 'movie-$requests',
                'Name': 'Movie $requests',
                'Type': 'Movie',
              },
            ],
            'TotalRecordCount': 1,
          }),
          200,
        );
      }),
    );
    addTearDown(service.close);

    Future<EmbyLibraryItemPage> load({bool refresh = false}) =>
        service.loadLibraryItems(
          serverAddress: 'http://emby.test:8096',
          accessToken: 'token',
          userId: 'user-1',
          parentId: 'library-1',
          sortBy: EmbyLibrarySort.title,
          ascending: true,
          startIndex: 0,
          forceRefresh: refresh,
        );

    expect((await load()).items.single.id, 'movie-1');
    expect((await load()).items.single.id, 'movie-1');
    expect((await load(refresh: true)).items.single.id, 'movie-2');
    expect(requests, 2);
  });

  test('loads user views, resume list, and latest 20 per library', () async {
    final requests = <http.Request>[];
    final service = EmbyLibraryService(
      client: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        if (path.endsWith('/Users/user-1/Views')) {
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'library-1', 'Name': 'Movies'},
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/Users/user-1/Items/Latest')) {
          return http.Response(
            jsonEncode([
              {
                'Id': 'movie-1',
                'Name': 'Latest movie',
                'Type': 'Movie',
                'ImageTags': {'Primary': 'image-tag'},
              },
            ]),
            200,
          );
        }
        if (path.endsWith('/Users/user-1/Items/Resume')) {
          return http.Response(
            jsonEncode({'Items': <Object>[], 'TotalRecordCount': 0}),
            200,
          );
        }
        if (path.endsWith('/Users/user-1/Items') &&
            request.url.queryParameters['Filters'] == 'IsResumable') {
          return http.Response(
            jsonEncode({'Items': <Object>[], 'TotalRecordCount': 0}),
            200,
          );
        }
        return http.Response('', 404);
      }),
    );
    addTearDown(service.close);

    final home = await service.loadHome(
      serverAddress: 'http://emby.example:8096/emby',
      accessToken: 'access-token',
      userId: 'user-1',
    );

    expect(home.featured.single.name, 'Latest movie');
    expect(home.libraries.single.library.name, 'Movies');
    expect(home.libraries.single.items.single.primaryImageTag, 'image-tag');
    expect(home.recentlyPlayed, isEmpty);

    final latestRequests = requests
        .where((request) => request.url.path.endsWith('/Items/Latest'))
        .toList();
    expect(latestRequests, hasLength(2));
    expect(
      latestRequests.first.url.queryParameters,
      containsPair('Limit', '20'),
    );
    expect(
      latestRequests.last.url.queryParameters,
      containsPair('Limit', '10'),
    );
    expect(
      latestRequests.first.url.queryParameters,
      containsPair('ParentId', 'library-1'),
    );
    expect(
      requests.every(
        (request) => request.headers['x-emby-token'] == 'access-token',
      ),
      isTrue,
    );
    final resumeRequest = requests.singleWhere(
      (request) => request.url.path.endsWith('/Users/user-1/Items/Resume'),
    );
    expect(
      resumeRequest.url.queryParameters['Fields'],
      'ProductionYear,Overview',
    );
    expect(resumeRequest.url.queryParameters['MediaTypes'], 'Video');
    expect(resumeRequest.url.queryParameters['EnableUserData'], 'true');
    expect(resumeRequest.headers['x-emby-token'], 'access-token');
    expect(
      requests.where(
        (request) => request.url.path.endsWith('/Users/user-1/Items/Resume'),
      ),
      hasLength(1),
    );
    expect(
      requests.where(
        (request) =>
            request.url.path.endsWith('/Users/user-1/Items') &&
            request.url.queryParameters['Filters'] == 'IsResumable',
      ),
      isEmpty,
    );
  });

  test('loads continue-watching videos from Emby Resume endpoint', () async {
    final requests = <http.Request>[];
    final service = EmbyLibraryService(
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/Users/user-1/Views')) {
          return http.Response(jsonEncode({'Items': <Object>[]}), 200);
        }
        if (request.url.path.endsWith('/Users/user-1/Items/Resume')) {
          return http.Response(
            jsonEncode({
              'Items': [
                {
                  'Id': 'resume-1',
                  'Name': 'Next episode',
                  'Type': 'Episode',
                  'RunTimeTicks': 1000,
                  'UserData': {'PlaybackPositionTicks': 200},
                },
                {
                  'Id': 'resume-2',
                  'Name': 'Paused movie',
                  'Type': 'Movie',
                  'RunTimeTicks': 2000,
                  'UserData': {'PlaybackPositionTicks': 900},
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/Users/user-1/Items/Latest')) {
          return http.Response('[]', 200);
        }
        return http.Response('', 404);
      }),
    );
    addTearDown(service.close);

    final home = await service.loadHome(
      serverAddress: 'http://emby.example:8096',
      accessToken: 'access-token',
      userId: 'user-1',
    );

    expect(home.recentlyPlayed.map((item) => item.id), [
      'resume-1',
      'resume-2',
    ]);
    expect(home.recentlyPlayed.last.name, 'Paused movie');
    expect(home.recentlyPlayed.last.playbackPositionTicks, 900);
    final resumeRequests = requests
        .where(
          (request) => request.url.path.endsWith('/Users/user-1/Items/Resume'),
        )
        .toList();
    expect(resumeRequests, hasLength(1));
    expect(resumeRequests.single.url.queryParameters['MediaTypes'], 'Video');
    expect(
      resumeRequests.single.url.queryParameters['Fields'],
      'ProductionYear,Overview',
    );
    expect(resumeRequests.single.url.queryParameters['EnableUserData'], 'true');
    expect(resumeRequests.single.headers['x-emby-token'], 'access-token');
    expect(
      requests.where(
        (request) =>
            request.url.path.endsWith('/Users/user-1/Items') &&
            request.url.queryParameters['Filters'] == 'IsResumable',
      ),
      isEmpty,
    );
  });

  test('uses Emby item image URL and includes a supplied image cache tag', () {
    final service = EmbyLibraryService(
      client: MockClient((_) async => http.Response('', 200)),
    );
    addTearDown(service.close);

    final uri = service.imageUri(
      serverAddress: 'https://emby.example/proxy',
      itemId: 'item-1',
      imageTag: 'primary-tag',
      maxWidth: 640,
    );

    expect(uri.path, '/proxy/emby/Items/item-1/Images/Primary');
    expect(uri.queryParameters['tag'], 'primary-tag');
    expect(uri.queryParameters['maxWidth'], '640');
  });
}
