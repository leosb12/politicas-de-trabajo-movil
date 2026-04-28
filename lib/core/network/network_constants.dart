import 'package:flutter/foundation.dart';

class NetworkConstants {
  const NetworkConstants._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _legacyLanBaseUrl = 'http://44.201.97.229:8080';

  static String get baseUrl => baseUrls.first;

  static List<String> get baseUrls {
    final String configuredBaseUrl = _normalizeBaseUrl(_configuredBaseUrl);
    if (configuredBaseUrl.isNotEmpty) {
      return <String>[configuredBaseUrl];
    }

    final List<String> resolved = <String>[];

    void addCandidate(String rawUrl) {
      final String normalized = _normalizeBaseUrl(rawUrl);
      if (normalized.isEmpty || resolved.contains(normalized)) {
        return;
      }
      resolved.add(normalized);
    }

    for (final String rawUrl in _defaultBaseUrlsForCurrentPlatform) {
      addCandidate(rawUrl);
    }

    if (resolved.isEmpty) {
      resolved.add(_legacyLanBaseUrl);
    }

    return resolved;
  }

  static const String mobileLoginPath = '/api/auth/movil/login';
  static const String mobileRegisterPath = '/api/auth/movil/register';
  static const String changePasswordPath = '/api/auth/cambiar-contrasena';
  static const String forgotPasswordPath = '/api/auth/forgot-password';
  static const String resetPasswordPath = '/api/auth/reset-password';
  static const String availableTramitesPath =
      '/api/politicas/movil/disponibles';
  static const String instanciasPath = '/api/instancias';
  static const String stripeCheckoutPath = '/api/pagos/stripe/crear-checkout';
  static const String stripeVerificarPath = '/api/pagos/stripe/verificar';
  static const String paypalCrearLinkPath = '/api/pagos/paypal/crear-link';
  static const String misTramitesCardsPath =
      '$instanciasPath/mis-tramites/cards';
  static const String tareasPath = '/api/tareas';
  static const String guiaUsuarioMovilPath = '/api/guide/mobile-user';
  static const String mobileDeviceTokensPath = '/api/mobile/device-tokens';
  static const String mobileNotificationTestPath =
      '/api/mobile/notifications/test';

  static String pagoPath(String pagoId) {
    final String encodedPagoId = Uri.encodeComponent(pagoId);
    return '/api/pagos/$encodedPagoId';
  }

  static String instanciaSeguimientoPath(String instanciaId) {
    final String encodedInstanciaId = Uri.encodeComponent(instanciaId);
    return '$instanciasPath/$encodedInstanciaId/seguimiento';
  }

  static String instanciaFlujoPath(String instanciaId) {
    final String encodedInstanciaId = Uri.encodeComponent(instanciaId);
    return '$instanciasPath/$encodedInstanciaId/flujo';
  }

  static String tareaDetallePath(String tareaId) {
    final String encodedTareaId = Uri.encodeComponent(tareaId);
    return '$tareasPath/$encodedTareaId';
  }

  static String tareaCompletarPath(String tareaId) {
    final String encodedTareaId = Uri.encodeComponent(tareaId);
    return '$tareasPath/$encodedTareaId/completar';
  }

  static List<String> get _defaultBaseUrlsForCurrentPlatform {
    if (kIsWeb) {
      return const <String>[
        'http://localhost:8080',
        'http://127.0.0.1:8080',
        _legacyLanBaseUrl,
      ];
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const <String>[
          _legacyLanBaseUrl,
        ];
      case TargetPlatform.iOS:
        return const <String>[
          _legacyLanBaseUrl,
        ];
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return const <String>[
          _legacyLanBaseUrl,
        ];
    }
  }

  static String _normalizeBaseUrl(String rawUrl) {
    return rawUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
