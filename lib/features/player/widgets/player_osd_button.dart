import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../l10n/generated/app_localizations.dart';

class PlayerOsdButton extends StatelessWidget {
  const PlayerOsdButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconSize = 27,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final double iconSize;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
    iconSize: iconSize,
    style: IconButton.styleFrom(
      foregroundColor: const Color(0xFFE5E3E9),
      disabledForegroundColor: Colors.white30,
      minimumSize: const Size.square(48),
      padding: const EdgeInsets.all(8),
      tapTargetSize: MaterialTapTargetSize.padded,
    ),
  );
}

@Preview(
  name: 'Player controls',
  size: Size(280, 80),
  brightness: Brightness.dark,
)
Widget playerOsdButtonPreview() => MaterialApp(
  theme: ThemeData.dark(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    backgroundColor: Colors.black,
    body: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerOsdButton(
                tooltip: l10n.playerPlay,
                icon: Icons.play_arrow_rounded,
                iconSize: 34,
                onPressed: () {},
              ),
              PlayerOsdButton(
                tooltip: l10n.playerAudio,
                icon: Icons.music_note_outlined,
                onPressed: () {},
              ),
              PlayerOsdButton(
                tooltip: l10n.playerSubtitles,
                icon: Icons.closed_caption_outlined,
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    ),
  ),
);
