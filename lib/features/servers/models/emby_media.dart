import 'emby_library_preferences.dart';

typedef EmbyMediaSelected = void Function(
  EmbyLibraryItem item, {
  required String userId,
  required String accessToken,
});

typedef EmbyLibrarySelected = void Function(
  EmbyLibrary library, {
  required String userId,
  required String accessToken,
});

typedef EmbyLibraryManagementSelected = Future<void> Function({
  required List<EmbyLibrary> libraries,
  required EmbyLibraryPreferences preferences,
});

class EmbyLibraryItem {
  const EmbyLibraryItem({
    required this.id,
    required this.name,
    required this.type,
    this.overview,
    this.productionYear,
    this.communityRating,
    this.primaryImageTag,
    this.backdropImageTag,
    this.playbackPositionTicks,
    this.runTimeTicks,
  });

  final String id;
  final String name;
  final String type;
  final String? overview;
  final int? productionYear;
  final double? communityRating;
  final String? primaryImageTag;
  final String? backdropImageTag;
  final int? playbackPositionTicks;
  final int? runTimeTicks;

  factory EmbyLibraryItem.fromJson(Map<String, dynamic> json) {
    final tags = json['ImageTags'];
    final userData = json['UserData'];
    final backdropTags = json['BackdropImageTags'];
    return EmbyLibraryItem(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      type: json['Type'] as String? ?? '',
      overview: json['Overview'] as String?,
      productionYear: json['ProductionYear'] as int?,
      communityRating: (json['CommunityRating'] as num?)?.toDouble(),
      primaryImageTag: tags is Map ? tags['Primary'] as String? : null,
      backdropImageTag: switch (backdropTags) {
        [final String first, ...] => first,
        _ => null,
      },
      playbackPositionTicks: userData is Map
          ? userData['PlaybackPositionTicks'] as int?
          : null,
      runTimeTicks: json['RunTimeTicks'] as int?,
    );
  }
}

class EmbyLibrary {
  const EmbyLibrary({
    required this.id,
    required this.name,
    this.collectionType,
  });

  final String id;
  final String name;
  final String? collectionType;

  factory EmbyLibrary.fromJson(Map<String, dynamic> json) => EmbyLibrary(
    id: json['Id'] as String? ?? '',
    name: json['Name'] as String? ?? '',
    collectionType: json['CollectionType'] as String?,
  );
}

class EmbyLibrarySection {
  const EmbyLibrarySection({required this.library, required this.items});

  final EmbyLibrary library;
  final List<EmbyLibraryItem> items;
}

class EmbyHomeContent {
  const EmbyHomeContent({
    required this.featured,
    required this.recentlyPlayed,
    required this.libraries,
  });

  final List<EmbyLibraryItem> featured;
  final List<EmbyLibraryItem> recentlyPlayed;
  final List<EmbyLibrarySection> libraries;
}
