import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/auth_provider.dart';
import '../../../provider/review_provider.dart';
import '../../widget/state/catalog_state_widgets.dart';
import '../product_detail/product_detail_screen.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().authenticated) {
        context.read<ReviewProvider>().loadMine(force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = context.watch<ReviewProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('My Reviews')),
      body: !auth.authenticated
          ? const CatalogEmpty(message: 'Please sign in to view your reviews.')
          : RefreshIndicator(
              onRefresh: () =>
                  context.read<ReviewProvider>().loadMine(force: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  if (p.state == ReviewLoadState.loading && p.myReviews.isEmpty)
                    const SizedBox(
                      height: 320,
                      child: CatalogLoading(label: 'Loading your reviews...'),
                    )
                  else if (p.error != null && p.myReviews.isEmpty)
                    SizedBox(
                      height: 320,
                      child: CatalogErrorView(
                        message: p.error!,
                        onRetry: () => context.read<ReviewProvider>().loadMine(
                          force: true,
                        ),
                      ),
                    )
                  else if (p.myReviews.isEmpty)
                    const SizedBox(
                      height: 320,
                      child: CatalogEmpty(
                        message:
                            'No reviews yet. Delivered orders will show review options.',
                      ),
                    )
                  else
                    ...p.myReviews.map(
                      (review) => Card(
                        child: ListTile(
                          key: Key('myReview-${review.reviewNumber}'),
                          leading: _Stars(rating: review.rating, compact: true),
                          title: Text(review.productName),
                          subtitle: Text(
                            [
                              if (review.title?.isNotEmpty == true)
                                review.title!,
                              review.comment ?? '',
                              review.status ?? '',
                            ].where((e) => e.isNotEmpty).join('\n'),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(
                                productId: review.productId,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class ReviewStars extends StatelessWidget {
  const ReviewStars({super.key, required this.rating, this.compact = false});
  final int rating;
  final bool compact;

  @override
  Widget build(BuildContext context) =>
      _Stars(rating: rating, compact: compact);
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, required this.compact});
  final int rating;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children:
        List.generate(
          compact ? 1 : 5,
          (index) => Icon(
            compact || index < rating ? Icons.star : Icons.star_border,
            size: compact ? 18 : 20,
            color: Colors.amber.shade700,
          ),
        )..add(
          compact
              ? Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text('$rating'),
                )
              : const SizedBox.shrink(),
        ),
  );
}
