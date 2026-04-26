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
  Future<void> iniciarTramite({
    required String actorUserId,
    required String tramiteId,
  }) async {
    try {
      await _dio.post(
        NetworkConstants.instanciasPath,
        data: jsonEncode(<String, String>{'politicaId': tramiteId}),
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
}
