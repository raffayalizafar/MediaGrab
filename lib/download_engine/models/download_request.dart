/// Represents a user request to download a video, audio, or playlist.
class DownloadRequest {
  final String url;
  final bool isAudioOnly;
  final String selectedQuality;
  final String outputFormat;
  final String outputDirectory;
  final bool embedSubtitles;
  final String subtitleLanguage;
  final bool embedMetadata;
  final bool embedThumbnail;
  final bool useAria2c;
  final String? customArgs;
  final bool isPlaylist;
  final String? playlistTitle;
  final List<int>? playlistIndices;
  final DateTime? scheduledAt;

  const DownloadRequest({
    required this.url,
    this.isAudioOnly = false,
    this.selectedQuality = 'Best',
    this.outputFormat = 'mp4',
    required this.outputDirectory,
    this.embedSubtitles = false,
    this.subtitleLanguage = 'en',
    this.embedMetadata = true,
    this.embedThumbnail = true,
    this.useAria2c = false,
    this.customArgs,
    this.isPlaylist = false,
    this.playlistTitle,
    this.playlistIndices,
    this.scheduledAt,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'is_audio_only': isAudioOnly,
    'selected_quality': selectedQuality,
    'output_format': outputFormat,
    'output_directory': outputDirectory,
    'embed_subtitles': embedSubtitles,
    'subtitle_language': subtitleLanguage,
    'embed_metadata': embedMetadata,
    'embed_thumbnail': embedThumbnail,
    'use_aria2c': useAria2c,
    'custom_args': customArgs,
    'is_playlist': isPlaylist,
    'playlist_title': playlistTitle,
    'playlist_indices': playlistIndices,
    'scheduled_at': scheduledAt?.toIso8601String(),
  };

  factory DownloadRequest.fromJson(Map<String, dynamic> json) =>
      DownloadRequest(
        url: json['url'] as String,
        isAudioOnly: json['is_audio_only'] as bool? ?? false,
        selectedQuality: json['selected_quality'] as String? ?? 'Best',
        outputFormat: json['output_format'] as String? ?? 'mp4',
        outputDirectory: json['output_directory'] as String? ?? '',
        embedSubtitles: json['embed_subtitles'] as bool? ?? false,
        subtitleLanguage: json['subtitle_language'] as String? ?? 'en',
        embedMetadata: json['embed_metadata'] as bool? ?? true,
        embedThumbnail: json['embed_thumbnail'] as bool? ?? true,
        useAria2c: json['use_aria2c'] as bool? ?? false,
        customArgs: json['custom_args'] as String?,
        isPlaylist: json['is_playlist'] as bool? ?? false,
        playlistTitle: json['playlist_title'] as String?,
        playlistIndices: (json['playlist_indices'] as List?)?.cast<int>(),
        scheduledAt: json['scheduled_at'] != null
            ? DateTime.parse(json['scheduled_at'] as String)
            : null,
      );
}
