import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';

/// Provider for raw StorageService dependency injection.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized in main()');
});

/// State representation of all user-configurable settings.
class SettingsState {
  final ThemeMode themeMode;
  final bool useDynamicColor;
  final bool isAmoledDark;
  final String defaultDownloadMode;
  final String defaultVideoQuality;
  final String defaultVideoFormat;
  final String defaultAudioFormat;
  final int maxConcurrentDownloads;
  final bool embedSubtitles;
  final String subtitleLanguage;
  final bool embedMetadata;
  final bool embedThumbnail;
  final bool useAria2c;
  final String customYtDlpArgs;
  final String downloadDirectory;
  final bool downloadOverWifiOnly;
  final bool autoResumeOnReconnect;
  final bool slowSpeedWarning;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.useDynamicColor = true,
    this.isAmoledDark = false,
    this.defaultDownloadMode = 'video',
    this.defaultVideoQuality = AppConstants.defaultVideoQuality,
    this.defaultVideoFormat = AppConstants.defaultVideoFormat,
    this.defaultAudioFormat = AppConstants.defaultAudioFormat,
    this.maxConcurrentDownloads = AppConstants.defaultMaxConcurrentDownloads,
    this.embedSubtitles = true,
    this.subtitleLanguage = AppConstants.defaultSubtitleLang,
    this.embedMetadata = true,
    this.embedThumbnail = true,
    this.useAria2c = false,
    this.customYtDlpArgs = '',
    this.downloadDirectory = '',
    this.downloadOverWifiOnly = false,
    this.autoResumeOnReconnect = true,
    this.slowSpeedWarning = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? useDynamicColor,
    bool? isAmoledDark,
    String? defaultDownloadMode,
    String? defaultVideoQuality,
    String? defaultVideoFormat,
    String? defaultAudioFormat,
    int? maxConcurrentDownloads,
    bool? embedSubtitles,
    String? subtitleLanguage,
    bool? embedMetadata,
    bool? embedThumbnail,
    bool? useAria2c,
    String? customYtDlpArgs,
    String? downloadDirectory,
    bool? downloadOverWifiOnly,
    bool? autoResumeOnReconnect,
    bool? slowSpeedWarning,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      isAmoledDark: isAmoledDark ?? this.isAmoledDark,
      defaultDownloadMode: defaultDownloadMode ?? this.defaultDownloadMode,
      defaultVideoQuality: defaultVideoQuality ?? this.defaultVideoQuality,
      defaultVideoFormat: defaultVideoFormat ?? this.defaultVideoFormat,
      defaultAudioFormat: defaultAudioFormat ?? this.defaultAudioFormat,
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      embedSubtitles: embedSubtitles ?? this.embedSubtitles,
      subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
      embedMetadata: embedMetadata ?? this.embedMetadata,
      embedThumbnail: embedThumbnail ?? this.embedThumbnail,
      useAria2c: useAria2c ?? this.useAria2c,
      customYtDlpArgs: customYtDlpArgs ?? this.customYtDlpArgs,
      downloadDirectory: downloadDirectory ?? this.downloadDirectory,
      downloadOverWifiOnly: downloadOverWifiOnly ?? this.downloadOverWifiOnly,
      autoResumeOnReconnect:
          autoResumeOnReconnect ?? this.autoResumeOnReconnect,
      slowSpeedWarning: slowSpeedWarning ?? this.slowSpeedWarning,
    );
  }
}

/// Global settings state notifier provider.
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final storage = ref.watch(storageServiceProvider);
    return SettingsNotifier(storage);
  },
);

class SettingsNotifier extends StateNotifier<SettingsState> {
  final StorageService _storage;

  SettingsNotifier(this._storage)
    : super(
        SettingsState(
          themeMode: _parseThemeMode(_storage.themeMode),
          useDynamicColor: _storage.useDynamicColor,
          isAmoledDark: _storage.isAmoledDark,
          defaultDownloadMode: _storage.defaultDownloadMode,
          defaultVideoQuality: _storage.defaultVideoQuality,
          defaultVideoFormat: _storage.defaultVideoFormat,
          defaultAudioFormat: _storage.defaultAudioFormat,
          maxConcurrentDownloads: _storage.maxConcurrentDownloads,
          embedSubtitles: _storage.embedSubtitles,
          subtitleLanguage: _storage.subtitleLanguage,
          embedMetadata: _storage.embedMetadata,
          embedThumbnail: _storage.embedThumbnail,
          useAria2c: _storage.useAria2c,
          customYtDlpArgs: _storage.customYtDlpArgs,
          downloadOverWifiOnly: _storage.downloadOverWifiOnly,
          autoResumeOnReconnect: _storage.autoResumeOnReconnect,
          slowSpeedWarning: _storage.slowSpeedWarning,
        ),
      ) {
    _loadFromStorage();
  }

