import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_constants.dart';
import '../../data/datasources/iniciar_tramite_mock_datasource.dart';
import '../../data/datasources/iniciar_tramite_remote_datasource.dart';
import '../../data/repositories/iniciar_tramite_repository_impl.dart';
import '../../domain/repositories/iniciar_tramite_repository.dart';
import 'iniciar_tramite_state.dart';
import 'iniciar_tramite_view_model.dart';

const bool _useMockIniciarTramites = false;

final iniciarTramiteDioProvider = Provider<Dio>((ref) {
  return ApiClient(baseUrl: NetworkConstants.baseUrl).dio;
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
  return IniciarTramiteRepositoryImpl(ref.watch(iniciarTramiteDataSourceProvider));
});

final iniciarTramiteViewModelProvider =
    StateNotifierProvider<IniciarTramiteViewModel, IniciarTramiteState>((ref) {
      return IniciarTramiteViewModel(
        repository: ref.watch(iniciarTramiteRepositoryProvider),
      );
    });