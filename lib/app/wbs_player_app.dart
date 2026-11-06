import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/servers/models/emby_media.dart';
import '../features/servers/models/emby_server.dart';
import '../features/servers/repositories/drift_server_repository.dart';
import '../features/servers/repositories/server_repository.dart';
import '../features/servers/services/emby_library_service.dart';
import '../features/servers/services/emby_server_service.dart';
import '../features/servers/views/emby_home_page.dart';
import '../features/servers/views/emby_library_page.dart';
import '../features/servers/views/emby_media_detail_page.dart';
import '../features/servers/views/server_home_page.dart';
import '../l10n/app_localizations_context.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/core/app_colors.dart';
import 'locale_preference.dart';
import 'locale_preference_store.dart';

class _LibraryRouteArgs {
  const _LibraryRouteArgs({required this.server, required this.library});

  final EmbyServer server;
  final EmbyLibrary library;
}

class _MediaRouteArgs {
  const _MediaRouteArgs({
    required this.server,
    required this.userId,
    required this.itemId,
    this.library,
  });

  final EmbyServer server;
  final String userId;
  final String itemId;
  final EmbyLibrary? library;
}

String _mediaDetailText(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'mediaDetailRetry' => l10n.mediaDetailRetry,
    'mediaDetailLoading' => l10n.mediaDetailLoading,
    'mediaDetailLoadFailed' => l10n.mediaDetailLoadFailed,
    'mediaDetailPlaybackFailed' => l10n.mediaDetailPlaybackFailed,
    'mediaDetailNoOverview' => l10n.mediaDetailNoOverview,
    'mediaDetailPlay' => l10n.mediaDetailPlay,
    'mediaDetailPlaybackUnavailable' => l10n.mediaDetailPlaybackUnavailable,
    'mediaDetailNoStreams' => l10n.mediaDetailNoStreams,
    'mediaDetailChooseVersion' => l10n.mediaDetailChooseVersion,
    'mediaDetailUnknownVersion' => l10n.mediaDetailUnknownVersion,
    'mediaDetailChooseAudio' => l10n.mediaDetailChooseAudio,
    'mediaDetailUnknownAudio' => l10n.mediaDetailUnknownAudio,
    'mediaDetailDurationMinutes' => l10n.mediaDetailDurationMinutes(
      '{minutes}',
    ),
    'mediaDetailDurationHoursMinutes' => l10n.mediaDetailDurationHoursMinutes(
      '{hours}',
      '{minutes}',
    ),
    'mediaDetailCast' => l10n.mediaDetailCast,
    'mediaDetailNoPeople' => l10n.mediaDetailNoPeople,
    'mediaDetailDirector' => l10n.mediaDetailDirector,
    'mediaDetailWriter' => l10n.mediaDetailWriter,
    'mediaDetailCrew' => l10n.mediaDetailCrew,
    'mediaDetailPhotos' => l10n.mediaDetailPhotos,
    'mediaDetailNoImages' => l10n.mediaDetailNoImages,
    'mediaDetailSimilar' => l10n.mediaDetailSimilar,
    'mediaDetailNoSimilar' => l10n.mediaDetailNoSimilar,
    'mediaDetailStudios' => l10n.mediaDetailStudios,
    'mediaDetailNoStudio' => l10n.mediaDetailNoStudio,
    'mediaDetailExternalLinks' => l10n.mediaDetailExternalLinks,
    'mediaDetailNoExternalLinks' => l10n.mediaDetailNoExternalLinks,
    'mediaDetailTechnicalInfo' => l10n.mediaDetailTechnicalInfo,
    'mediaDetailVersion' => l10n.mediaDetailVersion,
    'mediaDetailTechContainer' => l10n.mediaDetailTechContainer,
    'mediaDetailTechSize' => l10n.mediaDetailTechSize,
    'mediaDetailTechBitrate' => l10n.mediaDetailTechBitrate,
    'mediaDetailTechVideo' => l10n.mediaDetailTechVideo,
    'mediaDetailTechAudio' => l10n.mediaDetailTechAudio,
    'mediaDetailResolution' => l10n.mediaDetailResolution,
    'mediaDetailFrameRate' => l10n.mediaDetailFrameRate,
    'mediaDetailVideoRange' => l10n.mediaDetailVideoRange,
    'mediaDetailColorSpace' => l10n.mediaDetailColorSpace,
    'mediaDetailColorTransfer' => l10n.mediaDetailColorTransfer,
    'mediaDetailStreamDefault' => l10n.mediaDetailStreamDefault,
    'mediaDetailStreamForced' => l10n.mediaDetailStreamForced,
    'mediaDetailStreamExternal' => l10n.mediaDetailStreamExternal,
    'mediaDetailAddFavorite' => l10n.mediaDetailAddFavorite,
    'mediaDetailRemoveFavorite' => l10n.mediaDetailRemoveFavorite,
    'mediaDetailFavoriteFailed' => l10n.mediaDetailFavoriteFailed,
    _ => key,
  };
}

