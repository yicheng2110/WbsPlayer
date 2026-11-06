import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Bounded, short-lived cache for successful Emby API responses.
///
/// Cached API payloads are stored locally without authentication tokens. The
/// default shared instance persists JSON responses between app launches. Tests
/// or callers can pass a preferences instance or leave persistence disabled.
class EmbyApiResponseCache {
  EmbyApiResponseCache({
    this.maxAge = const Duration(minutes: 5),
    this.maxEntries = 256,
    SharedPreferences? preferences,
    bool persist = false,
  }) : _preferences = preferences,
       _persist = persist,
       assert(maxAge > Duration.zero),
       assert(maxEntries > 0);

  /// Process-wide cache shared by Emby services and detail-page instances.
  static final shared = EmbyApiResponseCache(persist: true);

  static const _storageKey = 'emby_api_response_cache_v1';

  final Duration maxAge;
  final int maxEntries;
  final bool _persist;
  SharedPreferences? _preferences;
  final Map<String, _CacheEntry> _entries = {};
  final Map<String, Future<Object?>> _inFlight = {};
  Future<void>? _loadFuture;
  Future<void> _persistQueue = Future<void>.value();

  /// Returns a cached value, or loads and caches the successful response.
  /// Concurrent requests for the same key share the same in-flight request.
  Future<T> getOrLoad<T>(
    String key,
    Future<T> Function() load, {
    bool forceRefresh = false,
    bool persistValue = true,
  }) async {
    await _ensureLoaded();
    final now = DateTime.now();
    final entry = _entries.remove(key);
    if (!forceRefresh && entry != null && now.isBefore(entry.expiresAt)) {
      _entries[key] = entry;
      return entry.value as T;
    }

    final pending = _inFlight[key];
    if (pending != null) return await pending as T;

    final request = Future<T>.sync(load);
    _inFlight[key] = request;
    try {
      final value = await request;
      _entries.remove(key);
      _entries[key] = _CacheEntry(
        value,
        DateTime.now().add(maxAge),
        persistValue: persistValue,
      );
      while (_entries.length > maxEntries) {
        _entries.remove(_entries.keys.first);
      }
      _schedulePersist();
      return value;
    } finally {
      if (identical(_inFlight[key], request)) _inFlight.remove(key);
    }
  }

  /// Removes cached entries whose keys start with [prefix].
  void invalidatePrefix(String prefix) {
    _entries.removeWhere((key, _) => key.startsWith(prefix));
    _schedulePersist();
  }

  /// Clears all cached responses.
  void clear() {
    _entries.clear();
    _schedulePersist();
  }

  Future<void> _ensureLoaded() => _loadFuture ??= _loadPersisted();

  Future<void> _loadPersisted() async {
    if (!_persist) return;
    try {
      final preferences = await _getPreferences();
      final raw = preferences.getString(_storageKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final now = DateTime.now();
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue;
        final expiresAt = value['expiresAt'];
        if (expiresAt is! int || expiresAt <= now.millisecondsSinceEpoch) {
          continue;
        }
        _entries[entry.key] = _CacheEntry(
          value['value'],
          DateTime.fromMillisecondsSinceEpoch(expiresAt),
        );
      }
      while (_entries.length > maxEntries) {
        _entries.remove(_entries.keys.first);
      }
    } catch (_) {
      // A corrupt or unavailable cache should never block API requests.
      _entries.clear();
    }
  }

  void _schedulePersist() {
    if (!_persist) return;
    _persistQueue = _persistQueue
        .then((_) async {
          try {
            final preferences = await _getPreferences();
            final values = <String, Object?>{};
            for (final entry in _entries.entries) {
              if (!entry.value.persistValue) continue;
              try {
                // PlaybackInfo-derived models may be cached in memory only.
                jsonEncode(entry.value.value);
                values[entry.key] = {
                  'expiresAt': entry.value.expiresAt.millisecondsSinceEpoch,
                  'value': entry.value.value,
                };
              } on JsonUnsupportedObjectError {
                continue;
              }
            }
            await preferences.setString(_storageKey, jsonEncode(values));
          } catch (_) {
            // Persistence is best-effort; memory caching remains available.
          }
        })
        .catchError((Object _) {});
  }

  Future<SharedPreferences> _getPreferences() async =>
      _preferences ??= await SharedPreferences.getInstance();
}

class _CacheEntry {
  const _CacheEntry(this.value, this.expiresAt, {this.persistValue = true});

  final Object? value;
  final DateTime expiresAt;
  final bool persistValue;
}
