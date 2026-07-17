enum NotificationCategory {
  order,
  payment,
  returnRequest,
  cancellation,
  account,
  support,
  review,
  system,
  unknown,
}

enum NotificationSeverity { info, success, warning, error, unknown }

enum NotificationActionType {
  openOrder,
  openPayment,
  openReturnRequest,
  openCancellationRequest,
  openProfile,
  openSupportTicket,
  openReview,
  none,
  unknown,
}

enum NotificationReadStatus { all, unread, read }

String _text(Object? value) => value is String ? value : '';
DateTime _date(Object? value) =>
    DateTime.tryParse(_text(value)) ?? DateTime.fromMillisecondsSinceEpoch(0);

NotificationCategory notificationCategoryFrom(String? value) =>
    switch ((value ?? '').toUpperCase()) {
      'ORDER' => NotificationCategory.order,
      'PAYMENT' => NotificationCategory.payment,
      'RETURN' => NotificationCategory.returnRequest,
      'CANCELLATION' => NotificationCategory.cancellation,
      'ACCOUNT' => NotificationCategory.account,
      'SUPPORT' => NotificationCategory.support,
      'REVIEW' => NotificationCategory.review,
      'SYSTEM' => NotificationCategory.system,
      _ => NotificationCategory.unknown,
    };

String notificationCategoryCode(NotificationCategory value) => switch (value) {
  NotificationCategory.order => 'ORDER',
  NotificationCategory.payment => 'PAYMENT',
  NotificationCategory.returnRequest => 'RETURN',
  NotificationCategory.cancellation => 'CANCELLATION',
  NotificationCategory.account => 'Account',
  NotificationCategory.support => 'Support',
  NotificationCategory.review => 'Reviews',
  NotificationCategory.system => 'System',
  NotificationCategory.unknown => 'UNKNOWN',
};

String notificationCategoryLabel(NotificationCategory value) => switch (value) {
  NotificationCategory.order => 'Orders',
  NotificationCategory.payment => 'Payments',
  NotificationCategory.returnRequest => 'Returns',
  NotificationCategory.cancellation => 'Cancellations',
  NotificationCategory.account => 'Account',
  NotificationCategory.support => 'Support',
  NotificationCategory.review => 'Reviews',
  NotificationCategory.system => 'System',
  NotificationCategory.unknown => 'Other',
};

NotificationSeverity notificationSeverityFrom(String? value) =>
    switch ((value ?? '').toUpperCase()) {
      'INFO' => NotificationSeverity.info,
      'SUCCESS' => NotificationSeverity.success,
      'WARNING' => NotificationSeverity.warning,
      'ERROR' => NotificationSeverity.error,
      _ => NotificationSeverity.unknown,
    };

NotificationActionType notificationActionTypeFrom(String? value) =>
    switch ((value ?? '').toUpperCase()) {
      'OPEN_ORDER' => NotificationActionType.openOrder,
      'OPEN_PAYMENT' => NotificationActionType.openPayment,
      'OPEN_RETURN_REQUEST' => NotificationActionType.openReturnRequest,
      'OPEN_CANCELLATION_REQUEST' =>
        NotificationActionType.openCancellationRequest,
      'OPEN_PROFILE' => NotificationActionType.openProfile,
      'OPEN_SUPPORT_TICKET' => NotificationActionType.openSupportTicket,
      'OPEN_REVIEW' => NotificationActionType.openReview,
      'NONE' => NotificationActionType.none,
      _ => NotificationActionType.unknown,
    };

class NotificationPage {
  const NotificationPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });
  final List<CustomerNotificationSummary> content;
  final int page, size, totalElements, totalPages;
  final bool first, last;
  factory NotificationPage.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return NotificationPage(
      content: ((j['content'] as List?) ?? const [])
          .map(CustomerNotificationSummary.fromJson)
          .toList(),
      page: ((j['page'] as num?) ?? 0).toInt(),
      size: ((j['size'] as num?) ?? 0).toInt(),
      totalElements: ((j['totalElements'] as num?) ?? 0).toInt(),
      totalPages: ((j['totalPages'] as num?) ?? 0).toInt(),
      first: j['first'] == true,
      last: j['last'] == true,
    );
  }
}

