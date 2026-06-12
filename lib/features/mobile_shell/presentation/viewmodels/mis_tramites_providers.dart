import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/offline/offline_providers.dart';
import '../../../../core/offline/offline_sync_service.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../data/datasources/mis_tramites_mock_datasource.dart';
import '../../data/datasources/mis_tramites_remote_datasource.dart';
import '../../data/datasources/tarea_formulario_offline_datasource.dart';
import '../../data/repositories/mis_tramites_repository_impl.dart';
import '../../domain/repositories/mis_tramites_repository.dart';
import 'mis_tramites_state.dart';
import 'mis_tramites_view_model.dart';
import 'tramite_seguimiento_state.dart';
import 'tramite_seguimiento_view_model.dart';

const bool _useMockMisTramites = false;

final misTramitesDioProvider = Provider<Dio>((ref) {
  return ref.watch(dioProvider);
});

final misTramitesDataSourceProvider = Provider<MisTramitesDataSource>((ref) {
  if (_useMockMisTramites) {
    return MisTramitesMockDataSource();
  }

  return MisTramitesRemoteDataSource(ref.watch(misTramitesDioProvider));
});

final misTramitesRepositoryProvider = Provider<MisTramitesRepository>((ref) {
  return MisTramitesRepositoryImpl(
    remoteDataSource: ref.watch(misTramitesDataSourceProvider),
    snapshotStore: ref.watch(snapshotStoreProvider),
    connectivity: ref.watch(connectivityNotifierProvider.notifier),
  );
});

final misTramitesViewModelProvider =
    StateNotifierProvider<MisTramitesViewModel, MisTramitesState>((ref) {
      final viewModel = MisTramitesViewModel(
        repository: ref.watch(misTramitesRepositoryProvider),
      );

      // Escuchar cambios de sincronización en background para refrescar la UI automáticamente
      ref.listen<SyncState>(offlineSyncServiceProvider, (previous, next) {
        if (previous == SyncState.syncing &&
            (next == SyncState.completed || next == SyncState.idle || next == SyncState.error)) {
          final String? activeUserId = viewModel.currentState.lastLoadedUserId;
          if (activeUserId != null && activeUserId.isNotEmpty) {
            viewModel.cargarMisTramites(usuarioId: activeUserId);
          }
        }
      });

      return viewModel;
    });

final tramiteSeguimientoViewModelProvider = StateNotifierProvider.autoDispose
    .family<
      TramiteSeguimientoViewModel,
      TramiteSeguimientoState,
      TramiteSeguimientoArgs
    >((ref, TramiteSeguimientoArgs args) {
      return TramiteSeguimientoViewModel(
        repository: ref.watch(misTramitesRepositoryProvider),
        usuarioId: args.usuarioId,
        instanciaId: args.instanciaId,
      );
    });

// ── Tarea formulario offline-first ──────────────────────────────────────────

/// Datasource offline para tareas — usado directamente en la view/viewmodel.
final tareaFormularioOfflineDataSourceProvider =
    Provider<TareaFormularioOfflineDataSource>((ref) {
  return TareaFormularioOfflineDataSource(
    snapshotStore: ref.watch(snapshotStoreProvider),
    queueStore: ref.watch(offlineQueueStoreProvider),
  );
});
