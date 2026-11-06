import 'package:flutter/foundation.dart';

import '../models/emby_media_detail.dart';
import '../models/emby_server.dart';
import '../services/emby_media_detail_service.dart';

/// Owns detail loading and media source/audio selection for the detail view.
class EmbyMediaDetailViewModel extends ChangeNotifier {
  EmbyMediaDetailViewModel({
    required EmbyMediaDetailService service,
    required this.server,
    required this.userId,
    required this.itemId,
  }) : _service = service;

  final EmbyMediaDetailService _service;
  final EmbyServer server;
  final String userId;
  final String itemId;

  EmbyMediaDetailContent? _content;
  Object? _error;
  bool _isLoading = false;
  int? _selectedSourcePosition;
  int? _selectedAudioPosition;
  int _requestVersion = 0;
  bool _isSavingFavorite = false;

  EmbyMediaDetailContent? get content => _content;
  Object? get error => _error;
  bool get isLoading => _isLoading;
  bool get isSavingFavorite => _isSavingFavorite;
  int? get selectedSourcePosition => _selectedSourcePosition;
  int? get selectedAudioPosition => _selectedAudioPosition;

  EmbyMediaSource? get selectedMediaSource {
    final position = _selectedSourcePosition;
    final sources = _content?.mediaSources ?? const <EmbyMediaSource>[];
    return position == null || position < 0 || position >= sources.length
        ? null
        : sources[position];
  }

  EmbyMediaStream? get selectedAudioStream {
    final position = _selectedAudioPosition;
    final streams =
        selectedMediaSource?.audioStreams ?? const <EmbyMediaStream>[];
    return position == null || position < 0 || position >= streams.length
        ? null
        : streams[position];
  }

  /// Fetches required item details and optional sections through the service.
  Future<void> load({bool forceRefresh = false}) async {
    final version = ++_requestVersion;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.loadDetail(
        serverAddress: server.address,
        accessToken: server.accessToken,
        userId: userId,
        itemId: itemId,
        forceRefresh: forceRefresh,
      );
      if (version != _requestVersion) return;
      _content = result;
      _selectDefaultSource(result.mediaSources);
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      if (version != _requestVersion) return;
      _error = error;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selects a version by its position in the current source list.
  void selectSource(int? position) {
    final sources = _content?.mediaSources ?? const <EmbyMediaSource>[];
    if (position == null || position < 0 || position >= sources.length) return;
    _selectedSourcePosition = position;
    _selectedAudioPosition = _defaultAudioPosition(sources[position]);
    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    final content = _content;
    if (content == null || _isSavingFavorite) return;
    final nextValue = !content.detail.isFavorite;
    _isSavingFavorite = true;
    notifyListeners();
    try {
      await _service.setFavorite(
        serverAddress: server.address,
        accessToken: server.accessToken,
        userId: userId,
        itemId: itemId,
        favorite: nextValue,
      );
      _content = EmbyMediaDetailContent(
        detail: EmbyMediaDetail.fromJson({
          ...content.detail.toJson(),
          'UserData': {
            'PlaybackPositionTicks': content.detail.playbackPositionTicks,
            'IsFavorite': nextValue,
          },
        }),
        similar: content.similar,
        seasons: content.seasons,
        mediaSources: content.mediaSources,
        images: content.images,
        failedSections: content.failedSections,
      );
    } finally {
      _isSavingFavorite = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _requestVersion++;
    super.dispose();
  }

  /// Selects an audio stream by its position within the current source.
  void selectAudio(int? position) {
    final streams =
        selectedMediaSource?.audioStreams ?? const <EmbyMediaStream>[];
    if (position == null || position < 0 || position >= streams.length) return;
    _selectedAudioPosition = position;
    notifyListeners();
  }

  void _selectDefaultSource(List<EmbyMediaSource> sources) {
    if (sources.isEmpty) {
      _selectedSourcePosition = null;
      _selectedAudioPosition = null;
      return;
    }
    final preferred = sources.indexWhere(
      (source) =>
          source.defaultAudioStreamIndex != null ||
          source.defaultSubtitleStreamIndex != null,
    );
    _selectedSourcePosition = preferred < 0 ? 0 : preferred;
    _selectedAudioPosition = _defaultAudioPosition(
      sources[_selectedSourcePosition!],
    );
  }

  int? _defaultAudioPosition(EmbyMediaSource source) {
    final audioStreams = source.audioStreams;
    if (audioStreams.isEmpty) return null;
    final defaultIndex = source.defaultAudioStreamIndex;
    if (defaultIndex != null) {
      final position = audioStreams.indexWhere(
        (stream) => stream.index == defaultIndex,
      );
      if (position >= 0) return position;
    }
    final isDefaultPosition = audioStreams.indexWhere(
      (stream) => stream.isDefault,
    );
    return isDefaultPosition >= 0 ? isDefaultPosition : 0;
  }
}
