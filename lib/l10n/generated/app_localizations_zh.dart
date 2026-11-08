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
  String get globalSettings => '全局配置';

  @override
  String get clearCache => '清空缓存';

  @override
  String get clearCacheDescription => '清除 Emby 图片和媒体信息缓存';

  @override
  String get clearCacheConfirmation => '将删除已缓存的图片和媒体信息。此操作不会删除服务器或账号信息，是否继续？';

  @override
  String get cacheCleared => '缓存已清空';

  @override
  String get cacheClearFailed => '清空缓存失败，请重试';

  @override
  String get clear => '清空';

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
  String get done => '完成';

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
  String get libraryManage => '管理媒体库';

  @override
  String get libraryManageTitle => '媒体库管理';

  @override
  String get libraryShowOnHome => '在首页展示';

  @override
  String get libraryOrderHandle => '调整媒体库顺序';

  @override
  String get libraryManageUnavailable => '此服务器暂不支持媒体库管理。';

  @override
  String get libraryPreferencesSaveFailed => '媒体库设置保存失败。';

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
  String get librarySearch => '搜索此媒体库';

  @override
  String get librarySearchClose => '关闭搜索';

  @override
  String get librarySearchClear => '清除搜索';

  @override
  String get librarySearchHint => '搜索电影或剧集';

  @override
  String get librarySearchNoResults => '没有找到匹配的电影或剧集';

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
  String get mediaDetailSeasons => '剧集';

  @override
  String get mediaDetailNoSeasons => '暂无季信息';

  @override
  String mediaDetailSeasonNumber(int number) {
    return '第 $number 季';
  }

  @override
  String mediaDetailEpisodeNumber(int number) {
    return '第 $number 集';
  }

  @override
  String mediaDetailEpisodeCount(int count) {
    return '$count 集';
  }

  @override
  String get mediaDetailNoEpisodes => '暂无剧集';

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
  String get playerBack => '返回';

  @override
  String get playerTracks => '音轨与字幕';

  @override
  String get playerAudio => '音轨';

  @override
  String get playerSubtitles => '字幕';

  @override
  String get playerSubtitlesOff => '关闭';

  @override
  String get playerSpeed => '播放速度';

  @override
  String get playerSpeedIncrease => '加快播放速度';

  @override
  String get playerSpeedDecrease => '减慢播放速度';

  @override
  String get playerLockControls => '锁定控制';

  @override
  String get playerUnlockControls => '解锁控制';

  @override
  String get playerVideoFit => '切换画面比例';

  @override
  String get playerLandscape => '切换横屏';

  @override
  String get playerPortrait => '切换竖屏';

  @override
  String get playerDecoderMode => '点击切换解码模式';

  @override
  String get playerDecoderSwitchFailed => '切换解码模式失败';

  @override
  String get playerMore => '更多选项';

  @override
  String get playerUnmute => '取消静音';

  @override
  String get playerSeek => '进度';

  @override
  String get playerBrightness => '亮度';

  @override
  String get playerVolume => '音量';

  @override
  String get playerPlay => '播放';

  @override
  String get playerPause => '暂停';

  @override
  String get playerBack10 => '后退 10 秒';

  @override
  String get playerForward10 => '前进 10 秒';

  @override
  String get playerSeekBackward => '双击后退';

  @override
  String get playerSeekForward => '双击快进';

  @override
  String playerSeekSecondsValue(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get playerRetry => '重试';

  @override
  String get playerPlaybackFailed => '播放失败';

  @override
  String get playerQuality => '播放画质';

  @override
  String get playerSettings => '播放器设置';

  @override
  String get playerQualityOriginal => '原画';

  @override
  String get playerQualityLimit => '限制码率';

  @override
  String get playerSubtitleLanguage => '默认字幕语言';

  @override
  String get playerSubtitleSize => '字幕字号';

  @override
  String get playerAudioPassthrough => '音频直通';

  @override
  String get playerHardwareAcceleration => '硬件解码';

  @override
  String get playerCache => '播放缓存';

  @override
  String get playerCacheDescription => '播放时使用磁盘缓存';

  @override
  String get playerCacheSize => '缓存大小';

  @override
  String playerCacheSizeValue(int size) {
    return '$size MB';
  }

  @override
  String get playerNextEpisode => '下一集';

  @override
  String get playerStats => '播放统计';

  @override
  String get playerExternalSubtitles => '外挂字幕';

  @override
  String get playerRetrying => '正在重试播放…';

  @override
  String get playerMute => '静音';

  @override
  String get playerSubtitleJapanese => '日语';

  @override
  String get playerNoPlayableUrl => '此媒体版本没有可用的直连地址。';

  @override
  String get playerInvalidPlaybackUrl => '服务器返回了无效的播放地址。';

  @override
  String get playerNetworkError => '无法连接媒体服务器。';

  @override
  String get playerPlaybackTimeout => '媒体服务器响应超时，请重试。';

  @override
  String get playerRequestFailed => '媒体服务器拒绝了播放请求。';

  @override
  String get playerSubtitleUnsupported => '暂不支持此字幕格式。';

  @override
  String get playerInvalidPlaybackResponse => '媒体服务器返回了无效响应。';

  @override
  String get playerStatsVideo => '视频';

  @override
  String get playerStatsAudio => '音频';

  @override
  String get playerStatsBuffer => '缓冲';

  @override
  String get playerStatsVolume => '音量';

  @override
  String get playerStatsMethod => '方式';

  @override
  String get playerSettingsSaveFailed => '播放设置保存失败。';

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
