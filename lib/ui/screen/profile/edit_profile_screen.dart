import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/auth_provider.dart';
import '../../widget/auth/auth_validation.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfileScreen> {
  final form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> c;
  @override
  void initState() {
    super.initState();
    final p = context.read<AuthProvider>().profile!;
    c = {
      'fullName': TextEditingController(text: p.fullName),
      'phone': TextEditingController(text: p.phone),
      'address': TextEditingController(text: p.address),
      'city': TextEditingController(text: p.city),
      'state': TextEditingController(text: p.state),
      'postalCode': TextEditingController(text: p.postalCode),
      'country': TextEditingController(text: p.country),
    };
  }

  @override
  void dispose() {
    for (final x in c.values) {
      x.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              field(
                'fullName',
                'Full name',
                (v) => (v?.trim().length ?? 0) < 2
                    ? 'Enter your full name.'
                    : null,
              ),
              field('phone', 'Phone', AuthValidation.phone),
              field('address', 'Address', null),
              field('city', 'City', null),
              field('state', 'State / Division', null),
              field('postalCode', 'Postal code', null),
              field('country', 'Country', null),
              const Text('Email and customer code cannot be edited here.'),
              if (a.error != null)
                Text(
                  a.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              FilledButton(
                onPressed: a.busy
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        final values = {
                          for (final e in c.entries) e.key: e.value.text.trim(),
                        };
                        final ok = await context
                            .read<AuthProvider>()
                            .updateProfile(values);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated.')),
                          );
                          Navigator.pop(context);
                        }
                      },
                child: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget field(
    String key,
    String label,
    String? Function(String?)? validator,
  ) => TextFormField(
    key: Key('profile-$key'),
    controller: c[key],
    decoration: InputDecoration(labelText: label),
    validator: validator,
  );
}
