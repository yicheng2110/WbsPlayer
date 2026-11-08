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
  EmbyMediaDetail? _playbackDetail;
  List<EmbyMediaSource> _playbackSources = const [];
  bool _isResolvingPlayback = false;
  int _playbackRequestVersion = 0;

  EmbyMediaDetailContent? get content => _content;
  Object? get error => _error;
  bool get isLoading => _isLoading;
  bool get isSavingFavorite => _isSavingFavorite;
  bool get isResolvingPlayback => _isResolvingPlayback;
  EmbyMediaDetail? get playbackDetail => _playbackDetail;
  List<EmbyMediaSource> get playbackSources => _playbackSources;
  int? get selectedSourcePosition => _selectedSourcePosition;
  int? get selectedAudioPosition => _selectedAudioPosition;

  EmbyMediaSource? get selectedMediaSource {
    final position = _selectedSourcePosition;
    final sources = _playbackSources;
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
    _playbackRequestVersion++;
    _isResolvingPlayback = false;
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
      final isSeries = result.detail.type.toLowerCase() == 'series';
      _playbackDetail = isSeries ? null : result.detail;
      _playbackSources = isSeries ? const [] : result.mediaSources;
      _selectDefaultSource(_playbackSources);
      _isLoading = false;
      notifyListeners();
      if (isSeries) {
        try {
          await preparePlayback();
        } catch (_) {
          // Playback discovery is optional; the play action can retry it.
        }
      }
    } catch (error) {
      if (version != _requestVersion) return;
      _error = error;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes a series playback target and its available versions and audio.
  ///
  /// Returns `false` when no episode or playable source is available. Network
  /// failures are propagated without hiding the series detail page.
  Future<bool> preparePlayback() async {
    final detail = _content?.detail;
    if (detail == null || _isLoading || _isResolvingPlayback) return false;
    if (detail.type.toLowerCase() != 'series') {
      return selectedMediaSource != null;
    }
    final version = ++_playbackRequestVersion;
    final detailVersion = _requestVersion;
    final previousItemId = _playbackDetail?.id;
    final previousSourceId = selectedMediaSource?.id;
    final previousAudioIndex = selectedAudioStream?.index;
    _isResolvingPlayback = true;
    notifyListeners();
    try {
      final episode = await _service.getSeriesPlaybackEpisode(
        serverAddress: server.address,
        accessToken: server.accessToken,
        userId: userId,
        seriesId: detail.id,
      );
      if (version != _playbackRequestVersion ||
          detailVersion != _requestVersion)
        return false;
      if (episode == null) {
        _playbackDetail = null;
        _playbackSources = const [];
        _selectDefaultSource(_playbackSources);
        return false;
      }
      final playbackDetail = await _service.getDetail(
        serverAddress: server.address,
        accessToken: server.accessToken,
        userId: userId,
        itemId: episode.id,
        forceRefresh: true,
      );
      if (version != _playbackRequestVersion ||
          detailVersion != _requestVersion)
        return false;
      final sources = playbackDetail.mediaSources.isNotEmpty
          ? playbackDetail.mediaSources
          : await _service.getMediaSources(
              serverAddress: server.address,
              accessToken: server.accessToken,
              userId: userId,
              itemId: episode.id,
              forceRefresh: true,
            );
      if (version != _playbackRequestVersion ||
          detailVersion != _requestVersion)
        return false;
      _playbackDetail = playbackDetail;
      _playbackSources = List.unmodifiable(sources);
      _selectDefaultSource(_playbackSources);
      if (previousItemId == playbackDetail.id && previousSourceId != null) {
        final sourcePosition = sources.indexWhere(
          (source) => source.id == previousSourceId,
        );
        if (sourcePosition >= 0) {
          _selectedSourcePosition = sourcePosition;
          _selectedAudioPosition = _defaultAudioPosition(
            sources[sourcePosition],
          );
          if (previousAudioIndex != null) {
            final audioPosition = sources[sourcePosition].audioStreams
                .indexWhere((stream) => stream.index == previousAudioIndex);
            if (audioPosition >= 0) _selectedAudioPosition = audioPosition;
          }
        }
      }
      return selectedMediaSource != null;
    } finally {
      if (version == _playbackRequestVersion &&
          detailVersion == _requestVersion) {
        _isResolvingPlayback = false;
        notifyListeners();
      }
    }
  }

  /// Selects a version by its position in the current playback source list.
  void selectSource(int? position) {
    final sources = _playbackSources;
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
            if (content.detail.datePlayed != null)
              'LastPlayedDate': content.detail.datePlayed!.toIso8601String(),
            'PlayCount': content.detail.playCount,
            'Played': content.detail.isPlayed,
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
    _playbackRequestVersion++;
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
