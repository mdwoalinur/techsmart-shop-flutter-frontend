import '../../model/review/review_models.dart';
import '../../model/support/support_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';

abstract interface class SupportRepository {
  Future<List<SupportTicketSummary>> tickets();
  Future<SupportTicketDetail> createTicket({
    required String subject,
    required String category,
    String? priority,
    String? relatedOrderNumber,
    required String message,
  });
  Future<SupportTicketDetail> ticket(String ticketNumber);
  Future<SupportTicketDetail> addMessage(String ticketNumber, String message);
  Future<SupportTicketDetail> close(String ticketNumber);
}

class SupportService implements SupportRepository {
  const SupportService(this._client);
  final ApiClient _client;

  @override
  Future<List<SupportTicketSummary>> tickets() async {
    final raw = unwrapData(
      await _safe(() => _client.get('support/tickets', authenticated: true)),
    );
    if (raw is! List<Object?>) {
      throw const FormatException('tickets must be an array.');
    }
    return List.unmodifiable(raw.map(SupportTicketSummary.fromJson));
  }

  @override
  Future<SupportTicketDetail> createTicket({
    required String subject,
    required String category,
    String? priority,
    String? relatedOrderNumber,
    required String message,
  }) async => SupportTicketDetail.fromJson(
    await _safe(
      () => _client.post(
        'support/tickets',
        authenticated: true,
        body: {
          'subject': subject,
          'category': category,
          if (priority?.isNotEmpty == true) 'priority': priority,
          if (relatedOrderNumber?.trim().isNotEmpty == true)
            'relatedOrderNumber': relatedOrderNumber!.trim(),
          'message': message,
        },
      ),
    ),
  );

  @override
  Future<SupportTicketDetail> ticket(String ticketNumber) async =>
      SupportTicketDetail.fromJson(
        await _safe(
          () =>
              _client.get('support/tickets/$ticketNumber', authenticated: true),
        ),
      );

  @override
  Future<SupportTicketDetail> addMessage(
    String ticketNumber,
    String message,
  ) async => SupportTicketDetail.fromJson(
    await _safe(
      () => _client.post(
        'support/tickets/$ticketNumber/messages',
        authenticated: true,
        body: {'message': message},
      ),
    ),
  );

  @override
  Future<SupportTicketDetail> close(String ticketNumber) async =>
      SupportTicketDetail.fromJson(
        await _safe(
          () => _client.post(
            'support/tickets/$ticketNumber/close',
            authenticated: true,
          ),
        ),
      );

  Future<Object?> _safe(Future<Object?> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      throw SupportRequestException(
        userSafeApiMessage(e),
        statusCode: e.statusCode,
        cause: e,
      );
    } on FormatException catch (e) {
      throw SupportRequestException(
        'The server returned unexpected support data.',
        cause: e,
      );
    }
  }
}

class SupportRequestException implements Exception {
  const SupportRequestException(this.message, {this.statusCode, this.cause});
  final String message;
  final int? statusCode;
  final Object? cause;
}
