import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/payment/payment_models.dart';
import '../../../model/product/catalog_models.dart';
import '../../../provider/payment_provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.orderNumber});
  final String orderNumber;
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ref = TextEditingController();
  final name = TextEditingController();
  final phone = TextEditingController();
  final note = TextEditingController();
  final walletNumber = TextEditingController(text: '01700000000');
  final walletCode = TextEditingController(text: '123456');
  final walletPin = TextEditingController(text: '12345');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<PaymentProvider>().loadMethods(widget.orderNumber),
    );
  }

  @override
  void dispose() {
    ref.dispose();
    name.dispose();
    phone.dispose();
    note.dispose();
    walletNumber.dispose();
    walletCode.dispose();
    walletPin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PaymentProvider>();
    final amount = p.current?.amount;
    return Scaffold(
      appBar: AppBar(title: Text('Payment ${widget.orderNumber}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            'Choose payment method',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          if (amount != null)
            Card(
              child: ListTile(
                title: const Text('Amount due'),
                subtitle: const Text('Calculated by backend. Not editable.'),
                trailing: Text(
                  MoneyFormatter.taka(amount),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          if (p.state == PaymentFlowState.loadingMethods)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          ...p.methods.map(
            (m) => _MethodTile(
              method: m,
              selected: p.selectedMethod?.code == m.code,
              onTap: () => p.selectMethod(m),
            ),
          ),
          const SizedBox(height: 12),
          if (p.selectedMethod != null)
            _ActionArea(
              method: p.selectedMethod!,
              ref: ref,
              name: name,
              phone: phone,
              note: note,
              walletNumber: walletNumber,
              walletCode: walletCode,
              walletPin: walletPin,
            ),
          const Divider(),
          _StatusCard(),
          if (p.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(p.error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });
  final PaymentMethodOption method;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      enabled: method.eligible,
      onTap: method.eligible ? onTap : null,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
      ),
      title: Text(method.displayName),
      subtitle: Text(
        method.eligible
            ? (method.instructions ?? method.type)
            : (method.ineligibilityReason ?? 'Not eligible'),
      ),
      trailing: method.isWallet
          ? const Chip(label: Text('Wallet'))
          : method.reviewRequired
          ? const Chip(label: Text('Review'))
          : method.autoVerify
          ? const Chip(label: Text('Auto'))
          : null,
    ),
  );
}

class _ActionArea extends StatelessWidget {
  const _ActionArea({
    required this.method,
    required this.ref,
    required this.name,
    required this.phone,
    required this.note,
    required this.walletNumber,
    required this.walletCode,
    required this.walletPin,
  });
  final PaymentMethodOption method;
  final TextEditingController ref, name, phone, note;
  final TextEditingController walletNumber, walletCode, walletPin;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PaymentProvider>();
    if (method.isWallet) {
      return _WalletArea(
        walletNumber: walletNumber,
        walletCode: walletCode,
        walletPin: walletPin,
      );
    }
    if (method.isOnline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Online development gateway opens a backend-created session. The app waits for backend verification before showing paid.',
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: p.state == PaymentFlowState.initiating
                ? null
                : () => p.initiateOnline(),
            icon: const Icon(Icons.lock_outline),
            label: Text(
              p.state == PaymentFlowState.initiating
                  ? 'Starting...'
                  : 'Start secure payment',
            ),
          ),
        ],
      );
    }
    if (method.isManual) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submit the transfer reference for review. This will not mark the order paid.',
          ),
          TextField(
            controller: ref,
            decoration: const InputDecoration(
              labelText: 'Transaction reference *',
            ),
          ),
          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'Payer name (optional)',
            ),
          ),
          TextField(
            controller: phone,
            decoration: const InputDecoration(
              labelText: 'Payer phone (optional)',
            ),
          ),
          TextField(
            controller: note,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: p.state == PaymentFlowState.initiating
                ? null
                : () {
                    p.updateManualDraft(
                      reference: ref.text,
                      name: name.text,
                      phone: phone.text,
                      note: note.text,
                    );
                    p.submitManual();
                  },
            icon: const Icon(Icons.rate_review_outlined),
            label: Text(
              p.state == PaymentFlowState.initiating
                  ? 'Submitting...'
                  : 'Submit for review',
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cash will be collected on delivery. This does not mark the order paid or posted.',
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: p.state == PaymentFlowState.initiating
              ? null
              : () => p.selectCod(),
          icon: const Icon(Icons.local_shipping_outlined),
          label: Text(
            p.state == PaymentFlowState.initiating
                ? 'Saving...'
                : 'Select Cash on Delivery',
          ),
        ),
      ],
    );
  }
}

