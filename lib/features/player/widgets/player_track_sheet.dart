import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../../servers/models/emby_media_detail.dart';

/// Audio, subtitle and playback speed selection sheet.
class PlayerTrackSheet extends StatelessWidget {
  const PlayerTrackSheet({
    super.key,
    required this.tracks,
    required this.selectedAudio,
    required this.selectedSubtitle,
    required this.onAudioSelected,
    required this.onSubtitleSelected,
    required this.onRateSelected,
    this.externalSubtitles = const [],
    this.onExternalSubtitleSelected,
    this.text,
  });

  final Tracks tracks;
  final AudioTrack? selectedAudio;
  final SubtitleTrack? selectedSubtitle;
  final ValueChanged<AudioTrack> onAudioSelected;
  final ValueChanged<SubtitleTrack> onSubtitleSelected;
  final ValueChanged<double> onRateSelected;
  final List<EmbyMediaStream> externalSubtitles;
  final ValueChanged<EmbyMediaStream>? onExternalSubtitleSelected;
  final String Function(String key)? text;

  String _text(String key, String fallback) => text?.call(key) ?? fallback;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                _text('playerTracks', 'Tracks'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (tracks.audio.isNotEmpty) ...[
              _heading(context, _text('playerAudio', 'Audio')),
              for (final track in tracks.audio)
                RadioListTile<AudioTrack>(
                  dense: true,
                  value: track,
                  groupValue: selectedAudio,
                  title: Text(_trackName(track)),
                  onChanged: (value) {
                    if (value != null) onAudioSelected(value);
                  },
                ),
            ],
            if (tracks.subtitle.isNotEmpty || externalSubtitles.isNotEmpty) ...[
              _heading(context, _text('playerSubtitles', 'Subtitles')),
              for (final track in tracks.subtitle)
                RadioListTile<SubtitleTrack>(
                  dense: true,
                  value: track,
                  groupValue: selectedSubtitle,
                  title: Text(_trackName(track)),
                  onChanged: (value) {
                    if (value != null) onSubtitleSelected(value);
                  },
                ),
              if (externalSubtitles.isNotEmpty)
                _heading(
                  context,
                  _text('playerExternalSubtitles', 'External subtitles'),
                ),
              for (final stream in externalSubtitles)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.subtitles),
                  title: Text(
                    stream.displayTitle ??
                        stream.title ??
                        stream.language ??
                        stream.codec ??
                        'Subtitle',
                  ),
                  subtitle: stream.language == null
                      ? null
                      : Text(stream.language!),
                  onTap: onExternalSubtitleSelected == null
                      ? null
                      : () => onExternalSubtitleSelected!(stream),
                ),
            ],
            _heading(context, _text('playerSpeed', 'Speed')),
            Wrap(
              spacing: 8,
              children: [
                for (final rate in [0.75, 1.0, 1.25, 1.5, 2.0])
                  ActionChip(
                    label: Text('${rate}x'),
                    onPressed: () => onRateSelected(rate),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _heading(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 6),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );

  String _trackName(dynamic track) {
    if (track.title case final title? when title.isNotEmpty) return title;
    if (track.language case final language? when language.isNotEmpty) {
      return '${track.codec ?? ''} $language'.trim();
    }
    if (track.id == 'no') return _text('playerSubtitlesOff', 'Off');
    return '${track.codec ?? ''} ${track.id}'.trim();
  }
}
