import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wbs_player/features/servers/services/emby_library_service.dart';

void main() {
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
    expect(
      requests.any((request) => request.url.path.endsWith('/Items/Resume')),
      isTrue,
    );
    expect(
      requests.any(
        (request) =>
            request.url.path.endsWith('/Users/user-1/Items') &&
            request.url.queryParameters['Filters'] == 'IsResumable',
      ),
      isTrue,
    );
  });

  test(
    'merges Emby Resume and IsResumable results without duplicates',
    () async {
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
                ],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/Users/user-1/Items') &&
              request.url.queryParameters['Filters'] == 'IsResumable') {
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
      final resumableRequest = requests.singleWhere(
        (request) =>
            request.url.path.endsWith('/Users/user-1/Items') &&
            request.url.queryParameters['Filters'] == 'IsResumable',
      );
      expect(resumableRequest.url.queryParameters['Recursive'], 'true');
      expect(resumableRequest.url.queryParameters['EnableUserData'], 'true');
      expect(resumableRequest.headers['x-emby-token'], 'access-token');
    },
  );

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
