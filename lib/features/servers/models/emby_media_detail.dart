/// Immutable, defensive DTOs for the standalone Emby detail module.
///
/// Optional values with incompatible types are ignored. Numeric strings and
/// numeric IDs, which occur on some Emby-compatible servers, are accepted.
class EmbyMediaDetail {
  EmbyMediaDetail({
    required this.id,
    required this.name,
    required this.type,
    this.overview,
    this.originalTitle,
    this.seriesName,
    this.seriesId,
    this.seasonId,
    this.seasonName,
    this.seasonNumber,
    this.episodeNumber,
    this.productionYear,
    this.communityRating,
    this.criticRating,
    this.officialRating,
    this.premiereDate,
    this.runTimeTicks,
    this.datePlayed,
    this.playCount = 0,
    this.isPlayed = false,
    this.playbackPositionTicks = 0,
    this.isFavorite = false,
    this.isFolder = false,
    Iterable<String> genres = const [],
    Iterable<EmbyMediaStudio> studios = const [],
    Iterable<EmbyMediaPerson> people = const [],
    Iterable<EmbyExternalLink> externalLinks = const [],
    Iterable<EmbyMediaSource> mediaSources = const [],
    Iterable<EmbyMediaDetailImage> images = const [],
  }) : genres = List.unmodifiable(genres),
       studios = List.unmodifiable(studios),
       people = List.unmodifiable(people),
       externalLinks = List.unmodifiable(externalLinks),
       mediaSources = List.unmodifiable(mediaSources),
       images = List.unmodifiable(images);

  final String id;
  final String name;
  final String type;
  final String? overview;
  final String? originalTitle;
  final String? seriesName;
  final String? seriesId;
  final String? seasonId;
  final String? seasonName;
  final int? seasonNumber;
  final int? episodeNumber;
  final int? productionYear;
  final double? communityRating;
  final double? criticRating;
  final String? officialRating;
  final DateTime? premiereDate;
  final int? runTimeTicks;
  final DateTime? datePlayed;
  final int playCount;
  final bool isPlayed;
  final int playbackPositionTicks;
  final bool isFavorite;
  final bool isFolder;
  final List<String> genres;
  final List<EmbyMediaStudio> studios;
  final List<EmbyMediaPerson> people;
  final List<EmbyExternalLink> externalLinks;
  final List<EmbyMediaSource> mediaSources;
  final List<EmbyMediaDetailImage> images;

  factory EmbyMediaDetail.fromJson(Map<String, dynamic> json) {
    final id = _id(json['Id']) ?? '';
    final userData = _map(json['UserData']);
    return EmbyMediaDetail(
      id: id,
      name: _text(json['Name']) ?? '',
      type: _text(json['Type']) ?? '',
      overview: _text(json['Overview']),
      originalTitle: _text(json['OriginalTitle']),
      seriesName: _text(json['SeriesName']),
      seriesId: _id(json['SeriesId']),
      seasonId: _id(json['SeasonId']),
      seasonName: _text(json['SeasonName']),
      seasonNumber: _nonNegativeInt(json['ParentIndexNumber']),
      episodeNumber: _nonNegativeInt(json['IndexNumber']),
      productionYear: _positiveInt(json['ProductionYear']),
      communityRating: _number(json['CommunityRating']),
      criticRating: _number(json['CriticRating']),
      officialRating: _text(json['OfficialRating']),
      premiereDate: DateTime.tryParse(_text(json['PremiereDate']) ?? ''),
      runTimeTicks: _positiveInt(json['RunTimeTicks']),
      datePlayed: DateTime.tryParse(
        _text(userData['LastPlayedDate'] ?? json['DatePlayed']) ?? '',
      ),
      playCount: _nonNegativeInt(userData['PlayCount']) ?? 0,
      isPlayed: _bool(userData['Played']) ?? false,
      playbackPositionTicks:
          _positiveInt(userData['PlaybackPositionTicks']) ?? 0,
      isFavorite: _bool(userData['IsFavorite']) ?? false,
      isFolder: _bool(json['IsFolder']) ?? false,
      genres: _strings(json['Genres']),
      studios: _objects(json['Studios'])
          .map(EmbyMediaStudio.fromJson)
          .where((studio) => studio.name.isNotEmpty),
      people: _objects(json['People'])
          .map(EmbyMediaPerson.fromJson)
          .where((person) => person.name.isNotEmpty),
      externalLinks: _objects(json['ExternalUrls'])
          .map(EmbyExternalLink.fromJson)
          .where((link) => link.uri != null),
      mediaSources: _objects(json['MediaSources'])
          .map(EmbyMediaSource.fromJson),
      images: _itemImages(json, id),
    );
  }

