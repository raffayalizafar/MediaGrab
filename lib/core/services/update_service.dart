import 'dart:convert';
import 'dart:io';
import '../constants/app_constants.dart';
import '../errors/logger_service.dart';

/// Represents a parsed Semantic Version supporting optional pre-release identifiers.
class SemanticVersion implements Comparable<SemanticVersion> {
  final int major;
  final int minor;
  final int patch;
  final String? preReleaseType; // 'alpha', 'beta', 'rc', etc.
  final int preReleaseNumber;
  final String raw;

  const SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.preReleaseType,
    this.preReleaseNumber = 0,
    required this.raw,
  });

  bool get isPreRelease => preReleaseType != null;

  /// Parses version strings such as "v1.0.0-beta.1", "1.0.0", "1.2.3-rc.2+5".
  factory SemanticVersion.parse(String input) {
    final raw = input.trim();
    var clean = raw;
    if (clean.startsWith('v') || clean.startsWith('V')) {
      clean = clean.substring(1);
    }

    // Strip build metadata (+...)
    if (clean.contains('+')) {
      clean = clean.split('+').first;
    }

    String? preType;
    int preNum = 0;

    // Check for pre-release (-...)
    if (clean.contains('-')) {
      final parts = clean.split('-');
      clean = parts[0];
      final prePart = parts.sublist(1).join('-');
      final preTokens = prePart.split('.');
      preType = preTokens[0].toLowerCase();
      if (preTokens.length > 1) {
        preNum = int.tryParse(preTokens[1]) ?? 0;
      }
    }

    final versionNums = clean.split('.');
    final major = versionNums.isNotEmpty ? (int.tryParse(versionNums[0]) ?? 0) : 0;
    final minor = versionNums.length > 1 ? (int.tryParse(versionNums[1]) ?? 0) : 0;
    final patch = versionNums.length > 2 ? (int.tryParse(versionNums[2]) ?? 0) : 0;

    return SemanticVersion(
      major: major,
      minor: minor,
      patch: patch,
      preReleaseType: preType,
      preReleaseNumber: preNum,
      raw: raw,
    );
  }

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    // If version numbers are identical:
    // A stable release (no pre-release) has higher precedence than any pre-release.
    if (!isPreRelease && other.isPreRelease) return 1;
    if (isPreRelease && !other.isPreRelease) return -1;
    if (!isPreRelease && !other.isPreRelease) return 0;

    // Both are pre-releases: compare pre-release type precedence
    final weightSelf = _preReleaseWeight(preReleaseType);
    final weightOther = _preReleaseWeight(other.preReleaseType);
    if (weightSelf != weightOther) {
      return weightSelf.compareTo(weightOther);
    }

    return preReleaseNumber.compareTo(other.preReleaseNumber);
  }

  static int _preReleaseWeight(String? type) {
    switch (type) {
      case 'alpha':
        return 1;
      case 'beta':
        return 2;
      case 'rc':
        return 3;
      default:
        return 0;
    }
  }

  bool operator >(SemanticVersion other) => compareTo(other) > 0;
  bool operator <(SemanticVersion other) => compareTo(other) < 0;
  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;
  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemanticVersion && compareTo(other) == 0;

  @override
  int get hashCode =>
      major.hashCode ^
      minor.hashCode ^
      patch.hashCode ^
      preReleaseType.hashCode ^
      preReleaseNumber.hashCode;

  @override
  String toString() => raw;
}

/// Represents a downloadable binary asset attached to a GitHub release.
class ReleaseAsset {
  final String name;
  final String downloadUrl;
  final int size;
  final String contentType;

  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
    required this.contentType,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: json['name'] as String? ?? '',
      downloadUrl: json['browser_download_url'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      contentType: json['content_type'] as String? ?? 'application/octet-stream',
    );
  }

  String get humanReadableSize {
    if (size <= 0) return '';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var bytes = size.toDouble();
    var i = 0;
    while (bytes >= 1024 && i < suffixes.length - 1) {
      bytes /= 1024;
      i++;
    }
    return '${bytes.toStringAsFixed(1)} ${suffixes[i]}';
  }
}

/// Represents a GitHub release with metadata, notes, and binaries.
class AppRelease {
  final int id;
  final String tagName;
  final String name;
  final String body;
  final String htmlUrl;
  final bool isPrerelease;
  final bool isDraft;
  final DateTime? publishedAt;
  final List<ReleaseAsset> assets;
  final SemanticVersion version;

