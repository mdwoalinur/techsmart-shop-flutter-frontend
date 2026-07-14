import '../product/catalog_models.dart';

class OrderPage {
  const OrderPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });
  final List<OrderSummary> content;
  final int page, size, totalPages;
  final int totalElements;
  final bool first, last;
  factory OrderPage.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return OrderPage(
      content: ((j['content'] as List?) ?? const [])
          .map(OrderSummary.fromJson)
          .toList(),
      page: (j['page'] as num).toInt(),
      size: (j['size'] as num).toInt(),
      totalElements: (j['totalElements'] as num).toInt(),
      totalPages: (j['totalPages'] as num).toInt(),
      first: j['first'] == true,
      last: j['last'] == true,
    );
  }
}

class OrderSummary {
  const OrderSummary({
    required this.orderNumber,
    required this.submittedAt,
    required this.orderStatus,
    required this.visibleStatus,
    required this.paymentStatus,
    required this.total,
    required this.currency,
    required this.totalQuantity,
    required this.itemCount,
    this.firstItemName,
    this.firstItemImageUrl,
    required this.additionalItemCount,
    this.deliveryMethodName,
    required this.cancellationEligible,
    required this.returnEligible,
  });
  final String orderNumber, orderStatus, visibleStatus, paymentStatus, currency;
  final DateTime submittedAt;
  final DecimalValue total;
  final int totalQuantity, itemCount, additionalItemCount;
  final String? firstItemName, firstItemImageUrl, deliveryMethodName;
  final bool cancellationEligible, returnEligible;
  factory OrderSummary.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return OrderSummary(
      orderNumber: j['orderNumber'] as String,
      submittedAt: DateTime.parse(j['submittedAt'] as String),
      orderStatus: j['orderStatus'] as String,
      visibleStatus:
          (j['customerVisibleStatusLabel'] as String?) ??
          j['orderStatus'] as String,
      paymentStatus: j['paymentStatus'] as String,
      total: DecimalValue.fromJson(j['grandTotal'], 'grandTotal'),
      currency: (j['currency'] as String?) ?? 'BDT',
      totalQuantity: (j['totalQuantity'] as num).toInt(),
      itemCount: (j['itemCount'] as num).toInt(),
      firstItemName: j['firstItemName'] as String?,
      firstItemImageUrl: j['firstItemImageUrl'] as String?,
      additionalItemCount: (j['additionalItemCount'] as num).toInt(),
      deliveryMethodName: j['deliveryMethodName'] as String?,
      cancellationEligible: j['cancellationEligible'] == true,
      returnEligible: j['returnEligible'] == true,
    );
  }
}

