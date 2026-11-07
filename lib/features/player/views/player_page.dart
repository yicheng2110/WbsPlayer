import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../servers/models/emby_media_detail.dart';
import '../models/player_preferences.dart';
import '../services/emby_playback_reporter.dart';
import '../services/emby_playback_service.dart';
import '../services/playback_engine.dart';
import '../view_models/player_view_model.dart';
import '../widgets/player_error_view.dart';
import '../widgets/player_gesture_layer.dart';
import '../widgets/player_osd_controls.dart';
import '../widgets/player_track_sheet.dart';

/// Arguments required to open a video from the detail page.
class PlayerPageArgs {
  const PlayerPageArgs({
    required this.serverAddress,
    required this.accessToken,
    required this.userId,
    required this.itemId,
    required this.detail,
    required this.mediaSource,
    this.audioStream,
    this.preferences = const PlayerPreferences(),
    this.nextEpisodeLoader,
    this.onNextEpisode,
    this.title,
    this.text,
  });

  final String serverAddress;
  final String accessToken;
  final String userId;
  final String itemId;
  final EmbyMediaDetail detail;
  final EmbyMediaSource mediaSource;
  final EmbyMediaStream? audioStream;
  final PlayerPreferences preferences;
  final Future<PlayerPageArgs?> Function()? nextEpisodeLoader;
  final ValueChanged<PlayerPageArgs>? onNextEpisode;
  final String? title;
  final String Function(String key)? text;
}

