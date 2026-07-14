class AppEnvironment {
  AppEnvironment._();

  static const String defaultApiBaseUrl = 'http://127.0.0.1:8080/api/mobile/v1';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultApiBaseUrl,
  );

  static Uri get apiBaseUri => resolveApiBaseUri(apiBaseUrl);

  static String resolveBackendFileUrl(String value) {
    final trimmed = value.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme && parsed.hasAuthority) {
      return parsed.toString();
    }
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return apiBaseUri
        .replace(path: path, queryParameters: null, fragment: null)
        .toString();
  }

  static Uri resolveApiBaseUri(String value) {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException(
        'API_BASE_URL must be an absolute HTTP or HTTPS URL.',
      );
    }
    return uri;
  }
}