class _WalletArea extends StatelessWidget {
  const _WalletArea({
    required this.walletNumber,
    required this.walletCode,
    required this.walletPin,
  });
  final TextEditingController walletNumber, walletCode, walletPin;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PaymentProvider>();
    final loading =
        p.state == PaymentFlowState.loadingWalletProviders ||
        p.state == PaymentFlowState.initiating ||
        p.state == PaymentFlowState.processingWallet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Payment Simulation — Presentation Environment. No official wallet logos are used and no real wallet credentials should be entered.',
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (p.walletProviders.isEmpty)
          FilledButton.icon(
            onPressed: loading ? null : () => p.loadWalletProviders(),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: Text(
              loading ? 'Loading wallets...' : 'Choose Mobile Wallet',
            ),
          ),
        if (p.walletProviders.isNotEmpty) ...[
          Text(
            'Choose Mobile Wallet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: p.walletProviders
                .map(
                  (w) => _WalletProviderCard(
                    provider: w,
                    selected: p.selectedWalletProvider?.code == w.code,
                    onTap: () => p.selectWalletProvider(w),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          if (p.walletSession == null)
            FilledButton.icon(
              onPressed: loading || p.selectedWalletProvider == null
                  ? null
                  : () => p.initiateWallet(),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(loading ? 'Starting...' : 'Start wallet simulation'),
            ),
        ],
        if (p.walletSession != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.walletSession!.providerDisplayName} simulation',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(p.walletSession!.safeInstruction),
                  const SizedBox(height: 8),
                  const Text('Test verification code: 123456'),
                  const Text('Test payment PIN: 12345'),
                  TextField(
                    controller: walletNumber,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText:
                          p.selectedWalletProvider?.phoneLabel ??
                          'Wallet number',
                      hintText:
                          p.selectedWalletProvider?.phoneHint ?? '01XXXXXXXXX',
                    ),
                  ),
                  TextField(
                    controller: walletCode,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Verification code',
                    ),
                  ),
                  TextField(
                    controller: walletPin,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Payment PIN'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: loading
                        ? null
                        : () => p.confirmWallet(
                            walletNumber: walletNumber.text,
                            verificationCode: walletCode.text,
                            paymentPin: walletPin.text,
                          ),
                    icon: const Icon(Icons.verified_outlined),
                    label: Text(
                      loading ? 'Processing...' : 'Confirm simulated payment',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WalletProviderCard extends StatelessWidget {
  const _WalletProviderCard({
    required this.provider,
    required this.selected,
    required this.onTap,
  });
  final MobileWalletProviderOption provider;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _themeColor(provider.visualThemeKey);
    return SizedBox(
      width: 158,
      child: Card(
        color: selected ? color.withValues(alpha: 0.14) : null,
        child: InkWell(
          onTap: provider.eligible ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  child: Text(
                    provider.displayName.length <= 2
                        ? provider.displayName.toUpperCase()
                        : provider.displayName.substring(0, 2).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.displayName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  provider.eligible
                      ? (provider.shortDescription ?? 'Wallet simulation')
                      : (provider.ineligibilityReason ?? 'Not eligible'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _themeColor(String? key) => switch (key) {
    'pink' => Colors.pink,
    'orange' => Colors.deepOrange,
    'purple' => Colors.deepPurple,
    'blue' => Colors.blue,
    'green' => Colors.green,
    'teal' => Colors.teal,
    _ => Colors.indigo,
  };
}

class _StatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<PaymentProvider>();
    final s = p.current;
    if (s == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Payment has not started.'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment status: ${s.paymentStatus}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('Accounting: ${s.accountingStatus}'),
            if (s.paymentNumber != null) Text('Payment: ${s.paymentNumber}'),
            if (s.message != null) Text(s.message!),
            if (s.paid)
              const Text(
                'Paid after backend verification.',
                style: TextStyle(color: Colors.green),
              ),
            if (s.reviewRequired)
              const Text('Submitted for review. Not paid yet.'),
            if (s.codPending)
              const Text('COD pending. Payment is collected on delivery.'),
            if (s.cancellable)
              OutlinedButton.icon(
                onPressed: p.state == PaymentFlowState.initiating
                    ? null
                    : () => p.cancelPending(),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel pending payment'),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => p.refreshStatus(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh status'),
            ),
            for (final e in s.timeline)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.circle, size: 10),
                title: Text(e.status),
                subtitle: Text(
                  '${e.source}${e.note == null ? '' : ' - ${e.note}'}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
