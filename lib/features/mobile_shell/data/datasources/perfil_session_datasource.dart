import '../../../../core/storage/session_storage.dart';
import '../dtos/perfil_usuario_dto.dart';
import 'perfil_mock_datasource.dart';

class PerfilSessionDataSource implements PerfilDataSource {
  PerfilSessionDataSource(this._sessionStorage);

  final SessionStorage _sessionStorage;

  @override
  Future<PerfilUsuarioDto?> obtenerPerfil({required String usuarioId}) async {
    final Map<String, dynamic>? session = _sessionStorage.readSession();
    if (session == null) {
      return null;
    }

    final PerfilUsuarioDto dto = PerfilUsuarioDto.fromJson(session);
    if (dto.id.trim().isEmpty) {
      return null;
    }

    if (dto.id.trim() != usuarioId.trim()) {
      return null;
    }

    return dto;
  }
}