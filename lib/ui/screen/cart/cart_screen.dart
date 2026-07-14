import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/product/catalog_models.dart';
import '../../../provider/cart_provider.dart';
import '../../widget/state/catalog_state_widgets.dart';
import '../product_detail/product_detail_screen.dart';
import '../checkout/checkout_screen.dart';
import '../auth/login_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    cart.authenticated
                        ? 'Synced Account Cart'
                        : 'Current Session Cart',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (cart.items.isNotEmpty)
                  TextButton(
                    onPressed: () => _clear(context, cart),
                    child: const Text('Clear'),
                  ),
              ],
            ),
            Text(
              cart.authenticated
                  ? 'Saved to your account. Current server prices and availability are shown.'
                  : 'Items remain only while this app process is running. Log in to preserve them.',
            ),
            if (cart.loading || cart.merging) const LinearProgressIndicator(),
            if (cart.error != null)
              Row(
                children: [
                  Expanded(child: Text(cart.error!)),
                  TextButton(onPressed: cart.retry, child: const Text('Retry')),
                ],
              ),
            ...cart.warnings.map(
              (w) =>
                  Text(w.message, style: const TextStyle(color: Colors.orange)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: cart.items.isEmpty
                  ? const CatalogEmpty(
                      message: 'No items are in your current Cart.',
                    )
                  : ListView.separated(
                      itemCount: cart.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final item = cart.items[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(
                                        productId: item.productId,
                                      ),
                                    ),
                                  ),
                                  child: SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: ProductImage(
                                      url: item.imageUrl,
                                      size: 65,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      if (item.variationName != null)
                                        Text(
                                          'Variation: ${item.variationName}',
                                        ),
                                      Text(
                                        '${MoneyFormatter.taka(item.unitPrice)} each',
                                      ),
                                      Text(
                                        'Subtotal: ${MoneyFormatter.taka(item.subtotal)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            tooltip: 'Decrease quantity',
                                            onPressed: item.quantity > 1
                                                ? () => cart.decrease(
                                                    item.identity,
                                                  )
                                                : null,
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                            ),
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            key: Key(
                                              'cartQuantity-${item.identity}',
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Increase quantity',
                                            onPressed: item.quantity < 99
                                                ? () => cart.increase(
                                                    item.identity,
                                                  )
                                                : null,
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            tooltip: 'Remove item',
                                            onPressed: () =>
                                                cart.remove(item.identity),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (cart.items.isNotEmpty) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cart.authenticated ? 'Server subtotal' : 'Session subtotal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    MoneyFormatter.taka(cart.subtotal),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                cart.authenticated
                    ? 'Price and availability are validated by the server. No stock is reserved.'
                    : 'Final stock and price will be validated after login.',
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  if (cart.authenticated) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please log in to preserve this Cart and continue checkout.',
                        ),
                      ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
                child: const Text('Proceed to Checkout'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _clear(BuildContext context, CartProvider cart) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Remove every item from this session Cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (yes == true) cart.clear();
  }
}
