import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_context.dart';
import '../../../ui/core/app_colors.dart';
import '../models/emby_media.dart';
import '../models/emby_server.dart';
import '../services/emby_library_service.dart';

class FeaturedCarousel extends StatefulWidget {
  const FeaturedCarousel({
    super.key,
    required this.items,
    required this.server,
    required this.service,
  });

  final List<EmbyLibraryItem> items;
  final EmbyServer server;
  final EmbyLibraryService service;

  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> {
  late final PageController _controller = PageController(viewportFraction: 1);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = math.min(width * 1.08, 620.0);
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            key: const Key('featured-carousel'),
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  _MediaImage(
                    item: item,
                    server: widget.server,
                    service: widget.service,
                    imageType: item.backdropImageTag == null
                        ? 'Primary'
                        : 'Backdrop',
                    maxWidth: 1200,
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x66000000),
                          Color(0x00000000),
                          Color(0xC9000000),
                          Color(0xFF101211),
                        ],
                        stops: [0, 0.25, 0.72, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 46,
                    child: _FeaturedDetails(item: item),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: 14,
            left: 20,
            child: _SectionEyebrow(label: context.l10n.homeFeatured),
          ),
          if (widget.items.length > 1)
            Positioned(
              right: 20,
              bottom: 23,
              child: Row(
                children: List.generate(math.min(widget.items.length, 8), (
                  index,
                ) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(left: 5),
                    width: index == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index == _index
                          ? AppColors.mediaAccent
                          : Colors.white60,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeaturedDetails extends StatelessWidget {
  const _FeaturedDetails({required this.item});

  final EmbyLibraryItem item;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (item.communityRating case final rating?)
        '★ ${rating.toStringAsFixed(1)}',
      if (item.productionYear case final year?) '$year',
      if (item.type.isNotEmpty) item.type,
    ].join('  ·  ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 9),
          Text(
            details,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          (item.overview?.trim().isNotEmpty ?? false)
              ? item.overview!.trim()
              : context.l10n.homeOverviewUnavailable,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            height: 1.45,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class ContinueWatchingSection extends StatelessWidget {
  const ContinueWatchingSection({
    super.key,
    required this.items,
    required this.server,
    required this.service,
  });

  final List<EmbyLibraryItem> items;
  final EmbyServer server;
  final EmbyLibraryService service;

  @override
  Widget build(BuildContext context) => _MediaRail(
    title: context.l10n.homeContinueWatching,
    items: items,
    server: server,
    service: service,
    landscape: true,
    showProgress: true,
  );
}

class LibraryListSection extends StatelessWidget {
  const LibraryListSection({
    super.key,
    required this.sections,
    required this.server,
    required this.service,
  });

  final List<EmbyLibrarySection> sections;
  final EmbyServer server;
  final EmbyLibraryService service;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 8),
        child: Text(
          context.l10n.homeLibraries,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
        ),
      ),
      for (final section in sections)
        _MediaRail(
          key: ValueKey('library-${section.library.id}'),
          title: section.library.name,
          items: section.items,
          server: server,
          service: service,
        ),
    ],
  );
}

class _MediaRail extends StatelessWidget {
  const _MediaRail({
    super.key,
    required this.title,
    required this.items,
    required this.server,
    required this.service,
    this.landscape = false,
    this.showProgress = false,
  });

  final String title;
  final List<EmbyLibraryItem> items;
  final EmbyServer server;
  final EmbyLibraryService service;
  final bool landscape;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.sizeOf(context).width;
    final itemWidth = (availableWidth / 3.15).clamp(132.0, 220.0);
    final imageHeight = landscape ? itemWidth * 0.56 : itemWidth * 1.48;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 21, 14, 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
            child: Text(
              context.l10n.homeNoItems,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          )
        else
          SizedBox(
            height: imageHeight + (showProgress ? 66 : 58),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  width: itemWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: SizedBox(
                          width: itemWidth,
                          height: imageHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _MediaImage(
                                item: item,
                                server: server,
                                service: service,
                                maxWidth: 520,
                                fit: BoxFit.cover,
                              ),
                              if (showProgress)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: LinearProgressIndicator(
                                    minHeight: 4,
                                    value: _progress(item),
                                    backgroundColor: Colors.white30,
                                    color: AppColors.mediaAccent,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (showProgress)
                        Text(
                          item.productionYear?.toString() ?? item.type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        )
                      else if (item.productionYear != null)
                        Text(
                          '${item.productionYear}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  double? _progress(EmbyLibraryItem item) {
    final position = item.playbackPositionTicks;
    final duration = item.runTimeTicks;
    if (position == null || duration == null || duration <= 0) return null;
    return (position / duration).clamp(0.0, 1.0);
  }
}

class _MediaImage extends StatelessWidget {
  const _MediaImage({
    required this.item,
    required this.server,
    required this.service,
    required this.maxWidth,
    required this.fit,
    this.imageType = 'Primary',
  });

  final EmbyLibraryItem item;
  final EmbyServer server;
  final EmbyLibraryService service;
  final int maxWidth;
  final BoxFit fit;
  final String imageType;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      service
          .imageUri(
            serverAddress: server.address,
            itemId: item.id,
            imageType: imageType,
            imageTag: imageType == 'Backdrop'
                ? item.backdropImageTag
                : item.primaryImageTag,
            maxWidth: maxWidth,
          )
          .toString(),
      headers: {'X-Emby-Token': server.accessToken},
      fit: fit,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const _PosterPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) => const _PosterPlaceholder(),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.mediaSurface,
    alignment: Alignment.center,
    child: Icon(
      Icons.movie_outlined,
      color: Colors.white.withValues(alpha: 0.3),
      size: 34,
    ),
  );
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.48),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
