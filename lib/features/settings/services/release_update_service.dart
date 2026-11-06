import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

class ReleaseUpdate {
  const ReleaseUpdate({
    required this.currentVersion,
    required this.latestVersion,
    required this.apkUri,
  });

  final String currentVersion;
  final String latestVersion;
  final Uri? apkUri;

  bool get isLatest =>
      _versionPrecedence(currentVersion) == _versionPrecedence(latestVersion);

  static Version _versionPrecedence(String value) {
    final version = Version.parse(value);
    return Version(
      version.major,
      version.minor,
      version.patch,
      pre: version.preRelease.isEmpty ? null : version.preRelease.join('.'),
    );
  }

  factory ReleaseUpdate.fromJson(
    Map<String, dynamic> json, {
    required String currentVersion,
  }) {
    final tagName = json['tag_name'];
    if (tagName is! String || tagName.isEmpty) {
      throw const FormatException('Release tag is missing.');
    }

    final latestVersion = tagName.replaceFirst(
      RegExp(r'^v', caseSensitive: false),
      '',
    );
    Version.parse(latestVersion);

    Uri? apkUri;
    final assets = json['assets'];
    if (assets is List) {
      for (final asset in assets.whereType<Map<String, dynamic>>()) {
        if (asset['name'] != 'app-release.apk') continue;
        final downloadUrl = asset['browser_download_url'];
        if (downloadUrl is! String) break;
        final candidate = Uri.tryParse(downloadUrl);
        if (candidate?.scheme == 'https') apkUri = candidate;
        break;
      }
    }

    final release = ReleaseUpdate(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      apkUri: apkUri,
    );
    if (!release.isLatest && apkUri == null) {
      throw const FormatException(
        'Release does not contain a valid app-release.apk asset.',
      );
    }
    if (apkUri != null &&
        apkUri.host != 'github.com' &&
        apkUri.host != 'objects.githubusercontent.com' &&
        apkUri.host != 'release-assets.githubusercontent.com') {
      throw const FormatException('APK download host is not trusted.');
    }
    return release;
  }
}

class ReleaseUpdateService {
  ReleaseUpdateService({
    http.Client? client,
    Future<String> Function()? currentVersionProvider,
    Future<Directory> Function()? temporaryDirectoryProvider,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _currentVersionProvider = currentVersionProvider ?? _readCurrentVersion,
       _temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? getTemporaryDirectory;

  static const _latestReleaseUri =
      'https://api.github.com/repos/yicheng2110/WbsPlayer/releases/latest';

  final http.Client _client;
  final bool _ownsClient;
  final Future<String> Function() _currentVersionProvider;
  final Future<Directory> Function() _temporaryDirectoryProvider;

  Future<ReleaseUpdate> checkForUpdate() async {
    final currentVersion = await _currentVersionProvider();
    final response = await _client
        .get(
          Uri.parse(_latestReleaseUri),
          headers: const {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
            'User-Agent': 'WbsPlayer',
          },
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'GitHub returned status ${response.statusCode}.',
        uri: Uri.parse(_latestReleaseUri),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('GitHub release response is invalid.');
    }
    return ReleaseUpdate.fromJson(decoded, currentVersion: currentVersion);
  }

  Future<File> downloadApk(
    ReleaseUpdate release, {
    required void Function(int receivedBytes, int? totalBytes) onProgress,
  }) async {
    final apkUri = release.apkUri;
    if (apkUri == null) {
      throw const FormatException('Release does not contain app-release.apk.');
    }
    final request = http.Request('GET', apkUri);
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != HttpStatus.ok) {
      await response.stream.drain<void>();
      throw HttpException(
        'APK download returned status ${response.statusCode}.',
        uri: apkUri,
      );
    }

    final directory = await _temporaryDirectoryProvider();
    final file = File(p.join(directory.path, 'wbs-player-update.apk'));
    final totalBytes = response.contentLength;
    final sink = file.openWrite();
    var receivedBytes = 0;
    try {
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 30),
      )) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        onProgress(
          receivedBytes,
          totalBytes != null && totalBytes > 0 ? totalBytes : null,
        );
      }
      await sink.flush();
      await sink.close();
      if (totalBytes != null && totalBytes > 0 && receivedBytes != totalBytes) {
        throw const HttpException('APK download was incomplete.');
      }
      return file;
    } catch (_) {
      await sink.close();
      if (await file.exists()) await file.delete();
      rethrow;
    }
  }

  void close() {
    if (_ownsClient) _client.close();
  }

  static Future<String> _readCurrentVersion() async =>
      (await PackageInfo.fromPlatform()).version;
}
