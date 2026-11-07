import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import '../../servers/models/emby_media_detail.dart';
import '../models/player_media_source.dart';
import '../models/player_preferences.dart';
import '../models/player_session_state.dart';
import '../services/emby_playback_reporter.dart';
import '../services/emby_playback_service.dart';
import '../services/playback_engine.dart';

/// Owns playback resolution, the playback engine lifecycle, track selection,
/// state snapshots and Emby reporting.
class PlayerViewModel extends ChangeNotifier {
  PlayerViewModel({
    required this.serverAddress,
    required this.accessToken,
    required this.userId,
    required this.itemId,
    required this.detail,
    required this.mediaSource,
    required this.audioStream,
    this.preferences = const PlayerPreferences(),
    required EmbyPlaybackService playbackService,
    required EmbyPlaybackReporter reporter,
    required PlaybackEngine engine,
  }) : _playbackService = playbackService,
       _reporter = reporter,
       _engine = engine {
    _state = const PlayerSessionState();
    _subscribe();
  }

  final String serverAddress;
  final String accessToken;
  final String userId;
  final String itemId;
  final EmbyMediaDetail detail;
  final EmbyMediaSource mediaSource;
  final EmbyMediaStream? audioStream;
  final PlayerPreferences preferences;
  final EmbyPlaybackService _playbackService;
  final EmbyPlaybackReporter _reporter;
  final PlaybackEngine _engine;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  late PlayerSessionState _state;
  PlayerSessionState get state => _state;
  PlaybackEngine get engine => _engine;
  PlayerMediaSource? _resolvedSource;
  PlayerMediaSource? get resolvedSource => _resolvedSource;
  bool _isOpening = false;
  bool get isOpening => _isOpening;
  bool _hasStopped = false;
  Future<void>? _stopFuture;
  bool _disposed = false;
  bool _hasReportedStart = false;
  bool _openedBefore = false;
  bool _hasRetriedTranscode = false;
  bool _hasAppliedDefaultTracks = false;
  bool _isMuted = false;
  double _lastAudibleVolume = 100;

