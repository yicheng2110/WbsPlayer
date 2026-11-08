import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'emby_cache_storage.dart';

/// Persistent disk cache for Emby posters, backdrops, and other images.
///
/// Image bytes are saved in the app-scoped external cache directory, keyed by
/// the image URL (which includes Emby's image tag when available). Auth tokens
/// are sent only as request headers and are never written to disk.
class EmbyImageCache {
  EmbyImageCache({
    http.Client? client,
    Future<Directory> Function()? directoryProvider,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _directoryProvider =
           directoryProvider ?? EmbyCacheStorage.imageDirectory;

  /// Process-wide image cache used by Emby image widgets.
  static final shared = EmbyImageCache();

  final http.Client _client;
  final bool _ownsClient;
  final Future<Directory> Function() _directoryProvider;
  final Duration requestTimeout;
  final Map<String, Future<Uint8List>> _inFlight = {};
  int _generation = 0;

  /// Returns a cached image or downloads and persists it.
  Future<Uint8List> load(Uri uri, {Map<String, String>? headers}) async {
    final key = uri.replace(userInfo: '').toString();
    final pending = _inFlight[key];
    if (pending != null) return pending;

    final generation = _generation;
    final request = _load(key, uri, headers, generation);
    _inFlight[key] = request;
    try {
      return await request;
    } finally {
      if (identical(_inFlight[key], request)) _inFlight.remove(key);
    }
  }

  Future<Uint8List> _load(
    String key,
    Uri uri,
    Map<String, String>? headers,
    int generation,
  ) async {
    try {
      final directory = await _directoryProvider();
      final file = _fileForKey(directory, key);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) return bytes;
        await file.delete();
      }
    } on FileSystemException {
      // External cache files are optional; fall back to downloading.
    }

    final response = await _client
        .get(uri, headers: headers)
        .timeout(requestTimeout);
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw HttpException(
        'Emby image request failed with status ${response.statusCode}.',
        uri: uri,
      );
    }
    final bytes = response.bodyBytes;
    if (generation == _generation) await _persist(key, bytes);
    return bytes;
  }

  Future<void> _persist(String key, Uint8List bytes) async {
    try {
      final directory = await _directoryProvider();
      await directory.create(recursive: true);
      final file = _fileForKey(directory, key);
      final temporaryFile = File('${file.path}.tmp');
      await temporaryFile.writeAsBytes(bytes, flush: true);
      if (await file.exists()) await file.delete();
      await temporaryFile.rename(file.path);
    } on FileSystemException {
      // Keep the image usable in memory when cache storage is unavailable/full.
    }
  }

  /// Removes cached bytes for an image so a later build downloads it again.
  Future<void> evict(Uri uri) async {
    final key = uri.replace(userInfo: '').toString();
    try {
      final file = _fileForKey(await _directoryProvider(), key);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Cache eviction is best effort.
    }
  }

  /// Clears persisted images and stops in-flight requests repopulating the
  /// cache after a user-initiated clear operation.
  Future<void> clear() async {
    _generation++;
    _inFlight.clear();
    try {
      final directory = await _directoryProvider();
      if (await directory.exists()) await directory.delete(recursive: true);
    } on FileSystemException {
      // Cache clearing is best effort if the platform already removed it.
    }
  }

  /// Releases an HTTP client created by this cache.
  void close() {
    if (_ownsClient) _client.close();
  }

  File _fileForKey(Directory directory, String key) {
    final digest = sha256.convert(utf8.encode(key));
    return File(p.join(directory.path, '$digest.img'));
  }
}
