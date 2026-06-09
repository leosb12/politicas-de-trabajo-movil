import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/offline/offline_providers.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../data/datasources/iniciar_tramite_mock_datasource.dart';
import '../../data/datasources/iniciar_tramite_remote_datasource.dart';
import '../../data/repositories/iniciar_tramite_repository_impl.dart';
import '../../domain/repositories/iniciar_tramite_repository.dart';
import 'iniciar_tramite_state.dart';
import 'iniciar_tramite_view_model.dart';

const bool _useMockIniciarTramites = false;

final iniciarTramiteDioProvider = Provider<Dio>((ref) {
  return ref.watch(dioProvider);
});

final iniciarTramiteDataSourceProvider = Provider<IniciarTramiteDataSource>((
  ref,
) {
  if (_useMockIniciarTramites) {
    return IniciarTramiteMockDataSource();
  }

  return IniciarTramiteRemoteDataSource(ref.watch(iniciarTramiteDioProvider));
});

final iniciarTramiteRepositoryProvider = Provider<IniciarTramiteRepository>((
  ref,
) {
  return IniciarTramiteRepositoryImpl(
    remoteDataSource: ref.watch(iniciarTramiteDataSourceProvider),
    snapshotStore: ref.watch(snapshotStoreProvider),
    queueStore: ref.watch(offlineQueueStoreProvider),
    connectivity: ref.watch(connectivityNotifierProvider.notifier),
  );
});

final iniciarTramiteViewModelProvider =
    StateNotifierProvider<IniciarTramiteViewModel, IniciarTramiteState>((ref) {
      return IniciarTramiteViewModel(
        repository: ref.watch(iniciarTramiteRepositoryProvider),
      );
    });
