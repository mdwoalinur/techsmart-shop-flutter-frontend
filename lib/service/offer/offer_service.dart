import '../../model/common/api_models.dart';
import '../../model/offer/offer_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';

abstract interface class OfferRepository {
  Future<List<OfferSummary>> fetchOffers();
  Future<OfferDetail> fetchOffer(int id);
  Future<ApiPage<OfferProduct>> fetchOfferProducts(
    int id, {
    int page = 0,
    int size = 20,
  });
}

class OfferService implements OfferRepository {
  const OfferService(this._client);
  final ApiClient _client;

  @override
  Future<List<OfferSummary>> fetchOffers() async {
    final raw = await _get('/offers');
    return ApiEnvelope<List<OfferSummary>>.fromJson(raw, (data) {
      if (data is! List<Object?>) {
        throw CatalogParseException('offers must be an array.', data);
      }
      return List.unmodifiable(data.map(OfferSummary.fromJson));
    }).data;
  }

  @override
  Future<OfferDetail> fetchOffer(int id) async =>
      ApiEnvelope<OfferDetail>.fromJson(
        await _get('/offers/$id'),
        OfferDetail.fromJson,
      ).data;

  @override
  Future<ApiPage<OfferProduct>> fetchOfferProducts(
    int id, {
    int page = 0,
    int size = 20,
  }) async => ApiEnvelope<ApiPage<OfferProduct>>.fromJson(
    await _get('/offers/$id/products', {'page': '$page', 'size': '$size'}),
    (raw) => ApiPage.fromJson(raw, OfferProduct.fromJson),
  ).data;

  Future<Object?> _get(
    String path, [
    Map<String, String?> query = const {},
  ]) async {
    try {
      return await _client.get(path, queryParameters: query);
    } on ApiException catch (error) {
      MobileApiError? parsed;
      try {
        if (error.responseBody != null) {
          parsed = MobileApiError.fromJson(error.responseBody);
        }
      } on FormatException {
        /* use safe message */
      }
      throw OfferRequestException(
        parsed?.message ?? error.message,
        statusCode: error.statusCode,
        type: error.type,
      );
    } on FormatException catch (error) {
      throw OfferRequestException(
        'The server returned unexpected offer data.',
        cause: error,
      );
    }
  }
}

class OfferRequestException implements Exception {
  const OfferRequestException(
    this.message, {
    this.statusCode,
    this.type,
    this.cause,
  });
  final String message;
  final int? statusCode;
  final ApiExceptionType? type;
  final Object? cause;
}