class OrderDetail {
  const OrderDetail({
    required this.orderNumber,
    required this.submittedAt,
    this.updatedAt,
    required this.orderStatus,
    required this.visibleStatus,
    required this.paymentStatus,
    required this.accountingStatus,
    required this.subtotal,
    required this.tax,
    required this.delivery,
    required this.discount,
    required this.total,
    required this.items,
    required this.deliverySnapshot,
    this.note,
    required this.timeline,
    required this.cancellationEligibility,
    required this.returnEligibility,
    required this.documentAvailable,
  });
  final String orderNumber,
      orderStatus,
      visibleStatus,
      paymentStatus,
      accountingStatus;
  final DateTime submittedAt;
  final DateTime? updatedAt;
  final DecimalValue subtotal, tax, delivery, discount, total;
  final List<OrderItemSnapshot> items;
  final DeliverySnapshot deliverySnapshot;
  final String? note;
  final List<OrderTimelineEntry> timeline;
  final CancellationEligibility cancellationEligibility;
  final ReturnEligibility returnEligibility;
  final bool documentAvailable;
  factory OrderDetail.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return OrderDetail(
      orderNumber: j['orderNumber'] as String,
      submittedAt: DateTime.parse(j['submittedAt'] as String),
      updatedAt: j['updatedAt'] == null
          ? null
          : DateTime.parse(j['updatedAt'] as String),
      orderStatus: j['orderStatus'] as String,
      visibleStatus:
          (j['customerVisibleStatusLabel'] as String?) ??
          j['orderStatus'] as String,
      paymentStatus: j['paymentStatus'] as String,
      accountingStatus: (j['accountingStatus'] as String?) ?? '',
      subtotal: DecimalValue.fromJson(j['subtotal'], 'subtotal'),
      tax: DecimalValue.fromJson(j['taxTotal'], 'taxTotal'),
      delivery: DecimalValue.fromJson(j['deliveryCharge'], 'deliveryCharge'),
      discount: DecimalValue.fromJson(j['discountTotal'], 'discountTotal'),
      total: DecimalValue.fromJson(j['grandTotal'], 'grandTotal'),
      items: ((j['items'] as List?) ?? const [])
          .map(OrderItemSnapshot.fromJson)
          .toList(),
      deliverySnapshot: DeliverySnapshot.fromJson(j['delivery']),
      note: j['customerNote'] as String?,
      timeline: ((j['timeline'] as List?) ?? const [])
          .map(OrderTimelineEntry.fromJson)
          .toList(),
      cancellationEligibility: CancellationEligibility.fromJson(
        j['cancellationEligibility'],
      ),
      returnEligibility: ReturnEligibility.fromJson(j['returnEligibility']),
      documentAvailable: j['documentAvailable'] == true,
    );
  }
}

class OrderItemSnapshot {
  const OrderItemSnapshot({
    required this.itemId,
    required this.productId,
    this.variationId,
    required this.productName,
    required this.productCode,
    this.variationName,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.lineSubtotal,
    required this.taxRate,
    required this.taxAmount,
  });
  final int itemId, productId, quantity;
  final int? variationId;
  final String productName, productCode;
  final String? variationName, imageUrl;
  final DecimalValue unitPrice, lineSubtotal, taxRate, taxAmount;
  factory OrderItemSnapshot.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return OrderItemSnapshot(
      itemId: (j['itemId'] as num).toInt(),
      productId: (j['productId'] as num).toInt(),
      variationId: (j['variationId'] as num?)?.toInt(),
      productName: j['productName'] as String,
      productCode: (j['productCode'] as String?) ?? '',
      variationName: j['variationName'] as String?,
      imageUrl: j['imageUrl'] as String?,
      unitPrice: DecimalValue.fromJson(j['unitPrice'], 'unitPrice'),
      quantity: (j['quantity'] as num).toInt(),
      lineSubtotal: DecimalValue.fromJson(j['lineSubtotal'], 'lineSubtotal'),
      taxRate: DecimalValue.fromJson(j['taxRate'], 'taxRate'),
      taxAmount: DecimalValue.fromJson(j['taxAmount'], 'taxAmount'),
    );
  }
}

class DeliverySnapshot {
  const DeliverySnapshot({
    required this.recipientName,
    required this.phone,
    required this.address,
    required this.deliveryMethodName,
  });
  final String recipientName, phone, address, deliveryMethodName;
  factory DeliverySnapshot.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return DeliverySnapshot(
      recipientName: (j['recipientName'] as String?) ?? '',
      phone: (j['phone'] as String?) ?? '',
      address: (j['address'] as String?) ?? '',
      deliveryMethodName: (j['deliveryMethodName'] as String?) ?? '',
    );
  }
}

class OrderTimelineEntry {
  const OrderTimelineEntry({
    required this.status,
    required this.title,
    required this.description,
    required this.occurredAt,
    required this.completed,
    required this.current,
    this.note,
  });
  final String status, title, description;
  final DateTime occurredAt;
  final bool completed, current;
  final String? note;
  factory OrderTimelineEntry.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return OrderTimelineEntry(
      status: j['status'] as String,
      title: (j['title'] as String?) ?? j['status'] as String,
      description: (j['description'] as String?) ?? '',
      occurredAt: DateTime.parse(j['occurredAt'] as String),
      completed: j['completed'] == true,
      current: j['current'] == true,
      note: j['note'] as String?,
    );
  }
}