  AppRelease({
    required this.id,
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    required this.isPrerelease,
    required this.isDraft,
    this.publishedAt,
    required this.assets,
    required this.version,
  });

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String? ?? '';
    final assetList = (json['assets'] as List<dynamic>? ?? [])
        .map((e) => ReleaseAsset.fromJson(e as Map<String, dynamic>))
        .toList();

    DateTime? published;
    if (json['published_at'] != null) {
      published = DateTime.tryParse(json['published_at'] as String);
    }

    return AppRelease(
      id: json['id'] as int? ?? 0,
      tagName: tagName,
      name: json['name'] as String? ?? tagName,
      body: json['body'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      isPrerelease: json['prerelease'] as bool? ?? false,
      isDraft: json['draft'] as bool? ?? false,
      publishedAt: published,
      assets: assetList,
      version: SemanticVersion.parse(tagName),
    );
  }
}

/// Core service that interacts directly with GitHub Releases API.
class UpdateService {
  final HttpClient _client;

  UpdateService({HttpClient? client}) : _client = client ?? HttpClient();

  /// Fetches published releases from the official GitHub repository.
  Future<List<AppRelease>> fetchReleases({
    String repoOwner = 'raffayalizafar',
    String repoName = 'MediaGrab',
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final url = Uri.parse(
        'https://api.github.com/repos/$repoOwner/$repoName/releases?per_page=15');
    try {
      final request = await _client.getUrl(url).timeout(timeout);
      request.headers.set('User-Agent', 'MediaGrab-App/${AppConstants.appVersion}');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close().timeout(timeout);
      if (response.statusCode != 200) {
        LoggerService.warning(
            'GitHub API update check returned status ${response.statusCode}');
        return [];
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final jsonList = jsonDecode(responseBody) as List<dynamic>;

      return jsonList
          .map((item) => AppRelease.fromJson(item as Map<String, dynamic>))
          .where((release) => !release.isDraft)
          .toList();
    } catch (e, stack) {
      LoggerService.warning('Failed to fetch GitHub releases: $e\n$stack');
      return [];
    }
  }

  /// Determines if a newer compatible release is available compared to [currentVersionStr].
  AppRelease? checkLatestUpdate({
    required List<AppRelease> releases,
    required String currentVersionStr,
    bool includePrereleases = true,
  }) {
    if (releases.isEmpty) return null;

    final current = SemanticVersion.parse(currentVersionStr);

    // Filter out pre-releases if user opted out
    final eligibleReleases = releases.where((r) {
      if (!includePrereleases && r.isPrerelease) return false;
      return true;
    }).toList();

    if (eligibleReleases.isEmpty) return null;

    // Sort descending by semantic version
    eligibleReleases.sort((a, b) => b.version.compareTo(a.version));

    final newest = eligibleReleases.first;
    if (newest.version > current) {
      return newest;
    }

    return null;
  }

  /// Resolves the optimal installation asset for the given release matching the host platform.
  ReleaseAsset? resolveRecommendedAsset(
    AppRelease release, {
    String? platformOverride,
  }) {
    if (release.assets.isEmpty) return null;

    final os = (platformOverride ?? Platform.operatingSystem).toLowerCase();

    if (os == 'macos') {
      return _findAsset(release.assets, ['.dmg']) ??
          _findAsset(release.assets, ['-macos.zip', '.zip']);
    } else if (os == 'windows') {
      return _findAsset(release.assets, ['-setup.exe', '.exe']) ??
          _findAsset(release.assets, ['-windows-x64.zip', '.zip']);
    } else if (os == 'android') {
      return _findAsset(release.assets, ['-arm64-v8a.apk']) ??
          _findAsset(release.assets, ['-universal.apk', '.apk']);
    } else if (os == 'linux') {
      return _findAsset(release.assets, ['-linux-x64.tar.gz', '.tar.gz', '.appimage']);
    }

    return null;
  }

  ReleaseAsset? _findAsset(List<ReleaseAsset> assets, List<String> patterns) {
    for (final pattern in patterns) {
      for (final asset in assets) {
        if (asset.name.toLowerCase().contains(pattern.toLowerCase())) {
          return asset;
        }
      }
    }
    return null;
  }
}
