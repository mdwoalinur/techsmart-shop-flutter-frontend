import '../address/address_models.dart';
import '../product/catalog_models.dart';

class DeliveryMethod {
  const DeliveryMethod({
    required this.id,
    required this.code,
    required this.name,
    required this.charge,
    required this.minDays,
    required this.maxDays,
    required this.eligible,
    this.reason,
  });
  final int id, minDays, maxDays;
  final String code, name;
  final DecimalValue charge;
  final bool eligible;
  final String? reason;
  factory DeliveryMethod.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return DeliveryMethod(
      id: (j['id'] as num).toInt(),
      code: j['code'] as String,
      name: j['name'] as String,
      charge: DecimalValue.fromJson(j['deliveryCharge'], 'deliveryCharge'),
      minDays: (j['estimatedMinDays'] as num).toInt(),
      maxDays: (j['estimatedMaxDays'] as num).toInt(),
      eligible: j['eligible'] == true,
      reason: j['ineligibilityReason'] as String?,
    );
  }
}

class CheckoutReview {
  const CheckoutReview({
    required this.id,
    required this.expiresAt,
    required this.subtotal,
    required this.tax,
    required this.delivery,
    required this.discount,
    required this.total,
    required this.address,
    required this.method,
    required this.blocking,
    required this.warnings,
    required this.ready,
  });
  final String id;
  final DateTime expiresAt;
  final DecimalValue subtotal, tax, delivery, discount, total;
  final CustomerAddress address;
  final DeliveryMethod method;
  final List<String> blocking, warnings;
  final bool ready;
  factory CheckoutReview.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return CheckoutReview(
      id: j['reviewId'] as String,
      expiresAt: DateTime.parse(j['reviewExpiresAt'] as String),
      subtotal: DecimalValue.fromJson(j['subtotal'], 'subtotal'),
      tax: DecimalValue.fromJson(j['taxTotal'], 'taxTotal'),
      delivery: DecimalValue.fromJson(j['deliveryCharge'], 'deliveryCharge'),
      discount: DecimalValue.fromJson(j['discountTotal'], 'discountTotal'),
      total: DecimalValue.fromJson(j['grandTotal'], 'grandTotal'),
      address: CustomerAddress.fromJson(j['address']),
      method: DeliveryMethod.fromJson(j['deliveryMethod']),
      blocking: (j['blockingIssues'] as List).cast<String>(),
      warnings: (j['warnings'] as List).cast<String>(),
      ready: j['readyToSubmit'] == true,
    );
  }
}

class OrderConfirmation {
  const OrderConfirmation({
    required this.orderNumber,
    required this.submittedAt,
    required this.orderStatus,
    required this.paymentStatus,
    required this.total,
    required this.address,
    required this.method,
    required this.nextStep,
  });
  final String orderNumber,
      orderStatus,
      paymentStatus,
      address,
      method,
      nextStep;
  final DateTime submittedAt;
  final DecimalValue total;
  factory OrderConfirmation.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return OrderConfirmation(
      orderNumber: j['orderNumber'] as String,
      submittedAt: DateTime.parse(j['submittedAt'] as String),
      orderStatus: j['orderStatus'] as String,
      paymentStatus: j['paymentStatus'] as String,
      total: DecimalValue.fromJson(j['grandTotal'], 'grandTotal'),
      address: j['deliveryAddress'] as String,
      method: j['deliveryMethod'] as String,
      nextStep: j['nextStep'] as String,
    );
  }
}
