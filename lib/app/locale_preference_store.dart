import 'package:shared_preferences/shared_preferences.dart';

/// Loads and saves the user's app language selection.
abstract interface class LocalePreferenceStore {
  Future<String?> read();

  Future<void> write(String value);
}

/// Shared preferences implementation for [LocalePreferenceStore].
class SharedPreferencesLocalePreferenceStore implements LocalePreferenceStore {
  SharedPreferencesLocalePreferenceStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const key = 'app_locale_preference';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(key);

  @override
  Future<void> write(String value) => _preferences.setString(key, value);
}
