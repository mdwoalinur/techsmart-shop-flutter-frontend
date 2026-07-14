import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/category_provider.dart';
import '../../../provider/navigation_provider.dart';
import '../../../provider/product_provider.dart';
import '../../../provider/notification_provider.dart';
import '../../theme/app_colors.dart';
import '../../widget/product/product_grid.dart';
import '../../widget/state/catalog_state_widgets.dart';
import '../../widget/notification/notification_bell.dart';
import '../product_detail/product_detail_screen.dart';
import '../products/product_listing_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: RefreshIndicator(
      onRefresh: () async => Future.wait([
        context.read<CategoryProvider>().load(rootOnly: true),
        context.read<ProductProvider>().refresh(),
        context.read<NotificationProvider>().loadUnreadCount(),
      ]),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BrandHeader(),
            const SizedBox(height: 18),
            InkWell(
              key: const Key('homeSearch'),
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 10),
                    Text('Search products'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _heading(
              context,
              'Shop by category',
              () => context.read<NavigationProvider>().select(
                AppDestination.categories,
              ),
            ),
            const SizedBox(height: 10),
            const _HomeCategories(),
            const SizedBox(height: 24),
            _heading(
              context,
              'Latest Products',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ProductListingScreen(title: 'All Products'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _HomeProducts(),
          ],
        ),
      ),
    ),
  );
  Widget _heading(BuildContext context, String title, VoidCallback view) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      TextButton(onPressed: view, child: const Text('View all')),
    ],
  );
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();
  @override
  Widget build(BuildContext context) => Container(
    height: 100,
    width: double.infinity,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Stack(
      children: [
        Center(
          child: Image.asset(
            'assets/branding/techsmart_shop_logo.png',
            key: const Key('techSmartShopLogo'),
            fit: BoxFit.contain,
          ),
        ),
        const Positioned(right: 4, top: 4, child: NotificationBell()),
      ],
    ),
  );
}

class _HomeCategories extends StatelessWidget {
  const _HomeCategories();
  @override
  Widget build(BuildContext context) {
    final p = context.watch<CategoryProvider>();
    if (p.isLoading && p.categories.isEmpty) {
      return const SizedBox(
        height: 100,
        child: CatalogLoading(label: 'Loading categories…'),
      );
    }
    if (p.error != null && p.categories.isEmpty) {
      return CatalogErrorView(
        message: p.error!,
        onRetry: () => p.load(rootOnly: true),
      );
    }
    if (p.categories.isEmpty) {
      return const CatalogEmpty(message: 'No categories are available.');
    }
    final items = p.categories.take(8).toList();
    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = items[i];
          return SizedBox(
            width: 104,
            child: Card(
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductListingScreen(title: c.name, categoryId: c.id),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        child: Text(c.name.substring(0, 1).toUpperCase()),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        c.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeProducts extends StatelessWidget {
  const _HomeProducts();
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProductProvider>();
    if (p.isInitialLoading && p.products.isEmpty) {
      return const CatalogLoading(label: 'Loading products…');
    }
    if (p.error != null && p.products.isEmpty) {
      return CatalogErrorView(message: p.error!, onRetry: p.retry);
    }
    if (p.products.isEmpty) {
      return const CatalogEmpty(message: 'No products were found.');
    }
    return ProductGrid(
      products: p.products.take(6).toList(),
      onTap: (x) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: x.id)),
      ),
    );
  }
}
