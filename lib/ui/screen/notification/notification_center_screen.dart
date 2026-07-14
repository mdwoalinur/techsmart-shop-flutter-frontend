import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/notification/notification_models.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/notification_provider.dart';
import '../../widget/notification/notification_bell.dart';
import 'notification_detail_screen.dart';
import 'notification_preferences_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});
  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<NotificationProvider>();
      if (p.signedIn) {
        p.load(refresh: true);
      }
    });
    _scroll.addListener(() {
      final p = context.read<NotificationProvider>();
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 160) {
        p.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            key: const Key('notificationPreferencesButton'),
            tooltip: 'Preferences',
            onPressed: auth.authenticated
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationPreferencesScreen(),
                    ),
                  )
                : null,
            icon: const Icon(Icons.tune),
          ),
          TextButton(
            onPressed: auth.authenticated && p.unreadCount > 0
                ? () => p.markAllRead()
                : null,
            child: const Text('Read all'),
          ),
        ],
      ),
      body: auth.authenticated ? _body(p) : const NotificationLoginPrompt(),
    );
  }

  Widget _body(NotificationProvider p) => RefreshIndicator(
    onRefresh: () => p.load(refresh: true),
    child: ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _filters(p),
        const SizedBox(height: 8),
        if (p.error != null)
          _Error(message: p.error!, onRetry: () => p.load(refresh: true)),
        if (p.state == NotificationLoadState.loading && p.notifications.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (p.notifications.isEmpty &&
            p.state != NotificationLoadState.loading &&
            p.error == null)
          const _Empty(),
        ...p.notifications.map(
          (n) => _NotificationTile(
            notification: n,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationDetailScreen(
                  notificationNumber: n.notificationNumber,
                ),
              ),
            ),
          ),
        ),
        if (p.state == NotificationLoadState.loadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    ),
  );
  Widget _filters(NotificationProvider p) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      FilterChip(
        label: const Text('All'),
        selected: p.categoryFilter == null,
        onSelected: (_) => p.setFilters(category: null),
      ),
      for (final c in [
        NotificationCategory.order,
        NotificationCategory.payment,
        NotificationCategory.returnRequest,
        NotificationCategory.cancellation,
        NotificationCategory.account,
      ])
        FilterChip(
          label: Text(notificationCategoryLabel(c)),
          selected: p.categoryFilter == c,
          onSelected: (_) => p.setFilters(category: c),
        ),
      ChoiceChip(
        label: const Text('Unread'),
        selected: p.readFilter == NotificationReadStatus.unread,
        onSelected: (v) => p.setFilters(
          readStatus: v
              ? NotificationReadStatus.unread
              : NotificationReadStatus.all,
        ),
      ),
      ChoiceChip(
        label: const Text('Read'),
        selected: p.readFilter == NotificationReadStatus.read,
        onSelected: (v) => p.setFilters(
          readStatus: v
              ? NotificationReadStatus.read
              : NotificationReadStatus.all,
        ),
      ),
    ],
  );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});
  final CustomerNotificationSummary notification;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = switch (notification.severity) {
      NotificationSeverity.success => Colors.green,
      NotificationSeverity.warning => Colors.orange,
      NotificationSeverity.error => Colors.red,
      _ => Theme.of(context).colorScheme.primary,
    };
    return Card(
      color: notification.read
          ? null
          : Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: .35),
      child: ListTile(
        key: Key('notification-${notification.notificationNumber}'),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .14),
          child: Icon(
            notification.read
                ? Icons.notifications_none
                : Icons.notifications_active,
            color: color,
          ),
        ),
        title: Text(
          notification.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${notification.shortMessage}\n${notificationCategoryLabel(notification.category)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: notification.read
            ? null
            : const Icon(Icons.circle, size: 10, color: Colors.red),
        onTap: onTap,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(32),
    child: Center(child: Text('No notifications yet.')),
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.error_outline),
      title: Text(message),
      trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
    ),
  );
}
