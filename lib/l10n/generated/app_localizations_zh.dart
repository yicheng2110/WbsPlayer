// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Wbs Player';

  @override
  String get serversTitle => '服务器';

  @override
  String get settingsTitle => '设置';

  @override
  String get moreOptions => '更多选项';

  @override
  String get addServer => '添加服务器';

  @override
  String get serverName => '服务器名称';

  @override
  String get serverNameHint => '例如：家里的 Emby';

  @override
  String get serverAddress => '服务器地址';

  @override
  String get serverAddressHint => 'http://192.168.1.10:8096';

  @override
  String get serverAddressRequired => '请输入服务器地址';

  @override
  String get serverAddressInvalid => '请输入有效的服务器地址';

  @override
  String get cancel => '取消';

  @override
  String get add => '添加';

  @override
  String get defaultServerName => 'Emby 服务器';

  @override
  String get emptyServersMessage => '马上添加 Emby 服务器，以开始您的媒体之旅！';

  @override
  String get serverConnectionComingSoon => 'Emby 登录与连接功能后续接入';

  @override
  String get embySignInTitle => '登录 Emby 服务器';

  @override
  String get embyUsername => '用户名';

  @override
  String get embyUsernameRequired => '请输入用户名';

  @override
  String get embyPassword => '密码';

  @override
  String get embySignIn => '登录';

  @override
  String get embyInvalidCredentials => '用户名或密码错误';

  @override
  String get embyConnectionFailed => '无法连接服务器，请检查地址和网络';

  @override
  String get embyLoginFailed => '登录失败，请稍后重试';

  @override
  String get embyMediaBrowsingComingSoon => '媒体浏览功能后续接入';

  @override
  String get serverSaveFailed => '服务器登录成功，但保存失败，请重试';

  @override
  String get serverLoadFailed => '读取本地服务器列表失败';

  @override
  String get serverLoading => '正在读取服务器列表…';

  @override
  String get languageSetting => '语言';

  @override
  String get languageAuto => 'Auto';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSaveFailed => '语言设置保存失败';

  @override
  String get aggregationTab => '聚合视界';
}
