import '../product/catalog_models.dart';

String _s(Map<String, Object?> j, String k, [String d = '']) =>
    (j[k] as String?) ?? d;
bool _b(Map<String, Object?> j, String k) => j[k] == true;
DateTime? _dt(Object? v) => v == null ? null : DateTime.parse(v as String);

class PaymentMethodOption {
  const PaymentMethodOption({
    required this.code,
    required this.displayName,
    required this.type,
    required this.active,
    required this.eligible,
    required this.currency,
    required this.requiresReference,
    required this.requiresProof,
    required this.autoVerify,
    required this.reviewRequired,
    this.description,
    this.ineligibilityReason,
    this.minAmount,
    this.maxAmount,
    this.instructions,
  });
  final String code, displayName, type, currency;
  final String? description, ineligibilityReason, instructions;
  final DecimalValue? minAmount, maxAmount;
  final bool active,
      eligible,
      requiresReference,
      requiresProof,
      autoVerify,
      reviewRequired;
  bool get isOnline => type == 'ONLINE_GATEWAY';
  bool get isWallet => type == 'MOBILE_WALLET';
  bool get isManual =>
      type == 'BANK_TRANSFER' || type == 'MOBILE_FINANCIAL_SERVICE';
  bool get isCod => type == 'CASH_ON_DELIVERY';
  factory PaymentMethodOption.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return PaymentMethodOption(
      code: _s(j, 'code'),
      displayName: _s(j, 'displayName'),
      description: j['description'] as String?,
      type: _s(j, 'type'),
      active: _b(j, 'active'),
      eligible: _b(j, 'eligible'),
      ineligibilityReason: j['ineligibilityReason'] as String?,
      minAmount: j['minAmount'] == null
          ? null
          : DecimalValue.fromJson(j['minAmount'], 'minAmount'),
      maxAmount: j['maxAmount'] == null
          ? null
          : DecimalValue.fromJson(j['maxAmount'], 'maxAmount'),
      currency: _s(j, 'supportedCurrency', 'BDT'),
      requiresReference: _b(j, 'requiresReference'),
      requiresProof: _b(j, 'requiresProof'),
      instructions: j['customerInstructions'] as String?,
      autoVerify: _b(j, 'autoVerify'),
      reviewRequired: _b(j, 'reviewRequired'),
    );
  }
}

class PaymentInitiationResult {
  const PaymentInitiationResult({
    required this.paymentNumber,
    required this.orderNumber,
    required this.paymentStatus,
    required this.attemptStatus,
    required this.methodCode,
    required this.methodType,
    required this.amount,
    required this.currency,
    this.provider,
    this.gatewaySessionId,
    this.redirectUrl,
    this.expiresAt,
    this.message,
  });
  final String paymentNumber,
      orderNumber,
      paymentStatus,
      attemptStatus,
      methodCode,
      methodType,
      currency;
  final DecimalValue amount;
  final String? provider, gatewaySessionId, redirectUrl, message;
  final DateTime? expiresAt;
  factory PaymentInitiationResult.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return PaymentInitiationResult(
      paymentNumber: _s(j, 'paymentNumber'),
      orderNumber: _s(j, 'orderNumber'),
      paymentStatus: _s(j, 'paymentStatus'),
      attemptStatus: _s(j, 'attemptStatus'),
      methodCode: _s(j, 'methodCode'),
      methodType: _s(j, 'methodType'),
      amount: DecimalValue.fromJson(j['amount'], 'amount'),
      currency: _s(j, 'currency', 'BDT'),
      provider: j['provider'] as String?,
      gatewaySessionId: j['gatewaySessionId'] as String?,
      redirectUrl: j['redirectUrl'] as String?,
      expiresAt: _dt(j['expiresAt']),
      message: j['customerMessage'] as String?,
    );
  }
}

