import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/auth_provider.dart';
import '../../../provider/support_provider.dart';
import '../../widget/state/catalog_state_widgets.dart';
import 'support_ticket_detail_screen.dart';
import 'support_ticket_form_screen.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().authenticated) {
        context.read<SupportProvider>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = context.watch<SupportProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      floatingActionButton: auth.authenticated
          ? FloatingActionButton.extended(
              key: const Key('newSupportTicket'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SupportTicketFormScreen(),
                ),
              ),
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('New Ticket'),
            )
          : null,
      body: !auth.authenticated
          ? const CatalogEmpty(message: 'Please sign in to contact support.')
          : RefreshIndicator(
              onRefresh: () =>
                  context.read<SupportProvider>().load(force: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  Text(
                    'Create and track customer support tickets. Do not share passwords, OTPs, or payment PINs.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  if (p.state == SupportLoadState.loading && p.tickets.isEmpty)
                    const SizedBox(
                      height: 320,
                      child: CatalogLoading(
                        label: 'Loading support tickets...',
                      ),
                    )
                  else if (p.error != null && p.tickets.isEmpty)
                    SizedBox(
                      height: 320,
                      child: CatalogErrorView(
                        message: p.error!,
                        onRetry: () =>
                            context.read<SupportProvider>().load(force: true),
                      ),
                    )
                  else if (p.tickets.isEmpty)
                    const SizedBox(
                      height: 320,
                      child: CatalogEmpty(message: 'No support tickets yet.'),
                    )
                  else
                    ...p.tickets.map(
                      (ticket) => Card(
                        child: ListTile(
                          key: Key('ticket-${ticket.ticketNumber}'),
                          leading: const Icon(Icons.support_agent),
                          title: Text(ticket.subject),
                          subtitle: Text(
                            '${ticket.category} • ${ticket.status}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SupportTicketDetailScreen(
                                ticketNumber: ticket.ticketNumber,
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
