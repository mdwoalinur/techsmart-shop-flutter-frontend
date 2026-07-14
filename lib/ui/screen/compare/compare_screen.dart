import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/product/catalog_models.dart';
import '../../../provider/compare_provider.dart';
import '../../widget/state/catalog_state_widgets.dart';
import '../product_detail/product_detail_screen.dart';

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<CompareProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Products'),
        actions: [
          if (p.items.isNotEmpty)
            IconButton(
              tooltip: 'Clear comparison',
              onPressed: p.clear,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: p.items.isEmpty
          ? const CatalogEmpty(message: 'Add up to 4 products to compare.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Comparison uses only currently available product information.',
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: p.items
                          .map(
                            (e) => SizedBox(
                              width: 220,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 150,
                                        child: ProductImage(
                                          url: e.imageUrl,
                                          size: 140,
                                        ),
                                      ),
                                      Text(
                                        e.name,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const Divider(),
                                      Text(MoneyFormatter.taka(e.price)),
                                      Text(e.stock.stockLabel),
                                      Text('Code: ${e.productCode}'),
                                      Text('SKU: ${e.sku ?? '—'}'),
                                      Text('Category: ${e.category ?? '—'}'),
                                      Text('Unit: ${e.unit ?? '—'}'),
                                      Row(
                                        children: [
                                          IconButton(
                                            tooltip: 'Open details',
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ProductDetailScreen(
                                                      productId: e.productId,
                                                    ),
                                              ),
                                            ),
                                            icon: const Icon(Icons.open_in_new),
                                          ),
                                          IconButton(
                                            tooltip: 'Remove ${e.name}',
                                            onPressed: () =>
                                                p.remove(e.productId),
                                            icon: const Icon(Icons.close),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
