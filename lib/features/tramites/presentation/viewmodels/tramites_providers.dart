import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/offline/offline_providers.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../data/datasource/tramites_remote_datasource.dart';
import '../../data/repositories/tramites_repository_impl.dart';
import '../../domain/repositories/tramites_repository.dart';
import '../../domain/usecases/iniciar_tramite_usecase.dart';
import '../../domain/usecases/obtener_requisitos_iniciales_usecase.dart';
import '../../domain/usecases/obtener_tramites_disponibles_usecase.dart';
import 'tramites_state.dart';
import 'tramites_view_model.dart';

final tramitesDioProvider = Provider<Dio>((ref) {
  return ref.watch(dioProvider);
});

final tramitesRemoteDataSourceProvider = Provider<TramitesRemoteDataSource>((
  ref,
) {
  return TramitesRemoteDataSourceImpl(ref.watch(tramitesDioProvider));
});

final tramitesRepositoryProvider = Provider<TramitesRepository>((ref) {
  return TramitesRepositoryImpl(
    remoteDataSource: ref.watch(tramitesRemoteDataSourceProvider),
    snapshotStore: ref.watch(snapshotStoreProvider),
    connectivity: ref.watch(connectivityNotifierProvider.notifier),
  );
});

final obtenerTramitesDisponiblesUseCaseProvider =
    Provider<ObtenerTramitesDisponiblesUseCase>((ref) {
      return ObtenerTramitesDisponiblesUseCase(
        ref.watch(tramitesRepositoryProvider),
      );
    });

final iniciarTramiteUseCaseProvider = Provider<IniciarTramiteUseCase>((ref) {
  return IniciarTramiteUseCase(ref.watch(tramitesRepositoryProvider));
});

final obtenerRequisitosInicialesUseCaseProvider =
    Provider<ObtenerRequisitosInicialesUseCase>((ref) {
      return ObtenerRequisitosInicialesUseCase(
        ref.watch(tramitesRepositoryProvider),
      );
    });

final tramitesViewModelProvider =
    StateNotifierProvider<TramitesViewModel, TramitesState>((ref) {
      return TramitesViewModel(
        obtenerTramitesDisponiblesUseCase: ref.watch(
          obtenerTramitesDisponiblesUseCaseProvider,
        ),
        iniciarTramiteUseCase: ref.watch(iniciarTramiteUseCaseProvider),
      );
    });
