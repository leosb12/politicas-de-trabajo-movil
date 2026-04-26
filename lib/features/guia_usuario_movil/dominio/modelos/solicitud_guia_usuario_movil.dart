import 'contexto_guia_usuario_movil.dart';

class SolicitudGuiaUsuarioMovil {
  const SolicitudGuiaUsuarioMovil({
    required this.usuarioId,
    required this.pantalla,
    required this.pregunta,
    this.nombreUsuario = '',
    this.rol = 'MOBILE_USER',
    this.contexto = const ContextoGuiaUsuarioMovil(),
  });

  final String usuarioId;
  final String nombreUsuario;
  final String rol;
  final String pantalla;
  final String pregunta;
  final ContextoGuiaUsuarioMovil contexto;

  Map<String, dynamic> aJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'userId': usuarioId.trim(),
      'role': rol.trim().isEmpty ? 'MOBILE_USER' : rol.trim(),
      'screen': pantalla.trim(),
      'question': pregunta.trim(),
      'context': contexto.aJson(),
    };

    if (nombreUsuario.trim().isNotEmpty) {
      json['userName'] = nombreUsuario.trim();
    }

    return json;
  }
}
