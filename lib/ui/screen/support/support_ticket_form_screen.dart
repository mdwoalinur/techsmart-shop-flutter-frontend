import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/support_provider.dart';
import 'support_ticket_detail_screen.dart';

class SupportTicketFormScreen extends StatefulWidget {
  const SupportTicketFormScreen({super.key, this.relatedOrderNumber});
  final String? relatedOrderNumber;

  @override
  State<SupportTicketFormScreen> createState() =>
      _SupportTicketFormScreenState();
}

class _SupportTicketFormScreenState extends State<SupportTicketFormScreen> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _order = TextEditingController();
  final _message = TextEditingController();
  String _category = 'ORDER';
  String _priority = 'NORMAL';

  @override
  void initState() {
    super.initState();
    _order.text = widget.relatedOrderNumber ?? '';
  }

  @override
  void dispose() {
    _subject.dispose();
    _order.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SupportProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('New Support Ticket')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              key: const Key('ticketSubject'),
              controller: _subject,
              decoration: const InputDecoration(labelText: 'Subject'),
              maxLength: 160,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Subject is required.' : null,
            ),
            DropdownButtonFormField<String>(
              key: const Key('ticketCategory'),
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                'ORDER',
                'PAYMENT',
                'DELIVERY',
                'RETURN',
                'PRODUCT',
                'ACCOUNT',
                'OTHER',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                'LOW',
                'NORMAL',
                'HIGH',
                'URGENT',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _priority = v ?? _priority),
            ),
            TextFormField(
              controller: _order,
              decoration: const InputDecoration(
                labelText: 'Related order number (optional)',
              ),
              maxLength: 60,
            ),
            TextFormField(
              key: const Key('ticketMessage'),
              controller: _message,
              decoration: const InputDecoration(labelText: 'Message'),
              minLines: 4,
              maxLines: 8,
              maxLength: 1500,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Message is required.' : null,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('submitTicket'),
              onPressed: p.submitting ? null : _submit,
              icon: p.submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(p.submitting ? 'Creating...' : 'Create Ticket'),
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
    final provider = context.read<SupportProvider>();
    final detail = await provider.create(
      subject: _subject.text.trim(),
      category: _category,
      priority: _priority,
      relatedOrderNumber: _order.text.trim().isEmpty
          ? null
          : _order.text.trim(),
      message: _message.text.trim(),
    );
    if (!mounted || detail == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SupportTicketDetailScreen(ticketNumber: detail.ticketNumber),
      ),
    );
  }
}
