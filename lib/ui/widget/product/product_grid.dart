import 'package:flutter/material.dart';
import '../../../model/product/catalog_models.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({required this.products, required this.onTap, super.key});
  final List<ProductSummary> products;
  final void Function(ProductSummary) onTap;
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 240,
      mainAxisExtent: 315,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    itemCount: products.length,
    itemBuilder: (_, i) =>
        ProductCard(product: products[i], onTap: () => onTap(products[i])),
  );
}
