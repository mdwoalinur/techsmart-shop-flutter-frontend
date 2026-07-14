import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/auth_provider.dart';
import '../../widget/auth/auth_validation.dart';
import 'reset_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPasswordScreen> {
  final form = GlobalKey<FormState>(), email = TextEditingController();
  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Enter your email. The same response is shown whether or not an eligible account exists.',
              ),
              TextFormField(
                key: const Key('forgotEmail'),
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: AuthValidation.email,
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
                            .forgotPassword(email.text);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'If an eligible account exists, a verification code has been sent.',
                              ),
                            ),
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ResetOtpScreen(),
                            ),
                          );
                        }
                      },
                child: const Text('Send Verification Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
