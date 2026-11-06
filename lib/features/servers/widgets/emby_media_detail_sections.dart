import 'package:flutter/material.dart';

import '../../../ui/core/app_colors.dart';
import '../models/emby_media_detail.dart';
import '../models/emby_server.dart';
import '../services/emby_library_service.dart';

/// Resolves a detail localization key from the host application's l10n object.
///
/// The module deliberately adds no ARB or generated localization files. Until
/// the host provides a key, its stable key is shown as a visible placeholder.
typedef EmbyMediaDetailText = String Function(String key);

typedef EmbyMediaPlaybackDelegate = Future<void> Function({
  required EmbyMediaDetail detail,
  required EmbyMediaSource mediaSource,
  EmbyMediaStream? audioStream,
});

String embyMediaDetailText(EmbyMediaDetailText? text, String key) {
  final value = text?.call(key);
  return value == null || value.isEmpty ? key : value;
}

class EmbyMediaDetailHero extends StatelessWidget {
  const EmbyMediaDetailHero({
    super.key,
    required this.detail,
    required this.mediaSources,
    required this.images,
    required this.server,
    required this.libraryService,
    required this.selectedSourcePosition,
    required this.selectedAudioPosition,
    required this.onSourceChanged,
    required this.onAudioChanged,
    required this.onPlay,
    this.playbackDelegate,
    this.text,
  });