class CancellationEligibility {
  const CancellationEligibility({
    required this.eligible,
    required this.reasonCode,
    required this.message,
    this.existingStatus,
  });
  final bool eligible;
  final String reasonCode, message;
  final String? existingStatus;
  factory CancellationEligibility.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return CancellationEligibility(
      eligible: j['eligible'] == true,
      reasonCode: (j['reasonCode'] as String?) ?? '',
      message: (j['message'] as String?) ?? '',
      existingStatus: j['existingRequestStatus'] as String?,
    );
  }
}

class CancellationRequest {
  const CancellationRequest({
    required this.orderNumber,
    required this.status,
    required this.reasonCode,
    this.reasonText,
    required this.requestedAt,
    required this.message,
  });
  final String orderNumber, status, reasonCode, message;
  final String? reasonText;
  final DateTime requestedAt;
  factory CancellationRequest.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return CancellationRequest(
      orderNumber: j['orderNumber'] as String,
      status: j['status'] as String,
      reasonCode: j['reasonCode'] as String,
      reasonText: j['reasonText'] as String?,
      requestedAt: DateTime.parse(j['requestedAt'] as String),
      message: j['message'] as String,
    );
  }
}

class ReturnEligibility {
  const ReturnEligibility({
    required this.eligible,
    required this.reasonCode,
    required this.message,
    required this.returnWindowDays,
    required this.items,
    this.existingStatus,
  });
  final bool eligible;
  final String reasonCode, message;
  final int returnWindowDays;
  final List<ReturnableOrderItem> items;
  final String? existingStatus;
  factory ReturnEligibility.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return ReturnEligibility(
      eligible: j['eligible'] == true,
      reasonCode: (j['reasonCode'] as String?) ?? '',
      message: (j['message'] as String?) ?? '',
      returnWindowDays: ((j['returnWindowDays'] as num?) ?? 0).toInt(),
      items: ((j['items'] as List?) ?? const [])
          .map(ReturnableOrderItem.fromJson)
          .toList(),
      existingStatus: j['existingRequestStatus'] as String?,
    );
  }
}

class ReturnableOrderItem {
  const ReturnableOrderItem({
    required this.itemId,
    required this.productName,
    this.variationName,
    required this.orderedQuantity,
    required this.remainingReturnableQuantity,
  });
  final int itemId, orderedQuantity, remainingReturnableQuantity;
  final String productName;
  final String? variationName;
  factory ReturnableOrderItem.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return ReturnableOrderItem(
      itemId: (j['itemId'] as num).toInt(),
      productName: j['productName'] as String,
      variationName: j['variationName'] as String?,
      orderedQuantity: (j['orderedQuantity'] as num).toInt(),
      remainingReturnableQuantity: (j['remainingReturnableQuantity'] as num)
          .toInt(),
    );
  }
}

class ReturnRequest {
  const ReturnRequest({
    required this.requestNumber,
    required this.orderNumber,
    required this.status,
    required this.preferredResolution,
    required this.requestedAt,
    required this.items,
    required this.message,
  });
  final String requestNumber, orderNumber, status, preferredResolution, message;
  final DateTime requestedAt;
  final List<ReturnRequestItem> items;
  factory ReturnRequest.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return ReturnRequest(
      requestNumber: j['requestNumber'] as String,
      orderNumber: j['orderNumber'] as String,
      status: j['status'] as String,
      preferredResolution: j['preferredResolution'] as String,
      requestedAt: DateTime.parse(j['requestedAt'] as String),
      items: ((j['items'] as List?) ?? const [])
          .map(ReturnRequestItem.fromJson)
          .toList(),
      message: j['message'] as String,
    );
  }
}

