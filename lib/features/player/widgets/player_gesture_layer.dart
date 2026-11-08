import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// Seek, volume, brightness and double-tap gesture surface.
class PlayerGestureLayer extends StatefulWidget {
  const PlayerGestureLayer({
    super.key,
    required this.duration,
    required this.position,
    required this.volume,
    required this.onSeek,
    required this.onVolumeChanged,
    required this.onTap,
    required this.onDoubleTap,
    this.locked = false,
    this.onPreviewChanged,
    this.onActivity,
    this.onInteractionChanged,
    this.text,
  });

  final bool locked;
  final Duration duration;
  final Duration position;
  final double volume;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final ValueChanged<Duration?>? onPreviewChanged;
  final VoidCallback? onActivity;
  final ValueChanged<bool>? onInteractionChanged;
  final String Function(String key)? text;

  @override
  State<PlayerGestureLayer> createState() => _PlayerGestureLayerState();
}

class _PlayerGestureLayerState extends State<PlayerGestureLayer> {
  Offset? _start;
  Duration? _preview;
  double _startValue = 0;
  bool _isHorizontalSeek = false;
  bool _isVerticalAdjust = false;
  bool _adjustBrightness = false;
  double? _brightness;
  Future<double>? _brightnessRead;
  int _gestureGeneration = 0;
  String? _indicator;

  String _text(String key, String fallback) =>
      widget.text?.call(key) ?? fallback;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      onDoubleTap: widget.locked ? null : widget.onDoubleTap,
      onPanStart: widget.locked
          ? null
          : (details) => _onPanStart(details, constraints.biggest),
      onPanUpdate: widget.locked
          ? null
          : (details) => _onPanUpdate(details, constraints.biggest),
      onPanEnd: widget.locked ? null : (_) => _onPanEnd(),
      onPanCancel: widget.locked ? null : _cancelPan,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_indicator != null)
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Text(
                    _indicator!,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  void _onPanStart(DragStartDetails details, Size size) {
    _gestureGeneration++;
    widget.onInteractionChanged?.call(true);
    widget.onActivity?.call();
    _start = details.localPosition;
    _startValue = 0;
    _isHorizontalSeek = false;
    _isVerticalAdjust = false;
    _adjustBrightness = details.localPosition.dx < size.width / 2;
    _indicator = null;
    _preview = widget.position;
  }

  Future<void> _onPanUpdate(DragUpdateDetails details, Size size) async {
    final start = _start;
    final generation = _gestureGeneration;
    if (start == null || widget.locked) return;
    widget.onActivity?.call();
    final delta = details.localPosition - start;
    if (!_isHorizontalSeek && !_isVerticalAdjust) {
      if (delta.distance < 12) return;
      _isHorizontalSeek = delta.dx.abs() > delta.dy.abs();
      _isVerticalAdjust = !_isHorizontalSeek;
      if (_isVerticalAdjust) {
        if (_adjustBrightness) {
          // The system brightness read below is asynchronous; do not apply a
          // guessed baseline while the finger is still moving.
          _startValue = _brightness == null ? 0 : _brightness! * 100;
        } else {
          _startValue = widget.volume;
        }
      }
    }
    if (_isVerticalAdjust && _adjustBrightness && _brightness == null) {
      final brightness = await (_brightnessRead ??= _readBrightness());
      if (!mounted || generation != _gestureGeneration || widget.locked) return;
      _brightness ??= brightness;
      _startValue = brightness * 100;
    }
    if (_isHorizontalSeek) {
      final seconds = delta.dx / size.width * 120;
      final milliseconds =
          widget.position.inMilliseconds + (seconds * 1000).round();
      final maximum = widget.duration.inMilliseconds;
      final candidate = Duration(
        milliseconds: maximum > 0
            ? milliseconds.clamp(0, maximum)
            : milliseconds.clamp(0, 1 << 31),
      );
      _preview = candidate;
      _indicator = '${_text('playerSeek', 'Seek')}: ${_format(candidate)}';
      widget.onPreviewChanged?.call(candidate);
      setState(() {});
    } else if (_isVerticalAdjust) {
      final value = (_startValue - delta.dy / size.height * 100).clamp(
        0.0,
        100.0,
      );
      if (_adjustBrightness) {
        final brightness = (value / 100).clamp(0.0, 1.0);
        _brightness = brightness;
        ScreenBrightness()
            .setApplicationScreenBrightness(brightness)
            .catchError((_) {});
        _indicator =
            '${_text('playerBrightness', 'Brightness')}: ${value.round()}%';
      } else {
        widget.onVolumeChanged(value);
        _indicator = '${_text('playerVolume', 'Volume')}: ${value.round()}%';
      }
      setState(() {});
    }
  }

  Future<double> _readBrightness() async {
    try {
      return await ScreenBrightness().application;
    } catch (_) {
      return 0.5;
    }
  }

  void _onPanEnd() {
    if (_isHorizontalSeek && _preview != null) widget.onSeek(_preview!);
    _cancelPan();
  }

  void _cancelPan() {
    _gestureGeneration++;
    widget.onInteractionChanged?.call(false);
    widget.onActivity?.call();
    widget.onPreviewChanged?.call(null);
    _start = null;
    _preview = null;
    _isHorizontalSeek = false;
    _isVerticalAdjust = false;
    if (!mounted) return;
    setState(() => _indicator = null);
  }

  String _format(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
