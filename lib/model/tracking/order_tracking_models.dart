enum FulfillmentStatus {
  processing,
  packed,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  deliveryException,
  unknown;

  static FulfillmentStatus parse(String? value) => switch (value) {
    'PROCESSING' => processing,
    'PACKED' => packed,
    'SHIPPED' => shipped,
    'OUT_FOR_DELIVERY' => outForDelivery,
    'DELIVERED' => delivered,
    'CANCELLED' => cancelled,
    'DELIVERY_EXCEPTION' => deliveryException,
    _ => unknown,
  };

  String get label => switch (this) {
    processing => 'Processing',
    packed => 'Packed',
    shipped => 'Shipped',
    outForDelivery => 'Out for Delivery',
    delivered => 'Delivered',
    cancelled => 'Cancelled',
    deliveryException => 'Delivery Exception',
    unknown => 'Tracking pending',
  };
}

enum TrackingStepStatus {
  completed,
  current,
  pending,
  unknown;

  static TrackingStepStatus parse(String? value) => switch (value) {
    'COMPLETED' => completed,
    'CURRENT' => current,
    'PENDING' => pending,
    _ => unknown,
  };
}

enum CodTrackingStatus {
  codPending,
  cashCollected,
  collectionMismatch,
  reconciled,
  failedCollection,
  waived,
  cancelled,
  unknown;

  static CodTrackingStatus parse(String? value) => switch (value) {
    'COD_PENDING' => codPending,
    'CASH_COLLECTED' => cashCollected,
    'COLLECTION_MISMATCH' => collectionMismatch,
    'RECONCILED' => reconciled,
    'FAILED_COLLECTION' => failedCollection,
    'WAIVED' => waived,
    'CANCELLED' => cancelled,
    null || '' => unknown,
    _ => unknown,
  };

  String get label => switch (this) {
    codPending => 'COD pending',
    cashCollected => 'Cash collected',
    collectionMismatch => 'Collection mismatch',
    reconciled => 'COD reconciled',
    failedCollection => 'Collection failed',
    waived => 'COD waived',
    cancelled => 'COD cancelled',
    unknown => 'Not COD',
  };
}

class OrderTracking {
  const OrderTracking({
    required this.orderNumber,
    required this.orderStatus,
    required this.fulfillmentStatus,
    required this.paymentStatus,
    required this.codStatus,
    this.deliveryMethodName,
    this.estimatedDeliveryDate,
    this.deliveryPartner,
    this.trackingNumber,
    this.deliveryContactPhone,
    this.deliveredAt,
    this.currentStep,
    required this.steps,
    required this.deliveryEvents,
  });

  final String orderNumber, orderStatus, paymentStatus;
  final FulfillmentStatus fulfillmentStatus;
  final CodTrackingStatus codStatus;
  final String? deliveryMethodName,
      deliveryPartner,
      trackingNumber,
      deliveryContactPhone,
      currentStep;
  final DateTime? estimatedDeliveryDate, deliveredAt;
  final List<TrackingStep> steps;
  final List<DeliveryTrackingEvent> deliveryEvents;

  factory OrderTracking.fromJson(Object? value) {
    final json = value as Map<String, Object?>;
    return OrderTracking(
      orderNumber: json['orderNumber'] as String,
      orderStatus: (json['orderStatus'] as String?) ?? '',
      fulfillmentStatus: FulfillmentStatus.parse(
        json['fulfillmentStatus'] as String?,
      ),
      paymentStatus: (json['paymentStatus'] as String?) ?? '',
      codStatus: CodTrackingStatus.parse(json['codStatus'] as String?),
      deliveryMethodName: json['deliveryMethodName'] as String?,
      estimatedDeliveryDate: _date(json['estimatedDeliveryDate']),
      deliveryPartner: json['deliveryPartner'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      deliveryContactPhone: json['deliveryContactPhone'] as String?,
      deliveredAt: _dateTime(json['deliveredAt']),
      currentStep: json['currentStep'] as String?,
      steps: ((json['steps'] as List?) ?? const [])
          .map(TrackingStep.fromJson)
          .toList(growable: false),
      deliveryEvents: ((json['deliveryEvents'] as List?) ?? const [])
          .map(DeliveryTrackingEvent.fromJson)
          .toList(growable: false),
    );
  }
}

class TrackingStep {
  const TrackingStep({
    required this.key,
    required this.title,
    required this.description,
    required this.status,
    this.timestamp,
  });
  final String key, title, description;
  final TrackingStepStatus status;
  final DateTime? timestamp;
  bool get completed => status == TrackingStepStatus.completed;
  bool get current => status == TrackingStepStatus.current;

  factory TrackingStep.fromJson(Object? value) {
    final json = value as Map<String, Object?>;
    return TrackingStep(
      key: (json['key'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      status: TrackingStepStatus.parse(json['status'] as String?),
      timestamp: _dateTime(json['timestamp']),
    );
  }
}

class DeliveryTrackingEvent {
  const DeliveryTrackingEvent({
    required this.eventType,
    required this.title,
    this.description,
    this.location,
    required this.customerVisible,
    this.occurredAt,
  });
  final String eventType, title;
  final String? description, location;
  final bool customerVisible;
  final DateTime? occurredAt;

  factory DeliveryTrackingEvent.fromJson(Object? value) {
    final json = value as Map<String, Object?>;
    return DeliveryTrackingEvent(
      eventType: (json['eventType'] as String?) ?? 'UNKNOWN',
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      customerVisible: json['customerVisible'] != false,
      occurredAt: _dateTime(json['occurredAt']),
    );
  }
}

DateTime? _dateTime(Object? value) =>
    value == null ? null : DateTime.tryParse(value as String)?.toLocal();

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse('${value}T00:00:00')?.toLocal();