  final EmbyMediaDetail detail;
  final List<EmbyMediaSource> mediaSources;
  final List<EmbyMediaDetailImage> images;
  final EmbyServer server;
  final EmbyLibraryService libraryService;
  final int? selectedSourcePosition;
  final int? selectedAudioPosition;
  final ValueChanged<int> onSourceChanged;
  final ValueChanged<int> onAudioChanged;
  final VoidCallback onPlay;
  final EmbyMediaPlaybackDelegate? playbackDelegate;
  final EmbyMediaDetailText? text;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 760;
      if (isWide) {
        return SizedBox(
          height: 560,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _backdrop(),
              const _HeroGradient(),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(44, 86, 44, 34),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _Poster(
                          detail: detail,
                          server: server,
                          libraryService: libraryService,
                          width: 276,
                        ),
                        const SizedBox(width: 36),
                        Expanded(child: _description(context, wide: true)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 286,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _backdrop(),
                const _HeroGradient(),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 54, 20, 22),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _Poster(
                          detail: detail,
                          server: server,
                          libraryService: libraryService,
                          width: 132,
                        ),
                        const SizedBox(width: 17),
                        Expanded(child: _compactMetadata(context)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: const Color(0xFFFFD9C6),
            padding: const EdgeInsets.fromLTRB(21, 23, 21, 27),
            child: _description(context, wide: false),
          ),
        ],
      );
    },
  );

  Widget _backdrop() {
    final image = _preferredBackdrop(images, detail.id);
    if (image == null) return const ColoredBox(color: Color(0xFFFFD9C6));
    return _networkImage(
      _imageUri(image),
      fit: BoxFit.cover,
      fallback: const ColoredBox(color: Color(0xFFFFD9C6)),
    );
  }

  Widget _compactMetadata(BuildContext context) {
    final facts = _facts(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.name,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.mediaInk,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 9),
        if (detail.communityRating != null) ...[
          _Rating(rating: detail.communityRating!),
          const SizedBox(height: 8),
        ],
        Text(
          facts.join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.mediaMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _description(BuildContext context, {required bool wide}) {
    final source = _selectedSource;
    final audioStreams = source?.audioStreams ?? const <EmbyMediaStream>[];
    final overview = detail.overview?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (wide)
          Text(
            detail.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.mediaInk,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (detail.communityRating != null)
              _Rating(rating: detail.communityRating!),
            if (detail.criticRating != null)
              _FactChip('RT ${detail.criticRating!.toStringAsFixed(0)}%'),
            if (detail.premiereDate case final premiereDate?)
              _FactChip(
                '${premiereDate.year}-${premiereDate.month.toString().padLeft(2, '0')}-${premiereDate.day.toString().padLeft(2, '0')}',
              ),
            if (detail.productionYear != null)
              _FactChip('${detail.productionYear}'),
            if (detail.officialRating != null)
              _FactChip(detail.officialRating!),
            if (detail.type.isNotEmpty) _FactChip(detail.type),
            for (final genre in detail.genres.take(4)) _FactChip(genre),
          ],
        ),
        const SizedBox(height: 13),
        Text(
          overview == null || overview.isEmpty
              ? embyMediaDetailText(text, 'mediaDetailNoOverview')
              : overview,
          maxLines: wide ? 5 : 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.mediaMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        if (mediaSources.isNotEmpty || audioStreams.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              if (mediaSources.isNotEmpty)
                _choice<int>(
                  label: embyMediaDetailText(text, 'mediaDetailChooseVersion'),
                  value: selectedSourcePosition,
                  options: List.generate(mediaSources.length, (index) => index),
                  title: (index) => mediaSources[index].name.isEmpty
                      ? embyMediaDetailText(text, 'mediaDetailUnknownVersion')
                      : mediaSources[index].name,
                  onSelected: onSourceChanged,
                ),
              if (audioStreams.isNotEmpty)
                _choice<int>(
                  label: embyMediaDetailText(text, 'mediaDetailChooseAudio'),
                  value: selectedAudioPosition,
                  options: List.generate(audioStreams.length, (index) => index),
                  title: (index) => _audioTitle(audioStreams[index]),
                  onSelected: onAudioChanged,
                ),
            ],
          ),
        ],
        const SizedBox(height: 17),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: playbackDelegate == null || source == null
                  ? null
                  : onPlay,
              icon: Icon(
                playbackDelegate == null || source == null
                    ? Icons.info_outline
                    : Icons.play_arrow_rounded,
              ),
              label: Text(
                embyMediaDetailText(
                  text,
                  playbackDelegate == null
                      ? 'mediaDetailPlaybackUnavailable'
                      : source == null
                      ? 'mediaDetailNoStreams'
                      : 'mediaDetailPlay',
                ),
              ),
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.mediaAccent,
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white70,
                minimumSize: const Size(136, 48),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _choice<T>({
    required String label,
    required T? value,
    required List<T> options,
    required String Function(T value) title,
    required ValueChanged<T> onSelected,
  }) => PopupMenuButton<T>(
    tooltip: label,
    onSelected: onSelected,
    itemBuilder: (context) => options
        .map(
          (option) =>
              PopupMenuItem<T>(value: option, child: Text(title(option))),
        )
        .toList(growable: false),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mediaAccent.withValues(alpha: 0.10),
        border: Border.all(
          color: AppColors.mediaAccent.withValues(alpha: 0.24),
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ${value == null ? '-' : title(value)}',
              style: const TextStyle(color: AppColors.mediaInk, fontSize: 13),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.expand_more, color: Colors.white70, size: 17),
          ],
        ),
      ),
    ),
  );

  EmbyMediaSource? get _selectedSource {
    final position = selectedSourcePosition;
    return position == null || position < 0 || position >= mediaSources.length
        ? null
        : mediaSources[position];
  }

  List<String> _facts(BuildContext context) => [
    if (detail.productionYear != null) '${detail.productionYear}',
    if (detail.type.isNotEmpty) detail.type,
    if (detail.officialRating != null) detail.officialRating!,
    if (detail.runTimeTicks != null && detail.runTimeTicks! > 0)
      _formatDuration(context, detail.runTimeTicks!),
  ];

  String _audioTitle(EmbyMediaStream stream) {
    final title =
        stream.displayTitle ??
        stream.title ??
        [
          stream.language,
          stream.codec,
          stream.channelLayout,
        ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    return title.isEmpty
        ? embyMediaDetailText(text, 'mediaDetailUnknownAudio')
        : title;
  }

  Uri _imageUri(EmbyMediaDetailImage image) => embyMediaDetailImageUri(
    libraryService: libraryService,
    server: server,
    image: image,
    maxWidth: 1600,
  );

  Widget _networkImage(Uri uri, {required BoxFit fit, Widget? fallback}) =>
      Image.network(
        uri.toString(),
        headers: {'X-Emby-Token': server.accessToken},
        fit: fit,
        filterQuality: FilterQuality.medium,
        frameBuilder: (context, child, frame, sync) => sync || frame != null
            ? child
            : (fallback ?? const _ImageFallback()),
        errorBuilder: (_, _, _) => fallback ?? const _ImageFallback(),
      );

  String _formatDuration(BuildContext context, int ticks) {
    final minutes = ticks ~/ 10000000 ~/ 60;
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) {
      return embyMediaDetailText(
        text,
        'mediaDetailDurationMinutes',
      ).replaceAll('{minutes}', '$remainder');
    }
    return embyMediaDetailText(
      text,
      'mediaDetailDurationHoursMinutes',
    ).replaceAll('{hours}', '$hours').replaceAll('{minutes}', '$remainder');
  }
}

