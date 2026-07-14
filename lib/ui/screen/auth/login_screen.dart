import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/auth_provider.dart';
import '../../widget/auth/auth_validation.dart';
import 'password_recovery_screens.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>(),
      email = TextEditingController(),
      password = TextEditingController();
  bool obscure = true;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Login')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Image.asset('assets/branding/techsmart_shop_logo.png', height: 90),
            const SizedBox(height: 24),
            Form(
              key: form,
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('loginEmail'),
                    controller: email,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: AuthValidation.email,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('loginPassword'),
                    controller: password,
                    autofillHints: const [AutofillHints.password],
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        key: const Key('loginPasswordVisibility'),
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (v) =>
                        (v ?? '').isEmpty ? 'Enter your password.' : null,
                  ),
                  if (auth.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        auth.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('loginSubmit'),
                      onPressed: auth.busy
                          ? null
                          : () async {
                              if (!form.currentState!.validate()) return;
                              final ok = await context
                                  .read<AuthProvider>()
                                  .login(email.text, password.text);
                              password.clear();
                              if (ok && context.mounted) Navigator.pop(context);
                            },
                      child: auth.busy
                          ? const CircularProgressIndicator()
                          : const Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              child: const Text('Forgot Password?'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text('Create Account'),
            ),
            TextButton(
              key: const Key('continueGuest'),
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Continue Browsing as Guest'),
            ),
          ],
        ),
      ),
    );
  }
}
