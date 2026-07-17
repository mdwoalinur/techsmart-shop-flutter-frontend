import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/help_provider.dart';

class FaqDetailScreen extends StatefulWidget {
  const FaqDetailScreen({super.key, required this.faqCode});
  final String faqCode;

  @override
  State<FaqDetailScreen> createState() => _FaqDetailScreenState();
}

class _FaqDetailScreenState extends State<FaqDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<HelpProvider>().loadDetail(widget.faqCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HelpProvider>();
    final faq = p.selected;
    return Scaffold(
      appBar: AppBar(title: const Text('Help Article')),
      body: p.state == HelpLoadState.loading && faq == null
          ? const Center(child: CircularProgressIndicator())
          : faq == null
          ? Center(child: Text(p.error ?? 'Help article not found.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  faq.category,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  faq.question,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(faq.answer),
              ],
            ),
    );
  }
}