class EmbyMediaDetailSections extends StatelessWidget {
  const EmbyMediaDetailSections({
    super.key,
    required this.detail,
    required this.similar,
    required this.mediaSources,
    required this.images,
    required this.server,
    required this.libraryService,
    this.text,
    this.onSimilarTap,
    this.onExternalLinkTap,
  });

  final EmbyMediaDetail detail;
  final List<EmbySimilarItem> similar;
  final List<EmbyMediaSource> mediaSources;
  final List<EmbyMediaDetailImage> images;
  final EmbyServer server;
  final EmbyLibraryService libraryService;
  final EmbyMediaDetailText? text;
  final ValueChanged<EmbySimilarItem>? onSimilarTap;
  final ValueChanged<EmbyExternalLink>? onExternalLinkTap;

  @override
  Widget build(BuildContext context) {
    final actors = detail.people.where(_isActor).toList(growable: false);
    final crew = detail.people
        .where((person) => !_isActor(person))
        .toList(growable: false);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(context, 'mediaDetailCast'),
              if (actors.isNotEmpty)
                _ActorsRail(
                  actors: actors,
                  server: server,
                  libraryService: libraryService,
                )
              else
                _empty(context, 'mediaDetailNoPeople'),
              if (crew.isNotEmpty) _CrewLine(people: crew, text: text),
              _sectionTitle(context, 'mediaDetailPhotos'),
              _ImageRail(
                images: images,
                server: server,
                libraryService: libraryService,
                text: text,
              ),
              _sectionTitle(context, 'mediaDetailSimilar'),
              if (similar.isEmpty)
                _empty(context, 'mediaDetailNoSimilar')
              else
                _SimilarRail(
                  items: similar,
                  server: server,
                  libraryService: libraryService,
                  onTap: onSimilarTap,
                ),
              _sectionTitle(context, 'mediaDetailStudios'),
              if (detail.studios.isEmpty)
                _empty(context, 'mediaDetailNoStudio')
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: detail.studios
                        .map((studio) => _Tag(studio.name))
                        .toList(growable: false),
                  ),
                ),
              _sectionTitle(context, 'mediaDetailExternalLinks'),
              if (detail.externalLinks.isEmpty)
                _empty(context, 'mediaDetailNoExternalLinks')
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: detail.externalLinks
                        .map(
                          (link) => ActionChip(
                            avatar: const Icon(Icons.open_in_new, size: 16),
                            label: Text(link.name),
                            onPressed:
                                link.uri == null || onExternalLinkTap == null
                                ? null
                                : () => onExternalLinkTap!(link),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              _sectionTitle(context, 'mediaDetailTechnicalInfo'),
              _TechnicalInfo(sources: mediaSources, text: text),
            ],
          ),
        ),
      ),
    );
  }

  bool _isActor(EmbyMediaPerson person) => switch (person.type?.toLowerCase()) {
    'actor' || 'gueststar' => true,
    _ => false,
  };

  Widget _sectionTitle(BuildContext context, String key) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 27, 22, 12),
    child: Text(
      embyMediaDetailText(text, key),
      style: const TextStyle(
        color: AppColors.mediaInk,
        fontSize: 21,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _empty(BuildContext context, String key) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
    child: Text(
      embyMediaDetailText(text, key),
      style: const TextStyle(color: AppColors.mediaMuted, fontSize: 13),
    ),
  );
}

