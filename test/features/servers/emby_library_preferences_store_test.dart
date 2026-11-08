import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wbs_player/features/servers/models/emby_library_preferences.dart';
import 'package:wbs_player/features/servers/services/emby_library_preferences_store.dart';

void main() {
  test('persists preferences separately for each server', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final store = SharedPreferencesEmbyLibraryPreferencesStore();
    const first = EmbyLibraryPreferences(
      order: ['b', 'a'],
      hiddenLibraryIds: {'a'},
    );
    const second = EmbyLibraryPreferences(order: ['x', 'y']);

    await store.write('server-1', first);
    await store.write('server-2', second);

    expect((await store.read('server-1')).order, first.order);
    expect(
      (await store.read('server-1')).hiddenLibraryIds,
      first.hiddenLibraryIds,
    );
    expect((await store.read('server-2')).order, second.order);
  });
}
