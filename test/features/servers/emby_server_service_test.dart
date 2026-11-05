import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wbs_player/features/servers/services/emby_server_service.dart';

void main() {
  group('EmbyServerService', () {
    test('checks the Emby public system info endpoint', () async {
      Uri? requestedUri;
      final service = EmbyServerService(
        client: MockClient((request) async {
          requestedUri = request.url;
          expect(request.method, 'GET');
          expect(request.headers['authorization'], contains('Emby Client='));
          return http.Response(jsonEncode({'Id': 'server-123'}), 200);
        }),
      );
      addTearDown(service.close);

      await service.checkConnection('http://emby.example:8096/media');

      expect(
        requestedUri,
        Uri.parse('http://emby.example:8096/media/emby/System/Info/Public'),
      );
    });

    test('rejects an address that does not respond as Emby', () async {
      final service = EmbyServerService(
        client: MockClient((_) async => http.Response('not found', 404)),
      );
      addTearDown(service.close);

      await expectLater(
        service.checkConnection('http://emby.example:8096'),
        throwsA(isA<EmbyConnectionException>()),
      );
    });

    test(
      'posts username and password and returns the authentication token',
      () async {
        Uri? requestedUri;
        Map<String, dynamic>? requestBody;
        final service = EmbyServerService(
          client: MockClient((request) async {
            requestedUri = request.url;
            requestBody = jsonDecode(request.body) as Map<String, dynamic>;
            expect(request.method, 'POST');
            expect(
              request.headers['content-type'],
              contains('application/json'),
            );
            return http.Response(
              jsonEncode({
                'AccessToken': 'token-abc',
                'ServerId': 'server-123',
              }),
              200,
            );
          }),
        );
        addTearDown(service.close);

        final result = await service.authenticate(
          serverAddress: 'https://emby.example/emby/',
          username: 'alice',
          password: 'secret',
        );

        expect(
          requestedUri,
          Uri.parse('https://emby.example/emby/Users/AuthenticateByName'),
        );
        expect(requestBody, {'Username': 'alice', 'Pw': 'secret'});
        expect(result.username, 'alice');
        expect(result.accessToken, 'token-abc');
        expect(result.serverId, 'server-123');
      },
    );

    test('probes a token and verifies the Emby server identity', () async {
      http.Request? request;
      final service = EmbyServerService(
        client: MockClient((incomingRequest) async {
          request = incomingRequest;
          return http.Response(jsonEncode({'Id': 'server-123'}), 200);
        }),
      );
      addTearDown(service.close);

      final valid = await service.isAccessTokenValid(
        serverAddress: 'http://emby.example:8096',
        accessToken: 'token-abc',
        serverId: 'server-123',
      );

      expect(valid, isTrue);
      expect(request?.method, 'GET');
      expect(request?.url.path, '/emby/System/Info');
      expect(request?.headers['x-emby-token'], 'token-abc');
    });

    test(
      'returns false when the token is rejected or the server id differs',
      () async {
        final responses = [
          http.Response('', 401),
          http.Response(jsonEncode({'Id': 'other-server'}), 200),
        ];
        final service = EmbyServerService(
          client: MockClient((_) async => responses.removeAt(0)),
        );
        addTearDown(service.close);

        for (var attempt = 0; attempt < 2; attempt++) {
          expect(
            await service.isAccessTokenValid(
              serverAddress: 'http://emby.example:8096',
              accessToken: 'token-abc',
              serverId: 'server-123',
            ),
            isFalse,
          );
        }
      },
    );

    test('distinguishes rejected credentials from server errors', () async {
      final service = EmbyServerService(
        client: MockClient((_) async => http.Response('', 401)),
      );
      addTearDown(service.close);

      await expectLater(
        service.authenticate(
          serverAddress: 'http://emby.example:8096',
          username: 'alice',
          password: 'wrong',
        ),
        throwsA(isA<EmbyAuthenticationException>()),
      );
    });
  });
}