/// Full-screen media_kit player route.
class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.args});

  final PlayerPageArgs args;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver {
  late final MediaKitPlaybackEngine _engine = MediaKitPlaybackEngine();
  late final VideoController _videoController = VideoController(
    _engine.player,
    configuration: VideoControllerConfiguration(
      hwdec: widget.args.preferences.hardwareAcceleration ? 'auto-safe' : 'no',
    ),
  );
  late final PlayerViewModel _viewModel = PlayerViewModel(
    serverAddress: widget.args.serverAddress,
    accessToken: widget.args.accessToken,
    userId: widget.args.userId,
    itemId: widget.args.itemId,
    detail: widget.args.detail,
    mediaSource: widget.args.mediaSource,
    audioStream: widget.args.audioStream,
    preferences: widget.args.preferences,
    playbackService: EmbyPlaybackService(),
    reporter: EmbyPlaybackReporter(),
    engine: _engine,
  );
  final _osdKey = GlobalKey<PlayerOsdControlsState>();
  final FocusNode _focusNode = FocusNode(debugLabel: 'PlayerPage');
  bool _isSeeking = false;
  bool _showStats = false;
  bool _isAdvancing = false;
  String? _completionHandledItemId;

  String _text(String key, String fallback) =>
      widget.args.text?.call(key) ?? fallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel.addListener(_handlePlaybackState);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _viewModel.open();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_viewModel.onAppPaused());
      if (state == AppLifecycleState.detached) unawaited(_viewModel.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.removeListener(_handlePlaybackState);
    _focusNode.dispose();
    unawaited(
      ScreenBrightness().resetApplicationScreenBrightness().catchError((_) {}),
    );
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    _viewModel.dispose();
    super.dispose();
  }

  void _handlePlaybackState() {
    if (!_viewModel.state.isCompleted ||
        widget.args.nextEpisodeLoader == null ||
        _completionHandledItemId == widget.args.itemId) {
      return;
    }
    _completionHandledItemId = widget.args.itemId;
    unawaited(_playNextEpisode());
  }

  Future<void> _showTracks() async {
    final state = _viewModel.state;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF202124),
      builder: (context) => PlayerTrackSheet(
        tracks: state.tracks,
        externalSubtitles: widget.args.mediaSource.mediaStreams
            .where(
              (stream) =>
                  stream.type?.toLowerCase() == 'subtitle' && stream.isExternal,
            )
            .toList(growable: false),
        selectedAudio: state.selectedAudio,
        selectedSubtitle: state.selectedSubtitle,
        text: (key) => _text(key, key),
        onAudioSelected: (track) {
          unawaited(_viewModel.selectAudio(track));
          Navigator.pop(context);
        },
        onSubtitleSelected: (track) {
          unawaited(_viewModel.selectSubtitle(track));
          Navigator.pop(context);
        },
        onExternalSubtitleSelected: (stream) {
          unawaited(
            _viewModel.setSubtitleStream(stream).catchError((Object error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${_text('playerPlaybackFailed', 'Playback failed')}: ${_playbackError(error.toString())}',
                    ),
                  ),
                );
              }
            }),
          );
          Navigator.pop(context);
        },
        onRateSelected: (rate) {
          unawaited(_viewModel.setRate(rate));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _back() {
    unawaited(_viewModel.stop());
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.mediaPlayPause): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _SeekIntent(-10),
        SingleActivator(LogicalKeyboardKey.arrowRight): _SeekIntent(10),
        SingleActivator(LogicalKeyboardKey.keyM): _MuteIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              unawaited(_viewModel.togglePlayPause());
              return null;
            },
          ),
          _SeekIntent: CallbackAction<_SeekIntent>(
            onInvoke: (intent) {
              unawaited(
                _viewModel.seek(
                  _viewModel.state.position + Duration(seconds: intent.seconds),
                ),
              );
              return null;
            },
          ),
          _MuteIntent: CallbackAction<_MuteIntent>(
            onInvoke: (_) {
              unawaited(_viewModel.toggleMute());
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          focusNode: _focusNode,
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              final state = _viewModel.state;
              final error = state.error;
              return PopScope(
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) unawaited(_viewModel.stop());
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Video(
                      controller: _videoController,
                      controls: NoVideoControls,
                      pauseUponEnteringBackgroundMode: false,
                      subtitleViewConfiguration: SubtitleViewConfiguration(
                        style: TextStyle(
                          fontSize: widget.args.preferences.subtitleFontSize,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          backgroundColor: Colors.black.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                    PlayerGestureLayer(
                      duration: state.duration,
                      position: state.position,
                      volume: state.volume,
                      onSeek: (position) =>
                          unawaited(_viewModel.seek(position)),
                      onVolumeChanged: (volume) =>
                          unawaited(_viewModel.setVolume(volume)),
                      onTap: () => _osdKey.currentState?.showControls(),
                      onDoubleTap: () =>
                          unawaited(_viewModel.togglePlayPause()),
                      onPreviewChanged: (position) {
                        if (mounted)
                          setState(() => _isSeeking = position != null);
                      },
                      onActivity: () => _osdKey.currentState?.showControls(),
                      text: (key) => _text(key, key),
                    ),
                    PlayerOsdControls(
                      key: _osdKey,
                      title: widget.args.title ?? widget.args.detail.name,
                      state: state,
                      onBack: _back,
                      onPlayPause: () =>
                          unawaited(_viewModel.togglePlayPause()),
                      onSeek: (position) =>
                          unawaited(_viewModel.seek(position)),
                      onTracks: _showTracks,
                      onRetry: () => _viewModel.open(),
                      onMute: () => unawaited(_viewModel.toggleMute()),
                      onStats: () => setState(() => _showStats = !_showStats),
                      onActivity: () => _osdKey.currentState?.showControls(),
                      isMuted: state.volume <= 0,
                      canPlayNext: widget.args.nextEpisodeLoader != null,
                      onNext: () => unawaited(_playNextEpisode()),
                      text: (key) => _text(key, key),
                    ),
                    if (error != null)
                      ColoredBox(
                        color: Colors.black.withValues(alpha: 0.82),
                        child: PlayerErrorView(
                          message:
                              '${_text('playerPlaybackFailed', 'Playback failed')}: ${_playbackError(error)}',
                          retryLabel: _text('playerRetry', 'Retry'),
                          backLabel: _text('playerBack', 'Back'),
                          onRetry: () => _viewModel.open(),
                          onBack: _back,
                        ),
                      ),
                    if (_viewModel.isOpening && !state.hasError)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    if (_showStats) _buildStatsOverlay(state),
                    if (state.isCompleted &&
                        widget.args.nextEpisodeLoader != null)
                      _buildNextEpisodePrompt(),
                    if (_isAdvancing)
                      ColoredBox(
                        color: Colors.black54,
                        child: Center(
                          child: Text(
                            _text('playerRetrying', 'Loading next episode…'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    if (_isSeeking)
                      Positioned(
                        top: 24,
                        right: 24,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              _formatDuration(state.position),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _buildStatsOverlay(PlayerSessionState state) => Positioned(
    top: 20,
    left: 20,
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_text('playerStats', 'Playback statistics')),
                Text(
                  '${_text('playerStatsVideo', 'Video')}: ${state.width ?? '—'} × ${state.height ?? '—'} ${state.videoCodec ?? ''}',
                ),
                Text(
                  '${_text('playerStatsAudio', 'Audio')}: ${state.audioCodec ?? '—'} ${_formatBitrate(state.audioBitrate)}',
                ),
                Text(
                  '${_text('playerStatsBuffer', 'Buffer')}: ${_formatDuration(state.buffered)}',
                ),
                Text(
                  '${_text('playerStatsVolume', 'Volume')}: ${state.volume.round()}%',
                ),
                Text(
                  '${_text('playerStatsMethod', 'Method')}: ${_viewModel.resolvedSource?.playMethod.apiValue ?? '—'}',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildNextEpisodePrompt() => Positioned(
    right: 24,
    bottom: 88,
    child: FilledButton.icon(
      onPressed: _isAdvancing ? null : _playNextEpisode,
      icon: const Icon(Icons.skip_next),
      label: Text(_text('playerNextEpisode', 'Next episode')),
    ),
  );

  Future<void> _playNextEpisode() async {
    final loader = widget.args.nextEpisodeLoader;
    if (loader == null || _isAdvancing) return;
    setState(() => _isAdvancing = true);
    await _viewModel.stop();
    try {
      final next = await loader();
      if (!mounted) return;
      if (next != null) {
        final onNextEpisode = widget.args.onNextEpisode;
        if (onNextEpisode != null) {
          onNextEpisode(next);
        } else {
          final currentPath = GoRouterState.of(context).uri.path;
          final prefix = currentPath.substring(
            0,
            currentPath.lastIndexOf('/play/'),
          );
          context.pushReplacement<void>(
            '$prefix/play/${Uri.encodeComponent(next.itemId)}',
            extra: next,
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_text('playerPlaybackFailed', 'Playback failed')}: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdvancing = false);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  String _formatBitrate(double? bitsPerSecond) => bitsPerSecond == null
      ? ''
      : '${(bitsPerSecond / 1000000).toStringAsFixed(1)} Mbps';

  String _playbackError(String error) {
    final code = RegExp(r'EmbyPlaybackException\(([^,)]+)')
        .firstMatch(error)
        ?.group(1);
    return switch (code) {
      'noPlayableUrl' => _text(
        'playerNoPlayableUrl',
        'No direct-play URL is available.',
      ),
      'invalidUrl' || 'invalidServerAddress' => _text(
        'playerInvalidPlaybackUrl',
        'The server returned an invalid URL.',
      ),
      'timeout' => _text(
        'playerPlaybackTimeout',
        'The media server timed out.',
      ),
      'network' => _text(
        'playerNetworkError',
        'Could not contact the media server.',
      ),
      'unsupportedSubtitle' => _text(
        'playerSubtitleUnsupported',
        'Subtitle format is unsupported.',
      ),
      'invalidResponse' || 'missingSources' => _text(
        'playerInvalidPlaybackResponse',
        'The media server returned an invalid response.',
      ),
      'requestFailed' => _text(
        'playerRequestFailed',
        'The server rejected the playback request.',
      ),
      _ => error,
    };
  }
}

class _SeekIntent extends Intent {
  const _SeekIntent(this.seconds);
  final int seconds;
}

class _MuteIntent extends Intent {
  const _MuteIntent();
}
