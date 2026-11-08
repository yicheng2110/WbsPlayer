import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'emby_cache_storage.dart';

/// Persistent, token-free cache for successful Emby JSON API responses.
///
/// Responses have no time-based expiry. A successful forced refresh replaces
/// the stored value, and callers can invalidate a server/user scope after a
/// mutation. Playback media bytes are never handled by this cache.
class EmbyApiResponseCache {
  EmbyApiResponseCache({
    this.persist = false,
    Future<Directory> Function()? directoryProvider,
    int maxMemoryEntries = 128,
    Duration maxAge = const Duration(days: 36500),
    int? maxEntries,
    SharedPreferences? preferences,
  }) : maxMemoryEntries = maxEntries ?? maxMemoryEntries,
       _directoryProvider = directoryProvider ?? EmbyCacheStorage.apiDirectory,
       _preferences = preferences,
       assert((maxEntries ?? maxMemoryEntries) > 0),
       assert(maxAge > Duration.zero);

  /// Process-wide cache shared by Emby services.
  static final shared = EmbyApiResponseCache(persist: true);
  static const _legacyStorageKey = 'emby_api_response_cache_v1';

  final bool persist;
  final int maxMemoryEntries;
  final Future<Directory> Function() _directoryProvider;
  final SharedPreferences? _preferences;
  final Map<String, Object?> _entries = {};
  final Map<String, Future<Object?>> _inFlight = {};
  int _generation = 0;

  /// Returns a saved value, or loads and permanently caches a successful API
  /// response. Concurrent requests sharing [key] use one disk/network request.
  Future<T> getOrLoad<T>(
    String key,
    Future<T> Function() load, {
    bool forceRefresh = false,
    bool persistValue = true,
  }) async {
    if (!forceRefresh && _entries.containsKey(key)) {
      final value = _entries.remove(key);
      _entries[key] = value;
      return value as T;
    }

    final pending = _inFlight[key];
    if (pending != null) return await pending as T;

    final generation = _generation;
    final request = _loadOrFetch<T>(
      key,
      load,
      forceRefresh: forceRefresh,
      persistValue: persistValue,
      generation: generation,
    );
    _inFlight[key] = request;
    try {
      return await request;
    } finally {
      if (identical(_inFlight[key], request)) _inFlight.remove(key);
    }
  }

  Future<T> _loadOrFetch<T>(
    String key,
    Future<T> Function() load, {
    required bool forceRefresh,
    required bool persistValue,
    required int generation,
  }) async {
    if (persist && !forceRefresh) {
      final cached = await _readPersisted(key);
      if (cached != null) {
        _remember(key, cached.value);
        return cached.value as T;
      }
    }

    final value = await Future<T>.sync(load);
    if (generation == _generation) {
      _remember(key, value);
      if (persist && persistValue) await _writePersisted(key, value);
    }
    return value;
  }

  /// Removes cached entries whose keys start with [prefix].
  void invalidatePrefix(String prefix) {
    unawaited(_invalidatePersistedPrefix(prefix));
  }

  Future<void> _invalidatePersistedPrefix(String prefix) async {
    _entries.removeWhere((key, _) => key.startsWith(prefix));
    if (!persist) return;
    try {
      final directory = await _directoryProvider();
      if (!await directory.exists()) return;
      await for (final entity in directory.list()) {
        if (entity is! File || p.extension(entity.path) != '.json') continue;
        try {
          final decoded = jsonDecode(await entity.readAsString());
          if (decoded is Map<String, dynamic> &&
              decoded['key'] is String &&
              (decoded['key'] as String).startsWith(prefix)) {
            await entity.delete();
          }
        } on FormatException {
          await entity.delete();
        } on FileSystemException {
          // Cache invalidation is best effort if a file was concurrently removed.
        }
      }
    } on FileSystemException {
      // A cache directory failure must not turn a successful API mutation into
      // a user-visible failure.
    }
  }

  /// Clears this cache's memory entries and persisted JSON response files.
  Future<void> clear() async {
    _generation++;
    _inFlight.clear();
    clearMemory();
    final preferences = _preferences;
    if (preferences != null) await preferences.remove(_legacyStorageKey);
    if (!persist) return;
    try {
      final directory = await _directoryProvider();
      if (await directory.exists()) await directory.delete(recursive: true);
    } on FileSystemException {
      // Cache clearing is best effort when the OS has already removed files.
    }
  }

  /// Drops in-memory values without touching persistent files.
  void clearMemory() => _entries.clear();

  void _remember(String key, Object? value) {
    _entries.remove(key);
    _entries[key] = value;
    while (_entries.length > maxMemoryEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  Future<_PersistedResponse?> _readPersisted(String key) async {
    try {
      final directory = await _directoryProvider();
      final file = _fileForKey(directory, key);
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic> || decoded['key'] != key) {
        await file.delete();
        return null;
      }
      return _PersistedResponse(decoded['value']);
    } on FormatException {
      return null;
    } on FileSystemException {
      // Cache storage is optional; fall through to the network.
      return null;
    }
  }

  Future<void> _writePersisted(String key, Object? value) async {
    try {
      final directory = await _directoryProvider();
      await directory.create(recursive: true);
      final file = _fileForKey(directory, key);
      final temporaryFile = File('${file.path}.tmp');
      await temporaryFile.writeAsString(
        jsonEncode({'key': key, 'value': value}),
        flush: true,
      );
      if (await file.exists()) await file.delete();
      await temporaryFile.rename(file.path);
    } on JsonUnsupportedObjectError {
      // Only JSON-compatible responses can be persisted.
    } on FileSystemException {
      // Preserve the in-memory response if external cache storage is full.
    }
  }

  File _fileForKey(Directory directory, String key) {
    final digest = sha256.convert(utf8.encode(key));
    return File(p.join(directory.path, '$digest.json'));
  }
}

class _PersistedResponse {
  const _PersistedResponse(this.value);

  final Object? value;
}
