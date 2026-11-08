class EmbyLibraryPreferences {
  const EmbyLibraryPreferences({
    this.order = const [],
    this.hiddenLibraryIds = const {},
  });

  final List<String> order;
  final Set<String> hiddenLibraryIds;

  bool isVisibleOnHome(String libraryId) =>
      !hiddenLibraryIds.contains(libraryId);

  List<String> get visibleLibraryIds =>
      order.where(isVisibleOnHome).toList(growable: false);

  EmbyLibraryPreferences normalize(Iterable<String> libraryIds) {
    final currentIds = libraryIds.toSet();
    final normalizedOrder = <String>[
      for (final id in order)
        if (currentIds.remove(id)) id,
      ...currentIds,
    ];
    return EmbyLibraryPreferences(
      order: normalizedOrder,
      hiddenLibraryIds: hiddenLibraryIds.intersection(normalizedOrder.toSet()),
    );
  }

  EmbyLibraryPreferences reorder(int oldIndex, int newIndex) {
    final reordered = [...order];
    var destination = newIndex;
    if (destination > oldIndex) destination--;
    final libraryId = reordered.removeAt(oldIndex);
    reordered.insert(destination, libraryId);
    return EmbyLibraryPreferences(
      order: reordered,
      hiddenLibraryIds: hiddenLibraryIds,
    );
  }

  EmbyLibraryPreferences setVisible(String libraryId, bool visible) {
    final hidden = {...hiddenLibraryIds};
    if (visible) {
      hidden.remove(libraryId);
    } else {
      hidden.add(libraryId);
    }
    return EmbyLibraryPreferences(order: order, hiddenLibraryIds: hidden);
  }

  factory EmbyLibraryPreferences.fromJson(Map<String, dynamic> json) {
    final rawOrder = json['order'];
    final rawHiddenIds = json['hiddenLibraryIds'];
    return EmbyLibraryPreferences(
      order: rawOrder is List
          ? rawOrder.whereType<String>().toList()
          : const [],
      hiddenLibraryIds: rawHiddenIds is List
          ? rawHiddenIds.whereType<String>().toSet()
          : const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'order': order,
    'hiddenLibraryIds': hiddenLibraryIds.toList(),
  };
}
