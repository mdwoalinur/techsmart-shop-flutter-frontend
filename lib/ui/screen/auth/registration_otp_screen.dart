import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../provider/auth_provider.dart';
import '../../widget/auth/auth_validation.dart';

class RegistrationOtpScreen extends StatefulWidget {
  const RegistrationOtpScreen({super.key});
  @override
  State<RegistrationOtpScreen> createState() => _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState extends State<RegistrationOtpScreen> {
  final form = GlobalKey<FormState>(), code = TextEditingController();
  Timer? timer;
  int cooldown = 45;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (cooldown > 0 && mounted) setState(() => cooldown--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 72),
              const SizedBox(height: 16),
              Text(
                'Enter the six-digit code sent to ${_mask(auth.pendingEmail)}.',
                textAlign: TextAlign.center,
              ),
              const Text(
                'The server controls expiry, attempt limits, and resend eligibility.',
                textAlign: TextAlign.center,
              ),
              TextFormField(
                key: const Key('registrationOtp'),
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
              if (auth.error != null)
                Text(
                  auth.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: auth.busy
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        final ok = await context
                            .read<AuthProvider>()
                            .verifyRegistration(code.text);
                        code.clear();
                        if (ok && context.mounted) {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        }
                      },
                child: const Text('Verify'),
              ),
              TextButton(
                onPressed: auth.busy || cooldown > 0
                    ? null
                    : () async {
                        final ok = await context
                            .read<AuthProvider>()
                            .resendRegistration();
                        if (ok && mounted) setState(() => cooldown = 45);
                      },
                child: Text(
                  cooldown > 0
                      ? 'Resend available in ${cooldown}s'
                      : 'Resend OTP',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _mask(String? email) {
  if (email == null || !email.contains('@')) return 'your email';
  final p = email.split('@');
  return '${p.first.substring(0, 1)}***@${p.last}';
}
