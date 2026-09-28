import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/logger_service.dart';
import '../../../download_engine/download_engine.dart';
import '../../../download_engine/engine_resolver.dart';
import '../../../download_engine/models/download_request.dart';
import '../../../download_engine/models/media_info.dart';
import '../../../download_engine/models/stream_option.dart';
import '../../downloads/providers/download_manager.dart';
import '../../settings/providers/settings_provider.dart';

enum HomeStateStatus { idle, fetchingInfo, ready, downloading, error }

class HomeState {
  final HomeStateStatus status;
  final String url;
  final MediaInfo? mediaInfo;
  final List<StreamOption> streamOptions;
  final String? errorMessage;
  final bool isAudioOnly;
  final String selectedQuality;
  final String selectedFormat;
  final bool embedSubtitles;
  final String subtitleLanguage;
  final bool embedMetadata;
  final bool embedThumbnail;
  final bool isQuickLoading;
  final String? customOutputDirectory;
  final DateTime? scheduledAt;

  const HomeState({
    this.status = HomeStateStatus.idle,
    this.url = '',
    this.mediaInfo,
    this.streamOptions = const [],
    this.errorMessage,
    this.isAudioOnly = false,
    this.selectedQuality = AppConstants.defaultVideoQuality,
    this.selectedFormat = AppConstants.defaultVideoFormat,
    this.embedSubtitles = true,
    this.subtitleLanguage = AppConstants.defaultSubtitleLang,
    this.embedMetadata = true,
    this.embedThumbnail = true,
    this.isQuickLoading = false,
    this.customOutputDirectory,
    this.scheduledAt,
  });

  HomeState copyWith({
    HomeStateStatus? status,
    String? url,
    MediaInfo? mediaInfo,
    List<StreamOption>? streamOptions,
    String? errorMessage,
    bool? isAudioOnly,
    String? selectedQuality,
    String? selectedFormat,
    bool? embedSubtitles,
    String? subtitleLanguage,
    bool? embedMetadata,
    bool? embedThumbnail,
    bool? isQuickLoading,
    String? customOutputDirectory,
    bool clearCustomOutputDirectory = false,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      url: url ?? this.url,
      mediaInfo: mediaInfo ?? this.mediaInfo,
      streamOptions: streamOptions ?? this.streamOptions,
      errorMessage: errorMessage,
      isAudioOnly: isAudioOnly ?? this.isAudioOnly,
      selectedQuality: selectedQuality ?? this.selectedQuality,
      selectedFormat: selectedFormat ?? this.selectedFormat,
      embedSubtitles: embedSubtitles ?? this.embedSubtitles,
      subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
      embedMetadata: embedMetadata ?? this.embedMetadata,
      embedThumbnail: embedThumbnail ?? this.embedThumbnail,
      isQuickLoading: isQuickLoading ?? this.isQuickLoading,
      customOutputDirectory: clearCustomOutputDirectory
          ? null
          : (customOutputDirectory ?? this.customOutputDirectory),
      scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
    );
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final downloadManager = ref.watch(downloadManagerProvider.notifier);
  final settings = ref.watch(settingsProvider);
  return HomeNotifier(downloadManager, settings);
});

class HomeNotifier extends StateNotifier<HomeState> {
  final DownloadManager _downloadManager;
  final SettingsState _settings;
  DownloadEngine? _engine;
  int _currentFetchToken = 0;

  HomeNotifier(this._downloadManager, this._settings)
    : super(
        HomeState(
          isAudioOnly: _settings.defaultDownloadMode == 'audio',
          selectedQuality: _settings.defaultVideoQuality,
          selectedFormat: _settings.defaultDownloadMode == 'audio'
              ? _settings.defaultAudioFormat
              : _settings.defaultVideoFormat,
          embedSubtitles: _settings.embedSubtitles,
          subtitleLanguage: _settings.subtitleLanguage,
          embedMetadata: _settings.embedMetadata,
          embedThumbnail: _settings.embedThumbnail,
        ),
      );

  void setUrl(String url) {
    state = state.copyWith(url: url, errorMessage: null);
  }

  /// Cancels an in-flight media fetch request and resets status back to idle.
  Future<void> cancelFetch() async {
    _currentFetchToken++;
    if (state.status == HomeStateStatus.fetchingInfo || state.isQuickLoading) {
      state = state.copyWith(
        status: HomeStateStatus.idle,
        isQuickLoading: false,
        errorMessage: null,
      );
      LoggerService.info(
        'HomeNotifier: fetch/loading request cancelled by user',
      );
      try {
        await _engine?.cancelFetch();
      } catch (e) {
        LoggerService.error('Error in engine.cancelFetch: $e');
      }
    }
  }

  void setAudioOnly(bool isAudio) {
    state = state.copyWith(
      isAudioOnly: isAudio,
      selectedFormat: isAudio
          ? _settings.defaultAudioFormat
          : _settings.defaultVideoFormat,
    );
  }

  void setSelectedQuality(String quality) {
    state = state.copyWith(selectedQuality: quality);
  }

  void setSelectedFormat(String format) {
    state = state.copyWith(selectedFormat: format);
  }

  void setEmbedSubtitles(bool embed) {
    state = state.copyWith(embedSubtitles: embed);
  }

  void setSubtitleLanguage(String lang) {
    state = state.copyWith(subtitleLanguage: lang);
  }

