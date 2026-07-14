import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/notification/notification_models.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/notification_provider.dart';
import '../../widget/notification/notification_bell.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});
  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<NotificationProvider>();
      if (p.signedIn) {
        p.loadPreferences();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: !auth.authenticated
          ? const NotificationLoginPrompt()
          : p.preferencesLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (p.error != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text(p.error!),
                    ),
                  ),
                ...p.preferences.map(
                  (pref) => Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          key: Key(
                            'pref-inapp-${notificationCategoryCode(pref.category)}',
                          ),
                          title: Text(notificationCategoryLabel(pref.category)),
                          subtitle: Text(
                            pref.critical
                                ? 'In-app account alerts stay enabled for safety.'
                                : 'In-app notifications',
                          ),
                          value: pref.inAppEnabled,
                          onChanged: pref.critical
                              ? null
                              : (v) => p.updatePreferenceDraft(
                                  pref.category,
                                  inAppEnabled: v,
                                ),
                        ),
                        SwitchListTile(
                          key: Key(
                            'pref-email-${notificationCategoryCode(pref.category)}',
                          ),
                          title: const Text('Email notifications'),
                          value: pref.emailEnabled,
                          onChanged: (v) => p.updatePreferenceDraft(
                            pref.category,
                            emailEnabled: v,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('saveNotificationPreferences'),
                  onPressed: p.preferencesSaving
                      ? null
                      : () async {
                          final ok = await p.savePreferences();
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Notification preferences saved.',
                                ),
                              ),
                            );
                          }
                        },
                  child: p.preferencesSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save preferences'),
                ),
              ],
            ),
    );
  }
}
