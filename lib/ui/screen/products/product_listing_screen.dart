import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/product_provider.dart';
import '../../../service/catalog/catalog_service.dart';
import '../../widget/product/product_grid.dart';
import '../../widget/state/catalog_state_widgets.dart';
import '../product_detail/product_detail_screen.dart';
import 'product_filter_sheet.dart';

class ProductListingScreen extends StatelessWidget {
  const ProductListingScreen({required this.title, this.categoryId, super.key});
  final String title;
  final int? categoryId;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) =>
        ProductProvider(c.read<CatalogRepository>(), categoryId: categoryId)
          ..loadInitial(),
    child: _Listing(title: title),
  );
}

class _Listing extends StatefulWidget {
  const _Listing({required this.title});
  final String title;
  @override
  State<_Listing> createState() => _ListingState();
}

class _ListingState extends State<_Listing> {
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 500) {
        context.read<ProductProvider>().loadMore();
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
    final p = context.watch<ProductProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CatalogSort>(
                    initialValue: p.sort,
                    decoration: const InputDecoration(labelText: 'Sort'),
                    items: CatalogSort.values
                        .map(
                          (s) =>
                              DropdownMenuItem(value: s, child: Text(s.label)),
                        )
                        .toList(),
                    onChanged: (s) {
                      if (s != null) p.changeSort(s);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final f = await showModalBottomSheet<CatalogFilters>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ProductFilterSheet(initial: p.filters),
                    );
                    if (f != null) p.applyFilters(f);
                  },
                  icon: const Icon(Icons.tune),
                  label: const Text('Filter'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _body(p)),
        ],
      ),
    );
  }

  Widget _body(ProductProvider p) {
    if (p.isInitialLoading && p.products.isEmpty) {
      return const CatalogLoading(label: 'Loading products…');
    }
    if (p.error != null && p.products.isEmpty) {
      return CatalogErrorView(message: p.error!, onRetry: p.retry);
    }
    if (p.products.isEmpty) {
      return const CatalogEmpty(message: 'No products were found.');
    }
    return RefreshIndicator(
      onRefresh: p.refresh,
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text('${p.totalElements} products'),
          const SizedBox(height: 10),
          ProductGrid(
            products: p.products,
            onTap: (x) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(productId: x.id),
              ),
            ),
          ),
          if (p.isLoadingMore) const CatalogLoading(label: 'Loading more…'),
          if (p.loadMoreError != null)
            TextButton(
              onPressed: p.loadMore,
              child: const Text('Retry loading more'),
            ),
        ],
      ),
    );
  }
}
