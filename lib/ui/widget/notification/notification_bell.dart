import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/notification_provider.dart';
import '../../screen/auth/login_screen.dart';
import '../../screen/notification/notification_center_screen.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, this.tooltip = 'Notifications'});
  final String tooltip;
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final count = context.watch<NotificationProvider>().unreadCount;
    return IconButton(
      key: const Key('notificationBell'),
      tooltip: tooltip,
      onPressed: () {
        if (!auth.authenticated) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
        );
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none),
          if (auth.authenticated && count > 0)
            Positioned(
              right: -10,
              top: -8,
              child: Container(
                key: const Key('notificationBadge'),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NotificationLoginPrompt extends StatelessWidget {
  const NotificationLoginPrompt({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_none, size: 56),
          const SizedBox(height: 12),
          const Text(
            'Please sign in to view notifications.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text('Sign in'),
          ),
        ],
      ),
    ),
  );
}
