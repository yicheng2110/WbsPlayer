import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:wbs_player/features/player/models/hardware_decoder_mode.dart';
import 'package:wbs_player/features/player/models/player_session_state.dart';
import 'package:wbs_player/features/player/widgets/player_gesture_layer.dart';
import 'package:wbs_player/features/player/widgets/player_osd_controls.dart';
import 'package:wbs_player/features/player/widgets/player_track_sheet.dart';
import 'package:wbs_player/l10n/generated/app_localizations.dart';

void main() {
  for (final size in [
    const Size(393, 852),
    const Size(852, 393),
    const Size(1280, 720),
    const Size(280, 640),
    const Size(640, 280),
  ]) {
    testWidgets('keeps controls reachable at $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _player(
          state: const PlayerSessionState(duration: Duration(hours: 2)),
          onRateChanged: (_) {},
          onFit: () {},
          onRotate: () {},
          canPlayNext: true,
        ),
      );
      expect(tester.takeException(), isNull);
      final title = tester.getRect(find.byKey(const Key('player-title')));
      final play = tester.getRect(find.byKey(const Key('player-play-pause')));
      final slider = tester.getRect(find.byKey(const Key('player-progress')));
      expect(title.top, greaterThan(size.height / 2));
      expect(play.top, greaterThan(slider.top));
      for (final key in [
        'player-play-pause',
        'player-lock',
        'player-audio',
        'player-subtitles',
        'player-more',
        'player-rotate',
      ]) {
        final rect = tester.getRect(find.byKey(Key(key)));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
    });
  }

  testWidgets('fits safe areas and large text in a narrow viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _player(
        textScale: 2,
        safeInsets: const EdgeInsets.fromLTRB(0, 28, 0, 24),
        state: const PlayerSessionState(duration: Duration(hours: 12)),
        onRateChanged: (_) {},
        onFit: () {},
        canPlayNext: true,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byKey(const Key('player-more'))).top,
      greaterThanOrEqualTo(28),
    );
    expect(
      tester.getRect(find.byKey(const Key('player-play-pause'))).bottom,
      lessThanOrEqualTo(616),
    );
  });

  testWidgets('track sections isolate audio and subtitle selection', (
    tester,
  ) async {
    const audio = AudioTrack('1', 'English audio', 'en');
    const subtitle = SubtitleTrack('2', 'Chinese subtitles', 'zh');
    const tracks = Tracks(audio: [audio], subtitle: [subtitle]);
    AudioTrack? selectedAudio;
    SubtitleTrack? selectedSubtitle;
    Widget sheet(PlayerTrackSection section) => MaterialApp(
      home: Scaffold(
        body: PlayerTrackSheet(
          section: section,
          tracks: tracks,
          selectedAudio: null,
          selectedSubtitle: null,
          onAudioSelected: (track) => selectedAudio = track,
          onSubtitleSelected: (track) => selectedSubtitle = track,
          onRateSelected: (_) {},
        ),
      ),
    );
    await tester.pumpWidget(sheet(PlayerTrackSection.audio));
    expect(find.text('English audio'), findsOneWidget);
    expect(find.text('Chinese subtitles'), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
    await tester.tap(find.text('English audio'));
    expect(selectedAudio, audio);
    await tester.pumpWidget(sheet(PlayerTrackSection.subtitles));
    expect(find.text('English audio'), findsNothing);
    expect(find.text('Chinese subtitles'), findsOneWidget);
    await tester.tap(find.text('Chinese subtitles'));
    expect(selectedSubtitle, subtitle);
  });

  testWidgets('routes separate track actions and adjusts speed within limits', (
    tester,
  ) async {
    var audio = 0;
    var subtitles = 0;
    double? rate;
    await tester.pumpWidget(
      _player(
        state: const PlayerSessionState(rate: 1.25),
        onAudio: () => audio++,
        onSubtitles: () => subtitles++,
        onRateChanged: (value) => rate = value,
      ),
    );
    await tester.tap(find.byKey(const Key('player-audio')));
    await tester.tap(find.byKey(const Key('player-subtitles')));
    await tester.tap(find.byKey(const Key('player-speed-increase')));
    expect(audio, 1);
    expect(subtitles, 1);
    expect(rate, 1.5);
    await tester.tap(find.byKey(const Key('player-speed-decrease')));
    expect(rate, 1);
    expect(find.text('1.25x'), findsOneWidget);
    await tester.pumpWidget(
      _player(
        state: const PlayerSessionState(rate: 2),
        onRateChanged: (value) => rate = value,
      ),
    );
    rate = null;
    await tester.tap(find.byKey(const Key('player-speed-increase')));
    expect(rate, isNull);
  });

  testWidgets('rotates through the control and hides it when locked', (
    tester,
  ) async {
    var rotations = 0;
    await tester.pumpWidget(_player(onRotate: () => rotations++));
    expect(find.byTooltip('Switch to landscape'), findsOneWidget);
    await tester.tap(find.byKey(const Key('player-rotate')));
    expect(rotations, 1);
    await tester.tap(find.byKey(const Key('player-lock')));
    await tester.pump();
    expect(find.byKey(const Key('player-rotate')), findsNothing);
  });

  testWidgets('cycles the decoder mode in the displayed order', (tester) async {
    final changes = <HardwareDecoderMode>[];
    var current = HardwareDecoderMode.software;
    await tester.pumpWidget(
      _player(
        decoderMode: current,
        onDecoderModeChanged: (mode) => changes.add(mode),
      ),
    );

    for (final next in [
      HardwareDecoderMode.hardwareSafe,
      HardwareDecoderMode.hardwareAuto,
      HardwareDecoderMode.software,
    ]) {
      expect(find.text(current.label), findsOneWidget);
      await tester.tap(find.byKey(const Key('player-decoder')));
      expect(changes.last, next);
      current = next;
      await tester.pumpWidget(
        _player(
          decoderMode: current,
          onDecoderModeChanged: (mode) => changes.add(mode),
        ),
      );
    }
  });

  testWidgets('locks controls and keeps unlock reachable after auto-hide', (
    tester,
  ) async {
    final key = GlobalKey<PlayerOsdControlsState>();
    bool? locked;
    await tester.pumpWidget(
      _player(
        osdKey: key,
        state: const PlayerSessionState(isPlaying: true),
        onLockChanged: (value) => locked = value,
      ),
    );
    await tester.tap(find.byKey(const Key('player-lock')));
    await tester.pump();
    expect(locked, isTrue);
    expect(key.currentState!.isLocked, isTrue);
    expect(find.byKey(const Key('player-play-pause')), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    expect(key.currentState!.isVisible, isFalse);
    key.currentState!.showControls();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('player-lock')));
    await tester.pump();
    expect(locked, isFalse);
    expect(find.byKey(const Key('player-play-pause')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('keeps controls visible while a track sheet is open', (
    tester,
  ) async {
    final key = GlobalKey<PlayerOsdControlsState>();
    final closed = Completer<void>();
    await tester.pumpWidget(
      _player(
        osdKey: key,
        state: const PlayerSessionState(isPlaying: true),
        onAudio: () => closed.future,
      ),
    );
    await tester.tap(find.byKey(const Key('player-audio')));
    await tester.pump(const Duration(seconds: 5));
    expect(key.currentState!.isVisible, isTrue);
    closed.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(key.currentState!.isVisible, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('holds auto-hide during scrubbing and seeks on release', (
    tester,
  ) async {
    final key = GlobalKey<PlayerOsdControlsState>();
    Duration? target;
    await tester.pumpWidget(
      _player(
        osdKey: key,
        state: const PlayerSessionState(
          isPlaying: true,
          duration: Duration(minutes: 10),
        ),
        onSeek: (value) => target = value,
      ),
    );
    final slider = tester.getRect(find.byKey(const Key('player-progress')));
    final gesture = await tester.startGesture(
      slider.centerLeft + const Offset(24, 0),
    );
    await gesture.moveTo(slider.center);
    await tester.pump(const Duration(seconds: 4));
    expect(key.currentState!.isVisible, isTrue);
    await gesture.up();
    await tester.pump();
    expect(target, isNotNull);
    expect(target!.inSeconds, inInclusiveRange(240, 360));
    await tester.pump(const Duration(seconds: 3));
    expect(key.currentState!.isVisible, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('holds auto-hide while the video gesture is active', (
    tester,
  ) async {
    final key = GlobalKey<PlayerOsdControlsState>();
    await tester.pumpWidget(
      _player(osdKey: key, state: const PlayerSessionState(isPlaying: true)),
    );
    key.currentState!.setGestureActive(true);
    await tester.pump(const Duration(seconds: 4));
    expect(key.currentState!.isVisible, isTrue);
    key.currentState!.setGestureActive(false);
    await tester.pump(const Duration(seconds: 3));
    expect(key.currentState!.isVisible, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('opens localized overflow menu without hiding controls', (
    tester,
  ) async {
    final key = GlobalKey<PlayerOsdControlsState>();
    var stats = 0;
    await tester.pumpWidget(
      _player(
        osdKey: key,
        locale: const Locale('zh'),
        state: const PlayerSessionState(isPlaying: true),
        onStats: () => stats++,
      ),
    );
    await tester.tap(find.byKey(const Key('player-more')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 4));
    expect(key.currentState!.isVisible, isTrue);
    expect(find.text('播放统计'), findsOneWidget);
    await tester.tap(find.text('播放统计'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(stats, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'locked gesture surface allows reveal but blocks playback and seek',
    (tester) async {
      var taps = 0;
      var doubleTaps = 0;
      var seeks = 0;
      var volumeChanges = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerGestureLayer(
            locked: true,
            duration: const Duration(minutes: 5),
            position: Duration.zero,
            volume: 100,
            onSeek: (_) => seeks++,
            onVolumeChanged: (_) => volumeChanges++,
            onTap: () => taps++,
            onDoubleTap: () => doubleTaps++,
          ),
        ),
      );
      await tester.tapAt(const Offset(200, 200));
      await tester.pump(const Duration(milliseconds: 350));
      expect(taps, 1);
      await tester.tapAt(const Offset(200, 200));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(const Offset(200, 200));
      await tester.dragFrom(const Offset(100, 200), const Offset(300, 0));
      await tester.dragFrom(const Offset(600, 200), const Offset(0, -100));
      expect(doubleTaps, 0);
      expect(seeks, 0);
      expect(volumeChanges, 0);
    },
  );

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

Widget _player({
  GlobalKey<PlayerOsdControlsState>? osdKey,
  PlayerSessionState state = const PlayerSessionState(),
  FutureOr<void> Function()? onAudio,
  FutureOr<void> Function()? onSubtitles,
  ValueChanged<double>? onRateChanged,
  ValueChanged<bool>? onLockChanged,
  ValueChanged<Duration>? onSeek,
  VoidCallback? onFit,
  FutureOr<void> Function()? onRotate,
  HardwareDecoderMode decoderMode = HardwareDecoderMode.hardwareSafe,
  ValueChanged<HardwareDecoderMode>? onDecoderModeChanged,
  VoidCallback? onStats,
  bool canPlayNext = false,
  Locale locale = const Locale('en'),
  double textScale = 1,
  EdgeInsets safeInsets = EdgeInsets.zero,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale), padding: safeInsets),
    child: child!,
  ),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    backgroundColor: Colors.black,
    body: PlayerOsdControls(
      key: osdKey,
      title: 'Test movie with a long title that should truncate',
      state: state,
      onBack: () {},
      onPlayPause: () {},
      onSeek: onSeek ?? (_) {},
      onTracks: () {},
      onRetry: () {},
      onAudio: onAudio,
      onSubtitles: onSubtitles,
      onRateChanged: onRateChanged,
      onLockChanged: onLockChanged,
      onFit: onFit,
      onRotate: onRotate,
      decoderMode: decoderMode,
      onDecoderModeChanged: onDecoderModeChanged,
      onStats: onStats,
      canPlayNext: canPlayNext,
      onNext: () {},
    ),
  ),
);
