import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wbs_player/features/servers/services/emby_api_response_cache.dart';

void main() {
  test('caches a successful response and bypasses it on refresh', () async {
    final cache = EmbyApiResponseCache();
    var calls = 0;

    Future<int> load() async => ++calls;

    expect(await cache.getOrLoad('item', load), 1);
    expect(await cache.getOrLoad('item', load), 1);
    expect(await cache.getOrLoad('item', load, forceRefresh: true), 2);
    expect(await cache.getOrLoad('item', load), 2);
    expect(calls, 2);
  });

  test(
    'does not cache failed requests and invalidates matching prefixes',
    () async {
      final cache = EmbyApiResponseCache();
      var calls = 0;

      Future<int> load() async {
        calls++;
        if (calls == 1) throw StateError('request failed');
        return calls;
      }

      await expectLater(cache.getOrLoad('server|item', load), throwsStateError);
      expect(await cache.getOrLoad('server|item', load), 2);
      await cache.getOrLoad('server|other', () async => 3);
      cache.invalidatePrefix('server|item');
      expect(await cache.getOrLoad('server|item', load), 3);
      expect(await cache.getOrLoad('server|other', () async => 5), 3);
    },
  );

  test('persists JSON responses between cache instances', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final firstCache = EmbyApiResponseCache(
      persist: true,
      preferences: preferences,
    );
    await firstCache.getOrLoad<Map<String, Object?>>(
      'persisted',
      () async => {'id': 'cached-item'},
    );
    await Future<void>.delayed(Duration.zero);

    final secondCache = EmbyApiResponseCache(
      persist: true,
      preferences: preferences,
    );
    var calls = 0;
    final value = await secondCache.getOrLoad<Map<String, dynamic>>(
      'persisted',
      () async {
        calls++;
        return {'id': 'fresh-item'};
      },
    );

    expect(value['id'], 'cached-item');
    expect(calls, 0);
  });

  test('coalesces concurrent requests with the same key', () async {
    final cache = EmbyApiResponseCache();
    var calls = 0;
    final completer = Completer<String>();

    Future<String> load() {
      calls++;
      return completer.future;
    }

    final first = cache.getOrLoad('same', load);
    final second = cache.getOrLoad('same', load);
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    completer.complete('result');
    expect(await first, 'result');
    expect(await second, 'result');
  });
}
