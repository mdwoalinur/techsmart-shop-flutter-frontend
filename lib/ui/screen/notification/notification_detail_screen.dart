import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/notification/notification_models.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/notification_provider.dart';
import '../order/order_detail_screen.dart';
import '../payment/payment_screen.dart';
import '../profile/profile_screen.dart';
import '../../widget/notification/notification_bell.dart';

class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({super.key, required this.notificationNumber});
  final String notificationNumber;
  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<NotificationProvider>();
      if (p.signedIn) {
        p.loadDetail(widget.notificationNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = context.watch<NotificationProvider>();
    final d = p.selected;
    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: !auth.authenticated
          ? const NotificationLoginPrompt()
          : p.detailLoading
          ? const Center(child: CircularProgressIndicator())
          : d == null
          ? Center(child: Text(p.error ?? 'Notification not found.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Icon(
                  _icon(d.severity),
                  size: 48,
                  color: _color(context, d.severity),
                ),
                const SizedBox(height: 12),
                Text(d.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(notificationCategoryLabel(d.category)),
                const SizedBox(height: 16),
                Text(d.message),
                const SizedBox(height: 16),
                Text('Created: ${d.createdAt.toLocal()}'),
                if (d.readAt != null) Text('Read: ${d.readAt!.toLocal()}'),
                const SizedBox(height: 24),
                if (_label(d) != null)
                  FilledButton(
                    key: const Key('notificationActionButton'),
                    onPressed: () => _open(context, d),
                    child: Text(_label(d)!),
                  ),
              ],
            ),
    );
  }

  IconData _icon(NotificationSeverity s) => switch (s) {
    NotificationSeverity.success => Icons.check_circle_outline,
    NotificationSeverity.warning => Icons.warning_amber,
    NotificationSeverity.error => Icons.error_outline,
    _ => Icons.notifications_none,
  };
  Color _color(BuildContext c, NotificationSeverity s) => switch (s) {
    NotificationSeverity.success => Colors.green,
    NotificationSeverity.warning => Colors.orange,
    NotificationSeverity.error => Colors.red,
    _ => Theme.of(c).colorScheme.primary,
  };
  String? _label(CustomerNotificationDetail d) => switch (d.actionType) {
    NotificationActionType.openOrder => 'View Order',
    NotificationActionType.openPayment => 'View Payment',
    NotificationActionType.openReturnRequest => 'View Return',
    NotificationActionType.openCancellationRequest => 'View Cancellation',
    NotificationActionType.openProfile => 'View Profile',
    _ => null,
  };

  void _open(BuildContext context, CustomerNotificationDetail d) {
    final ref = d.actionReference;
    switch (d.actionType) {
      case NotificationActionType.openOrder:
      case NotificationActionType.openReturnRequest:
      case NotificationActionType.openCancellationRequest:
        if (ref != null && ref.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderNumber: ref),
            ),
          );
        }
        break;
      case NotificationActionType.openPayment:
        if (ref != null && ref.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PaymentScreen(orderNumber: ref)),
          );
        }
        break;
      case NotificationActionType.openProfile:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
      default:
        break;
    }
  }
}