class _ActorsRail extends StatelessWidget {
  const _ActorsRail({
    required this.actors,
    required this.server,
    required this.libraryService,
  });

  final List<EmbyMediaPerson> actors;
  final EmbyServer server;
  final EmbyLibraryService libraryService;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 187,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      scrollDirection: Axis.horizontal,
      itemCount: actors.length,
      separatorBuilder: (_, _) => const SizedBox(width: 13),
      itemBuilder: (context, index) {
        final person = actors[index];
        return SizedBox(
          width: 108,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: SizedBox(
                  width: 108,
                  height: 132,
                  child: _personImage(person),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                person.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.mediaInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (person.role != null)
                Text(
                  person.role!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mediaMuted,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );

  Widget _personImage(EmbyMediaPerson person) {
    final id = person.id;
    final tag = person.primaryImageTag;
    if (id == null || tag == null) return const _ImageFallback();
    final uri = libraryService.imageUri(
      serverAddress: server.address,
      itemId: id,
      imageType: 'Primary',
      imageTag: tag,
      maxWidth: 280,
    );
    return Image.network(
      uri.toString(),
      headers: {'X-Emby-Token': server.accessToken},
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _ImageFallback(),
    );
  }
}

class _CrewLine extends StatelessWidget {
  const _CrewLine({required this.people, this.text});

  final List<EmbyMediaPerson> people;
  final EmbyMediaDetailText? text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
    child: Wrap(
      spacing: 17,
      runSpacing: 8,
      children: people
          .map((person) {
            final type = person.type?.toLowerCase();
            final roleKey = switch (type) {
              'director' => 'mediaDetailDirector',
              'writer' => 'mediaDetailWriter',
              _ => 'mediaDetailCrew',
            };
            return Text(
              '${embyMediaDetailText(text, roleKey)}: ${person.name}',
              style: const TextStyle(color: AppColors.mediaMuted, fontSize: 13),
            );
          })
          .toList(growable: false),
    ),
  );
}

class _ImageRail extends StatelessWidget {
  const _ImageRail({
    required this.images,
    required this.server,
    required this.libraryService,
    this.text,
  });

  final List<EmbyMediaDetailImage> images;
  final EmbyServer server;
  final EmbyLibraryService libraryService;
  final EmbyMediaDetailText? text;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Text(embyMediaDetailText(text, 'mediaDetailNoImages')),
      );
    }
    return SizedBox(
      height: 154,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final image = images[index];
          final width = image.type == 'Primary' ? 103.0 : 234.0;
          final uri = _imageUri(image);
          return ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: width,
              child: Image.network(
                uri.toString(),
                headers: {'X-Emby-Token': server.accessToken},
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ImageFallback(),
              ),
            ),
          );
        },
      ),
    );
  }

  Uri _imageUri(EmbyMediaDetailImage image) => embyMediaDetailImageUri(
    libraryService: libraryService,
    server: server,
    image: image,
    maxWidth: 780,
  );
}

class _SimilarRail extends StatelessWidget {
  const _SimilarRail({
    required this.items,
    required this.server,
    required this.libraryService,
    this.onTap,
  });

