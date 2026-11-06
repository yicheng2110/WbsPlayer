import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_context.dart';
import '../../../ui/core/app_colors.dart';
import '../models/emby_media.dart';
import '../models/emby_server.dart';
import '../repositories/server_repository.dart';
import '../services/emby_library_service.dart';
import '../services/emby_server_service.dart';
import '../widgets/emby_home_sections.dart';

class EmbyLibraryPage extends StatefulWidget {
  const EmbyLibraryPage({
    super.key,
    required this.library,
    required this.server,
    required this.serverService,
    required this.serverRepository,
    required this.libraryService,
    this.onMediaSelected,
  });

  final EmbyLibrary library;
  final EmbyServer server;
  final EmbyServerService serverService;
  final ServerRepository? serverRepository;
  final EmbyLibraryService libraryService;
  final EmbyMediaSelected? onMediaSelected;

  @override
  State<EmbyLibraryPage> createState() => _EmbyLibraryPageState();
}

class _EmbyLibraryPageState extends State<EmbyLibraryPage> {
  static const _pageSize = 40;
  static const _sortOptions = EmbyLibrarySort.values;

  final _scrollController = ScrollController();
  final List<EmbyLibraryItem> _items = [];
  EmbyLibrarySort _sortBy = EmbyLibrarySort.dateCreated;
  bool _ascending = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  Object? _error;
  int _totalRecordCount = 0;
  int _requestId = 0;
  String? _userId;
  late String _accessToken;

  bool get _hasMore =>
      _sortBy != EmbyLibrarySort.random && _items.length < _totalRecordCount;

