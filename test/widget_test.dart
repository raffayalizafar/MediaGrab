import 'package:downloader_all_platform/app.dart';
import 'package:downloader_all_platform/core/constants/app_constants.dart';
import 'package:downloader_all_platform/core/services/storage_service.dart';
import 'package:downloader_all_platform/features/settings/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('MediaGrab renders navigation and switches tabs cleanly', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storageService)],
        child: const MediaGrabApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Home Screen elements
    expect(find.text('MediaGrab'), findsWidgets);
    expect(find.text('Download Any Video or Audio'), findsOneWidget);
    expect(find.text('Quick Templates'), findsOneWidget);

    // Switch to Downloads tab
    final downloadsTab = find.text('Downloads');
    expect(downloadsTab, findsWidgets);
    await tester.tap(downloadsTab.first);
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);

    // Switch to Templates tab
    final templatesTab = find.text('Templates');
    expect(templatesTab, findsWidgets);
    await tester.tap(templatesTab.first);
    await tester.pumpAndSettle();

    expect(find.text('Command Templates'), findsWidgets);
    expect(find.text('New Template'), findsOneWidget);

    // Switch to Settings tab
    final settingsTab = find.text('Settings');
    expect(settingsTab, findsWidgets);
    await tester.tap(settingsTab.first);
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Dynamic Colors'), findsOneWidget);
    expect(find.text('AMOLED Pure Black'), findsOneWidget);
  });

  testWidgets(
    'ActiveTabProvider switches tabs programmatically and syncs with shell',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storageService)],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MediaGrabApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial tab is Home (index 0)
      expect(container.read(activeTabProvider), 0);
      expect(find.text('Download Any Video or Audio'), findsOneWidget);

      // Switch to Downloads tab (index 1) via provider
      container.read(activeTabProvider.notifier).state = 1;
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Switch to Settings tab (index 3) via provider
      container.read(activeTabProvider.notifier).state = 3;
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);

      // Switch back to Home (index 0)
      container.read(activeTabProvider.notifier).state = 0;
      await tester.pumpAndSettle();

      expect(find.text('Download Any Video or Audio'), findsOneWidget);
    },
  );

  testWidgets('Renders all screens on compact/mobile width without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(371, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storageService)],
        child: const MediaGrabApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Home Screen renders on narrow width without overflow
    expect(find.text('SUPPORTED PLATFORMS & ENGINES'), findsOneWidget);
    expect(find.text('Auto-detected upon pasting'), findsOneWidget);

    // Switch to Downloads tab
    final downloadsTab = find.text('Downloads');
    await tester.tap(downloadsTab.first);
    await tester.pumpAndSettle();

    expect(find.text('Downloads & Activity'), findsOneWidget);
    expect(find.text('Filter downloads...'), findsOneWidget);

    // Switch to Settings tab
    final settingsTab = find.text('Settings');
    await tester.tap(settingsTab.first);
    await tester.pumpAndSettle();

    // Verify Settings Screen renders section headers on narrow width without overflow
    expect(find.text('Appearance'), findsWidgets);
    expect(find.text('MEDIA PROCESSING & METADATA'), findsOneWidget);
    expect(find.text('FFmpeg & Mutagen core'), findsOneWidget);
    expect(find.text('ENGINE & NETWORK'), findsOneWidget);
    expect(
      find.text('Multi-threaded socket & network resilience'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Downloads screen renders without overflow on mid-size tablet/split view (750px)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(750, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storageService)],
          child: const MediaGrabApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Downloads tab
      final downloadsTab = find.text('Downloads');
      await tester.tap(downloadsTab.first);
      await tester.pumpAndSettle();

      // Verify downloads screen elements render without overflow
      expect(find.text('Downloads & Activity'), findsOneWidget);
      expect(find.text('Filter downloads...'), findsOneWidget);
      expect(find.text('New Download'), findsOneWidget);

      // Verify TextField has InputBorder.none borders (no double borders)
      final textField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Filter downloads...'),
      );
      expect(textField.decoration?.border, InputBorder.none);
      expect(textField.decoration?.enabledBorder, InputBorder.none);
      expect(textField.decoration?.focusedBorder, InputBorder.none);
    },
  );

  testWidgets(
    'AMOLED dark mode sets background to pure black and shows version',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyThemeMode: 'dark',
        AppConstants.keyAmoledDark: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storageService)],
          child: const MediaGrabApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Theme scaffoldBackgroundColor is pure black
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, Colors.black);

      // Switch to Settings tab
      final settingsTab = find.text('Settings');
      await tester.tap(settingsTab.first);
      await tester.pumpAndSettle();

      // Verify Settings screen also has Colors.black scaffold background
      final settingsScaffold = tester.widget<Scaffold>(
        find.byType(Scaffold).first,
      );
      expect(settingsScaffold.backgroundColor, Colors.black);

      // Verify version badges and text
      expect(
        find.text('v${AppConstants.appVersion} Pre-release'),
        findsOneWidget,
      );
      expect(find.text('v${AppConstants.appVersion}'), findsWidgets);
    },
  );

  testWidgets(
    'Settings screen renders folder selection controls and directory badges',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storageService)],
          child: const MediaGrabApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Settings tab
      final settingsTab = find.text('Settings');
      await tester.tap(settingsTab.first);
      await tester.pumpAndSettle();

      // Verify download directory controls
      expect(find.text('Default Download Directory'), findsOneWidget);
      expect(find.text('Change Folder'), findsOneWidget);
      expect(find.text('Reset to Default'), findsOneWidget);
      expect(find.text('video/ for videos'), findsOneWidget);
      expect(find.text('audio/ for audio'), findsOneWidget);
      expect(find.text('playlist subfolders'), findsOneWidget);
    },
  );
}
