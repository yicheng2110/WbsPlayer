import 'package:flutter/foundation.dart';

/// User-configurable playback defaults shared by settings and the player.
@immutable
class PlayerPreferences {
  const PlayerPreferences({
    this.maxStreamingBitrate,
    this.subtitleLanguage = '',
    this.subtitleFontSize = 32,
    this.audioPassthrough = false,
    this.hardwareAcceleration = true,
  });

  /// `null` means original quality; non-null values are bits per second.
  final int? maxStreamingBitrate;
  final String subtitleLanguage;
  final double subtitleFontSize;
  final bool audioPassthrough;
  final bool hardwareAcceleration;

  factory PlayerPreferences.fromJson(Map<String, dynamic> json) {
    final bitrate = json['maxStreamingBitrate'];
    final fontSize = json['subtitleFontSize'];
    final language = json['subtitleLanguage'];
    return PlayerPreferences(
      maxStreamingBitrate: bitrate is int && bitrate > 0 ? bitrate : null,
      subtitleLanguage: language is String ? language : '',
      subtitleFontSize: fontSize is num && fontSize > 8 && fontSize < 100
          ? fontSize.toDouble()
          : 32,
      audioPassthrough: json['audioPassthrough'] == true,
      hardwareAcceleration: json['hardwareAcceleration'] != false,
    );
  }

  PlayerPreferences copyWith({
    int? maxStreamingBitrate,
    String? subtitleLanguage,
    double? subtitleFontSize,
    bool? audioPassthrough,
    bool? hardwareAcceleration,
    bool clearMaxStreamingBitrate = false,
  }) => PlayerPreferences(
    maxStreamingBitrate: clearMaxStreamingBitrate
        ? null
        : maxStreamingBitrate ?? this.maxStreamingBitrate,
    subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
    subtitleFontSize: subtitleFontSize ?? this.subtitleFontSize,
    audioPassthrough: audioPassthrough ?? this.audioPassthrough,
    hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
  );

  Map<String, dynamic> toJson() => {
    'maxStreamingBitrate': maxStreamingBitrate,
    'subtitleLanguage': subtitleLanguage,
    'subtitleFontSize': subtitleFontSize,
    'audioPassthrough': audioPassthrough,
    'hardwareAcceleration': hardwareAcceleration,
  };
}
