// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/product/catalog_models.dart';
import '../../../model/address/address_models.dart';
import '../../../model/checkout/checkout_models.dart';
import '../../../provider/checkout_provider.dart';
import '../order/order_detail_screen.dart';
import 'address_form_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _C();
}

class _C extends State<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CheckoutProvider>().loadPrerequisites(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CheckoutProvider>();
    if (p.confirmation != null) {
      final o = p.confirmation!;
      return Scaffold(
        appBar: AppBar(title: const Text('Order Confirmation')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 72),
            Text(
              o.orderNumber,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('Status: ${o.orderStatus}'),
            Text('Payment: ${o.paymentStatus}'),
            Text('Total: ${MoneyFormatter.taka(o.total)}'),
            Text(o.address),
            Text(o.method),
            Text(o.nextStep),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text('Return Home'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(orderNumber: o.orderNumber),
                ),
              ),
              child: const Text('View Order Details'),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Secure Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('1. Delivery address'),
          ...p.addresses.map(
            (a) => RadioListTile<CustomerAddress>(
              value: a,
              groupValue: p.selectedAddress,
              onChanged: (v) {
                if (v != null) p.selectAddress(v);
              },
              title: Text(
                '${a.label}${a.isDefault ? ' ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Default' : ''}',
              ),
              subtitle: Text(a.summary),
              secondary: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddressFormScreen(address: a),
                  ),
                ),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddressFormScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Address'),
          ),
          const Divider(),
          const Text('2. Delivery method'),
          ...p.methods.map(
            (m) => RadioListTile<DeliveryMethod>(
              value: m,
              groupValue: p.selectedMethod,
              onChanged: m.eligible
                  ? (v) {
                      if (v != null) p.selectMethod(v);
                    }
                  : null,
              title: Text(m.name),
              subtitle: Text(
                '${MoneyFormatter.taka(m.charge)} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ${m.minDays}-${m.maxDays} days${m.reason == null ? '' : ' ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ${m.reason}'}',
              ),
            ),
          ),
          FilledButton(
            onPressed: p.selectedAddress != null && p.selectedMethod != null
                ? p.requestReview
                : null,
            child: const Text('Review Order'),
          ),
          if (p.state == CheckoutState.loadingReview)
            const LinearProgressIndicator(),
          if (p.error != null)
            Text(p.error!, style: const TextStyle(color: Colors.red)),
          if (p.review case final r?) ...[
            const Divider(),
            Text('Subtotal: ${MoneyFormatter.taka(r.subtotal)}'),
            Text('Tax: ${MoneyFormatter.taka(r.tax)}'),
            Text('Delivery: ${MoneyFormatter.taka(r.delivery)}'),
            Text('Discount: ${MoneyFormatter.taka(r.discount)}'),
            Text(
              'Grand total: ${MoneyFormatter.taka(r.total)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ...r.blocking.map(
              (e) => Text(e, style: const TextStyle(color: Colors.red)),
            ),
            CheckboxListTile(
              value: p.termsAccepted,
              onChanged: (v) => p.setTerms(v ?? false),
              title: const Text(
                'I confirm the order details and accept the terms.',
              ),
            ),
            const Text('Payment selection will be available in a later phase.'),
            FilledButton(
              onPressed:
                  r.ready &&
                      p.termsAccepted &&
                      p.state != CheckoutState.submitting
                  ? () => p.submit()
                  : null,
              child: Text(
                p.state == CheckoutState.submitting
                    ? 'SubmittingÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦'
                    : 'Submit Order',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
