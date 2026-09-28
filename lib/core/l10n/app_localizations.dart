import 'package:flutter/widgets.dart';

/// Lightweight, extensible localization dictionary for MediaGrab.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('zh'),
  ];

  // Strings
  String get appTitle => 'MediaGrab';
  String get home => 'Home';
  String get downloads => 'Downloads';
  String get templates => 'Templates';
  String get settings => 'Settings';

  String get pasteUrlHint => 'Paste video or audio link here...';
  String get paste => 'Paste';
  String get clear => 'Clear';
  String get quickDownload => 'Quick Download';
  String get configureDownload => 'Configure Download';
  String get fetchingInfo => 'Fetching media info...';
  String get invalidUrl => 'Please enter a valid URL';
  String get unsupportedUrl => 'Unable to resolve video stream from URL';

  String get video => 'Video';
  String get audio => 'Audio';
  String get quality => 'Quality';
  String get format => 'Format';
  String get subtitles => 'Subtitles';
  String get embedSubtitles => 'Embed Subtitles';
  String get embedMetadata => 'Embed Metadata & Tags';
  String get embedThumbnail => 'Embed Thumbnail Cover';
  String get startDownload => 'Start Download';

  String get activeDownloads => 'Active';
  String get completedDownloads => 'Completed';
  String get noActiveDownloads => 'No active downloads in progress';
  String get noCompletedDownloads => 'No completed downloads yet';
  String get pause => 'Pause';
  String get resume => 'Resume';
  String get cancel => 'Cancel';
  String get retry => 'Retry';
  String get delete => 'Delete';
  String get share => 'Share';
  String get open => 'Open';

  String get playlistDetected => 'Playlist Detected';
  String get selectAll => 'Select All';
  String get deselectAll => 'Deselect All';
  String get downloadSelected => 'Download Selected';

  String get customTemplates => 'Command Templates';
  String get newTemplate => 'New Template';
  String get templateName => 'Template Name';
  String get commandArguments => 'Command Arguments';
  String get save => 'Save';

  String get appearance => 'Appearance';
  String get themeMode => 'Theme Mode';
  String get dynamicColors => 'Material You Dynamic Colors';
  String get amoledDark => 'AMOLED Pure Black';
  String get downloadSettings => 'Download Settings';
  String get downloadLocation => 'Download Location';
  String get maxConcurrent => 'Max Concurrent Downloads';
  String get externalDownloader => 'External Downloader (aria2c)';
  String get enableAria2c => 'Accelerate with aria2c';
  String get about => 'About';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'es', 'fr', 'de', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
