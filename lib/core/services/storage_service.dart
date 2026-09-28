import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../errors/logger_service.dart';

/// Centralized storage service for application settings, downloads history, and templates.
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Getters & Setters ---

  String get themeMode =>
      _prefs.getString(AppConstants.keyThemeMode) ?? 'system';
  Future<bool> setThemeMode(String value) =>
      _prefs.setString(AppConstants.keyThemeMode, value);

  bool get useDynamicColor =>
      _prefs.getBool(AppConstants.keyUseDynamicColor) ?? true;
  Future<bool> setUseDynamicColor(bool value) =>
      _prefs.setBool(AppConstants.keyUseDynamicColor, value);

  bool get isAmoledDark => _prefs.getBool(AppConstants.keyAmoledDark) ?? false;
  Future<bool> setAmoledDark(bool value) =>
      _prefs.setBool(AppConstants.keyAmoledDark, value);

  String get defaultDownloadMode =>
      _prefs.getString(AppConstants.keyDefaultDownloadMode) ?? 'video';
  Future<bool> setDefaultDownloadMode(String value) =>
      _prefs.setString(AppConstants.keyDefaultDownloadMode, value);

  String get defaultVideoQuality =>
      _prefs.getString(AppConstants.keyDefaultVideoQuality) ??
      AppConstants.defaultVideoQuality;
  Future<bool> setDefaultVideoQuality(String value) =>
      _prefs.setString(AppConstants.keyDefaultVideoQuality, value);

  String get defaultVideoFormat =>
      _prefs.getString(AppConstants.keyDefaultVideoFormat) ??
      AppConstants.defaultVideoFormat;
  Future<bool> setDefaultVideoFormat(String value) =>
      _prefs.setString(AppConstants.keyDefaultVideoFormat, value);

  String get defaultAudioFormat =>
      _prefs.getString(AppConstants.keyDefaultAudioFormat) ??
      AppConstants.defaultAudioFormat;
  Future<bool> setDefaultAudioFormat(String value) =>
      _prefs.setString(AppConstants.keyDefaultAudioFormat, value);

  int get maxConcurrentDownloads =>
      _prefs.getInt(AppConstants.keyMaxConcurrentDownloads) ??
      AppConstants.defaultMaxConcurrentDownloads;
  Future<bool> setMaxConcurrentDownloads(int value) =>
      _prefs.setInt(AppConstants.keyMaxConcurrentDownloads, value);

  bool get embedSubtitles =>
      _prefs.getBool(AppConstants.keyEmbedSubtitles) ?? true;
  Future<bool> setEmbedSubtitles(bool value) =>
      _prefs.setBool(AppConstants.keyEmbedSubtitles, value);

  String get subtitleLanguage =>
      _prefs.getString(AppConstants.keySubtitleLanguage) ??
      AppConstants.defaultSubtitleLang;
  Future<bool> setSubtitleLanguage(String value) =>
      _prefs.setString(AppConstants.keySubtitleLanguage, value);

  bool get embedMetadata =>
      _prefs.getBool(AppConstants.keyEmbedMetadata) ?? true;
  Future<bool> setEmbedMetadata(bool value) =>
      _prefs.setBool(AppConstants.keyEmbedMetadata, value);

  bool get embedThumbnail =>
      _prefs.getBool(AppConstants.keyEmbedThumbnail) ?? true;
  Future<bool> setEmbedThumbnail(bool value) =>
      _prefs.setBool(AppConstants.keyEmbedThumbnail, value);

  bool get useAria2c => _prefs.getBool(AppConstants.keyUseAria2c) ?? false;
  Future<bool> setUseAria2c(bool value) =>
      _prefs.setBool(AppConstants.keyUseAria2c, value);

  String get customYtDlpArgs =>
      _prefs.getString(AppConstants.keyCustomYtDlpArgs) ?? '';
  Future<bool> setCustomYtDlpArgs(String value) =>
      _prefs.setString(AppConstants.keyCustomYtDlpArgs, value);

  bool get downloadOverWifiOnly =>
      _prefs.getBool(AppConstants.keyDownloadOverWifiOnly) ?? false;
  Future<bool> setDownloadOverWifiOnly(bool value) =>
      _prefs.setBool(AppConstants.keyDownloadOverWifiOnly, value);

  bool get autoResumeOnReconnect =>
      _prefs.getBool(AppConstants.keyAutoResumeOnReconnect) ?? true;
  Future<bool> setAutoResumeOnReconnect(bool value) =>
      _prefs.setBool(AppConstants.keyAutoResumeOnReconnect, value);

  bool get slowSpeedWarning =>
      _prefs.getBool(AppConstants.keySlowSpeedWarning) ?? true;
  Future<bool> setSlowSpeedWarning(bool value) =>
      _prefs.setBool(AppConstants.keySlowSpeedWarning, value);

  // --- Download Directory Resolution ---

  static Future<void> _ensureCategorySubdirs(String basePath) async {
    try {
      final v = Directory(p.join(basePath, 'video'));
      if (!await v.exists()) await v.create(recursive: true);
      final a = Directory(p.join(basePath, 'audio'));
      if (!await a.exists()) await a.create(recursive: true);
    } catch (e) {
      LoggerService.warning('Failed to initialize media subdirectories: $e');
    }
  }

  Future<String> getDownloadDirectory() async {
    final customPath = _prefs.getString(AppConstants.keyDefaultDownloadDir);
    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (await dir.exists()) {
        await _ensureCategorySubdirs(dir.path);
        return customPath;
      }
    }

    // Try standard Desktop Downloads directory via environment
    if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        final downloads = Directory(p.join(home, 'Downloads', 'MediaGrab'));
        try {
          if (!await downloads.exists()) {
            await downloads.create(recursive: true);
          }
          await _ensureCategorySubdirs(downloads.path);
          return downloads.path;
        } catch (_) {}
      }
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        final downloads = Directory(
          p.join(userProfile, 'Downloads', 'MediaGrab'),
        );
        try {
          if (!await downloads.exists()) {
            await downloads.create(recursive: true);
          }
          await _ensureCategorySubdirs(downloads.path);
          return downloads.path;
        } catch (_) {}
      }
    }

    try {
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final mediaGrabDir = Directory(p.join(extDir.path, 'MediaGrab'));
          if (!await mediaGrabDir.exists()) {
            await mediaGrabDir.create(recursive: true);
          }
          await _ensureCategorySubdirs(mediaGrabDir.path);
          return mediaGrabDir.path;
        }
      }

      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final mediaGrabDir = Directory(p.join(downloadsDir.path, 'MediaGrab'));
        if (!await mediaGrabDir.exists()) {
          await mediaGrabDir.create(recursive: true);
        }
        await _ensureCategorySubdirs(mediaGrabDir.path);
        return mediaGrabDir.path;
      }

      final docDir = await getApplicationDocumentsDirectory();
      final mediaGrabDir = Directory(p.join(docDir.path, 'MediaGrab'));
      if (!await mediaGrabDir.exists()) {
        await mediaGrabDir.create(recursive: true);
      }
      await _ensureCategorySubdirs(mediaGrabDir.path);
      return mediaGrabDir.path;
    } catch (e) {
      LoggerService.warning('Error resolving standard download directory: $e');
    }

    // Ultimate fallback: system temporary directory with MediaGrab subfolder
    final fallback = Directory(p.join(Directory.systemTemp.path, 'MediaGrab'));
    if (!await fallback.exists()) {
      await fallback.create(recursive: true);
    }
    await _ensureCategorySubdirs(fallback.path);
    return fallback.path;
  }

  Future<bool> setDownloadDirectory(String path) async {
    await _ensureCategorySubdirs(path);
    return _prefs.setString(AppConstants.keyDefaultDownloadDir, path);
  }

  Future<bool> resetDownloadDirectory() =>
      _prefs.remove(AppConstants.keyDefaultDownloadDir);

  // --- Saved History & Templates (JSON list in Prefs) ---

  List<Map<String, dynamic>> getSavedHistory() {
    final raw = _prefs.getString(AppConstants.keyDownloadHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      LoggerService.error('Failed to parse download history: $e');
      return [];
    }
  }

  Future<bool> saveHistory(List<Map<String, dynamic>> records) {
    return _prefs.setString(
      AppConstants.keyDownloadHistory,
      jsonEncode(records),
    );
  }

  List<Map<String, dynamic>> getSavedTemplates() {
    final raw = _prefs.getString(AppConstants.keySavedTemplates);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      LoggerService.error('Failed to parse saved templates: $e');
      return [];
    }
  }

  Future<bool> saveTemplates(List<Map<String, dynamic>> templates) {
    return _prefs.setString(
      AppConstants.keySavedTemplates,
      jsonEncode(templates),
    );
  }
}
