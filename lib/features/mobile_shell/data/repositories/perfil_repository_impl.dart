import '../../domain/models/perfil_usuario.dart';
import '../../domain/repositories/perfil_repository.dart';
import '../datasources/perfil_mock_datasource.dart';
import '../mappers/perfil_usuario_mapper.dart';

class PerfilRepositoryImpl implements PerfilRepository {
  PerfilRepositoryImpl({
    required PerfilDataSource dataSource,
    required PerfilUsuarioMapper mapper,
  }) : _dataSource = dataSource,
       _mapper = mapper;

  final PerfilDataSource _dataSource;
  final PerfilUsuarioMapper _mapper;

  @override
  Future<PerfilUsuario?> obtenerPerfil({required String usuarioId}) async {
    final dto = await _dataSource.obtenerPerfil(usuarioId: usuarioId);
    if (dto == null) {
      return null;
    }

    return _mapper.toDomain(dto);
  }
}