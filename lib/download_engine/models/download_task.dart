import 'download_progress.dart';
import 'download_request.dart';
import 'media_info.dart';

/// Status of a download operation.
enum DownloadStatus {
  queued,
  fetchingMetadata,
  downloading,
  muxing,
  completed,
  failed,
  paused,
  scheduled,
  cancelled;

  bool get isActive =>
      this == queued ||
      this == fetchingMetadata ||
      this == downloading ||
      this == muxing ||
      this == paused ||
      this == scheduled;

  bool get isDone => this == completed || this == failed || this == cancelled;

  bool get isPaused => this == paused;
  bool get isScheduled => this == scheduled;
  bool get isDownloading => this == downloading;
}

/// Represents an individual download job.
class DownloadTask {
  final String id;
  final DownloadRequest request;
  final MediaInfo mediaInfo;
  final DownloadStatus status;
  final DownloadProgress progress;
  final String? filePath;
  final String? errorMessage;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? scheduledAt;

  const DownloadTask({
    required this.id,
    required this.request,
    required this.mediaInfo,
    this.status = DownloadStatus.queued,
    this.progress = const DownloadProgress(),
    this.filePath,
    this.errorMessage,
    required this.startedAt,
    this.completedAt,
    this.scheduledAt,
  });

  bool get isPaused => status.isPaused;
  bool get isScheduled => status.isScheduled;
  bool get isDownloading => status.isDownloading;
  bool get isActive => status.isActive;

  DownloadTask copyWith({
    DownloadStatus? status,
    DownloadProgress? progress,
    String? filePath,
    String? errorMessage,
    DateTime? completedAt,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
  }) {
    return DownloadTask(
      id: id,
      request: request,
      mediaInfo: mediaInfo,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage ?? this.errorMessage,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'request': request.toJson(),
    'media_info': mediaInfo.toJson(),
    'status': status.name,
    'file_path': filePath,
    'error_message': errorMessage,
    'started_at': startedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'scheduled_at': scheduledAt?.toIso8601String(),
  };

  factory DownloadTask.fromJson(Map<String, dynamic> json) => DownloadTask(
    id: json['id'] as String,
    request: DownloadRequest.fromJson(json['request'] as Map<String, dynamic>),
    mediaInfo: MediaInfo.fromJson(json['media_info'] as Map<String, dynamic>),
    status: DownloadStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => DownloadStatus.completed,
    ),
    filePath: json['file_path'] as String?,
    errorMessage: json['error_message'] as String?,
    startedAt: DateTime.parse(json['started_at'] as String),
    completedAt: json['completed_at'] != null
        ? DateTime.parse(json['completed_at'] as String)
        : null,
    scheduledAt: json['scheduled_at'] != null
        ? DateTime.parse(json['scheduled_at'] as String)
        : null,
  );
}