  @override
  void initState() {
    super.initState();
    _userId = widget.server.userId;
    _accessToken = widget.server.accessToken;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirstPage());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || _isLoadingMore) return;
    if (_scrollController.position.extentAfter < 600) _loadNextPage();
  }

  Future<void> _loadFirstPage() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _error = null;
      _items.clear();
      _totalRecordCount = 0;
    });
    try {
      final page = _sortBy == EmbyLibrarySort.random
          ? await _loadRandomItems(requestId)
          : await _requestPage(startIndex: 0);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _items.addAll(page.items);
        _totalRecordCount = page.totalRecordCount;
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

  Future<EmbyLibraryItemPage> _loadRandomItems(int requestId) async {
    final items = <EmbyLibraryItem>[];
    var totalRecordCount = 0;
    while (items.length < totalRecordCount || items.isEmpty) {
      final page = await _requestPage(startIndex: items.length);
      if (!mounted || requestId != _requestId) {
        return EmbyLibraryItemPage(items: const [], totalRecordCount: 0);
      }
      items.addAll(page.items);
      totalRecordCount = page.totalRecordCount;
      if (items.length >= totalRecordCount ||
          page.items.isEmpty ||
          page.items.length < _pageSize) {
        break;
      }
    }
    items.shuffle();
    return EmbyLibraryItemPage(items: items, totalRecordCount: items.length);
  }

  Future<void> _loadNextPage() async {
    if (_isLoading ||
        _isLoadingMore ||
        !_hasMore ||
        _error != null ||
        _sortBy == EmbyLibrarySort.random) {
      return;
    }
    final requestId = _requestId;
    setState(() => _isLoadingMore = true);
    try {
      final page = await _requestPage(startIndex: _items.length);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _items.addAll(page.items);
        _totalRecordCount = page.totalRecordCount;
        _isLoadingMore = false;
        if (page.items.isEmpty) _totalRecordCount = _items.length;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = error;
        _isLoadingMore = false;
      });
    }
  }

  void _retryNextPage() {
    setState(() => _error = null);
    _loadNextPage();
  }

  Future<EmbyLibraryItemPage> _requestPage({required int startIndex}) async {
    var userId = _userId;
    if (userId == null || userId.isEmpty) {
      await _reauthenticate();
      userId = _userId!;
    }
    try {
      return await widget.libraryService.loadLibraryItems(
        serverAddress: widget.server.address,
        accessToken: _accessToken,
        userId: userId,
        parentId: widget.library.id,
        sortBy: _sortBy == EmbyLibrarySort.random
            ? EmbyLibrarySort.title
            : _sortBy,
        ascending: _sortBy == EmbyLibrarySort.random ? true : _ascending,
        startIndex: startIndex,
        limit: _pageSize,
      );
    } on EmbyLibraryRequestException catch (error) {
      if (error.statusCode != 401) rethrow;
      await _reauthenticate();
      return widget.libraryService.loadLibraryItems(
        serverAddress: widget.server.address,
        accessToken: _accessToken,
        userId: _userId!,
        parentId: widget.library.id,
        sortBy: _sortBy == EmbyLibrarySort.random
            ? EmbyLibrarySort.title
            : _sortBy,
        ascending: _sortBy == EmbyLibrarySort.random ? true : _ascending,
        startIndex: startIndex,
        limit: _pageSize,
      );
    }
  }

  Future<void> _reauthenticate() async {
    final authentication = await widget.serverService.authenticateStoredUser(
      widget.server,
    );
    final userId = authentication.userId;
    if (userId == null || userId.isEmpty) {
      throw const EmbyLibraryRequestException();
    }
    _userId = userId;
    _accessToken = authentication.accessToken;
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

  void _selectSort(EmbyLibrarySort? sort) {
    if (sort == null || sort.apiValue == null) return;
    if (sort == _sortBy) {
      if (sort == EmbyLibrarySort.random) _loadFirstPage();
      return;
    }
    setState(() => _sortBy = sort);
    _loadFirstPage();
  }

  void _toggleDirection() {
    setState(() => _ascending = !_ascending);
    _loadFirstPage();
  }

  String _sortLabel(BuildContext context, EmbyLibrarySort sort) {
    final l10n = context.l10n;
    return switch (sort) {
      EmbyLibrarySort.dateCreated => l10n.librarySortDateAdded,
      EmbyLibrarySort.title => l10n.librarySortTitle,
      EmbyLibrarySort.communityRating => l10n.librarySortCommunityRating,
      EmbyLibrarySort.criticRating => l10n.librarySortCriticRating,
      EmbyLibrarySort.productionYear => l10n.librarySortProductionYear,
      EmbyLibrarySort.premiereDate => l10n.librarySortPremiereDate,
      EmbyLibrarySort.officialRating => l10n.librarySortOfficialRating,
      EmbyLibrarySort.datePlayed => l10n.librarySortDatePlayed,
      EmbyLibrarySort.runtime => l10n.librarySortRuntime,
      EmbyLibrarySort.bitrate => l10n.librarySortBitrate,
      EmbyLibrarySort.size => l10n.librarySortSize,
      EmbyLibrarySort.random => l10n.librarySortRandom,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.mediaBackground,
      appBar: AppBar(
        backgroundColor: AppColors.mediaBackground,
        foregroundColor: AppColors.mediaInk,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.library.name),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          PopupMenuButton<EmbyLibrarySort>(
            tooltip: l10n.librarySort,
            initialValue: _sortBy,
            onSelected: _selectSort,
            itemBuilder: (context) => [
              for (final sort in _sortOptions)
                PopupMenuItem<EmbyLibrarySort>(
                  value: sort,
                  enabled: sort.apiValue != null,
                  child: Row(
                    children: [
                      Expanded(child: Text(_sortLabel(context, sort))),
                      if (sort.apiValue == null)
                        Text(
                          l10n.librarySortUnsupported,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
            ],
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            tooltip: _ascending
                ? l10n.librarySortAscending
                : l10n.librarySortDescending,
            onPressed: _toggleDirection,
            icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.mediaAccent),
      );
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.homeLoadFailed, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _loadFirstPage,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.homeRetry),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) return Center(child: Text(context.l10n.homeNoItems));

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      color: AppColors.mediaAccent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: GridView.builder(
            key: const Key('emby-library-grid'),
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 205,
              mainAxisSpacing: 18,
              crossAxisSpacing: 12,
              childAspectRatio: 0.57,
            ),
            itemCount:
                _items.length +
                (_isLoadingMore || (_error != null && _hasMore) ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _items.length) {
                if (_isLoadingMore) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.mediaAccent,
                    ),
                  );
                }
                return Center(
                  child: IconButton(
                    tooltip: context.l10n.homeRetry,
                    onPressed: _retryNextPage,
                    icon: const Icon(Icons.refresh),
                  ),
                );
              }
              final item = _items[index];
              return _LibraryPoster(
                item: item,
                server: widget.server,
                service: widget.libraryService,
                accessToken: _accessToken,
                onTap: widget.onMediaSelected == null
                    ? null
                    : () => widget.onMediaSelected!(
                        item,
                        userId: _userId ?? '',
                        accessToken: _accessToken,
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LibraryPoster extends StatelessWidget {
  const _LibraryPoster({
    required this.item,
    required this.server,
    required this.service,
    required this.accessToken,
    required this.onTap,
  });

  final EmbyLibraryItem item;
  final EmbyServer server;
  final EmbyLibraryService service;
  final String accessToken;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox.expand(
              child: EmbyPosterImage(
                item: item,
                server: server,
                service: service,
                maxWidth: 520,
                fit: BoxFit.cover,
                accessToken: accessToken,
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.mediaInk,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          [
            if (item.productionYear case final year?) '$year',
            if (item.type.isNotEmpty) item.type,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.mediaMuted, fontSize: 12),
        ),
      ],
    ),
  );
}
