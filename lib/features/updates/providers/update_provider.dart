import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/update_service.dart';
import '../../settings/providers/settings_provider.dart';

enum UpdateStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  error,
}

class UpdateState {
  final UpdateStatus status;
  final String currentVersion;
  final AppRelease? latestRelease;
  final ReleaseAsset? recommendedAsset;
  final DateTime? lastChecked;
  final String? errorMessage;
  final bool isManualCheck;
  final bool autoCheckOnStartup;
  final bool includePrereleases;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.currentVersion = AppConstants.appVersion,
    this.latestRelease,
    this.recommendedAsset,
    this.lastChecked,
    this.errorMessage,
    this.isManualCheck = false,
    this.autoCheckOnStartup = AppConstants.defaultCheckUpdatesOnStartup,
    this.includePrereleases = AppConstants.defaultIncludePrereleases,
  });

  UpdateState copyWith({
    UpdateStatus? status,
    String? currentVersion,
    AppRelease? latestRelease,
    ReleaseAsset? recommendedAsset,
    DateTime? lastChecked,
    String? errorMessage,
    bool? isManualCheck,
    bool? autoCheckOnStartup,
    bool? includePrereleases,
    bool clearError = false,
    bool clearRelease = false,
  }) {
    return UpdateState(
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      latestRelease: clearRelease ? null : (latestRelease ?? this.latestRelease),
      recommendedAsset: clearRelease ? null : (recommendedAsset ?? this.recommendedAsset),
      lastChecked: lastChecked ?? this.lastChecked,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isManualCheck: isManualCheck ?? this.isManualCheck,
      autoCheckOnStartup: autoCheckOnStartup ?? this.autoCheckOnStartup,
      includePrereleases: includePrereleases ?? this.includePrereleases,
    );
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

final updateProvider =
    StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final updateService = ref.watch(updateServiceProvider);
  return UpdateNotifier(storageService, updateService);
});

class UpdateNotifier extends StateNotifier<UpdateState> {
  final StorageService _storage;
  final UpdateService _service;

  UpdateNotifier(this._storage, this._service)
      : super(UpdateState(
          autoCheckOnStartup: _storage.checkUpdatesOnStartup,
          includePrereleases: _storage.includePrereleases,
          lastChecked: _storage.lastUpdateCheckTimestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  _storage.lastUpdateCheckTimestamp!)
              : null,
        ));

  /// Checks GitHub releases for a newer version.
  Future<void> checkForUpdates({bool isManual = false}) async {
    if (state.status == UpdateStatus.checking) return;

    state = state.copyWith(
      status: UpdateStatus.checking,
      isManualCheck: isManual,
      clearError: true,
    );

    try {
      final releases = await _service.fetchReleases();
      final now = DateTime.now();
      await _storage.setLastUpdateCheckTimestamp(now.millisecondsSinceEpoch);

      if (releases.isEmpty) {
        state = state.copyWith(
          status: isManual ? UpdateStatus.error : UpdateStatus.idle,
          lastChecked: now,
          errorMessage: 'Unable to check for updates. Please check your connection.',
        );
        return;
      }

      final newerRelease = _service.checkLatestUpdate(
        releases: releases,
        currentVersionStr: state.currentVersion,
        includePrereleases: state.includePrereleases,
      );

      if (newerRelease != null) {
        final asset = _service.resolveRecommendedAsset(newerRelease);
        state = state.copyWith(
          status: UpdateStatus.updateAvailable,
          latestRelease: newerRelease,
          recommendedAsset: asset,
          lastChecked: now,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          status: UpdateStatus.upToDate,
          clearRelease: true,
          lastChecked: now,
          clearError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: isManual ? UpdateStatus.error : UpdateStatus.idle,
        errorMessage: e.toString(),
      );
    }
  }

  /// Dismisses the active update banner or status.
  void dismissUpdate() {
    state = state.copyWith(status: UpdateStatus.idle);
  }

  /// Toggles whether to check for updates automatically on app launch.
  Future<void> setAutoCheckOnStartup(bool value) async {
    await _storage.setCheckUpdatesOnStartup(value);
    state = state.copyWith(autoCheckOnStartup: value);
  }

  /// Toggles whether pre-releases and beta versions are considered.
  Future<void> setIncludePrereleases(bool value) async {
    await _storage.setIncludePrereleases(value);
    state = state.copyWith(includePrereleases: value);
    // Re-check updates with new preference
    await checkForUpdates(isManual: false);
  }
}
