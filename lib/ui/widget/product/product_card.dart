import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/product/catalog_models.dart';
import '../../../provider/compare_provider.dart';
import '../../../provider/wishlist_provider.dart';
import '../../theme/app_colors.dart';
import '../state/catalog_state_widgets.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, required this.onTap, super.key});
  final ProductSummary product;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final compare = context.watch<CompareProvider>();
    final liked = wishlist.contains(product.id);
    final compared = compare.contains(product.id);
    final hasOfferPrice =
        product.originalPrice != null &&
        product.originalPrice!.numericValue > product.sellingPrice.numericValue;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ProductImage(url: product.imageUrl, size: 130),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Column(
                        children: [
                          IconButton(
                            key: Key('wishlist-${product.id}'),
                            tooltip: liked
                                ? 'Remove from Wishlist'
                                : 'Add to Wishlist',
                            onPressed: () => wishlist.toggle(product),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            icon: Icon(
                              liked ? Icons.favorite : Icons.favorite_border,
                              color: liked ? Colors.red : AppColors.navy,
                            ),
                          ),
                          IconButton(
                            key: Key('compare-${product.id}'),
                            tooltip: compared
                                ? 'Remove from comparison'
                                : 'Add to comparison',
                            onPressed: () {
                              final result = compare.toggle(product);
                              if (result == CompareResult.limitReached) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'You can compare up to 4 products.',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            icon: Icon(
                              Icons.compare_arrows,
                              color: compared
                                  ? AppColors.electricBlue
                                  : AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      MoneyFormatter.taka(product.sellingPrice),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.electricBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (hasOfferPrice) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        MoneyFormatter.taka(product.originalPrice!),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (hasOfferPrice && product.savingsLabel != null) ...[
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.savingsLabel!,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                product.stock.stockLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: product.stock.inStock
                      ? AppColors.teal
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
