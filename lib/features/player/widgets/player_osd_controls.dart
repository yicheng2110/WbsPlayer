import 'dart:async';

import 'package:flutter/material.dart';

import '../models/player_session_state.dart';

/// Custom full-screen OSD with a three-second idle hide timer.
class PlayerOsdControls extends StatefulWidget {
  const PlayerOsdControls({
    super.key,
    required this.title,
    required this.state,
    required this.onBack,
    required this.onPlayPause,
    required this.onSeek,
    required this.onTracks,
    required this.onRetry,
    this.onMute,
    this.onStats,
    this.onActivity,
    this.onNext,
    this.isMuted = false,
    this.canPlayNext = false,
    this.text,
  });

  final String title;
  final PlayerSessionState state;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onTracks;
  final VoidCallback onRetry;
  final VoidCallback? onMute;
  final VoidCallback? onStats;
  final VoidCallback? onActivity;
  final VoidCallback? onNext;
  final bool isMuted;
  final bool canPlayNext;
  final String Function(String key)? text;

  @override
  State<PlayerOsdControls> createState() => PlayerOsdControlsState();
}

class PlayerOsdControlsState extends State<PlayerOsdControls> {
  Timer? _hideTimer;
  bool _visible = true;
  double? _scrubValue;

  bool get isVisible => _visible;

  String _text(String key, String fallback) =>
      widget.text?.call(key) ?? fallback;

  void showControls() {
    if (!_visible) setState(() => _visible = true);
    _scheduleHide();
  }

  void _interact() {
    _scheduleHide();
    widget.onActivity?.call();
  }

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void didUpdateWidget(covariant PlayerOsdControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.isPlaying != oldWidget.state.isPlaying) {
      if (widget.state.isPlaying) {
        _scheduleHide();
      } else {
        _hideTimer?.cancel();
        if (!_visible) setState(() => _visible = true);
      }
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!widget.state.isPlaying) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.state.isPlaying) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.state.duration;
    final progress =
        _scrubValue ?? widget.state.position.inMilliseconds.toDouble();
    final max = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    return AnimatedOpacity(
      key: const Key('player-osd-opacity'),
      opacity: _visible || !widget.state.isPlaying ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: !_visible && widget.state.isPlaying,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x99000000),
                      Colors.transparent,
                      Color(0xCC000000),
                    ],
                    stops: [0, 0.44, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 8,
              right: 12,
              child: Row(
                children: [
                  IconButton(
                    tooltip: _text('playerBack', 'Back'),
                    onPressed: () {
                      _interact();
                      widget.onBack();
                    },
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ),
                  IconButton(
                    tooltip: _text('playerTracks', 'Tracks'),
                    onPressed: () {
                      _interact();
                      widget.onTracks();
                    },
                    color: Colors.white,
                    icon: const Icon(Icons.subtitles_outlined),
                  ),
                  if (widget.canPlayNext)
                    IconButton(
                      tooltip: _text('playerNextEpisode', 'Next episode'),
                      onPressed: () {
                        _interact();
                        widget.onNext?.call();
                      },
                      color: Colors.white,
                      icon: const Icon(Icons.skip_next),
                    ),
                  IconButton(
                    tooltip: _text('playerStats', 'Playback statistics'),
                    onPressed: () {
                      _interact();
                      widget.onStats?.call();
                    },
                    color: Colors.white,
                    icon: const Icon(Icons.analytics_outlined),
                  ),
                  IconButton(
                    tooltip: _text('playerMute', 'Mute'),
                    onPressed: () {
                      _interact();
                      widget.onMute?.call();
                    },
                    color: Colors.white,
                    icon: Icon(
                      widget.isMuted ? Icons.volume_off : Icons.volume_up,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.state.isBuffering)
              const Center(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: _text('playerBack10', 'Back 10 seconds'),
                      onPressed: () {
                        _interact();
                        widget.onSeek(
                          widget.state.position - const Duration(seconds: 10),
                        );
                      },
                      color: Colors.white,
                      iconSize: 32,
                      icon: const Icon(Icons.replay_10),
                    ),
                    const SizedBox(width: 24),
                    IconButton.filledTonal(
                      key: const Key('player-play-pause'),
                      tooltip: widget.state.isPlaying
                          ? _text('playerPause', 'Pause')
                          : _text('playerPlay', 'Play'),
                      onPressed: () {
                        _interact();
                        widget.onPlayPause();
                      },
                      iconSize: 40,
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                      icon: Icon(
                        widget.state.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      tooltip: _text('playerForward10', 'Forward 10 seconds'),
                      onPressed: () {
                        _interact();
                        widget.onSeek(
                          widget.state.position + const Duration(seconds: 10),
                        );
                      },
                      color: Colors.white,
                      iconSize: 32,
                      icon: const Icon(Icons.forward_10),
                    ),
                  ],
                ),
              ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Row(
                children: [
                  Text(
                    _format(
                      _scrubValue == null
                          ? widget.state.position
                          : Duration(milliseconds: _scrubValue!.round()),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                      ),
                      child: Slider(
                        key: const Key('player-progress'),
                        min: 0,
                        max: max,
                        value: progress.clamp(0, max),
                        onChangeStart: (value) =>
                            setState(() => _scrubValue = value),
                        onChanged: (value) =>
                            setState(() => _scrubValue = value),
                        onChangeEnd: (value) {
                          setState(() => _scrubValue = null);
                          _interact();
                          widget.onSeek(Duration(milliseconds: value.round()));
                        },
                      ),
                    ),
                  ),
                  Text(
                    _format(duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  IconButton(
                    tooltip: _text('playerRetry', 'Retry'),
                    onPressed: () {
                      _interact();
                      widget.onRetry();
                    },
                    color: Colors.white,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
