import 'package:flutter/foundation.dart';

import '../model/support/support_models.dart';
import '../service/support/support_service.dart';
import 'auth_provider.dart';

enum SupportLoadState { idle, loading, loaded, error }

class SupportProvider extends ChangeNotifier {
  SupportProvider(this.repository, this.auth) {
    auth.addListener(_authChanged);
  }

  final SupportRepository repository;
  final AuthProvider auth;
  SupportLoadState state = SupportLoadState.idle;
  String? error;
  List<SupportTicketSummary> tickets = const [];
  SupportTicketDetail? selected;
  bool submitting = false;

  Future<void> load({bool force = false}) async {
    if (!auth.authenticated) return;
    if (!force && tickets.isNotEmpty && state == SupportLoadState.loaded) {
      return;
    }
    state = SupportLoadState.loading;
    error = null;
    notifyListeners();
    try {
      tickets = await repository.tickets();
      state = SupportLoadState.loaded;
    } catch (e) {
      error = e is SupportRequestException
          ? e.message
          : 'Unable to load support tickets.';
      state = SupportLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadDetail(String ticketNumber) async {
    if (!auth.authenticated) return;
    state = SupportLoadState.loading;
    error = null;
    notifyListeners();
    try {
      selected = await repository.ticket(ticketNumber);
      state = SupportLoadState.loaded;
    } catch (e) {
      error = e is SupportRequestException
          ? e.message
          : 'Unable to load ticket.';
      state = SupportLoadState.error;
    }
    notifyListeners();
  }

  Future<SupportTicketDetail?> create({
    required String subject,
    required String category,
    String? priority,
    String? relatedOrderNumber,
    required String message,
  }) async {
    if (!auth.authenticated || submitting) return null;
    submitting = true;
    error = null;
    notifyListeners();
    try {
      final detail = await repository.createTicket(
        subject: subject,
        category: category,
        priority: priority,
        relatedOrderNumber: relatedOrderNumber,
        message: message,
      );
      selected = detail;
      tickets = [
        detail,
        ...tickets.where((e) => e.ticketNumber != detail.ticketNumber),
      ];
      submitting = false;
      notifyListeners();
      return detail;
    } catch (e) {
      error = e is SupportRequestException
          ? e.message
          : 'Unable to create ticket.';
      submitting = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> reply(String ticketNumber, String message) async {
    if (!auth.authenticated || submitting) return false;
    submitting = true;
    error = null;
    notifyListeners();
    try {
      selected = await repository.addMessage(ticketNumber, message);
      tickets = [
        selected!,
        ...tickets.where((e) => e.ticketNumber != ticketNumber),
      ];
      submitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e is SupportRequestException
          ? e.message
          : 'Unable to send reply.';
      submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> close(String ticketNumber) async {
    if (!auth.authenticated || submitting) return false;
    submitting = true;
    error = null;
    notifyListeners();
    try {
      selected = await repository.close(ticketNumber);
      tickets = [
        selected!,
        ...tickets.where((e) => e.ticketNumber != ticketNumber),
      ];
      submitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e is SupportRequestException
          ? e.message
          : 'Unable to close ticket.';
      submitting = false;
      notifyListeners();
      return false;
    }
  }

  void _authChanged() {
    if (!auth.authenticated) clear();
  }

  void clear() {
    state = SupportLoadState.idle;
    error = null;
    tickets = const [];
    selected = null;
    submitting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    auth.removeListener(_authChanged);
    super.dispose();
  }
}
