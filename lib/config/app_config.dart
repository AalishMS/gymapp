class AppConfig {
  static const String _defaultApiBaseUrl =
      'https://opengym-api.azurewebsites.net';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );

  static String get normalizedApiBaseUrl {
    if (apiBaseUrl.endsWith('/')) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - 1);
    }
    return apiBaseUrl;
  }

  static Uri uriForPath(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedApiBaseUrl$normalizedPath');
  }
}
