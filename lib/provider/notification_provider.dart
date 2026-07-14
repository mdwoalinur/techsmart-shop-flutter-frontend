import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/notification/notification_models.dart';
import '../service/api/api_exception.dart';
import '../service/notification/notification_service.dart';
import 'auth_provider.dart';

enum NotificationLoadState {
  idle,
  loading,
  loaded,
  refreshing,
  loadingMore,
  error,
}

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this.repository, this.auth) {
    _customer = auth.authenticated ? auth.profile!.customerId : null;
    auth.addListener(_authChanged);
    if (_customer != null) {
      unawaited(loadUnreadCount());
    }
  }
  final NotificationRepository repository;
  final AuthProvider auth;
  NotificationLoadState state = NotificationLoadState.idle;
  String? error;
  int unreadCount = 0;
  List<CustomerNotificationSummary> notifications = [];
  int page = 0;
  bool last = true;
  NotificationCategory? categoryFilter;
  NotificationReadStatus readFilter = NotificationReadStatus.all;
  CustomerNotificationDetail? selected;
  bool detailLoading = false;
  List<NotificationPreference> preferences = [];
  bool preferencesLoading = false, preferencesSaving = false;
  int? _customer;
  int _generation = 0;

  bool get signedIn => auth.authenticated;

  Future<void> loadUnreadCount() async {
    if (!auth.authenticated) {
      clear();
      return;
    }
    final g = _generation;
    try {
      final count = await repository.fetchUnreadCount();
      if (g != _generation) {
        return;
      }
      unreadCount = count.unreadCount;
      notifyListeners();
    } catch (_) {
      if (g == _generation) notifyListeners();
    }
  }

  Future<void> load({bool refresh = false}) async {
    if (!auth.authenticated) {
      clear();
      return;
    }
    if (state == NotificationLoadState.loading ||
        state == NotificationLoadState.refreshing) {
      return;
    }
    final g = _generation;
    state = notifications.isEmpty
        ? NotificationLoadState.loading
        : NotificationLoadState.refreshing;
    error = null;
    notifyListeners();
    try {
      final p = await repository.fetchNotifications(
        page: 0,
        size: 20,
        category: categoryFilter,
        readStatus: readFilter,
      );
      if (g != _generation) {
        return;
      }
      notifications = p.content;
      page = p.page;
      last = p.last;
      state = NotificationLoadState.loaded;
      await loadUnreadCount();
    } catch (e) {
      if (g != _generation) {
        return;
      }
      error = _safeMessage(e);
      state = notifications.isEmpty
          ? NotificationLoadState.error
          : NotificationLoadState.loaded;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!auth.authenticated ||
        last ||
        state == NotificationLoadState.loadingMore) {
      return;
    }
    final g = _generation;
    state = NotificationLoadState.loadingMore;
    notifyListeners();
    try {
      final p = await repository.fetchNotifications(
        page: page + 1,
        size: 20,
        category: categoryFilter,
        readStatus: readFilter,
      );
      if (g != _generation) {
        return;
      }
      notifications = [...notifications, ...p.content];
      page = p.page;
      last = p.last;
      state = NotificationLoadState.loaded;
    } catch (e) {
      if (g != _generation) {
        return;
      }
      error = _safeMessage(e);
      state = NotificationLoadState.loaded;
    }
    notifyListeners();
  }

  Future<void> setFilters({
    NotificationCategory? category,
    NotificationReadStatus? readStatus,
  }) async {
    categoryFilter = category;
    readFilter = readStatus ?? readFilter;
    await load(refresh: true);
  }

  Future<CustomerNotificationDetail?> loadDetail(
    String notificationNumber, {
    bool markRead = true,
  }) async {
    if (!auth.authenticated) return null;
    final g = _generation;
    detailLoading = true;
    selected = null;
    error = null;
    notifyListeners();
    try {
      final detail = markRead
          ? await repository.markAsRead(notificationNumber)
          : await repository.fetchNotificationDetail(notificationNumber);
      if (g != _generation) return null;
      selected = detail;
      _markLocalRead(notificationNumber);
      await loadUnreadCount();
      return detail;
    } catch (e) {
      if (g != _generation) return null;
      error = _safeMessage(e);
      return null;
    } finally {
      if (g == _generation) {
        detailLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> markRead(String notificationNumber) async {
    if (!auth.authenticated) return;
    final g = _generation;
    try {
      await repository.markAsRead(notificationNumber);
      if (g != _generation) {
        return;
      }
      _markLocalRead(notificationNumber);
      unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
    } catch (e) {
      if (g == _generation) error = _safeMessage(e);
    }
    notifyListeners();
  }

  Future<void> markAllRead() async {
    if (!auth.authenticated) return;
    final g = _generation;
    try {
      final c = await repository.markAllAsRead();
      if (g != _generation) {
        return;
      }
      notifications = notifications
          .map((e) => e.copyWith(read: true))
          .toList(growable: false);
      unreadCount = c.unreadCount;
    } catch (e) {
      if (g == _generation) error = _safeMessage(e);
    }
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    if (!auth.authenticated) return;
    final g = _generation;
    preferencesLoading = true;
    error = null;
    notifyListeners();
    try {
      final p = await repository.fetchPreferences();
      if (g != _generation) {
        return;
      }
      preferences = p;
    } catch (e) {
      if (g == _generation) error = _safeMessage(e);
    }
    if (g == _generation) {
      preferencesLoading = false;
      notifyListeners();
    }
  }

  void updatePreferenceDraft(
    NotificationCategory category, {
    bool? inAppEnabled,
    bool? emailEnabled,
  }) {
    preferences = preferences
        .map(
          (p) => p.category == category
              ? p.copyWith(
                  inAppEnabled: p.critical ? true : inAppEnabled,
                  emailEnabled: emailEnabled,
                )
              : p,
        )
        .toList(growable: false);
    notifyListeners();
  }

  Future<bool> savePreferences() async {
    if (!auth.authenticated || preferencesSaving) return false;
    final g = _generation;
    preferencesSaving = true;
    error = null;
    notifyListeners();
    try {
      final saved = await repository.updatePreferences(preferences);
      if (g != _generation) return false;
      preferences = saved;
      return true;
    } catch (e) {
      if (g == _generation) error = _safeMessage(e);
      return false;
    } finally {
      if (g == _generation) {
        preferencesSaving = false;
        notifyListeners();
      }
    }
  }

  void _markLocalRead(String notificationNumber) {
    notifications = notifications
        .map(
          (e) => e.notificationNumber == notificationNumber
              ? e.copyWith(read: true)
              : e,
        )
        .toList(growable: false);
    final d = selected;
    if (d != null && d.notificationNumber == notificationNumber && !d.read) {
      selected = CustomerNotificationDetail(
        notificationNumber: d.notificationNumber,
        type: d.type,
        category: d.category,
        title: d.title,
        message: d.message,
        severity: d.severity,
        read: true,
        createdAt: d.createdAt,
        readAt: DateTime.now(),
        relatedEntityType: d.relatedEntityType,
        relatedEntityReference: d.relatedEntityReference,
        actionType: d.actionType,
        actionReference: d.actionReference,
      );
    }
  }

  String _safeMessage(Object e) {
    final msg = userSafeApiMessage(e);
    if (msg.contains('ApiException')) {
      return 'Something went wrong. Please try again.';
    }
    if (e is ApiException && e.statusCode == 401) {
      return 'Please sign in to view notifications.';
    }
    if (e is ApiException && e.statusCode == 403) {
      return 'You do not have permission to view this notification.';
    }
    return msg;
  }

  void clear() {
    ++_generation;
    unreadCount = 0;
    notifications = [];
    page = 0;
    last = true;
    selected = null;
    preferences = [];
    error = null;
    state = NotificationLoadState.idle;
    notifyListeners();
  }

  void _authChanged() {
    final n = auth.authenticated ? auth.profile!.customerId : null;
    if (n == _customer) return;
    _customer = n;
    clear();
    if (n != null) unawaited(loadUnreadCount());
  }

  @override
  void dispose() {
    auth.removeListener(_authChanged);
    super.dispose();
  }
}
