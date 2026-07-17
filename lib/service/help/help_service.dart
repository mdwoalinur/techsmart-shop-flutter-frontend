import '../../model/help/help_models.dart';
import '../../model/review/review_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';

abstract interface class HelpRepository {
  Future<List<HelpFaq>> faqs({String? category, String? query});
  Future<HelpFaq> faq(String faqCode);
}

class HelpService implements HelpRepository {
  const HelpService(this._client);
  final ApiClient _client;

  @override
  Future<List<HelpFaq>> faqs({String? category, String? query}) async {
    final qp = <String, String?>{};
    if (category != null) {
      qp['category'] = category;
    }
    if (query != null) {
      qp['q'] = query;
    }
    final raw = unwrapData(
      await _safe(() => _client.get('help/faqs', queryParameters: qp)),
    );
    if (raw is! List<Object?>) {
      throw const FormatException('faqs must be an array.');
    }
    return List.unmodifiable(raw.map(HelpFaq.fromJson));
  }

  @override
  Future<HelpFaq> faq(String faqCode) async =>
      HelpFaq.fromJson(await _safe(() => _client.get('help/faqs/$faqCode')));

  Future<Object?> _safe(Future<Object?> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      throw HelpRequestException(
        userSafeApiMessage(e),
        statusCode: e.statusCode,
        cause: e,
      );
    } on FormatException catch (e) {
      throw HelpRequestException(
        'The server returned unexpected help center data.',
        cause: e,
      );
    }
  }
}

class HelpRequestException implements Exception {
  const HelpRequestException(this.message, {this.statusCode, this.cause});
  final String message;
  final int? statusCode;
  final Object? cause;
}