class CustomerNotificationSummary {
  const CustomerNotificationSummary({
    required this.notificationNumber,
    required this.type,
    required this.category,
    required this.title,
    required this.shortMessage,
    required this.severity,
    required this.read,
    required this.createdAt,
    this.relatedEntityType,
    this.relatedEntityReference,
    required this.actionType,
  });
  final String notificationNumber, type, title, shortMessage;
  final NotificationCategory category;
  final NotificationSeverity severity;
  final bool read;
  final DateTime createdAt;
  final String? relatedEntityType, relatedEntityReference;
  final NotificationActionType actionType;
  factory CustomerNotificationSummary.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return CustomerNotificationSummary(
      notificationNumber: _text(j['notificationNumber']),
      type: _text(j['type']),
      category: notificationCategoryFrom(j['category'] as String?),
      title: _text(j['title']),
      shortMessage: _text(j['shortMessage']),
      severity: notificationSeverityFrom(j['severity'] as String?),
      read: j['read'] == true,
      createdAt: _date(j['createdAt']),
      relatedEntityType: j['relatedEntityType'] as String?,
      relatedEntityReference: j['relatedEntityReference'] as String?,
      actionType: notificationActionTypeFrom(j['actionType'] as String?),
    );
  }
  CustomerNotificationSummary copyWith({bool? read}) =>
      CustomerNotificationSummary(
        notificationNumber: notificationNumber,
        type: type,
        category: category,
        title: title,
        shortMessage: shortMessage,
        severity: severity,
        read: read ?? this.read,
        createdAt: createdAt,
        relatedEntityType: relatedEntityType,
        relatedEntityReference: relatedEntityReference,
        actionType: actionType,
      );
}

class CustomerNotificationDetail {
  const CustomerNotificationDetail({
    required this.notificationNumber,
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    required this.severity,
    required this.read,
    required this.createdAt,
    this.readAt,
    this.relatedEntityType,
    this.relatedEntityReference,
    required this.actionType,
    this.actionReference,
  });
  final String notificationNumber, type, title, message;
  final NotificationCategory category;
  final NotificationSeverity severity;
  final bool read;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? relatedEntityType, relatedEntityReference, actionReference;
  final NotificationActionType actionType;
  factory CustomerNotificationDetail.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return CustomerNotificationDetail(
      notificationNumber: _text(j['notificationNumber']),
      type: _text(j['type']),
      category: notificationCategoryFrom(j['category'] as String?),
      title: _text(j['title']),
      message: _text(j['message']),
      severity: notificationSeverityFrom(j['severity'] as String?),
      read: j['read'] == true,
      createdAt: _date(j['createdAt']),
      readAt: j['readAt'] == null ? null : _date(j['readAt']),
      relatedEntityType: j['relatedEntityType'] as String?,
      relatedEntityReference: j['relatedEntityReference'] as String?,
      actionType: notificationActionTypeFrom(j['actionType'] as String?),
      actionReference: j['actionReference'] as String?,
    );
  }
}

class NotificationUnreadCount {
  const NotificationUnreadCount(this.unreadCount);
  final int unreadCount;
  factory NotificationUnreadCount.fromJson(Object? v) =>
      NotificationUnreadCount(
        (((v as Map<String, Object?>)['unreadCount'] as num?) ?? 0).toInt(),
      );
}

class NotificationPreference {
  const NotificationPreference({
    required this.category,
    required this.inAppEnabled,
    required this.emailEnabled,
    required this.critical,
  });
  final NotificationCategory category;
  final bool inAppEnabled, emailEnabled, critical;
  factory NotificationPreference.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return NotificationPreference(
      category: notificationCategoryFrom(j['category'] as String?),
      inAppEnabled: j['inAppEnabled'] == true,
      emailEnabled: j['emailEnabled'] == true,
      critical: j['critical'] == true,
    );
  }
  Map<String, Object?> toJson() => {
    'category': notificationCategoryCode(category),
    'inAppEnabled': inAppEnabled,
    'emailEnabled': emailEnabled,
  };
  NotificationPreference copyWith({bool? inAppEnabled, bool? emailEnabled}) =>
      NotificationPreference(
        category: category,
        inAppEnabled: inAppEnabled ?? this.inAppEnabled,
        emailEnabled: emailEnabled ?? this.emailEnabled,
        critical: critical,
      );
}
