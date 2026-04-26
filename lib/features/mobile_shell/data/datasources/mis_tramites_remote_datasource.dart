import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/network_constants.dart';
import '../../domain/models/mis_tramite_item.dart';
import '../../domain/models/tramite_seguimiento.dart';
import '../models/tramite_seguimiento_model.dart';
import 'mis_tramites_mock_datasource.dart';

class MisTramitesRemoteDataSource implements MisTramitesDataSource {
  MisTramitesRemoteDataSource(this._dio);

  final Dio _dio;
  static const int _defaultPage = 0;
  static const int _defaultSize = 50;

  @override
  Future<List<MisTramiteItem>> obtenerMisTramites({
    required String usuarioId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        NetworkConstants.misTramitesCardsPath,
        queryParameters: const <String, dynamic>{
          'page': _defaultPage,
          'size': _defaultSize,
        },
        options: Options(headers: <String, String>{'X-User-Id': usuarioId}),
      );

      return _parseInstanciasCards(data: response.data, usuarioId: usuarioId);
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  @override
  Future<TramiteSeguimiento> obtenerSeguimiento({
    required String usuarioId,
    required String instanciaId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        NetworkConstants.instanciaFlujoPath(instanciaId),
        options: Options(headers: <String, String>{'X-User-Id': usuarioId}),
      );

      return _parseSeguimientoResponse(response.data).toDomain();
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  List<MisTramiteItem> _parseInstanciasCards({
    required dynamic data,
    required String usuarioId,
  }) {
    final dynamic rawContent;
    if (data is List<dynamic>) {
      rawContent = data;
    } else if (data is Map<String, dynamic>) {
      rawContent = data['content'];
    } else if (data is Map<dynamic, dynamic>) {
      rawContent = data['content'];
    } else {
      throw ApiFailure(message: 'Respuesta invalida del servidor.');
    }

    if (rawContent is! List<dynamic>) {
      throw ApiFailure(message: 'Respuesta invalida del servidor.');
    }

    return rawContent
        .map((dynamic rawItem) {
          final Map<String, dynamic>? item = _asJsonMap(rawItem);
          if (item == null) {
            throw ApiFailure(message: 'Respuesta invalida del servidor.');
          }

          final String id = _stringValue(item['id']);
          if (id.isEmpty) {
            throw ApiFailure(
              message: 'El servidor devolvio una instancia invalida.',
            );
          }

          final String estadoRaw = _stringValue(
            item['estadoInstancia'],
          ).toUpperCase();

          return MisTramiteItem(
            id: id,
            usuarioId: usuarioId,
            codigoTramite: _stringValue(item['codigoTramite']),
            nombre: _stringValue(item['nombre']).isEmpty
                ? 'Tramite sin nombre'
                : _stringValue(item['nombre']),
            estado: _normalizarEstado(estadoRaw),
            progreso: _estimarProgresoPorEstado(estadoRaw),
            fechaCreacion: _parseDateTime(item['fechaCreacion']),
          );
        })
        .toList(growable: false);
  }

  String _normalizarEstado(String estadoRaw) {
    switch (estadoRaw) {
      case 'EN_CURSO':
        return 'En curso';
      case 'FINALIZADA':
        return 'Finalizada';
      case 'PAUSADA':
        return 'Pausada';
      case 'CANCELADA':
        return 'Cancelada';
      default:
        return estadoRaw.isEmpty ? 'Sin estado' : estadoRaw;
    }
  }

  double _estimarProgresoPorEstado(String estadoRaw) {
    switch (estadoRaw) {
      case 'FINALIZADA':
        return 1;
      case 'CANCELADA':
        return 1;
      case 'PAUSADA':
        return 0.5;
      case 'EN_CURSO':
        return 0.2;
      default:
        return 0;
    }
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  String _stringValue(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  Map<String, dynamic>? _asJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map<dynamic, dynamic>) {
      return value.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );
    }

    return null;
  }

  TramiteSeguimientoModel _parseSeguimientoResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return TramiteSeguimientoModel.fromJson(data);
    }

    if (data is Map<dynamic, dynamic>) {
      return TramiteSeguimientoModel.fromJson(
        data.map(
          (dynamic key, dynamic value) =>
              MapEntry<String, dynamic>(key.toString(), value),
        ),
      );
    }

    throw ApiFailure(message: 'Respuesta invalida del servidor.');
  }
}
