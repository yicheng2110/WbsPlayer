import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/emby_media_detail.dart';
import 'emby_api_response_cache.dart';

/// Loads media detail and its optional related Emby resources.
///
/// Inject [client] to share networking. [close] only closes a client created by
/// this service itself.
class EmbyMediaDetailService {
  EmbyMediaDetailService({
    http.Client? client,
    EmbyApiResponseCache? responseCache,
    this.requestTimeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client(),
       _responseCache =
           responseCache ??
           (client == null
               ? EmbyApiResponseCache.shared
               : EmbyApiResponseCache()),
       _ownsClient = client == null;

  static const _clientName = 'Wbs Player';
  static const _deviceName = 'Flutter';
  static const _deviceId = 'wbs-player';
  static const _clientVersion = '0.1.0';
  static const _detailFields =
      'Overview,OriginalTitle,Genres,People,Studios,MediaSources,MediaStreams,'
      'ExternalUrls,ProductionYear,CommunityRating,CriticRating,OfficialRating,'
      'PremiereDate,RunTimeTicks,UserData,SeriesName,SeriesId,SeasonId,SeasonName,'
      'ParentIndexNumber,IndexNumber,BackdropImageTags,ParentBackdropItemId,'
      'ParentBackdropImageTags';

  final http.Client _client;
  final EmbyApiResponseCache _responseCache;
  final bool _ownsClient;
  final Duration requestTimeout;

  /// Loads the main item and optional recommendations, images and sources.
  /// Failures in secondary endpoints are reported in [EmbyMediaDetailContent]
  /// but do not hide an otherwise readable detail page.
  Future<EmbyMediaDetailContent> loadDetail({
    required String serverAddress,
    required String accessToken,
    required String userId,
    required String itemId,
    bool forceRefresh = false,
  }) async {
    final detail = await getDetail(
      serverAddress: serverAddress,
      accessToken: accessToken,
      userId: userId,
      itemId: itemId,
      forceRefresh: forceRefresh,
    );
    final failedSections = <EmbyMediaDetailSection>{};
    final requests = <Future<Object?>>[
      getSimilar(
        serverAddress: serverAddress,
        accessToken: accessToken,
        userId: userId,
        itemId: itemId,
        forceRefresh: forceRefresh,
      ).catchError((Object _) {
        failedSections.add(EmbyMediaDetailSection.similar);
        return const <EmbySimilarItem>[];
      }),
      getImages(
        serverAddress: serverAddress,
        accessToken: accessToken,
        itemId: itemId,
        userId: userId,
        forceRefresh: forceRefresh,
      ).catchError((Object _) {
        failedSections.add(EmbyMediaDetailSection.images);
        return const <EmbyMediaDetailImage>[];
      }),
      if (detail.mediaSources.isNotEmpty)
        Future<List<EmbyMediaSource>>.value(detail.mediaSources)
      else
        getMediaSources(
          serverAddress: serverAddress,
          accessToken: accessToken,
          userId: userId,
          itemId: itemId,
          forceRefresh: forceRefresh,
        ).catchError((Object _) {
          failedSections.add(EmbyMediaDetailSection.mediaSources);
          return const <EmbyMediaSource>[];
        }),
    ];
    if (detail.type.toLowerCase() == 'series') {
      requests.add(
        getSeasons(
          serverAddress: serverAddress,
          accessToken: accessToken,
          userId: userId,
          seriesId: itemId,
          forceRefresh: forceRefresh,
        ).catchError((Object _) {
          failedSections.add(EmbyMediaDetailSection.seasons);
          return const <EmbyMediaSeason>[];
        }),
      );
    }
    final results = await Future.wait<Object?>(requests);
    return EmbyMediaDetailContent(
      detail: detail,
      similar: results[0] as List<EmbySimilarItem>,
      seasons: detail.type.toLowerCase() == 'series'
          ? results[3] as List<EmbyMediaSeason>
          : const <EmbyMediaSeason>[],
      images: _mergeImages(
        detail.images,
        results[1] as List<EmbyMediaDetailImage>,
      ),
      mediaSources: results[2] as List<EmbyMediaSource>,
      failedSections: failedSections,
    );
  }

  /// Loads seasons for a series, including episode counts and poster tags.
  Future<List<EmbyMediaSeason>> getSeasons({
    required String serverAddress,
    required String accessToken,
    required String userId,
    required String seriesId,
    bool forceRefresh = false,
  }) async {
    final payload = await _getJson(
      _endpoint(serverAddress, 'Shows/${_segment(seriesId)}/Seasons').replace(
        queryParameters: {
          'UserId': userId,
          'Fields': 'ChildCount,ProductionYear',
          'EnableImages': 'true',
          'EnableImageTypes': 'Primary',
        },
      ),
      accessToken,
      cacheScope: _cacheScope(serverAddress, userId),
      forceRefresh: forceRefresh,
    );
    return _readItems(payload)
        .map(EmbyMediaSeason.fromJson)
        .where((season) => season.id.isNotEmpty)
        .toList(growable: false);
  }

  /// Finds the episode immediately after [episodeId] in series order.
  Future<EmbyMediaDetail?> getNextEpisode({
    required String serverAddress,
    required String accessToken,
    required String userId,
    required String seriesId,
    required String episodeId,
  }) async {
    final payload = await _getJson(
      _endpoint(serverAddress, 'Shows/${_segment(seriesId)}/Episodes').replace(
        queryParameters: {
          'UserId': userId,
          'Fields': 'Overview,MediaSources,MediaStreams,RunTimeTicks,UserData,SeriesId,SeasonId,ParentIndexNumber,IndexNumber',
          'SortBy': 'ParentIndexNumber,IndexNumber',
          'SortOrder': 'Ascending',
          'Limit': '1000',
        },
      ),
      accessToken,
      cacheScope: _cacheScope(serverAddress, userId),
      forceRefresh: true,
    );
    final episodes =
        _readItems(payload)
            .map(EmbyMediaDetail.fromJson)
            .where((episode) => episode.type.toLowerCase() == 'episode')
            .toList()
          ..sort(_compareEpisodes);
    final currentIndex = episodes.indexWhere(
      (episode) => episode.id == episodeId,
    );
    if (currentIndex < 0 || currentIndex + 1 >= episodes.length) return null;
    return episodes[currentIndex + 1];
  }

  int _compareEpisodes(EmbyMediaDetail left, EmbyMediaDetail right) {
    final season = (left.seasonNumber ?? -1).compareTo(
      right.seasonNumber ?? -1,
    );
    if (season != 0) return season;
    final episode = (left.episodeNumber ?? -1).compareTo(
      right.episodeNumber ?? -1,
    );
    if (episode != 0) return episode;
    return left.name.compareTo(right.name);
  }

  /// Loads the main item. Missing/malformed essential payloads throw.
  Future<EmbyMediaDetail> getDetail({
    required String serverAddress,
    required String accessToken,
    required String userId,
    required String itemId,
    bool forceRefresh = false,
  }) async {
    final uri =
        _endpoint(
          serverAddress,
          'Users/${_segment(userId)}/Items/${_segment(itemId)}',
        ).replace(
          queryParameters: const {
            'Fields': _detailFields,
            'EnableImages': 'true',
            'EnableUserData': 'true',
            'EnableImageTypes': 'Primary,Backdrop,Thumb,Logo,Art,Banner,Disc',
          },
        );
    final item = _asMap(
      await _getJson(
        uri,
        accessToken,
        cacheScope: _cacheScope(serverAddress, userId),
        forceRefresh: forceRefresh,
      ),
    );
    if (item == null) throw const EmbyMediaDetailRequestException();
    final detail = EmbyMediaDetail.fromJson(item);
    if (detail.id.isEmpty) throw const EmbyMediaDetailRequestException();
    return detail;
  }

  Future<List<EmbySimilarItem>> getSimilar({
    required String serverAddress,
    required String accessToken,
    required String userId,
    required String itemId,
    int limit = 16,
    bool forceRefresh = false,
  }) async {
    final payload = await _getJson(
      _endpoint(serverAddress, 'Items/${_segment(itemId)}/Similar').replace(
        queryParameters: {
          'UserId': userId,
          'Limit': '$limit',
          'Fields': 'ProductionYear,CommunityRating',
          'EnableImages': 'true',
          'EnableImageTypes': 'Primary',
        },
      ),
      accessToken,
      cacheScope: _cacheScope(serverAddress, userId),
      forceRefresh: forceRefresh,
    );
    return _readItems(payload)
        .map(EmbySimilarItem.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  /// Reads image metadata, retaining Emby's actual ImageIndex values.
  Future<List<EmbyMediaDetailImage>> getImages({
    required String serverAddress,
    required String accessToken,
    required String itemId,
    String userId = '',
    bool forceRefresh = false,
  }) async {
    final payload = await _getJson(
      _endpoint(serverAddress, 'Items/${_segment(itemId)}/Images'),
      accessToken,
      cacheScope: _cacheScope(serverAddress, userId),
      forceRefresh: forceRefresh,
    );
    return _readItems(payload)
        .map((image) => EmbyMediaDetailImage.fromJson(image, itemId: itemId))
        .where((image) => image.type.isNotEmpty)
        .toList(growable: false);
  }

  /// Reads sources from Emby's source endpoint when item fields omit them.
  Future<List<EmbyMediaSource>> getMediaSources({
    required String serverAddress,
    required String accessToken,
    required String userId,
    required String itemId,
    bool forceRefresh = false,
  }) async {
    final payload = await _responseCache.getOrLoad<dynamic>(
      '${_cacheScope(serverAddress, userId)}playback-info:$itemId',
      () => _postJson(
        _endpoint(serverAddress, 'Items/${_segment(itemId)}/PlaybackInfo'),
        accessToken,
        body: {'Id': itemId, 'UserId': userId},
      ),
      forceRefresh: forceRefresh,
      persistValue: false,
    );
    final response = _asMap(payload);
    final sourcePayload = response?['MediaSources'];
    final sources = sourcePayload is List ? sourcePayload : const <dynamic>[];
    return sources
        .whereType<Map>()
        .map(_stringMap)
        .map(EmbyMediaSource.fromJson)
        .where((source) => source.id.isNotEmpty || source.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> setFavorite({
    required String serverAddress,
    required String accessToken,
    required String userId,
    required String itemId,
    required bool favorite,
  }) async {
    final uri = _endpoint(
      serverAddress,
      'Users/${_segment(userId)}/FavoriteItems/${_segment(itemId)}',
    );
    try {
      final response =
          await (favorite
                  ? _client.post(
                      uri,
                      headers: {..._headers, 'X-Emby-Token': accessToken},
                    )
                  : _client.delete(
                      uri,
                      headers: {..._headers, 'X-Emby-Token': accessToken},
                    ))
              .timeout(requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw EmbyMediaDetailRequestException(response.statusCode);
      }
      _responseCache.invalidatePrefix(_cacheScope(serverAddress, userId));
    } on EmbyMediaDetailRequestException {
      rethrow;
    } on TimeoutException {
      throw const EmbyMediaDetailRequestException();
    } on http.ClientException {
      throw const EmbyMediaDetailRequestException();
    }
  }

  Future<dynamic> _postJson(
    Uri uri,
    String accessToken, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              ..._headers,
              'X-Emby-Token': accessToken,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw EmbyMediaDetailRequestException(response.statusCode);
      }
      return jsonDecode(response.body);
    } on EmbyMediaDetailRequestException {
      rethrow;
    } on TimeoutException {
      throw const EmbyMediaDetailRequestException();
    } on http.ClientException {
      throw const EmbyMediaDetailRequestException();
    } on FormatException {
      throw const EmbyMediaDetailRequestException();
    }
  }

  Future<dynamic> _getJson(
    Uri uri,
    String accessToken, {
    required String cacheScope,
    bool forceRefresh = false,
  }) => _responseCache.getOrLoad<dynamic>(
    '$cacheScope${uri.toString()}',
    () => _requestJson(uri, accessToken),
    forceRefresh: forceRefresh,
  );

  Future<dynamic> _requestJson(Uri uri, String accessToken) async {
    try {
      final response = await _client
          .get(uri, headers: {..._headers, 'X-Emby-Token': accessToken})
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw EmbyMediaDetailRequestException(response.statusCode);
      }
      return jsonDecode(response.body);
    } on EmbyMediaDetailRequestException {
      rethrow;
    } on TimeoutException {
      throw const EmbyMediaDetailRequestException();
    } on http.ClientException {
      throw const EmbyMediaDetailRequestException();
    } on FormatException {
      throw const EmbyMediaDetailRequestException();
    }
  }

  Map<String, String> get _headers => const {
    'Accept': 'application/json',
    'Authorization':
        'Emby Client="$_clientName", Device="$_deviceName", '
        'DeviceId="$_deviceId", Version="$_clientVersion"',
  };

  Uri _endpoint(String serverAddress, String apiPath) {
    final baseUri = Uri.parse(serverAddress.trim());
    final pathSegments = baseUri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList(growable: true);
    if (pathSegments.isEmpty || pathSegments.last != 'emby') {
      pathSegments.add('emby');
    }
    pathSegments.addAll(
      apiPath
          .split('/')
          .where((segment) => segment.isNotEmpty)
          .map(_decodeSegment),
    );
    return Uri(
      scheme: baseUri.scheme,
      userInfo: baseUri.userInfo,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      pathSegments: pathSegments,
    );
  }

  String _cacheScope(String serverAddress, String userId) {
    final sanitizedServer = Uri.parse(serverAddress.trim())
        .replace(userInfo: '', query: '', fragment: '')
        .toString();
    return '$sanitizedServer|$userId|';
  }

  /// Releases the HTTP client if this service created it.
  void close() {
    if (_ownsClient) _client.close();
  }
}

class EmbyMediaDetailRequestException implements Exception {
  const EmbyMediaDetailRequestException([this.statusCode]);

  final int? statusCode;
}

String _segment(String value) => Uri.encodeComponent(value);

String _decodeSegment(String value) {
  try {
    return Uri.decodeComponent(value);
  } on FormatException {
    return value;
  }
}

Map<String, dynamic>? _asMap(Object? value) =>
    value is Map ? _stringMap(value) : null;

List<Map<String, dynamic>> _readItems(Object? payload) {
  final raw = switch (payload) {
    {'Items': final List<dynamic> items} => items,
    List<dynamic> items => items,
    _ => throw const EmbyMediaDetailRequestException(),
  };
  return raw.whereType<Map>().map(_stringMap).toList(growable: false);
}

Map<String, dynamic> _stringMap(Map<dynamic, dynamic> value) =>
    Map<String, dynamic>.fromEntries(
      value.entries
          .where((entry) => entry.key is String)
          .map((entry) => MapEntry(entry.key as String, entry.value)),
    );

List<EmbyMediaDetailImage> _mergeImages(
  List<EmbyMediaDetailImage> initial,
  List<EmbyMediaDetailImage> extra,
) {
  final unique = <String, EmbyMediaDetailImage>{};
  for (final image in [...initial, ...extra]) {
    unique['${image.itemId}|${image.type}|${image.index}|${image.tag}'] = image;
  }
  return unique.values.toList(growable: false);
}
