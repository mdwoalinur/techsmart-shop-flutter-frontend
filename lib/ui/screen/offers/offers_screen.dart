import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/offer/offer_models.dart';
import '../../../model/product/catalog_models.dart';
import '../../../provider/offer_provider.dart';
import '../../theme/app_colors.dart';
import '../../widget/product/product_card.dart';
import '../../widget/state/catalog_state_widgets.dart';
import '../product_detail/product_detail_screen.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OfferProvider>().loadOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OfferProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Offers')),
      body: RefreshIndicator(
        onRefresh: () => context.read<OfferProvider>().loadOffers(force: true),
        child: _body(context, provider),
      ),
    );
  }

  Widget _body(BuildContext context, OfferProvider provider) {
    if (provider.state == OfferLoadState.loading && provider.offers.isEmpty) {
      return const CatalogLoading(label: 'Loading offers...');
    }
    if (provider.state == OfferLoadState.error && provider.offers.isEmpty) {
      return CatalogErrorView(
        message: provider.error ?? 'Unable to load offers.',
        onRetry: () => context.read<OfferProvider>().loadOffers(force: true),
      );
    }
    if (provider.offers.isEmpty) {
      return const CatalogEmpty(
        message: 'No active offers are available right now.',
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: provider.offers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) => OfferCard(
        offer: provider.offers[index],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                OfferDetailScreen(offerId: provider.offers[index].id),
          ),
        ),
      ),
    );
  }
}

class OfferCard extends StatelessWidget {
  const OfferCard({required this.offer, required this.onTap, super.key});
  final OfferSummary offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 132,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navy, AppColors.electricBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  if (offer.bannerUrl != null)
                    Positioned.fill(
                      child: Image.network(offer.bannerUrl!, fit: BoxFit.cover),
                    ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Text(
                      offer.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (offer.channel != null)
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Chip(
                        label: Text(offer.channel!),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (offer.subtitle != null)
                    Text(
                      offer.subtitle!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (offer.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      offer.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(Icons.event_available, _date(offer.startAt)),
                      _InfoChip(Icons.event_busy, _date(offer.endAt)),
                      _InfoChip(
                        Icons.inventory_2_outlined,
                        '${offer.productCount} products',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.local_offer_outlined),
                    label: const Text('Shop Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime value) =>
      '${value.year}-${_two(value.month)}-${_two(value.day)}';
  String _two(int value) => value.toString().padLeft(2, '0');
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.electricBlue),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    ),
  );
}

class OfferDetailScreen extends StatefulWidget {
  const OfferDetailScreen({required this.offerId, super.key});
  final int offerId;

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OfferProvider>().loadDetail(widget.offerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OfferProvider>();
    final offer = provider.selected;
    return Scaffold(
      appBar: AppBar(title: Text(offer?.title ?? 'Offer Details')),
      body: _body(context, provider),
    );
  }

  Widget _body(BuildContext context, OfferProvider provider) {
    if (provider.state == OfferLoadState.loading && provider.selected == null) {
      return const CatalogLoading(label: 'Loading offer products...');
    }
    if (provider.state == OfferLoadState.error && provider.selected == null) {
      return CatalogErrorView(
        message: provider.error ?? 'Unable to load offer.',
        onRetry: () => context.read<OfferProvider>().loadDetail(widget.offerId),
      );
    }
    final offer = provider.selected;
    if (offer == null) return const SizedBox.shrink();
    if (provider.products.isEmpty) {
      return const CatalogEmpty(
        message: 'No products are included in this offer.',
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >
            notification.metrics.maxScrollExtent - 300) {
          context.read<OfferProvider>().loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _OfferHeader(offer: offer)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .66,
              ),
              itemCount: provider.products.length,
              itemBuilder: (context, index) {
                final ProductSummary product = provider.products[index];
                return ProductCard(
                  product: product,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailScreen(productId: product.id),
                    ),
                  ),
                );
              },
            ),
          ),
          if (provider.loadingMore)
            const SliverToBoxAdapter(
              child: CatalogLoading(label: 'Loading more products...'),
            ),
        ],
      ),
    );
  }
}

class _OfferHeader extends StatelessWidget {
  const _OfferHeader({required this.offer});
  final OfferDetail offer;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          offer.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (offer.description != null) ...[
          const SizedBox(height: 6),
          Text(offer.description!),
        ],
      ],
    ),
  );
}
