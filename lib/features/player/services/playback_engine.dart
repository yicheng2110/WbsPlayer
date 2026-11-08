import 'package:media_kit/media_kit.dart';

import '../models/player_preferences.dart';

/// Minimal playback-engine contract so ViewModels can be tested without
/// initializing the native libmpv backend.
abstract interface class PlaybackEngine {
  Stream<Duration> get position;
  Stream<Duration> get duration;
  Stream<Duration> get buffer;
  Stream<double> get volume;
  Stream<bool> get playing;
  Stream<bool> get buffering;
  Stream<bool> get completed;
  Stream<Tracks> get tracks;
  Stream<Track> get track;
  Stream<VideoParams> get videoParams;
  Stream<int?> get videoWidth;
  Stream<int?> get videoHeight;
  Stream<double?> get audioBitrateEvents;
  Stream<double> get rate;
  Stream<String> get error;
  int? get width;
  int? get height;
  String? get videoCodec;
  double? get audioBitrate;

  Future<void> open(Media media);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setRate(double rate);
  Future<void> setAudioPassthrough(bool enabled);
  Future<void> setAudioTrack(AudioTrack track);
  Future<void> setSubtitleTrack(SubtitleTrack track);
  Future<void> dispose();
}

/// Production [PlaybackEngine] backed by media_kit's [Player].
class MediaKitPlaybackEngine implements PlaybackEngine {
  MediaKitPlaybackEngine({
    Player? player,
    PlayerConfiguration? configuration,
    this.cacheEnabled = true,
    this.cacheSizeMb = PlayerPreferences.defaultCacheSizeMb,
  }) : player =
           player ??
           Player(
             configuration:
                 configuration ??
                 PlayerConfiguration(
                   bufferSize:
                       PlayerPreferences.normalizeCacheSizeMb(cacheSizeMb) *
                       1024 *
                       1024,
                 ),
           );

  final bool cacheEnabled;
  final int cacheSizeMb;

  final Player player;

  @override
  Stream<Duration> get position => player.stream.position;
  @override
  Stream<Duration> get duration => player.stream.duration;
  @override
  Stream<Duration> get buffer => player.stream.buffer;
  @override
  Stream<double> get volume => player.stream.volume;
  @override
  Stream<double> get rate => player.stream.rate;
  @override
  Stream<bool> get playing => player.stream.playing;
  @override
  Stream<bool> get buffering => player.stream.buffering;
  @override
  Stream<bool> get completed => player.stream.completed;
  @override
  Stream<Tracks> get tracks => player.stream.tracks;
  @override
  Stream<Track> get track => player.stream.track;
  @override
  Stream<VideoParams> get videoParams => player.stream.videoParams;
  @override
  Stream<int?> get videoWidth => player.stream.width;
  @override
  Stream<int?> get videoHeight => player.stream.height;
  @override
  Stream<double?> get audioBitrateEvents => player.stream.audioBitrate;
  @override
  Stream<String> get error => player.stream.error;
  @override
  int? get width => player.state.videoParams.w;
  @override
  int? get height => player.state.videoParams.h;
  @override
  String? get videoCodec => player.state.track.video.codec;
  @override
  double? get audioBitrate => player.state.audioBitrate;

  @override
  Future<void> open(Media media) async {
    await _configureCache();
    await player.open(media);
  }

  Future<void> _configureCache() async {
    final platform = player.platform;
    if (platform is! NativePlayer) return;
    try {
      await platform.setProperty('cache', cacheEnabled ? 'yes' : 'no');
      await platform.setProperty('cache-on-disk', cacheEnabled ? 'yes' : 'no');
    } on UnsupportedError {
      // The web implementation does not expose mpv properties.
    }
  }

  @override
  Future<void> play() => player.play();
  @override
  Future<void> pause() => player.pause();
  @override
  Future<void> seek(Duration position) => player.seek(position);
  @override
  Future<void> setVolume(double volume) => player.setVolume(volume);
  @override
  Future<void> setRate(double rate) => player.setRate(rate);
  @override
  Future<void> setAudioPassthrough(bool enabled) async {
    final platform = player.platform;
    if (platform is NativePlayer) {
      try {
        await platform.setProperty(
          'audio-spdif',
          enabled ? 'ac3,eac3,dts,dts-hd,truehd' : '',
        );
      } on UnsupportedError {
        // The web implementation does not expose mpv properties.
      }
    }
  }

  @override
  Future<void> setAudioTrack(AudioTrack track) => player.setAudioTrack(track);
  @override
  Future<void> setSubtitleTrack(SubtitleTrack track) =>
      player.setSubtitleTrack(track);
  @override
  Future<void> dispose() => player.dispose();
}
