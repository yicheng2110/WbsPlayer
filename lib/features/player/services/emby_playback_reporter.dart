import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/player_media_source.dart';

/// Reports a playback session to Emby without allowing network errors to
/// interrupt local playback.
class EmbyPlaybackReporter {
  EmbyPlaybackReporter({
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 8),
    this.progressInterval = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  static const _authorization =
      'Emby Client="Wbs Player", Device="Flutter", '
      'DeviceId="wbs-player", Version="0.1.0"';

  final http.Client _client;
  final bool _ownsClient;
  final Duration requestTimeout;
  final Duration progressInterval;

  Uri? _endpoint;
  String _accessToken = '';
  String _itemId = '';
  String _userId = '';
  PlayerMediaSource? _source;
  Duration _position = Duration.zero;
  bool _isPaused = false;
  bool _isMuted = false;
  int? _audioStreamIndex;
  int? _subtitleStreamIndex;
  DateTime? _lastProgressAt;
  bool _started = false;
  bool _stopped = false;
  Future<void> _queue = Future<void>.value();

  /// Starts a new session and sends the initial playing notification once.
  Future<void> onStart({
    required String serverAddress,
    required String accessToken,
    required String userId,
    required String itemId,
    required PlayerMediaSource source,
    Duration position = Duration.zero,
    bool isMuted = false,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    if (_started && !_stopped) return;
    _endpoint = _endpointFor(serverAddress);
    _accessToken = accessToken;
    _userId = userId;
    _itemId = itemId;
    _source = source;
    _position = position;
    _isPaused = false;
    _isMuted = isMuted;
    _audioStreamIndex = audioStreamIndex;
    _subtitleStreamIndex = subtitleStreamIndex;
    _lastProgressAt = null;
    _started = true;
    _stopped = false;
    await _send('Sessions/Playing', _sessionPayload());
    _lastProgressAt = DateTime.now();
  }

  /// Updates position and reports immediately for state changes or after the
  /// configured interval for ordinary position updates.
  Future<void> onProgress({
    required Duration position,
    required bool isPaused,
    bool? isMuted,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    bool force = false,
  }) async {
    if (!_started || _stopped) return;
    final stateChanged = _isPaused != isPaused;
    _position = position;
    _isPaused = isPaused;
    if (isMuted != null) _isMuted = isMuted;
    if (audioStreamIndex != null) _audioStreamIndex = audioStreamIndex;
    if (subtitleStreamIndex != null) _subtitleStreamIndex = subtitleStreamIndex;
    final now = DateTime.now();
    if (!force &&
        !stateChanged &&
        _lastProgressAt != null &&
        now.difference(_lastProgressAt!) < progressInterval) {
      return;
    }
    _lastProgressAt = now;
    await _send('Sessions/Playing/Progress', {
      ..._sessionPayload(),
      'IsPaused': isPaused,
      'EventName': 'TimeUpdate',
    });
  }

  /// Finishes the session at most once.
  Future<void> onStop({Duration? position}) async {
    if (!_started || _stopped) return;
    _stopped = true;
    if (position != null) _position = position;
    await _send('Sessions/Playing/Stopped', _sessionPayload());
  }

  Map<String, dynamic> _sessionPayload() {
    final source = _source!;
    return {
      'ItemId': _itemId,
      'MediaSourceId': source.mediaSourceId,
      'PlaySessionId': source.playSessionId,
      'PositionTicks': durationToTicks(_position),
      'PlayMethod': source.playMethod.apiValue,
      'CanSeek': true,
      'IsMuted': _isMuted,
      'IsPaused': _isPaused,
      if (_audioStreamIndex != null) 'AudioStreamIndex': _audioStreamIndex,
      if (_subtitleStreamIndex != null)
        'SubtitleStreamIndex': _subtitleStreamIndex,
      'IsAutomated': false,
      'UserId': _userId,
    };
  }

  Uri _endpointFor(String serverAddress) {
    final base = Uri.parse(serverAddress.trim());
    final segments = base.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty || segments.last.toLowerCase() != 'emby') {
      segments.add('emby');
    }
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      pathSegments: segments,
    );
  }

  Future<void> _send(String path, Map<String, dynamic> body) async {
    final endpoint = _endpoint;
    if (endpoint == null) return;
    final accessToken = _accessToken;
    final uri = endpoint.replace(
      pathSegments: [
        ...endpoint.pathSegments,
        ...path.split('/').map(Uri.encodeComponent),
      ],
    );
    _queue = _queue.then((_) async {
      try {
        final response = await _client
            .post(
              uri,
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': _authorization,
                if (accessToken.isNotEmpty) 'X-Emby-Token': accessToken,
              },
              body: jsonEncode(body),
            )
            .timeout(requestTimeout);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          debugPrint(
            'Emby playback report failed: HTTP ${response.statusCode}',
          );
        }
      } catch (error) {
        debugPrint('Emby playback report failed: $error');
      }
    });
    await _queue;
  }

  /// Converts a Dart duration into Emby's 100-nanosecond ticks.
  static int durationToTicks(Duration duration) => duration.inMicroseconds * 10;

  /// Converts Emby's 100-nanosecond ticks into a Dart duration.
  static Duration ticksToDuration(int ticks) =>
      Duration(microseconds: ticks ~/ 10);

  void close() {
    if (_ownsClient) _client.close();
  }
}
