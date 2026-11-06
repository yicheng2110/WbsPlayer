import 'package:flutter/material.dart';

import '../../../ui/core/app_colors.dart';
import '../models/emby_media_detail.dart';
import '../models/emby_server.dart';
import '../services/emby_library_service.dart';
import '../services/emby_media_detail_service.dart';
import '../view_models/emby_media_detail_view_model.dart';
import '../widgets/emby_media_detail_sections.dart';

/// Responsive standalone Emby detail page, ready to mount from the host router.
///
/// The host owns the shared [libraryService]. Inject a shared detail service if
/// desired; the page only closes a service it creates itself. The optional
/// playback callback is the only play entry point: absent a real player, play
/// stays explicitly unavailable instead of pretending to start playback.
class EmbyMediaDetailPage extends StatefulWidget {
  const EmbyMediaDetailPage({
    super.key,
    required this.server,
    required this.userId,
    required this.itemId,
    required this.libraryService,
    this.detailService,
    this.playbackDelegate,
    this.text,
    this.onSimilarTap,
    this.onExternalLinkTap,
  });

  final EmbyServer server;
  final String userId;
  final String itemId;
  final EmbyLibraryService libraryService;
  final EmbyMediaDetailService? detailService;
  final EmbyMediaPlaybackDelegate? playbackDelegate;
  final EmbyMediaDetailText? text;
  final ValueChanged<EmbySimilarItem>? onSimilarTap;
  final ValueChanged<EmbyExternalLink>? onExternalLinkTap;

  @override
  State<EmbyMediaDetailPage> createState() => _EmbyMediaDetailPageState();
}

class _EmbyMediaDetailPageState extends State<EmbyMediaDetailPage> {
  late final EmbyMediaDetailService _detailService;
  late final bool _ownsDetailService;
  late final EmbyMediaDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _ownsDetailService = widget.detailService == null;
    _detailService = widget.detailService ?? EmbyMediaDetailService();
    _viewModel = EmbyMediaDetailViewModel(
      service: _detailService,
      server: widget.server,
      userId: widget.userId,
      itemId: widget.itemId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _viewModel.load();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    if (_ownsDetailService) _detailService.close();
    super.dispose();
  }

  Future<void> _play() async {
    final delegate = widget.playbackDelegate;
    final detail = _viewModel.content?.detail;
    final source = _viewModel.selectedMediaSource;
    if (delegate == null || detail == null || source == null) return;
    try {
      await delegate(
        detail: detail,
        mediaSource: source,
        audioStream: _viewModel.selectedAudioStream,
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('mediaDetailPlaybackFailed');
    }
  }

  void _showMessage(String key) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(embyMediaDetailText(widget.text, key))),
      );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) {
      final content = _viewModel.content;
      return Scaffold(
        backgroundColor: const Color(0xFFFFD9C6),
        body: CustomScrollView(
          key: const Key('emby-media-detail-scroll'),
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: const Color(0xFFFFD9C6).withValues(alpha: 0.96),
              surfaceTintColor: Colors.transparent,
              foregroundColor: AppColors.mediaInk,
              title: Text(content?.detail.name ?? widget.server.name),
              leading: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.arrow_back),
              ),
              actions: [
                if (content != null)
                  IconButton(
                    key: const Key('emby-media-detail-favorite'),
                    tooltip: embyMediaDetailText(
                      widget.text,
                      content.detail.isFavorite
                          ? 'mediaDetailRemoveFavorite'
                          : 'mediaDetailAddFavorite',
                    ),
                    onPressed: _viewModel.isSavingFavorite
                        ? null
                        : () async {
                            try {
                              await _viewModel.toggleFavorite();
                            } catch (_) {
                              if (mounted) {
                                _showMessage('mediaDetailFavoriteFailed');
                              }
                            }
                          },
                    icon: Icon(
                      content.detail.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: content.detail.isFavorite
                          ? AppColors.mediaAccent
                          : null,
                    ),
                  ),
                IconButton(
                  key: const Key('emby-media-detail-refresh'),
                  tooltip: embyMediaDetailText(widget.text, 'mediaDetailRetry'),
                  onPressed: () => _viewModel.load(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (_viewModel.isLoading && content == null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.mediaAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        embyMediaDetailText(widget.text, 'mediaDetailLoading'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_viewModel.error != null && content == null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 42),
                        const SizedBox(height: 14),
                        Text(
                          embyMediaDetailText(
                            widget.text,
                            'mediaDetailLoadFailed',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _viewModel.load(forceRefresh: true),
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            embyMediaDetailText(
                              widget.text,
                              'mediaDetailRetry',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (content != null) ...[
              SliverToBoxAdapter(
                child: EmbyMediaDetailHero(
                  detail: content.detail,
                  mediaSources: content.mediaSources,
                  images: content.images,
                  server: widget.server,
                  libraryService: widget.libraryService,
                  selectedSourcePosition: _viewModel.selectedSourcePosition,
                  selectedAudioPosition: _viewModel.selectedAudioPosition,
                  onSourceChanged: _viewModel.selectSource,
                  onAudioChanged: _viewModel.selectAudio,
                  onPlay: _play,
                  playbackDelegate: widget.playbackDelegate,
                  text: widget.text,
                ),
              ),
              SliverToBoxAdapter(
                child: EmbyMediaDetailSections(
                  detail: content.detail,
                  similar: content.similar,
                  seasons: content.seasons,
                  mediaSources: content.mediaSources,
                  images: content.images,
                  server: widget.server,
                  libraryService: widget.libraryService,
                  text: widget.text,
                  onSimilarTap: widget.onSimilarTap,
                  onExternalLinkTap: widget.onExternalLinkTap,
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
