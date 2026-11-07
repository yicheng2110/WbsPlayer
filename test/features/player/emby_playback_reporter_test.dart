import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wbs_player/features/player/models/player_media_source.dart';
import 'package:wbs_player/features/player/services/emby_playback_reporter.dart';

void main() {
  PlayerMediaSource source() => PlayerMediaSource(
    url: Uri.parse('http://emby.test/video'),
    headers: const {},
    mediaSourceId: 'source-1',
    playSessionId: 'session-1',
    playMethod: EmbyPlayMethod.directPlay,
  );

  test('converts duration to Emby ticks and back', () {
    const duration = Duration(seconds: 123, milliseconds: 456);
    final ticks = EmbyPlaybackReporter.durationToTicks(duration);
    expect(ticks, 1234560000);
    expect(EmbyPlaybackReporter.ticksToDuration(ticks), duration);
  });

  test(
    'reports start, throttles progress, reports state change and stops once',
    () async {
      final requests = <http.Request>[];
      final reporter = EmbyPlaybackReporter(
        progressInterval: const Duration(hours: 1),
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('', 204);
        }),
      );
      addTearDown(reporter.close);

      await reporter.onStart(
        serverAddress: 'http://emby.test:8096',
        accessToken: 'secret-token',
        userId: 'user-1',
        itemId: 'item-1',
        source: source(),
      );
      await reporter.onProgress(
        position: const Duration(seconds: 2),
        isPaused: false,
      );
      await reporter.onProgress(
        position: const Duration(seconds: 3),
        isPaused: true,
      );
      await reporter.onStop(position: const Duration(seconds: 4));
      await reporter.onStop();

      expect(requests, hasLength(3));
      expect(requests[0].url.path, '/emby/Sessions/Playing');
      expect(requests[0].headers['x-emby-token'], 'secret-token');
      expect(requests[1].url.path, '/emby/Sessions/Playing/Progress');
      final progress = jsonDecode(requests[1].body);
      expect(progress['IsPaused'], isTrue);
      expect(progress['PositionTicks'], 30000000);
      expect(requests[2].url.path, '/emby/Sessions/Playing/Stopped');
      expect(jsonDecode(requests[2].body)['PositionTicks'], 40000000);
    },
  );
}
