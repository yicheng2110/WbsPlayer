import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'server_database.g.dart';

/// SQLite table containing configured Emby servers and their credentials.
class StoredServers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  TextColumn get username => text()();
  TextColumn get password => text()();
  TextColumn get accessToken => text()();
  TextColumn get serverId => text()();
  TextColumn get userId => text().nullable()();
}

/// Persistent database used by the server feature.
@DriftDatabase(tables: [StoredServers])
class ServerDatabase extends _$ServerDatabase {
  ServerDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'wbs_player_servers'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(storedServers, storedServers.userId);
      }
    },
  );
}
