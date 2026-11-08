import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../models/player_session_state.dart';
import 'player_osd_button.dart';

/// Full-screen player controls with a three-second idle hide timer.
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
    this.onAudio,
    this.onSubtitles,
    this.onRateChanged,
    this.onLockChanged,
    this.onFit,
    this.onMute,
    this.onStats,
    this.onActivity,
    this.onNext,
    this.isMuted = false,
    this.canPlayNext = false,
    this.hardwareAcceleration = true,
    this.text,
  });

  final String title;
  final PlayerSessionState state;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final FutureOr<void> Function() onTracks;
  final VoidCallback onRetry;
  final FutureOr<void> Function()? onAudio;
  final FutureOr<void> Function()? onSubtitles;
  final ValueChanged<double>? onRateChanged;
  final ValueChanged<bool>? onLockChanged;
  final VoidCallback? onFit;
  final VoidCallback? onMute;
  final VoidCallback? onStats;
  final VoidCallback? onActivity;
  final VoidCallback? onNext;
  final bool isMuted;
  final bool canPlayNext;
  final bool hardwareAcceleration;
  final String Function(String key)? text;

  @override
  State<PlayerOsdControls> createState() => PlayerOsdControlsState();
}

class PlayerOsdControlsState extends State<PlayerOsdControls> {
  Timer? _hideTimer;
  bool _visible = true;
  bool _locked = false;
  bool _menuOpen = false;
  bool _gestureActive = false;
  int _activeActions = 0;
  double? _scrubValue;

  bool get isVisible => _visible;
  bool get isLocked => _locked;

  AppLocalizations get _l10n =>
      AppLocalizations.of(context) ??
      lookupAppLocalizations(const Locale('en'));

  void showControls() {
    if (!_visible) setState(() => _visible = true);
    _scheduleHide();
  }

  void setGestureActive(bool active) {
    _gestureActive = active;
    showControls();
  }

  void _interact() {
    widget.onActivity?.call();
    _scheduleHide();
  }

