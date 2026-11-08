import 'package:flutter/foundation.dart';

import 'package:media_kit/media_kit.dart';

/// Immutable playback state exposed to player widgets.
@immutable
class PlayerSessionState {
  const PlayerSessionState({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffered = Duration.zero,
    this.volume = 100,
    this.rate = 1,
    this.width,
    this.height,
    this.videoCodec,
    this.audioCodec,
    this.audioBitrate,
    this.streamLoadBytesPerSecond,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isCompleted = false,
    this.tracks = const Tracks(),
    this.selectedAudio,
    this.selectedSubtitle,
    this.error,
  });

  final Duration position;
  final Duration duration;
  final Duration buffered;
  final double volume;
  final double rate;
  final int? width;
  final int? height;
  final String? videoCodec;
  final String? audioCodec;
  final double? audioBitrate;
  final double? streamLoadBytesPerSecond;
  final bool isPlaying;
  final bool isBuffering;
  final bool isCompleted;
  final Tracks tracks;
  final AudioTrack? selectedAudio;
  final SubtitleTrack? selectedSubtitle;
  final String? error;

  bool get hasError => error != null;

  PlayerSessionState copyWith({
    Duration? position,
    Duration? duration,
    Duration? buffered,
    double? volume,
    double? rate,
    int? width,
    int? height,
    String? videoCodec,
    String? audioCodec,
    double? audioBitrate,
    double? streamLoadBytesPerSecond,
    bool clearStreamLoadRate = false,
    bool? isPlaying,
    bool? isBuffering,
    bool? isCompleted,
    Tracks? tracks,
    AudioTrack? selectedAudio,
    SubtitleTrack? selectedSubtitle,
    String? error,
    bool clearError = false,
  }) => PlayerSessionState(
    position: position ?? this.position,
    duration: duration ?? this.duration,
    buffered: buffered ?? this.buffered,
    volume: volume ?? this.volume,
    rate: rate ?? this.rate,
    width: width ?? this.width,
    height: height ?? this.height,
    videoCodec: videoCodec ?? this.videoCodec,
    audioCodec: audioCodec ?? this.audioCodec,
    audioBitrate: audioBitrate ?? this.audioBitrate,
    streamLoadBytesPerSecond: clearStreamLoadRate
        ? null
        : streamLoadBytesPerSecond ?? this.streamLoadBytesPerSecond,
    isPlaying: isPlaying ?? this.isPlaying,
    isBuffering: isBuffering ?? this.isBuffering,
    isCompleted: isCompleted ?? this.isCompleted,
    tracks: tracks ?? this.tracks,
    selectedAudio: selectedAudio ?? this.selectedAudio,
    selectedSubtitle: selectedSubtitle ?? this.selectedSubtitle,
    error: clearError ? null : error ?? this.error,
  );
}
