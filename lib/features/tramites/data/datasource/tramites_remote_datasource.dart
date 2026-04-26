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

  Future<List<InstanciaIniciadaModel>> obtenerInstancias({
    required String actorUserId,
    String? estado,
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
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        NetworkConstants.availableTramitesPath,
        options: Options(headers: <String, String>{'X-User-Id': actorUserId}),
      );

      return _parseTramitesDisponiblesResponse(response.data);
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  @override
  Future<List<InstanciaIniciadaModel>> obtenerInstancias({
    required String actorUserId,
    String? estado,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        NetworkConstants.instanciasPath,
        queryParameters: estado != null && estado.trim().isNotEmpty
            ? <String, dynamic>{'estado': estado}
            : null,
        options: Options(headers: <String, String>{'X-User-Id': actorUserId}),
      );

      return _parseInstanciasResponse(response.data);
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  @override
  Future<InstanciaIniciadaModel> iniciarTramite({
    required String actorUserId,
    required String politicaId,
  }) async {
    final CrearInstanciaRequestModel request = CrearInstanciaRequestModel(
      politicaId: politicaId,
    );

    try {
      final Response<dynamic> response = await _dio.post(
        NetworkConstants.instanciasPath,
        data: jsonEncode(request.toJson()),
        options: Options(
          contentType: Headers.jsonContentType,
          headers: <String, String>{'X-User-Id': actorUserId},
        ),
      );

      return _parseInstanciaIniciadaResponse(response.data);
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
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

  List<InstanciaIniciadaModel> _parseInstanciasResponse(dynamic data) {
    if (data is! List<dynamic>) {
      throw ApiFailure(message: 'Respuesta invalida del servidor.');
    }

    return data
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw ApiFailure(message: 'Respuesta invalida del servidor.');
          }

          return InstanciaIniciadaModel.fromJson(item);
        })
        .toList(growable: false);
  }

  InstanciaIniciadaModel _parseInstanciaIniciadaResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(message: 'Respuesta invalida del servidor.');
    }

    return InstanciaIniciadaModel.fromJson(data);
  }
}
