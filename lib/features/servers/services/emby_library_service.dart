import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/emby_media.dart';

/// Reads a user's Emby libraries and media items through the REST API.
class EmbyLibraryService {
  EmbyLibraryService({
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client();

  static const _clientName = 'Wbs Player';
  static const _deviceName = 'Flutter';
  static const _deviceId = 'wbs-player';
  static const _clientVersion = '0.1.0';

  final http.Client _client;
  final Duration requestTimeout;

  Future<EmbyHomeContent> loadHome({
    required String serverAddress,
    required String accessToken,
    required String userId,
  }) async {
    final libraries = await _loadLibraries(
      serverAddress: serverAddress,
      accessToken: accessToken,
      userId: userId,
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
            ),
          ),
        ),
      ),
      _getItems(
        serverAddress: serverAddress,
        accessToken: accessToken,
        path: 'Users/$userId/Items/Resume',
        queryParameters: const {
          'Limit': '20',
          'EnableImages': 'true',
          'EnableUserData': 'true',
          'EnableImageTypes': 'Primary,Thumb,Backdrop',
        },
        queryResult: true,
      ),
      _loadLatestItems(
        serverAddress: serverAddress,
        accessToken: accessToken,
        userId: userId,
        limit: 10,
      ),
    ]);
    return EmbyHomeContent(
      libraries: parts[0] as List<EmbyLibrarySection>,
      recentlyPlayed: parts[1] as List<EmbyLibraryItem>,
      featured: parts[2] as List<EmbyLibraryItem>,
    );
  }

  Future<List<EmbyLibrary>> _loadLibraries({
    required String serverAddress,
    required String accessToken,
    required String userId,
  }) async {
    final items = await _getItems(
      serverAddress: serverAddress,
      accessToken: accessToken,
      path: 'Users/$userId/Views',
      queryParameters: const {
        'IncludeExternalContent': 'false',
        'EnableImages': 'true',
      },
      queryResult: true,
    );
    return items
        .map((item) => EmbyLibrary(id: item.id, name: item.name))
        .where((library) => library.id.isNotEmpty && library.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<EmbyLibraryItem>> _loadLatestItems({
    required String serverAddress,
    required String accessToken,
    required String userId,
    String? parentId,
    int limit = 20,
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
    );
  }

  Future<List<EmbyLibraryItem>> _getItems({
    required String serverAddress,
    required String accessToken,
    required String path,
    required Map<String, String> queryParameters,
    required bool queryResult,
  }) async {
    final uri = _endpoint(
      serverAddress,
      path,
    ).replace(queryParameters: queryParameters);
    try {
      final response = await _client
          .get(uri, headers: {..._headers, 'X-Emby-Token': accessToken})
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw EmbyLibraryRequestException(response.statusCode);
      }
      final payload = jsonDecode(response.body);
      final dynamic rawItems = queryResult
          ? (payload as Map<String, dynamic>)['Items']
          : payload;
      if (rawItems is! List) throw const EmbyLibraryRequestException();
      return rawItems
          .whereType<Map>()
          .map(
            (item) => EmbyLibraryItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false);
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
