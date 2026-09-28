/// Represents a stream/format option (video resolution or audio bitrate).
class StreamOption {
  final String label;
  final String format; // mp4, webm, m4a, mp3, etc.
  final bool isAudioOnly;
  final bool isMuxed;
  final int? width;
  final int? height;
  final int? sizeBytes;
  final int? bitrate;
  final String? codec;
  final int? itag;
  final int? fps;

  const StreamOption({
    required this.label,
    required this.format,
    this.isAudioOnly = false,
    this.isMuxed = false,
    this.width,
    this.height,
    this.sizeBytes,
    this.bitrate,
    this.codec,
    this.itag,
    this.fps,
  });

  String get formattedSize {
    if (sizeBytes == null || sizeBytes! <= 0) return '';
    final mb = sizeBytes! / (1024 * 1024);
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'format': format,
    'is_audio_only': isAudioOnly,
    'is_muxed': isMuxed,
    'width': width,
    'height': height,
    'size_bytes': sizeBytes,
    'bitrate': bitrate,
    'codec': codec,
    'itag': itag,
    'fps': fps,
  };

  factory StreamOption.fromJson(Map<String, dynamic> json) => StreamOption(
    label: json['label'] as String? ?? '',
    format: json['format'] as String? ?? 'mp4',
    isAudioOnly: json['is_audio_only'] as bool? ?? false,
    isMuxed: json['is_muxed'] as bool? ?? false,
    width: json['width'] as int?,
    height: json['height'] as int?,
    sizeBytes: json['size_bytes'] as int?,
    bitrate: json['bitrate'] as int?,
    codec: json['codec'] as String?,
    itag: json['itag'] as int?,
    fps: json['fps'] as int?,
  );
}
