import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/order/order_models.dart';
import '../../../provider/order_provider.dart';

class ReturnRequestScreen extends StatefulWidget {
  const ReturnRequestScreen({super.key, required this.detail});
  final OrderDetail detail;
  @override
  State<ReturnRequestScreen> createState() => _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends State<ReturnRequestScreen> {
  bool _reviewing = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().startReturnDraft(
        widget.detail.returnEligibility,
        widget.detail.orderNumber,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final draft = provider.returnDraft;
    final result = provider.returnRequest;
    return Scaffold(
      appBar: AppBar(title: const Text('Request Return')),
      body: SafeArea(
        child: draft == null && !_submitted
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  if (_submitted && result != null)
                    _ReturnConfirmation(result: result)
                  else ...[
                    Text(
                      _reviewing ? 'Review return request' : 'Select items',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A return request is only a request. It does not approve a refund, restore stock, or create a SaleReturn record.',
                    ),
                    const SizedBox(height: 16),
                    if (_reviewing)
                      _ReviewDraft(draft: draft!)
                    else
                      _EditDraft(draft: draft!),
                    if (provider.returnDraftError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        provider.returnDraftError!,
                        key: const Key('returnDraftError'),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    if (provider.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        provider.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: provider.submittingReturn
                                ? null
                                : () {
                                    if (_reviewing) {
                                      setState(() => _reviewing = false);
                                    } else {
                                      Navigator.pop(context);
                                    }
                                  },
                            child: Text(_reviewing ? 'Back' : 'Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: Key(
                              _reviewing
                                  ? 'submitReturnRequest'
                                  : 'reviewReturnRequest',
                            ),
                            onPressed: provider.submittingReturn
                                ? null
                                : () async {
                                    if (!_reviewing) {
                                      final message = provider
                                          .validateReturnDraft();
                                      if (message == null) {
                                        setState(() => _reviewing = true);
                                      }
                                      return;
                                    }
                                    final ok = await provider
                                        .submitReturnDraft();
                                    if (ok && mounted) {
                                      setState(() => _submitted = true);
                                    }
                                  },
                            child: Text(
                              provider.submittingReturn
                                  ? 'Submitting...'
                                  : _reviewing
                                  ? 'Submit Once'
                                  : 'Review Request',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _EditDraft extends StatelessWidget {
  const _EditDraft({required this.draft});
  final ReturnRequestDraft draft;
  @override
  Widget build(BuildContext context) {
    final provider = context.read<OrderProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...draft.items.map((item) => _ReturnItemEditor(item: item)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: const Key('returnPreferredResolution'),
          isExpanded: true,
          initialValue: draft.preferredResolution,
          decoration: const InputDecoration(
            labelText: 'Preferred resolution (requested, not approved)',
            border: OutlineInputBorder(),
          ),
          items:
              const [
                    'REFUND_REQUESTED',
                    'REPLACEMENT_REQUESTED',
                    'STORE_CREDIT_REQUESTED',
                  ]
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) provider.updateReturnPreferredResolution(value);
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('returnOverallComment'),
          initialValue: draft.comment,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Optional overall comment',
            border: OutlineInputBorder(),
          ),
          onChanged: provider.updateReturnComment,
        ),
      ],
    );
  }
}

class _ReturnItemEditor extends StatelessWidget {
  const _ReturnItemEditor({required this.item});
  final ReturnRequestItemDraft item;
  static const reasons = [
    'DAMAGED_OR_DEFECTIVE',
    'WRONG_ITEM',
    'NOT_AS_DESCRIBED',
    'MISSING_PARTS',
    'CHANGED_MIND',
    'OTHER',
  ];
  @override
  Widget build(BuildContext context) {
    final provider = context.read<OrderProvider>();
    final message = item.validationMessage;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              key: Key('returnSelect-${item.item.itemId}'),
              contentPadding: EdgeInsets.zero,
              value: item.selected,
              title: Text(item.item.productName),
              subtitle: Text(
                '${item.item.variationName ?? 'Standard item'} • Returnable ${item.item.remainingReturnableQuantity}',
              ),
              onChanged: (value) =>
                  provider.selectReturnItem(item.item.itemId, value ?? false),
            ),
            if (item.selected) ...[
              Row(
                children: [
                  IconButton.filledTonal(
                    key: Key('returnQtyMinus-${item.item.itemId}'),
                    onPressed: () => provider.updateReturnQuantity(
                      item.item.itemId,
                      item.quantity - 1,
                    ),
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Semantics(
                      label: 'Requested quantity for ${item.item.productName}',
                      child: TextFormField(
                        key: Key('returnQty-${item.item.itemId}'),
                        initialValue: '${item.quantity}',
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText:
                              'Quantity, max ${item.item.remainingReturnableQuantity}',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => provider.updateReturnQuantity(
                          item.item.itemId,
                          int.tryParse(value) ?? 1,
                        ),
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    key: Key('returnQtyPlus-${item.item.itemId}'),
                    onPressed: () => provider.updateReturnQuantity(
                      item.item.itemId,
                      item.quantity + 1,
                    ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: Key('returnReason-${item.item.itemId}'),
                isExpanded: true,
                initialValue: item.reasonCode,
                decoration: const InputDecoration(
                  labelText: 'Reason for this item',
                  border: OutlineInputBorder(),
                ),
                items: reasons
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    provider.updateReturnReason(item.item.itemId, value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: Key('returnReasonText-${item.item.itemId}'),
                initialValue: item.reasonText,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: item.reasonCode == 'OTHER'
                      ? 'Explanation required for OTHER'
                      : 'Optional item explanation',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) =>
                    provider.updateReturnReasonText(item.item.itemId, value),
              ),
              if (message != null)
                Text(message, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewDraft extends StatelessWidget {
  const _ReviewDraft({required this.draft});
  final ReturnRequestDraft draft;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items in this one request',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...draft.selectedItems.map(
          (item) => ListTile(
            key: Key('reviewReturnItem-${item.item.itemId}'),
            contentPadding: EdgeInsets.zero,
            title: Text(item.item.productName),
            subtitle: Text(
              'Qty ${item.quantity} • ${item.reasonCode}${item.reasonText == null ? '' : '\n${item.reasonText}'}',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Preferred resolution requested: ${draft.preferredResolution}'),
        if (draft.comment != null) Text('Comment: ${draft.comment}'),
        const SizedBox(height: 8),
        const Text(
          'Submitting creates one REQUESTED return request. It does not approve a refund or restore stock.',
        ),
      ],
    );
  }
}

class _ReturnConfirmation extends StatelessWidget {
  const _ReturnConfirmation({required this.result});
  final ReturnRequest result;
  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('returnRequestConfirmation'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.fact_check_outlined, color: Colors.green, size: 72),
        const SizedBox(height: 12),
        Text(
          result.requestNumber,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text('Status: ${result.status}'),
        Text('Preferred resolution requested: ${result.preferredResolution}'),
        const SizedBox(height: 12),
        Text(result.message, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
