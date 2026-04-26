import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/network_constants.dart';
import '../../dominio/modelos/respuesta_guia_usuario_movil.dart';
import '../../dominio/modelos/solicitud_guia_usuario_movil.dart';

class GuiaUsuarioMovilRemota {
  GuiaUsuarioMovilRemota(this._dio);

  final Dio _dio;
  static const Duration _guideConnectTimeout = Duration(seconds: 5);
  static const Duration _guideSendTimeout = Duration(seconds: 15);
  static const Duration _guideReceiveTimeout = Duration(seconds: 45);

  Future<RespuestaGuiaUsuarioMovil> consultar(
    SolicitudGuiaUsuarioMovil solicitud,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post(
        NetworkConstants.guiaUsuarioMovilPath,
        data: solicitud.aJson(),
        options: Options(
          headers: <String, String>{'X-User-Id': solicitud.usuarioId.trim()},
          connectTimeout: _guideConnectTimeout,
          sendTimeout: _guideSendTimeout,
          receiveTimeout: _guideReceiveTimeout,
        ),
      );

      final Map<String, dynamic> json = _comoMapa(response.data);
      return RespuestaGuiaUsuarioMovil.desdeJson(json);
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    }
  }

  Map<String, dynamic> _comoMapa(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map<dynamic, dynamic>) {
      return data.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );
    }
    throw ApiFailure(message: 'Respuesta invalida del servicio de guia.');
  }
}
