import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/servers/models/emby_media.dart';
import '../features/servers/models/emby_media_detail.dart';
import '../features/servers/models/emby_server.dart';
import '../features/servers/repositories/drift_server_repository.dart';
import '../features/servers/repositories/server_repository.dart';
import '../features/servers/services/emby_library_service.dart';
import '../features/servers/services/emby_server_service.dart';
import '../features/servers/views/emby_home_page.dart';
import '../features/servers/views/emby_library_page.dart';
import '../features/servers/views/emby_media_detail_page.dart';
import '../features/servers/views/server_home_page.dart';
import '../features/servers/services/emby_media_detail_service.dart';
import '../features/player/models/player_preferences.dart';
import '../features/player/services/player_preferences_store.dart';
import '../features/player/views/player_page.dart';
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

String _playerText(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'playerBack' => l10n.playerBack,
    'playerTracks' => l10n.playerTracks,
    'playerAudio' => l10n.playerAudio,
    'playerSubtitles' => l10n.playerSubtitles,
    'playerSubtitlesOff' => l10n.playerSubtitlesOff,
    'playerSpeed' => l10n.playerSpeed,
    'playerSeek' => l10n.playerSeek,
    'playerBrightness' => l10n.playerBrightness,
    'playerVolume' => l10n.playerVolume,
    'playerPlay' => l10n.playerPlay,
    'playerPause' => l10n.playerPause,
    'playerBack10' => l10n.playerBack10,
    'playerForward10' => l10n.playerForward10,
    'playerRetry' => l10n.playerRetry,
    'playerPlaybackFailed' => l10n.playerPlaybackFailed,
    'playerMute' => l10n.playerMute,
    'playerQuality' => l10n.playerQuality,
    'playerQualityOriginal' => l10n.playerQualityOriginal,
    'playerQualityLimit' => l10n.playerQualityLimit,
    'playerSubtitleLanguage' => l10n.playerSubtitleLanguage,
    'playerSubtitleSize' => l10n.playerSubtitleSize,
    'playerAudioPassthrough' => l10n.playerAudioPassthrough,
    'playerHardwareAcceleration' => l10n.playerHardwareAcceleration,
    'playerNextEpisode' => l10n.playerNextEpisode,
    'playerStats' => l10n.playerStats,
    'playerExternalSubtitles' => l10n.playerExternalSubtitles,
    'playerRetrying' => l10n.playerRetrying,
    'playerSubtitleJapanese' => l10n.playerSubtitleJapanese,
    'playerNoPlayableUrl' => l10n.playerNoPlayableUrl,
    'playerInvalidPlaybackUrl' => l10n.playerInvalidPlaybackUrl,
    'playerNetworkError' => l10n.playerNetworkError,
    'playerPlaybackTimeout' => l10n.playerPlaybackTimeout,
    'playerRequestFailed' => l10n.playerRequestFailed,
    'playerSubtitleUnsupported' => l10n.playerSubtitleUnsupported,
    'playerInvalidPlaybackResponse' => l10n.playerInvalidPlaybackResponse,
    'playerStatsVideo' => l10n.playerStatsVideo,
    'playerStatsAudio' => l10n.playerStatsAudio,
    'playerStatsBuffer' => l10n.playerStatsBuffer,
    'playerStatsVolume' => l10n.playerStatsVolume,
    'playerStatsMethod' => l10n.playerStatsMethod,
    _ => key,
  };
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
    'mediaDetailSeasons' => l10n.mediaDetailSeasons,
    'mediaDetailNoSeasons' => l10n.mediaDetailNoSeasons,
    'mediaDetailSeasonNumber' =>
      l10n.mediaDetailSeasonNumber(0).replaceAll('0', '{number}'),
    'mediaDetailEpisodeNumber' =>
      l10n.mediaDetailEpisodeNumber(0).replaceAll('0', '{number}'),
    'mediaDetailEpisodeCount' =>
      l10n.mediaDetailEpisodeCount(0).replaceAll('0', '{count}'),
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
    this.playerPreferencesStore,
  });

  final EmbyServerService? serverService;
  final ServerRepository? serverRepository;
  final EmbyLibraryService? libraryService;
  final LocalePreferenceStore? localePreferenceStore;
  final PlayerPreferencesStore? playerPreferencesStore;

  @override
  State<WbsPlayerApp> createState() => _WbsPlayerAppState();
}