  Map<String, dynamic> toJson() => {
    'Id': id,
    'Name': name,
    'Type': type,
    'IsFolder': isFolder,
    if (overview != null) 'Overview': overview,
    if (originalTitle != null) 'OriginalTitle': originalTitle,
    if (seriesName != null) 'SeriesName': seriesName,
    if (seriesId != null) 'SeriesId': seriesId,
    if (seasonId != null) 'SeasonId': seasonId,
    if (seasonName != null) 'SeasonName': seasonName,
    if (seasonNumber != null) 'ParentIndexNumber': seasonNumber,
    if (episodeNumber != null) 'IndexNumber': episodeNumber,
    if (productionYear != null) 'ProductionYear': productionYear,
    if (communityRating != null) 'CommunityRating': communityRating,
    if (criticRating != null) 'CriticRating': criticRating,
    if (officialRating != null) 'OfficialRating': officialRating,
    if (premiereDate != null) 'PremiereDate': premiereDate!.toIso8601String(),
    if (runTimeTicks != null) 'RunTimeTicks': runTimeTicks,
    'UserData': {
      'PlaybackPositionTicks': playbackPositionTicks,
      if (datePlayed != null) 'LastPlayedDate': datePlayed!.toIso8601String(),
      'PlayCount': playCount,
      'Played': isPlayed,
      'IsFavorite': isFavorite,
    },
    'Genres': genres,
    'Studios': studios.map((studio) => studio.toJson()).toList(),
    'People': people.map((person) => person.toJson()).toList(),
    'ExternalUrls': externalLinks.map((link) => link.toJson()).toList(),
    'MediaSources': mediaSources.map((source) => source.toJson()).toList(),
    'ImageTags': {
      for (final image in images)
        if (image.itemId == id && image.index == null && image.tag != null)
          image.type: image.tag,
    },
    'BackdropImageTags': _backdropTags(images, id),
    if (images.any(
      (image) => image.itemId != id && image.type == 'Backdrop',
    )) ...{
      'ParentBackdropItemId': images
          .firstWhere((image) => image.itemId != id && image.type == 'Backdrop')
          .itemId,
      'ParentBackdropImageTags': _backdropTags(
        images,
        images
            .firstWhere(
              (image) => image.itemId != id && image.type == 'Backdrop',
            )
            .itemId,
      ),
    },
  };
}

/// Additional endpoints may fail without making the item itself unreadable.
enum EmbyMediaDetailSection { similar, images, mediaSources, seasons }

class EmbyMediaDetailContent {
  EmbyMediaDetailContent({
    required this.detail,
    Iterable<EmbySimilarItem> similar = const [],
    Iterable<EmbyMediaSeason> seasons = const [],
    Iterable<EmbyMediaSource>? mediaSources,
    Iterable<EmbyMediaDetailImage>? images,
    Iterable<EmbyMediaDetailSection> failedSections = const [],
  }) : similar = List.unmodifiable(similar),
       seasons = List.unmodifiable(seasons),
       mediaSources = List.unmodifiable(mediaSources ?? detail.mediaSources),
       images = List.unmodifiable(images ?? detail.images),
       failedSections = Set.unmodifiable(failedSections);

  final EmbyMediaDetail detail;
  final List<EmbySimilarItem> similar;
  final List<EmbyMediaSeason> seasons;
  final List<EmbyMediaSource> mediaSources;
  final List<EmbyMediaDetailImage> images;
  final Set<EmbyMediaDetailSection> failedSections;
}

