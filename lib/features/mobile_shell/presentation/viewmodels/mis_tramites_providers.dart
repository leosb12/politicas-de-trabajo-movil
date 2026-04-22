import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_constants.dart';
import '../../data/datasources/mis_tramites_mock_datasource.dart';
import '../../data/datasources/mis_tramites_remote_datasource.dart';
import '../../data/repositories/mis_tramites_repository_impl.dart';
import '../../domain/repositories/mis_tramites_repository.dart';
import 'mis_tramites_state.dart';
import 'mis_tramites_view_model.dart';

const bool _useMockMisTramites = false;

final misTramitesDioProvider = Provider<Dio>((ref) {
  return ApiClient(baseUrl: NetworkConstants.baseUrl).dio;
});

final misTramitesDataSourceProvider = Provider<MisTramitesDataSource>((ref) {
  if (_useMockMisTramites) {
    return MisTramitesMockDataSource();
  }

  return MisTramitesRemoteDataSource(ref.watch(misTramitesDioProvider));
});

final misTramitesRepositoryProvider = Provider<MisTramitesRepository>((ref) {
  return MisTramitesRepositoryImpl(ref.watch(misTramitesDataSourceProvider));
});

final misTramitesViewModelProvider =
    StateNotifierProvider<MisTramitesViewModel, MisTramitesState>((ref) {
      return MisTramitesViewModel(
        repository: ref.watch(misTramitesRepositoryProvider),
      );
    });