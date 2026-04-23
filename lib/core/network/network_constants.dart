import 'dart:collection';

class NetworkConstants {
  const NetworkConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.16:8080',
  );

  static const String fallbackBaseUrls = String.fromEnvironment(
    'API_BASE_URL_FALLBACKS',
    defaultValue: '',
  );

  static const String mobileLoginPath = '/api/auth/movil/login';
  static const String mobileRegisterPath = '/api/auth/movil/register';
  static const String availableTramitesPath =
      '/api/politicas/movil/disponibles';
  static const String instanciasPath = '/api/instancias';
  static const String tareasPath = '/api/tareas';

  static String instanciaSeguimientoPath(String instanciaId) {
    final String encodedInstanciaId = Uri.encodeComponent(instanciaId);
    return '$instanciasPath/$encodedInstanciaId/seguimiento';
  }

  static String tareaDetallePath(String tareaId) {
    final String encodedTareaId = Uri.encodeComponent(tareaId);
    return '$tareasPath/$encodedTareaId';
  }

  static String tareaCompletarPath(String tareaId) {
    final String encodedTareaId = Uri.encodeComponent(tareaId);
    return '$tareasPath/$encodedTareaId/completar';
  }

  static List<String> candidateBaseUrls({String? currentBaseUrl}) {
    final LinkedHashSet<String> uniqueBaseUrls = LinkedHashSet<String>();

    void addBaseUrl(String? value) {
      final String normalizedValue = (value ?? '').trim();
      if (normalizedValue.isEmpty) {
        return;
      }

      uniqueBaseUrls.add(normalizedValue);
    }

    addBaseUrl(currentBaseUrl);
    addBaseUrl(baseUrl);

    for (final String fallback in fallbackBaseUrls.split(',')) {
      addBaseUrl(fallback);
    }

    return uniqueBaseUrls.toList(growable: false);
  }
}
