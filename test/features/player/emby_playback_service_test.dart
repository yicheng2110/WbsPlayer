import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wbs_player/features/player/models/player_media_source.dart';
import 'package:wbs_player/features/player/services/emby_playback_service.dart';
import 'package:wbs_player/features/servers/models/emby_media_detail.dart';

void main() {
  const sourceId = 'source-1';

  test(
    'prefers DirectPlay and resolves relative URL with token header',
    () async {
      late http.Request request;
      final service = EmbyPlaybackService(
        playSessionIdGenerator: () => 'generated-session',
        client: MockClient((value) async {
          request = value;
          return http.Response(
            jsonEncode({
              'PlaySessionId': 'session-from-server',
              'MediaSources': [
                {
                  'Id': sourceId,
                  'DirectStreamUrl': '/Videos/item-1/stream.mkv',
                  'SupportsDirectPlay': true,
                  'SupportsDirectStream': true,
                  'RequiredHttpHeaders': {'Accept': 'video/*'},
                },
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);

      final resolved = await service.resolve(
        serverAddress: 'http://emby.test:8096/base',
        accessToken: 'secret-token',
        userId: 'user-1',
        itemId: 'item-1',
        mediaSource: EmbyMediaSource(id: sourceId, name: '1080p'),
        audioStreamIndex: 2,
      );

      expect(request.url.path, '/base/emby/Items/item-1/PlaybackInfo');
      expect(request.headers['x-emby-token'], 'secret-token');
      expect(request.url.query, isEmpty);
      expect(jsonDecode(request.body)['AudioStreamIndex'], 2);
      expect(
        resolved.url.toString(),
        'http://emby.test:8096/Videos/item-1/stream.mkv',
      );
      expect(resolved.playMethod, EmbyPlayMethod.directPlay);
      expect(resolved.headers, {
        'Accept': 'video/*',
        'X-Emby-Token': 'secret-token',
      });
      expect(resolved.playSessionId, 'session-from-server');
      expect(jsonDecode(request.body)['DeviceProfile'], isA<Map>());
    },
  );

  test('uses DirectStream when DirectPlay is unsupported', () async {
    final service = EmbyPlaybackService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'MediaSources': [
              {
                'Id': sourceId,
                'DirectStreamUrl': 'http://emby.test/stream',
                'SupportsDirectPlay': false,
                'SupportsDirectStream': true,
              },
            ],
          }),
          200,
        ),
      ),
    );
    addTearDown(service.close);

    final resolved = await service.resolve(
      serverAddress: 'http://emby.test',
      accessToken: 'token',
      userId: 'user',
      itemId: 'item',
      mediaSource: EmbyMediaSource(id: sourceId, name: 'Version'),
    );
    expect(resolved.playMethod, EmbyPlayMethod.directStream);
  });

  test(
    'does not forward required or Emby auth headers to a foreign CDN',
    () async {
      final service = EmbyPlaybackService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'MediaSources': [
                {
                  'Id': sourceId,
                  'DirectStreamUrl': 'https://cdn.example/stream',
                  'SupportsDirectPlay': true,
                  'RequiredHttpHeaders': {
                    'X-CDN-Key': 'private',
                    'X-Emby-Token': 'overridden',
                  },
                },
              ],
            }),
            200,
          ),
        ),
      );
      addTearDown(service.close);

      final resolved = await service.resolve(
        serverAddress: 'http://emby.test',
        accessToken: 'secret',
        userId: 'user',
        itemId: 'item',
        mediaSource: EmbyMediaSource(id: sourceId, name: 'Version'),
      );
      expect(resolved.headers, isEmpty);
    },
  );

  test('downloads external subtitles with authentication', () async {
    late http.Request request;
    final service = EmbyPlaybackService(
      client: MockClient((value) async {
        request = value;
        return http.Response('subtitle data', 200);
      }),
    );
    addTearDown(service.close);

    final content = await service.loadExternalSubtitle(
      serverAddress: 'http://emby.test:8096/proxy',
      accessToken: 'secret',
      itemId: 'item-1',
      mediaSourceId: sourceId,
      subtitle: const EmbyMediaStream(
        index: 4,
        type: 'Subtitle',
        codec: 'SubRip',
        isExternal: true,
      ),
    );
    expect(content, 'subtitle data');
    expect(
      request.url.path,
      '/proxy/emby/Videos/item-1/source-1/Subtitles/4/Stream.srt',
    );
    expect(request.headers['x-emby-token'], 'secret');
  });

  test('selects HLS transcoding when a bitrate limit is configured', () async {
    final service = EmbyPlaybackService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'PlaySessionId': 'session-hls',
            'MediaSources': [
              {
                'Id': sourceId,
                'DirectStreamUrl': '/source.mkv',
                'TranscodingUrl': '/Videos/item/master.m3u8',
                'SupportsDirectPlay': true,
              },
            ],
          }),
          200,
        ),
      ),
    );
    addTearDown(service.close);

    final resolved = await service.resolve(
      serverAddress: 'http://emby.test:8096',
      accessToken: 'token',
      userId: 'user',
      itemId: 'item',
      mediaSource: EmbyMediaSource(id: sourceId, name: 'Version'),
      maxStreamingBitrate: 20000000,
    );
    expect(resolved.playMethod, EmbyPlayMethod.transcode);
    expect(resolved.url.path, '/Videos/item/master.m3u8');
    expect(resolved.supportsTranscoding, isTrue);
  });

  test('throws a readable error when no direct URL is available', () async {
    final service = EmbyPlaybackService(
      client: MockClient(
        (_) async => http.Response(jsonEncode({'MediaSources': []}), 200),
      ),
    );
    addTearDown(service.close);
    expect(
      () => service.resolve(
        serverAddress: 'http://emby.test',
        accessToken: 'token',
        userId: 'user',
        itemId: 'item',
        mediaSource: EmbyMediaSource(id: sourceId, name: 'Version'),
      ),
      throwsA(isA<EmbyPlaybackException>()),
    );
  });

  test(
    'sends requested quality and never returns query tokens in URLs',
    () async {
      final service = EmbyPlaybackService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'MediaSources': [
                {
                  'Id': sourceId,
                  'DirectStreamUrl':
                      'http://emby.test/stream?api_key=secret&x=1&x=2',
                  'SupportsDirectPlay': true,
                },
              ],
            }),
            200,
          ),
        ),
      );
      addTearDown(service.close);
      final resolved = await service.resolve(
        serverAddress: 'http://emby.test',
        accessToken: 'secret',
        userId: 'user',
        itemId: 'item',
        mediaSource: EmbyMediaSource(id: sourceId, name: 'Version'),
        maxStreamingBitrate: 20000000,
      );
      expect(resolved.url.queryParametersAll, {
        'x': ['1', '2'],
      });
    },
  );
}
