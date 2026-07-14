import 'package:tech_smart_shop/model/common/api_models.dart';
import 'package:tech_smart_shop/model/offer/offer_models.dart';
import 'package:tech_smart_shop/model/product/catalog_models.dart';
import 'package:tech_smart_shop/service/offer/offer_service.dart';

final sampleOffer = OfferSummary(
  id: 1,
  code: 'TEST_OFFER',
  title: 'Online Tech Deals',
  subtitle: 'Savings on selected products',
  description: 'Backend-driven offer data for tests.',
  channel: 'Online',
  startAt: DateTime.utc(2026, 7, 1),
  endAt: DateTime.utc(2026, 7, 31),
  productCount: 1,
);

final sampleOfferProduct = OfferProduct(
  id: 32,
  productCode: 'ANKER',
  name: 'Anker 555 USB-C Hub (8-in-1)',
  sellingPrice: DecimalValue.fromInput('4950.00'),
  originalPrice: DecimalValue.fromInput('5500.00'),
  savingsAmount: DecimalValue.fromInput('550.00'),
  savingsLabel: '10% off',
  stock: const StockAvailability(inStock: true, stockLabel: 'In Stock'),
  offerId: 1,
  offerTitle: 'Online Tech Deals',
);

class FakeOfferRepository implements OfferRepository {
  const FakeOfferRepository({this.empty = false, this.fail = false});
  final bool empty;
  final bool fail;

  @override
  Future<List<OfferSummary>> fetchOffers() async {
    if (fail) throw const OfferRequestException('failed');
    return empty ? const [] : [sampleOffer];
  }

  @override
  Future<OfferDetail> fetchOffer(int id) async {
    if (fail) throw const OfferRequestException('failed');
    return OfferDetail(
      id: sampleOffer.id,
      code: sampleOffer.code,
      title: sampleOffer.title,
      subtitle: sampleOffer.subtitle,
      description: sampleOffer.description,
      bannerUrl: sampleOffer.bannerUrl,
      channel: sampleOffer.channel,
      startAt: sampleOffer.startAt,
      endAt: sampleOffer.endAt,
      productCount: sampleOffer.productCount,
    );
  }

  @override
  Future<ApiPage<OfferProduct>> fetchOfferProducts(
    int id, {
    int page = 0,
    int size = 20,
  }) async {
    if (fail) throw const OfferRequestException('failed');
    return ApiPage(
      content: empty ? const [] : [sampleOfferProduct],
      page: page,
      size: size,
      totalElements: empty ? 0 : 1,
      totalPages: empty ? 0 : 1,
      first: true,
      last: true,
    );
  }
}
