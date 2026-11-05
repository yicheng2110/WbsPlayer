import '../models/emby_server.dart';

/// Stores configured Emby servers and their credentials.
abstract interface class ServerRepository {
  /// Reads every configured server from persistent storage.
  Future<List<EmbyServer>> getAllServers();

  /// Inserts a successfully authenticated server and returns its local ID.
  Future<EmbyServer> saveServer(EmbyServer server);

  /// Releases resources owned by this repository.
  Future<void> close();
}
