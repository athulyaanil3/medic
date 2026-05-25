import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/medicine_catalog.dart';
import '../services/auth_service.dart';
import '../services/local_store.dart';
import '../services/notification_service.dart';
import '../services/reminder_voice_service.dart';
import '../theme/app_theme.dart';
import '../widgets/medi_background.dart';
import '../widgets/ui_kit.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _voiceReminders = true;
  bool _testingVoice = false;

  @override
  void initState() {
    super.initState();
    _voiceReminders = LocalStore.readVoiceRemindersEnabled();
  }

  Future<void> _setVoiceReminders(bool value) async {
    await LocalStore.writeVoiceRemindersEnabled(value);
    if (mounted) {
      await context.read<MedicineCatalog>().rescheduleReminders();
    }
    if (!mounted) return;
    setState(() => _voiceReminders = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Voice alerts on (${ReminderVoiceService.languageTag()})'
                : 'Voice alerts off — notifications only',
          ),
        ),
      );
    }
  }

  Future<void> _testVoiceReminder() async {
    setState(() => _testingVoice = true);
    try {
      await ensureReminderPermissions(requestIfNeeded: true);
      await showTestReminderNotification();
    } finally {
      if (mounted) setState(() => _testingVoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email =
        AuthService().getCurrentUser()?.email ?? 'Not signed in';
    final lang = ReminderVoiceService.languageTag();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
      ),
      body: MediBackground(
        child: ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
            left: 20,
            right: 20,
            bottom: 24,
          ),
          children: [
            const PageHeader(
              title: 'Your account',
              subtitle: 'Manage reminders and sign-in.',
            ),
            GlassCard(
              child: Row(
                children: [
                  const IconBadge(
                    icon: Icons.person_rounded,
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Signed in as',
                          style: TextStyle(
                            color: AppTheme.inkMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const PageHeader(
              title: 'Reminder voice',
              subtitle:
                  'Speaks medicine name and dose in your phone language when a reminder fires.',
            ),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Local language voice alert',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Device language: $lang\n'
                      'Hindi, Malayalam, Tamil, Telugu, Kannada, Bengali, Marathi, or English.',
                      style: const TextStyle(fontSize: 12, height: 1.35),
                    ),
                    value: _voiceReminders,
                    onChanged: _setVoiceReminders,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _testingVoice ? null : _testVoiceReminder,
                    icon: _testingVoice
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.volume_up_rounded, size: 20),
                    label: Text(
                      _testingVoice ? 'Playing…' : 'Test voice reminder',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.coralGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [AppTheme.softShadow(0.15)],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await AuthService().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(),
                        ),
                        (_) => false,
                      );
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Sign out',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
