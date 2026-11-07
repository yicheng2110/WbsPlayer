import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:media_kit/media_kit.dart';
import 'package:wbs_player/features/player/services/emby_playback_reporter.dart';
import 'package:wbs_player/features/player/services/emby_playback_service.dart';
import 'package:wbs_player/features/player/services/playback_engine.dart';
import 'package:wbs_player/features/player/view_models/player_view_model.dart';
import 'package:wbs_player/features/servers/models/emby_media_detail.dart';

void main() {
  test('opens at resume position, seeks and reports a session', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/PlaybackInfo')) {
        return http.Response(
          jsonEncode({
            'PlaySessionId': 'session-1',
            'MediaSources': [
              {
                'Id': 'source-1',
                'DirectStreamUrl': '/video.mkv',
                'SupportsDirectPlay': true,
              },
            ],
          }),
          200,
        );
      }
      return http.Response('', 204);
    });
    final service = EmbyPlaybackService(client: client);
    final reporter = EmbyPlaybackReporter(client: client);
    final engine = _FakePlaybackEngine();
    final viewModel = PlayerViewModel(
      serverAddress: 'http://emby.test:8096',
      accessToken: 'token',
      userId: 'user-1',
      itemId: 'item-1',
      detail: EmbyMediaDetail(
        id: 'item-1',
        name: 'Test movie',
        type: 'Movie',
        playbackPositionTicks: 1200000000,
      ),
      mediaSource: EmbyMediaSource(id: 'source-1', name: 'Original'),
      audioStream: null,
      playbackService: service,
      reporter: reporter,
      engine: engine,
    );
    addTearDown(() async {
      viewModel.dispose();
      await Future<void>.delayed(Duration.zero);
      client.close();
    });

    await viewModel.open();
    expect(viewModel.state.hasError, isFalse);
    expect(engine.openedMedia, isNotNull);
    expect(engine.openedMedia!.uri, 'http://emby.test:8096/video.mkv');
    expect(engine.openedMedia!.start, const Duration(seconds: 120));
    expect(
      requests.map((request) => request.url.path),
      contains('/emby/Sessions/Playing'),
    );

    await viewModel.seek(const Duration(seconds: 10));
    expect(engine.lastSeek, const Duration(seconds: 10));
    expect(
      requests.map((request) => request.url.path),
      contains('/emby/Sessions/Playing/Progress'),
    );
  });

  test(
    'exposes a readable error and does not report an unresolved session',
    () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'MediaSources': []}), 200),
      );
      final service = EmbyPlaybackService(client: client);
      final reporter = EmbyPlaybackReporter(client: client);
      final engine = _FakePlaybackEngine();
      final viewModel = PlayerViewModel(
        serverAddress: 'http://emby.test',
        accessToken: '',
        userId: 'user',
        itemId: 'item',
        detail: EmbyMediaDetail(id: 'item', name: 'Test', type: 'Movie'),
        mediaSource: EmbyMediaSource(id: 'source', name: 'Source'),
        audioStream: null,
        playbackService: service,
        reporter: reporter,
        engine: engine,
      );
      addTearDown(() async {
        viewModel.dispose();
        await Future<void>.delayed(Duration.zero);
        client.close();
      });

      await viewModel.open();
      expect(viewModel.state.hasError, isTrue);
      expect(viewModel.state.error, contains('noPlayableUrl'));
      expect(engine.openedMedia, isNull);
    },
  );
}

class _FakePlaybackEngine implements PlaybackEngine {
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration>.broadcast();
  final _buffer = StreamController<Duration>.broadcast();
  final _volume = StreamController<double>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _buffering = StreamController<bool>.broadcast();
  final _completed = StreamController<bool>.broadcast();
  final _tracks = StreamController<Tracks>.broadcast();
  final _track = StreamController<Track>.broadcast();
  final _videoParams = StreamController<VideoParams>.broadcast();
  final _width = StreamController<int?>.broadcast();
  final _height = StreamController<int?>.broadcast();
  final _audioBitrate = StreamController<double?>.broadcast();
  final _rate = StreamController<double>.broadcast();
  final _error = StreamController<String>.broadcast();

  Media? openedMedia;
  Duration? lastSeek;
  double currentVolume = 100;
  bool disposed = false;

  @override
  Stream<Duration> get position => _position.stream;
  @override
  Stream<Duration> get duration => _duration.stream;
  @override
  Stream<Duration> get buffer => _buffer.stream;
  @override
  Stream<double> get volume => _volume.stream;
  @override
  Stream<bool> get playing => _playing.stream;
  @override
  Stream<bool> get buffering => _buffering.stream;
  @override
  Stream<bool> get completed => _completed.stream;
  @override
  Stream<Tracks> get tracks => _tracks.stream;
  @override
  Stream<Track> get track => _track.stream;
  @override
  Stream<VideoParams> get videoParams => _videoParams.stream;
  @override
  Stream<int?> get videoWidth => _width.stream;
  @override
  Stream<int?> get videoHeight => _height.stream;
  @override
  Stream<double?> get audioBitrateEvents => _audioBitrate.stream;
  @override
  Stream<double> get rate => _rate.stream;
  @override
  Stream<String> get error => _error.stream;
  @override
  int? get width => null;
  @override
  int? get height => null;
  @override
  String? get videoCodec => null;
  @override
  double? get audioBitrate => null;

  @override
  Future<void> open(Media media) async {
    openedMedia = media;
  }

  @override
  Future<void> play() async => _playing.add(true);
  @override
  Future<void> pause() async => _playing.add(false);
  @override
  Future<void> seek(Duration position) async => lastSeek = position;
  @override
  Future<void> setVolume(double volume) async {
    currentVolume = volume;
    _volume.add(volume);
  }

  @override
  Future<void> setRate(double rate) async => _rate.add(rate);
  @override
  Future<void> setAudioPassthrough(bool enabled) async {}
  @override
  Future<void> setAudioTrack(AudioTrack track) async =>
      _track.add(Track(audio: track));
  @override
  Future<void> setSubtitleTrack(SubtitleTrack track) async =>
      _track.add(Track(subtitle: track));
  @override
  Future<void> dispose() async {
    disposed = true;
    await Future.wait([
      _position.close(),
      _duration.close(),
      _buffer.close(),
      _volume.close(),
      _playing.close(),
      _buffering.close(),
      _completed.close(),
      _tracks.close(),
      _track.close(),
      _videoParams.close(),
      _width.close(),
      _height.close(),
      _audioBitrate.close(),
      _rate.close(),
      _error.close(),
    ]);
  }
}
