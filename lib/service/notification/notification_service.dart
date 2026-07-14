import '../../model/notification/notification_models.dart';
import '../api/api_client.dart';

abstract class NotificationRepository {
  Future<NotificationPage> fetchNotifications({
    int page = 0,
    int size = 20,
    NotificationCategory? category,
    NotificationReadStatus readStatus = NotificationReadStatus.all,
  });
  Future<NotificationUnreadCount> fetchUnreadCount();
  Future<CustomerNotificationDetail> fetchNotificationDetail(
    String notificationNumber,
  );
  Future<CustomerNotificationDetail> markAsRead(String notificationNumber);
  Future<NotificationUnreadCount> markAllAsRead();
  Future<List<NotificationPreference>> fetchPreferences();
  Future<List<NotificationPreference>> updatePreferences(
    List<NotificationPreference> preferences,
  );
}

class NotificationService implements NotificationRepository {
  NotificationService(this.client);
  final ApiClient client;
  @override
  Future<NotificationPage> fetchNotifications({
    int page = 0,
    int size = 20,
    NotificationCategory? category,
    NotificationReadStatus readStatus = NotificationReadStatus.all,
  }) async => NotificationPage.fromJson(
    await client.get(
      'notifications',
      authenticated: true,
      queryParameters: {
        'page': '$page',
        'size': '$size',
        'category': category == null || category == NotificationCategory.unknown
            ? null
            : notificationCategoryCode(category),
        'readStatus': readStatus == NotificationReadStatus.all
            ? null
            : readStatus.name,
      },
    ),
  );
  @override
  Future<NotificationUnreadCount> fetchUnreadCount() async =>
      NotificationUnreadCount.fromJson(
        await client.get('notifications/unread-count', authenticated: true),
      );
  @override
  Future<CustomerNotificationDetail> fetchNotificationDetail(String n) async =>
      CustomerNotificationDetail.fromJson(
        await client.get('notifications/$n', authenticated: true),
      );
  @override
  Future<CustomerNotificationDetail> markAsRead(String n) async =>
      CustomerNotificationDetail.fromJson(
        await client.post('notifications/$n/read', authenticated: true),
      );
  @override
  Future<NotificationUnreadCount> markAllAsRead() async =>
      NotificationUnreadCount.fromJson(
        await client.post('notifications/read-all', authenticated: true),
      );
  @override
  Future<List<NotificationPreference>> fetchPreferences() async =>
      (await client.get('notifications/preferences', authenticated: true)
              as List)
          .map(NotificationPreference.fromJson)
          .toList();
  @override
  Future<List<NotificationPreference>> updatePreferences(
    List<NotificationPreference> preferences,
  ) async =>
      (await client.put(
                'notifications/preferences',
                authenticated: true,
                body: {
                  'preferences': preferences.map((e) => e.toJson()).toList(),
                },
              )
              as List)
          .map(NotificationPreference.fromJson)
          .toList();
}