  Future<void> _run(FutureOr<void> Function() action) async {
    _activeActions++;
    _hideTimer?.cancel();
    _interact();
    try {
      await action();
    } finally {
      _activeActions--;
      if (mounted) _scheduleHide();
    }
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
      if (!widget.state.isPlaying) _visible = true;
      _scheduleHide();
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if ((!widget.state.isPlaying && !_locked) ||
        _menuOpen ||
        _gestureActive ||
        _activeActions > 0 ||
        _scrubValue != null) {
      return;
    }
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _toggleLock() {
    setState(() => _locked = !_locked);
    widget.onLockChanged?.call(_locked);
    _interact();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    key: const Key('player-osd-opacity'),
    opacity: _visible ? 1 : 0,
    duration: const Duration(milliseconds: 250),
    child: IgnorePointer(
      ignoring: !_visible,
      child: Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE5E3E9),
            surface: Color(0xFF1C1B20),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!_locked)
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x99000000),
                        Colors.transparent,
                        Colors.transparent,
                        Color(0xD9000000),
                      ],
                      stops: [0, 0.22, 0.62, 1],
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 440;
                  final inset = constraints.maxWidth < 600 ? 20.0 : 32.0;
                  final edge = compact ? 4.0 : 12.0;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (!_locked) ...[
                        Positioned(
                          top: edge,
                          left: inset - 8,
                          right: inset - 8,
                          child: _buildTopBar(
                            constraints.maxWidth >= 320 &&
                                MediaQuery.textScalerOf(context).scale(18) <=
                                    24,
                          ),
                        ),
                        Positioned(
                          bottom: edge,
                          left: inset,
                          right: inset,
                          child: _buildBottomBar(context, compact),
                        ),
                        if (widget.onRateChanged != null)
                          Positioned(
                            right: inset,
                            top:
                                constraints.maxHeight * 0.46 -
                                (constraints.maxHeight < 320
                                    ? 24
                                    : compact
                                    ? 58
                                    : 66),
                            child: _buildSpeedControl(
                              compact,
                              horizontal: constraints.maxHeight < 320,
                            ),
                          ),
                      ],
                      Positioned(
                        left: inset - 8,
                        top: constraints.maxHeight * 0.46 - 24,
                        child: _button(
                          key: const Key('player-lock'),
                          tooltip: _locked
                              ? _l10n.playerUnlockControls
                              : _l10n.playerLockControls,
                          icon: _locked
                              ? Icons.lock_outline_rounded
                              : Icons.lock_open_rounded,
                          onPressed: _toggleLock,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (widget.state.isBuffering)
              const IgnorePointer(
                child: Center(
                  child: SizedBox.square(
                    dimension: 40,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _buildTopBar(bool showDecoder) => Row(
    children: [
      _button(
        tooltip: _l10n.playerBack,
        icon: Icons.arrow_back_rounded,
        onPressed: () => _run(widget.onBack),
      ),
      const Spacer(),
      if (showDecoder)
        Tooltip(
          message: _l10n.playerHardwareAcceleration,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              widget.hardwareAcceleration ? 'HW+' : 'SW',
              key: const Key('player-decoder'),
              style: const TextStyle(color: Color(0xFFE5E3E9), fontSize: 18),
            ),
          ),
        ),
      _button(
        tooltip: _l10n.playerTracks,
        icon: Icons.menu_book_outlined,
        onPressed: () => _run(widget.onTracks),
      ),
      if (widget.onFit != null)
        _button(
          tooltip: _l10n.playerVideoFit,
          icon: Icons.fit_screen_outlined,
          onPressed: () => _run(widget.onFit!),
        ),
      PopupMenuButton<_PlayerMenuAction>(
        key: const Key('player-more'),
        tooltip: _l10n.playerMore,
        icon: const Icon(Icons.more_vert_rounded),
        iconColor: const Color(0xFFE5E3E9),
        iconSize: 28,
        color: const Color(0xFF1C1B20),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        position: PopupMenuPosition.under,
        constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
        onOpened: () {
          _menuOpen = true;
          _interact();
        },
        onCanceled: _closeMenu,
        onSelected: (action) {
          _closeMenu();
          switch (action) {
            case _PlayerMenuAction.stats:
              _run(widget.onStats!);
            case _PlayerMenuAction.mute:
              _run(widget.onMute!);
            case _PlayerMenuAction.retry:
              _run(widget.onRetry);
          }
        },
        itemBuilder: (context) => [
          if (widget.onStats != null)
            _menuItem(
              _PlayerMenuAction.stats,
              Icons.info_outline_rounded,
              _l10n.playerStats,
            ),
          if (widget.onMute != null)
            _menuItem(
              _PlayerMenuAction.mute,
              widget.isMuted
                  ? Icons.volume_up_outlined
                  : Icons.volume_off_outlined,
              widget.isMuted ? _l10n.playerUnmute : _l10n.playerMute,
            ),
          _menuItem(
            _PlayerMenuAction.retry,
            Icons.refresh_rounded,
            _l10n.playerRetry,
          ),
        ],
      ),
    ],
  );

  void _closeMenu() {
    _menuOpen = false;
    _scheduleHide();
  }

  PopupMenuItem<_PlayerMenuAction> _menuItem(
    _PlayerMenuAction action,
    IconData icon,
    String label,
  ) => PopupMenuItem(
    value: action,
    height: 58,
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFFE5E3E9), size: 25),
        const SizedBox(width: 18),
        Flexible(
          child: Text(label, style: const TextStyle(color: Color(0xFFE5E3E9))),
        ),
      ],
    ),
  );

  Widget _buildBottomBar(BuildContext context, bool compact) {
    final duration = widget.state.duration;
    final maximum = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    final progress =
        _scrubValue ?? widget.state.position.inMilliseconds.toDouble();
    final position = Duration(milliseconds: progress.round());
    final time = Text(
      '${_format(position)} / ${_format(duration)}',
      key: const Key('player-time'),
      style: const TextStyle(
        color: Color(0xFFE5E3E9),
        fontSize: 13,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        activeTrackColor: const Color(0xFFE5E3E9),
        inactiveTrackColor: Colors.white30,
        secondaryActiveTrackColor: Colors.white54,
        thumbColor: const Color(0xFFE5E3E9),
        overlayColor: Colors.white12,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      child: Slider(
        key: const Key('player-progress'),
        max: maximum,
        value: progress.clamp(0, maximum),
        secondaryTrackValue: widget.state.buffered.inMilliseconds
            .toDouble()
            .clamp(0, maximum),
        semanticFormatterCallback: (value) =>
            _format(Duration(milliseconds: value.round())),
        onChangeStart: (_) {
          setState(() => _scrubValue = progress.clamp(0, maximum));
          _interact();
        },
        onChanged: duration > Duration.zero
            ? (value) => setState(() => _scrubValue = value)
            : null,
        onChangeEnd: (value) {
          setState(() => _scrubValue = null);
          _run(() => widget.onSeek(Duration(milliseconds: value.round())));
        },
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          key: const Key('player-title'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFFE5E3E9),
            fontSize: compact ? 20 : 24,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: compact ? 0 : 10),
        LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= 340 &&
                  MediaQuery.textScalerOf(context).scale(13) <= 18
              ? Row(
                  children: [
                    time,
                    const SizedBox(width: 8),
                    Expanded(child: slider),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    time,
                    SizedBox(height: 36, child: slider),
                  ],
                ),
        ),
        Row(
          children: [
            _button(
              key: const Key('player-play-pause'),
              tooltip: widget.state.isPlaying
                  ? _l10n.playerPause
                  : _l10n.playerPlay,
              icon: widget.state.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              iconSize: 34,
              onPressed: () => _run(widget.onPlayPause),
            ),
            if (widget.canPlayNext && widget.onNext != null)
              _button(
                tooltip: _l10n.playerNextEpisode,
                icon: Icons.skip_next_rounded,
                onPressed: () => _run(widget.onNext!),
              ),
            const Spacer(),
            _button(
              key: const Key('player-audio'),
              tooltip: _l10n.playerAudio,
              icon: Icons.music_note_outlined,
              onPressed: () => _run(widget.onAudio ?? widget.onTracks),
            ),
            const SizedBox(width: 8),
            _button(
              key: const Key('player-subtitles'),
              tooltip: _l10n.playerSubtitles,
              icon: Icons.closed_caption_outlined,
              onPressed: () => _run(widget.onSubtitles ?? widget.onTracks),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeedControl(bool compact, {bool horizontal = false}) {
    final rate = widget.state.rate;
    return DecoratedBox(
      key: const Key('player-speed-control'),
      decoration: BoxDecoration(
        color: const Color(0xCC18181B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Flex(
        direction: horizontal ? Axis.horizontal : Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(
            key: const Key('player-speed-increase'),
            tooltip: _l10n.playerSpeedIncrease,
            icon: Icons.add_rounded,
            onPressed: rate < 2
                ? () => _run(
                    () => widget.onRateChanged!((rate + 0.25).clamp(0.25, 2.0)),
                  )
                : null,
          ),
          Semantics(
            label: _l10n.playerSpeed,
            value: '${rate}x',
            child: SizedBox(
              width: 52,
              height: compact ? 20 : 36,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '${rate.toStringAsFixed(rate * 10 == (rate * 10).roundToDouble() ? 1 : 2)}x',
                    style: const TextStyle(
                      color: Color(0xFFE5E3E9),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _button(
            key: const Key('player-speed-decrease'),
            tooltip: _l10n.playerSpeedDecrease,
            icon: Icons.remove_rounded,
            onPressed: rate > 0.25
                ? () => _run(
                    () => widget.onRateChanged!((rate - 0.25).clamp(0.25, 2.0)),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _button({
    Key? key,
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    double iconSize = 27,
  }) => PlayerOsdButton(
    key: key,
    tooltip: tooltip,
    icon: icon,
    onPressed: onPressed,
    iconSize: iconSize,
  );

  String _format(Duration duration) {
    final value = duration < Duration.zero ? Duration.zero : duration;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${value.inHours}:$minutes:$seconds';
  }
}

enum _PlayerMenuAction { stats, mute, retry }
