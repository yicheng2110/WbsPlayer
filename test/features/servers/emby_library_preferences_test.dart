import 'package:flutter_test/flutter_test.dart';
import 'package:wbs_player/features/servers/models/emby_library_preferences.dart';

void main() {
  test(
    'normalizes order by retaining saved IDs and appending new libraries',
    () {
      const preferences = EmbyLibraryPreferences(
        order: ['c', 'removed', 'a'],
        hiddenLibraryIds: {'a', 'removed'},
      );

      final normalized = preferences.normalize(['a', 'b', 'c']);

      expect(normalized.order, ['c', 'a', 'b']);
      expect(normalized.hiddenLibraryIds, {'a'});
    },
  );

  test('reorders libraries and tracks home visibility independently', () {
    final preferences = const EmbyLibraryPreferences(order: ['c', 'a', 'b'])
        .reorder(0, 3)
        .setVisible('a', false);

    expect(preferences.order, ['a', 'b', 'c']);
    expect(preferences.isVisibleOnHome('a'), isFalse);
    expect(preferences.isVisibleOnHome('b'), isTrue);
    expect(preferences.visibleLibraryIds, ['b', 'c']);
    expect(preferences.toJson(), {
      'order': ['a', 'b', 'c'],
      'hiddenLibraryIds': ['a'],
    });
  });

  test('round trips JSON preferences', () {
    const preferences = EmbyLibraryPreferences(
      order: ['a', 'b'],
      hiddenLibraryIds: {'b'},
    );

    expect(
      EmbyLibraryPreferences.fromJson(preferences.toJson()).order,
      preferences.order,
    );
    expect(
      EmbyLibraryPreferences.fromJson(preferences.toJson()).hiddenLibraryIds,
      preferences.hiddenLibraryIds,
    );
  });
}
