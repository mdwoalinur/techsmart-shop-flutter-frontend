import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/review/review_models.dart';
import '../../../provider/review_provider.dart';

class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({super.key, required this.item});
  final ReviewableItem item;

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _comment = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _title.dispose();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReviewProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Write Review')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.item.productName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.item.variationName?.isNotEmpty == true)
              Text(widget.item.variationName!),
            const SizedBox(height: 16),
            Text('Rating', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: List.generate(5, (index) {
                final value = index + 1;
                return IconButton(
                  key: Key('reviewStar$value'),
                  onPressed: () => setState(() => _rating = value),
                  icon: Icon(value <= _rating ? Icons.star : Icons.star_border),
                  color: Colors.amber.shade700,
                );
              }),
            ),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title (optional)'),
              maxLength: 120,
            ),
            TextFormField(
              key: const Key('reviewComment'),
              controller: _comment,
              decoration: const InputDecoration(labelText: 'Review'),
              minLines: 4,
              maxLines: 8,
              maxLength: 1000,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Review is required.' : null,
            ),
            FilledButton.icon(
              key: const Key('submitReview'),
              onPressed: p.submitting ? null : _submit,
              icon: p.submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.rate_review_outlined),
              label: Text(p.submitting ? 'Submitting...' : 'Submit Review'),
            ),
            if (p.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  p.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ok = await context.read<ReviewProvider>().submit(
      item: widget.item,
      rating: _rating,
      title: _title.text.trim().isEmpty ? null : _title.text.trim(),
      comment: _comment.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Review submitted.')));
      Navigator.pop(context, true);
    }
  }
}
