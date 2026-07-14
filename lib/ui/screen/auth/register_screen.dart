import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/auth_provider.dart';
import '../../widget/auth/auth_validation.dart';
import 'registration_otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final form = GlobalKey<FormState>(),
      name = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool terms = false, obscure = true, obscureConfirm = true;
  @override
  void dispose() {
    for (final c in [name, email, phone, password, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                key: const Key('registerName'),
                controller: name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => (v?.trim().length ?? 0) < 2
                    ? 'Enter your full name.'
                    : null,
              ),
              TextFormField(
                key: const Key('registerEmail'),
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: AuthValidation.email,
              ),
              TextFormField(
                key: const Key('registerPhone'),
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: '01XXXXXXXXX or +8801XXXXXXXXX',
                ),
                validator: AuthValidation.phone,
              ),
              const SizedBox(height: 12),
              Text('Password policy: ${AuthValidation.passwordPolicy}'),
              TextFormField(
                key: const Key('registerPassword'),
                controller: password,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
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
                key: const Key('registerConfirm'),
                controller: confirm,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => obscureConfirm = !obscureConfirm),
                    icon: Icon(
                      obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (v) =>
                    v != password.text ? 'Passwords do not match.' : null,
              ),
              CheckboxListTile(
                key: const Key('termsCheckbox'),
                value: terms,
                onChanged: (v) => setState(() => terms = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'I acknowledge the Terms and Privacy Policy.',
                ),
              ),
              if (auth.error != null)
                Text(
                  auth.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('registerSubmit'),
                onPressed: auth.busy
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        if (!terms) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Terms and Privacy acknowledgement is required.',
                              ),
                            ),
                          );
                          return;
                        }
                        final ok = await context.read<AuthProvider>().register(
                          fullName: name.text,
                          email: email.text,
                          phone: phone.text,
                          password: password.text,
                          confirmPassword: confirm.text,
                          terms: terms,
                        );
                        password.clear();
                        confirm.clear();
                        if (ok && context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegistrationOtpScreen(),
                            ),
                          );
                        }
                      },
                child: auth.busy
                    ? const CircularProgressIndicator()
                    : const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
