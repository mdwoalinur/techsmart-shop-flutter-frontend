import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/product/catalog_models.dart';
import '../../../model/order/order_models.dart';
import '../../../model/tracking/order_tracking_models.dart';
import '../../../provider/order_provider.dart';
import 'return_request_screen.dart';
import '../payment/payment_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderNumber});
  final String orderNumber;
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<OrderProvider>().loadDetail(widget.orderNumber),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OrderProvider>();
    final d = p.selected;
    return Scaffold(
      appBar: AppBar(title: Text(widget.orderNumber)),
      body: d == null
          ? Center(
              child: p.error == null
                  ? const CircularProgressIndicator()
                  : Text(p.error!),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Text(
                  d.visibleStatus,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text('Order: ${d.orderNumber}'),
                Text('Payment: ${d.paymentStatus}'),
                Text('Accounting: ${d.accountingStatus}'),
                const Divider(),
                Text('Items', style: Theme.of(context).textTheme.titleLarge),
                ...d.items.map(
                  (i) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(i.productName),
                    subtitle: Text(
                      '${i.variationName ?? i.productCode} ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ Qty ${i.quantity}',
                    ),
                    trailing: Text(MoneyFormatter.taka(i.lineSubtotal)),
                  ),
                ),
                const Divider(),
                _amount('Subtotal', d.subtotal),
                _amount('Tax', d.tax),
                _amount('Delivery', d.delivery),
                _amount('Discount', d.discount),
                _amount('Grand total', d.total, big: true),
                const Divider(),
                _PaymentSection(detail: d),
                const Divider(),
                _TrackingSection(orderNumber: d.orderNumber),
                const Divider(),
                Text('Delivery', style: Theme.of(context).textTheme.titleLarge),
                Text(d.deliverySnapshot.recipientName),
                Text(d.deliverySnapshot.phone),
                Text(d.deliverySnapshot.address),
                Text(d.deliverySnapshot.deliveryMethodName),
                if (d.note != null) Text('Note: ${d.note}'),
                const Divider(),
                Text('Timeline', style: Theme.of(context).textTheme.titleLarge),
                ...d.timeline.map(
                  (e) => ListTile(
                    leading: Icon(
                      e.current
                          ? Icons.radio_button_checked
                          : Icons.check_circle_outline,
                    ),
                    title: Text(e.title),
                    subtitle: Text(
                      '${e.description}\n${e.occurredAt.toLocal()}${e.note == null ? '' : '\n${e.note}'}',
                    ),
                  ),
                ),
                const Divider(),
                _CancellationSection(detail: d),
                const Divider(),
                _ReturnSection(detail: d),
                const Divider(),
                FilledButton.icon(
                  onPressed: d.documentAvailable && !p.loadingDocument
                      ? p.loadDocument
                      : null,
                  icon: const Icon(Icons.description_outlined),
                  label: Text(
                    p.loadingDocument
                        ? 'Loading document...'
                        : 'View Order Summary / Pro Forma',
                  ),
                ),
                if (p.document != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.document!.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.document!.html.replaceAll(
                              RegExp(r'<[^>]+>'),
                              ' ',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (p.error != null)
                  Text(p.error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
    );
  }

  Widget _amount(String l, DecimalValue v, {bool big = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: big ? Theme.of(context).textTheme.titleMedium : null),
        Text(
          MoneyFormatter.taka(v),
          style: big ? Theme.of(context).textTheme.titleMedium : null,
        ),
      ],
    ),
  );
}

