import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/product/catalog_models.dart';
import '../../../provider/cart_provider.dart';
import '../../../provider/compare_provider.dart';
import '../../../provider/navigation_provider.dart';
import '../../../provider/product_provider.dart';
import '../../../provider/wishlist_provider.dart';
import '../../../service/catalog/catalog_service.dart';
import '../../theme/app_colors.dart';
import '../../widget/state/catalog_state_widgets.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({required this.productId, super.key});
  final int productId;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) =>
        ProductProvider(c.read<CatalogRepository>())..loadDetail(productId),
    child: const _Detail(),
  );
}

class _Detail extends StatefulWidget {
  const _Detail();
  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  int quantity = 1;
  bool adding = false;
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProductProvider>();
    final d = p.detail;
    if (p.isInitialLoading) {
      return const Scaffold(body: CatalogLoading(label: 'Loading product…'));
    }
    if (d == null) {
      return Scaffold(
        appBar: AppBar(),
        body: CatalogErrorView(
          message: p.error ?? 'This product is unavailable.',
          onRetry: p.retryDetail,
        ),
      );
    }
    final selected = p.selectedVariation;
    final image = selected?.imageUrl ?? d.imageUrl;
    final price = selected?.effectivePrice ?? d.sellingPrice;
    final wishlist = context.watch<WishlistProvider>();
    final compare = context.watch<CompareProvider>();
    final liked = wishlist.contains(d.id);
    final compared = compare.contains(d.id);
    final images = <String>{
      if (d.imageUrl != null) d.imageUrl!,
      ...d.variations.map((e) => e.imageUrl).whereType<String>(),
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          IconButton(
            key: const Key('detailWishlist'),
            tooltip: liked ? 'Remove from Wishlist' : 'Add to Wishlist',
            onPressed: () => wishlist.toggle(d),
            icon: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              color: liked ? Colors.red : null,
            ),
          ),
          IconButton(
            key: const Key('detailCompare'),
            tooltip: compared ? 'Remove from comparison' : 'Add to comparison',
            onPressed: () {
              final r = compare.toggle(d);
              if (r == CompareResult.limitReached) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You can compare up to 4 products.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.compare_arrows),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              height: MediaQuery.sizeOf(context).width.clamp(240, 360),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ProductImage(
                key: ValueKey('main-$image'),
                url: image,
                size: 280,
              ),
            ),
            if (images.length > 1) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 70,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: images.map((url) {
                    final isBase = url == d.imageUrl;
                    final variation = d.variations
                        .where((e) => e.imageUrl == url)
                        .firstOrNull;
                    final active = image == url;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () =>
                            p.selectVariation(isBase ? null : variation),
                        child: Container(
                          width: 70,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: active
                                  ? AppColors.electricBlue
                                  : AppColors.border,
                              width: active ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ProductImage(url: url, size: 60),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(d.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              MoneyFormatter.taka(price),
              key: const Key('detailPrice'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.electricBlue,
              ),
            ),
            const SizedBox(height: 8),
            Chip(label: Text(d.stock.stockLabel)),
            const SizedBox(height: 12),
            Text('Product code: ${d.productCode}'),
            Text('SKU: ${selected?.sku ?? d.sku ?? '—'}'),
            if (d.category != null) Text('Category: ${d.category!.name}'),
            if (d.unit != null) Text('Unit: ${d.unit!.name} (${d.unit!.code})'),
            if (d.taxRate != null) Text('Tax rate: ${d.taxRate}%'),
            if (d.variations.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Choose a variation',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Base product'),
                    selected: selected == null,
                    onSelected: (_) => p.selectVariation(null),
                  ),
                  ...d.variations.map(
                    (v) => ChoiceChip(
                      label: Text(v.name),
                      selected: selected?.id == v.id,
                      onSelected: (_) => p.selectVariation(v),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            Text('Quantity', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                IconButton(
                  key: const Key('decrementQuantity'),
                  tooltip: 'Decrease quantity',
                  onPressed: quantity > 1
                      ? () => setState(() => quantity--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$quantity',
                  key: const Key('detailQuantity'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  key: const Key('incrementQuantity'),
                  tooltip: 'Increase quantity',
                  onPressed: quantity < 99
                      ? () => setState(() => quantity++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const Text(
              'Final stock and price will be verified during checkout.',
            ),
            if (d.description?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 22),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(d.description!),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('addToCart'),
              onPressed: !d.stock.inStock || adding
                  ? null
                  : () => _add(context, d, selected),
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(
                d.stock.inStock ? 'Add to Session Cart' : 'Out of Stock',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(
    BuildContext context,
    ProductDetail d,
    ProductVariation? variation,
  ) async {
    if (adding) return;
    setState(() => adding = true);
    final cart = context.read<CartProvider>();
    final result = cart.add(d, variation: variation, quantity: quantity);
    if (mounted) setState(() => adding = false);
    if (result == CartAddResult.outOfStock) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This product is currently out of stock.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Added to your current shopping session.',
              style: Theme.of(sheet).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(d.name),
            if (variation != null) Text('Variation: ${variation.name}'),
            Text('Quantity added: $quantity'),
            Text('Cart quantity: ${cart.totalQuantity}'),
            Text('Cart subtotal: ${MoneyFormatter.taka(cart.subtotal)}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheet),
                    child: const Text('Continue Shopping'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const Key('viewCart'),
                    onPressed: () {
                      Navigator.pop(sheet);
                      context.read<NavigationProvider>().select(
                        AppDestination.cart,
                      );
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('View Cart'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
