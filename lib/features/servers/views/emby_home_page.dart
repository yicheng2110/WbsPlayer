import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations_context.dart';
import '../../../ui/core/app_colors.dart';
import '../models/emby_media.dart';
import '../models/emby_server.dart';
import '../repositories/server_repository.dart';
import '../services/emby_library_service.dart';
import '../services/emby_server_service.dart';
import '../widgets/emby_home_sections.dart';
import 'emby_library_page.dart';

class EmbyHomePage extends StatefulWidget {
  const EmbyHomePage({
    super.key,
    required this.server,
    this.serverService,
    this.serverRepository,
    this.libraryService,
    this.onLibrarySelected,
    this.onMediaSelected,
  });

  final EmbyServer server;
  final EmbyServerService? serverService;
  final ServerRepository? serverRepository;
  final EmbyLibraryService? libraryService;
  final EmbyLibrarySelected? onLibrarySelected;
  final EmbyMediaSelected? onMediaSelected;

  @override
  State<EmbyHomePage> createState() => _EmbyHomePageState();
}

class _EmbyHomePageState extends State<EmbyHomePage> {
  late final EmbyServerService _serverService =
      widget.serverService ?? EmbyServerService();
  late final EmbyLibraryService _libraryService =
      widget.libraryService ?? EmbyLibraryService();
  late final bool _ownsServerService = widget.serverService == null;
  late final bool _ownsLibraryService = widget.libraryService == null;

  EmbyHomeContent? _content;
  String? _contentUserId;
  String? _contentAccessToken;
  Object? _error;
  bool _isLoading = true;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    if (_ownsServerService) _serverService.close();
    if (_ownsLibraryService) _libraryService.close();
    super.dispose();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      var userId = widget.server.userId;
      var accessToken = widget.server.accessToken;
      if (userId == null || userId.isEmpty) {
        final authentication = await _serverService.authenticateStoredUser(
          widget.server,
        );
        userId = authentication.userId!;
        accessToken = authentication.accessToken;
        final localId = widget.server.localId;
        final repository = widget.serverRepository;
        if (localId != null && repository != null) {
          await repository.updateAuthentication(
            localId: localId,
            accessToken: authentication.accessToken,
            userId: userId,
          );
        }
      }
      _contentUserId = userId;
      _contentAccessToken = accessToken;
      final content = await _loadHomeWithToken(
        userId: userId,
        accessToken: accessToken,
        forceRefresh: _content != null,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _content = content;
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

  Future<EmbyHomeContent> _loadHomeWithToken({
    required String userId,
    required String accessToken,
    required bool forceRefresh,
  }) async {
    try {
      return await _libraryService.loadHome(
        serverAddress: widget.server.address,
        accessToken: accessToken,
        userId: userId,
        forceRefresh: forceRefresh,
      );
    } on EmbyLibraryRequestException catch (error) {
      if (error.statusCode != 401) rethrow;
      final authentication = await _serverService.authenticateStoredUser(
        widget.server,
      );
      final refreshedUserId = authentication.userId!;
      _contentUserId = refreshedUserId;
      _contentAccessToken = authentication.accessToken;
      final localId = widget.server.localId;
      final repository = widget.serverRepository;
      if (localId != null && repository != null) {
        await repository.updateAuthentication(
          localId: localId,
          accessToken: authentication.accessToken,
          userId: refreshedUserId,
        );
      }
      return _libraryService.loadHome(
        serverAddress: widget.server.address,
        accessToken: authentication.accessToken,
        userId: refreshedUserId,
        forceRefresh: true,
      );
    }
  }

  void _openLibrary(EmbyLibrary library) {
    final userId = _contentUserId ?? '';
    final accessToken = _contentAccessToken ?? widget.server.accessToken;
    final callback = widget.onLibrarySelected;
    if (callback != null) {
      callback(library, userId: userId, accessToken: accessToken);
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EmbyLibraryPage(
          library: library,
          server: widget.server.copyWith(
            userId: userId,
            accessToken: accessToken,
          ),
          serverService: _serverService,
          serverRepository: widget.serverRepository,
          libraryService: _libraryService,
          onMediaSelected: widget.onMediaSelected,
        ),
      ),
    );
  }

  EmbyServer get _activeServer => widget.server.copyWith(
    userId: _contentUserId,
    accessToken: _contentAccessToken,
  );

  void _selectMedia(EmbyLibraryItem item) {
    widget.onMediaSelected?.call(
      item,
      userId: _contentUserId ?? '',
      accessToken: _contentAccessToken ?? widget.server.accessToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;
    return Scaffold(
      backgroundColor: AppColors.mediaBackground,
      body: CustomScrollView(
        key: const Key('emby-home-scroll'),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.mediaBackground,
            surfaceTintColor: Colors.transparent,
            foregroundColor: AppColors.mediaInk,
            title: Text(widget.server.name),
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              IconButton(
                key: const Key('emby-home-refresh'),
                tooltip: context.l10n.homeRetry,
                onPressed: _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (_isLoading && content == null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.mediaAccent,
                    ),
                    const SizedBox(height: 18),
                    Text(context.l10n.homeLoading),
                  ],
                ),
              ),
            )
          else if (_error != null && content == null)
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
                        context.l10n.homeLoadFailed,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: Text(context.l10n.homeRetry),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            if (content != null && content.featured.isNotEmpty)
              SliverToBoxAdapter(
                child: FeaturedCarousel(
                  items: content.featured,
                  server: _activeServer,
                  service: _libraryService,
                  onMediaSelected: _selectMedia,
                ),
              ),
            if (_isLoading)
              SliverToBoxAdapter(
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.mediaAccent,
                  backgroundColor: Colors.white12,
                ),
              ),
            if (content != null)
              SliverToBoxAdapter(
                child: ContinueWatchingSection(
                  items: content.recentlyPlayed,
                  server: _activeServer,
                  service: _libraryService,
                  onMediaSelected: _selectMedia,
                ),
              ),
            if (content != null && content.libraries.isNotEmpty)
              SliverToBoxAdapter(
                child: LibraryListSection(
                  sections: content.libraries,
                  server: _activeServer,
                  service: _libraryService,
                  onLibrarySelected: _openLibrary,
                  onMediaSelected: _selectMedia,
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