class _TrackingSection extends StatelessWidget {
  const _TrackingSection({required this.orderNumber});
  final String orderNumber;
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final tracking = provider.trackingByOrderNumber[orderNumber];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Delivery tracking',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Refresh tracking',
              onPressed: provider.refreshingTracking
                  ? null
                  : () => provider.loadTracking(orderNumber, refresh: true),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (provider.trackingLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          )
        else if (tracking == null)
          Text(provider.trackingError ?? 'Tracking is not available yet.')
        else ...[
          Text('Fulfillment: ${tracking.fulfillmentStatus.label}'),
          Text('Payment: ${tracking.paymentStatus}'),
          if (tracking.codStatus != CodTrackingStatus.unknown)
            Text('COD: ${tracking.codStatus.label}'),
          if (tracking.deliveryPartner?.isNotEmpty == true)
            Text('Delivery partner: ${tracking.deliveryPartner}'),
          if (tracking.trackingNumber?.isNotEmpty == true)
            Text('Tracking number: ${tracking.trackingNumber}'),
          if (tracking.estimatedDeliveryDate != null)
            Text('Estimated delivery: ${tracking.estimatedDeliveryDate}'),
          if (tracking.deliveredAt != null)
            Text('Delivered at: ${tracking.deliveredAt}'),
          const SizedBox(height: 8),
          ...tracking.steps.map((step) => _TrackingStepTile(step: step)),
          if (tracking.deliveryEvents.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Delivery events',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...tracking.deliveryEvents.map(
              (event) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text(event.title),
                subtitle: Text(
                  [
                    if (event.description?.isNotEmpty == true)
                      event.description!,
                    if (event.location?.isNotEmpty == true) event.location!,
                    if (event.occurredAt != null) '${event.occurredAt}',
                  ].join('\n'),
                ),
              ),
            ),
          ],
          if (provider.trackingError != null)
            Text(
              provider.trackingError!,
              style: const TextStyle(color: Colors.red),
            ),
        ],
      ],
    );
  }
}

class _TrackingStepTile extends StatelessWidget {
  const _TrackingStepTile({required this.step});
  final TrackingStep step;
  @override
  Widget build(BuildContext context) {
    final icon = step.completed
        ? Icons.check_circle
        : step.current
        ? Icons.radio_button_checked
        : Icons.radio_button_unchecked;
    final color = step.completed || step.current
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).disabledColor;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(step.title),
      subtitle: Text(
        '${step.description}${step.timestamp == null ? '' : '\n${step.timestamp}'}',
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({required this.detail});
  final OrderDetail detail;
  bool get payable =>
      detail.paymentStatus != 'PAID' &&
      detail.orderStatus != 'CANCELLED' &&
      detail.orderStatus != 'REFUNDED';
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Payment', style: Theme.of(context).textTheme.titleLarge),
      Text('Status: ${detail.paymentStatus}'),
      Text('Accounting: ${detail.accountingStatus}'),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: payable
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PaymentScreen(orderNumber: detail.orderNumber),
                ),
              )
            : null,
        icon: const Icon(Icons.payment_outlined),
        label: Text(
          payable ? 'Pay Now / View Payment Details' : 'Payment closed',
        ),
      ),
    ],
  );
}

class _CancellationSection extends StatelessWidget {
  const _CancellationSection({required this.detail});
  final OrderDetail detail;
  @override
  Widget build(BuildContext context) {
    final p = context.watch<OrderProvider>();
    final e = detail.cancellationEligibility;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cancellation', style: Theme.of(context).textTheme.titleLarge),
        Text(e.message),
        if (e.eligible)
          FilledButton(
            onPressed: p.submittingCancellation ? null : () => _dialog(context),
            child: Text(
              p.submittingCancellation
                  ? 'Submitting...'
                  : 'Request Cancellation',
            ),
          ),
        if (p.cancellation != null)
          Text('Request status: ${p.cancellation!.status}'),
      ],
    );
  }

  Future<void> _dialog(BuildContext context) async {
    String reason = 'ORDERED_BY_MISTAKE';
    final text = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Request cancellation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: reason,
              items: const [
                'ORDERED_BY_MISTAKE',
                'NEED_TO_CHANGE_ADDRESS',
                'NEED_TO_CHANGE_ITEMS',
                'FOUND_BETTER_PRICE',
                'DELIVERY_TIME_TOO_LONG',
                'OTHER',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => reason = v ?? reason,
            ),
            TextField(
              controller: text,
              decoration: const InputDecoration(
                labelText: 'Explanation (required for OTHER)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<OrderProvider>().submitCancellation(
        reason,
        text: text.text,
      );
    }
  }
}

class _ReturnSection extends StatelessWidget {
  const _ReturnSection({required this.detail});
  final OrderDetail detail;
  @override
  Widget build(BuildContext context) {
    final p = context.watch<OrderProvider>();
    final e = detail.returnEligibility;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Return request', style: Theme.of(context).textTheme.titleLarge),
        Text(e.message),
        if (e.eligible)
          FilledButton(
            onPressed: p.submittingReturn
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReturnRequestScreen(detail: detail),
                    ),
                  ),
            child: Text(
              p.submittingReturn ? 'Submitting...' : 'Request Return',
            ),
          ),
        if (p.returnRequest != null)
          Text(
            'Return request ${p.returnRequest!.requestNumber}: ${p.returnRequest!.status}',
          ),
      ],
    );
  }
}