class ManualPaymentResult {
  const ManualPaymentResult({
    required this.paymentNumber,
    required this.orderNumber,
    required this.paymentStatus,
    required this.reviewStatus,
    required this.amount,
    required this.currency,
    this.reference,
    this.submittedAt,
    this.message,
  });
  final String paymentNumber,
      orderNumber,
      paymentStatus,
      reviewStatus,
      currency;
  final DecimalValue amount;
  final String? reference, message;
  final DateTime? submittedAt;
  factory ManualPaymentResult.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return ManualPaymentResult(
      paymentNumber: _s(j, 'paymentNumber'),
      orderNumber: _s(j, 'orderNumber'),
      paymentStatus: _s(j, 'paymentStatus'),
      reviewStatus: _s(j, 'reviewStatus'),
      amount: DecimalValue.fromJson(j['amount'], 'amount'),
      currency: _s(j, 'currency', 'BDT'),
      reference: j['transactionReference'] as String?,
      submittedAt: _dt(j['submittedAt']),
      message: j['customerMessage'] as String?,
    );
  }
}

class CodSelectionResult {
  const CodSelectionResult({
    required this.paymentNumber,
    required this.orderNumber,
    required this.paymentStatus,
    required this.orderStatus,
    required this.amount,
    required this.currency,
    this.message,
  });
  final String paymentNumber, orderNumber, paymentStatus, orderStatus, currency;
  final DecimalValue amount;
  final String? message;
  factory CodSelectionResult.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return CodSelectionResult(
      paymentNumber: _s(j, 'paymentNumber'),
      orderNumber: _s(j, 'orderNumber'),
      paymentStatus: _s(j, 'paymentStatus'),
      orderStatus: _s(j, 'orderStatus'),
      amount: DecimalValue.fromJson(j['amount'], 'amount'),
      currency: _s(j, 'currency', 'BDT'),
      message: j['customerMessage'] as String?,
    );
  }
}

class PaymentStatusResult {
  const PaymentStatusResult({
    this.paymentNumber,
    required this.orderNumber,
    required this.paymentStatus,
    required this.accountingStatus,
    this.methodCode,
    this.methodType,
    required this.amount,
    required this.currency,
    this.message,
    required this.retryAllowed,
    required this.cancellable,
    required this.attempts,
    required this.timeline,
  });
  final String? paymentNumber, methodCode, methodType, message;
  final String orderNumber, paymentStatus, accountingStatus, currency;
  final DecimalValue amount;
  final bool retryAllowed, cancellable;
  final List<PaymentAttemptSummary> attempts;
  final List<PaymentTimelineEntry> timeline;
  bool get paid => paymentStatus == 'PAID';
  bool get reviewRequired => paymentStatus == 'REVIEW_REQUIRED';
  bool get codPending => paymentStatus == 'COD_PENDING';
  factory PaymentStatusResult.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return PaymentStatusResult(
      paymentNumber: j['paymentNumber'] as String?,
      orderNumber: _s(j, 'orderNumber'),
      paymentStatus: _s(j, 'paymentStatus'),
      accountingStatus: _s(j, 'accountingStatus'),
      methodCode: j['methodCode'] as String?,
      methodType: j['methodType'] as String?,
      amount: DecimalValue.fromJson(j['amount'], 'amount'),
      currency: _s(j, 'currency', 'BDT'),
      message: j['customerMessage'] as String?,
      retryAllowed: _b(j, 'retryAllowed'),
      cancellable: _b(j, 'cancellable'),
      attempts: ((j['attempts'] as List?) ?? const [])
          .map(PaymentAttemptSummary.fromJson)
          .toList(),
      timeline: ((j['timeline'] as List?) ?? const [])
          .map(PaymentTimelineEntry.fromJson)
          .toList(),
    );
  }
}

class PaymentAttemptSummary {
  const PaymentAttemptSummary({
    required this.attemptNumber,
    required this.status,
    required this.method,
    this.provider,
    this.gatewaySessionId,
    this.externalReference,
    this.expiresAt,
    this.createdAt,
  });
  final int attemptNumber;
  final String status, method;
  final String? provider, gatewaySessionId, externalReference;
  final DateTime? expiresAt, createdAt;
  factory PaymentAttemptSummary.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return PaymentAttemptSummary(
      attemptNumber: (j['attemptNumber'] as num).toInt(),
      status: _s(j, 'status'),
      method: _s(j, 'method'),
      provider: j['provider'] as String?,
      gatewaySessionId: j['gatewaySessionId'] as String?,
      externalReference: j['externalReference'] as String?,
      expiresAt: _dt(j['expiresAt']),
      createdAt: _dt(j['createdAt']),
    );
  }
}

