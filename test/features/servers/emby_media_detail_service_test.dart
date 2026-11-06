import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wbs_player/features/servers/services/emby_api_response_cache.dart';
import 'package:wbs_player/features/servers/services/emby_media_detail_service.dart';

void main() {
  test('loads series seasons and caches detail requests', () async {
    final requests = <http.Request>[];
    final cache = EmbyApiResponseCache();
    final service = EmbyMediaDetailService(
      responseCache: cache,
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/Users/user-1/Items/series-1')) {
          return http.Response(
            jsonEncode({
              'Id': 'series-1',
              'Name': 'Show',
              'Type': 'Series',
              'MediaSources': [],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/Seasons')) {
          return http.Response(
            jsonEncode({
              'Items': [
                {
                  'Id': 'season-1',
                  'Name': 'Season 1',
                  'IndexNumber': 1,
                  'ChildCount': 8,
                  'ImageTags': {'Primary': 'season-poster'},
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/Similar')) {
          return http.Response(jsonEncode({'Items': []}), 200);
        }
        if (request.url.path.endsWith('/Images')) {
          return http.Response(jsonEncode([]), 200);
        }
        if (request.url.path.endsWith('/PlaybackInfo')) {
          return http.Response(jsonEncode({'MediaSources': []}), 200);
        }
        return http.Response('', 404);
      }),
    );
    addTearDown(service.close);

    final detail = await service.loadDetail(
      serverAddress: 'http://emby.test:8096',
      accessToken: 'token-1',
      userId: 'user-1',
      itemId: 'series-1',
    );
    expect(detail.seasons, hasLength(1));
    expect(detail.seasons.single.indexNumber, 1);
    expect(detail.seasons.single.episodeCount, 8);
    expect(detail.seasons.single.primaryImageTag, 'season-poster');

    final requestCount = requests.length;
    expect(
      requests.where((request) => request.url.path.endsWith('/Seasons')),
      hasLength(1),
    );
    await service.loadDetail(
      serverAddress: 'http://emby.test:8096',
      accessToken: 'token-1',
      userId: 'user-1',
      itemId: 'series-1',
    );
    expect(requests, hasLength(requestCount));
    await service.loadDetail(
      serverAddress: 'http://emby.test:8096',
      accessToken: 'token-1',
      userId: 'user-1',
      itemId: 'series-1',
      forceRefresh: true,
    );
    expect(requests.length, greaterThan(requestCount));
    expect(
      requests.where((request) => request.url.path.endsWith('/Seasons')),
      hasLength(2),
    );
  });

  test('parses season and episode metadata for episode details', () async {
    final service = EmbyMediaDetailService(
      responseCache: EmbyApiResponseCache(),
      client: MockClient((request) async {
        if (request.url.path.endsWith('/Users/user-1/Items/episode-1')) {
          return http.Response(
            jsonEncode({
              'Id': 'episode-1',
              'Name': 'Pilot',
              'Type': 'Episode',
              'SeriesName': 'Show',
              'SeasonName': 'Season 1',
              'SeriesId': 'series-1',
              'SeasonId': 'season-1',
              'ParentIndexNumber': 1,
              'IndexNumber': 2,
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/Similar')) {
          return http.Response(jsonEncode({'Items': []}), 200);
        }
        if (request.url.path.endsWith('/Images')) {
          return http.Response(jsonEncode([]), 200);
        }
        if (request.url.path.endsWith('/PlaybackInfo')) {
          return http.Response(jsonEncode({'MediaSources': []}), 200);
        }
        return http.Response('', 404);
      }),
    );
    addTearDown(service.close);

    final detail = await service.getDetail(
      serverAddress: 'http://emby.test:8096',
      accessToken: 'token-1',
      userId: 'user-1',
      itemId: 'episode-1',
    );

    expect(detail.seriesName, 'Show');
    expect(detail.seasonName, 'Season 1');
    expect(detail.seriesId, 'series-1');
    expect(detail.seasonId, 'season-1');
    expect(detail.seasonNumber, 1);
    expect(detail.episodeNumber, 2);
    expect(detail.toJson()['ParentIndexNumber'], 1);
  });
}
