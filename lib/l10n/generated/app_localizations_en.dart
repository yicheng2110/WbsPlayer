// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wbs Player';

  @override
  String get serversTitle => 'Servers';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get moreOptions => 'More options';

  @override
  String get addServer => 'Add server';

  @override
  String get serverName => 'Server name';

  @override
  String get serverNameHint => 'For example: My Emby server';

  @override
  String get serverAddress => 'Server address';

  @override
  String get serverAddressHint => 'http://192.168.1.10:8096';

  @override
  String get serverAddressRequired => 'Enter a server address';

  @override
  String get serverAddressInvalid => 'Enter a valid server address';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get defaultServerName => 'Emby server';

  @override
  String get emptyServersMessage =>
      'Add an Emby server to begin your media journey!';

  @override
  String get serverConnectionComingSoon =>
      'Emby sign-in and connection will be added later';

  @override
  String get embySignInTitle => 'Sign in to Emby server';

  @override
  String get embyUsername => 'Username';

  @override
  String get embyUsernameRequired => 'Enter a username';

  @override
  String get embyPassword => 'Password';

  @override
  String get embySignIn => 'Sign in';

  @override
  String get embyInvalidCredentials => 'Incorrect username or password';

  @override
  String get embyConnectionFailed =>
      'Unable to connect. Check the server address and network.';

  @override
  String get embyLoginFailed => 'Sign-in failed. Please try again.';

  @override
  String get embyMediaBrowsingComingSoon =>
      'Media browsing will be added later';

  @override
  String get serverSaveFailed =>
      'Sign-in succeeded, but saving the server failed. Please retry.';

  @override
  String get serverLoadFailed => 'Failed to load the saved server list.';

  @override
  String get serverLoading => 'Loading servers…';

  @override
  String get languageSetting => 'Language';

  @override
  String get languageAuto => 'Auto';

  @override
  String get languageChinese => 'Simplified Chinese';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSaveFailed => 'Failed to save the language setting.';

  @override
  String get aggregationTab => 'Aggregate';
}
