import 'package:flutter/material.dart';
import '../../../model/product/catalog_models.dart';
import '../../../service/catalog/catalog_service.dart';

class ProductFilterSheet extends StatefulWidget {
  const ProductFilterSheet({required this.initial, super.key});
  final CatalogFilters initial;
  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late final TextEditingController min, max;
  late bool stock;
  String? error;
  @override
  void initState() {
    super.initState();
    min = TextEditingController(text: widget.initial.minPrice?.value ?? '');
    max = TextEditingController(text: widget.initial.maxPrice?.value ?? '');
    stock = widget.initial.inStockOnly;
  }

  @override
  void dispose() {
    min.dispose();
    max.dispose();
    super.dispose();
  }

  void apply() {
    try {
      final lo = min.text.trim().isEmpty
          ? null
          : DecimalValue.fromInput(min.text);
      final hi = max.text.trim().isEmpty
          ? null
          : DecimalValue.fromInput(max.text);
      if ((lo?.numericValue ?? 0) < 0 || (hi?.numericValue ?? 0) < 0) {
        throw const FormatException('Prices cannot be negative.');
      }
      if (lo != null && hi != null && lo.numericValue > hi.numericValue) {
        throw const FormatException(
          'Minimum price cannot exceed maximum price.',
        );
      }
      Navigator.pop(
        context,
        CatalogFilters(
          categoryId: widget.initial.categoryId,
          minPrice: lo,
          maxPrice: hi,
          inStockOnly: stock,
        ),
      );
    } on FormatException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filter products', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        TextField(
          controller: min,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Minimum price'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: max,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Maximum price'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: stock,
          onChanged: (v) => setState(() => stock = v),
          title: const Text('In stock only'),
        ),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                CatalogFilters(categoryId: widget.initial.categoryId),
              ),
              child: const Text('Reset'),
            ),
            const Spacer(),
            FilledButton(onPressed: apply, child: const Text('Apply filters')),
          ],
        ),
      ],
    ),
  );
}
