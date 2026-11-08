import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wbs_player/features/player/widgets/player_status_bar.dart';

void main() {
  testWidgets('shows local time and stream load speed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerStatusBar(
            time: DateTime(2026, 11, 8, 9, 7),
            streamLoadBytesPerSecond: 2500000,
          ),
        ),
      ),
    );

    expect(find.text('09:07'), findsOneWidget);
    expect(find.text('20.0 Mbps'), findsOneWidget);
  });

  testWidgets('shows a placeholder when the stream rate is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerStatusBar(
            time: DateTime(2026, 11, 8, 21, 5),
            streamLoadBytesPerSecond: null,
          ),
        ),
      ),
    );

    expect(find.text('21:05'), findsOneWidget);
    expect(find.text('\u2014'), findsOneWidget);
  });
}
