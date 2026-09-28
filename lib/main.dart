import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/background_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'features/downloads/providers/download_manager.dart';
import 'features/settings/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent preferences
  final storageService = await StorageService.init();

  // Initialize local notifications service
  await NotificationService.instance.initialize();

  // Create Riverpod container
  final container = ProviderContainer(
    overrides: [storageServiceProvider.overrideWithValue(storageService)],
  );

  // Initialize desktop background service to keep downloads running when window is closed
  await BackgroundService.instance.initialize(() {
    return container.read(downloadManagerProvider).activeTasks.isNotEmpty;
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MediaGrabApp(),
    ),
  );
}
