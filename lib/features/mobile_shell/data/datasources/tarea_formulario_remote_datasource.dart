import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/network_constants.dart';
import '../../domain/models/tarea_formulario_detalle.dart';
import '../models/tarea_formulario_detalle_model.dart';

abstract class TareaFormularioDataSource {
  Future<TareaFormularioDetalle> obtenerDetalle({
    required String usuarioId,
    required String tareaId,
  });

  Future<void> completarTarea({
    required String usuarioId,
    required String tareaId,
    required Map<String, dynamic> formularioRespuesta,
    String? observaciones,
  });
}

class TareaFormularioRemoteDataSource implements TareaFormularioDataSource {
  TareaFormularioRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<TareaFormularioDetalle> obtenerDetalle({
    required String usuarioId,
    required String tareaId,
  }) {
    return _executeWithFallback((Dio dio) async {
      final Response<dynamic> response = await dio.get(
        NetworkConstants.tareaDetallePath(tareaId),
        options: Options(headers: <String, String>{'X-User-Id': usuarioId}),
      );

      final JsonMap? json = _toJsonMap(response.data);
      if (json == null) {
        throw ApiFailure(message: 'Respuesta invalida del servidor.');
      }

      return TareaFormularioDetalleModel.fromJson(json).toDomain();
    });
  }

  @override
  Future<void> completarTarea({
    required String usuarioId,
    required String tareaId,
    required Map<String, dynamic> formularioRespuesta,
    String? observaciones,
  }) {
    return _executeWithFallback((Dio dio) async {
      await dio.post<dynamic>(
        NetworkConstants.tareaCompletarPath(tareaId),
        data: <String, dynamic>{
          'formularioRespuesta': formularioRespuesta,
          'observaciones': _normalize(observaciones),
        },
        options: Options(headers: <String, String>{'X-User-Id': usuarioId}),
      );
    });
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
      } on ApiFailure catch (failure) {
        firstFatalFailure ??= failure;
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

  String? _normalize(String? value) {
    final String normalized = (value ?? '').trim();
    return normalized.isEmpty ? null : normalized;
  }
}

JsonMap? _toJsonMap(dynamic value) {
  if (value is JsonMap) {
    return value;
  }

  if (value is Map<dynamic, dynamic>) {
    return value.map(
      (dynamic key, dynamic item) =>
          MapEntry<String, dynamic>(key.toString(), item),
    );
  }

  return null;
}