  Future<void> open() async {
    if (_isOpening || _disposed) return;
    _isOpening = true;
    if (_hasReportedStart) {
      await stop();
      _hasReportedStart = false;
    }
    _hasStopped = false;
    _hasRetriedTranscode = false;
    _state = _state.copyWith(
      position: _openedBefore ? _state.position : _resumePosition,
      isCompleted: false,
      clearError: true,
    );
    notifyListeners();
    try {
      var resolved = await _playbackService.resolve(
        serverAddress: serverAddress,
        accessToken: accessToken,
        userId: userId,
        itemId: itemId,
        mediaSource: mediaSource,
        audioStreamIndex: audioStream?.index,
        maxStreamingBitrate: preferences.maxStreamingBitrate,
      );
      if (_disposed) return;
      _resolvedSource = resolved;
      final position = _state.position;
      if (preferences.audioPassthrough) {
        try {
          await _engine.setAudioPassthrough(true);
        } catch (error) {
          debugPrint('Unable to enable audio passthrough: $error');
        }
      }
      try {
        await _openSource(resolved, position);
      } catch (directError) {
        if (!resolved.supportsTranscoding) rethrow;
        debugPrint(
          'Direct playback failed, retrying with HLS transcode: $directError',
        );
        resolved = await _playbackService.resolve(
          serverAddress: serverAddress,
          accessToken: accessToken,
          userId: userId,
          itemId: itemId,
          mediaSource: mediaSource,
          audioStreamIndex: audioStream?.index,
          maxStreamingBitrate: preferences.maxStreamingBitrate,
          forceTranscoding: true,
        );
        if (_disposed) return;
        _resolvedSource = resolved;
        await _openSource(resolved, position);
      }
      if (_disposed) return;
      _openedBefore = true;
      _hasRetriedTranscode = false;
      _hasReportedStart = true;
      _hasStopped = false;
      _stopFuture = null;
      await _reporter.onStart(
        serverAddress: serverAddress,
        accessToken: accessToken,
        userId: userId,
        itemId: itemId,
        source: resolved,
        position: position,
        isMuted: _state.volume <= 0,
        audioStreamIndex: audioStream?.index,
        subtitleStreamIndex: mediaSource.defaultSubtitleStreamIndex,
      );
    } catch (error) {
      _hasReportedStart = false;
      _hasStopped = false;
      if (_disposed) return;
      _state = _state.copyWith(error: error.toString());
      notifyListeners();
    } finally {
      _isOpening = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _openSource(PlayerMediaSource source, Duration position) =>
      _engine.open(
        Media(
          source.url.toString(),
          httpHeaders: source.headers,
          start: position > Duration.zero ? position : null,
        ),
      );

  Duration get _resumePosition {
    final ticks = detail.playbackPositionTicks;
    if (ticks <= 0) return Duration.zero;
    return EmbyPlaybackReporter.ticksToDuration(ticks);
  }

  Future<void> togglePlayPause() async {
    final shouldPause = _state.isPlaying;
    if (shouldPause) {
      await _engine.pause();
    } else {
      await _engine.play();
    }
    await _reportProgress(force: true, isPaused: shouldPause);
  }

  Future<void> pauseAndReport() async {
    await _engine.pause();
    await _reportProgress(force: true, isPaused: true);
  }

  Future<void> toggleMute() async {
    if (_isMuted) {
      await setVolume(_lastAudibleVolume);
      _isMuted = false;
    } else {
      if (_state.volume > 0) _lastAudibleVolume = _state.volume;
      await setVolume(0);
      _isMuted = true;
    }
    await _reportProgress(force: true);
    notifyListeners();
  }

  Future<void> setAudioPassthrough(bool enabled) =>
      _engine.setAudioPassthrough(enabled);

  Future<void> setSubtitleStream(EmbyMediaStream stream) async {
    if (!stream.isExternal) return;
    final content = await _playbackService.loadExternalSubtitle(
      serverAddress: serverAddress,
      accessToken: accessToken,
      itemId: itemId,
      mediaSourceId: mediaSource.id,
      subtitle: stream,
    );
    final track = SubtitleTrack.data(
      content,
      title: stream.displayTitle ?? stream.title ?? stream.language,
      language: stream.language,
    );
    await _engine.setSubtitleTrack(track);
    _state = _state.copyWith(selectedSubtitle: track);
    notifyListeners();
    await _reportProgress(force: true);
  }

  Future<void> seek(Duration position) async {
    final duration = _state.duration;
    final target = duration <= Duration.zero
        ? position
        : position < Duration.zero
        ? Duration.zero
        : position > duration
        ? duration
        : position;
    await _engine.seek(target);
    await _reportProgress(force: true, position: target);
  }

  Future<void> setVolume(double volume) =>
      _engine.setVolume(volume.clamp(0, 100));

  Future<void> setRate(double rate) => _engine.setRate(rate);

  Future<void> selectAudio(AudioTrack track) async {
    await _engine.setAudioTrack(track);
    _state = _state.copyWith(selectedAudio: track);
    notifyListeners();
    await _reportProgress(force: true);
  }

  Future<void> selectSubtitle(SubtitleTrack track) async {
    await _engine.setSubtitleTrack(track);
    _state = _state.copyWith(selectedSubtitle: track);
    notifyListeners();
    await _reportProgress(force: true);
  }

  Future<void> onAppPaused() async {
    if (_state.isPlaying) await pauseAndReport();
  }

  Future<void> stop() {
    if (_hasStopped) return _stopFuture ?? Future<void>.value();
    if (!_hasReportedStart) return Future<void>.value();
    _hasStopped = true;
    return _stopFuture = _reporter.onStop(position: _state.position);
  }

  Future<void> _reportProgress({
    bool force = false,
    Duration? position,
    bool? isPaused,
  }) async {
    if (!_hasReportedStart) return;
    await _reporter.onProgress(
      position: position ?? _state.position,
      isPaused: isPaused ?? !_state.isPlaying,
      isMuted: _state.volume <= 0,
      audioStreamIndex: _selectedEmbyStreamIndex(
        _state.selectedAudio?.id,
        mediaSource.audioStreams,
      ),
      subtitleStreamIndex: _selectedEmbyStreamIndex(
        _state.selectedSubtitle?.id,
        mediaSource.mediaStreams.where(
          (stream) => stream.type?.toLowerCase() == 'subtitle',
        ),
      ),
      force: force,
    );
  }

  void _subscribe() {
    _listen<Duration>(_engine.position, (position) {
      _state = _state.copyWith(position: position);
      notifyListeners();
      unawaited(_reportProgress());
    });
    _listen<Duration>(_engine.duration, (duration) {
      _state = _state.copyWith(duration: duration);
      notifyListeners();
    });
    _listen<VideoParams>(_engine.videoParams, (_) => _updateVideoStats());
    _listen<int?>(_engine.videoWidth, (_) => _updateVideoStats());
    _listen<int?>(_engine.videoHeight, (_) => _updateVideoStats());
    _listen<double?>(_engine.audioBitrateEvents, (bitrate) {
      _state = _state.copyWith(audioBitrate: bitrate);
      notifyListeners();
    });
    _listen<Duration>(_engine.buffer, (buffered) {
      _state = _state.copyWith(buffered: buffered);
      notifyListeners();
    });
    _listen<double>(_engine.volume, (volume) {
      _state = _state.copyWith(volume: volume);
      if (volume > 0) _lastAudibleVolume = volume;
      _isMuted = volume == 0;
      notifyListeners();
    });
    _listen<double>(_engine.rate, (_) {
      unawaited(_reportProgress(force: true));
    });
    _listen<bool>(_engine.playing, (isPlaying) {
      _state = _state.copyWith(isPlaying: isPlaying);
      notifyListeners();
    });
    _listen<bool>(_engine.buffering, (isBuffering) {
      _state = _state.copyWith(isBuffering: isBuffering);
      notifyListeners();
    });
    _listen<bool>(_engine.completed, (completed) {
      _state = _state.copyWith(isCompleted: completed);
      notifyListeners();
      if (completed) unawaited(stop());
    });
    _listen<Tracks>(_engine.tracks, (tracks) {
      _state = _state.copyWith(
        tracks: tracks,
        width: _engine.width,
        height: _engine.height,
        videoCodec: _engine.videoCodec,
        audioCodec: _state.selectedAudio?.codec,
        audioBitrate: _engine.audioBitrate,
      );
      notifyListeners();
      _selectMatchingAudioTrack(tracks);
    });
    _listen<Track>(_engine.track, (track) {
      _state = _state.copyWith(
        selectedAudio: track.audio,
        selectedSubtitle: track.subtitle,
        audioCodec: track.audio.codec,
      );
      notifyListeners();
      unawaited(_reportProgress(force: true));
    });
    _listen<String>(_engine.error, (error) {
      if (error.isEmpty) return;
      final source = _resolvedSource;
      if (source != null &&
          source.supportsTranscoding &&
          source.playMethod != EmbyPlayMethod.transcode &&
          !_hasRetriedTranscode) {
        _hasRetriedTranscode = true;
        unawaited(_retryWithTranscoding(error));
        return;
      }
      _state = _state.copyWith(error: error);
      notifyListeners();
    });
  }

  Future<void> _retryWithTranscoding(String directError) async {
    if (_disposed) return;
    _isOpening = true;
    _state = _state.copyWith(clearError: true);
    notifyListeners();
    if (_hasReportedStart) {
      await stop();
      _hasReportedStart = false;
    }
    try {
      final source = await _playbackService.resolve(
        serverAddress: serverAddress,
        accessToken: accessToken,
        userId: userId,
        itemId: itemId,
        mediaSource: mediaSource,
        audioStreamIndex: audioStream?.index,
        maxStreamingBitrate: preferences.maxStreamingBitrate ?? 40000000,
        forceTranscoding: true,
      );
      if (_disposed) return;
      await _openSource(source, _state.position);
      if (_disposed) return;
      _resolvedSource = source;
      _hasStopped = false;
      _hasReportedStart = true;
      _stopFuture = null;
      await _reporter.onStart(
        serverAddress: serverAddress,
        accessToken: accessToken,
        userId: userId,
        itemId: itemId,
        source: source,
        position: _state.position,
        isMuted: _state.volume <= 0,
      );
    } catch (error) {
      if (_disposed) return;
      _state = _state.copyWith(error: '$directError; $error');
      notifyListeners();
    } finally {
      _isOpening = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _listen<T>(Stream<T> stream, void Function(T) onData) {
    _subscriptions.add(stream.listen(onData));
  }

  int? _selectedEmbyStreamIndex(
    String? trackId,
    Iterable<EmbyMediaStream> streams,
  ) {
    if (trackId == null || trackId == 'no' || trackId == 'auto') return null;
    final mpvId = int.tryParse(trackId);
    if (mpvId == null) return null;
    final ordered = streams.where((stream) => stream.index != null).toList()
      ..sort((left, right) => left.index!.compareTo(right.index!));
    if (mpvId < 0) return null;
    for (final stream in ordered) {
      if (stream.index == mpvId) return stream.index;
    }
    return mpvId < ordered.length ? ordered[mpvId].index : null;
  }

  void _updateVideoStats() {
    _state = _state.copyWith(
      width: _engine.width,
      height: _engine.height,
      videoCodec: _engine.videoCodec,
      audioCodec: _state.selectedAudio?.codec,
      audioBitrate: _engine.audioBitrate,
    );
    notifyListeners();
  }

  void _selectMatchingAudioTrack(Tracks tracks) {
    final selected = audioStream;
    if (selected != null && selected.index != null) {
      final matchedByIndex = tracks.audio
          .where((track) => track.id == '${selected.index}')
          .firstOrNull;
      final matchedByMetadata = tracks.audio.where((track) {
        final languageMatches =
            selected.language != null &&
            track.language?.toLowerCase() == selected.language!.toLowerCase();
        final title = selected.displayTitle ?? selected.title;
        final titleMatches =
            title != null &&
            title.isNotEmpty &&
            track.title?.toLowerCase() == title.toLowerCase();
        final codecMatches =
            selected.codec != null &&
            track.codec?.toLowerCase() == selected.codec!.toLowerCase();
        return titleMatches || (languageMatches && codecMatches);
      }).firstOrNull;
      final playableTracks = tracks.audio
          .where((track) => track.id != 'no' && track.id != 'auto')
          .toList();
      final track =
          matchedByIndex ??
          matchedByMetadata ??
          (playableTracks.length == 1 ? playableTracks.single : null);
      if (track != null) {
        unawaited(_engine.setAudioTrack(track));
        _state = _state.copyWith(selectedAudio: track);
        notifyListeners();
      }
    }
    if (!_hasAppliedDefaultTracks) {
      _hasAppliedDefaultTracks = true;
      _selectDefaultSubtitleTrack(tracks);
    }
  }

  void _selectDefaultSubtitleTrack(Tracks tracks) {
    final embyDefault = mediaSource.defaultSubtitleStreamIndex;
    final subtitleStreams =
        mediaSource.mediaStreams
            .where((stream) => stream.type?.toLowerCase() == 'subtitle')
            .toList()
          ..sort(
            (left, right) => (left.index ?? -1).compareTo(right.index ?? -1),
          );
    final language = preferences.subtitleLanguage.toLowerCase();
    EmbyMediaStream? preferred;
    if (embyDefault != null && embyDefault >= 0) {
      preferred = subtitleStreams
          .where((stream) => stream.index == embyDefault)
          .firstOrNull;
    }
    preferred ??= language.isEmpty
        ? null
        : subtitleStreams
              .where((stream) => stream.language?.toLowerCase() == language)
              .firstOrNull;
    preferred ??= subtitleStreams
        .where((stream) => stream.isDefault)
        .firstOrNull;
    final stream = preferred;
    if (stream == null || stream.index == null) return;
    if (stream.isExternal) {
      unawaited(setSubtitleStream(stream));
      return;
    }
    final matchingTrack = tracks.subtitle
        .where((track) => track.id == '${stream.index}')
        .firstOrNull;
    final languageTrack = tracks.subtitle
        .where(
          (track) =>
              stream.language != null &&
              track.language?.toLowerCase() == stream.language!.toLowerCase(),
        )
        .firstOrNull;
    final playableTracks = tracks.subtitle
        .where((track) => track.id != 'no' && track.id != 'auto')
        .toList();
    final track =
        matchingTrack ??
        languageTrack ??
        (playableTracks.length == 1 ? playableTracks.single : null);
    if (track == null) return;
    unawaited(_engine.setSubtitleTrack(track));
    _state = _state.copyWith(selectedSubtitle: track);
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_disposeResources());
    super.dispose();
  }

  Future<void> _disposeResources() async {
    await stop();
    await _engine.dispose();
    _playbackService.close();
    _reporter.close();
  }
}
