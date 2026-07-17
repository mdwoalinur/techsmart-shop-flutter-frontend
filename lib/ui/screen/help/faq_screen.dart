import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/help_provider.dart';
import '../../widget/state/catalog_state_widgets.dart';
import 'faq_detail_screen.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<HelpProvider>().load(),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HelpProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ & Help Center')),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<HelpProvider>().load(search: _search.text),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            TextField(
              key: const Key('faqSearchField'),
              controller: _search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: 'Search help articles',
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  onPressed: () =>
                      context.read<HelpProvider>().load(search: _search.text),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
              onSubmitted: (value) =>
                  context.read<HelpProvider>().load(search: value),
            ),
            const SizedBox(height: 16),
            if (p.state == HelpLoadState.loading)
              const SizedBox(
                height: 280,
                child: CatalogLoading(label: 'Loading help articles...'),
              )
            else if (p.error != null)
              SizedBox(
                height: 280,
                child: CatalogErrorView(
                  message: p.error!,
                  onRetry: () =>
                      context.read<HelpProvider>().load(search: _search.text),
                ),
              )
            else if (p.faqs.isEmpty)
              const SizedBox(
                height: 280,
                child: CatalogEmpty(message: 'No help articles found.'),
              )
            else
              ...p.faqs.map(
                (faq) => Card(
                  child: ListTile(
                    key: Key('faq-${faq.faqCode}'),
                    leading: const Icon(Icons.help_outline),
                    title: Text(faq.question),
                    subtitle: Text(faq.category),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FaqDetailScreen(faqCode: faq.faqCode),
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
