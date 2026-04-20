import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/network_constants.dart';
import '../models/crear_instancia_request_model.dart';
import '../models/instancia_iniciada_model.dart';
import '../models/tramite_disponible_model.dart';

abstract class TramitesRemoteDataSource {
  Future<List<TramiteDisponibleModel>> obtenerDisponibles({
    required String actorUserId,
  });

  Future<InstanciaIniciadaModel> iniciarTramite({
    required String actorUserId,
    required String politicaId,
  });
}

class TramitesRemoteDataSourceImpl implements TramitesRemoteDataSource {
  TramitesRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<TramiteDisponibleModel>> obtenerDisponibles({
    required String actorUserId,
  }) {
    return _executeWithFallback((dio) async {
      final Response<dynamic> response = await dio.get(
        NetworkConstants.availableTramitesPath,
        options: Options(headers: <String, String>{'X-User-Id': actorUserId}),
      );

      return _parseTramitesDisponiblesResponse(response.data);
    });
  }

  @override
  Future<InstanciaIniciadaModel> iniciarTramite({
    required String actorUserId,
    required String politicaId,
  }) {
    final CrearInstanciaRequestModel request = CrearInstanciaRequestModel(
      politicaId: politicaId,
    );

    return _executeWithFallback((dio) async {
      final Response<dynamic> response = await dio.post(
        NetworkConstants.instanciasPath,
        data: jsonEncode(request.toJson()),
        options: Options(
          contentType: Headers.jsonContentType,
          headers: <String, String>{'X-User-Id': actorUserId},
        ),
      );

      return _parseInstanciaIniciadaResponse(response.data);
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

  List<TramiteDisponibleModel> _parseTramitesDisponiblesResponse(dynamic data) {
    if (data is! List<dynamic>) {
      throw ApiFailure(message: 'Respuesta invalida del servidor.');
    }

    return data
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw ApiFailure(message: 'Respuesta invalida del servidor.');
          }

          return TramiteDisponibleModel.fromJson(item);
        })
        .toList(growable: false);
  }

  InstanciaIniciadaModel _parseInstanciaIniciadaResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(message: 'Respuesta invalida del servidor.');
    }

    return InstanciaIniciadaModel.fromJson(data);
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
}
