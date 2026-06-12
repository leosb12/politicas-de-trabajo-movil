class NetworkConstants {
  const NetworkConstants._();

  static const String baseUrl = 'https://parcial.leonardoserrate.xyz';

  static List<String> get baseUrls {
    const String configuredBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    final String normalized = _normalizeBaseUrl(configuredBaseUrl);
    if (normalized.isNotEmpty) {
      return <String>[normalized];
    }
    return const <String>[baseUrl];
  }

  static const String healthCheckPath = '/api/health';
  static const String mobileLoginPath = '/api/auth/movil/login';
  static const String mobileRegisterPath = '/api/auth/movil/register';
  static const String changePasswordPath = '/api/auth/cambiar-contrasena';
  static const String forgotPasswordPath = '/api/auth/forgot-password';
  static const String resetPasswordPath = '/api/auth/reset-password';
  static const String availableTramitesPath =
      '/api/politicas/movil/disponibles';
  static const String sincronizarCatalogPath =
      '/api/politicas/movil/sincronizar';
  static const String clasificarSolicitudMovilPath =
      '/api/movil/ia/clasificar-solicitud';
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
  static const String archivosPath = '/api/archivos';

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

  static String requisitosInicialesPath(String politicaId) {
    final String encodedId = Uri.encodeComponent(politicaId);
    return '/api/politicas/$encodedId/requisitos-iniciales';
  }

  static String tareaDetallePath(String tareaId) {
    final String encodedTareaId = Uri.encodeComponent(tareaId);
    return '$tareasPath/$encodedTareaId';
  }

  static String tareaCompletarPath(String tareaId) {
    final String encodedTareaId = Uri.encodeComponent(tareaId);
    return '$tareasPath/$encodedTareaId/completar';
  }

  static String archivosPorInstanciaPath(String instanciaId) {
    final String encodedInstanciaId = Uri.encodeComponent(instanciaId);
    return '$archivosPath/by-instancia/$encodedInstanciaId';
  }

  static String archivoDetallePath(String archivoId) {
    return '$archivosPath/${Uri.encodeComponent(archivoId)}';
  }

  static String archivoVerPath(String archivoId) {
    return '${archivoDetallePath(archivoId)}/view';
  }

  static String archivoDescargarPath(String archivoId) {
    return '${archivoDetallePath(archivoId)}/download';
  }

  static String archivoReemplazarPath(String archivoId) {
    return '${archivoDetallePath(archivoId)}/replace';
  }

  static String documentoColaborativoMobileViewerPath(String documentoId) {
    return '/api/documentos-colaborativos/${Uri.encodeComponent(documentoId)}/mobile-viewer';
  }

  static String documentosColaborativosPorTramitePath(String tramiteId) {
    final String encodedId = Uri.encodeComponent(tramiteId);
    return '/api/tramites/$encodedId/documentos-colaborativos';
  }

  static String documentosColaborativosPorTareaPath(String tareaId) {
    final String encodedId = Uri.encodeComponent(tareaId);
    return '/api/tareas/$encodedId/documentos-colaborativos';
  }



  static String _normalizeBaseUrl(String rawUrl) {
    return rawUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
