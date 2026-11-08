import 'package:flutter/foundation.dart';

/// User-configurable playback defaults shared by settings and the player.
@immutable
class PlayerPreferences {
  static const minCacheSizeMb = 2;
  static const maxCacheSizeMb = 1024;
  static const defaultCacheSizeMb = 64;
  static const defaultSeekDurationSeconds = 10;
  static const List<int> seekDurationOptionsSeconds = [
    5,
    10,
    15,
    20,
    25,
    30,
    35,
    40,
    45,
    50,
    55,
    60,
  ];

  static int normalizeSeekDurationSeconds(int value) {
    final clamped = value.clamp(5, 60).toInt();
    return ((clamped / 5).round() * 5).clamp(5, 60).toInt();
  }

  static int normalizeCacheSizeMb(int value) {
    final clamped = value.clamp(minCacheSizeMb, maxCacheSizeMb).toInt();
    return clamped.isEven ? clamped : clamped - 1;
  }

  const PlayerPreferences({
    this.maxStreamingBitrate,
    this.subtitleLanguage = '',
    this.subtitleFontSize = 32,
    this.audioPassthrough = false,
    this.hardwareAcceleration = true,
    this.cacheEnabled = true,
    this.cacheSizeMb = defaultCacheSizeMb,
    this.seekBackwardSeconds = defaultSeekDurationSeconds,
    this.seekForwardSeconds = defaultSeekDurationSeconds,
  });

  /// `null` means original quality; non-null values are bits per second.
  final int? maxStreamingBitrate;
  final String subtitleLanguage;
  final double subtitleFontSize;
  final bool audioPassthrough;
  final bool hardwareAcceleration;
  final bool cacheEnabled;
  final int cacheSizeMb;
  final int seekBackwardSeconds;
  final int seekForwardSeconds;

  factory PlayerPreferences.fromJson(Map<String, dynamic> json) {
    final bitrate = json['maxStreamingBitrate'];
    final fontSize = json['subtitleFontSize'];
    final language = json['subtitleLanguage'];
    final cacheSizeMb = json['cacheSizeMb'];
    final seekBackwardSeconds = json['seekBackwardSeconds'];
    final seekForwardSeconds = json['seekForwardSeconds'];
    return PlayerPreferences(
      maxStreamingBitrate: bitrate is int && bitrate > 0 ? bitrate : null,
      subtitleLanguage: language is String ? language : '',
      subtitleFontSize: fontSize is num && fontSize > 8 && fontSize < 100
          ? fontSize.toDouble()
          : 32,
      audioPassthrough: json['audioPassthrough'] == true,
      hardwareAcceleration: json['hardwareAcceleration'] != false,
      cacheEnabled: json['cacheEnabled'] != false,
      cacheSizeMb: cacheSizeMb is num
          ? normalizeCacheSizeMb(cacheSizeMb.round())
          : defaultCacheSizeMb,
      seekBackwardSeconds: seekBackwardSeconds is int
          ? normalizeSeekDurationSeconds(seekBackwardSeconds)
          : defaultSeekDurationSeconds,
      seekForwardSeconds: seekForwardSeconds is int
          ? normalizeSeekDurationSeconds(seekForwardSeconds)
          : defaultSeekDurationSeconds,
    );
  }

  PlayerPreferences copyWith({
    int? maxStreamingBitrate,
    String? subtitleLanguage,
    double? subtitleFontSize,
    bool? audioPassthrough,
    bool? hardwareAcceleration,
    bool? cacheEnabled,
    int? cacheSizeMb,
    int? seekBackwardSeconds,
    int? seekForwardSeconds,
    bool clearMaxStreamingBitrate = false,
  }) => PlayerPreferences(
    maxStreamingBitrate: clearMaxStreamingBitrate
        ? null
        : maxStreamingBitrate ?? this.maxStreamingBitrate,
    subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
    subtitleFontSize: subtitleFontSize ?? this.subtitleFontSize,
    audioPassthrough: audioPassthrough ?? this.audioPassthrough,
    hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
    cacheEnabled: cacheEnabled ?? this.cacheEnabled,
    cacheSizeMb: normalizeCacheSizeMb(cacheSizeMb ?? this.cacheSizeMb),
    seekBackwardSeconds: normalizeSeekDurationSeconds(
      seekBackwardSeconds ?? this.seekBackwardSeconds,
    ),
    seekForwardSeconds: normalizeSeekDurationSeconds(
      seekForwardSeconds ?? this.seekForwardSeconds,
    ),
  );

  Map<String, dynamic> toJson() => {
    'maxStreamingBitrate': maxStreamingBitrate,
    'subtitleLanguage': subtitleLanguage,
    'subtitleFontSize': subtitleFontSize,
    'audioPassthrough': audioPassthrough,
    'hardwareAcceleration': hardwareAcceleration,
    'cacheEnabled': cacheEnabled,
    'cacheSizeMb': cacheSizeMb,
    'seekBackwardSeconds': seekBackwardSeconds,
    'seekForwardSeconds': seekForwardSeconds,
  };
}
