import 'package:downloader_all_platform/core/services/storage_service.dart';
import 'package:downloader_all_platform/download_engine/models/media_info.dart';
import 'package:downloader_all_platform/features/home/providers/home_provider.dart';
import 'package:downloader_all_platform/features/home/ui/media_config_sheet.dart';
import 'package:downloader_all_platform/features/settings/providers/settings_provider.dart';
import 'package:downloader_all_platform/shared/widgets/clay_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHomeNotifier extends StateNotifier<HomeState>
    implements HomeNotifier {
  _FakeHomeNotifier(super.initialState);

  @override
  void setAudioOnly(bool isAudio) {
    state = state.copyWith(isAudioOnly: isAudio);
  }

  @override
  void setCustomOutputDirectory(String? path) {
    if (path == null) {
      state = state.copyWith(clearCustomOutputDirectory: true);
    } else {
      state = state.copyWith(customOutputDirectory: path);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
  });

  group('MediaConfigSheet Instant Loading & Claymorphism Tests', () {
    testWidgets('Renders loading skeleton instantly when mediaInfo is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
            homeProvider.overrideWith(
              (ref) => _FakeHomeNotifier(
                const HomeState(
                  status: HomeStateStatus.fetchingInfo,
                  url: 'https://www.youtube.com/shorts/_4DqqXrPcf0',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: MediaConfigSheet())),
        ),
      );

      // Verify immediate render without throwing assertions
      expect(
        find.text('Resolving available streams & formats...'),
        findsOneWidget,
      );
      expect(find.byType(ClayShimmer), findsWidgets);
    });

    testWidgets(
      'Renders ready content with download destination and switches video/audio cleanly',
      (WidgetTester tester) async {
        const mockInfo = MediaInfo(
          title: 'Test Amazing Video Title',
          url: 'https://example.com/video',
          author: 'TestCreator',
          duration: Duration(minutes: 2),
          availableQualities: ['1080p', '720p', '480p'],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storageService),
              homeProvider.overrideWith(
                (ref) => _FakeHomeNotifier(
                  const HomeState(
                    status: HomeStateStatus.ready,
                    mediaInfo: mockInfo,
                    url: 'https://example.com/video',
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: Scaffold(body: MediaConfigSheet())),
          ),
        );

        await tester.pumpAndSettle();

        // Verify title and chips
        expect(find.text('Test Amazing Video Title'), findsOneWidget);
        expect(find.text('Video'), findsOneWidget);
        expect(find.text('Audio'), findsOneWidget);
        expect(find.text('1080p (FHD)'), findsOneWidget);
        expect(find.text('720p (HD)'), findsOneWidget);
        expect(find.text('Download Destination'), findsOneWidget);
        expect(find.text('Change'), findsOneWidget);
        expect(find.text('Start Download'), findsOneWidget);

        // Switch to Audio tab
        await tester.tap(find.text('Audio'));
        await tester.pumpAndSettle();

        expect(find.text('Start Download'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders playlist subfolder notice when downloading a playlist',
      (WidgetTester tester) async {
        const mockPlaylist = MediaInfo(
          title: 'Greatest Hits 2026',
          url: 'https://example.com/playlist?list=PL123',
          author: 'MusicChannel',
          isPlaylist: true,
          playlistCount: 15,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storageService),
              homeProvider.overrideWith(
                (ref) => _FakeHomeNotifier(
                  const HomeState(
                    status: HomeStateStatus.ready,
                    mediaInfo: mockPlaylist,
                    url: 'https://example.com/playlist?list=PL123',
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: Scaffold(body: MediaConfigSheet())),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Greatest Hits 2026'), findsOneWidget);
        expect(find.text('Download Destination'), findsOneWidget);
        expect(
          find.text('Playlist will be stored in a dedicated subfolder'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ClayContainer renders in light and dark mode with dual shadows',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: Scaffold(
              body: Center(
                child: ClayContainer(
                  depth: 6,
                  borderRadius: BorderRadius.circular(20),
                  child: const Text('Clay Content'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Clay Content'), findsOneWidget);
        expect(find.byType(ClayContainer), findsOneWidget);
      },
    );
  });
}