class ReturnRequestItem {
  const ReturnRequestItem({
    required this.orderItemId,
    required this.productName,
    required this.requestedQuantity,
    required this.reasonCode,
    this.reasonText,
  });
  final int orderItemId, requestedQuantity;
  final String productName, reasonCode;
  final String? reasonText;
  factory ReturnRequestItem.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return ReturnRequestItem(
      orderItemId: (j['orderItemId'] as num).toInt(),
      productName: j['productName'] as String,
      requestedQuantity: (j['requestedQuantity'] as num).toInt(),
      reasonCode: j['reasonCode'] as String,
      reasonText: j['reasonText'] as String?,
    );
  }
}

class OrderDocument {
  const OrderDocument({
    required this.orderNumber,
    required this.fileName,
    required this.contentType,
    required this.title,
    required this.html,
  });
  final String orderNumber, fileName, contentType, title, html;
  factory OrderDocument.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return OrderDocument(
      orderNumber: j['orderNumber'] as String,
      fileName: j['fileName'] as String,
      contentType: j['contentType'] as String,
      title: j['documentTitle'] as String,
      html: j['html'] as String,
    );
  }
}

class ReturnRequestItemDraft {
  const ReturnRequestItemDraft({
    required this.item,
    this.selected = false,
    this.quantity = 1,
    this.reasonCode = 'DAMAGED_OR_DEFECTIVE',
    this.reasonText,
  });
  final ReturnableOrderItem item;
  final bool selected;
  final int quantity;
  final String reasonCode;
  final String? reasonText;

  int get safeQuantity =>
      quantity.clamp(1, item.remainingReturnableQuantity).toInt();
  bool get needsExplanation => reasonCode == 'OTHER';
  String? get validationMessage {
    if (!selected) return null;
    if (quantity < 1) return 'Quantity must be at least 1.';
    if (quantity > item.remainingReturnableQuantity) {
      return 'Quantity cannot exceed ${item.remainingReturnableQuantity}.';
    }
    if (needsExplanation &&
        (reasonText == null || reasonText!.trim().isEmpty)) {
      return 'Please explain the OTHER reason.';
    }
    return null;
  }

  ReturnRequestItemDraft copyWith({
    bool? selected,
    int? quantity,
    String? reasonCode,
    Object? reasonText = _sentinel,
  }) => ReturnRequestItemDraft(
    item: item,
    selected: selected ?? this.selected,
    quantity: quantity ?? this.quantity,
    reasonCode: reasonCode ?? this.reasonCode,
    reasonText: identical(reasonText, _sentinel)
        ? this.reasonText
        : reasonText as String?,
  );

  Map<String, Object?> toJson() => {
    'orderItemId': item.itemId,
    'quantity': quantity,
    'reasonCode': reasonCode,
    'reasonText': reasonText,
  };
}

class ReturnRequestDraft {
  const ReturnRequestDraft({
    required this.orderNumber,
    required this.items,
    this.preferredResolution = 'REFUND_REQUESTED',
    this.comment,
    this.idempotencyKey,
  });
  final String orderNumber;
  final List<ReturnRequestItemDraft> items;
  final String preferredResolution;
  final String? comment;
  final String? idempotencyKey;

  List<ReturnRequestItemDraft> get selectedItems =>
      items.where((e) => e.selected).toList(growable: false);
  String? get validationMessage {
    if (selectedItems.isEmpty) return 'Select at least one item to return.';
    for (final item in selectedItems) {
      final message = item.validationMessage;
      if (message != null) return message;
    }
    return null;
  }

  ReturnRequestDraft copyWith({
    List<ReturnRequestItemDraft>? items,
    String? preferredResolution,
    Object? comment = _sentinel,
    Object? idempotencyKey = _sentinel,
  }) => ReturnRequestDraft(
    orderNumber: orderNumber,
    items: items ?? this.items,
    preferredResolution: preferredResolution ?? this.preferredResolution,
    comment: identical(comment, _sentinel) ? this.comment : comment as String?,
    idempotencyKey: identical(idempotencyKey, _sentinel)
        ? this.idempotencyKey
        : idempotencyKey as String?,
  );

  List<Map<String, Object?>> selectedJsonItems() =>
      selectedItems.map((e) => e.toJson()).toList(growable: false);
}

const Object _sentinel = Object();
