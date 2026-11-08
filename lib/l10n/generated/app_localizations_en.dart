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
  String get globalSettings => 'Global settings';

  @override
  String get clearCache => 'Clear cache';

  @override
  String get clearCacheDescription =>
      'Remove cached Emby images and media information';

  @override
  String get clearCacheConfirmation =>
      'Cached images and media information will be deleted. Server and account details will remain. Continue?';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get cacheClearFailed => 'Could not clear cache. Please try again.';

  @override
  String get clear => 'Clear';

  @override
  String get moreOptions => 'More options';

  @override
  String get addServer => 'Add server';

  @override
  String get editServer => 'Edit server';

  @override
  String get save => 'Save';

  @override
  String get serverEditFailed =>
      'Failed to update the server. Please try again.';

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
  String get done => 'Done';

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
  String get homeFeatured => 'Featured';

  @override
  String get homeContinueWatching => 'Continue watching';

  @override
  String get homeLibraries => 'Libraries';

  @override
  String get libraryManage => 'Manage libraries';

  @override
  String get libraryManageTitle => 'Manage libraries';

  @override
  String get libraryShowOnHome => 'Show on home';

  @override
  String get libraryOrderHandle => 'Reorder library';

  @override
  String get libraryManageUnavailable =>
      'Library management is unavailable for this server.';

  @override
  String get libraryPreferencesSaveFailed =>
      'Could not save library preferences.';

  @override
  String get homeLoading => 'Loading your library…';

  @override
  String get homeLoadFailed =>
      'Could not load media. Check the server connection or sign in again.';

  @override
  String get homeRetry => 'Retry';

  @override
  String get homeNoItems => 'No items yet';

  @override
  String get homeViewAll => 'View all';

  @override
  String get librarySearch => 'Search this library';

  @override
  String get librarySearchClose => 'Close search';

  @override
  String get librarySearchClear => 'Clear search';

  @override
  String get librarySearchHint => 'Search movies and series';

  @override
  String get librarySearchNoResults => 'No matching movies or series';

  @override
  String get librarySort => 'Sort by';

  @override
  String get librarySortDateAdded => 'Date added';

  @override
  String get librarySortTitle => 'Title';

  @override
  String get librarySortCommunityRating => 'Community rating';

  @override
  String get librarySortCriticRating => 'Critic rating';

  @override
  String get librarySortProductionYear => 'Production year';

  @override
  String get librarySortPremiereDate => 'Premiere date';

  @override
  String get librarySortOfficialRating => 'Official rating';

  @override
  String get librarySortDatePlayed => 'Date played';

  @override
  String get librarySortRuntime => 'Runtime';

  @override
  String get librarySortBitrate => 'Bitrate';

  @override
  String get librarySortSize => 'Size';

  @override
  String get librarySortRandom => 'Random';

  @override
  String get librarySortUnsupported => 'Unsupported';

  @override
  String get librarySortAscending => 'Ascending';

  @override
  String get librarySortDescending => 'Descending';

  @override
  String get mediaDetailRetry => 'Retry';

  @override
  String get mediaDetailLoading => 'Loading media details…';

  @override
  String get mediaDetailLoadFailed =>
      'Could not load media details. Check the server connection or sign in again.';

  @override
  String get mediaDetailPlaybackFailed => 'Could not start playback.';

  @override
  String get mediaDetailNoOverview => 'No overview available';

  @override
  String get mediaDetailPlay => 'Play';

  @override
  String get mediaDetailPlaybackUnavailable => 'Playback is not connected yet';

  @override
  String get mediaDetailNoStreams => 'No media stream information available';

  @override
  String get mediaDetailChooseVersion => 'Version';

  @override
  String get mediaDetailUnknownVersion => 'Unknown version';

  @override
  String get mediaDetailChooseAudio => 'Audio';

  @override
  String get mediaDetailUnknownAudio => 'Unknown audio track';

  @override
  String mediaDetailDurationMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String mediaDetailDurationHoursMinutes(Object hours, Object minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String get mediaDetailCast => 'Cast and crew';

  @override
  String get mediaDetailNoPeople => 'No cast information available';

  @override
  String get mediaDetailDirector => 'Director';

  @override
  String get mediaDetailWriter => 'Writer';

  @override
  String get mediaDetailCrew => 'Crew';

  @override
  String get mediaDetailPhotos => 'Photos';

  @override
  String get mediaDetailNoImages => 'No images available';

  @override
  String get mediaDetailSimilar => 'More like this';

  @override
  String get mediaDetailNoSimilar => 'No similar items available';

  @override
  String get mediaDetailSeasons => 'Seasons';

  @override
  String get mediaDetailNoSeasons => 'No seasons available';

  @override
  String mediaDetailSeasonNumber(int number) {
    return 'Season $number';
  }

  @override
  String mediaDetailEpisodeNumber(int number) {
    return 'Episode $number';
  }

  @override
  String mediaDetailEpisodeCount(int count) {
    return '$count episodes';
  }

  @override
  String get mediaDetailNoEpisodes => 'No episodes available';

  @override
  String get mediaDetailStudios => 'Studios';

  @override
  String get mediaDetailNoStudio => 'No studio information available';

  @override
  String get mediaDetailExternalLinks => 'External links';

  @override
  String get mediaDetailNoExternalLinks => 'No external links available';

  @override
  String get mediaDetailTechnicalInfo => 'Media information';

  @override
  String get mediaDetailVersion => 'Version';

  @override
  String get mediaDetailTechContainer => 'Container';

  @override
  String get mediaDetailTechSize => 'Size';

  @override
  String get mediaDetailTechBitrate => 'Bitrate';

  @override
  String get mediaDetailTechVideo => 'Video';

  @override
  String get mediaDetailTechAudio => 'Audio';

  @override
  String get mediaDetailResolution => 'Resolution';

  @override
  String get mediaDetailFrameRate => 'Frame rate';

  @override
  String get mediaDetailVideoRange => 'Dynamic range';

  @override
  String get mediaDetailColorSpace => 'Color space';

  @override
  String get mediaDetailColorTransfer => 'Color transfer';

  @override
  String get mediaDetailStreamDefault => 'Default';

  @override
  String get mediaDetailStreamForced => 'Forced';

  @override
  String get mediaDetailStreamExternal => 'External';

  @override
  String get mediaDetailAddFavorite => 'Add to favorites';

  @override
  String get mediaDetailRemoveFavorite => 'Remove from favorites';

  @override
  String get mediaDetailFavoriteFailed => 'Could not update favorite status.';

  @override
  String get playerBack => 'Back';

  @override
  String get playerTracks => 'Audio and subtitles';

  @override
  String get playerAudio => 'Audio';

  @override
  String get playerSubtitles => 'Subtitles';

  @override
  String get playerSubtitlesOff => 'Off';

  @override
  String get playerSpeed => 'Playback speed';

  @override
  String get playerSpeedIncrease => 'Increase playback speed';

  @override
  String get playerSpeedDecrease => 'Decrease playback speed';

  @override
  String get playerLockControls => 'Lock controls';

  @override
  String get playerUnlockControls => 'Unlock controls';

  @override
  String get playerVideoFit => 'Change video fit';

  @override
  String get playerLandscape => 'Switch to landscape';

  @override
  String get playerPortrait => 'Switch to portrait';

  @override
  String get playerDecoderMode => 'Tap to change decoder mode';

  @override
  String get playerDecoderSwitchFailed => 'Unable to change decoder mode';

  @override
  String get playerMore => 'More options';

  @override
  String get playerUnmute => 'Unmute';

  @override
  String get playerSeek => 'Seek';

  @override
  String get playerBrightness => 'Brightness';

  @override
  String get playerVolume => 'Volume';

  @override
  String get playerPlay => 'Play';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerBack10 => 'Back 10 seconds';

  @override
  String get playerForward10 => 'Forward 10 seconds';

  @override
  String get playerSeekBackward => 'Double-tap rewind';

  @override
  String get playerSeekForward => 'Double-tap forward';

  @override
  String playerSeekSecondsValue(int seconds) {
    return '$seconds sec';
  }

  @override
  String get playerRetry => 'Retry';

  @override
  String get playerPlaybackFailed => 'Playback failed';

  @override
  String get playerQuality => 'Streaming quality';

  @override
  String get playerSettings => 'Player settings';

  @override
  String get playerQualityOriginal => 'Original quality';

  @override
  String get playerQualityLimit => 'Limit bitrate';

  @override
  String get playerSubtitleLanguage => 'Preferred subtitle language';

  @override
  String get playerSubtitleSize => 'Subtitle size';

  @override
  String get playerAudioPassthrough => 'Audio passthrough';

  @override
  String get playerHardwareAcceleration => 'Hardware decoding';

  @override
  String get playerCache => 'Playback cache';

  @override
  String get playerCacheDescription => 'Use disk cache while playing';

  @override
  String get playerCacheSize => 'Cache size';

  @override
  String playerCacheSizeValue(int size) {
    return '$size MB';
  }

  @override
  String get playerNextEpisode => 'Next episode';

  @override
  String get playerStats => 'Playback statistics';

  @override
  String get playerExternalSubtitles => 'External subtitles';

  @override
  String get playerRetrying => 'Retrying playback…';

  @override
  String get playerMute => 'Mute';

  @override
  String get playerSubtitleJapanese => 'Japanese';

  @override
  String get playerNoPlayableUrl => 'This media source has no direct-play URL.';

  @override
  String get playerInvalidPlaybackUrl =>
      'The server returned an invalid playback address.';

  @override
  String get playerNetworkError => 'Could not contact the media server.';

  @override
  String get playerPlaybackTimeout =>
      'The media server timed out. Please retry.';

  @override
  String get playerRequestFailed =>
      'The media server rejected the playback request.';

  @override
  String get playerSubtitleUnsupported =>
      'This subtitle format is not supported.';

  @override
  String get playerInvalidPlaybackResponse =>
      'The media server returned an invalid response.';

  @override
  String get playerStatsVideo => 'Video';

  @override
  String get playerStatsAudio => 'Audio';

  @override
  String get playerStatsBuffer => 'Buffer';

  @override
  String get playerStatsVolume => 'Volume';

  @override
  String get playerStatsMethod => 'Method';

  @override
  String get playerSettingsSaveFailed => 'Failed to save playback settings.';

  @override
  String get homeOverviewUnavailable => 'No overview available';

  @override
  String homeRating(Object rating) {
    return 'Rating $rating';
  }

  @override
  String homeServer(Object name) {
    return 'Server: $name';
  }

  @override
  String get homeRefreshing => 'Refreshing…';

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

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checkingForUpdates => 'Checking for updates…';

  @override
  String get latestVersionInstalled => 'You are using the latest version';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String updateAvailableMessage(Object currentVersion, Object latestVersion) {
    return 'Current version: $currentVersion\nLatest version: $latestVersion';
  }

  @override
  String get downloadUpdate => 'Download update';

  @override
  String get downloadingUpdate => 'Downloading update…';

  @override
  String downloadPercent(int percent) {
    return '$percent%';
  }

  @override
  String get openingUpdateInstaller => 'Download complete. Opening installer…';

  @override
  String get updateCheckFailed =>
      'Could not check for updates. Check your connection and retry.';

  @override
  String get updateDownloadFailed =>
      'Could not download the update. Please try again.';

  @override
  String get updateInstallerFailed =>
      'Could not open the installer. Check your system install permission.';

  @override
  String get updateInstallerStarted =>
      'Installer opened. Follow the system prompts to update.';
}
