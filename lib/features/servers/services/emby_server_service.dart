import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/emby_server.dart';

/// Communicates with an Emby server for reachability checks and user login.
class EmbyServerService {
  EmbyServerService({
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client();

  static const _clientName = 'Wbs Player';
  static const _deviceName = 'Flutter';
  static const _deviceId = 'wbs-player';
  static const _clientVersion = '0.1.0';

  final http.Client _client;
  final Duration requestTimeout;

  /// Checks that the provided address responds as an Emby server.
  Future<void> checkConnection(String serverAddress) async {
    try {
      final response = await _client
          .get(
            _endpoint(serverAddress, 'System/Info/Public'),
            headers: _headers,
          )
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw const EmbyConnectionException();
      }
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic> ||
          payload['Id'] is! String ||
          (payload['Id'] as String).isEmpty) {
        throw const EmbyConnectionException();
      }
    } on EmbyConnectionException {
      rethrow;
    } on TimeoutException {
      throw const EmbyConnectionException();
    } on http.ClientException {
      throw const EmbyConnectionException();
    } on FormatException {
      throw const EmbyConnectionException();
    }
  }

  /// Reauthenticates a stored account and reads its current Emby user ID.
  Future<EmbyAuthenticationResult> authenticateStoredUser(
    EmbyServer server,
  ) async {
    final authentication = await authenticate(
      serverAddress: server.address,
      username: server.username,
      password: server.password,
    );
    if (authentication.serverId != server.serverId ||
        authentication.userId == null) {
      throw const EmbyServerRequestException();
    }
    return authentication;
  }

  /// Checks whether an access token can read the authenticated system info.
  Future<bool> isAccessTokenValid({
    required String serverAddress,
    required String accessToken,
    required String serverId,
  }) async {
    try {
      final response = await _client
          .get(
            _endpoint(serverAddress, 'System/Info'),
            headers: {..._headers, 'X-Emby-Token': accessToken},
          )
          .timeout(requestTimeout);
      if (response.statusCode != 200) return false;
      final payload = jsonDecode(response.body);
      return payload is Map<String, dynamic> && payload['Id'] == serverId;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    } on FormatException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Authenticates a user and returns the token, server ID, and Emby user ID.
  Future<EmbyAuthenticationResult> authenticate({
    required String serverAddress,
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client
          .post(
            _endpoint(serverAddress, 'Users/AuthenticateByName'),
            headers: {
              ..._headers,
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode({'Username': username, 'Pw': password}),
          )
          .timeout(requestTimeout);
      if (response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 403) {
        throw const EmbyAuthenticationException();
      }
      if (response.statusCode != 200) {
        throw const EmbyServerRequestException();
      }
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic> ||
          payload['AccessToken'] is! String ||
          (payload['AccessToken'] as String).isEmpty ||
          payload['ServerId'] is! String ||
          (payload['ServerId'] as String).isEmpty) {
        throw const EmbyServerRequestException();
      }
      final user = payload['User'];
      final userId = switch (user) {
        {'Id': final String id} when id.isNotEmpty => id,
        _ => null,
      };
      return EmbyAuthenticationResult(
        username: username,
        password: password,
        accessToken: payload['AccessToken'] as String,
        serverId: payload['ServerId'] as String,
        userId: userId,
      );
    } on EmbyAuthenticationException {
      rethrow;
    } on EmbyServerRequestException {
      rethrow;
    } on TimeoutException {
      throw const EmbyConnectionException();
    } on http.ClientException {
      throw const EmbyConnectionException();
    } on FormatException {
      throw const EmbyServerRequestException();
    }
  }

  /// Releases the underlying HTTP client.
  void close() => _client.close();

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
    final path = '$apiRoot/$apiPath'.replaceFirst(RegExp(r'^/+/'), '/');
    return Uri(
      scheme: baseUri.scheme,
      userInfo: baseUri.userInfo,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: path,
    );
  }
}

/// The result of an Emby username/password authentication.
class EmbyAuthenticationResult {
  const EmbyAuthenticationResult({
    required this.username,
    required this.password,
    required this.accessToken,
    required this.serverId,
    this.userId,
  });

  final String username;
  final String password;
  final String accessToken;
  final String serverId;
  final String? userId;
}

/// A failure while locating or reaching an Emby server.
class EmbyConnectionException implements Exception {
  const EmbyConnectionException();
}

/// Emby rejected the supplied username or password.
class EmbyAuthenticationException implements Exception {
  const EmbyAuthenticationException();
}

/// The server returned an unexpected response or an API error.
class EmbyServerRequestException implements Exception {
  const EmbyServerRequestException();
}
