import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/emby_library_preferences.dart';

abstract interface class EmbyLibraryPreferencesStore {
  Future<EmbyLibraryPreferences> read(String serverId);

  Future<void> write(String serverId, EmbyLibraryPreferences preferences);
}

class SharedPreferencesEmbyLibraryPreferencesStore
    implements EmbyLibraryPreferencesStore {
  SharedPreferencesEmbyLibraryPreferencesStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const _keyPrefix = 'emby_library_preferences_';

  final SharedPreferencesAsync _preferences;

  @override
  Future<EmbyLibraryPreferences> read(String serverId) async {
    final encoded = await _preferences.getString('$_keyPrefix$serverId');
    if (encoded == null) return const EmbyLibraryPreferences();
    try {
      final value = jsonDecode(encoded);
      if (value is Map<String, dynamic>) {
        return EmbyLibraryPreferences.fromJson(value);
      }
    } on FormatException {
      // Ignore malformed preferences and use defaults.
    }
    return const EmbyLibraryPreferences();
  }

  @override
  Future<void> write(String serverId, EmbyLibraryPreferences preferences) =>
      _preferences.setString(
        '$_keyPrefix$serverId',
        jsonEncode(preferences.toJson()),
      );
}