  final List<EmbySimilarItem> items;
  final EmbyServer server;
  final EmbyLibraryService libraryService;
  final ValueChanged<EmbySimilarItem>? onTap;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width / 4).clamp(128.0, 208.0);
    return SizedBox(
      height: width * 1.48 + 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final uri = libraryService.imageUri(
            serverAddress: server.address,
            itemId: item.id,
            imageTag: item.primaryImageTag,
            maxWidth: 500,
          );
          return SizedBox(
            width: width,
            child: InkWell(
              onTap: onTap == null ? null : () => onTap!(item),
              borderRadius: BorderRadius.circular(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: SizedBox(
                      width: width,
                      height: width * 1.28,
                      child: Image.network(
                        uri.toString(),
                        headers: {'X-Emby-Token': server.accessToken},
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _ImageFallback(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mediaInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.productionYear?.toString() ?? item.type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mediaMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TechnicalInfo extends StatelessWidget {
  const _TechnicalInfo({required this.sources, this.text});

  final List<EmbyMediaSource> sources;
  final EmbyMediaDetailText? text;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Text(embyMediaDetailText(text, 'mediaDetailNoStreams')),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          for (var index = 0; index < sources.length; index++)
            _SourceInfo(
              source: sources[index],
              title:
                  '${embyMediaDetailText(text, 'mediaDetailVersion')} ${index + 1}',
              text: text,
            ),
        ],
      ),
    );
  }
}

class _SourceInfo extends StatelessWidget {
  const _SourceInfo({required this.source, required this.title, this.text});

  final EmbyMediaSource source;
  final String title;
  final EmbyMediaDetailText? text;

  @override
  Widget build(BuildContext context) {
    final video = source.mediaStreams.where(
      (stream) => stream.type?.toLowerCase() == 'video',
    );
    final rows = <(String, String)>[
      if (source.container != null)
        (
          embyMediaDetailText(text, 'mediaDetailTechContainer'),
          source.container!,
        ),
      if (source.size != null)
        (embyMediaDetailText(text, 'mediaDetailTechSize'), _size(source.size!)),
      if (source.bitrate != null)
        (
          embyMediaDetailText(text, 'mediaDetailTechBitrate'),
          _bitrate(source.bitrate!),
        ),
      for (final stream in video) ...[
        if (stream.codec != null)
          (embyMediaDetailText(text, 'mediaDetailTechVideo'), stream.codec!),
        if (stream.width != null && stream.height != null)
          (
            embyMediaDetailText(text, 'mediaDetailResolution'),
            '${stream.width}×${stream.height}',
          ),
        if (stream.frameRate != null)
          (
            embyMediaDetailText(text, 'mediaDetailFrameRate'),
            '${stream.frameRate!.toStringAsFixed(2)} fps',
          ),
        if (stream.videoRange != null)
          (
            embyMediaDetailText(text, 'mediaDetailVideoRange'),
            stream.videoRange!,
          ),
        if (stream.colorSpace != null)
          (
            embyMediaDetailText(text, 'mediaDetailColorSpace'),
            stream.colorSpace!,
          ),
        if (stream.colorTransfer != null)
          (
            embyMediaDetailText(text, 'mediaDetailColorTransfer'),
            stream.colorTransfer!,
          ),
      ],
      for (final stream in source.audioStreams)
        (
          embyMediaDetailText(text, 'mediaDetailTechAudio'),
          _audioDetails(stream),
        ),
    ];
    return Card(
      color: AppColors.mediaSurface,
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(source.name.isNotEmpty ? source.name : title),
        subtitle: Text(_summary(source)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      label,
                      style: const TextStyle(color: AppColors.mediaMuted),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(color: AppColors.mediaInk),
                    ),
                  ),
                ],
              ),
            ),
          if (rows.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(embyMediaDetailText(text, 'mediaDetailNoStreams')),
            ),
        ],
      ),
    );
  }

  String _summary(EmbyMediaSource value) => [
    if (value.container != null) value.container!,
    if (value.bitrate != null) _bitrate(value.bitrate!),
  ].join(' · ');

  String _audioDetails(EmbyMediaStream stream) => [
    stream.displayTitle,
    stream.title,
    stream.codec,
    stream.language,
    stream.channelLayout,
    if (stream.channels != null) '${stream.channels}ch',
    if (stream.sampleRate != null) '${stream.sampleRate} Hz',
    if (stream.bitDepth != null) '${stream.bitDepth} bit',
    if (stream.isDefault) embyMediaDetailText(text, 'mediaDetailStreamDefault'),
    if (stream.isForced) embyMediaDetailText(text, 'mediaDetailStreamForced'),
    if (stream.isExternal)
      embyMediaDetailText(text, 'mediaDetailStreamExternal'),
  ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');

  String _size(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return '${value.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
  }

  String _bitrate(int bits) => '${(bits / 1000000).toStringAsFixed(1)} Mbps';
}

