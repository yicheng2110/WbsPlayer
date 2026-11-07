import 'package:flutter/foundation.dart';

/// How Emby will serve the selected media source.
///
/// Phase 1 supports only direct playback and direct stream. Transcoding is
/// intentionally excluded until the client advertises a DeviceProfile.
enum EmbyPlayMethod {
  directPlay('DirectPlay'),
  directStream('DirectStream'),
  transcode('Transcode');

  const EmbyPlayMethod(this.apiValue);

  final String apiValue;
}

/// Resolved playback parameters that are safe to pass to the playback engine.
@immutable
class PlayerMediaSource {
  PlayerMediaSource({
    required this.url,
    required Map<String, String> headers,
    required this.mediaSourceId,
    required this.playSessionId,
    required this.playMethod,
    this.supportsTranscoding = false,
  }) : headers = Map.unmodifiable(headers);

  final Uri url;
  final Map<String, String> headers;
  final String mediaSourceId;
  final String playSessionId;
  final EmbyPlayMethod playMethod;
  final bool supportsTranscoding;
}
