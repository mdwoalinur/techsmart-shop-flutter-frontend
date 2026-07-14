import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/search_provider.dart';
import '../../../service/catalog/catalog_service.dart';
import '../../widget/product/product_grid.dart';
import '../../widget/state/catalog_state_widgets.dart';
import '../product_detail/product_detail_screen.dart';
import '../products/product_filter_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  final scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    scroll.addListener(() {
      if (scroll.position.extentAfter < 450) {
        context.read<SearchProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SearchProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Search products')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              key: const Key('searchInput'),
              controller: controller,
              maxLength: 100,
              textInputAction: TextInputAction.search,
              onChanged: (v) {
                p.updateQuery(v);
                setState(() {});
              },
              onSubmitted: (_) => p.submit(),
              decoration: InputDecoration(
                hintText: 'Name, code, SKU or description',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          controller.clear();
                          p.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          if (p.query.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<CatalogSort>(
                      isExpanded: true,
                      value: p.sort,
                      items: CatalogSort.values
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.label),
                            ),
                          )
                          .toList(),
                      onChanged: (s) {
                        if (s != null) p.changeSort(s);
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Filter',
                    onPressed: () async {
                      final f = await showModalBottomSheet<CatalogFilters>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => ProductFilterSheet(initial: p.filters),
                      );
                      if (f != null) p.applyFilters(f);
                    },
                    icon: const Icon(Icons.tune),
                  ),
                ],
              ),
            ),
          Expanded(child: _body(p)),
        ],
      ),
    );
  }

  Widget _body(SearchProvider p) {
    if (p.query.trim().isEmpty) {
      return const CatalogEmpty(
        message: 'Enter a product name, code, SKU or description.',
      );
    }
    if (p.isLoading && p.results.isEmpty) {
      return const CatalogLoading(label: 'Searching…');
    }
    if (p.error != null && p.results.isEmpty) {
      return CatalogErrorView(message: p.error!, onRetry: p.submit);
    }
    if (p.results.isEmpty) {
      return const CatalogEmpty(
        message: 'No products were found. Try a different search.',
      );
    }
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.all(16),
      children: [
        ProductGrid(
          products: p.results,
          onTap: (x) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: x.id),
            ),
          ),
        ),
        if (p.isLoadingMore) const CatalogLoading(label: 'Loading more…'),
      ],
    );
  }
}
