import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'Wbs Player'**
  String get appTitle;

  /// No description provided for @serversTitle.
  ///
  /// In zh, this message translates to:
  /// **'服务器'**
  String get serversTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @moreOptions.
  ///
  /// In zh, this message translates to:
  /// **'更多选项'**
  String get moreOptions;

  /// No description provided for @addServer.
  ///
  /// In zh, this message translates to:
  /// **'添加服务器'**
  String get addServer;

  /// No description provided for @serverName.
  ///
  /// In zh, this message translates to:
  /// **'服务器名称'**
  String get serverName;

  /// No description provided for @serverNameHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：家里的 Emby'**
  String get serverNameHint;

  /// No description provided for @serverAddress.
  ///
  /// In zh, this message translates to:
  /// **'服务器地址'**
  String get serverAddress;

  /// No description provided for @serverAddressHint.
  ///
  /// In zh, this message translates to:
  /// **'http://192.168.1.10:8096'**
  String get serverAddressHint;

  /// No description provided for @serverAddressRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入服务器地址'**
  String get serverAddressRequired;

  /// No description provided for @serverAddressInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的服务器地址'**
  String get serverAddressInvalid;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get add;

  /// No description provided for @defaultServerName.
  ///
  /// In zh, this message translates to:
  /// **'Emby 服务器'**
  String get defaultServerName;

  /// No description provided for @emptyServersMessage.
  ///
  /// In zh, this message translates to:
  /// **'马上添加 Emby 服务器，以开始您的媒体之旅！'**
  String get emptyServersMessage;

  /// No description provided for @serverConnectionComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'Emby 登录与连接功能后续接入'**
  String get serverConnectionComingSoon;

  /// No description provided for @embySignInTitle.
  ///
  /// In zh, this message translates to:
  /// **'登录 Emby 服务器'**
  String get embySignInTitle;

  /// No description provided for @embyUsername.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get embyUsername;

  /// No description provided for @embyUsernameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入用户名'**
  String get embyUsernameRequired;

  /// No description provided for @embyPassword.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get embyPassword;

  /// No description provided for @embySignIn.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get embySignIn;

  /// No description provided for @embyInvalidCredentials.
  ///
  /// In zh, this message translates to:
  /// **'用户名或密码错误'**
  String get embyInvalidCredentials;

  /// No description provided for @embyConnectionFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法连接服务器，请检查地址和网络'**
  String get embyConnectionFailed;

  /// No description provided for @embyLoginFailed.
  ///
  /// In zh, this message translates to:
  /// **'登录失败，请稍后重试'**
  String get embyLoginFailed;

  /// No description provided for @embyMediaBrowsingComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'媒体浏览功能后续接入'**
  String get embyMediaBrowsingComingSoon;

  /// No description provided for @serverSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'服务器登录成功，但保存失败，请重试'**
  String get serverSaveFailed;

  /// No description provided for @serverLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'读取本地服务器列表失败'**
  String get serverLoadFailed;

  /// No description provided for @serverLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在读取服务器列表…'**
  String get serverLoading;

  /// No description provided for @languageSetting.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get languageSetting;

  /// No description provided for @languageAuto.
  ///
  /// In zh, this message translates to:
  /// **'Auto'**
  String get languageAuto;

  /// No description provided for @languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'语言设置保存失败'**
  String get languageSaveFailed;

  /// No description provided for @aggregationTab.
  ///
  /// In zh, this message translates to:
  /// **'聚合视界'**
  String get aggregationTab;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
