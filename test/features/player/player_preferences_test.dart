import 'package:flutter_test/flutter_test.dart';
import 'package:wbs_player/features/player/models/player_preferences.dart';

void main() {
  group('PlayerPreferences cache settings', () {
    test('uses enabled 64 MB cache by default', () {
      const preferences = PlayerPreferences();

      expect(preferences.cacheEnabled, isTrue);
      expect(preferences.cacheSizeMb, PlayerPreferences.defaultCacheSizeMb);
    });

    test('reads cache settings and keeps legacy fields compatible', () {
      final preferences = PlayerPreferences.fromJson({
        'cacheEnabled': false,
        'cacheSizeMb': 128,
        'hardwareAcceleration': false,
      });

      expect(preferences.cacheEnabled, isFalse);
      expect(preferences.cacheSizeMb, 128);
      expect(preferences.hardwareAcceleration, isFalse);

      final legacy = PlayerPreferences.fromJson({});
      expect(legacy.cacheEnabled, isTrue);
      expect(legacy.cacheSizeMb, 64);
    });

    test('clamps cache size to an even value between 2 MB and 1 GB', () {
      expect(PlayerPreferences.normalizeCacheSizeMb(-1), 2);
      expect(PlayerPreferences.normalizeCacheSizeMb(3), 2);
      expect(PlayerPreferences.normalizeCacheSizeMb(65), 64);
      expect(PlayerPreferences.normalizeCacheSizeMb(1023), 1022);
      expect(PlayerPreferences.normalizeCacheSizeMb(2048), 1024);

      final preferences = const PlayerPreferences().copyWith(cacheSizeMb: 1025);
      expect(preferences.cacheSizeMb, 1024);
    });

    test('serializes cache settings', () {
      final preferences = const PlayerPreferences().copyWith(
        cacheEnabled: false,
        cacheSizeMb: 256,
      );

      expect(preferences.toJson(), containsPair('cacheEnabled', false));
      expect(preferences.toJson(), containsPair('cacheSizeMb', 256));
    });
  });
}
