import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/product/catalog_models.dart';
import '../../../model/order/order_models.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/order_provider.dart';
import '../auth/login_screen.dart';
import 'order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});
  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<OrderProvider>().load(refresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56),
                const SizedBox(height: 12),
                const Text('Login required to view your orders.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final p = context.watch<OrderProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: RefreshIndicator(
        onRefresh: () => p.load(refresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Newest'),
                  selected: p.sort == 'newest',
                  onSelected: (_) => p.setFilters(orderSort: 'newest'),
                ),
                ChoiceChip(
                  label: const Text('Oldest'),
                  selected: p.sort == 'oldest',
                  onSelected: (_) => p.setFilters(orderSort: 'oldest'),
                ),
                ChoiceChip(
                  label: const Text('Total high'),
                  selected: p.sort == 'total_desc',
                  onSelected: (_) => p.setFilters(orderSort: 'total_desc'),
                ),
              ],
            ),
            if (p.state == OrderLoadState.loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (p.error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  p.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (p.orders.isEmpty && p.state != OrderLoadState.loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No orders yet. Submitted orders will appear here.',
                  ),
                ),
              ),
            ...p.orders.map((o) => _OrderCard(order: o)),
            if (!p.last)
              OutlinedButton(
                onPressed: p.state == OrderLoadState.loadingMore
                    ? null
                    : p.loadMore,
                child: Text(
                  p.state == OrderLoadState.loadingMore
                      ? 'Loading...'
                      : 'Load more',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final OrderSummary order;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: order.firstItemImageUrl == null
          ? const CircleAvatar(child: Icon(Icons.shopping_bag_outlined))
          : CircleAvatar(
              backgroundImage: NetworkImage(order.firstItemImageUrl!),
            ),
      title: Text(order.orderNumber),
      subtitle: Text(
        '${order.visibleStatus} • Payment ${order.paymentStatus}\n${order.firstItemName ?? 'Order items'}${order.additionalItemCount > 0 ? ' +${order.additionalItemCount} more' : ''}\nQty ${order.totalQuantity} • ${order.deliveryMethodName ?? ''}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(MoneyFormatter.taka(order.total)),
          if (order.cancellationEligible)
            const Text('Can cancel', style: TextStyle(fontSize: 11)),
          if (order.returnEligible)
            const Text('Can return', style: TextStyle(fontSize: 11)),
        ],
      ),
      isThreeLine: true,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderNumber: order.orderNumber),
        ),
      ),
    ),
  );
}
