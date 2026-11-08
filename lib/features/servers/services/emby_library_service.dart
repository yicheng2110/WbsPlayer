import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/emby_media.dart';
import 'emby_api_response_cache.dart';

/// Reads a user's Emby libraries and media items through the REST API.
class EmbyLibraryService {
  EmbyLibraryService({
    http.Client? client,
    EmbyApiResponseCache? responseCache,
    this.requestTimeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client(),
       _responseCache =
           responseCache ??
           (client == null
               ? EmbyApiResponseCache.shared
               : EmbyApiResponseCache());

  static const _clientName = 'Wbs Player';
  static const _deviceName = 'Flutter';
  static const _deviceId = 'wbs-player';
  static const _clientVersion = '0.1.0';

  final http.Client _client;
  final EmbyApiResponseCache _responseCache;
  final Duration requestTimeout;

  Future<List<EmbyLibrary>> loadLibraries({
    required String serverAddress,
    required String accessToken,
    required String userId,
    bool forceRefresh = false,
  }) => _loadLibraries(
    serverAddress: serverAddress,
    accessToken: accessToken,
    userId: userId,
    forceRefresh: forceRefresh,
  );

  Future<EmbyHomeContent> loadHome({
    required String serverAddress,
    required String accessToken,
    required String userId,
    bool forceRefresh = false,
  }) async {
    final libraries = await _loadLibraries(
      serverAddress: serverAddress,
      accessToken: accessToken,
      userId: userId,
      forceRefresh: forceRefresh,
    );
    final parts = await Future.wait<dynamic>([
      Future.wait(
        libraries.map(
          (library) async => EmbyLibrarySection(
            library: library,
            items: await _loadLatestItems(
              serverAddress: serverAddress,
              accessToken: accessToken,
              userId: userId,
              parentId: library.id,
              forceRefresh: forceRefresh,
            ),
          ),
        ),
      ),
      _loadRecentlyPlayedItems(
        serverAddress: serverAddress,
        accessToken: accessToken,
        userId: userId,
        forceRefresh: forceRefresh,
      ),
      _loadLatestItems(
        serverAddress: serverAddress,
        accessToken: accessToken,
        userId: userId,
        limit: 10,
        forceRefresh: forceRefresh,
      ),
    ]);
    return EmbyHomeContent(
      libraries: parts[0] as List<EmbyLibrarySection>,
      recentlyPlayed: parts[1] as List<EmbyLibraryItem>,
      featured: parts[2] as List<EmbyLibraryItem>,
    );
  }

  Future<List<EmbyLibraryItem>> _loadRecentlyPlayedItems({
    required String serverAddress,
    required String accessToken,
    required String userId,
    bool forceRefresh = false,
  }) async {
    return _getItems(
      serverAddress: serverAddress,
      accessToken: accessToken,
      path: 'Users/$userId/Items/Resume',
      queryParameters: const {
        'Limit': '20',
        'Fields': 'ProductionYear,Overview',
        'MediaTypes': 'Video',
        'EnableImages': 'true',
        'EnableUserData': 'true',
        'EnableImageTypes': 'Primary,Thumb,Backdrop',
      },
      queryResult: true,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<EmbyLibrary>> _loadLibraries({
    required String serverAddress,
    required String accessToken,
    required String userId,
    bool forceRefresh = false,
  }) async {
    final payload = await _getPayload(
      serverAddress: serverAddress,
      accessToken: accessToken,
      path: 'Users/$userId/Views',
      queryParameters: const {
        'IncludeExternalContent': 'false',
        'EnableImages': 'true',
      },
      forceRefresh: forceRefresh,
    );
    if (payload is! Map<String, dynamic> || payload['Items'] is! List) {
      throw const EmbyLibraryRequestException();
    }
    try {
      return (payload['Items'] as List)
          .whereType<Map>()
          .map(
            (item) => EmbyLibrary.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((library) => library.id.isNotEmpty && library.name.isNotEmpty)
          .toList(growable: false);
    } on TypeError {
      throw const EmbyLibraryRequestException();
    }
  }

  Future<List<EmbyLibraryItem>> _loadLatestItems({
    required String serverAddress,
    required String accessToken,
    required String userId,
    String? parentId,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    return _getItems(
      serverAddress: serverAddress,
      accessToken: accessToken,
      path: 'Users/$userId/Items/Latest',
      queryParameters: {
        if (parentId != null) 'ParentId': parentId,
        'Limit': '$limit',
        'EnableImages': 'true',
        'EnableUserData': 'true',
        'EnableImageTypes': 'Primary,Thumb,Backdrop',
      },
      queryResult: false,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<EmbyLibraryItem>> _getItems({
    required String serverAddress,
    required String accessToken,
    required String path,
    required Map<String, String> queryParameters,
    required bool queryResult,
    bool forceRefresh = false,
  }) async {
    final payload = await _getPayload(
      serverAddress: serverAddress,
      accessToken: accessToken,
      path: path,
      queryParameters: queryParameters,
      forceRefresh: forceRefresh,
    );
    final dynamic rawItems;
    if (queryResult) {
      if (payload is! Map<String, dynamic>) {
        throw const EmbyLibraryRequestException();
      }
      rawItems = payload['Items'];
    } else {
      rawItems = payload;
    }
    if (rawItems is! List) throw const EmbyLibraryRequestException();
    return _parseItems(rawItems);
  }

  Future<EmbyLibraryItemPage> loadLibraryItems({
    required String serverAddress,
    required String accessToken,
    required String userId,
    required String parentId,
    required EmbyLibrarySort sortBy,
    required bool ascending,
    required int startIndex,
    String? collectionType,
    int limit = 40,
    bool forceRefresh = false,
  }) async {
    final apiSort = sortBy.apiValue;
    if (apiSort == null) throw const EmbyLibraryRequestException();
    final payload = await _getPayload(
      serverAddress: serverAddress,
      accessToken: accessToken,
      path: 'Users/$userId/Items',
      forceRefresh: forceRefresh,
      queryParameters: {
        'ParentId': parentId,
        'Recursive': 'true',
        'EnableTotalRecordCount': 'true',
        'StartIndex': '$startIndex',
        'Limit': '$limit',
        'SortBy': apiSort,
        'SortOrder': ascending ? 'Ascending' : 'Descending',
        if (collectionType?.toLowerCase() == 'tvshows')
          'IncludeItemTypes': 'Series',
        'Fields': 'ProductionYear,Overview',
        'EnableImages': 'true',
        'EnableUserData': 'true',
        'EnableImageTypes': 'Primary,Thumb,Backdrop',
      },
    );
    if (payload is! Map<String, dynamic> || payload['Items'] is! List) {
      throw const EmbyLibraryRequestException();
    }
    final items = _parseItems(payload['Items'] as List);
    final rawTotal = payload['TotalRecordCount'];
    final total = rawTotal is int
        ? rawTotal
        : startIndex + items.length + (items.length == limit ? 1 : 0);
    return EmbyLibraryItemPage(items: items, totalRecordCount: total);
  }

  Future<dynamic> _getPayload({
    required String serverAddress,
    required String accessToken,
    required String path,
    required Map<String, String> queryParameters,
    bool forceRefresh = false,
  }) async {
    final uri = _endpoint(
      serverAddress,
      path,
    ).replace(queryParameters: queryParameters);
    final cacheServer = Uri.parse(serverAddress.trim())
        .replace(userInfo: '', query: '', fragment: '')
        .toString();
    final cacheKey = '$cacheServer|${uri.path}?${uri.query}';
    return _responseCache.getOrLoad<dynamic>(
      cacheKey,
      () => _requestPayload(uri, accessToken),
      forceRefresh: forceRefresh,
    );
  }

  Future<dynamic> _requestPayload(Uri uri, String accessToken) async {
    try {
      final response = await _client
          .get(uri, headers: {..._headers, 'X-Emby-Token': accessToken})
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw EmbyLibraryRequestException(response.statusCode);
      }
      return jsonDecode(response.body);
    } on EmbyLibraryRequestException {
      rethrow;
    } on TimeoutException {
      throw const EmbyLibraryRequestException();
    } on http.ClientException {
      throw const EmbyLibraryRequestException();
    } on FormatException {
      throw const EmbyLibraryRequestException();
    } on TypeError {
      throw const EmbyLibraryRequestException();
    }
  }

  List<EmbyLibraryItem> _parseItems(List<dynamic> rawItems) {
    try {
      return rawItems
          .whereType<Map>()
          .map(
            (item) => EmbyLibraryItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false);
    } on TypeError {
      throw const EmbyLibraryRequestException();
    }
  }

  Uri imageUri({
    required String serverAddress,
    required String itemId,
    String imageType = 'Primary',
    String? imageTag,
    int maxWidth = 800,
  }) => _endpoint(serverAddress, 'Items/$itemId/Images/$imageType').replace(
    queryParameters: {
      'maxWidth': '$maxWidth',
      if (imageTag != null && imageTag.isNotEmpty) 'tag': imageTag,
    },
  );

  Map<String, String> get _headers => const {
    'Accept': 'application/json',
    'Authorization':
        'Emby Client="$_clientName", Device="$_deviceName", '
        'DeviceId="$_deviceId", Version="$_clientVersion"',
  };

  Uri _endpoint(String serverAddress, String apiPath) {
    final baseUri = Uri.parse(serverAddress.trim());
    final basePath = baseUri.path.replaceFirst(RegExp(r'/+$'), '');
    final apiRoot = basePath.endsWith('/emby') ? basePath : '$basePath/emby';
    return baseUri.replace(path: '$apiRoot/$apiPath');
  }

  void close() => _client.close();
}

class EmbyLibraryRequestException implements Exception {
  const EmbyLibraryRequestException([this.statusCode]);

  final int? statusCode;
}

enum EmbyLibrarySort {
  dateCreated('DateCreated'),
  title('SortName'),
  communityRating('CommunityRating'),
  criticRating('CriticRating'),
  productionYear('ProductionYear'),
  premiereDate('PremiereDate'),
  officialRating(null),
  datePlayed('DatePlayed'),
  runtime('Runtime'),
  bitrate(null),
  size(null),
  random('Random');

  const EmbyLibrarySort(this.apiValue);

  final String? apiValue;
}

class EmbyLibraryItemPage {
  const EmbyLibraryItemPage({
    required this.items,
    required this.totalRecordCount,
  });

  final List<EmbyLibraryItem> items;
  final int totalRecordCount;
}
