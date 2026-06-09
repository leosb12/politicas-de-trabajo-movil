import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/network_constants.dart';
import '../offline/health_check_service.dart';
import '../offline/mobile_snapshot_store.dart';
import '../offline/offline_hive_store.dart';
import '../offline/offline_initial_sync_service.dart';
import '../offline/offline_profile_store.dart';
import '../offline/offline_queue_store.dart';
import '../offline/offline_sync_service.dart';

// ── Core DIO provider (here to avoid circular imports) ─────────────────────

final coreApiClientProvider = Provider<ApiClient>((ref) {
  final List<String> urls = NetworkConstants.baseUrls;
  return ApiClient(
    baseUrl: urls.first,
    fallbackBaseUrls: urls.skip(1).toList(),
  );
});

/// Dio provider in core — shared with auth and offline layers.
final coreDioProvider = Provider<Dio>((ref) {
  return ref.watch(coreApiClientProvider).dio;
});

// ── Hive Box providers ──────────────────────────────────────────────────────

final offlineProfileBoxProvider = Provider<OfflineProfileStore>((ref) {
  return OfflineProfileStore(OfflineHiveStore.authProfilesBox);
});

final snapshotStoreProvider = Provider<MobileSnapshotStore>((ref) {
  return MobileSnapshotStore(OfflineHiveStore.snapshotBox);
});

final offlineQueueStoreProvider = Provider<OfflineQueueStore>((ref) {
  return OfflineQueueStore(
    queueBox: OfflineHiveStore.queueBox,
    conflictsBox: OfflineHiveStore.conflictsBox,
  );
});

// ── Health check + Connectivity ─────────────────────────────────────────────

final healthCheckServiceProvider = Provider<HealthCheckService>((ref) {
  final service = HealthCheckService(ref.watch(coreDioProvider));
  ref.onDispose(service.dispose);
  return service;
});

final connectivityNotifierProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier(ref.watch(healthCheckServiceProvider));
});

/// Conveniencia: retorna true si el backend está disponible.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityNotifierProvider);
});

// ── Sync services ────────────────────────────────────────────────────────────

final offlineInitialSyncServiceProvider = Provider<OfflineInitialSyncService>((ref) {
  return OfflineInitialSyncService(
    dio: ref.watch(coreDioProvider),
    profileStore: ref.watch(offlineProfileBoxProvider),
    snapshotStore: ref.watch(snapshotStoreProvider),
  );
});

final offlineSyncServiceProvider = StateNotifierProvider<OfflineSyncService, SyncState>((ref) {
  return OfflineSyncService(
    dio: ref.watch(coreDioProvider),
    connectivity: ref.watch(connectivityNotifierProvider.notifier),
    queue: ref.watch(offlineQueueStoreProvider),
    snapshotStore: ref.watch(snapshotStoreProvider),
  );
});

/// Conteo de operaciones pendientes en cola.
final pendingQueueCountProvider = Provider<int>((ref) {
  ref.watch(offlineSyncServiceProvider); // recompute when sync changes
  return ref.watch(offlineQueueStoreProvider).pendingCount;
});
