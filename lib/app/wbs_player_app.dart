import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/servers/repositories/server_repository.dart';
import '../features/servers/services/emby_server_service.dart';
import '../features/servers/views/server_home_page.dart';
import '../l10n/app_localizations_context.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/core/app_colors.dart';
import 'locale_preference.dart';
import 'locale_preference_store.dart';

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
    this.localePreferenceStore,
  });

  final EmbyServerService? serverService;
  final ServerRepository? serverRepository;
  final LocalePreferenceStore? localePreferenceStore;

  @override
  State<WbsPlayerApp> createState() => _WbsPlayerAppState();
}

class _WbsPlayerAppState extends State<WbsPlayerApp> {
  late final LocalePreferenceStore _localePreferenceStore;
  LocalePreference _localePreference = LocalePreference.system;
  bool _isLocaleLoaded = false;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
    });
  }

  Future<void> _setLocalePreference(LocalePreference preference) async {
    final previous = _localePreference;
    setState(() => _localePreference = preference);
    try {
      await _localePreferenceStore.write(preference.storedValue);
    } catch (_) {
      if (!mounted) return;
      setState(() => _localePreference = previous);
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
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: ServerHomePage(
        serverService: widget.serverService,
        serverRepository: widget.serverRepository,
        onLocalePreferenceSelected: _setLocalePreference,
        localePreference: _localePreference,
        isLocaleLoaded: _isLocaleLoaded,
      ),
    );
  }
}