class EmbyMediaSeason {
  const EmbyMediaSeason({
    required this.id,
    required this.name,
    this.indexNumber,
    this.episodeCount,
    this.productionYear,
    this.primaryImageTag,
  });

  final String id;
  final String name;
  final int? indexNumber;
  final int? episodeCount;
  final int? productionYear;
  final String? primaryImageTag;

  factory EmbyMediaSeason.fromJson(Map<String, dynamic> json) =>
      EmbyMediaSeason(
        id: _id(json['Id']) ?? '',
        name: _text(json['Name']) ?? '',
        indexNumber: _nonNegativeInt(json['IndexNumber']),
        episodeCount: _nonNegativeInt(json['ChildCount']),
        productionYear: _positiveInt(json['ProductionYear']),
        primaryImageTag:
            _text(json['PrimaryImageTag']) ??
            _text(_map(json['ImageTags'])['Primary']),
      );
}

class EmbySimilarItem {
  const EmbySimilarItem({
    required this.id,
    required this.name,
    required this.type,
    this.productionYear,
    this.communityRating,
    this.primaryImageTag,
  });

  final String id;
  final String name;
  final String type;
  final int? productionYear;
  final double? communityRating;
  final String? primaryImageTag;

  factory EmbySimilarItem.fromJson(Map<String, dynamic> json) =>
      EmbySimilarItem(
        id: _id(json['Id']) ?? '',
        name: _text(json['Name']) ?? '',
        type: _text(json['Type']) ?? '',
        productionYear: _positiveInt(json['ProductionYear']),
        communityRating: _number(json['CommunityRating']),
        primaryImageTag:
            _text(_map(json['ImageTags'])['Primary']) ??
            _text(json['PrimaryImageTag']),
      );

  Map<String, dynamic> toJson() => {
    'Id': id,
    'Name': name,
    'Type': type,
    if (productionYear != null) 'ProductionYear': productionYear,
    if (communityRating != null) 'CommunityRating': communityRating,
    if (primaryImageTag != null) 'ImageTags': {'Primary': primaryImageTag},
  };
}

class EmbyMediaStudio {
  const EmbyMediaStudio({required this.name, this.id});

  final String name;
  final String? id;

  factory EmbyMediaStudio.fromJson(Map<String, dynamic> json) =>
      EmbyMediaStudio(name: _text(json['Name']) ?? '', id: _id(json['Id']));

  Map<String, dynamic> toJson() => {'Name': name, if (id != null) 'Id': id};
}

class EmbyMediaPerson {
  const EmbyMediaPerson({
    required this.name,
    this.id,
    this.role,
    this.type,
    this.primaryImageTag,
  });

  final String name;
  final String? id;
  final String? role;
  final String? type;
  final String? primaryImageTag;

  factory EmbyMediaPerson.fromJson(Map<String, dynamic> json) =>
      EmbyMediaPerson(
        name: _text(json['Name']) ?? '',
        id: _id(json['Id']),
        role: _text(json['Role']),
        type: _text(json['Type']),
        primaryImageTag:
            _text(json['PrimaryImageTag']) ??
            _text(_map(json['ImageTags'])['Primary']),
      );

  Map<String, dynamic> toJson() => {
    'Name': name,
    if (id != null) 'Id': id,
    if (role != null) 'Role': role,
    if (type != null) 'Type': type,
    if (primaryImageTag != null) 'PrimaryImageTag': primaryImageTag,
  };
}

/// Only HTTP(S) links without embedded credentials can leave this module.
class EmbyExternalLink {
  const EmbyExternalLink({required this.name, required this.url});

  final String name;
  final String url;

  Uri? get uri {
    final value = Uri.tryParse(url.trim());
    if (value == null ||
        !const ['http', 'https'].contains(value.scheme.toLowerCase()) ||
        value.host.isEmpty ||
        value.userInfo.isNotEmpty) {
      return null;
    }
    return value;
  }

  factory EmbyExternalLink.fromJson(Map<String, dynamic> json) =>
      EmbyExternalLink(
        name: _text(json['Name']) ?? '',
        url: _text(json['Url']) ?? '',
      );

  Map<String, dynamic> toJson() => {'Name': name, 'Url': url};
}

