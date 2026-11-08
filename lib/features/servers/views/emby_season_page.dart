import 'package:flutter/material.dart';

import '../../../ui/core/app_colors.dart';
import '../models/emby_media_detail.dart';
import '../models/emby_server.dart';
import '../services/emby_media_detail_service.dart';
import '../services/emby_library_service.dart';
import '../widgets/emby_cached_image.dart';

class EmbySeasonPage extends StatefulWidget {
  const EmbySeasonPage({
    super.key,
    required this.server,
    required this.userId,
    required this.seriesId,
    required this.season,
    this.detailService,
    required this.libraryService,
    required this.text,
    this.onEpisodeSelected,
  });

  final EmbyServer server;
  final String userId;
  final String seriesId;
  final EmbyMediaSeason season;
  final EmbyMediaDetailService? detailService;
  final EmbyLibraryService libraryService;
  final String Function(String key) text;
  final ValueChanged<EmbyMediaDetail>? onEpisodeSelected;

  @override
  State<EmbySeasonPage> createState() => _EmbySeasonPageState();
}

class _EmbySeasonPageState extends State<EmbySeasonPage> {
  late final EmbyMediaDetailService _detailService;
  late final bool _ownsDetailService;
  List<EmbyMediaDetail> _episodes = const [];
  Object? _error;
  bool _isLoading = true;
  int _requestId = 0;

  String get _title => widget.season.indexNumber == null
      ? widget.season.name
      : widget
            .text('mediaDetailSeasonNumber')
            .replaceAll('{number}', '${widget.season.indexNumber}');

  @override
  void initState() {
    super.initState();
    _ownsDetailService = widget.detailService == null;
    _detailService = widget.detailService ?? EmbyMediaDetailService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEpisodes());
  }

  @override
  void dispose() {
    _requestId++;
    if (_ownsDetailService) _detailService.close();
    super.dispose();
  }

  Future<void> _loadEpisodes({bool forceRefresh = false}) async {
    if (!mounted) return;
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final episodes = await _detailService.getSeasonEpisodes(
        serverAddress: widget.server.address,
        accessToken: widget.server.accessToken,
        userId: widget.userId,
        seriesId: widget.seriesId,
        seasonId: widget.season.id,
        forceRefresh: forceRefresh,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _episodes = episodes;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFD9C6),
    appBar: AppBar(
      title: Text(_title),
      backgroundColor: const Color(0xFFFFD9C6),
      foregroundColor: AppColors.mediaInk,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        IconButton(
          tooltip: widget.text('mediaDetailRetry'),
          onPressed: _isLoading
              ? null
              : () => _loadEpisodes(forceRefresh: true),
          icon: const Icon(Icons.refresh),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_isLoading && _episodes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.mediaAccent),
      );
    }
    if (_error != null && _episodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.text('mediaDetailLoadFailed')),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _loadEpisodes,
                icon: const Icon(Icons.refresh),
                label: Text(widget.text('mediaDetailRetry')),
              ),
            ],
          ),
        ),
      );
    }
    if (_episodes.isEmpty) {
      return Center(child: Text(widget.text('mediaDetailNoEpisodes')));
    }
    return RefreshIndicator(
      onRefresh: () => _loadEpisodes(forceRefresh: true),
      color: AppColors.mediaAccent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            itemCount: _episodes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _EpisodeTile(
              episode: _episodes[index],
              server: widget.server,
              libraryService: widget.libraryService,
              text: widget.text,
              onTap: widget.onEpisodeSelected == null
                  ? null
                  : () => widget.onEpisodeSelected!(_episodes[index]),
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.server,
    required this.libraryService,
    required this.text,
    required this.onTap,
  });

  final EmbyMediaDetail episode;
  final EmbyServer server;
  final EmbyLibraryService libraryService;
  final String Function(String key) text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primaryImage = episode.images.where(
      (image) => image.itemId == episode.id && image.type == 'Primary',
    );
    final imageTag = primaryImage.firstOrNull?.tag;
    final imageUri = imageTag == null
        ? null
        : libraryService.imageUri(
            serverAddress: server.address,
            itemId: episode.id,
            imageTag: imageTag,
            maxWidth: 440,
          );
    final episodeNumber = episode.episodeNumber;
    final title = episodeNumber == null
        ? episode.name
        : '${text('mediaDetailEpisodeNumber').replaceAll('{number}', '$episodeNumber')}  ${episode.name}';
    return Material(
      color: AppColors.mediaSurface,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: 124,
            child: Row(
              children: [
                SizedBox(
                  width: (constraints.maxWidth * 0.36).clamp(80.0, 176.0),
                  height: 124,
                  child: imageUri == null
                      ? const ColoredBox(
                          color: AppColors.mediaBackground,
                          child: Center(
                            child: Icon(
                              Icons.movie_outlined,
                              color: AppColors.mediaMuted,
                            ),
                          ),
                        )
                      : EmbyCachedImage(
                          uri: imageUri,
                          headers: {'X-Emby-Token': server.accessToken},
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: AppColors.mediaBackground,
                            child: Center(
                              child: Icon(
                                Icons.movie_outlined,
                                color: AppColors.mediaMuted,
                              ),
                            ),
                          ),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.mediaInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (episode.overview?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 7),
                          Expanded(
                            child: Text(
                              episode.overview!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.mediaMuted,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (episode.playbackPositionTicks > 0)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.play_circle_outline,
                      color: AppColors.mediaAccent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on Iterable<EmbyMediaDetailImage> {
  EmbyMediaDetailImage? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
