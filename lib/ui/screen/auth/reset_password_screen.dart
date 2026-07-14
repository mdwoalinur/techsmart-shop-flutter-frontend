import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/auth_provider.dart';
import '../../widget/auth/auth_validation.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPasswordScreen> {
  final form = GlobalKey<FormState>(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool obscure = true;
  @override
  void dispose() {
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Password policy: ${AuthValidation.passwordPolicy}'),
              TextFormField(
                key: const Key('resetPassword'),
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
                key: const Key('resetConfirm'),
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
                            .resetPassword(password.text, confirm.text);
                        password.clear();
                        confirm.clear();
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Password reset successfully. Please sign in.',
                              ),
                            ),
                          );
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        }
                      },
                child: const Text('Reset Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
