import '../data/server_database.dart';
import '../models/emby_server.dart';
import 'server_repository.dart';

/// Drift-backed server repository for SQLite persistence.
class DriftServerRepository implements ServerRepository {
  DriftServerRepository({ServerDatabase? database})
    : _database = database ?? ServerDatabase(),
      _ownsDatabase = database == null;

  final ServerDatabase _database;
  final bool _ownsDatabase;

  @override
  Future<List<EmbyServer>> getAllServers() async {
    final rows = await _database.select(_database.storedServers).get();
    return rows
        .map(
          (row) => EmbyServer(
            localId: row.id,
            name: row.name,
            address: row.address,
            username: row.username,
            password: row.password,
            accessToken: row.accessToken,
            serverId: row.serverId,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<EmbyServer> saveServer(EmbyServer server) async {
    final id = await _database
        .into(_database.storedServers)
        .insert(
          StoredServersCompanion.insert(
            name: server.name,
            address: server.address,
            username: server.username,
            password: server.password,
            accessToken: server.accessToken,
            serverId: server.serverId,
          ),
        );
    return server.copyWith(localId: id);
  }

  @override
  Future<void> close() async {
    if (_ownsDatabase) await _database.close();
  }
}
