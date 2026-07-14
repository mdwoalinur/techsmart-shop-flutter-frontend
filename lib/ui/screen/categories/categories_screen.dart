import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/category_provider.dart';
import '../../widget/state/catalog_state_widgets.dart';
import '../products/product_listing_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categories',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text('Browse active TechSmart Shop categories'),
            const SizedBox(height: 16),
            Expanded(child: _body(context, provider)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, CategoryProvider provider) {
    if (provider.isLoading && provider.categories.isEmpty) {
      return const CatalogLoading(label: 'Loading categories…');
    }
    if (provider.error != null && provider.categories.isEmpty) {
      return CatalogErrorView(
        message: provider.error!,
        onRetry: () => provider.load(rootOnly: true),
      );
    }
    if (provider.categories.isEmpty) {
      return const CatalogEmpty(message: 'No categories are available.');
    }
    return RefreshIndicator(
      onRefresh: () => provider.load(rootOnly: true),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 230,
          mainAxisExtent: 130,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: provider.categories.length,
        itemBuilder: (_, index) {
          final category = provider.categories[index];
          return Card(
            child: Semantics(
              button: true,
              label: 'Browse ${category.name}',
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductListingScreen(
                      title: category.name,
                      categoryId: category.id,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        child: Text(
                          category.name.substring(0, 1).toUpperCase(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
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
