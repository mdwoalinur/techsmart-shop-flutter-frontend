import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/address/address_models.dart';
import '../../../provider/checkout_provider.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, this.address});
  final CustomerAddress? address;
  @override
  State<AddressFormScreen> createState() => _S();
}

class _S extends State<AddressFormScreen> {
  final key = GlobalKey<FormState>();
  late final Map<String, TextEditingController> c;
  bool def = false;
  @override
  void initState() {
    super.initState();
    final a = widget.address;
    c = {
      'label': TextEditingController(text: a?.label ?? 'Home'),
      'name': TextEditingController(text: a?.recipientName),
      'phone': TextEditingController(text: a?.phone),
      'line': TextEditingController(text: a?.addressLine1),
      'city': TextEditingController(text: a?.city),
      'district': TextEditingController(text: a?.district),
      'division': TextEditingController(text: a?.division),
      'postal': TextEditingController(text: a?.postalCode),
      'instructions': TextEditingController(text: a?.instructions),
    };
    def = a?.isDefault ?? false;
  }

  @override
  Widget build(BuildContext x) => Scaffold(
    appBar: AppBar(
      title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
    ),
    body: SafeArea(
      child: Form(
        key: key,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final e in [
              ('label', 'Label'),
              ('name', 'Recipient name'),
              ('phone', 'Phone'),
              ('line', 'Address line'),
              ('city', 'City'),
              ('district', 'District'),
              ('division', 'Division'),
              ('postal', 'Postal code'),
              ('instructions', 'Delivery instructions'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: c[e.$1],
                  decoration: InputDecoration(labelText: e.$2),
                  maxLines: e.$1 == 'instructions' ? 3 : 1,
                  validator: e.$1 == 'postal' || e.$1 == 'instructions'
                      ? null
                      : (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
            SwitchListTile(
              value: def,
              onChanged: (v) => setState(() => def = v),
              title: const Text('Default address'),
            ),
            FilledButton(
              onPressed: () async {
                if (!key.currentState!.validate()) return;
                final d = AddressDraft(
                  label: c['label']!.text,
                  recipientName: c['name']!.text,
                  phone: c['phone']!.text,
                  addressLine1: c['line']!.text,
                  city: c['city']!.text,
                  district: c['district']!.text,
                  division: c['division']!.text,
                  postalCode: c['postal']!.text,
                  instructions: c['instructions']!.text,
                  isDefault: def,
                );
                if (await x.read<CheckoutProvider>().saveAddress(
                      d,
                      id: widget.address?.id,
                    ) &&
                    mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Address'),
            ),
          ],
        ),
      ),
    ),
  );
}
