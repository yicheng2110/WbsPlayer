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
  String get editServer => '修改服务器';

  @override
  String get save => '保存';

  @override
  String get serverEditFailed => '服务器信息更新失败，请重试';

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
  String get homeFeatured => '为你推荐';

  @override
  String get homeContinueWatching => '继续观看';

  @override
  String get homeLibraries => '媒体库';

  @override
  String get homeLoading => '正在加载媒体库…';

  @override
  String get homeLoadFailed => '无法加载媒体内容，请检查服务器连接或重新登录';

  @override
  String get homeRetry => '重试';

  @override
  String get homeNoItems => '暂无内容';

  @override
  String get homeViewAll => '查看全部';

  @override
  String get librarySort => '排序方式';

  @override
  String get librarySortDateAdded => '加入日期';

  @override
  String get librarySortTitle => '标题';

  @override
  String get librarySortCommunityRating => '公众评分';

  @override
  String get librarySortCriticRating => '影评人评分';

  @override
  String get librarySortProductionYear => '出品年份';

  @override
  String get librarySortPremiereDate => '首映日期';

  @override
  String get librarySortOfficialRating => '官方评级';

  @override
  String get librarySortDatePlayed => '播放日期';

  @override
  String get librarySortRuntime => '播放时长';

  @override
  String get librarySortBitrate => '比特率';

  @override
  String get librarySortSize => '大小';

  @override
  String get librarySortRandom => '随机';

  @override
  String get librarySortUnsupported => '不支持';

  @override
  String get librarySortAscending => '升序';

  @override
  String get librarySortDescending => '降序';

  @override
  String get mediaDetailRetry => '重试';

  @override
  String get mediaDetailLoading => '正在加载媒体详情…';

  @override
  String get mediaDetailLoadFailed => '无法加载媒体详情，请检查服务器连接或重新登录';

  @override
  String get mediaDetailPlaybackFailed => '播放启动失败';

  @override
  String get mediaDetailNoOverview => '暂无简介';

  @override
  String get mediaDetailPlay => '播放';

  @override
  String get mediaDetailPlaybackUnavailable => '播放功能尚未接入';

  @override
  String get mediaDetailNoStreams => '没有可用的媒体流信息';

  @override
  String get mediaDetailChooseVersion => '版本';

  @override
  String get mediaDetailUnknownVersion => '未知版本';

  @override
  String get mediaDetailChooseAudio => '音轨';

  @override
  String get mediaDetailUnknownAudio => '未知音轨';

  @override
  String mediaDetailDurationMinutes(Object minutes) {
    return '$minutes 分钟';
  }

  @override
  String mediaDetailDurationHoursMinutes(Object hours, Object minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String get mediaDetailCast => '演职人员';

  @override
  String get mediaDetailNoPeople => '暂无演职人员信息';

  @override
  String get mediaDetailDirector => '导演';

  @override
  String get mediaDetailWriter => '编剧';

  @override
  String get mediaDetailCrew => '制作人员';

  @override
  String get mediaDetailPhotos => '相册';

  @override
  String get mediaDetailNoImages => '暂无图片';

  @override
  String get mediaDetailSimilar => '更多类似';

  @override
  String get mediaDetailNoSimilar => '暂无类似内容';

  @override
  String get mediaDetailStudios => '工作室';

  @override
  String get mediaDetailNoStudio => '暂无工作室信息';

  @override
  String get mediaDetailExternalLinks => '外部链接';

  @override
  String get mediaDetailNoExternalLinks => '暂无外部链接';

  @override
  String get mediaDetailTechnicalInfo => '媒体信息';

  @override
  String get mediaDetailVersion => '版本';

  @override
  String get mediaDetailTechContainer => '封装';

  @override
  String get mediaDetailTechSize => '大小';

  @override
  String get mediaDetailTechBitrate => '比特率';

  @override
  String get mediaDetailTechVideo => '视频';

  @override
  String get mediaDetailTechAudio => '音频';

  @override
  String get mediaDetailResolution => '分辨率';

  @override
  String get mediaDetailFrameRate => '帧率';

  @override
  String get mediaDetailVideoRange => '动态范围';

  @override
  String get mediaDetailColorSpace => '色彩空间';

  @override
  String get mediaDetailColorTransfer => '色彩转换';

  @override
  String get mediaDetailStreamDefault => '默认';

  @override
  String get mediaDetailStreamForced => '强制';

  @override
  String get mediaDetailStreamExternal => '外部';

  @override
  String get mediaDetailAddFavorite => '添加收藏';

  @override
  String get mediaDetailRemoveFavorite => '取消收藏';

  @override
  String get mediaDetailFavoriteFailed => '收藏状态更新失败';

  @override
  String get homeOverviewUnavailable => '暂无简介';

  @override
  String homeRating(Object rating) {
    return '评分 $rating';
  }

  @override
  String homeServer(Object name) {
    return '服务器：$name';
  }

  @override
  String get homeRefreshing => '刷新中…';

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

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get checkingForUpdates => '正在检查更新…';

  @override
  String get latestVersionInstalled => '已安装最新版本';

  @override
  String get updateAvailableTitle => '发现新版本';

  @override
  String updateAvailableMessage(Object currentVersion, Object latestVersion) {
    return '当前版本：$currentVersion\n最新版本：$latestVersion';
  }

  @override
  String get downloadUpdate => '下载更新';

  @override
  String get downloadingUpdate => '正在下载更新…';

  @override
  String downloadPercent(int percent) {
    return '$percent%';
  }

  @override
  String get openingUpdateInstaller => '下载完成，正在打开安装程序…';

  @override
  String get updateCheckFailed => '检查更新失败，请检查网络后重试';

  @override
  String get updateDownloadFailed => '下载更新失败，请稍后重试';

  @override
  String get updateInstallerFailed => '无法打开安装程序，请检查系统安装权限';

  @override
  String get updateInstallerStarted => '安装程序已打开，请按系统提示完成更新';
}
