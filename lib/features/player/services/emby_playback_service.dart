import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../servers/models/emby_media_detail.dart';
import '../models/player_media_source.dart';

/// Requests and resolves an Emby direct-play/direct-stream URL.
class EmbyPlaybackService {
  EmbyPlaybackService({
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 20),
    String Function()? playSessionIdGenerator,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _playSessionIdGenerator = playSessionIdGenerator ?? _uuidV4;

  static const _authorization =
      'Emby Client="Wbs Player", Device="Flutter", '
      'DeviceId="wbs-player", Version="0.1.0"';

  static const Map<String, dynamic> _deviceProfile = {
    'MaxStreamingBitrate': 140000000,
    'MusicStreamingTranscodingBitrate': 320000,
    'DirectPlayProfiles': [
      {'Container': 'mkv,mp4,m4v,mov,webm,avi,ts,m2ts', 'Type': 'Video'},
      {'Container': 'mp3,aac,flac,ogg,wav,m4a', 'Type': 'Audio'},
    ],
    'TranscodingProfiles': [
      {
        'Container': 'ts',
        'Type': 'Video',
        'VideoCodec': 'h264,hevc',
        'AudioCodec': 'aac,ac3',
        'Protocol': 'hls',
        'Context': 'Streaming',
      },
    ],
    'CodecProfiles': [],
    'SubtitleProfiles': [
      {'Format': 'srt', 'Method': 'Embed'},
      {'Format': 'ass', 'Method': 'Embed'},
      {'Format': 'ssa', 'Method': 'Embed'},
      {'Format': 'vtt', 'Method': 'Embed'},
    ],
  };

  final http.Client _client;
  final bool _ownsClient;
  final Duration requestTimeout;
  final String Function() _playSessionIdGenerator;

  /// Gets PlaybackInfo, prefers direct play, then direct stream, and returns
  /// the selected absolute URL and headers. Transcoding is not used in Phase 1.
  Future<PlayerMediaSource> resolve({
    required String serverAddress,
    required String accessToken,
    required String userId,
    required String itemId,
    required EmbyMediaSource mediaSource,
    int? audioStreamIndex,
    int? maxStreamingBitrate,
    bool forceTranscoding = false,
  }) async {
    final endpoint = _endpoint(
      serverAddress,
      'Items/${Uri.encodeComponent(itemId)}/PlaybackInfo',
    );
    final payload = await _postJson(
      endpoint,
      accessToken,
      body: {
        'Id': itemId,
        'UserId': userId,
        'MediaSourceId': mediaSource.id,
        if (audioStreamIndex != null) 'AudioStreamIndex': audioStreamIndex,
        'DeviceProfile': _deviceProfile,
        if (maxStreamingBitrate != null && maxStreamingBitrate > 0)
          'MaxStreamingBitrate': maxStreamingBitrate,
      },
    );
    final sources = payload['MediaSources'];
    if (sources is! List) throw const EmbyPlaybackException('missingSources');
    final playSessionId =
        _string(payload['PlaySessionId']) ??
        mediaSource.playSessionId ??
        _playSessionIdGenerator();
    final parsedSources = sources
        .whereType<Map>()
        .map((value) => EmbyMediaSource.fromJson(_stringMap(value)))
        .toList(growable: false);
    final matching = parsedSources
        .where((value) => value.id == mediaSource.id)
        .firstOrNull;
    final source =
        matching ??
        (parsedSources.length == 1 ? parsedSources.single : null) ??
        mediaSource;
    final directStreamUrl =
        source.directStreamUrl ?? mediaSource.directStreamUrl;
    final directPlay =
        source.supportsDirectPlay ?? mediaSource.supportsDirectPlay;
    final directStream =
        source.supportsDirectStream ?? mediaSource.supportsDirectStream;
    final selected = _selectUrl(
      source,
      directStreamUrl: directStreamUrl,
      supportsDirectPlay: directPlay,
      supportsDirectStream: directStream,
    );
    final transcodeSource = parsedSources
        .where(
          (value) =>
              value.transcodingUrl != null && value.transcodingUrl!.isNotEmpty,
        )
        .firstOrNull;
    final useTranscode =
        transcodeSource != null &&
        (forceTranscoding || maxStreamingBitrate != null);
    final selectedSource = useTranscode ? transcodeSource! : source;
    final urlValue = useTranscode
        ? transcodeSource.transcodingUrl!
        : selected?.$1;
    final method = useTranscode ? EmbyPlayMethod.transcode : selected?.$2;
    if (urlValue == null || method == null) {
      throw const EmbyPlaybackException('noPlayableUrl');
    }
    final url = _resolveUrl(serverAddress, urlValue);
    // Never add a token to the query string. Servers commonly place api_key
    // in their returned URL, so remove it defensively to avoid leaking it.
    final sanitized = _withoutTokenQuery(url);
    final headers = _playbackHeaders(
      {
        ...mediaSource.requiredHttpHeaders,
        ...selectedSource.requiredHttpHeaders,
      },
      accessToken: accessToken,
      serverAddress: serverAddress,
      mediaUrl: sanitized,
    );
    return PlayerMediaSource(
      url: sanitized,
      headers: headers,
      mediaSourceId: selectedSource.id.isNotEmpty
          ? selectedSource.id
          : mediaSource.id,
      playSessionId: playSessionId,
      playMethod: method,
      supportsTranscoding: transcodeSource != null,
    );
  }

  /// Downloads an external text subtitle using the same authenticated Emby
  /// session as the selected media source.
  Future<String> loadExternalSubtitle({
    required String serverAddress,
    required String accessToken,
    required String itemId,
    required String mediaSourceId,
    required EmbyMediaStream subtitle,
  }) async {
    final index = subtitle.index;
    if (index == null || !subtitle.isExternal) {
      throw const EmbyPlaybackException('unsupportedSubtitle');
    }
    final format = _subtitleFormat(subtitle.codec);
    if (format == null) {
      throw const EmbyPlaybackException('unsupportedSubtitle');
    }
    final uri = _endpoint(
      serverAddress,
      'Videos/${Uri.encodeComponent(itemId)}/${Uri.encodeComponent(mediaSourceId)}/Subtitles/$index/Stream.$format',
    );
    final headers = <String, String>{
      'Accept': 'text/plain, text/vtt, */*',
      'Authorization': _authorization,
      if (accessToken.isNotEmpty && _sameOrigin(serverAddress, uri))
        'X-Emby-Token': accessToken,
    };
    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw EmbyPlaybackException(
          'subtitleRequestFailed',
          response.statusCode,
        );
      }
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    } on EmbyPlaybackException {
      rethrow;
    } on TimeoutException {
      throw const EmbyPlaybackException('timeout');
    } on http.ClientException {
      throw const EmbyPlaybackException('network');
    }
  }

  (String, EmbyPlayMethod)? _selectUrl(
    EmbyMediaSource source, {
    required String? directStreamUrl,
    required bool? supportsDirectPlay,
    required bool? supportsDirectStream,
  }) {
    if (directStreamUrl == null || directStreamUrl.isEmpty) return null;
    if (supportsDirectPlay == true) {
      return (directStreamUrl, EmbyPlayMethod.directPlay);
    }
    if (supportsDirectStream == true) {
      return (directStreamUrl, EmbyPlayMethod.directStream);
    }
    // Some compatible servers omit capability flags. A returned direct URL is
    // still usable, and DirectPlay is the most conservative reported method.
    if (supportsDirectPlay == null && supportsDirectStream == null) {
      return (directStreamUrl, EmbyPlayMethod.directPlay);
    }
    return null;
  }

  Uri _resolveUrl(String serverAddress, String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || rawUrl.trim().isEmpty) {
      throw const EmbyPlaybackException('invalidUrl');
    }
    if (uri.hasScheme) {
      if (!const {'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        throw const EmbyPlaybackException('invalidUrl');
      }
      return uri;
    }
    final base = Uri.tryParse(serverAddress.trim());
    if (base == null || base.host.isEmpty) {
      throw const EmbyPlaybackException('invalidServerAddress');
    }
    final root = Uri(
      scheme: base.scheme,
      userInfo: base.userInfo,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '${base.path.replaceFirst(RegExp(r'/+$'), '')}/',
    );
    final resolved = root.resolveUri(uri);
    if (resolved.host.isEmpty ||
        !const {'http', 'https'}.contains(resolved.scheme.toLowerCase()) ||
        resolved.userInfo.isNotEmpty) {
      throw const EmbyPlaybackException('invalidUrl');
    }
    return resolved;
  }

  Uri _withoutTokenQuery(Uri uri) {
    final query = Map<String, List<String>>.from(uri.queryParametersAll)
      ..removeWhere(
        (key, _) => const {
          'api_key',
          'apikey',
          'x-emby-token',
          'token',
        }.contains(key.toLowerCase()),
      );
    return uri.replace(queryParameters: query.isEmpty ? null : query);
  }

  Map<String, String> _playbackHeaders(
    Map<String, String> requiredHeaders, {
    required String accessToken,
    required String serverAddress,
    required Uri mediaUrl,
  }) {
    final headers = <String, String>{};
    final isSameOrigin = _sameOrigin(serverAddress, mediaUrl);
    if (isSameOrigin) {
      for (final entry in requiredHeaders.entries) {
        final key = entry.key.trim();
        final value = entry.value.trim();
        if (key.isEmpty ||
            value.isEmpty ||
            key.contains('\r') ||
            key.contains('\n') ||
            value.contains('\r') ||
            value.contains('\n') ||
            key.toLowerCase() == 'x-emby-token' ||
            key.toLowerCase() == 'authorization') {
          continue;
        }
        headers.removeWhere(
          (existing, _) => existing.toLowerCase() == key.toLowerCase(),
        );
        headers[key] = value;
      }
    }
    if (accessToken.isNotEmpty && isSameOrigin) {
      headers['X-Emby-Token'] = accessToken;
    }
    return Map.unmodifiable(headers);
  }

  bool _sameOrigin(String serverAddress, Uri target) {
    final server = Uri.tryParse(serverAddress.trim());
    return server != null &&
        server.host.isNotEmpty &&
        server.scheme.toLowerCase() == target.scheme.toLowerCase() &&
        server.host.toLowerCase() == target.host.toLowerCase() &&
        server.port == target.port;
  }

  String? _subtitleFormat(String? codec) => switch (codec?.toLowerCase()) {
    'ass' || 'ssa' => 'ass',
    'srt' || 'subrip' => 'srt',
    'vtt' || 'webvtt' => 'vtt',
    _ => null,
  };

  Uri _endpoint(String serverAddress, String path) {
    final base = Uri.tryParse(serverAddress.trim());
    if (base == null || base.host.isEmpty) {
      throw const EmbyPlaybackException('invalidServerAddress');
    }
    final segments = base.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty || segments.last.toLowerCase() != 'emby') {
      segments.add('emby');
    }
    segments.addAll(
      path.split('/').where((s) => s.isNotEmpty).map(_decodeSegment),
    );
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      pathSegments: segments,
    );
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    String accessToken, {
    required Map<String, dynamic> body,
  }) async {
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
        throw EmbyPlaybackException('requestFailed', response.statusCode);
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const EmbyPlaybackException('invalidResponse');
      return _stringMap(decoded);
    } on EmbyPlaybackException {
      rethrow;
    } on TimeoutException {
      throw const EmbyPlaybackException('timeout');
    } on http.ClientException {
      throw const EmbyPlaybackException('network');
    } on FormatException {
      throw const EmbyPlaybackException('invalidResponse');
    }
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}

/// Playback resolution failure, represented by a localization-safe error code.
class EmbyPlaybackException implements Exception {
  const EmbyPlaybackException(this.code, [this.statusCode]);

  final String code;
  final int? statusCode;

  @override
  String toString() =>
      'EmbyPlaybackException($code${statusCode == null ? '' : ', $statusCode'})';
}

String? _string(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

String _decodeSegment(String value) {
  try {
    return Uri.decodeComponent(value);
  } on FormatException {
    return value;
  }
}

Map<String, dynamic> _stringMap(Map<dynamic, dynamic> value) => {
  for (final entry in value.entries)
    if (entry.key is String) entry.key as String: entry.value,
};

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