class _Poster extends StatelessWidget {
  const _Poster({
    required this.detail,
    required this.server,
    required this.libraryService,
    required this.width,
  });

  final EmbyMediaDetail detail;
  final EmbyServer server;
  final EmbyLibraryService libraryService;
  final double width;

  @override
  Widget build(BuildContext context) {
    final image = _primaryImage(detail.images, detail.id);
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        width: width,
        height: width * 1.46,
        child: image == null
            ? const _ImageFallback()
            : Image.network(
                embyMediaDetailImageUri(
                  libraryService: libraryService,
                  server: server,
                  image: image,
                  maxWidth: 620,
                ).toString(),
                headers: {'X-Emby-Token': server.accessToken},
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ImageFallback(),
              ),
      ),
    );
  }
}

class _HeroGradient extends StatelessWidget {
  const _HeroGradient();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xE6FFD9C6), Color(0xF2FFD9C6), Color(0xFFFFD9C6)],
        stops: [0, 0.56, 1],
      ),
    ),
  );
}

class _Rating extends StatelessWidget {
  const _Rating({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFE4F0E8),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: const Color(0xFF6F9F80)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFD166), size: 17),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.mediaInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _FactChip extends StatelessWidget {
  const _FactChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.mediaAccent.withValues(alpha: 0.10),
      border: Border.all(color: AppColors.mediaAccent.withValues(alpha: 0.24)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.mediaInk, fontSize: 12),
      ),
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Chip(label: Text(label));
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.mediaSurface,
    child: Center(
      child: Icon(Icons.movie_outlined, color: AppColors.mediaMuted, size: 32),
    ),
  );
}

EmbyMediaDetailImage? _primaryImage(
  List<EmbyMediaDetailImage> images,
  String itemId,
) {
  for (final image in images) {
    if (image.itemId == itemId &&
        image.type == 'Primary' &&
        image.index == null) {
      return image;
    }
  }
  return null;
}

EmbyMediaDetailImage? _preferredBackdrop(
  List<EmbyMediaDetailImage> images,
  String itemId,
) {
  EmbyMediaDetailImage? first;
  for (final image in images) {
    if (image.type != 'Backdrop') continue;
    if (first == null) first = image;
    if (image.itemId == itemId) return image;
  }
  return first;
}

Uri embyMediaDetailImageUri({
  required EmbyLibraryService libraryService,
  required EmbyServer server,
  required EmbyMediaDetailImage image,
  required int maxWidth,
}) {
  final uri = libraryService.imageUri(
    serverAddress: server.address,
    itemId: image.itemId,
    imageType: image.type,
    imageTag: image.tag,
    maxWidth: maxWidth,
  );
  return image.index == null
      ? uri
      : uri.replace(pathSegments: [...uri.pathSegments, '${image.index}']);
}
