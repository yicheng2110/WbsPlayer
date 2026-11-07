import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wbs_player/features/player/models/player_session_state.dart';
import 'package:wbs_player/features/player/widgets/player_osd_controls.dart';

void main() {
  testWidgets('auto-hides after three seconds and stays visible while paused', (
    tester,
  ) async {
    final key = GlobalKey<PlayerOsdControlsState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerOsdControls(
            key: key,
            title: 'Test movie',
            state: const PlayerSessionState(isPlaying: true),
            onBack: () {},
            onPlayPause: () {},
            onSeek: (_) {},
            onTracks: () {},
            onRetry: () {},
          ),
        ),
      ),
    );
    expect(key.currentState!.isVisible, isTrue);

    await tester.pump(const Duration(seconds: 3));
    expect(key.currentState!.isVisible, isFalse);

    key.currentState!.showControls();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(key.currentState!.isVisible, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerOsdControls(
            key: key,
            title: 'Test movie',
            state: const PlayerSessionState(isPlaying: false),
            onBack: () {},
            onPlayPause: () {},
            onSeek: (_) {},
            onTracks: () {},
            onRetry: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 4));
    expect(key.currentState!.isVisible, isTrue);
  });
}