Locale _resolveSupportedLocaleList(List<Locale>? locales) {
  for (final locale in locales ?? const <Locale>[]) {
    if (locale.languageCode == 'zh' || locale.languageCode == 'en') {
      return Locale(locale.languageCode);
    }
  }
  return const Locale('zh');
}

class WbsPlayerApp extends StatefulWidget {
  const WbsPlayerApp({
    super.key,
    this.serverService,
    this.serverRepository,
    this.libraryService,
    this.localePreferenceStore,
  });

  final EmbyServerService? serverService;
  final ServerRepository? serverRepository;
  final EmbyLibraryService? libraryService;
  final LocalePreferenceStore? localePreferenceStore;

  @override
  State<WbsPlayerApp> createState() => _WbsPlayerAppState();
}

class _WbsPlayerAppState extends State<WbsPlayerApp> {
  late final LocalePreferenceStore _localePreferenceStore;
  LocalePreference _localePreference = LocalePreference.system;
  bool _isLocaleLoaded = false;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _localePreferenceNotifier = ValueNotifier(LocalePreference.system);
  final _localeLoadedNotifier = ValueNotifier(false);
  late final EmbyServerService _serverService =
      widget.serverService ?? EmbyServerService();
  late final bool _ownsServerService = widget.serverService == null;
  late final EmbyLibraryService _libraryService =
      widget.libraryService ?? EmbyLibraryService();
  late final bool _ownsLibraryService = widget.libraryService == null;
  late final ServerRepository _serverRepository =
      widget.serverRepository ?? DriftServerRepository();
  late final bool _ownsServerRepository = widget.serverRepository == null;
  late final Listenable _serverHomeRefresh = Listenable.merge([
    _localePreferenceNotifier,
    _localeLoadedNotifier,
  ]);
  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => ListenableBuilder(
          listenable: _serverHomeRefresh,
          builder: (context, child) => ServerHomePage(
            serverService: _serverService,
            serverRepository: _serverRepository,
            onServerSelected: (server) => context.push(
              '/server/${server.localId ?? Uri.encodeComponent(server.serverId)}',
              extra: server,
            ),
            onLocalePreferenceSelected: _setLocalePreference,
            localePreference: _localePreference,
            isLocaleLoaded: _isLocaleLoaded,
            localePreferenceListenable: _localePreferenceNotifier,
            localeLoadedListenable: _localeLoadedNotifier,
          ),
        ),
        routes: [
          GoRoute(
            path: 'server/:serverId',
            builder: (context, state) => FutureBuilder<EmbyServer?>(
              future: _resolveServer(state),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final server = snapshot.data;
                if (server == null) {
                  return Scaffold(
                    body: Center(child: Text(context.l10n.homeLoadFailed)),
                  );
                }
                final serverPath =
                    '/server/${state.pathParameters['serverId']}';
                return EmbyHomePage(
                  server: server,
                  serverService: _serverService,
                  serverRepository: _serverRepository,
                  libraryService: _libraryService,
                  onLibrarySelected:
                      (library, {required userId, required accessToken}) {
                        context.push(
                          '$serverPath/library/${Uri.encodeComponent(library.id)}',
                          extra: _LibraryRouteArgs(
                            server: server.copyWith(
                              userId: userId,
                              accessToken: accessToken,
                            ),
                            library: library,
                          ),
                        );
                      },
                  onMediaSelected:
                      (item, {required userId, required accessToken}) {
                        context.push(
                          '$serverPath/item/${Uri.encodeComponent(item.id)}',
                          extra: _MediaRouteArgs(
                            server: server.copyWith(
                              userId: userId,
                              accessToken: accessToken,
                            ),
                            userId: userId,
                            itemId: item.id,
                          ),
                        );
                      },
                );
              },
            ),
            routes: [
              GoRoute(
                path: 'library/:libraryId',
                builder: (context, state) => FutureBuilder<_LibraryRouteArgs?>(
                  future: _resolveLibraryRoute(state),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final args = snapshot.data;
                    if (args == null) {
                      return Scaffold(
                        body: Center(child: Text(context.l10n.homeLoadFailed)),
                      );
                    }
                    final serverPath =
                        '/server/${state.pathParameters['serverId']}';
                    return EmbyLibraryPage(
                      library: args.library,
                      server: args.server,
                      serverService: _serverService,
                      serverRepository: _serverRepository,
                      libraryService: _libraryService,
                      onMediaSelected:
                          (item, {required userId, required accessToken}) {
                            context.push(
                              '$serverPath/item/${Uri.encodeComponent(item.id)}',
                              extra: _MediaRouteArgs(
                                server: args.server.copyWith(
                                  userId: userId,
                                  accessToken: accessToken,
                                ),
                                userId: userId,
                                itemId: item.id,
                                library: args.library,
                              ),
                            );
                          },
                    );
                  },
                ),
              ),
              GoRoute(
                path: 'item/:itemId',
                builder: (context, state) => FutureBuilder<_MediaRouteArgs?>(
                  future: _resolveMediaRoute(state),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final args = snapshot.data;
                    if (args == null) {
                      return Scaffold(
                        body: Center(child: Text(context.l10n.homeLoadFailed)),
                      );
                    }
                    final serverPath =
                        '/server/${state.pathParameters['serverId']}';
                    return EmbyMediaDetailPage(
                      server: args.server,
                      userId: args.userId,
                      itemId: args.itemId,
                      libraryService: _libraryService,
                      text: (key) => _mediaDetailText(context, key),
                      onSimilarTap: (item) {
                        context.push(
                          '$serverPath/item/${Uri.encodeComponent(item.id)}',
                          extra: _MediaRouteArgs(
                            server: args.server,
                            userId: args.userId,
                            itemId: item.id,
                            library: args.library,
                          ),
                        );
                      },
                      onExternalLinkTap: (link) {
                        final uri = link.uri;
                        if (uri != null) launchUrl(uri);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  Future<EmbyServer?> _resolveServer(GoRouterState state) async {
    final serverId = state.pathParameters['serverId'];
    if (serverId == null) return null;
    final extra = state.extra;
    final server = switch (extra) {
      EmbyServer value => value,
      _LibraryRouteArgs value => value.server,
      _MediaRouteArgs value => value.server,
      _ => null,
    };
    if (server != null) return server;
    final servers = await _serverRepository.getAllServers();
    for (final candidate in servers) {
      if ('${candidate.localId}' == serverId ||
          candidate.serverId == serverId) {
        return candidate;
      }
    }
    return null;
  }

  Future<_LibraryRouteArgs?> _resolveLibraryRoute(GoRouterState state) async {
    final extra = state.extra;
    if (extra is _LibraryRouteArgs) return extra;
    final server = await _resolveServer(state);
    final libraryId = state.pathParameters['libraryId'];
    if (server == null || libraryId == null) return null;
    final authentication = server.userId == null || server.userId!.isEmpty
        ? await _serverService.authenticateStoredUser(server)
        : null;
    final activeServer = authentication == null
        ? server
        : server.copyWith(
            userId: authentication.userId,
            accessToken: authentication.accessToken,
          );
    final userId = activeServer.userId;
    if (userId == null || userId.isEmpty) return null;
    final libraries = await _libraryService.loadLibraries(
      serverAddress: activeServer.address,
      accessToken: activeServer.accessToken,
      userId: userId,
    );
    for (final library in libraries) {
      if (library.id == libraryId) {
        return _LibraryRouteArgs(server: activeServer, library: library);
      }
    }
    return null;
  }

  Future<_MediaRouteArgs?> _resolveMediaRoute(GoRouterState state) async {
    final extra = state.extra;
    final itemId = state.pathParameters['itemId'];
    if (itemId == null) return null;
    if (extra is _MediaRouteArgs) return extra;
    final server = await _resolveServer(state);
    if (server == null) return null;
    final authentication = server.userId == null || server.userId!.isEmpty
        ? await _serverService.authenticateStoredUser(server)
        : null;
    final activeServer = authentication == null
        ? server
        : server.copyWith(
            userId: authentication.userId,
            accessToken: authentication.accessToken,
          );
    final userId = activeServer.userId;
    if (userId == null || userId.isEmpty) return null;
    return _MediaRouteArgs(
      server: activeServer,
      userId: userId,
      itemId: itemId,
    );
  }

  @override
  void initState() {
    super.initState();
    _localePreferenceStore =
        widget.localePreferenceStore ??
        SharedPreferencesLocalePreferenceStore();
    _loadLocalePreference();
  }

  Future<void> _loadLocalePreference() async {
    LocalePreference preference = LocalePreference.system;
    try {
      preference = LocalePreference.fromStoredValue(
        await _localePreferenceStore.read(),
      );
    } catch (_) {
      // Follow the device locale if preferences are unavailable.
    }
    if (!mounted) return;
    setState(() {
      _localePreference = preference;
      _isLocaleLoaded = true;
      _localePreferenceNotifier.value = preference;
      _localeLoadedNotifier.value = true;
    });
  }

  Future<void> _setLocalePreference(LocalePreference preference) async {
    final previous = _localePreference;
    setState(() => _localePreference = preference);
    _localePreferenceNotifier.value = preference;
    try {
      await _localePreferenceStore.write(preference.storedValue);
    } catch (_) {
      if (!mounted) return;
      setState(() => _localePreference = previous);
      _localePreferenceNotifier.value = previous;
      final previousLocale =
          previous.locale ?? WidgetsBinding.instance.platformDispatcher.locale;
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            lookupAppLocalizations(
              previousLocale.languageCode == 'en'
                  ? const Locale('en')
                  : const Locale('zh'),
            ).languageSaveFailed,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _router.dispose();
    _localePreferenceNotifier.dispose();
    _localeLoadedNotifier.dispose();
    if (_ownsServerService) _serverService.close();
    if (_ownsLibraryService) _libraryService.close();
    if (_ownsServerRepository) unawaited(_serverRepository.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      onGenerateTitle: (context) => context.l10n.appTitle,
      locale: _localePreference.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      localeListResolutionCallback: (locales, supportedLocales) =>
          _resolveSupportedLocaleList(locales),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.pageBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          surface: AppColors.pageBackground,
          primary: AppColors.navy,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.pageBackground,
          foregroundColor: AppColors.ink,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
    );
  }
}
