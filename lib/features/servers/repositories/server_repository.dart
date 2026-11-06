import '../models/emby_server.dart';

/// Stores configured Emby servers and their credentials.
abstract interface class ServerRepository {
  /// Reads every configured server from persistent storage.
  Future<List<EmbyServer>> getAllServers();

  /// Inserts a successfully authenticated server and returns its local ID.
  Future<EmbyServer> saveServer(EmbyServer server);

  /// Updates all stored details for a server that has a local ID.
  Future<void> updateServer(EmbyServer server);

  /// Updates a saved server's resolved Emby user identifier.
  Future<void> updateAuthentication({
    required int localId,
    required String accessToken,
    required String userId,
  });

  /// Releases resources owned by this repository.
  Future<void> close();
}