/// Image index is the actual Emby index, not the position in a filtered list.
class EmbyMediaDetailImage {
  const EmbyMediaDetailImage({
    required this.itemId,
    required this.type,
    this.index,
    this.tag,
    this.width,
    this.height,
  });

  final String itemId;
  final String type;
  final int? index;
  final String? tag;
  final int? width;
  final int? height;

  factory EmbyMediaDetailImage.fromJson(
    Map<String, dynamic> json, {
    required String itemId,
  }) => EmbyMediaDetailImage(
    itemId: itemId,
    type: _text(json['ImageType']) ?? '',
    index: _nonNegativeInt(json['ImageIndex']),
    tag: _text(json['ImageTag']),
    width: _positiveInt(json['Width']),
    height: _positiveInt(json['Height']),
  );

  Map<String, dynamic> toJson() => {
    'ImageType': type,
    if (index != null) 'ImageIndex': index,
    if (tag != null) 'ImageTag': tag,
    if (width != null) 'Width': width,
    if (height != null) 'Height': height,
  };
}

class EmbyMediaSource {
  EmbyMediaSource({
    required this.id,
    required this.name,
    this.container,
    this.size,
    this.bitrate,
    this.runTimeTicks,
    this.defaultAudioStreamIndex,
    this.defaultSubtitleStreamIndex,
    this.directStreamUrl,
    this.transcodingUrl,
    this.playSessionId,
    Map<String, String> requiredHttpHeaders = const {},
    this.addApiKeyToDirectStreamUrl,
    this.supportsDirectPlay,
    this.supportsDirectStream,
    this.supportsTranscoding,
    Iterable<EmbyMediaStream> mediaStreams = const [],
  }) : requiredHttpHeaders = Map.unmodifiable(requiredHttpHeaders),
       mediaStreams = List.unmodifiable(mediaStreams);

  final String id;
  final String name;
  final String? container;
  final int? size;
  final int? bitrate;
  final int? runTimeTicks;
  final int? defaultAudioStreamIndex;
  final int? defaultSubtitleStreamIndex;
  final String? directStreamUrl;
  final String? transcodingUrl;
  final String? playSessionId;
  final Map<String, String> requiredHttpHeaders;
  final bool? addApiKeyToDirectStreamUrl;
  final bool? supportsDirectPlay;
  final bool? supportsDirectStream;
  final bool? supportsTranscoding;
  final List<EmbyMediaStream> mediaStreams;

  List<EmbyMediaStream> get audioStreams => List.unmodifiable(
    mediaStreams.where((stream) => stream.type?.toLowerCase() == 'audio'),
  );

  factory EmbyMediaSource.fromJson(
    Map<String, dynamic> json,
  ) => EmbyMediaSource(
    id: _id(json['Id']) ?? '',
    name: _text(json['Name']) ?? '',
    container: _text(json['Container']),
    size: _positiveInt(json['Size']),
    bitrate: _positiveInt(json['Bitrate'] ?? json['BitRate']),
    runTimeTicks: _positiveInt(json['RunTimeTicks']),
    defaultAudioStreamIndex: _nonNegativeInt(json['DefaultAudioStreamIndex']),
    defaultSubtitleStreamIndex: _integer(json['DefaultSubtitleStreamIndex']),
    directStreamUrl: _text(json['DirectStreamUrl']),
    transcodingUrl: _text(json['TranscodingUrl']),
    playSessionId: _text(json['PlaySessionId']),
    requiredHttpHeaders: _stringMap(json['RequiredHttpHeaders']),
    addApiKeyToDirectStreamUrl: _bool(json['AddApiKeyToDirectStreamUrl']),
    supportsDirectPlay: _bool(json['SupportsDirectPlay']),
    supportsDirectStream: _bool(json['SupportsDirectStream']),
    supportsTranscoding: _bool(json['SupportsTranscoding']),
    mediaStreams: _objects(json['MediaStreams']).map(EmbyMediaStream.fromJson),
  );