class PaymentTimelineEntry {
  const PaymentTimelineEntry({
    required this.status,
    required this.source,
    this.note,
    this.occurredAt,
    required this.actorType,
  });
  final String status, source, actorType;
  final String? note;
  final DateTime? occurredAt;
  factory PaymentTimelineEntry.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return PaymentTimelineEntry(
      status: _s(j, 'status'),
      source: _s(j, 'source'),
      note: j['note'] as String?,
      occurredAt: _dt(j['occurredAt']),
      actorType: _s(j, 'actorType'),
    );
  }
}

class MobileWalletProviderOption {
  const MobileWalletProviderOption({
    required this.code,
    required this.displayName,
    required this.eligible,
    required this.displayOrder,
    required this.requiresVerificationCode,
    required this.requiresPaymentPin,
    required this.currency,
    this.shortDescription,
    this.ineligibilityReason,
    this.iconAssetKey,
    this.visualThemeKey,
    this.phoneLabel,
    this.phoneHint,
    this.instructions,
    this.minAmount,
    this.maxAmount,
  });

  final String code, displayName, currency;
  final String? shortDescription,
      ineligibilityReason,
      iconAssetKey,
      visualThemeKey,
      phoneLabel,
      phoneHint,
      instructions;
  final int displayOrder;
  final bool eligible, requiresVerificationCode, requiresPaymentPin;
  final DecimalValue? minAmount, maxAmount;

  factory MobileWalletProviderOption.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return MobileWalletProviderOption(
      code: _s(j, 'code'),
      displayName: _s(j, 'displayName'),
      shortDescription: j['shortDescription'] as String?,
      eligible: _b(j, 'eligible'),
      ineligibilityReason: j['ineligibilityReason'] as String?,
      displayOrder: ((j['displayOrder'] as num?) ?? 0).toInt(),
      iconAssetKey: j['iconAssetKey'] as String?,
      visualThemeKey: j['visualThemeKey'] as String?,
      phoneLabel: j['phoneLabel'] as String?,
      phoneHint: j['phoneHint'] as String?,
      requiresVerificationCode: _b(j, 'requiresVerificationCode'),
      requiresPaymentPin: _b(j, 'requiresPaymentPin'),
      instructions: j['instructions'] as String?,
      minAmount: j['minAmount'] == null
          ? null
          : DecimalValue.fromJson(j['minAmount'], 'minAmount'),
      maxAmount: j['maxAmount'] == null
          ? null
          : DecimalValue.fromJson(j['maxAmount'], 'maxAmount'),
      currency: _s(j, 'supportedCurrency', 'BDT'),
    );
  }
}

class MobileWalletSessionResult {
  const MobileWalletSessionResult({
    required this.paymentNumber,
    required this.attemptReference,
    required this.orderNumber,
    required this.providerCode,
    required this.providerDisplayName,
    required this.amount,
    required this.currency,
    required this.currentStep,
    required this.safeInstruction,
    this.expiresAt,
  });

  final String paymentNumber,
      attemptReference,
      orderNumber,
      providerCode,
      providerDisplayName,
      currency,
      currentStep,
      safeInstruction;
  final DecimalValue amount;
  final DateTime? expiresAt;

  factory MobileWalletSessionResult.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return MobileWalletSessionResult(
      paymentNumber: _s(j, 'paymentNumber'),
      attemptReference: _s(j, 'attemptReference'),
      orderNumber: _s(j, 'orderNumber'),
      providerCode: _s(j, 'providerCode'),
      providerDisplayName: _s(j, 'providerDisplayName'),
      amount: DecimalValue.fromJson(j['amount'], 'amount'),
      currency: _s(j, 'currency', 'BDT'),
      expiresAt: _dt(j['expiresAt']),
      currentStep: _s(j, 'currentStep'),
      safeInstruction: _s(j, 'safeInstruction'),
    );
  }
}
