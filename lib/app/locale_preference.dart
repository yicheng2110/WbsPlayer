import 'package:flutter/material.dart';

/// The language choice exposed by the application settings.
enum LocalePreference {
  system,
  simplifiedChinese,
  english;

  /// The locale override for this choice, or null to follow the device.
  Locale? get locale => switch (this) {
    LocalePreference.system => null,
    LocalePreference.simplifiedChinese => const Locale('zh'),
    LocalePreference.english => const Locale('en'),
  };

  static LocalePreference fromStoredValue(String? value) => switch (value) {
    'system' => LocalePreference.system,
    'zh' => LocalePreference.simplifiedChinese,
    'en' => LocalePreference.english,
    _ => LocalePreference.system,
  };

  String get storedValue => switch (this) {
    LocalePreference.system => 'system',
    LocalePreference.simplifiedChinese => 'zh',
    LocalePreference.english => 'en',
  };
}
