import '../models/perfil_usuario.dart';

abstract class PerfilRepository {
  Future<PerfilUsuario?> obtenerPerfil({required String usuarioId});
}