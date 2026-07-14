import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/product/catalog_models.dart';
import '../../../provider/cart_provider.dart';
import '../../../provider/wishlist_provider.dart';
import '../../widget/state/catalog_state_widgets.dart';
import '../product_detail/product_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<WishlistProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(p.authenticated ? 'Saved Wishlist' : 'Session Wishlist'),
        actions: [
          if (p.items.isNotEmpty)
            IconButton(
              tooltip: 'Clear wishlist',
              onPressed: p.clear,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: p.items.isEmpty
          ? CatalogEmpty(
              message: p.authenticated
                  ? 'Your saved Wishlist is empty.'
                  : 'Your session Wishlist is empty.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  p.authenticated
                      ? 'Saved to your account and restored when you sign in.'
                      : 'Saved only for the current app session. Log in to preserve it.',
                ),
                if (p.loading || p.merging) const LinearProgressIndicator(),
                if (p.error != null)
                  Row(
                    children: [
                      Expanded(child: Text(p.error!)),
                      TextButton(
                        onPressed: p.retry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                ...p.items.map(
                  (item) => Card(
                    child: ListTile(
                      leading: SizedBox(
                        width: 58,
                        height: 58,
                        child: ProductImage(url: item.imageUrl, size: 55),
                      ),
                      title: Text(item.name),
                      subtitle: Text(
                        '${MoneyFormatter.taka(item.price)} • ${item.stock.stockLabel}',
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailScreen(productId: item.productId),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Add to Session Cart',
                            onPressed: item.stock.inStock
                                ? () {
                                    final product = ProductSummary(
                                      id: item.productId,
                                      productCode: item.productCode,
                                      name: item.name,
                                      sellingPrice: item.price,
                                      imageUrl: item.imageUrl,
                                      stock: item.stock,
                                    );
                                    context.read<CartProvider>().add(product);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Added to your current shopping session.',
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.add_shopping_cart),
                          ),
                          IconButton(
                            tooltip: 'Remove from wishlist',
                            onPressed: () => p.remove(item.productId),
                            icon: const Icon(Icons.favorite, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
