import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/network_constants.dart';
import '../../domain/models/tramite_disponible_item.dart';
import 'iniciar_tramite_mock_datasource.dart';

class IniciarTramiteRemoteDataSource implements IniciarTramiteDataSource {
  IniciarTramiteRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<TramiteDisponibleItem>> obtenerTramitesActivos({
    required String actorUserId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        NetworkConstants.availableTramitesPath,
        options: Options(headers: <String, String>{'X-User-Id': actorUserId}),
      );

      return _parseTramites(response.data);
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  @override
  Future<ClasificacionSolicitudResult> clasificarSolicitud({
    required String actorUserId,
    required String texto,
    bool usarDeepSeek = false,
    String? nombreDocumento,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        NetworkConstants.clasificarSolicitudMovilPath,
        data: jsonEncode(<String, dynamic>{
          'texto': texto,
          'usarDeepSeek': usarDeepSeek,
          if (nombreDocumento != null) 'nombreDocumento': nombreDocumento,
        }),
        options: Options(
          contentType: Headers.jsonContentType,
          headers: <String, String>{'X-User-Id': actorUserId},
        ),
      );

      return _parseClasificacion(response.data);
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  @override
  Future<void> iniciarTramite({
    required String actorUserId,
    required String tramiteId,
    Map<String, dynamic>? respuestasRequisitosIniciales,
  }) async {
    try {
      final Map<String, dynamic> request = <String, dynamic>{
        'politicaId': tramiteId,
        if (respuestasRequisitosIniciales != null)
          'respuestasRequisitosIniciales': respuestasRequisitosIniciales,
      };

      await _dio.post(
        NetworkConstants.instanciasPath,
        data: jsonEncode(request),
        options: Options(
          contentType: Headers.jsonContentType,
          headers: <String, String>{'X-User-Id': actorUserId},
        ),
      );
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  List<TramiteDisponibleItem> _parseTramites(dynamic data) {
    if (data is! List<dynamic>) {
      throw ApiFailure(message: 'Respuesta invalida del servidor.');
    }

    return data
        .map((dynamic item) {
          if (item is! Map<String, dynamic>) {
            throw ApiFailure(message: 'Respuesta invalida del servidor.');
          }

          final String id = (item['id'] as String? ?? '').trim();
          if (id.isEmpty) {
            throw ApiFailure(
              message: 'El servidor devolvio un tramite invalido.',
            );
          }

          return TramiteDisponibleItem(
            id: id,
            nombre: (item['nombre'] as String? ?? '').trim(),
            descripcion: (item['descripcion'] as String? ?? '').trim(),
            categoria: 'Tramite',
            requierePago: item['requierePago'] as bool? ?? false,
            tieneRequisitosIniciales:
                item['tieneRequisitosIniciales'] as bool? ?? false,
            montoPago: _readMontoPago(item['montoPago']),
            monedaPago: item['monedaPago'] as String?,
            descripcionPago: item['descripcionPago'] as String?,
          );
        })
        .toList(growable: false);
  }

  double? _readMontoPago(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  ClasificacionSolicitudResult _parseClasificacion(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(message: 'Respuesta invalida del clasificador.');
    }

    final String politicaId = (data['politicaId'] as String? ?? '').trim();
    final String nombrePolitica = (data['nombrePolitica'] as String? ?? '')
        .trim();

    if (politicaId.isEmpty || nombrePolitica.isEmpty) {
      throw ApiFailure(message: 'La IA no devolvio una politica valida.');
    }

    return ClasificacionSolicitudResult(
      politicaId: politicaId,
      nombrePolitica: nombrePolitica,
      descripcionPolitica: data['descripcionPolitica'] as String?,
      confianza: _readConfidence(data['confianza']),
      origen: (data['origen'] as String? ?? '').trim(),
      metodoRecomendacion: data['metodoRecomendacion'] as String?,
      requiereMasInformacion: data['requiereMasInformacion'] as bool? ?? false,
      requiereConfirmacion: data['requiereConfirmacion'] as bool? ?? true,
      mensaje: (data['mensaje'] as String? ?? '').trim(),
      requisitosDetectados: _parseStringList(data['requisitosDetectados']),
      requisitosCoincidentes: _parseStringList(data['requisitosCoincidentes']),
      requisitosFaltantes: _parseStringList(data['requisitosFaltantes']),
      scoreRequisitos: _readDoubleNullable(data['scoreRequisitos']),
      scoreSemantico: _readDoubleNullable(data['scoreSemantico']),
      scoreFinal: _readDoubleNullable(data['scoreFinal']),
      topResultados: _parseTopResultados(data['topResultados']),
    );
  }

  List<String> _parseStringList(dynamic value) {
    if (value is List<dynamic>) {
      return value.map((dynamic e) => e.toString()).toList();
    }
    return const <String>[];
  }

  double? _readDoubleNullable(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  List<ClasificacionSolicitudItem> _parseTopResultados(dynamic data) {
    if (data is! List<dynamic>) {
      return <ClasificacionSolicitudItem>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> item) {
          return ClasificacionSolicitudItem(
            politicaId: (item['politicaId'] as String? ?? '').trim(),
            nombrePolitica: (item['nombrePolitica'] as String? ?? '').trim(),
            confianza: _readConfidence(item['confianza']),
            scoreRequisitos: _readDoubleNullable(item['scoreRequisitos']),
            scoreSemantico: _readDoubleNullable(item['scoreSemantico']),
            scoreFinal: _readDoubleNullable(item['scoreFinal']),
            requisitosCoincidentes: _parseStringList(item['requisitosCoincidentes']),
            requisitosFaltantes: _parseStringList(item['requisitosFaltantes']),
          );
        })
        .where(
          (ClasificacionSolicitudItem item) =>
              item.politicaId.isNotEmpty && item.nombrePolitica.isNotEmpty,
        )
        .toList(growable: false);
  }

  double _readConfidence(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }
}
