import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wbs_player/features/servers/models/emby_library_preferences.dart';
import 'package:wbs_player/features/servers/models/emby_media.dart';
import 'package:wbs_player/features/servers/views/emby_library_management_page.dart';
import 'package:wbs_player/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('updates visibility and saves settings before leaving', (
    tester,
  ) async {
    final saved = <EmbyLibraryPreferences>[];
    final router = GoRouter(
      initialLocation: '/manage',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
          routes: [
            GoRoute(
              path: 'manage',
              builder: (context, state) => EmbyLibraryManagementPage(
                libraries: const [
                  EmbyLibrary(id: 'a', name: 'A'),
                  EmbyLibrary(id: 'b', name: 'B'),
                ],
                initialPreferences: const EmbyLibraryPreferences(
                  order: ['b', 'a'],
                ),
                onPreferencesChanged: (value) async => saved.add(value),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    );
    await tester.pump();

    expect(find.text('B'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('library-home-switch-b')));
    await tester.pump();

    expect(saved, hasLength(1));
    expect(saved.single.isVisibleOnHome('b'), isFalse);
    await tester.tap(find.byKey(const Key('library-management-done')));
    await tester.pump();
    expect(find.text('Home'), findsOneWidget);
  });
}
