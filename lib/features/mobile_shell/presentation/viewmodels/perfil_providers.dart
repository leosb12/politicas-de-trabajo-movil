import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/datasources/perfil_mock_datasource.dart';
import '../../data/datasources/perfil_session_datasource.dart';
import '../../data/mappers/perfil_usuario_mapper.dart';
import '../../data/repositories/perfil_repository_impl.dart';
import '../../domain/repositories/perfil_repository.dart';
import '../../domain/services/perfil_visibilidad_policy.dart';
import 'perfil_state.dart';
import 'perfil_view_model.dart';

const bool _useMockPerfil = false;

final perfilSessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage(ref.watch(sharedPreferencesProvider));
});

final perfilDataSourceProvider = Provider<PerfilDataSource>((ref) {
  if (_useMockPerfil) {
    return PerfilMockDataSource();
  }

  return PerfilSessionDataSource(ref.watch(perfilSessionStorageProvider));
});

final perfilMapperProvider = Provider<PerfilUsuarioMapper>((ref) {
  return const PerfilUsuarioMapper();
});

final perfilRepositoryProvider = Provider<PerfilRepository>((ref) {
  return PerfilRepositoryImpl(
    dataSource: ref.watch(perfilDataSourceProvider),
    mapper: ref.watch(perfilMapperProvider),
  );
});

final perfilVisibilidadPolicyProvider = Provider<PerfilVisibilidadPolicy>((ref) {
  return const PerfilVisibilidadPolicy();
});

final perfilViewModelProvider =
    StateNotifierProvider<PerfilViewModel, PerfilState>((ref) {
      return PerfilViewModel(
        repository: ref.watch(perfilRepositoryProvider),
        visibilidadPolicy: ref.watch(perfilVisibilidadPolicyProvider),
      );
    });