import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_failure.dart';
import 'network_constants.dart';

class StripeCheckoutResult {
  const StripeCheckoutResult({required this.checkoutUrl, this.sessionId});

  final String checkoutUrl;
  final String? sessionId;
}

class StripeVerificationResult {
  const StripeVerificationResult({required this.confirmado, this.estado});

  final bool confirmado;
  final String? estado;
}

class PaypalCheckoutResult {
  const PaypalCheckoutResult({required this.paypalUrl, required this.pagoId});

  final String paypalUrl;
  final String pagoId;
}

class PagoDetalle {
  const PagoDetalle({required this.id, required this.estado, this.rawData});

  final String id;
  final String estado;
  final Map<String, dynamic>? rawData;

  bool get estaAprobado {
    final String normalized = estado.trim().toUpperCase();
    return normalized == 'APROBADO' || normalized == 'APROBADO_MANUALMENTE';
  }

  bool get estaPendientePaypal {
    return estado.trim().toUpperCase() == 'PENDIENTE_CONFIRMACION_PAYPAL';
  }
}

class PagoService {
  PagoService(this._dio);

  final Dio _dio;

  Future<StripeCheckoutResult> crearCheckoutStripe({
    required String actorUserId,
    required String politicaId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        NetworkConstants.stripeCheckoutPath,
        data: jsonEncode(<String, String>{'politicaId': politicaId}),
        options: Options(
          contentType: Headers.jsonContentType,
          headers: <String, String>{'X-User-Id': actorUserId},
        ),
      );

      return _parseStripeCheckoutResult(response.data);
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  Future<StripeVerificationResult> verificarStripe({
    required String actorUserId,
    required String sessionId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        NetworkConstants.stripeVerificarPath,
        queryParameters: <String, dynamic>{'sessionId': sessionId},
        options: Options(
          headers: <String, String>{'X-User-Id': actorUserId},
        ),
      );

      return _parseStripeVerificationResult(response.data);
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  Future<PaypalCheckoutResult> crearLinkPaypal({
    required String actorUserId,
    required String politicaId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        NetworkConstants.paypalCrearLinkPath,
        data: jsonEncode(<String, String>{'politicaId': politicaId}),
        options: Options(
          contentType: Headers.jsonContentType,
          headers: <String, String>{'X-User-Id': actorUserId},
        ),
      );

      return _parsePaypalCheckoutResult(response.data);
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  Future<PagoDetalle> obtenerPago({
    required String actorUserId,
    required String pagoId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        NetworkConstants.pagoPath(pagoId),
        options: Options(
          headers: <String, String>{'X-User-Id': actorUserId},
        ),
      );

      return _parsePagoDetalle(response.data, fallbackId: pagoId);
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  StripeCheckoutResult _parseStripeCheckoutResult(dynamic data) {
    if (data is String && data.trim().isNotEmpty) {
      return StripeCheckoutResult(checkoutUrl: data.trim());
    }

    if (data is Map<String, dynamic>) {
      final String? checkoutUrl = _readString(data, <String>[
        'stripeCheckoutUrl',
        'checkoutUrl',
        'url',
      ]);

      if (checkoutUrl != null) {
        return StripeCheckoutResult(
          checkoutUrl: checkoutUrl,
          sessionId: _readString(data, <String>[
            'sessionId',
            'stripeSessionId',
          ]),
        );
      }
    }

    throw ApiFailure(message: 'Respuesta invalida del servidor.');
  }

  StripeVerificationResult _parseStripeVerificationResult(dynamic data) {
    if (data is bool) {
      return StripeVerificationResult(confirmado: data);
    }

    if (data is Map<String, dynamic>) {
      final bool? confirmado = _readBool(data, <String>[
        'confirmado',
        'pagado',
        'paid',
        'isPaid',
      ]);
      final String? estado = _readString(data, <String>['estado', 'status']);

      if (confirmado != null || estado != null) {
        return StripeVerificationResult(
          confirmado: confirmado ?? (estado?.trim().toUpperCase() == 'PAGADO'),
          estado: estado,
        );
      }
    }

    throw ApiFailure(message: 'Respuesta invalida del servidor.');
  }

  PaypalCheckoutResult _parsePaypalCheckoutResult(dynamic data) {
    if (data is Map<String, dynamic>) {
      final String? paypalUrl = _readString(data, <String>[
        'paypalUrl',
        'url',
        'approvalUrl',
      ]);
      final String? pagoId = _readString(data, <String>[
        'pagoId',
        'paymentId',
        'id',
      ]);

      if (paypalUrl != null && pagoId != null && pagoId.trim().isNotEmpty) {
        return PaypalCheckoutResult(
          paypalUrl: paypalUrl,
          pagoId: pagoId.trim(),
        );
      }
    }

    throw ApiFailure(message: 'Respuesta invalida del servidor.');
  }

  PagoDetalle _parsePagoDetalle(dynamic data, {required String fallbackId}) {
    if (data is Map<String, dynamic>) {
      final String? estado = _readString(data, <String>['estado', 'status']);
      final String id =
          _readString(data, <String>['id', 'pagoId']) ?? fallbackId;

      if (estado != null && estado.trim().isNotEmpty) {
        return PagoDetalle(id: id, estado: estado.trim(), rawData: data);
      }
    }

    throw ApiFailure(message: 'Respuesta invalida del servidor.');
  }

  String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  bool? _readBool(Map<String, dynamic> data, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = data[key];
      if (value is bool) {
        return value;
      }
      if (value is String) {
        final String normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'si') {
          return true;
        }
        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
          return false;
        }
      }
    }
    return null;
  }
}
