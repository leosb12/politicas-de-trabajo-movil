import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiFailure implements Exception {
  ApiFailure({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiFailure.fromDioException(DioException exception) {
    final int? statusCode = exception.response?.statusCode;
    final dynamic responseData = exception.response?.data;

    if (responseData is Map<String, dynamic>) {
      final dynamic backendMessage = responseData['message'];
      if (backendMessage is String && backendMessage.trim().isNotEmpty) {
        return ApiFailure(message: backendMessage, statusCode: statusCode);
      }
    }

    if (responseData is String && responseData.trim().isNotEmpty) {
      return ApiFailure(message: responseData, statusCode: statusCode);
    }

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiFailure(
          message: kDebugMode
              ? 'La solicitud tardo demasiado. '
                    'tipo=${exception.type.name} '
                    'url=${exception.requestOptions.uri}'
              : 'La solicitud tardo demasiado. Intenta nuevamente.',
          statusCode: statusCode,
        );
      case DioExceptionType.connectionError:
        return ApiFailure(
          message: kDebugMode
              ? 'No se pudo conectar con el servidor. '
                    'tipo=${exception.type.name} '
                    'url=${exception.requestOptions.uri} '
                    'detalle=${exception.message}'
              : 'No se pudo conectar con el servidor.',
          statusCode: statusCode,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return ApiFailure(
          message: statusCode != null
              ? 'No fue posible completar la solicitud (HTTP $statusCode).'
              : 'Ocurrio un error inesperado.',
          statusCode: statusCode,
        );
    }
  }

  @override
  String toString() => message;
}
