import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CatalogLoading extends StatelessWidget {
  const CatalogLoading({this.label = 'Loading…', super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(label),
        ],
      ),
    ),
  );
}

class CatalogEmpty extends StatelessWidget {
  const CatalogEmpty({required this.message, super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class CatalogErrorView extends StatelessWidget {
  const CatalogErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class ProductImage extends StatelessWidget {
  const ProductImage({this.url, this.size = 120, super.key});
  final String? url;
  final double size;
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: const Color(0xFFEAF1FA),
      alignment: Alignment.center,
      child: Icon(
        Icons.devices_other_rounded,
        size: size * .36,
        color: AppColors.electricBlue,
      ),
    );
    if (url == null || url!.isEmpty) return fallback;
    return Image.network(
      url!,
      fit: BoxFit.contain,
      loadingBuilder: (c, w, p) => p == null
          ? w
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
