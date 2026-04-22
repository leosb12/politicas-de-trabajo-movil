import '../dtos/perfil_usuario_dto.dart';

abstract class PerfilDataSource {
  Future<PerfilUsuarioDto?> obtenerPerfil({required String usuarioId});
}

class PerfilMockDataSource implements PerfilDataSource {
  static const List<PerfilUsuarioDto> _perfiles = <PerfilUsuarioDto>[
    PerfilUsuarioDto(
      id: '1',
      nombre: 'Usuario Demo',
      correo: 'usuario@demo.com',
      rol: 'USUARIO',
      departamentoId: null,
    ),
    PerfilUsuarioDto(
      id: '2',
      nombre: 'Funcionario Demo',
      correo: 'funcionario@demo.com',
      rol: 'FUNCIONARIO',
      departamentoId: 'Atención Ciudadana',
    ),
    PerfilUsuarioDto(
      id: '3',
      nombre: 'Admin Demo',
      correo: 'admin@demo.com',
      rol: 'ADMIN',
      departamentoId: 'Dirección General',
    ),
  ];

  @override
  Future<PerfilUsuarioDto?> obtenerPerfil({required String usuarioId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));

    for (final PerfilUsuarioDto perfil in _perfiles) {
      if (perfil.id == usuarioId) {
        return perfil;
      }
    }

    return null;
  }
}