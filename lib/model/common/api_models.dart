class CatalogParseException implements FormatException {
  const CatalogParseException(this.message, [this.source, this.offset]);

  @override
  final String message;
  @override
  final Object? source;
  @override
  final int? offset;

  @override
  String toString() => 'CatalogParseException: $message';
}

Map<String, Object?> requireMap(Object? value, String field) {
  if (value is Map<String, Object?>) return value;
  throw CatalogParseException('$field must be a JSON object.', value);
}

String requireString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is String && value.trim().isNotEmpty) return value;
  throw CatalogParseException('$field must be a non-empty string.', value);
}

int requireInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw CatalogParseException('$field must be an integer.', value);
}

bool requireBool(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is bool) return value;
  throw CatalogParseException('$field must be a boolean.', value);
}

class ApiEnvelope<T> {
  const ApiEnvelope({required this.success, required this.data, this.message});
  final bool success;
  final T data;
  final String? message;

  factory ApiEnvelope.fromJson(Object? value, T Function(Object?) parse) {
    final json = requireMap(value, 'response');
    return ApiEnvelope(
      success: requireBool(json, 'success'),
      data: parse(json['data']),
      message: json['message'] as String?,
    );
  }
}

class ApiPage<T> {
  const ApiPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  factory ApiPage.fromJson(Object? value, T Function(Object?) parse) {
    final json = requireMap(value, 'page');
    final raw = json['content'];
    if (raw is! List<Object?>) {
      throw CatalogParseException('content must be an array.', raw);
    }
    return ApiPage(
      content: List.unmodifiable(raw.map(parse)),
      page: requireInt(json, 'page'),
      size: requireInt(json, 'size'),
      totalElements: requireInt(json, 'totalElements'),
      totalPages: requireInt(json, 'totalPages'),
      first: requireBool(json, 'first'),
      last: requireBool(json, 'last'),
    );
  }
}

class MobileFieldError {
  const MobileFieldError({required this.field, required this.message});
  final String field;
  final String message;
  factory MobileFieldError.fromJson(Object? value) {
    final json = requireMap(value, 'fieldError');
    return MobileFieldError(
      field: requireString(json, 'field'),
      message: requireString(json, 'message'),
    );
  }
}

class MobileApiError {
  const MobileApiError({
    required this.code,
    required this.message,
    required this.fieldErrors,
  });
  final String code;
  final String message;
  final List<MobileFieldError> fieldErrors;
  factory MobileApiError.fromJson(Object? value) {
    final json = requireMap(value, 'error');
    final errors = json['fieldErrors'];
    return MobileApiError(
      code: requireString(json, 'code'),
      message: requireString(json, 'message'),
      fieldErrors: errors is List<Object?>
          ? List.unmodifiable(errors.map(MobileFieldError.fromJson))
          : const [],
    );
  }
}
