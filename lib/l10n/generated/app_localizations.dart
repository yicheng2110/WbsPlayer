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

  /// No description provided for @globalSettings.
  ///
  /// In zh, this message translates to:
  /// **'全局配置'**
  String get globalSettings;

  /// No description provided for @clearCache.
  ///
  /// In zh, this message translates to:
  /// **'清空缓存'**
  String get clearCache;

  /// No description provided for @clearCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'清除 Emby 图片和媒体信息缓存'**
  String get clearCacheDescription;

  /// No description provided for @clearCacheConfirmation.
  ///
  /// In zh, this message translates to:
  /// **'将删除已缓存的图片和媒体信息。此操作不会删除服务器或账号信息，是否继续？'**
  String get clearCacheConfirmation;

  /// No description provided for @cacheCleared.
  ///
  /// In zh, this message translates to:
  /// **'缓存已清空'**
  String get cacheCleared;

  /// No description provided for @cacheClearFailed.
  ///
  /// In zh, this message translates to:
  /// **'清空缓存失败，请重试'**
  String get cacheClearFailed;

  /// No description provided for @clear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get clear;

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

  /// No description provided for @editServer.
  ///
  /// In zh, this message translates to:
  /// **'修改服务器'**
  String get editServer;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @serverEditFailed.
  ///
  /// In zh, this message translates to:
  /// **'服务器信息更新失败，请重试'**
  String get serverEditFailed;

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

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

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

  /// No description provided for @homeFeatured.
  ///
  /// In zh, this message translates to:
  /// **'为你推荐'**
  String get homeFeatured;

  /// No description provided for @homeContinueWatching.
  ///
  /// In zh, this message translates to:
  /// **'继续观看'**
  String get homeContinueWatching;

  /// No description provided for @homeLibraries.
  ///
  /// In zh, this message translates to:
  /// **'媒体库'**
  String get homeLibraries;

  /// No description provided for @libraryManage.
  ///
  /// In zh, this message translates to:
  /// **'管理媒体库'**
  String get libraryManage;

  /// No description provided for @libraryManageTitle.
  ///
  /// In zh, this message translates to:
  /// **'媒体库管理'**
  String get libraryManageTitle;

  /// No description provided for @libraryShowOnHome.
  ///
  /// In zh, this message translates to:
  /// **'在首页展示'**
  String get libraryShowOnHome;

  /// No description provided for @libraryOrderHandle.
  ///
  /// In zh, this message translates to:
  /// **'调整媒体库顺序'**
  String get libraryOrderHandle;

  /// No description provided for @libraryManageUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'此服务器暂不支持媒体库管理。'**
  String get libraryManageUnavailable;

  /// No description provided for @libraryPreferencesSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'媒体库设置保存失败。'**
  String get libraryPreferencesSaveFailed;

  /// No description provided for @homeLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在加载媒体库…'**
  String get homeLoading;

  /// No description provided for @homeLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法加载媒体内容，请检查服务器连接或重新登录'**
  String get homeLoadFailed;

  /// No description provided for @homeRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get homeRetry;

  /// No description provided for @homeNoItems.
  ///
  /// In zh, this message translates to:
  /// **'暂无内容'**
  String get homeNoItems;

  /// No description provided for @homeViewAll.
  ///
  /// In zh, this message translates to:
  /// **'查看全部'**
  String get homeViewAll;

  /// No description provided for @librarySearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索此媒体库'**
  String get librarySearch;

  /// No description provided for @librarySearchClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭搜索'**
  String get librarySearchClose;

  /// No description provided for @librarySearchClear.
  ///
  /// In zh, this message translates to:
  /// **'清除搜索'**
  String get librarySearchClear;

  /// No description provided for @librarySearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索电影或剧集'**
  String get librarySearchHint;

  /// No description provided for @librarySearchNoResults.
  ///
  /// In zh, this message translates to:
  /// **'没有找到匹配的电影或剧集'**
  String get librarySearchNoResults;

  /// No description provided for @librarySort.
  ///
  /// In zh, this message translates to:
  /// **'排序方式'**
  String get librarySort;

  /// No description provided for @librarySortDateAdded.
  ///
  /// In zh, this message translates to:
  /// **'加入日期'**
  String get librarySortDateAdded;

  /// No description provided for @librarySortTitle.
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get librarySortTitle;

  /// No description provided for @librarySortCommunityRating.
  ///
  /// In zh, this message translates to:
  /// **'公众评分'**
  String get librarySortCommunityRating;

  /// No description provided for @librarySortCriticRating.
  ///
  /// In zh, this message translates to:
  /// **'影评人评分'**
  String get librarySortCriticRating;

  /// No description provided for @librarySortProductionYear.
  ///
  /// In zh, this message translates to:
  /// **'出品年份'**
  String get librarySortProductionYear;

  /// No description provided for @librarySortPremiereDate.
  ///
  /// In zh, this message translates to:
  /// **'首映日期'**
  String get librarySortPremiereDate;

  /// No description provided for @librarySortOfficialRating.
  ///
  /// In zh, this message translates to:
  /// **'官方评级'**
  String get librarySortOfficialRating;

  /// No description provided for @librarySortDatePlayed.
  ///
  /// In zh, this message translates to:
  /// **'播放日期'**
  String get librarySortDatePlayed;

  /// No description provided for @librarySortRuntime.
  ///
  /// In zh, this message translates to:
  /// **'播放时长'**
  String get librarySortRuntime;

  /// No description provided for @librarySortBitrate.
  ///
  /// In zh, this message translates to:
  /// **'比特率'**
  String get librarySortBitrate;

  /// No description provided for @librarySortSize.
  ///
  /// In zh, this message translates to:
  /// **'大小'**
  String get librarySortSize;

  /// No description provided for @librarySortRandom.
  ///
  /// In zh, this message translates to:
  /// **'随机'**
  String get librarySortRandom;

  /// No description provided for @librarySortUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'不支持'**
  String get librarySortUnsupported;

  /// No description provided for @librarySortAscending.
  ///
  /// In zh, this message translates to:
  /// **'升序'**
  String get librarySortAscending;

  /// No description provided for @librarySortDescending.
  ///
  /// In zh, this message translates to:
  /// **'降序'**
  String get librarySortDescending;

  /// No description provided for @mediaDetailRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get mediaDetailRetry;

  /// No description provided for @mediaDetailLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在加载媒体详情…'**
  String get mediaDetailLoading;

  /// No description provided for @mediaDetailLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法加载媒体详情，请检查服务器连接或重新登录'**
  String get mediaDetailLoadFailed;

  /// No description provided for @mediaDetailPlaybackFailed.
  ///
  /// In zh, this message translates to:
  /// **'播放启动失败'**
  String get mediaDetailPlaybackFailed;

  /// No description provided for @mediaDetailNoOverview.
  ///
  /// In zh, this message translates to:
  /// **'暂无简介'**
  String get mediaDetailNoOverview;

  /// No description provided for @mediaDetailPlay.
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get mediaDetailPlay;

  /// No description provided for @mediaDetailPlaybackUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'播放功能尚未接入'**
  String get mediaDetailPlaybackUnavailable;

  /// No description provided for @mediaDetailNoStreams.
  ///
  /// In zh, this message translates to:
  /// **'没有可用的媒体流信息'**
  String get mediaDetailNoStreams;

  /// No description provided for @mediaDetailChooseVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get mediaDetailChooseVersion;

  /// No description provided for @mediaDetailUnknownVersion.
  ///
  /// In zh, this message translates to:
  /// **'未知版本'**
  String get mediaDetailUnknownVersion;

  /// No description provided for @mediaDetailChooseAudio.
  ///
  /// In zh, this message translates to:
  /// **'音轨'**
  String get mediaDetailChooseAudio;

  /// No description provided for @mediaDetailUnknownAudio.
  ///
  /// In zh, this message translates to:
  /// **'未知音轨'**
  String get mediaDetailUnknownAudio;

  /// No description provided for @mediaDetailDurationMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{minutes} 分钟'**
  String mediaDetailDurationMinutes(Object minutes);

  /// No description provided for @mediaDetailDurationHoursMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{hours} 小时 {minutes} 分钟'**
  String mediaDetailDurationHoursMinutes(Object hours, Object minutes);

  /// No description provided for @mediaDetailCast.
  ///
  /// In zh, this message translates to:
  /// **'演职人员'**
  String get mediaDetailCast;

  /// No description provided for @mediaDetailNoPeople.
  ///
  /// In zh, this message translates to:
  /// **'暂无演职人员信息'**
  String get mediaDetailNoPeople;

  /// No description provided for @mediaDetailDirector.
  ///
  /// In zh, this message translates to:
  /// **'导演'**
  String get mediaDetailDirector;

  /// No description provided for @mediaDetailWriter.
  ///
  /// In zh, this message translates to:
  /// **'编剧'**
  String get mediaDetailWriter;

  /// No description provided for @mediaDetailCrew.
  ///
  /// In zh, this message translates to:
  /// **'制作人员'**
  String get mediaDetailCrew;

  /// No description provided for @mediaDetailPhotos.
  ///
  /// In zh, this message translates to:
  /// **'相册'**
  String get mediaDetailPhotos;

  /// No description provided for @mediaDetailNoImages.
  ///
  /// In zh, this message translates to:
  /// **'暂无图片'**
  String get mediaDetailNoImages;

  /// No description provided for @mediaDetailSimilar.
  ///
  /// In zh, this message translates to:
  /// **'更多类似'**
  String get mediaDetailSimilar;

  /// No description provided for @mediaDetailNoSimilar.
  ///
  /// In zh, this message translates to:
  /// **'暂无类似内容'**
  String get mediaDetailNoSimilar;

  /// No description provided for @mediaDetailSeasons.
  ///
  /// In zh, this message translates to:
  /// **'剧集'**
  String get mediaDetailSeasons;

  /// No description provided for @mediaDetailNoSeasons.
  ///
  /// In zh, this message translates to:
  /// **'暂无季信息'**
  String get mediaDetailNoSeasons;

  /// No description provided for @mediaDetailSeasonNumber.
  ///
  /// In zh, this message translates to:
  /// **'第 {number} 季'**
  String mediaDetailSeasonNumber(int number);

  /// No description provided for @mediaDetailEpisodeNumber.
  ///
  /// In zh, this message translates to:
  /// **'第 {number} 集'**
  String mediaDetailEpisodeNumber(int number);

  /// No description provided for @mediaDetailEpisodeCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 集'**
  String mediaDetailEpisodeCount(int count);

  /// No description provided for @mediaDetailNoEpisodes.
  ///
  /// In zh, this message translates to:
  /// **'暂无剧集'**
  String get mediaDetailNoEpisodes;

  /// No description provided for @mediaDetailStudios.
  ///
  /// In zh, this message translates to:
  /// **'工作室'**
  String get mediaDetailStudios;

  /// No description provided for @mediaDetailNoStudio.
  ///
  /// In zh, this message translates to:
  /// **'暂无工作室信息'**
  String get mediaDetailNoStudio;

  /// No description provided for @mediaDetailExternalLinks.
  ///
  /// In zh, this message translates to:
  /// **'外部链接'**
  String get mediaDetailExternalLinks;

  /// No description provided for @mediaDetailNoExternalLinks.
  ///
  /// In zh, this message translates to:
  /// **'暂无外部链接'**
  String get mediaDetailNoExternalLinks;

  /// No description provided for @mediaDetailTechnicalInfo.
  ///
  /// In zh, this message translates to:
  /// **'媒体信息'**
  String get mediaDetailTechnicalInfo;

  /// No description provided for @mediaDetailVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get mediaDetailVersion;

  /// No description provided for @mediaDetailTechContainer.
  ///
  /// In zh, this message translates to:
  /// **'封装'**
  String get mediaDetailTechContainer;

  /// No description provided for @mediaDetailTechSize.
  ///
  /// In zh, this message translates to:
  /// **'大小'**
  String get mediaDetailTechSize;

  /// No description provided for @mediaDetailTechBitrate.
  ///
  /// In zh, this message translates to:
  /// **'比特率'**
  String get mediaDetailTechBitrate;

  /// No description provided for @mediaDetailTechVideo.
  ///
  /// In zh, this message translates to:
  /// **'视频'**
  String get mediaDetailTechVideo;

  /// No description provided for @mediaDetailTechAudio.
  ///
  /// In zh, this message translates to:
  /// **'音频'**
  String get mediaDetailTechAudio;

  /// No description provided for @mediaDetailResolution.
  ///
  /// In zh, this message translates to:
  /// **'分辨率'**
  String get mediaDetailResolution;

  /// No description provided for @mediaDetailFrameRate.
  ///
  /// In zh, this message translates to:
  /// **'帧率'**
  String get mediaDetailFrameRate;

  /// No description provided for @mediaDetailVideoRange.
  ///
  /// In zh, this message translates to:
  /// **'动态范围'**
  String get mediaDetailVideoRange;

  /// No description provided for @mediaDetailColorSpace.
  ///
  /// In zh, this message translates to:
  /// **'色彩空间'**
  String get mediaDetailColorSpace;

  /// No description provided for @mediaDetailColorTransfer.
  ///
  /// In zh, this message translates to:
  /// **'色彩转换'**
  String get mediaDetailColorTransfer;

  /// No description provided for @mediaDetailStreamDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get mediaDetailStreamDefault;

  /// No description provided for @mediaDetailStreamForced.
  ///
  /// In zh, this message translates to:
  /// **'强制'**
  String get mediaDetailStreamForced;

  /// No description provided for @mediaDetailStreamExternal.
  ///
  /// In zh, this message translates to:
  /// **'外部'**
  String get mediaDetailStreamExternal;

  /// No description provided for @mediaDetailAddFavorite.
  ///
  /// In zh, this message translates to:
  /// **'添加收藏'**
  String get mediaDetailAddFavorite;

  /// No description provided for @mediaDetailRemoveFavorite.
  ///
  /// In zh, this message translates to:
  /// **'取消收藏'**
  String get mediaDetailRemoveFavorite;

  /// No description provided for @mediaDetailFavoriteFailed.
  ///
  /// In zh, this message translates to:
  /// **'收藏状态更新失败'**
  String get mediaDetailFavoriteFailed;

  /// No description provided for @playerBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get playerBack;

  /// No description provided for @playerTracks.
  ///
  /// In zh, this message translates to:
  /// **'音轨与字幕'**
  String get playerTracks;

  /// No description provided for @playerAudio.
  ///
  /// In zh, this message translates to:
  /// **'音轨'**
  String get playerAudio;

  /// No description provided for @playerSubtitles.
  ///
  /// In zh, this message translates to:
  /// **'字幕'**
  String get playerSubtitles;

  /// No description provided for @playerSubtitlesOff.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get playerSubtitlesOff;

  /// No description provided for @playerSpeed.
  ///
  /// In zh, this message translates to:
  /// **'播放速度'**
  String get playerSpeed;

  /// No description provided for @playerSpeedIncrease.
  ///
  /// In zh, this message translates to:
  /// **'加快播放速度'**
  String get playerSpeedIncrease;

  /// No description provided for @playerSpeedDecrease.
  ///
  /// In zh, this message translates to:
  /// **'减慢播放速度'**
  String get playerSpeedDecrease;

  /// No description provided for @playerLockControls.
  ///
  /// In zh, this message translates to:
  /// **'锁定控制'**
  String get playerLockControls;

  /// No description provided for @playerUnlockControls.
  ///
  /// In zh, this message translates to:
  /// **'解锁控制'**
  String get playerUnlockControls;

  /// No description provided for @playerVideoFit.
  ///
  /// In zh, this message translates to:
  /// **'切换画面比例'**
  String get playerVideoFit;

  /// No description provided for @playerLandscape.
  ///
  /// In zh, this message translates to:
  /// **'切换横屏'**
  String get playerLandscape;

  /// No description provided for @playerPortrait.
  ///
  /// In zh, this message translates to:
  /// **'切换竖屏'**
  String get playerPortrait;

  /// No description provided for @playerDecoderMode.
  ///
  /// In zh, this message translates to:
  /// **'点击切换解码模式'**
  String get playerDecoderMode;

  /// No description provided for @playerDecoderSwitchFailed.
  ///
  /// In zh, this message translates to:
  /// **'切换解码模式失败'**
  String get playerDecoderSwitchFailed;

  /// No description provided for @playerMore.
  ///
  /// In zh, this message translates to:
  /// **'更多选项'**
  String get playerMore;

  /// No description provided for @playerUnmute.
  ///
  /// In zh, this message translates to:
  /// **'取消静音'**
  String get playerUnmute;

  /// No description provided for @playerSeek.
  ///
  /// In zh, this message translates to:
  /// **'进度'**
  String get playerSeek;

  /// No description provided for @playerBrightness.
  ///
  /// In zh, this message translates to:
  /// **'亮度'**
  String get playerBrightness;

  /// No description provided for @playerVolume.
  ///
  /// In zh, this message translates to:
  /// **'音量'**
  String get playerVolume;

  /// No description provided for @playerPlay.
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get playerPlay;

  /// No description provided for @playerPause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get playerPause;

  /// No description provided for @playerBack10.
  ///
  /// In zh, this message translates to:
  /// **'后退 10 秒'**
  String get playerBack10;

  /// No description provided for @playerForward10.
  ///
  /// In zh, this message translates to:
  /// **'前进 10 秒'**
  String get playerForward10;

  /// No description provided for @playerSeekBackward.
  ///
  /// In zh, this message translates to:
  /// **'双击后退'**
  String get playerSeekBackward;

  /// No description provided for @playerSeekForward.
  ///
  /// In zh, this message translates to:
  /// **'双击快进'**
  String get playerSeekForward;

  /// No description provided for @playerSeekSecondsValue.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒'**
  String playerSeekSecondsValue(int seconds);

  /// Full-screen horizontal drag maps to this duration.
  ///
  /// In zh, this message translates to:
  /// **'横向拖动跨度'**
  String get playerDragSeekDuration;

  /// Duration represented by a full-width horizontal drag.
  ///
  /// In zh, this message translates to:
  /// **'{minutes} 分钟'**
  String playerDragSeekDurationValue(int minutes);

  /// No description provided for @playerRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get playerRetry;

  /// No description provided for @playerPlaybackFailed.
  ///
  /// In zh, this message translates to:
  /// **'播放失败'**
  String get playerPlaybackFailed;

  /// No description provided for @playerQuality.
  ///
  /// In zh, this message translates to:
  /// **'播放画质'**
  String get playerQuality;

  /// No description provided for @playerSettings.
  ///
  /// In zh, this message translates to:
  /// **'播放器设置'**
  String get playerSettings;

  /// No description provided for @playerQualityOriginal.
  ///
  /// In zh, this message translates to:
  /// **'原画'**
  String get playerQualityOriginal;

  /// No description provided for @playerQualityLimit.
  ///
  /// In zh, this message translates to:
  /// **'限制码率'**
  String get playerQualityLimit;

  /// No description provided for @playerSubtitleLanguage.
  ///
  /// In zh, this message translates to:
  /// **'默认字幕语言'**
  String get playerSubtitleLanguage;

  /// No description provided for @playerSubtitleSize.
  ///
  /// In zh, this message translates to:
  /// **'字幕字号'**
  String get playerSubtitleSize;

  /// No description provided for @playerAudioPassthrough.
  ///
  /// In zh, this message translates to:
  /// **'音频直通'**
  String get playerAudioPassthrough;

  /// No description provided for @playerHardwareAcceleration.
  ///
  /// In zh, this message translates to:
  /// **'硬件解码'**
  String get playerHardwareAcceleration;

  /// No description provided for @playerCache.
  ///
  /// In zh, this message translates to:
  /// **'播放缓存'**
  String get playerCache;

  /// No description provided for @playerCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'播放时使用磁盘缓存'**
  String get playerCacheDescription;

  /// No description provided for @playerCacheSize.
  ///
  /// In zh, this message translates to:
  /// **'缓存大小'**
  String get playerCacheSize;

  /// No description provided for @playerCacheSizeValue.
  ///
  /// In zh, this message translates to:
  /// **'{size} MB'**
  String playerCacheSizeValue(int size);

  /// No description provided for @playerNextEpisode.
  ///
  /// In zh, this message translates to:
  /// **'下一集'**
  String get playerNextEpisode;

  /// No description provided for @playerStats.
  ///
  /// In zh, this message translates to:
  /// **'播放统计'**
  String get playerStats;

  /// No description provided for @playerExternalSubtitles.
  ///
  /// In zh, this message translates to:
  /// **'外挂字幕'**
  String get playerExternalSubtitles;

  /// No description provided for @playerRetrying.
  ///
  /// In zh, this message translates to:
  /// **'正在重试播放…'**
  String get playerRetrying;

  /// No description provided for @playerMute.
  ///
  /// In zh, this message translates to:
  /// **'静音'**
  String get playerMute;

  /// No description provided for @playerSubtitleJapanese.
  ///
  /// In zh, this message translates to:
  /// **'日语'**
  String get playerSubtitleJapanese;

  /// No description provided for @playerNoPlayableUrl.
  ///
  /// In zh, this message translates to:
  /// **'此媒体版本没有可用的直连地址。'**
  String get playerNoPlayableUrl;

  /// No description provided for @playerInvalidPlaybackUrl.
  ///
  /// In zh, this message translates to:
  /// **'服务器返回了无效的播放地址。'**
  String get playerInvalidPlaybackUrl;

  /// No description provided for @playerNetworkError.
  ///
  /// In zh, this message translates to:
  /// **'无法连接媒体服务器。'**
  String get playerNetworkError;

  /// No description provided for @playerPlaybackTimeout.
  ///
  /// In zh, this message translates to:
  /// **'媒体服务器响应超时，请重试。'**
  String get playerPlaybackTimeout;

  /// No description provided for @playerRequestFailed.
  ///
  /// In zh, this message translates to:
  /// **'媒体服务器拒绝了播放请求。'**
  String get playerRequestFailed;

  /// No description provided for @playerSubtitleUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'暂不支持此字幕格式。'**
  String get playerSubtitleUnsupported;

  /// No description provided for @playerInvalidPlaybackResponse.
  ///
  /// In zh, this message translates to:
  /// **'媒体服务器返回了无效响应。'**
  String get playerInvalidPlaybackResponse;

  /// No description provided for @playerStatsVideo.
  ///
  /// In zh, this message translates to:
  /// **'视频'**
  String get playerStatsVideo;

  /// No description provided for @playerStatsAudio.
  ///
  /// In zh, this message translates to:
  /// **'音频'**
  String get playerStatsAudio;

  /// Current estimated stream input speed.
  ///
  /// In zh, this message translates to:
  /// **'流加载网速'**
  String get playerStatsNetworkSpeed;

  /// No description provided for @playerStatsBuffer.
  ///
  /// In zh, this message translates to:
  /// **'缓冲'**
  String get playerStatsBuffer;

  /// No description provided for @playerStatsVolume.
  ///
  /// In zh, this message translates to:
  /// **'音量'**
  String get playerStatsVolume;

  /// No description provided for @playerStatsMethod.
  ///
  /// In zh, this message translates to:
  /// **'方式'**
  String get playerStatsMethod;

  /// No description provided for @playerSettingsSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'播放设置保存失败。'**
  String get playerSettingsSaveFailed;

  /// No description provided for @homeOverviewUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂无简介'**
  String get homeOverviewUnavailable;

  /// No description provided for @homeRating.
  ///
  /// In zh, this message translates to:
  /// **'评分 {rating}'**
  String homeRating(Object rating);

  /// No description provided for @homeServer.
  ///
  /// In zh, this message translates to:
  /// **'服务器：{name}'**
  String homeServer(Object name);

  /// No description provided for @homeRefreshing.
  ///
  /// In zh, this message translates to:
  /// **'刷新中…'**
  String get homeRefreshing;

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

  /// No description provided for @checkForUpdates.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get checkForUpdates;

  /// No description provided for @checkingForUpdates.
  ///
  /// In zh, this message translates to:
  /// **'正在检查更新…'**
  String get checkingForUpdates;

  /// No description provided for @latestVersionInstalled.
  ///
  /// In zh, this message translates to:
  /// **'已安装最新版本'**
  String get latestVersionInstalled;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableMessage.
  ///
  /// In zh, this message translates to:
  /// **'当前版本：{currentVersion}\n最新版本：{latestVersion}'**
  String updateAvailableMessage(Object currentVersion, Object latestVersion);

  /// No description provided for @downloadUpdate.
  ///
  /// In zh, this message translates to:
  /// **'下载更新'**
  String get downloadUpdate;

  /// No description provided for @downloadingUpdate.
  ///
  /// In zh, this message translates to:
  /// **'正在下载更新…'**
  String get downloadingUpdate;

  /// No description provided for @downloadPercent.
  ///
  /// In zh, this message translates to:
  /// **'{percent}%'**
  String downloadPercent(int percent);

  /// No description provided for @openingUpdateInstaller.
  ///
  /// In zh, this message translates to:
  /// **'下载完成，正在打开安装程序…'**
  String get openingUpdateInstaller;

  /// No description provided for @updateCheckFailed.
  ///
  /// In zh, this message translates to:
  /// **'检查更新失败，请检查网络后重试'**
  String get updateCheckFailed;

  /// No description provided for @updateDownloadFailed.
  ///
  /// In zh, this message translates to:
  /// **'下载更新失败，请稍后重试'**
  String get updateDownloadFailed;

  /// No description provided for @updateInstallerFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法打开安装程序，请检查系统安装权限'**
  String get updateInstallerFailed;

  /// No description provided for @updateInstallerStarted.
  ///
  /// In zh, this message translates to:
  /// **'安装程序已打开，请按系统提示完成更新'**
  String get updateInstallerStarted;
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
