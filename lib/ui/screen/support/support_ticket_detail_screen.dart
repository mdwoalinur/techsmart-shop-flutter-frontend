import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/support_provider.dart';

class SupportTicketDetailScreen extends StatefulWidget {
  const SupportTicketDetailScreen({super.key, required this.ticketNumber});
  final String ticketNumber;

  @override
  State<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends State<SupportTicketDetailScreen> {
  final _reply = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<SupportProvider>().loadDetail(widget.ticketNumber),
    );
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SupportProvider>();
    final ticket = p.selected;
    final closed = ticket?.status == 'CLOSED';
    return Scaffold(
      appBar: AppBar(title: Text(widget.ticketNumber)),
      body: ticket == null && p.state == SupportLoadState.loading
          ? const Center(child: CircularProgressIndicator())
          : ticket == null
          ? Center(child: Text(p.error ?? 'Support ticket not found.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                Text(
                  ticket.subject,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '${ticket.category} • ${ticket.priority} • ${ticket.status}',
                ),
                if (ticket.relatedOrderNumber?.isNotEmpty == true)
                  Text('Order: ${ticket.relatedOrderNumber}'),
                const Divider(),
                Text('Messages', style: Theme.of(context).textTheme.titleLarge),
                if (ticket.messages.isEmpty)
                  const Text('No visible messages yet.')
                else
                  ...ticket.messages.map(
                    (m) => Card(
                      child: ListTile(
                        leading: Icon(
                          m.senderType == 'CUSTOMER'
                              ? Icons.person_outline
                              : m.senderType == 'SYSTEM'
                              ? Icons.info_outline
                              : Icons.support_agent,
                        ),
                        title: Text(m.senderType),
                        subtitle: Text(m.message),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (!closed) ...[
                  TextField(
                    key: const Key('supportReply'),
                    controller: _reply,
                    decoration: const InputDecoration(labelText: 'Reply'),
                    minLines: 2,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const Key('sendSupportReply'),
                    onPressed: p.submitting ? null : _sendReply,
                    icon: const Icon(Icons.reply_outlined),
                    label: Text(p.submitting ? 'Sending...' : 'Send Reply'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('closeSupportTicket'),
                    onPressed: p.submitting ? null : _close,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Close Ticket'),
                  ),
                ],
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
    );
  }

  Future<void> _sendReply() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    final ok = await context.read<SupportProvider>().reply(
      widget.ticketNumber,
      text,
    );
    if (ok) _reply.clear();
  }

  Future<void> _close() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Close ticket?'),
        content: const Text(
          'You can create a new ticket if you need more help later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await context.read<SupportProvider>().close(widget.ticketNumber);
    }
  }
}
