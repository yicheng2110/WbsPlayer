import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wbs_player/app/locale_preference_store.dart';
import 'package:wbs_player/app/wbs_player_app.dart';
import 'package:wbs_player/features/servers/data/server_database.dart';
import 'package:wbs_player/features/servers/models/emby_server.dart';
import 'package:wbs_player/features/servers/repositories/drift_server_repository.dart';
import 'package:wbs_player/features/servers/repositories/server_repository.dart';
import 'package:wbs_player/features/servers/services/emby_library_service.dart';
import 'package:wbs_player/features/servers/services/emby_server_service.dart';
import 'package:wbs_player/ui/core/app_colors.dart';

void main() {
  testWidgets('shows the empty server state and primary navigation', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale(
      'zh',
      'CN',
    );
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    final repository = _FakeServerRepository();
    addTearDown(repository.close);
    await tester.pumpWidget(
      WbsPlayerApp(
        serverRepository: repository,
        localePreferenceStore: _FakeLocalePreferenceStore(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('服务器'), findsNWidgets(2));
    expect(find.text('马上添加 Emby 服务器，以开始您的媒体之旅！'), findsOneWidget);
    expect(find.byKey(const Key('add-server-button')), findsOneWidget);
    expect(find.text('聚合视界'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the selected server poster wall from Emby data', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale(
      'zh',
      'CN',
    );
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    const server = EmbyServer(
      localId: 7,
      name: 'Home Emby',
      address: 'http://emby.test:8096',
      username: 'alice',
      password: 'secret',
      accessToken: 'token-abc',
      serverId: 'server-123',
      userId: 'user-456',
    );
    final repository = _FakeServerRepository(servers: [server]);
    addTearDown(repository.close);
    final serverService = EmbyServerService(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/System/Info')) {
          return http.Response(jsonEncode({'Id': 'server-123'}), 200);
        }
        return http.Response('', 404);
      }),
    );
    addTearDown(serverService.close);
    final mediaRequests = <http.Request>[];
    final libraryService = EmbyLibraryService(
      client: MockClient((request) async {
        mediaRequests.add(request);
        if (request.url.path.endsWith('/Users/user-456/Views')) {
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'library-1', 'Name': 'Movies'},
              ],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/Users/user-456/Items/Resume')) {
          return http.Response(jsonEncode({'Items': <Object>[]}), 200);
        }
        if (request.url.path.endsWith('/Users/user-456/Items/Latest')) {
          return http.Response(
            jsonEncode([
              {
                'Id': 'latest-1',
                'Name': 'Latest movie',
                'Type': 'Movie',
                'ProductionYear': 2025,
                'Overview': 'Overview returned by the Emby API',
              },
            ]),
            200,
          );
        }
        return http.Response('', 404);
      }),
    );
    addTearDown(libraryService.close);

    await tester.pumpWidget(
      WbsPlayerApp(
        serverService: serverService,
        serverRepository: repository,
        libraryService: libraryService,
        localePreferenceStore: _FakeLocalePreferenceStore(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-name-7')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      mediaRequests.map((request) => request.url.path).toList(),
      isNotEmpty,
    );
    expect(
      mediaRequests.map((request) => request.url.path).toList(),
      contains('/emby/Users/user-456/Views'),
    );
    expect(find.text('无法加载媒体内容，请检查服务器连接或重新登录'), findsNothing);
    expect(find.text('暂无内容'), findsNothing);
    expect(find.text('Home Emby'), findsWidgets);
    expect(find.byKey(const Key('featured-carousel')), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byKey(const Key('emby-home-scroll'))))
          .brightness,
      Brightness.light,
    );
    final homeScaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(homeScaffold.backgroundColor, AppColors.mediaBackground);
    expect(find.text('Latest movie'), findsWidgets);
    await tester.drag(
      find.byKey(const Key('emby-home-scroll')),
      const Offset(0, -700),
    );
    await tester.pump();
    expect(find.text('继续观看'), findsOneWidget);
    expect(find.text('暂无内容'), findsOneWidget);
    final libraryRail = find.byKey(const ValueKey('library-library-1'));
    final libraryTitle = tester.widget<Text>(
      find.descendant(of: libraryRail, matching: find.text('Movies')),
    );
    expect(libraryTitle.style?.color, AppColors.mediaInk);
    final mediaTitle = tester.widget<Text>(
      find.descendant(of: libraryRail, matching: find.text('Latest movie')),
    );
    expect(mediaTitle.style?.color, AppColors.mediaInk);
    expect(find.text('Movies'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'checks reachability, prompts for credentials and authenticates',
    (tester) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale(
        'zh',
        'CN',
      );
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      final requests = <http.Request>[];
      var authenticationAttempts = 0;
      final service = EmbyServerService(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/System/Info/Public')) {
            return http.Response(jsonEncode({'Id': 'server-123'}), 200);
          }
          if (request.url.path.endsWith('/Users/AuthenticateByName')) {
            authenticationAttempts++;
            if (authenticationAttempts == 1) return http.Response('', 401);
            return http.Response(
              jsonEncode({
                'AccessToken': 'token-abc',
                'ServerId': 'server-123',
              }),
              200,
            );
          }
          return http.Response('', 404);
        }),
      );
      addTearDown(service.close);
      final repository = _FakeServerRepository();
      addTearDown(repository.close);

      await tester.pumpWidget(
        WbsPlayerApp(
          serverService: service,
          serverRepository: repository,
          localePreferenceStore: _FakeLocalePreferenceStore(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-server-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('server-name-field')),
        '家里的媒体库',
      );
      await tester.enterText(
        find.byKey(const Key('server-address-field')),
        'http://192.168.1.10:8096',
      );
      await tester.tap(find.byKey(const Key('confirm-add-server')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('emby-credentials-dialog')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('emby-username-field')),
        'alice',
      );
      await tester.enterText(
        find.byKey(const Key('emby-password-field')),
        'wrong-password',
      );
      await tester.tap(find.byKey(const Key('emby-sign-in-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('emby-login-error')), findsOneWidget);
      expect(find.byKey(const Key('emby-credentials-dialog')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('emby-password-field')),
        'secret',
      );
      await tester.tap(find.byKey(const Key('emby-sign-in-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('家里的媒体库'), findsOneWidget);
      expect(find.text('http://192.168.1.10:8096'), findsOneWidget);
      expect(requests, hasLength(3));
      expect(requests.first.url.path, '/emby/System/Info/Public');
      expect(requests[1].url.path, '/emby/Users/AuthenticateByName');
      expect(requests.last.url.path, '/emby/Users/AuthenticateByName');
      expect(await repository.getAllServers(), hasLength(1));
      final savedServer = (await repository.getAllServers()).single;
      expect(savedServer.username, 'alice');
      expect(savedServer.password, 'secret');
      expect(savedServer.accessToken, 'token-abc');
      expect(savedServer.serverId, 'server-123');
      expect(jsonDecode(requests[1].body), {
        'Username': 'alice',
        'Pw': 'wrong-password',
      });
      expect(jsonDecode(requests.last.body), {
        'Username': 'alice',
        'Pw': 'secret',
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('does not ask for credentials when the server is unreachable', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale(
      'zh',
      'CN',
    );
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    final service = EmbyServerService(
      client: MockClient((_) async => http.Response('', 404)),
    );
    addTearDown(service.close);
    final repository = _FakeServerRepository();
    addTearDown(repository.close);

    await tester.pumpWidget(
      WbsPlayerApp(
        serverService: service,
        serverRepository: repository,
        localePreferenceStore: _FakeLocalePreferenceStore(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-server-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('server-address-field')),
      'http://192.168.1.10:8096',
    );
    await tester.tap(find.byKey(const Key('confirm-add-server')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('emby-credentials-dialog')), findsNothing);
    expect(find.byKey(const Key('server-connection-error')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits a saved server and persists the updated details', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale(
      'zh',
      'CN',
    );
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    const server = EmbyServer(
      localId: 7,
      name: 'Old server',
      address: 'http://old.test:8096',
      username: 'alice',
      password: 'old-password',
      accessToken: 'old-token',
      serverId: 'server-123',
    );
    final repository = _FakeServerRepository(servers: [server]);
    addTearDown(repository.close);
    final requests = <http.Request>[];
    final service = EmbyServerService(
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/System/Info/Public')) {
          return http.Response(jsonEncode({'Id': 'server-123'}), 200);
        }
        if (request.url.path.endsWith('/Users/AuthenticateByName')) {
          return http.Response(
            jsonEncode({
              'AccessToken': 'new-token',
              'ServerId': 'server-123',
              'User': {'Id': 'user-456'},
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/System/Info')) {
          return http.Response(jsonEncode({'Id': 'server-123'}), 200);
        }
        return http.Response('', 404);
      }),
    );
    addTearDown(service.close);

    await tester.pumpWidget(
      WbsPlayerApp(
        serverRepository: repository,
        serverService: service,
        localePreferenceStore: _FakeLocalePreferenceStore(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('edit-server-7')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-server-dialog')), findsOneWidget);
    expect(find.text('Old server'), findsWidgets);
    expect(find.text('http://old.test:8096'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('edit-server-name-field')),
      'New server',
    );
    await tester.enterText(
      find.byKey(const Key('edit-server-address-field')),
      'http://new.test:8096',
    );
    await tester.enterText(
      find.byKey(const Key('edit-server-username-field')),
      'bob',
    );
    await tester.enterText(
      find.byKey(const Key('edit-server-password-field')),
      'new-password',
    );
    await tester.tap(find.byKey(const Key('confirm-edit-server')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    final updatedServer = (await repository.getAllServers()).single;
    expect(updatedServer.localId, 7);
    expect(updatedServer.name, 'New server');
    expect(updatedServer.address, 'http://new.test:8096');
    expect(updatedServer.username, 'bob');
    expect(updatedServer.password, 'new-password');
    expect(updatedServer.accessToken, 'new-token');
    expect(updatedServer.userId, 'user-456');
    expect(find.text('New server'), findsOneWidget);
    expect(find.text('http://new.test:8096'), findsOneWidget);
    expect(
      requests.map((request) => request.url.path),
      contains('/emby/Users/AuthenticateByName'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('marks saved servers maroon when token probe fails', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale(
      'zh',
      'CN',
    );
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    final repository = _FakeServerRepository(
      servers: [
        const EmbyServer(
          localId: 7,
          name: 'Saved Emby',
          address: 'http://emby.test:8096',
          username: 'alice',
          password: 'secret',
          accessToken: 'expired-token',
          serverId: 'server-123',
        ),
      ],
    );
    addTearDown(repository.close);

    final requests = <http.Request>[];
    final service = EmbyServerService(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('', 401);
      }),
    );
    addTearDown(service.close);

    await tester.pumpWidget(
      WbsPlayerApp(
        serverRepository: repository,
        serverService: service,
        localePreferenceStore: _FakeLocalePreferenceStore(),
      ),
    );
    await tester.pumpAndSettle();

    final name = tester.widget<Text>(
      find.byKey(const ValueKey('server-name-7')),
    );
    final address = tester.widget<Text>(
      find.byKey(const ValueKey('server-address-7')),
    );
    expect(name.style?.color, const Color(0xFF800020));
    expect(address.style?.color, const Color(0xFF800020));
    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/emby/System/Info');
    expect(requests.single.headers['x-emby-token'], 'expired-token');
  });
}

class _FakeLocalePreferenceStore implements LocalePreferenceStore {
  @override
  Future<String?> read() async => 'zh';

  @override
  Future<void> write(String value) async {}
}

class _FakeServerRepository implements ServerRepository {
  _FakeServerRepository({List<EmbyServer> servers = const []})
    : _servers = List.of(servers);

  final List<EmbyServer> _servers;
  int _nextId = 1;

  @override
  Future<List<EmbyServer>> getAllServers() async => List.of(_servers);

  @override
  Future<EmbyServer> saveServer(EmbyServer server) async {
    final saved = server.copyWith(localId: _nextId++);
    _servers.add(saved);
    return saved;
  }

  @override
  Future<void> updateServer(EmbyServer server) async {
    final index = _servers.indexWhere(
      (saved) => saved.localId == server.localId,
    );
    if (index != -1) _servers[index] = server;
  }

  @override
  Future<void> updateAuthentication({
    required int localId,
    required String accessToken,
    required String userId,
  }) async {}

  @override
  Future<void> close() async {}
}
