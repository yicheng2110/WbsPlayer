import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/emby_media_detail.dart';

/// Loads media detail and its optional related Emby resources.
///
/// Inject [client] to share networking. [close] only closes a client created by
/// this service itself.
class EmbyMediaDetailService {
  EmbyMediaDetailService({
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  static const _clientName = 'Wbs Player';
  static const _deviceName = 'Flutter';
  static const _deviceId = 'wbs-player';
  static const _clientVersion = '0.1.0';
  static const _detailFields =
      'Overview,OriginalTitle,Genres,People,Studios,MediaSources,MediaStreams,'
      'ExternalUrls,ProductionYear,CommunityRating,CriticRating,OfficialRating,'
      'PremiereDate,RunTimeTicks,UserData,BackdropImageTags,ParentBackdropItemId,'
      'ParentBackdropImageTags';

  final http.Client _client;
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
  }) async {
    final detail = await getDetail(
      serverAddress: serverAddress,
      accessToken: accessToken,
      userId: userId,
      itemId: itemId,
    );
    final failedSections = <EmbyMediaDetailSection>{};
    final results = await Future.wait<Object?>([
      getSimilar(
        serverAddress: serverAddress,
        accessToken: accessToken,
        userId: userId,
        itemId: itemId,
      ).catchError((Object _) {
        failedSections.add(EmbyMediaDetailSection.similar);
        return const <EmbySimilarItem>[];
      }),
      getImages(
        serverAddress: serverAddress,
        accessToken: accessToken,
        itemId: itemId,
      ).catchError((Object _) {
        failedSections.add(EmbyMediaDetailSection.images);
        return const <EmbyMediaDetailImage>[];
      }),
      getMediaSources(
        serverAddress: serverAddress,
        accessToken: accessToken,
        userId: userId,
        itemId: itemId,
      ).catchError((Object _) {
        failedSections.add(EmbyMediaDetailSection.mediaSources);
        return const <EmbyMediaSource>[];
      }),
    ]);
    return EmbyMediaDetailContent(
      detail: detail,
      similar: results[0] as List<EmbySimilarItem>,
      images: _mergeImages(
        detail.images,
        results[1] as List<EmbyMediaDetailImage>,
      ),
      mediaSources: results[2] as List<EmbyMediaSource>,
      failedSections: failedSections,
    );
  }

  /// Loads the main item. Missing/malformed essential payloads throw.
  Future<EmbyMediaDetail> getDetail({
    required String serverAddress,
    required String accessToken,
    required String userId,
    required String itemId,
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
    final item = _asMap(await _getJson(uri, accessToken));
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
  }) async {
    final payload = await _getJson(
      _endpoint(serverAddress, 'Items/${_segment(itemId)}/Images'),
      accessToken,
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
  }) async {
    final payload = await _postJson(
      _endpoint(serverAddress, 'Items/${_segment(itemId)}/PlaybackInfo'),
      accessToken,
      body: {'Id': itemId, 'UserId': userId},
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

  Future<dynamic> _getJson(Uri uri, String accessToken) async {
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
