import 'dart:collection';

class NetworkConstants {
  const NetworkConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.16:8080',
  );

  static const String fallbackBaseUrls = String.fromEnvironment(
    'API_BASE_URL_FALLBACKS',
    defaultValue: 'http://127.0.0.1:8080,http://10.0.2.2:8080',
  );

  static const String mobileLoginPath = '/api/auth/movil/login';
  static const String mobileRegisterPath = '/api/auth/movil/register';
  static const String availableTramitesPath =
      '/api/politicas/movil/disponibles';
  static const String instanciasPath = '/api/instancias';

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
