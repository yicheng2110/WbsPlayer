import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_preferences.dart';

/// Persists the user's playback defaults independently from server media data.
abstract interface class PlayerPreferencesStore {
  Future<PlayerPreferences> read();

  Future<void> write(PlayerPreferences preferences);
}

/// Shared-preferences implementation of [PlayerPreferencesStore].
class SharedPreferencesPlayerPreferencesStore
    implements PlayerPreferencesStore {
  SharedPreferencesPlayerPreferencesStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const key = 'player_preferences';
  final SharedPreferencesAsync _preferences;

  @override
  Future<PlayerPreferences> read() async {
    final encoded = await _preferences.getString(key);
    if (encoded == null) return const PlayerPreferences();
    try {
      final json = jsonDecode(encoded);
      if (json is Map<String, dynamic>) {
        return PlayerPreferences.fromJson(json);
      }
    } on FormatException {
      // Ignore stale or malformed user preferences and use safe defaults.
    }
    return const PlayerPreferences();
  }

  @override
  Future<void> write(PlayerPreferences preferences) =>
      _preferences.setString(key, jsonEncode(preferences.toJson()));
}
