/// Represents live progress updates for an active download.
class DownloadProgress {
  final int downloadedBytes;
  final int totalBytes;
  final double speedBytesPerSecond;
  final int etaSeconds;
  final double percentage; // 0.0 to 1.0
  final String? statusMessage;
  final bool isSlowSpeed;
  final bool isStalled;
  final bool waitingForWifi;
  final bool waitingForNetwork;

  const DownloadProgress({
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.speedBytesPerSecond = 0.0,
    this.etaSeconds = 0,
    this.percentage = 0.0,
    this.statusMessage,
    this.isSlowSpeed = false,
    this.isStalled = false,
    this.waitingForWifi = false,
    this.waitingForNetwork = false,
  });

  String get speedFormatted {
    if (speedBytesPerSecond <= 0) return '0.0 MB/s';
    final mb = speedBytesPerSecond / (1024 * 1024);
    if (mb >= 1.0) {
      return '${mb.toStringAsFixed(1)} MB/s';
    }
    final kb = speedBytesPerSecond / 1024;
    return '${kb.toStringAsFixed(1)} KB/s';
  }

  String get etaFormatted {
    if (etaSeconds <= 0) return '--:--';
    final m = etaSeconds ~/ 60;
    final s = etaSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get downloadedFormatted {
    final mb = downloadedBytes / (1024 * 1024);
    if (totalBytes > 0) {
      final totalMb = totalBytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} / ${totalMb.toStringAsFixed(1)} MB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  DownloadProgress copyWith({
    int? downloadedBytes,
    int? totalBytes,
    double? speedBytesPerSecond,
    int? etaSeconds,
    double? percentage,
    String? statusMessage,
    bool? isSlowSpeed,
    bool? isStalled,
    bool? waitingForWifi,
    bool? waitingForNetwork,
  }) {
    return DownloadProgress(
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
      etaSeconds: etaSeconds ?? this.etaSeconds,
      percentage: percentage ?? this.percentage,
      statusMessage: statusMessage ?? this.statusMessage,
      isSlowSpeed: isSlowSpeed ?? this.isSlowSpeed,
      isStalled: isStalled ?? this.isStalled,
      waitingForWifi: waitingForWifi ?? this.waitingForWifi,
      waitingForNetwork: waitingForNetwork ?? this.waitingForNetwork,
    );
  }
}
