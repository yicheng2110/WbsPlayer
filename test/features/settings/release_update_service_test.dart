import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wbs_player/features/settings/services/release_update_service.dart';

void main() {
  group('ReleaseUpdateService', () {
    test('parses latest tag and exact APK asset', () async {
      final service = ReleaseUpdateService(
        currentVersionProvider: () async => '0.0.5',
        client: MockClient((request) async {
          expect(
            request.url.path,
            '/repos/yicheng2110/WbsPlayer/releases/latest',
          );
          return http.Response(
            jsonEncode({
              'tag_name': 'v0.0.6',
              'assets': [
                {
                  'name': 'app-release.apk',
                  'browser_download_url': 'https://github.com/yicheng2110/WbsPlayer/releases/download/v0.0.6/app-release.apk',
                },
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);

      final result = await service.checkForUpdate();

      expect(result.currentVersion, '0.0.5');
      expect(result.latestVersion, '0.0.6');
      expect(result.isLatest, isFalse);
      expect(result.apkUri!.path, endsWith('/app-release.apk'));
    });

    test('treats equivalent version strings as the same version', () {
      final release = ReleaseUpdate(
        currentVersion: '1.2.3+4',
        latestVersion: '1.2.3',
        apkUri: Uri.https('example.com', '/app-release.apk'),
      );
      expect(release.isLatest, isTrue);
    });

    test('accepts the current version even when no APK is attached', () {
      final release = ReleaseUpdate.fromJson({
        'tag_name': 'v1.2.3',
        'assets': <Object?>[],
      }, currentVersion: '1.2.3+9');

      expect(release.isLatest, isTrue);
      expect(release.apkUri, isNull);
    });

    test('rejects a release without app-release.apk', () {
      expect(
        () => ReleaseUpdate.fromJson({
          'tag_name': 'v1.0.0',
          'assets': [
            {
              'name': 'windows-setup.exe',
              'browser_download_url': 'https://example.com/setup.exe',
            },
          ],
        }, currentVersion: '0.9.0'),
        throwsFormatException,
      );
    });

    test('streams APK contents and reports byte progress', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'wbs_update_test_',
      );
      addTearDown(() => tempDirectory.delete(recursive: true));
      final service = ReleaseUpdateService(
        client: MockClient((request) async {
          expect(request.url.path, '/app-release.apk');
          return http.Response.bytes([1, 2, 3, 4], 200);
        }),
        temporaryDirectoryProvider: () async => tempDirectory,
      );
      addTearDown(service.close);
      final release = ReleaseUpdate(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        apkUri: Uri.https('example.com', '/app-release.apk'),
      );
      final progressEvents = <(int, int?)>[];

      final file = await service.downloadApk(
        release,
        onProgress: (receivedBytes, totalBytes) {
          progressEvents.add((receivedBytes, totalBytes));
        },
      );

      expect(await file.readAsBytes(), [1, 2, 3, 4]);
      expect(progressEvents, isNotEmpty);
      expect(progressEvents.last.$1, 4);
    });
  });
}