  Map<String, dynamic> toJson() => {
    'Id': id,
    'Name': name,
    if (container != null) 'Container': container,
    if (size != null) 'Size': size,
    if (bitrate != null) 'Bitrate': bitrate,
    if (runTimeTicks != null) 'RunTimeTicks': runTimeTicks,
    if (defaultAudioStreamIndex != null)
      'DefaultAudioStreamIndex': defaultAudioStreamIndex,
    if (defaultSubtitleStreamIndex != null)
      'DefaultSubtitleStreamIndex': defaultSubtitleStreamIndex,
    if (directStreamUrl != null) 'DirectStreamUrl': directStreamUrl,
    if (transcodingUrl != null) 'TranscodingUrl': transcodingUrl,
    if (playSessionId != null) 'PlaySessionId': playSessionId,
    if (requiredHttpHeaders.isNotEmpty)
      'RequiredHttpHeaders': requiredHttpHeaders,
    if (addApiKeyToDirectStreamUrl != null)
      'AddApiKeyToDirectStreamUrl': addApiKeyToDirectStreamUrl,
    if (supportsDirectPlay != null) 'SupportsDirectPlay': supportsDirectPlay,
    if (supportsDirectStream != null)
      'SupportsDirectStream': supportsDirectStream,
    if (supportsTranscoding != null) 'SupportsTranscoding': supportsTranscoding,
    'MediaStreams': mediaStreams.map((stream) => stream.toJson()).toList(),
  };
}

class EmbyMediaStream {
  const EmbyMediaStream({
    this.index,
    this.type,
    this.codec,
    this.profile,
    this.language,
    this.title,
    this.displayTitle,
    this.channels,
    this.channelLayout,
    this.width,
    this.height,
    this.bitrate,
    this.sampleRate,
    this.bitDepth,
    this.frameRate,
    this.videoRange,
    this.colorSpace,
    this.colorTransfer,
    this.colorPrimaries,
    this.isDefault = false,
    this.isForced = false,
    this.isExternal = false,
  });

  final int? index;
  final String? type;
  final String? codec;
  final String? profile;
  final String? language;
  final String? title;
  final String? displayTitle;
  final int? channels;
  final String? channelLayout;
  final int? width;
  final int? height;
  final int? bitrate;
  final int? sampleRate;
  final int? bitDepth;
  final double? frameRate;
  final String? videoRange;
  final String? colorSpace;
  final String? colorTransfer;
  final String? colorPrimaries;
  final bool isDefault;
  final bool isForced;
  final bool isExternal;

  factory EmbyMediaStream.fromJson(Map<String, dynamic> json) =>
      EmbyMediaStream(
        index: _nonNegativeInt(json['Index']),
        type: _text(json['Type']),
        codec: _text(json['Codec']),
        profile: _text(json['Profile']),
        language: _text(json['Language']),
        title: _text(json['Title']),
        displayTitle: _text(json['DisplayTitle']),
        channels: _positiveInt(json['Channels']),
        channelLayout: _text(json['ChannelLayout']),
        width: _positiveInt(json['Width']),
        height: _positiveInt(json['Height']),
        bitrate: _positiveInt(json['BitRate'] ?? json['Bitrate']),
        sampleRate: _positiveInt(json['SampleRate']),
        bitDepth: _positiveInt(json['BitDepth']),
        frameRate: _number(json['AverageFrameRate'] ?? json['RealFrameRate']),
        videoRange: _text(json['VideoRange']) ?? _text(json['VideoRangeType']),
        colorSpace: _text(json['ColorSpace']),
        colorTransfer: _text(json['ColorTransfer']),
        colorPrimaries: _text(json['ColorPrimaries']),
        isDefault: _bool(json['IsDefault']) ?? false,
        isForced: _bool(json['IsForced']) ?? false,
        isExternal: _bool(json['IsExternal']) ?? false,
      );

