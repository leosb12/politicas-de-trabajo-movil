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
  }) {
    return _executeWithFallback((Dio dio) async {
      final Response<dynamic> response = await dio.get(
        NetworkConstants.availableTramitesPath,
        options: Options(headers: <String, String>{'X-User-Id': actorUserId}),
      );

      return _parseTramites(response.data);
    });
  }

  @override
  Future<void> iniciarTramite({
    required String actorUserId,
    required String tramiteId,
  }) {
    return _executeWithFallback((Dio dio) async {
      await dio.post(
        NetworkConstants.instanciasPath,
        data: jsonEncode(<String, String>{'politicaId': tramiteId}),
        options: Options(
          contentType: Headers.jsonContentType,
          headers: <String, String>{'X-User-Id': actorUserId},
        ),
      );
    });
  }

  List<TramiteDisponibleItem> _parseTramites(dynamic data) {
    if (data is! List<dynamic>) {
      throw ApiFailure(message: 'Respuesta invalida del servidor.');
    }

    return data.map((dynamic item) {
      if (item is! Map<String, dynamic>) {
        throw ApiFailure(message: 'Respuesta invalida del servidor.');
      }

      final String id = (item['id'] as String? ?? '').trim();
      if (id.isEmpty) {
        throw ApiFailure(message: 'El servidor devolvio un tramite invalido.');
      }

      return TramiteDisponibleItem(
        id: id,
        nombre: (item['nombre'] as String? ?? '').trim(),
        descripcion: (item['descripcion'] as String? ?? '').trim(),
        categoria: 'Trámite',
      );
    }).toList(growable: false);
  }

  Future<T> _executeWithFallback<T>(Future<T> Function(Dio dio) action) async {
    final List<String> baseUrls = NetworkConstants.candidateBaseUrls(
      currentBaseUrl: _dio.options.baseUrl,
    );

    ApiFailure? fatalFailure;
    DioException? retryableException;

    for (final String baseUrl in baseUrls) {
      final Dio dio = _buildDioFor(baseUrl: baseUrl);

      try {
        final T result = await action(dio);
        _dio.options.baseUrl = baseUrl;
        return result;
      } on DioException catch (exception) {
        if (_isRetryable(exception)) {
          retryableException = exception;
          continue;
        }

        fatalFailure ??= ApiFailure.fromDioException(exception);
      } on ApiFailure catch (failure) {
        fatalFailure ??= failure;
      }
    }

    if (fatalFailure != null) {
      throw fatalFailure;
    }

    if (retryableException != null) {
      throw ApiFailure.fromDioException(retryableException);
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

  bool _isRetryable(DioException exception) {
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
}