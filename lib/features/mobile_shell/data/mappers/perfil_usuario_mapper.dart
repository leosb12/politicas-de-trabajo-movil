import '../../domain/models/perfil_usuario.dart';
import '../dtos/perfil_usuario_dto.dart';

class PerfilUsuarioMapper {
  const PerfilUsuarioMapper();

  PerfilUsuario toDomain(PerfilUsuarioDto dto) {
    return PerfilUsuario(
      usuarioId: dto.id,
      nombre: dto.nombre,
      correo: dto.correo,
      rol: dto.rol,
      departamento: dto.departamentoId,
    );
  }
}