  Map<String, dynamic> toJson() => {
    if (index != null) 'Index': index,
    if (type != null) 'Type': type,
    if (codec != null) 'Codec': codec,
    if (profile != null) 'Profile': profile,
    if (language != null) 'Language': language,
    if (title != null) 'Title': title,
    if (displayTitle != null) 'DisplayTitle': displayTitle,
    if (channels != null) 'Channels': channels,
    if (channelLayout != null) 'ChannelLayout': channelLayout,
    if (width != null) 'Width': width,
    if (height != null) 'Height': height,
    if (bitrate != null) 'BitRate': bitrate,
    if (sampleRate != null) 'SampleRate': sampleRate,
    if (bitDepth != null) 'BitDepth': bitDepth,
    if (frameRate != null) 'AverageFrameRate': frameRate,
    if (videoRange != null) 'VideoRange': videoRange,
    if (colorSpace != null) 'ColorSpace': colorSpace,
    if (colorTransfer != null) 'ColorTransfer': colorTransfer,
    if (colorPrimaries != null) 'ColorPrimaries': colorPrimaries,
    'IsDefault': isDefault,
    'IsForced': isForced,
    'IsExternal': isExternal,
  };
}

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

String? _id(Object? value) =>
    _text(value) ?? (value is int ? value.toString() : null);

int? _integer(Object? value) {
  if (value is int) return value;
  if (value is String) {
    final integer = int.tryParse(value.trim());
    if (integer != null) return integer;
  }
  final number = _number(value);
  if (number == null || number != number.roundToDouble()) return null;
  return number.toInt();
}

int? _positiveInt(Object? value) {
  final number = _integer(value);
  return number != null && number > 0 ? number : null;
}

int? _nonNegativeInt(Object? value) {
  final number = _integer(value);
  return number != null && number >= 0 ? number : null;
}

double? _number(Object? value) {
  final number = switch (value) {
    num value => value.toDouble(),
    String value => double.tryParse(value.trim()),
    _ => null,
  };
  return number != null && number.isFinite ? number : null;
}

bool? _bool(Object? value) => switch (value) {
  bool value => value,
  1 || '1' => true,
  0 || '0' => false,
  String value => switch (value.trim().toLowerCase()) {
    'true' => true,
    'false' => false,
    _ => null,
  },
  _ => null,
};

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return Map.unmodifiable({
    for (final entry in value.entries)
      if (entry.key is String && _text(entry.value) != null)
        entry.key as String: _text(entry.value)!,
  });
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}

Iterable<Map<String, dynamic>> _objects(Object? value) =>
    value is List ? value.whereType<Map>().map(_map) : const [];

Iterable<String> _strings(Object? value) =>
    value is List ? value.map(_text).whereType<String>() : const [];

List<EmbyMediaDetailImage> _itemImages(Map<String, dynamic> json, String id) {
  final images = <EmbyMediaDetailImage>[];
  for (final entry in _map(json['ImageTags']).entries) {
    final tag = _text(entry.value);
    if (tag == null || entry.key.isEmpty) continue;
    images.add(EmbyMediaDetailImage(itemId: id, type: entry.key, tag: tag));
  }
  final tags = json['BackdropImageTags'];
  if (tags is List) {
    for (var index = 0; index < tags.length; index++) {
      final tag = _text(tags[index]);
      if (tag != null) {
        images.add(
          EmbyMediaDetailImage(
            itemId: id,
            type: 'Backdrop',
            index: index,
            tag: tag,
          ),
        );
      }
    }
  }
  // Episodes can inherit artwork from a season or series.
  final parentId = _id(json['ParentBackdropItemId']);
  final parentTags = json['ParentBackdropImageTags'];
  if (!images.any((image) => image.type == 'Backdrop') &&
      parentId != null &&
      parentTags is List) {
    for (var index = 0; index < parentTags.length; index++) {
      final tag = _text(parentTags[index]);
      if (tag != null) {
        images.add(
          EmbyMediaDetailImage(
            itemId: parentId,
            type: 'Backdrop',
            index: index,
            tag: tag,
          ),
        );
      }
    }
  }
  return images;
}

List<String?> _backdropTags(List<EmbyMediaDetailImage> images, String itemId) {
  final indexed = images.where(
    (image) =>
        image.itemId == itemId &&
        image.type == 'Backdrop' &&
        image.index != null,
  );
  final tags = <String?>[];
  for (final image in indexed) {
    final index = image.index!;
    while (tags.length <= index) {
      tags.add(null);
    }
    tags[index] = image.tag;
  }
  return tags;
}
