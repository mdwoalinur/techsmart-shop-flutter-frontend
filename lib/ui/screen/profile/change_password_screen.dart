import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/auth_provider.dart';
import '../../widget/auth/auth_validation.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePasswordScreen> {
  final form = GlobalKey<FormState>(),
      current = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool obscure = true;
  @override
  void dispose() {
    current.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Password policy: ${AuthValidation.passwordPolicy}'),
              TextFormField(
                key: const Key('currentPassword'),
                controller: current,
                obscureText: obscure,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Enter current password.' : null,
              ),
              TextFormField(
                key: const Key('newPassword'),
                controller: password,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'New password',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: AuthValidation.password,
              ),
              TextFormField(
                key: const Key('confirmNewPassword'),
                controller: confirm,
                obscureText: obscure,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
                validator: (v) =>
                    v != password.text ? 'Passwords do not match.' : null,
              ),
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
                        final ok = await context
                            .read<AuthProvider>()
                            .changePassword(
                              current.text,
                              password.text,
                              confirm.text,
                            );
                        current.clear();
                        password.clear();
                        confirm.clear();
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Password changed. Please sign in again.',
                              ),
                            ),
                          );
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        }
                      },
                child: const Text('Change Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
