import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wbs_player/features/servers/data/server_database.dart';
import 'package:wbs_player/features/servers/models/emby_server.dart';
import 'package:wbs_player/features/servers/repositories/drift_server_repository.dart';

void main() {
  test(
    'persists server details and credentials in SQLite after reopening',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'wbs-player-',
      );
      addTearDown(() => tempDirectory.delete(recursive: true));
      final databaseFile = File(p.join(tempDirectory.path, 'servers.sqlite'));

      var database = ServerDatabase(NativeDatabase(databaseFile));
      var repository = DriftServerRepository(database: database);

      const server = EmbyServer(
        name: 'Home Emby',
        address: 'http://emby.test:8096',
        username: 'alice',
        password: 'plain-text-password',
        accessToken: 'access-token',
        serverId: 'emby-server-id',
      );

      final savedServer = await repository.saveServer(server);
      await database.close();

      database = ServerDatabase(NativeDatabase(databaseFile));
      repository = DriftServerRepository(database: database);
      addTearDown(database.close);
      final loadedServers = await repository.getAllServers();

      expect(savedServer.localId, isNotNull);
      expect(loadedServers, hasLength(1));
      expect(loadedServers.single.localId, savedServer.localId);
      expect(loadedServers.single.name, server.name);
      expect(loadedServers.single.address, server.address);
      expect(loadedServers.single.username, server.username);
      expect(loadedServers.single.password, 'plain-text-password');
      expect(loadedServers.single.accessToken, 'access-token');
      expect(loadedServers.single.serverId, server.serverId);
    },
  );
}
