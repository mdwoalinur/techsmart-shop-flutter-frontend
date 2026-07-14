import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../provider/auth_provider.dart';
import '../../widget/auth/auth_validation.dart';
import 'reset_password_screen.dart';

class ResetOtpScreen extends StatefulWidget {
  const ResetOtpScreen({super.key});
  @override
  State<ResetOtpScreen> createState() => _ResetOtpState();
}

class _ResetOtpState extends State<ResetOtpScreen> {
  final form = GlobalKey<FormState>(), code = TextEditingController();
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Reset Code')),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Enter the six-digit password-reset code.'),
              TextFormField(
                key: const Key('resetOtp'),
                controller: code,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  labelText: 'Verification code',
                ),
                validator: AuthValidation.otp,
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
                            .verifyResetOtp(code.text);
                        code.clear();
                        if (ok && context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ResetPasswordScreen(),
                            ),
                          );
                        }
                      },
                child: const Text('Verify Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