  void setEmbedMetadata(bool embed) {
    state = state.copyWith(embedMetadata: embed);
  }

  void setEmbedThumbnail(bool embed) {
    state = state.copyWith(embedThumbnail: embed);
  }

  void setCustomOutputDirectory(String? path) {
    if (path == null) {
      state = state.copyWith(clearCustomOutputDirectory: true);
    } else {
      state = state.copyWith(customOutputDirectory: path);
    }
  }

  Future<void> fetchInfo(String rawUrl) async {
    final cleanUrl = rawUrl.trim();
    if (cleanUrl.isEmpty) {
      state = state.copyWith(
        status: HomeStateStatus.error,
        errorMessage: 'Please enter a valid URL',
      );
      return;
    }

    final token = ++_currentFetchToken;

    state = state.copyWith(
      status: HomeStateStatus.fetchingInfo,
      url: cleanUrl,
      errorMessage: null,
    );

    try {
      _engine ??= await EngineResolver.resolveDefaultEngine();
      if (_currentFetchToken != token) return;

      final results = await Future.wait([
        _engine!.fetchMediaInfo(cleanUrl),
        _engine!.getAvailableStreams(cleanUrl),
      ]);
      if (_currentFetchToken != token) return;

      final info = results[0] as MediaInfo;
      final streams = results[1] as List<StreamOption>;

      state = state.copyWith(
        status: HomeStateStatus.ready,
        mediaInfo: info,
        streamOptions: streams,
        selectedQuality: info.availableQualities.isNotEmpty
            ? info.availableQualities.first
            : state.selectedQuality,
      );
    } catch (e) {
      if (_currentFetchToken != token) return;
      LoggerService.error('Error fetching info in HomeNotifier: $e');
      state = state.copyWith(
        status: HomeStateStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Quick download starts immediately using current defaults without waiting on stream lists.
  Future<void> quickDownload(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      state = state.copyWith(
        status: HomeStateStatus.error,
        errorMessage: 'Please enter a valid URL',
      );
      return;
    }

    final token = ++_currentFetchToken;

    state = state.copyWith(
      isQuickLoading: true,
      status: HomeStateStatus.fetchingInfo,
      url: cleanUrl,
      errorMessage: null,
    );

    try {
      _engine ??= await EngineResolver.resolveDefaultEngine();
      if (_currentFetchToken != token) return;

      final info = await _engine!.fetchMediaInfo(cleanUrl);
      if (_currentFetchToken != token) return;

      final request = DownloadRequest(
        url: cleanUrl,
        isAudioOnly: state.isAudioOnly,
        selectedQuality: state.selectedQuality,
        outputFormat: state.selectedFormat,
        outputDirectory:
            state.customOutputDirectory ?? _settings.downloadDirectory,
        embedSubtitles: state.embedSubtitles,
        subtitleLanguage: state.subtitleLanguage,
        embedMetadata: state.embedMetadata,
        embedThumbnail: state.embedThumbnail,
        useAria2c: _settings.useAria2c,
        customArgs: _settings.customYtDlpArgs,
        isPlaylist: info.isPlaylist,
        playlistTitle: info.isPlaylist ? info.title : null,
      );

      await _downloadManager.enqueueDownload(request, info);

      // Reset state back to idle immediately
      state = state.copyWith(
        isQuickLoading: false,
        status: HomeStateStatus.idle,
        url: '',
        mediaInfo: null,
        streamOptions: [],
        clearCustomOutputDirectory: true,
      );
    } catch (e) {
      if (_currentFetchToken != token) return;
      LoggerService.error('Quick download failed: $e');
      state = state.copyWith(
        isQuickLoading: false,
        status: HomeStateStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setScheduledAt(DateTime? scheduledAt) {
    state = state.copyWith(
      scheduledAt: scheduledAt,
      clearScheduledAt: scheduledAt == null,
    );
  }

  /// Enqueues the configured download.
  Future<void> startDownload({String? customArgs}) async {
    if (state.mediaInfo == null) return;

    final request = DownloadRequest(
      url: state.url,
      isAudioOnly: state.isAudioOnly,
      selectedQuality: state.selectedQuality,
      outputFormat: state.selectedFormat,
      outputDirectory:
          state.customOutputDirectory ?? _settings.downloadDirectory,
      embedSubtitles: state.embedSubtitles,
      subtitleLanguage: state.subtitleLanguage,
      embedMetadata: state.embedMetadata,
      embedThumbnail: state.embedThumbnail,
      useAria2c: _settings.useAria2c,
      customArgs: customArgs ?? _settings.customYtDlpArgs,
      isPlaylist: state.mediaInfo!.isPlaylist,
      playlistTitle: state.mediaInfo!.isPlaylist
          ? state.mediaInfo!.title
          : null,
      scheduledAt: state.scheduledAt,
    );

    await _downloadManager.enqueueDownload(request, state.mediaInfo!);

    // Reset state back to idle for next download
    state = state.copyWith(
      status: HomeStateStatus.idle,
      url: '',
      mediaInfo: null,
      streamOptions: [],
      clearCustomOutputDirectory: true,
      clearScheduledAt: true,
    );
  }

  void reset() {
    state = state.copyWith(
      status: HomeStateStatus.idle,
      mediaInfo: null,
      streamOptions: [],
      errorMessage: null,
      clearCustomOutputDirectory: true,
      clearScheduledAt: true,
    );
  }
}