  static ThemeMode _parseThemeMode(String modeStr) {
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _loadFromStorage() async {
    final mode = _parseThemeMode(_storage.themeMode);
    final dlDir = await _storage.getDownloadDirectory();

    state = SettingsState(
      themeMode: mode,
      useDynamicColor: _storage.useDynamicColor,
      isAmoledDark: _storage.isAmoledDark,
      defaultDownloadMode: _storage.defaultDownloadMode,
      defaultVideoQuality: _storage.defaultVideoQuality,
      defaultVideoFormat: _storage.defaultVideoFormat,
      defaultAudioFormat: _storage.defaultAudioFormat,
      maxConcurrentDownloads: _storage.maxConcurrentDownloads,
      embedSubtitles: _storage.embedSubtitles,
      subtitleLanguage: _storage.subtitleLanguage,
      embedMetadata: _storage.embedMetadata,
      embedThumbnail: _storage.embedThumbnail,
      useAria2c: _storage.useAria2c,
      customYtDlpArgs: _storage.customYtDlpArgs,
      downloadDirectory: dlDir,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _storage.setThemeMode(mode.name);
  }

  Future<void> setUseDynamicColor(bool value) async {
    state = state.copyWith(useDynamicColor: value);
    await _storage.setUseDynamicColor(value);
  }

  Future<void> setAmoledDark(bool value) async {
    state = state.copyWith(isAmoledDark: value);
    await _storage.setAmoledDark(value);
  }

  Future<void> setDefaultDownloadMode(String mode) async {
    state = state.copyWith(defaultDownloadMode: mode);
    await _storage.setDefaultDownloadMode(mode);
  }

  Future<void> setDefaultVideoQuality(String quality) async {
    state = state.copyWith(defaultVideoQuality: quality);
    await _storage.setDefaultVideoQuality(quality);
  }

  Future<void> setDefaultVideoFormat(String format) async {
    state = state.copyWith(defaultVideoFormat: format);
    await _storage.setDefaultVideoFormat(format);
  }

  Future<void> setDefaultAudioFormat(String format) async {
    state = state.copyWith(defaultAudioFormat: format);
    await _storage.setDefaultAudioFormat(format);
  }

  Future<void> setMaxConcurrentDownloads(int value) async {
    state = state.copyWith(maxConcurrentDownloads: value);
    await _storage.setMaxConcurrentDownloads(value);
  }

  Future<void> setEmbedSubtitles(bool value) async {
    state = state.copyWith(embedSubtitles: value);
    await _storage.setEmbedSubtitles(value);
  }

  Future<void> setSubtitleLanguage(String lang) async {
    state = state.copyWith(subtitleLanguage: lang);
    await _storage.setSubtitleLanguage(lang);
  }

  Future<void> setEmbedMetadata(bool value) async {
    state = state.copyWith(embedMetadata: value);
    await _storage.setEmbedMetadata(value);
  }

  Future<void> setEmbedThumbnail(bool value) async {
    state = state.copyWith(embedThumbnail: value);
    await _storage.setEmbedThumbnail(value);
  }

  Future<void> setUseAria2c(bool value) async {
    state = state.copyWith(useAria2c: value);
    await _storage.setUseAria2c(value);
  }

  Future<void> setCustomYtDlpArgs(String args) async {
    state = state.copyWith(customYtDlpArgs: args);
    await _storage.setCustomYtDlpArgs(args);
  }

  Future<void> setDownloadDirectory(String dir) async {
    state = state.copyWith(downloadDirectory: dir);
    await _storage.setDownloadDirectory(dir);
  }

  Future<void> resetDownloadDirectory() async {
    await _storage.resetDownloadDirectory();
    final defaultDir = await _storage.getDownloadDirectory();
    state = state.copyWith(downloadDirectory: defaultDir);
  }

  Future<void> setDownloadOverWifiOnly(bool value) async {
    state = state.copyWith(downloadOverWifiOnly: value);
    await _storage.setDownloadOverWifiOnly(value);
  }

  Future<void> setAutoResumeOnReconnect(bool value) async {
    state = state.copyWith(autoResumeOnReconnect: value);
    await _storage.setAutoResumeOnReconnect(value);
  }

  Future<void> setSlowSpeedWarning(bool value) async {
    state = state.copyWith(slowSpeedWarning: value);
    await _storage.setSlowSpeedWarning(value);
  }
}
