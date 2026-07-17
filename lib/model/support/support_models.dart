import '../common/api_models.dart';
import '../review/review_models.dart';

class SupportTicketSummary {
  const SupportTicketSummary({
    required this.ticketNumber,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    this.relatedOrderNumber,
    this.createdAt,
    this.updatedAt,
  });

  final String ticketNumber, subject, category, priority, status;
  final String? relatedOrderNumber;
  final DateTime? createdAt, updatedAt;

  factory SupportTicketSummary.fromJson(Object? value) {
    final j = unwrapDataMap(value, 'ticket');
    return SupportTicketSummary(
      ticketNumber: requireString(j, 'ticketNumber'),
      subject: requireString(j, 'subject'),
      category: requireString(j, 'category'),
      priority: requireString(j, 'priority'),
      status: requireString(j, 'status'),
      relatedOrderNumber: j['relatedOrderNumber'] as String?,
      createdAt: parseOptionalDate(j['createdAt']),
      updatedAt: parseOptionalDate(j['updatedAt']),
    );
  }
}

class SupportTicketDetail extends SupportTicketSummary {
  const SupportTicketDetail({
    required super.ticketNumber,
    required super.subject,
    required super.category,
    required super.priority,
    required super.status,
    super.relatedOrderNumber,
    super.createdAt,
    super.updatedAt,
    required this.messages,
  });

  final List<SupportTicketMessage> messages;

  factory SupportTicketDetail.fromJson(Object? value) {
    final j = unwrapDataMap(value, 'ticketDetail');
    final summary = SupportTicketSummary.fromJson(j);
    final raw = j['messages'];
    return SupportTicketDetail(
      ticketNumber: summary.ticketNumber,
      subject: summary.subject,
      category: summary.category,
      priority: summary.priority,
      status: summary.status,
      relatedOrderNumber: summary.relatedOrderNumber,
      createdAt: summary.createdAt,
      updatedAt: summary.updatedAt,
      messages: raw is List<Object?>
          ? List.unmodifiable(raw.map(SupportTicketMessage.fromJson))
          : const [],
    );
  }
}

class SupportTicketMessage {
  const SupportTicketMessage({
    required this.senderType,
    required this.message,
    this.createdAt,
  });
  final String senderType, message;
  final DateTime? createdAt;

  factory SupportTicketMessage.fromJson(Object? value) {
    final j = requireMap(value, 'ticketMessage');
    return SupportTicketMessage(
      senderType: requireString(j, 'senderType'),
      message: requireString(j, 'message'),
      createdAt: parseOptionalDate(j['createdAt']),
    );
  }
}
