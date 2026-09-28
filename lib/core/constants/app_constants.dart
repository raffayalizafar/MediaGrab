/// Global constants for the MediaGrab application.
class AppConstants {
  static const String appName = 'MediaGrab';
  static const String appTagline = 'Fast, Beautiful & Modern Media Downloader';
  static const String appVersion = '1.0.0-beta.1';
  static const String githubRepo =
      'https://github.com/raffayalizafar/MediaGrab';

  // Storage keys
  static const String keyThemeMode = 'settings_theme_mode';
  static const String keyUseDynamicColor = 'settings_use_dynamic_color';
  static const String keyAmoledDark = 'settings_amoled_dark';
  static const String keyDefaultDownloadDir = 'settings_download_dir';
  static const String keyDefaultDownloadMode =
      'settings_download_mode'; // 'video' or 'audio'
  static const String keyDefaultVideoQuality = 'settings_video_quality';
  static const String keyDefaultVideoFormat = 'settings_video_format';
  static const String keyDefaultAudioFormat = 'settings_audio_format';
  static const String keyMaxConcurrentDownloads =
      'settings_max_concurrent_downloads';
  static const String keyEmbedSubtitles = 'settings_embed_subtitles';
  static const String keySubtitleLanguage = 'settings_subtitle_language';
  static const String keyEmbedMetadata = 'settings_embed_metadata';
  static const String keyEmbedThumbnail = 'settings_embed_thumbnail';
  static const String keyUseAria2c = 'settings_use_aria2c';
  static const String keyCustomYtDlpArgs = 'settings_custom_ytdlp_args';
  static const String keyDownloadOverWifiOnly = 'settings_download_wifi_only';
  static const String keyAutoResumeOnReconnect =
      'settings_auto_resume_reconnect';
  static const String keySlowSpeedWarning = 'settings_slow_speed_warning';
  static const String keySavedTemplates = 'saved_command_templates';
  static const String keyDownloadHistory = 'download_history_records';

  // Defaults
  static const int defaultMaxConcurrentDownloads = 3;
  static const String defaultVideoFormat = 'mp4';
  static const String defaultAudioFormat = 'mp3';
  static const String defaultVideoQuality = '1080p';
  static const String defaultSubtitleLang = 'en';

  // Supported Formats
  static const List<String> videoFormats = ['mp4', 'mkv', 'webm', 'mov'];
  static const List<String> audioFormats = [
    'mp3',
    'm4a',
    'aac',
    'opus',
    'flac',
    'wav',
  ];
  static const List<String> commonResolutions = [
    'Best',
    '4320p',
    '2160p',
    '1440p',
    '1080p',
    '720p',
    '480p',
    '360p',
  ];
  static const List<String> commonAudioBitrates = [
    'Best',
    '320 kbps',
    '256 kbps',
    '160 kbps',
    '128 kbps',
    '70 kbps',
  ];
}
