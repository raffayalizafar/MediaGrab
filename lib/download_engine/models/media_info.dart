/// Represents metadata of a video or playlist retrieved before downloading.
class MediaInfo {
  final String url;
  final String title;
  final String author;
  final Duration duration;
  final String? thumbnailUrl;
  final String? description;
  final bool isPlaylist;
  final int? playlistCount;
  final List<String> availableQualities;
  final List<String> availableSubtitles;
  final int? viewCount;

  const MediaInfo({
    required this.url,
    required this.title,
    required this.author,
    this.duration = Duration.zero,
    this.thumbnailUrl,
    this.description,
    this.isPlaylist = false,
    this.playlistCount,
    this.availableQualities = const [],
    this.availableSubtitles = const [],
    this.viewCount,
  });

  String get durationFormatted {
    if (duration == Duration.zero) return '';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      return '$hours:${minutes.remainder(60).toString().padLeft(2, '0')}:$seconds';
    }
    return '$minutes:$seconds';
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    'author': author,
    'duration_seconds': duration.inSeconds,
    'thumbnail_url': thumbnailUrl,
    'description': description,
    'is_playlist': isPlaylist,
    'playlist_count': playlistCount,
    'available_qualities': availableQualities,
    'available_subtitles': availableSubtitles,
    'view_count': viewCount,
  };

  factory MediaInfo.fromJson(Map<String, dynamic> json) => MediaInfo(
    url: json['url'] as String? ?? '',
    title: json['title'] as String? ?? 'Untitled',
    author: json['author'] as String? ?? 'Unknown',
    duration: Duration(seconds: json['duration_seconds'] as int? ?? 0),
    thumbnailUrl: json['thumbnail_url'] as String?,
    description: json['description'] as String?,
    isPlaylist: json['is_playlist'] as bool? ?? false,
    playlistCount: json['playlist_count'] as int?,
    availableQualities:
        (json['available_qualities'] as List?)?.cast<String>() ?? [],
    availableSubtitles:
        (json['available_subtitles'] as List?)?.cast<String>() ?? [],
    viewCount: json['view_count'] as int?,
  );
}
