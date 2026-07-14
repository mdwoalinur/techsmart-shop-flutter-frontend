import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tech_smart_shop/model/notification/notification_models.dart';
import 'package:tech_smart_shop/provider/auth_provider.dart';
import 'package:tech_smart_shop/provider/notification_provider.dart';
import 'package:tech_smart_shop/service/notification/notification_service.dart';
import 'package:tech_smart_shop/ui/widget/notification/notification_bell.dart';
import 'support/fake_auth.dart';

void main() {
  test(
    'notification models parse page detail preferences and unknown enums',
    () {
      final page = NotificationPage.fromJson({
        'content': [
          {
            'notificationNumber': 'NTF-1',
            'type': 'NEW_FUTURE_TYPE',
            'category': 'NEW_CATEGORY',
            'title': 'Hello',
            'shortMessage': 'Short',
            'severity': 'LOUD',
            'read': false,
            'createdAt': '2026-01-01T00:00:00Z',
            'actionType': 'OPEN_ORDER',
          },
        ],
        'page': 0,
        'size': 20,
        'totalElements': 1,
        'totalPages': 1,
        'first': true,
        'last': true,
      });
      expect(page.content.single.category, NotificationCategory.unknown);
      expect(page.content.single.severity, NotificationSeverity.unknown);
      expect(page.content.single.actionType, NotificationActionType.openOrder);
      final detail = CustomerNotificationDetail.fromJson({
        'notificationNumber': 'NTF-1',
        'type': 'ORDER_CREATED',
        'category': 'ORDER',
        'title': 'Order',
        'message': 'Message',
        'severity': 'INFO',
        'read': true,
        'createdAt': '2026-01-01T00:00:00Z',
        'actionType': 'NONE',
      });
      expect(detail.read, isTrue);
      expect(
        NotificationUnreadCount.fromJson({'unreadCount': 3}).unreadCount,
        3,
      );
      expect(
        NotificationPreference.fromJson({
          'category': 'PAYMENT',
          'inAppEnabled': true,
          'emailEnabled': false,
          'critical': false,
        }).category,
        NotificationCategory.payment,
      );
    },
  );

  test(
    'provider loads unread/list, prevents duplicate load more, marks all read, and clears on logout',
    () async {
      final auth = AuthProvider(
        FakeAuthRepository(),
        MemorySessionStorage(),
        autoInitialize: false,
      );
      await auth.initialize();
      await auth.login('a@example.com', 'Pass');
      final repo = _NotificationRepo();
      final provider = NotificationProvider(repo, auth);
      await provider.loadUnreadCount();
      expect(provider.unreadCount, 2);
      await provider.load();
      expect(provider.notifications, hasLength(1));
      await provider.loadMore();
      await provider.loadMore();
      expect(repo.pageCalls, 2);
      await provider.markAllRead();
      expect(provider.unreadCount, 0);
      expect(provider.notifications.every((n) => n.read), isTrue);
      await auth.logout();
      expect(provider.notifications, isEmpty);
      expect(provider.unreadCount, 0);
      provider.dispose();
    },
  );

  testWidgets('bell shows capped unread badge and guest prompt is safe', (
    tester,
  ) async {
    final auth = AuthProvider(
      FakeAuthRepository(),
      MemorySessionStorage(),
      autoInitialize: false,
    );
    await auth.initialize();
    final repo = _NotificationRepo()..count = 120;
    final provider = NotificationProvider(repo, auth);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: provider),
        ],
        child: const MaterialApp(home: Scaffold(body: NotificationBell())),
      ),
    );
    await tester.tap(find.byKey(const Key('notificationBell')));
    await tester.pumpAndSettle();
    expect(find.text('Please sign in to view notifications.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.login('a@example.com', 'Pass');
    await provider.loadUnreadCount();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: provider),
        ],
        child: const MaterialApp(home: Scaffold(body: NotificationBell())),
      ),
    );
    await tester.pump();
    expect(find.text('99+'), findsOneWidget);
    provider.dispose();
  });
}

class _NotificationRepo implements NotificationRepository {
  int count = 2;
  int pageCalls = 0;
  @override
  Future<NotificationUnreadCount> fetchUnreadCount() async =>
      NotificationUnreadCount(count);
  @override
  Future<NotificationPage> fetchNotifications({
    int page = 0,
    int size = 20,
    NotificationCategory? category,
    NotificationReadStatus readStatus = NotificationReadStatus.all,
  }) async {
    pageCalls++;
    return NotificationPage(
      content: page == 0 ? [_summary(false)] : [_summary(true)],
      page: page,
      size: size,
      totalElements: 2,
      totalPages: 2,
      first: page == 0,
      last: page > 0,
    );
  }

  @override
  Future<CustomerNotificationDetail> fetchNotificationDetail(
    String notificationNumber,
  ) async => _detail(false);
  @override
  Future<CustomerNotificationDetail> markAsRead(
    String notificationNumber,
  ) async => _detail(true);
  @override
  Future<NotificationUnreadCount> markAllAsRead() async {
    count = 0;
    return const NotificationUnreadCount(0);
  }

  @override
  Future<List<NotificationPreference>> fetchPreferences() async => const [
    NotificationPreference(
      category: NotificationCategory.order,
      inAppEnabled: true,
      emailEnabled: true,
      critical: false,
    ),
  ];
  @override
  Future<List<NotificationPreference>> updatePreferences(
    List<NotificationPreference> preferences,
  ) async => preferences;
  CustomerNotificationSummary _summary(bool read) =>
      CustomerNotificationSummary(
        notificationNumber: read ? 'NTF-2' : 'NTF-1',
        type: 'ORDER_CREATED',
        category: NotificationCategory.order,
        title: 'Order',
        shortMessage: 'Short',
        severity: NotificationSeverity.info,
        read: read,
        createdAt: DateTime.utc(2026),
        actionType: NotificationActionType.openOrder,
      );
  CustomerNotificationDetail _detail(bool read) => CustomerNotificationDetail(
    notificationNumber: 'NTF-1',
    type: 'ORDER_CREATED',
    category: NotificationCategory.order,
    title: 'Order',
    message: 'Message',
    severity: NotificationSeverity.info,
    read: read,
    createdAt: DateTime.utc(2026),
    actionType: NotificationActionType.openOrder,
    actionReference: 'TSS-1',
  );
}
