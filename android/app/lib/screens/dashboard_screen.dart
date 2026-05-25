import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/calorie_journal.dart';
import '../providers/medicine_catalog.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/medi_background.dart';
import '../widgets/ui_kit.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.goTab});

  final void Function(int tab) goTab;

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will return to the login screen. Your data stays saved on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicineCatalog>().items;
    final kcal = context.watch<CalorieJournal>().todayTotal;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final name = email.contains('@') ? email.split('@').first : 'there';

    return MediBackground(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Hi, $name 👋',
              subtitle: 'Your wellness hub — reminders, calm breath, and mindful nutrition.',
              trailing: Material(
                color: AppTheme.cardWhite.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.settings_rounded, color: AppTheme.deepTeal),
                  ),
                ),
              ),
            ),
            if (email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(email, style: const TextStyle(color: AppTheme.inkMuted, fontSize: 13)),
              ),
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.mintGlow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.offline_bolt_rounded, color: AppTheme.deepTeal, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Medicines & meals save on this phone. Sign in to sync medicines across devices.',
                      style: TextStyle(color: AppTheme.inkMuted, height: 1.45, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Active reminders',
                    value: '${meds.length}',
                    icon: Icons.alarm_rounded,
                    onTap: () => goTab(1),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StatCard(
                    label: "Today's kcal",
                    value: '$kcal',
                    icon: Icons.local_fire_department_rounded,
                    gradient: AppTheme.coralGradient,
                    onTap: () => goTab(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Quick actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
            ),
            const SizedBox(height: 14),
            FeatureRow(
              title: 'Medicine reminders',
              subtitle: 'Schedule daily local notifications',
              icon: Icons.medication_liquid_rounded,
              onTap: () => goTab(1),
            ),
            FeatureRow(
              title: 'Guided breathing',
              subtitle: '4s inhale · 6s exhale relaxation',
              icon: Icons.spa_rounded,
              accent: const LinearGradient(colors: [Color(0xFF1BA39C), Color(0xFF5EEAD4)]),
              onTap: () => goTab(2),
            ),
            FeatureRow(
              title: 'Nutrition log',
              subtitle: 'Track meals & weekly calories',
              icon: Icons.restaurant_menu_rounded,
              accent: AppTheme.coralGradient,
              onTap: () => goTab(3),
            ),
            FeatureRow(
              title: 'MediCoach',
              subtitle: 'AI + voice — app topics only',
              icon: Icons.auto_awesome_rounded,
              accent: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9B8CFF)]),
              onTap: () => goTab(4),
            ),
            const SizedBox(height: 20),
            GlassCard(
              onTap: () => _logout(context),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCoral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.logout_rounded, color: AppTheme.accentCoral),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Switch account on this device', style: TextStyle(color: AppTheme.inkMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted.withValues(alpha: 0.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
