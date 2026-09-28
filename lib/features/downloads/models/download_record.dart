/// Stored history record for completed or historical downloads.
class DownloadRecord {
  final String id;
  final String title;
  final String author;
  final String url;
  final String format;
  final String quality;
  final bool isAudioOnly;
  final String filePath;
  final int fileSizeBytes;
  final String? thumbnailUrl;
  final DateTime dateCompleted;

  const DownloadRecord({
    required this.id,
    required this.title,
    required this.author,
    required this.url,
    required this.format,
    required this.quality,
    required this.isAudioOnly,
    required this.filePath,
    required this.fileSizeBytes,
    this.thumbnailUrl,
    required this.dateCompleted,
  });

  String get formattedSize {
    if (fileSizeBytes <= 0) return '';
    final mb = fileSizeBytes / (1024 * 1024);
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'url': url,
    'format': format,
    'quality': quality,
    'is_audio_only': isAudioOnly,
    'file_path': filePath,
    'file_size_bytes': fileSizeBytes,
    'thumbnail_url': thumbnailUrl,
    'date_completed': dateCompleted.toIso8601String(),
  };

  factory DownloadRecord.fromJson(Map<String, dynamic> json) => DownloadRecord(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Untitled',
    author: json['author'] as String? ?? 'Unknown',
    url: json['url'] as String? ?? '',
    format: json['format'] as String? ?? 'mp4',
    quality: json['quality'] as String? ?? 'Best',
    isAudioOnly: json['is_audio_only'] as bool? ?? false,
    filePath: json['file_path'] as String? ?? '',
    fileSizeBytes: json['file_size_bytes'] as int? ?? 0,
    thumbnailUrl: json['thumbnail_url'] as String?,
    dateCompleted: DateTime.parse(
      json['date_completed'] as String? ?? DateTime.now().toIso8601String(),
    ),
  );
}
