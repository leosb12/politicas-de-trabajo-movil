import '../../../../core/network/api_failure.dart';
import '../../datos/origenes/guia_usuario_movil_remota.dart';
import '../../datos/origenes/respaldo_guia_usuario_movil_local.dart';
import '../modelos/respuesta_guia_usuario_movil.dart';
import '../modelos/solicitud_guia_usuario_movil.dart';

class ServicioGuiaUsuarioMovil {
  ServicioGuiaUsuarioMovil({
    required GuiaUsuarioMovilRemota remota,
    required RespaldoGuiaUsuarioMovilLocal respaldoLocal,
  }) : _remota = remota,
       _respaldoLocal = respaldoLocal;

  final GuiaUsuarioMovilRemota _remota;
  final RespaldoGuiaUsuarioMovilLocal _respaldoLocal;

  Future<ResultadoGuiaUsuarioMovil> responder(
    SolicitudGuiaUsuarioMovil solicitud,
  ) async {
    try {
      final RespuestaGuiaUsuarioMovil respuesta = await _remota.consultar(
        solicitud,
      );
      if (respuesta.tieneContenido) {
        return ResultadoGuiaUsuarioMovil(
          respuesta: respuesta,
          usoRespaldoLocal: false,
        );
      }
    } on ApiFailure catch (error) {
      final RespuestaGuiaUsuarioMovil respaldo = _respaldoLocal.construir(
        solicitud,
      );
      return ResultadoGuiaUsuarioMovil(
        respuesta: respaldo,
        usoRespaldoLocal: true,
        detalleRespaldo: error.message,
      );
    } catch (_) {
      final RespuestaGuiaUsuarioMovil respaldo = _respaldoLocal.construir(
        solicitud,
      );
      return ResultadoGuiaUsuarioMovil(
        respuesta: respaldo,
        usoRespaldoLocal: true,
        detalleRespaldo:
            'La guia IA no respondio en este momento. Se mostro una orientacion local.',
      );
    }

    final RespuestaGuiaUsuarioMovil respaldo = _respaldoLocal.construir(
      solicitud,
    );
    return ResultadoGuiaUsuarioMovil(
      respuesta: respaldo,
      usoRespaldoLocal: true,
      detalleRespaldo:
          'La guia IA no devolvio contenido. Se mostro una orientacion local.',
    );
  }
}