class _WbsPlayerAppState extends State<WbsPlayerApp> {
  late final LocalePreferenceStore _localePreferenceStore;
  LocalePreference _localePreference = LocalePreference.system;
  bool _isLocaleLoaded = false;
  PlayerPreferences _playerPreferences = const PlayerPreferences();
  bool _arePlayerPreferencesLoaded = false;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _localePreferenceNotifier = ValueNotifier(LocalePreference.system);
  final _localeLoadedNotifier = ValueNotifier(false);
  final _playerPreferencesNotifier = ValueNotifier(const PlayerPreferences());
  final _playerPreferencesLoadedNotifier = ValueNotifier(false);
  late final PlayerPreferencesStore _playerPreferencesStore;
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
    _playerPreferencesNotifier,
    _playerPreferencesLoadedNotifier,
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
            playerPreferences: _playerPreferences,
            arePlayerPreferencesLoaded: _arePlayerPreferencesLoaded,
            onPlayerPreferencesChanged: _setPlayerPreferences,
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
                path: 'play/:itemId',
                builder: (context, state) => FutureBuilder<PlayerPageArgs?>(
                  future: _resolvePlayerRoute(state, context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Scaffold(
                        backgroundColor: Colors.black,
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final args = snapshot.data;
                    if (args == null) {
                      return Scaffold(
                        backgroundColor: Colors.black,
                        body: Center(child: Text(context.l10n.homeLoadFailed)),
                      );
                    }
                    return PlayerPage(key: ValueKey(args.itemId), args: args);
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
                      playbackDelegate:
                          ({
                            required detail,
                            required mediaSource,
                            audioStream,
                          }) async {
                            await context.push<void>(
                              '$serverPath/play/${Uri.encodeComponent(args.itemId)}',
                              extra: PlayerPageArgs(
                                serverAddress: args.server.address,
                                accessToken: args.server.accessToken,
                                userId: args.userId,
                                itemId: args.itemId,
                                detail: detail,
                                mediaSource: mediaSource,
                                audioStream: audioStream,
                                preferences: _playerPreferences,
                                nextEpisodeLoader:
                                    detail.type.toLowerCase() == 'episode' &&
                                        detail.seriesId != null
                                    ? () => _loadNextEpisodeArgs(
                                        context: context,
                                        serverPath: serverPath,
                                        server: args.server,
                                        userId: args.userId,
                                        current: detail,
                                      )
                                    : null,
                                onNextEpisode: (next) =>
                                    context.pushReplacement<void>(
                                      '$serverPath/play/${Uri.encodeComponent(next.itemId)}',
                                      extra: next,
                                    ),
                                title: detail.name,
                                text: (key) => _playerText(context, key),
                              ),
                            );
                          },
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

  Future<PlayerPageArgs?> _resolvePlayerRoute(
    GoRouterState state,
    BuildContext context,
  ) async {
    if (state.extra case final PlayerPageArgs args) return args;
    final route = await _resolveMediaRoute(state);
    if (route == null) return null;
    final detailService = EmbyMediaDetailService();
    try {
      final detail = await detailService.getDetail(
        serverAddress: route.server.address,
        accessToken: route.server.accessToken,
        userId: route.userId,
        itemId: route.itemId,
        forceRefresh: true,
      );
      final sources = detail.mediaSources.isNotEmpty
          ? detail.mediaSources
          : await detailService.getMediaSources(
              serverAddress: route.server.address,
              accessToken: route.server.accessToken,
              userId: route.userId,
              itemId: route.itemId,
              forceRefresh: true,
            );
      if (sources.isEmpty) return null;
      final serverPath = '/server/${state.pathParameters['serverId']}';
      return PlayerPageArgs(
        serverAddress: route.server.address,
        accessToken: route.server.accessToken,
        userId: route.userId,
        itemId: route.itemId,
        detail: detail,
        mediaSource: sources.first,
        preferences: _playerPreferences,
        title: detail.name,
        text: (key) => _playerText(context, key),
        nextEpisodeLoader:
            detail.type.toLowerCase() == 'episode' && detail.seriesId != null
            ? () => _loadNextEpisodeArgs(
                context: context,
                serverPath: serverPath,
                server: route.server,
                userId: route.userId,
                current: detail,
              )
            : null,
        onNextEpisode: (next) => context.pushReplacement<void>(
          '$serverPath/play/${Uri.encodeComponent(next.itemId)}',
          extra: next,
        ),
      );
    } catch (_) {
      return null;
    } finally {
      detailService.close();
    }
  }

  Future<PlayerPageArgs?> _loadNextEpisodeArgs({
    required BuildContext context,
    required String serverPath,
    required EmbyServer server,
    required String userId,
    required EmbyMediaDetail current,
  }) async {
    final detailService = EmbyMediaDetailService();
    try {
      final episode = await detailService.getNextEpisode(
        serverAddress: server.address,
        accessToken: server.accessToken,
        userId: userId,
        seriesId: current.seriesId!,
        episodeId: current.id,
      );
      if (episode == null) return null;
      final sources = episode.mediaSources.isNotEmpty
          ? episode.mediaSources
          : await detailService.getMediaSources(
              serverAddress: server.address,
              accessToken: server.accessToken,
              userId: userId,
              itemId: episode.id,
              forceRefresh: true,
            );
      if (sources.isEmpty) return null;
      return PlayerPageArgs(
        serverAddress: server.address,
        accessToken: server.accessToken,
        userId: userId,
        itemId: episode.id,
        detail: episode,
        mediaSource: sources.first,
        preferences: _playerPreferences,
        title: episode.name,
        text: (key) => _playerText(context, key),
        nextEpisodeLoader: () => _loadNextEpisodeArgs(
          context: context,
          serverPath: serverPath,
          server: server,
          userId: userId,
          current: episode,
        ),
        onNextEpisode: (next) => context.pushReplacement<void>(
          '$serverPath/play/${Uri.encodeComponent(next.itemId)}',
          extra: next,
        ),
      );
    } finally {
      detailService.close();
    }
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
    _playerPreferencesStore =
        widget.playerPreferencesStore ??
        SharedPreferencesPlayerPreferencesStore();
    _loadLocalePreference();
    _loadPlayerPreferences();
  }

  Future<void> _loadPlayerPreferences() async {
    PlayerPreferences preferences;
    try {
      preferences = await _playerPreferencesStore.read();
    } catch (_) {
      preferences = const PlayerPreferences();
    }
    if (!mounted) return;
    setState(() {
      _playerPreferences = preferences;
      _arePlayerPreferencesLoaded = true;
      _playerPreferencesNotifier.value = preferences;
      _playerPreferencesLoadedNotifier.value = true;
    });
  }

  Future<void> _setPlayerPreferences(PlayerPreferences preferences) async {
    final previous = _playerPreferences;
    setState(() => _playerPreferences = preferences);
    _playerPreferencesNotifier.value = preferences;
    try {
      await _playerPreferencesStore.write(preferences);
    } catch (_) {
      if (!mounted) return;
      setState(() => _playerPreferences = previous);
      _playerPreferencesNotifier.value = previous;
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(context.l10n.playerSettingsSaveFailed)),
      );
    }
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
    _playerPreferencesNotifier.dispose();
    _playerPreferencesLoadedNotifier.dispose();
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
