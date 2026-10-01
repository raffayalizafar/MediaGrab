import 'package:flutter_test/flutter_test.dart';
import 'package:downloader_all_platform/core/services/update_service.dart';

void main() {
  group('SemanticVersion Parsing & Comparison', () {
    test('parses basic semantic versions correctly', () {
      final v1 = SemanticVersion.parse('1.0.0');
      expect(v1.major, 1);
      expect(v1.minor, 0);
      expect(v1.patch, 0);
      expect(v1.isPreRelease, false);

      final v2 = SemanticVersion.parse('v2.4.12');
      expect(v2.major, 2);
      expect(v2.minor, 4);
      expect(v2.patch, 12);
      expect(v2.isPreRelease, false);
    });

    test('parses pre-release versions with identifiers and numbers', () {
      final beta1 = SemanticVersion.parse('v1.0.0-beta.1');
      expect(beta1.major, 1);
      expect(beta1.minor, 0);
      expect(beta1.patch, 0);
      expect(beta1.isPreRelease, true);
      expect(beta1.preReleaseType, 'beta');
      expect(beta1.preReleaseNumber, 1);

      final rc2 = SemanticVersion.parse('1.2.0-rc.2+build.44');
      expect(rc2.major, 1);
      expect(rc2.minor, 2);
      expect(rc2.patch, 0);
      expect(rc2.isPreRelease, true);
      expect(rc2.preReleaseType, 'rc');
      expect(rc2.preReleaseNumber, 2);
    });

    test('compares semantic versions with standard precedence', () {
      final v100 = SemanticVersion.parse('1.0.0');
      final v101 = SemanticVersion.parse('1.0.1');
      final v110 = SemanticVersion.parse('1.1.0');
      final v200 = SemanticVersion.parse('2.0.0');

      expect(v101 > v100, isTrue);
      expect(v110 > v101, isTrue);
      expect(v200 > v110, isTrue);
      expect(v100 < v101, isTrue);
      expect(v100 == SemanticVersion.parse('v1.0.0'), isTrue);
    });

    test('compares pre-release versions against stable releases', () {
      final stable = SemanticVersion.parse('1.0.0');
      final beta1 = SemanticVersion.parse('v1.0.0-beta.1');
      final beta2 = SemanticVersion.parse('v1.0.0-beta.2');
      final rc1 = SemanticVersion.parse('v1.0.0-rc.1');

      // Stable is greater than any pre-release of the same version
      expect(stable > beta1, isTrue);
      expect(stable > beta2, isTrue);
      expect(stable > rc1, isTrue);

      // Pre-release iteration comparisons
      expect(beta2 > beta1, isTrue);
      expect(beta1 < beta2, isTrue);
      expect(rc1 > beta2, isTrue);
      expect(rc1 > beta1, isTrue);
    });
  });

  group('Release Parsing & Asset Resolution', () {
    final sampleReleaseJson = {
      'id': 12345,
      'tag_name': 'v1.0.1',
      'name': 'MediaGrab v1.0.1',
      'body': '## Features\n- Direct update checks\n- Performance improvements',
      'html_url': 'https://github.com/raffayalizafar/MediaGrab/releases/tag/v1.0.1',
      'prerelease': false,
      'draft': false,
      'published_at': '2026-10-01T12:00:00Z',
      'assets': [
        {
          'name': 'MediaGrab-macos.dmg',
          'browser_download_url':
              'https://github.com/raffayalizafar/MediaGrab/releases/download/v1.0.1/MediaGrab-macos.dmg',
          'size': 26000000,
          'content_type': 'application/octet-stream',
        },
        {
          'name': 'MediaGrab-windows-setup.exe',
          'browser_download_url':
              'https://github.com/raffayalizafar/MediaGrab/releases/download/v1.0.1/MediaGrab-windows-setup.exe',
          'size': 14000000,
          'content_type': 'application/x-msdos-program',
        },
        {
          'name': 'MediaGrab-android-arm64-v8a.apk',
          'browser_download_url':
              'https://github.com/raffayalizafar/MediaGrab/releases/download/v1.0.1/MediaGrab-android-arm64-v8a.apk',
          'size': 24000000,
          'content_type': 'application/vnd.android.package-archive',
        },
        {
          'name': 'MediaGrab-linux-x64.tar.gz',
          'browser_download_url':
              'https://github.com/raffayalizafar/MediaGrab/releases/download/v1.0.1/MediaGrab-linux-x64.tar.gz',
          'size': 13000000,
          'content_type': 'application/gzip',
        },
        {
          'name': 'SHA256SUMS.txt',
          'browser_download_url':
              'https://github.com/raffayalizafar/MediaGrab/releases/download/v1.0.1/SHA256SUMS.txt',
          'size': 500,
          'content_type': 'text/plain',
        },
      ],
    };

    test('parses AppRelease and ReleaseAsset from JSON', () {
      final release = AppRelease.fromJson(sampleReleaseJson);

      expect(release.id, 12345);
      expect(release.tagName, 'v1.0.1');
      expect(release.name, 'MediaGrab v1.0.1');
      expect(release.isPrerelease, false);
      expect(release.isDraft, false);
      expect(release.version.major, 1);
      expect(release.version.minor, 0);
      expect(release.version.patch, 1);
      expect(release.assets.length, 5);

      final dmgAsset = release.assets.first;
      expect(dmgAsset.name, 'MediaGrab-macos.dmg');
      expect(dmgAsset.humanReadableSize, contains('MB'));
    });

    test('resolves recommended assets for different operating systems', () {
      final release = AppRelease.fromJson(sampleReleaseJson);
      final service = UpdateService();

      final macAsset =
          service.resolveRecommendedAsset(release, platformOverride: 'macos');
      expect(macAsset?.name, 'MediaGrab-macos.dmg');

      final winAsset =
          service.resolveRecommendedAsset(release, platformOverride: 'windows');
      expect(winAsset?.name, 'MediaGrab-windows-setup.exe');

      final androidAsset =
          service.resolveRecommendedAsset(release, platformOverride: 'android');
      expect(androidAsset?.name, 'MediaGrab-android-arm64-v8a.apk');

      final linuxAsset =
          service.resolveRecommendedAsset(release, platformOverride: 'linux');
      expect(linuxAsset?.name, 'MediaGrab-linux-x64.tar.gz');

      final iosAsset =
          service.resolveRecommendedAsset(release, platformOverride: 'ios');
      expect(iosAsset, isNull);
    });

    test('checkLatestUpdate correctly detects newer version', () {
      final release101 = AppRelease.fromJson(sampleReleaseJson);
      final betaRelease = AppRelease.fromJson({
        ...sampleReleaseJson,
        'tag_name': 'v1.0.0-beta.2',
        'prerelease': true,
      });

      final service = UpdateService();

      // Current version is 1.0.0-beta.1: release 1.0.1 should be detected
      final update1 = service.checkLatestUpdate(
        releases: [release101],
        currentVersionStr: '1.0.0-beta.1',
      );
      expect(update1, isNotNull);
      expect(update1?.tagName, 'v1.0.1');

      // Current version is already 1.0.1: no update should be detected
      final update2 = service.checkLatestUpdate(
        releases: [release101],
        currentVersionStr: '1.0.1',
      );
      expect(update2, isNull);

      // Current version is 1.0.2: no update should be detected
      final update3 = service.checkLatestUpdate(
        releases: [release101],
        currentVersionStr: '1.0.2',
      );
      expect(update3, isNull);

      // Pre-release filtering
      final updateWithPrereleases = service.checkLatestUpdate(
        releases: [betaRelease],
        currentVersionStr: '1.0.0-beta.1',
        includePrereleases: true,
      );
      expect(updateWithPrereleases?.tagName, 'v1.0.0-beta.2');

      final updateWithoutPrereleases = service.checkLatestUpdate(
        releases: [betaRelease],
        currentVersionStr: '1.0.0-beta.1',
        includePrereleases: false,
      );
      expect(updateWithoutPrereleases, isNull);
    });
  });
}
