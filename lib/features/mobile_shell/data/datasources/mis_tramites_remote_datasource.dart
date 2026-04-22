import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/network_constants.dart';
import '../../domain/models/mis_tramite_item.dart';
import 'mis_tramites_mock_datasource.dart';

class MisTramitesRemoteDataSource implements MisTramitesDataSource {
  MisTramitesRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<MisTramiteItem>> obtenerMisTramites({
    required String usuarioId,
  }) {
    return _executeWithFallback((Dio dio) async {
      final Response<dynamic> response = await dio.get(
        NetworkConstants.instanciasPath,
        options: Options(headers: <String, String>{'X-User-Id': usuarioId}),
      );

      return _parseInstancias(data: response.data, usuarioId: usuarioId);
    });
  }

  List<MisTramiteItem> _parseInstancias({
    required dynamic data,
    required String usuarioId,
  }) {
    if (data is! List<dynamic>) {
      throw ApiFailure(message: 'Respuesta invalida del servidor.');
    }

    return data.map((dynamic rawItem) {
      if (rawItem is! Map<String, dynamic>) {
        throw ApiFailure(message: 'Respuesta invalida del servidor.');
      }

      final String id = (rawItem['id'] as String? ?? '').trim();
      if (id.isEmpty) {
        throw ApiFailure(message: 'El servidor devolvio una instancia invalida.');
      }

      final String estadoRaw = (rawItem['estadoInstancia'] as String? ?? '')
          .trim()
          .toUpperCase();

      final int totalTareas = _toInt(rawItem['totalTareas']);
      final int tareasCompletadas = _toInt(rawItem['tareasCompletadas']);

      return MisTramiteItem(
        id: id,
        usuarioId: usuarioId,
        nombre: (rawItem['politicaNombre'] as String? ?? '').trim().isEmpty
            ? 'Trámite sin nombre'
            : (rawItem['politicaNombre'] as String).trim(),
        estado: _normalizarEstado(estadoRaw),
        progreso: _calcularProgreso(
          estadoRaw: estadoRaw,
          totalTareas: totalTareas,
          tareasCompletadas: tareasCompletadas,
        ),
        actualizadoEn: _parseDateTime(
          rawItem['fechaActualizacion'] ?? rawItem['fechaCreacion'],
        ),
      );
    }).toList(growable: false);
  }

  Future<T> _executeWithFallback<T>(Future<T> Function(Dio dio) action) async {
    final List<String> candidateBaseUrls = NetworkConstants.candidateBaseUrls(
      currentBaseUrl: _dio.options.baseUrl,
    );

    ApiFailure? firstFatalFailure;
    DioException? lastRetryableException;

    for (final String baseUrl in candidateBaseUrls) {
      final Dio dio = _buildDioFor(baseUrl: baseUrl);

      try {
        final T result = await action(dio);
        _dio.options.baseUrl = baseUrl;
        return result;
      } on DioException catch (exception) {
        if (_isRetryableNetworkError(exception)) {
          lastRetryableException = exception;
          continue;
        }

        firstFatalFailure ??= ApiFailure.fromDioException(exception);
        continue;
      } on ApiFailure catch (failure) {
        firstFatalFailure ??= failure;
        continue;
      }
    }

    if (firstFatalFailure != null) {
      throw firstFatalFailure;
    }

    if (lastRetryableException != null) {
      throw ApiFailure.fromDioException(lastRetryableException);
    }

    throw ApiFailure(
      message: 'No se encontro una URL base valida para el backend.',
    );
  }

  Dio _buildDioFor({required String baseUrl}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _dio.options.connectTimeout,
        receiveTimeout: _dio.options.receiveTimeout,
        sendTimeout: _dio.options.sendTimeout,
        headers: Map<String, dynamic>.from(_dio.options.headers),
      ),
    );
  }

  bool _isRetryableNetworkError(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return false;
    }
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return 0;
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

  double _calcularProgreso({
    required String estadoRaw,
    required int totalTareas,
    required int tareasCompletadas,
  }) {
    if (totalTareas > 0) {
      return (tareasCompletadas / totalTareas).clamp(0, 1);
    }

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
}